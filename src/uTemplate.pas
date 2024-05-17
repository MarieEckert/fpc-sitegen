unit uTemplate;

{$H+}

interface

uses SysUtils;

type
  TTemplateError = (teNONE, teNOT_FOUND, tePARSING_ERROR);
  
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

  TTemplateResult = record
    is_ok   : Boolean;
    value   : TTemplate;
    err     : TTemplateError;
    err_msg : String;
  end;

  TParseState = (psNONE, psHEAD_FORMAT, psSUB_HEAD_FORMAT, psTEXT_FORMAT, psSECTION_FORMAT,
                 psOUTPUT_FORMAT);

function Parse(const src: String): TTemplateResult;

implementation

function Parse(const src: String): TTemplateResult;
var
  state: TParseState;
  res: TTemplate;
  input_file: TextFile;
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

  state := psNONE;
end;

end.
