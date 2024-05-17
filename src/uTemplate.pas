unit uTemplate;

{$H+}

interface

uses SysUtils;

type
  TTemplateError = (teNONE, teNOT_FOUND, tePARSING_ERROR, teUNKNOWN);

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
    '?', 'head-format:', 'sub-head-format:', 'text-format:', 'section-format:', 'output-format',
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
function __ParseLine(cline: String; const nline: Integer; var state: TParseState;
                     var raw_template: TRawTemplate): TTemplateResult;
var
  new_state: TParseState;
  state_changed: Boolean;
begin
  __ParseLine.is_ok   := True;
  __ParseLine.err     := teNONE;
  __ParseLine.err_msg := '';

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

  writeln('state: ', state);
end;

{ --- Public Functions --- }

function Parse(const src: String): TTemplateResult;
var
  state: TParseState;

  res: TTemplate;
  raw_template: TRawTemplate;

  input_file: TextFile;
  cline: String;  { Current line }
  nline: Integer; { Current line number }
begin
  Parse.is_ok   := True;
  Parse.value   := res;
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
    Parse := __ParseLine(cline, nline, state, raw_template);
    if not Parse.is_ok then
      break;

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

  { TODO: Translate Raw Template into TTemplate }
end;

end.
