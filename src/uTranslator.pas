unit uTranslator;

{
  fpc-sitegen -- A more featured replacement for sadhtml

  Copyright (c) 2024, Marie Eckert
  Licensed under the BSD 3-Clause License.
}

{$H+}

interface

uses sad, StrUtils, SysUtils, Types, uShared;

type
  TTranslateError = (treNONE, treUNKNOWN, treINVALID_SYNTAX, treSECTION_START_OVERFLOW,
                     treDISALLOWED_SWITCH, treMISSING_SWITCH_PARAMETER, treGENERIC_SWITCH);

  TTranslateResult = record
    is_ok   : Boolean;
    err     : TTranslateError;
    err_msg : String;
    value   : String;
  end;

{
  All Translate functions are intended to append to TTranslateResult.value, except
  for TranslateSource (whose job is to begin translation)
}

function TranslateHeader(generator: TGenerator; header: TTextBlock; value: String): TTranslateResult;
function TranslateSection(generator: TGenerator; section: PSection; value: String)
                         : TTranslateResult;
function TranslateSource(generator: TGenerator): TTranslateResult;

implementation

{ --- Private Procedures --- }

procedure __TextGuard(var in_text: Boolean; const checktype: Boolean;
                      constref generator: TGenerator; var res: TTranslateResult);
begin
  if checktype then
  begin
    if in_text then
    begin
      in_text := False;
      res.value := res.value + generator.template.text_format.postfix_text;
    end;

    exit;
  end;

  if not in_text then
  begin
    in_text := True;
    res.value := res.value + generator.template.text_format.prefix_text;
  end;
end;

function __MakeStyleSpan(constref styles: TStyleDynArray): String;
var
  style: TStyle;
begin
  if Length(styles) = 0 then
    exit('<span class="text">');

  __MakeStyleSpan := '<span class="text ';

  for style in styles do
    __MakeStyleSpan := __MakeStyleSpan + MergeStringArray(style.args, '_') + ' ';

  __MakeStyleSpan := Trim(__MakeStyleSpan) + '">';
end;

{ --- Public Functions --- }

function TranslateHeader(generator: TGenerator; header: TTextBlock; value: String): TTranslateResult;
const
  HEADER_LEVEL_MARKER = '$$HEADER_LEVEL$$';
begin
  TranslateHeader.is_ok   := True;
  TranslateHeader.err     := treNONE;
  TranslateHeader.err_msg := '';
  TranslateHeader.value   := value;

  TranslateHeader.value := TranslateHeader.value +
                           StringReplace(
                             generator.template.head_format.prefix_text,
                             HEADER_LEVEL_MARKER,
                             header.styles[0].args[0],
                             [rfReplaceAll]
                           ) +
                           MergeStringArray(header.content, ' ') +
                           StringReplace(
                             generator.template.head_format.postfix_text,
                             HEADER_LEVEL_MARKER,
                             header.styles[0].args[0],
                             [rfReplaceAll]
                           );
end;

function TranslateSection(generator: TGenerator; section: PSection; value: String)
                         : TTranslateResult;
const
  SECTION_NAME_MARKER = '$$SECTION_NAME$$';
var
  word_ix, child_ix: Integer;
  empty_spaces: Integer;
  skip: Int64;

  prefix, span_text, _word, path, strTmp: String;
  tmp: TStringDynArray;

  insert_file: Text;

  block: TTextBlock;
begin
  TranslateSection.is_ok   := True;
  TranslateSection.err     := treNONE;
  TranslateSection.err_msg := '';
  TranslateSection.value   := value;

  { only the root section is allowed to have a Nil parent }
  if section^.parent = Nil then
    prefix := generator.template.root_section_format.prefix_text
  else
    prefix := generator.template.section_format.prefix_text;

  prefix := StringReplace(prefix, SECTION_NAME_MARKER, section^.name, [rfReplaceAll]);

  TranslateSection.value := TranslateSection.value + prefix;

  child_ix := 0;
  empty_spaces := 0;

  for block in section^.blocks do
  begin
    if Length(block.content) = 0 then
      continue;

    if (Length(block.styles) = 1) and (block.styles[0].kind = TStyleKind.Head) then
    begin
      TranslateSection := TranslateHeader(generator, block, TranslateSection.value);
      if not TranslateSection.is_ok then
        exit;
      continue;
    end;

    span_text := __MakeStyleSpan(block.styles);
    TranslateSection.value := TranslateSection.value + span_text;

    word_ix := 0;
    skip := 0;
    for _word in block.content do
    begin
      if skip > 0 then
      begin
        dec(skip);
        continue;
      end;

      if ((empty_spaces = 1) and (generator.options.auto_break = abmLF))
      or ((empty_spaces = 2) and (generator.options.auto_break = abmEL)) then
        TranslateSection.value := TranslateSection.value + '<br>';

      case _word of
        SECTION_START_MARKER: begin
          if child_ix >= Length(section^.children) then
          begin
            TranslateSection.is_ok   := False;
            TranslateSection.err     := treSECTION_START_OVERFLOW;
            TranslateSection.err_msg := 'a section-start marker was encountered eventhough all' +
                                        'sections have been inserted!';
            exit;
          end;

          TranslateSection.value := TranslateSection.value + '</span>';
          TranslateSection := TranslateSection(generator, section^.children[child_ix], TranslateSection.value);

          Inc(child_ix);
          if not TranslateSection.is_ok then
            exit;
        end;
        SECTION_END_MARKER: begin
        end;
        '{$insert': begin
          skip := word_ix;
          tmp := sad.ParseSwitchArgs(block.content, skip);
          skip := Length(tmp);

          if Length(tmp) <> 1 then
          begin
            TranslateSection.is_ok   := False;
            TranslateSection.err     := treGENERIC_SWITCH;
            TranslateSection.err_msg := 'insert switch requires one argument (name)!';
            exit;
          end;

          if not generator.options.file_defs.TryGetData(tmp[0], path) then
          begin
            TranslateSection.is_ok   := False;
            TranslateSection.err     := treGENERIC_SWITCH;
            TranslateSection.err_msg := 'no such file defined ("' + tmp[0] + '")';
            exit;
          end;

          if not FileExists(path) then
          begin
            TranslateSection.is_ok   := False;
            TranslateSection.err     := treGENERIC_SWITCH;
            TranslateSection.err_msg := 'no such file or directory: "' + path + '"';
            exit;
          end;

          Assign(insert_file, path);
          ReSet(insert_file);

          while not eof(insert_file) do
          begin
            readln(insert_file, strTmp);
            TranslateSection.value := TranslateSection.value + strTmp + sLineBreak;
          end;

          Close(insert_file);

          skip := 1;
        end;
        sLineBreak: Inc(empty_spaces);
        else begin
          empty_spaces := 0;
          TranslateSection.value := TranslateSection.value + _word + ' ';
        end;
      end;

      Inc(word_ix);
    end;

    TranslateSection.value := TranslateSection.value + '</span>';
  end;
end;

function TranslateSource(generator: TGenerator): TTranslateResult;
const
  DOCUMENT_TITLE_MARKER = '$$DOCUMENT_TITLE$$';
begin
  TranslateSource.is_ok   := True;
  TranslateSource.err     := treNONE;
  TranslateSource.err_msg := '';

  TranslateSource.value := generator.template.output_format.prefix_text;

  generator.source.root^.name := 'root';
  TranslateSource := TranslateSection(generator, generator.source.root,
                                      TranslateSource.value);
  if not TranslateSource.is_ok then
    exit;

  TranslateSource.value := TranslateSource.value + generator.template.output_format.postfix_text;
  TranslateSource.value := StringReplace(TranslateSource.value, DOCUMENT_TITLE_MARKER,
                                         generator.source.title, [rfReplaceAll]);
end;

end.