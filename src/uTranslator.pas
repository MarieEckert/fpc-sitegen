unit uTranslator;

{
  fpc-sitegen -- A more featured replacement for sadhtml

  Copyright (c) 2024, Marie Eckert
  Licensed under the BSD 3-Clause License.
}

{$H+}

interface

uses StrUtils, SysUtils, Types, uSADParser, uShared;

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

function TranslateHeader(generator: TGenerator; header: String; value: String): TTranslateResult;
function TranslateSubHeader(generator: TGenerator; header: String; value: String)
                           : TTranslateResult;
function TranslateSection(generator: TGenerator; section: TSection; value: String)
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

{ --- Public Functions --- }

function TranslateHeader(generator: TGenerator; header: String; value: String): TTranslateResult;
begin
  TranslateHeader.is_ok   := True;
  TranslateHeader.err     := treNONE;
  TranslateHeader.err_msg := '';
  TranslateHeader.value   := value;

  TranslateHeader.value := TranslateHeader.value +
                           generator.template.head_format.prefix_text +
                           header +
                           generator.template.head_format.postfix_text;
end;

function TranslateSubHeader(generator: TGenerator; header: String; value: String)
                           : TTranslateResult;
begin
  TranslateSubHeader.is_ok   := True;
  TranslateSubHeader.err     := treNONE;
  TranslateSubHeader.err_msg := '';
  TranslateSubHeader.value   := value;

  TranslateSubHeader.value := TranslateSubHeader.value +
                              generator.template.sub_head_format.prefix_text +
                              header +
                              generator.template.sub_head_format.postfix_text;
end;

{ TODO: move handling for insert switch into different function }
function TranslateSection(generator: TGenerator; section: TSection; value: String)
                         : TTranslateResult;
const
  SECTION_NAME_MARKER = '$$SECTION_NAME$$';
  SECTION_START_MARKER = '$$SECTION_START$$';
  SECTION_END_MARKER = '$$SECTION_END$$';
var
  nline, word_ix, child_ix, tmp_ix: LongInt;
  skip: Integer; { how many words should be skipped? }

  prefix, postfix, _word, tmp, path: String;
  lines, words: TStringDynArray;

  insert_file: Text;

  { counters for $color and $style switches }
  style_count: Integer;

  ended, in_text: Boolean;
begin
  TranslateSection.is_ok   := True;
  TranslateSection.err     := treNONE;
  TranslateSection.err_msg := '';
  TranslateSection.value   := value;

  if section.is_root then
    prefix := generator.template.root_section_format.prefix_text
  else
    prefix := generator.template.section_format.prefix_text;

  prefix := StringReplace(prefix, SECTION_NAME_MARKER, section.name, [rfReplaceAll]);

  TranslateSection.value := TranslateSection.value + prefix;

  lines := SplitString(section.contents, sLineBreak);

  child_ix := 0;
  style_count := 0;
  in_text := False;

  ended := False;

  for nline := 0 to Length(lines) - 1 do
  begin
    if Length(lines[nline]) < 1 then
    begin
      if in_text
      and (
           (generator.options.auto_break = abmEL)
        or (generator.options.auto_break = abmLF)
      ) then
        TranslateSection.value := TranslateSection.value + '<br>';
      continue;
    end;

    words := SplitString(lines[nline], ' ');

    skip := 0; { NOTE: This /could/ cause problems but is there to prevent problems }
    for word_ix := 0 to Length(words) - 1 do
    begin
      if skip > 0 then
      begin
        dec(skip);
        continue;
      end;
      _word := words[word_ix];

      case _word of
        SECTION_START_MARKER: begin
          __TextGuard(in_text, True, generator, TranslateSection);
          if child_ix >= Length(section.children) then
          begin
            TranslateSection.is_ok   := False;
            TranslateSection.err     := treSECTION_START_OVERFLOW;
            TranslateSection.err_msg := 'a section-start marker was encountered eventhough all' +
                                        'sections have been inserted!';
            exit;
          end;

          TranslateSection := TranslateSection(generator, section.children[child_ix],
                                               TranslateSection.value);
          inc(child_ix);
          if not TranslateSection.is_ok then
            exit;
        end;
        SECTION_END_MARKER: begin
          ended := True;
          break;
        end;
        HEADER: begin
          __TextGuard(in_text, True, generator, TranslateSection);

          TranslateSection := TranslateHeader(generator, MergeStringArray(
                                Copy(words, word_ix+1, Length(words)-1),
                                ' '
                              ), TranslateSection.value);
          if not TranslateSection.is_ok then
            exit;

          break;
        end;
        COLOR: begin { deprecated, should be removed in time }
          inc(style_count);
          if word_ix >= Length(words) then
          begin
            TranslateSection.is_ok   := False;
            TranslateSection.err     := treMISSING_SWITCH_PARAMETER;
            TranslateSection.err_msg := 'color switch is missing its parameter!';
            exit;
          end;

          __TextGuard(in_text, False, generator, TranslateSection);

          tmp := Copy(words[word_ix+1], 1, Length(words[word_ix+1]) - 1);
          TranslateSection.value := TranslateSection.value + '<span class="color-' + tmp + '">';
          inc(skip);

          writeln(stderr, 'WARNING: color switch is deprecated');
        end;
        STYLE: begin
          inc(style_count);
          if word_ix >= Length(words) then
          begin
            TranslateSection.is_ok   := False;
            TranslateSection.err     := treMISSING_SWITCH_PARAMETER;
            TranslateSection.err_msg := 'style switch is missing its parameter!';
            exit;
          end;

          __TextGuard(in_text, False, generator, TranslateSection);

          tmp := Copy(words[word_ix+1], 1, Length(words[word_ix+1]) - 1);
          TranslateSection.value := TranslateSection.value + '<span class="style-' + tmp + '">';
          inc(skip);
        end;
        RESET_ONE: begin
          if style_count = 0 then
          begin
            TranslateSection.is_ok   := False;
            TranslateSection.err     := treGENERIC_SWITCH;
            TranslateSection.err_msg := 'reset switch when no styles active!';
            exit;
          end;

          TranslateSection.value := TranslateSection.value + '</span>';
          dec(style_count);
        end;
        RESET_ALL: begin
          for tmp_ix := 0 to style_count - 1 do
          begin
            TranslateSection.value := TranslateSection.value + '</span>';
          end;
          style_count := 0;
        end;
        SUB_HEADER: begin
          __TextGuard(in_text, True, generator, TranslateSection);

          TranslateSection := TranslateSubHeader(generator, MergeStringArray(
                                Copy(words, word_ix+1, Length(words)-1),
                                ' '
                              ), TranslateSection.value);
          if not TranslateSection.is_ok then
            exit;

          break;
        end;
        '{$insert': begin
          if word_ix + 1 >= Length(words) then
          begin
            TranslateSection.is_ok   := False;
            TranslateSection.err     := treGENERIC_SWITCH;
            TranslateSection.err_msg := 'insert switch requires one argument (name)!';
            exit;
          end;

          tmp := Copy(words[word_ix+1], 1, Length(words[word_ix+1]) - 1);
          if not generator.options.file_defs.TryGetData(tmp, path) then
          begin
            TranslateSection.is_ok   := False;
            TranslateSection.err     := treGENERIC_SWITCH;
            TranslateSection.err_msg := 'no such file defined ("' + tmp + '")';
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
            readln(insert_file, tmp);
            TranslateSection.value := TranslateSection.value + tmp;
          end;

          Close(insert_file);

          skip := 1;
        end;
        { regular text }
        else begin
          __TextGuard(in_text, False, generator, TranslateSection);
          TranslateSection.value := TranslateSection.value + _word + ' ';
        end;
      end;
    end;

    if in_text and (generator.options.auto_break = abmLF) then
      TranslateSection.value := TranslateSection.value + '<br>';

    TranslateSection.value := TranslateSection.value + sLineBreak;
    if ended then
      break;
  end;

  if in_text then
    TranslateSection.value := TranslateSection.value + generator.template.text_format.postfix_text;

  if section.is_root then
    postfix := generator.template.root_section_format.postfix_text
  else
    postfix := generator.template.section_format.postfix_text;

  TranslateSection.value := TranslateSection.value + postfix;
end;

function TranslateSource(generator: TGenerator): TTranslateResult;
const
  DOCUMENT_TITLE_MARKER = '$$DOCUMENT_TITLE$$';
begin
  TranslateSource.is_ok   := True;
  TranslateSource.err     := treNONE;
  TranslateSource.err_msg := '';

  TranslateSource.value := generator.template.output_format.prefix_text;

  TranslateSource := TranslateSection(generator, generator.source.root_section,
                                      TranslateSource.value);
  if not TranslateSource.is_ok then
    exit;

  TranslateSource.value := TranslateSource.value + generator.template.output_format.postfix_text;
  TranslateSource.value := StringReplace(TranslateSource.value, DOCUMENT_TITLE_MARKER,
                                         generator.source.title, [rfReplaceAll]);
end;

end.
