unit uTranslator;

{$H+}

interface

uses StrUtils, SysUtils, Types, uSADParser, uShared;

type
  TTranslateError = (treNONE, treUNKNOWN, treINVALID_SYNTAX, treSECTION_START_OVERFLOW,
                     treDISALLOWED_SWITCH);

{ These types may be needed if the $reset switch is allowed. }
{
  TStyleProperty = record
    is_color : Boolean;
    name     : String;
  end;

  TStylePropertyDynArray = array of TStyleProperty;
}

  TTranslateResult = record
    is_ok   : Boolean;
    err     : TTranslateError;
    err_msg : String;
    value   : String;
  end;

{
  All Translate functions are intended to append to TTranslateResult.value, except
  for TranslateSource (whose job is to begin translation
}

function TranslateHeader(generator: TGenerator; header: String; value: String): TTranslateResult;
function TranslateSubHeader(generator: TGenerator; header: String; value: String)
                           : TTranslateResult;
function TranslateSection(generator: TGenerator; section: TSection; value: String)
                         : TTranslateResult;
function TranslateSource(generator: TGenerator): TTranslateResult;

implementation

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

function TranslateSection(generator: TGenerator; section: TSection; value: String)
                         : TTranslateResult;
const
  SECTION_NAME_MARKER = '$$SECTION_NAME$$';
  SECTION_START_MARKER = '$$SECTION_START$$';
var
  nline, word_ix, child_ix: Integer;
  prefix, _word: String;
  lines, words: TStringDynArray;

  { counters for $color and $style switches }
  color_count, style_count: Integer;

  in_text: Boolean;
begin
  TranslateSection.is_ok   := True;
  TranslateSection.err     := treNONE;
  TranslateSection.err_msg := '';
  TranslateSection.value   := value;

  prefix := StringReplace(generator.template.section_format.prefix_text,
                          SECTION_NAME_MARKER, section.name, [rfReplaceAll]);
  TranslateSection.value := TranslateSection.value + prefix;

  lines := SplitString(section.contents, sLineBreak);

  in_text := False;
  child_ix := 0;

  for nline := 0 to Length(lines) - 1 do
  begin
    if Length(lines[nline]) < 1 then
      continue;

    words := SplitString(lines[nline], ' ');

    for word_ix := 0 to Length(words) - 1 do
    begin
      _word := words[word_ix];

      case _word of
        SECTION_START_MARKER: begin
          if in_text then
          begin
            in_text := False;
            TranslateSection.value := TranslateSection.value +
                                      generator.template.text_format.postfix_text;
          end;

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
        HEADER: begin
          { TODO: How to properly de-duplicate this code? }
          if in_text then
          begin
            in_text := False;
            TranslateSection.value := TranslateSection.value +
                                      generator.template.text_format.postfix_text;
          end;

          TranslateSection := TranslateHeader(generator, MergeStringArray(
                                Copy(words, word_ix+1, Length(words)-1),
                                ' '
                              ), TranslateSection.value);
          if not TranslateSection.is_ok then
            exit;

          break;
        end;
        COLOR: begin
          inc(color_count);
        end;
        STYLE: begin
          inc(style_count);
        end;
        RESET_: begin
          TranslateSection.is_ok   := False;
          TranslateSection.err     := treDISALLOWED_SWITCH;
          TranslateSection.err_msg := 'the $reset switch is currently not allowed!';
          exit;
        end;
        RESET_ALL: begin
        end;
        SUB_HEADER: begin
          { TODO: How to properly de-duplicate this code? }
          if in_text then
          begin
            in_text := False;
            TranslateSection.value := TranslateSection.value +
                                      generator.template.text_format.postfix_text;
          end;

          TranslateSection := TranslateSubHeader(generator, MergeStringArray(
                                Copy(words, word_ix+1, Length(words)-1),
                                ' '
                              ), TranslateSection.value);
          if not TranslateSection.is_ok then
            exit;

          break;
        end;
        { regular text }
        else begin
          if not in_text then
          begin
            in_text := True;
            TranslateSection.value := TranslateSection.value +
                                      generator.template.text_format.prefix_text;
          end;

          TranslateSection.value := TranslateSection.value + _word + ' ';
        end;
      end;
    end;

    if in_text and generator.options.auto_break then
      TranslateSection.value := TranslateSection.value + '<br>';

    TranslateSection.value := TranslateSection.value + sLineBreak;
  end;

  TranslateSection.value := TranslateSection.value +
                            generator.template.section_format.postfix_text;
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
