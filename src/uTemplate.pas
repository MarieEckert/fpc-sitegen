unit uTemplate;

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
    head_format     : TTemplateFormat;
    sub_head_format : TTemplateFormat;
    text_format     : TTemplateFormat;
    section_format  : TTemplateFormat;

    { Final format for outputting the finished parsed text }
    output_format   : TTemplateFormat;
  end;

  {
    Contains the unprocessed format definitions
  }
  TRawTemplate = record
    head_format     : String;
    sub_head_format : String;
    text_format     : String;
    section_format  : String;
    output_format   : String;
  end;

  TTemplateResult = record
    is_ok   : Boolean;
    value   : TTemplate;
    err     : TTemplateError;
    err_msg : String;
  end;

  TParseState = (psNONE, psHEAD_FORMAT, psSUB_HEAD_FORMAT, psTEXT_FORMAT, psSECTION_FORMAT,
                 psOUTPUT_FORMAT, psERROR);

function Parse(const src: String): TTemplateResult;

const
  labels: array[TParseState] of string = (
    '?', 'head-format:', 'sub-head-format:', 'text-format:', 'section-format:', 'output-format:',
    '?'
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
    psHEAD_FORMAT:
      raw_template.head_format := raw_template.head_format + cline + sLineBreak;
    psSUB_HEAD_FORMAT:
      raw_template.sub_head_format := raw_template.sub_head_format + cline + sLineBreak;
    psTEXT_FORMAT:
      raw_template.text_format := raw_template.text_format + cline + slinebreak;
    psSECTION_FORMAT:
      raw_template.section_format := raw_template.section_format + cline + slinebreak;
    psOUTPUT_FORMAT:
      raw_template.output_format := raw_template.output_format + cline + slinebreak;
    psERROR:
      exit;
  end;
end;

function __TranslateRawTemplate(raw: TRawTemplate): TTemplateResult;
const
  CONTENT_MARKER = '$$CONTENT$$';
var
  res: TTemplate;
  tmp: TStringDynArray;
begin
  __TranslateRawTemplate.is_ok   := (Length(raw.head_format) > 0) and
                                    (Length(raw.sub_head_format) > 0) and
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

  tmp := SplitString(raw.head_format, CONTENT_MARKER);
  res.head_format.prefix_text := tmp[0];
  res.head_format.postfix_text := tmp[1];

  tmp := SplitString(raw.sub_head_format, CONTENT_MARKER);
  res.sub_head_format.prefix_text := tmp[0];
  res.sub_head_format.postfix_text := tmp[1];

  tmp := SplitString(raw.text_format, CONTENT_MARKER);
  res.text_format.prefix_text := tmp[0];
  res.text_format.postfix_text := tmp[1];

  tmp := SplitString(raw.section_format, CONTENT_MARKER);
  res.section_format.prefix_text := tmp[0];
  res.section_format.postfix_text := tmp[1];

  tmp := SplitString(raw.output_format, CONTENT_MARKER);
  res.output_format.prefix_text := tmp[0];
  res.output_format.postfix_text := tmp[1];

  __TranslateRawTemplate.value := res;
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
