unit uTemplate;

{$H+}

interface

type
  TTemplateError = (teNONE, teNOT_FOUND, tePARSING_ERROR);
  
  TTemplate = record
  end;

  TTemplateResult = record
    is_ok   : Boolean;
    value   : TTemplate;
    err     : TTemplateError;
    err_msg : String;
  end;

function Parse(const src: String): TTemplateResult;

implementation

function Parse(const src: String): TTemplateResult;
begin
end;

end.
