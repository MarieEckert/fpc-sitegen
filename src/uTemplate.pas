unit uTemplate;

{
  fpc-sitegen -- A more featured replacement for sadhtml

  Copyright (c) 2024, Marie Eckert
  Licensed under the BSD 3-Clause License.
}

{$H+}

interface

uses StrUtils, SysUtils, Types;

type
  TTemplateError = (teNONE, teNOT_FOUND, tePARSING_ERROR, teMISSING_FORMAT, teUNKNOWN);

  {
    Template formatting works by inserting $$CONTENT$$ into your format definition.
    Everything which comes before $$CONTENT$$ is saved as the prefix_text, everything after is
    stored as the postfix_text.
    This means that you can not insert the contents multiple times.
  }
  TTemplateFormat = record
    prefix_text  : String;
    postfix_text : String;
  end;

  TTemplate = record
    title_format        : TTemplateFormat;
    head_format         : TTemplateFormat;
    text_format         : TTemplateFormat;
    section_format      : TTemplateFormat;
    root_section_format : TTemplateFormat;

    { Final format for outputting the finished parsed text }
    output_format       : TTemplateFormat;
  end;

  {
    Contains the unprocessed format definitions
  }
  TRawTemplate = record
    title_format        : String;
    head_format         : String;
    text_format         : String;
    root_section_format : String;
    section_format      : String;
    output_format       : String;
  end;

  TTemplateResult = record
    is_ok   : Boolean;
    value   : TTemplate;
    err     : TTemplateError;
    err_msg : String;
  end;

  TParseState = (psNONE, psTITLE_FORMAT, psHEAD_FORMAT, psTEXT_FORMAT,
                 psSECTION_FORMAT, psROOT_SECTION_FORMAT, psOUTPUT_FORMAT, psERROR);

function Parse(const src: String): TTemplateResult;

const
  labels: array[TParseState] of string = (
    '?', 'title-format:', 'head-format:', 'text-format:', 'section-format:',
    'root-section-format:', 'output-format:', '?'
  );

implementation

{ --- Local Functions --- }

function __LabelToState(lbl: String): TParseState;
var
  ix: TParseState;
begin
  for ix := Low(TParseState) to High(TParseState) do
    if lbl = labels[ix] then
      exit(TParseState(ix));

  exit(psNONE);
end;

{
  Parses a singular line and updates the parser state.
}
procedure __ParseLine(cline: String; const nline: Integer; var state: TParseState;
                      var raw_template: TRawTemplate);
var
  new_state: TParseState;
  state_changed: Boolean;
begin
  new_state := __LabelToState(Trim(cline));
  state_changed := (new_state <> state) and (new_state <> psNONE);

  {
    exit early when the state changes so that we can easily avoid parsing labels
    as part of a format
  }
  if state_changed then
  begin
    state := new_state;
    exit;
  end;

  case state of
    psNONE:
      exit;
    psTITLE_FORMAT:
      raw_template.title_format := raw_template.title_format + cline + sLineBreak;
    psHEAD_FORMAT:
      raw_template.head_format := raw_template.head_format + cline + sLineBreak;
    psTEXT_FORMAT:
      raw_template.text_format := raw_template.text_format + cline + slinebreak;
    psSECTION_FORMAT:
      raw_template.section_format := raw_template.section_format + cline + slinebreak;
    psROOT_SECTION_FORMAT:
      raw_template.root_section_format := raw_template.root_section_format + cline + slinebreak;
    psOUTPUT_FORMAT:
      raw_template.output_format := raw_template.output_format + cline + slinebreak;
    psERROR:
      exit;
  end;
end;

function __SplitOnce(constref src: String; var prefix: String; var postfix: String): Integer;
const
  CONTENT_MARKER = '$$CONTENT$$';
var
  tmp: TStringDynArray;
begin
  tmp := SplitString(src, CONTENT_MARKER);
  if Length(tmp) <> 2 then
    exit(Length(tmp) - 1);

  prefix := tmp[0];
  postfix := tmp[1];
  exit(1);
end;

function __TranslateRawTemplate(raw: TRawTemplate): TTemplateResult;
var
  res: TTemplate;
  n: Integer;
  format: String;
label
  invalid;
begin
  __TranslateRawTemplate.is_ok   := (Length(raw.title_format) > 0) and
                                    (Length(raw.head_format) > 0) and
                                    (Length(raw.text_format) > 0) and
                                    (Length(raw.section_format) > 0) and
                                    (Length(raw.output_format) > 0);

  if not __TranslateRawTemplate.is_ok then
  begin
    __TranslateRawTemplate.err     := teMISSING_FORMAT;
    __TranslateRawTemplate.err_msg := 'the template is missing one or more formats!';
    exit;
  end
  else begin
    __TranslateRawTemplate.err     := teNONE;
    __TranslateRawTemplate.err_msg := '';
  end;

  { TODO: Maybe add escaping of $$CONTENT$$ ? }

  format := 'title-format';
  n := __SplitOnce(raw.title_format, res.title_format.prefix_text, res.title_format.postfix_text);
  if n <> 1 then goto invalid;

  format := 'head-format';
  n := __SplitOnce(raw.head_format, res.head_format.prefix_text, res.head_format.postfix_text);
  if n <> 1 then goto invalid;

  format := 'text-format';
  n := __SplitOnce(raw.text_format, res.text_format.prefix_text, res.text_format.postfix_text);
  if n <> 1 then goto invalid;

  format := 'section-format';
  n := __SplitOnce(
    raw.section_format,
    res.section_format.prefix_text,
    res.section_format.postfix_text
  );
  if n <> 1 then goto invalid;

  if Length(raw.root_section_format) > 0 then
  begin
  format := 'root-section-format';
    n := __SplitOnce(
              raw.root_section_format,
              res.root_section_format.prefix_text,
              res.root_section_format.postfix_text
      );
    if n <> 1 then goto invalid;
  end else
  begin
    res.root_section_format.prefix_text := res.section_format.prefix_text;
    res.root_section_format.postfix_text := res.section_format.postfix_text;
  end;

  format := 'output-format';
  n := __SplitOnce(
    raw.output_format,
    res.output_format.prefix_text,
    res.output_format.postfix_text
  );
  if n <> 1 then goto invalid;

  __TranslateRawTemplate.value := res;
  exit;

invalid:
  __TranslateRawTemplate.is_ok := False;
  __TranslateRawTemplate.err := tePARSING_ERROR;
  __TranslateRawTemplate.err_msg :=
    'expecting exactly 1 instance of $$CONTENT$$ in ' + format + ', found ' + IntToStr(n);
end;

{ --- Public Functions --- }

function Parse(const src: String): TTemplateResult;
var
  state: TParseState;

  raw_template: TRawTemplate;

  input_file: TextFile;
  cline: String;  { Current line }
  nline: Integer; { Current line number }
begin
  Parse.is_ok   := True;
  Parse.err     := teNONE;
  Parse.err_msg := '';

  if not FileExists(src, True) then
  begin
    Parse.is_ok   := False;
    Parse.err     := teNOT_FOUND;
    Parse.err_msg := 'can''t open template: No such file or directory.';
    exit;
  end;

  { Parse in Raw Template }

  Assign(input_file, src);
  ReSet(input_file);

  state := psNONE;

  nline := 0;
  while not eof(input_file) do
  begin
    readln(input_file, cline);
    Inc(nline);
    __ParseLine(cline, nline, state, raw_template);

    if state = psERROR then
    begin
      Parse.is_ok := False;
      Parse.err   := teUNKNOWN;
      Parse.err_msg := Format('A template-parsing error occured (line %d)', [nline]);
      break;
    end;
  end;

  Close(input_file);

  if not Parse.is_ok then
    exit;

  Parse := __TranslateRawTemplate(raw_template);
end;

end.
