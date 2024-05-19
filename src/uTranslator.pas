unit uTranslator;

{$H+}

interface

uses StrUtils, SysUtils, Types, uSADParser, uShared;

type
  TTranslateError = (treNONE, treUNKNOWN, treINVALID_SYNTAX);

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

function TranslateHeader(generator: TGenerator; header: String): TTranslateResult;
function TranslateSubHeader(generator: TGenerator; header: String): TTranslateResult;
function TranslateSection(generator: TGenerator; section: TSection): TTranslateResult;
function TranslateSource(generator: TGenerator): TTranslateResult;

implementation

function TranslateHeader(generator: TGenerator; header: String): TTranslateResult;
begin
  TranslateHeader.is_ok   := True;
  TranslateHeader.err     := treNONE;
  TranslateHeader.err_msg := '';
end;

function TranslateSubHeader(generator: TGenerator; header: String): TTranslateResult;
begin
  TranslateSubHeader.is_ok   := True;
  TranslateSubHeader.err     := treNONE;
  TranslateSubHeader.err_msg := '';
end;

function TranslateSection(generator: TGenerator; section: TSection): TTranslateResult;
const
  SECTION_NAME_MARKER = '$$SECTION_NAME$$';
  SECTION_START_MARKER = '$$SECTION_START$$';
var
  nline, child_ix: Integer;
  prefix, cline, _word: String;
  lines, words: TStringDynArray;

  in_text: Boolean;
begin
  TranslateSection.is_ok   := True;
  TranslateSection.err     := treNONE;
  TranslateSection.err_msg := '';

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

    for _word in words do
    begin
      case _word of
        SECTION_START_MARKER: begin
          if in_text then
          begin
            in_text := False;
            TranslateSection.value := TranslateSection.value +
                                      generator.template.text_format.postfix_text;
          end;

          TranslateSection := TranslateSection(generator, section.children[child_ix]);
          if not TranslateSection.is_ok then
            exit;
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

  TranslateSource := TranslateSection(generator, generator.source.root_section);
  if not TranslateSource.is_ok then
    exit;

  TranslateSource.value := TranslateSource.value + generator.template.output_format.postfix_text;
  TranslateSource.value := StringReplace(TranslateSource.value, DOCUMENT_TITLE_MARKER,
                                         generator.source.title, [rfReplaceAll]);
end;

end.
