unit uGenerator;

{$H+}

interface

uses uSADParser, uTemplate;

type
  TGenError = (geNONE, geUNKNOWN, geSRC_NOT_FOUND, geTEMPLATE_NOT_FOUND, geSRC_PARSING_ERROR, 
               geTEMPLATE_PARSING_ERROR, geTRANSLATION_ERROR);

  TGenResult = record
    is_ok   : Boolean;
    err     : TGenError;
    err_msg : String;
  end;

  TGenerator = record
    template : TTemplate;
    source   : TSADocument;
  end;

function GenerateSingle(const src: String; const template_src: String; const out: String)
                       : TGenResult;

implementation

{ --- Local Functions --- }

function __TemplateErrorToGenError(const err: TTemplateError): TGenError;
begin
  case err of
    teNONE: exit(geNONE);
    teNOT_FOUND: exit(geTEMPLATE_NOT_FOUND);
    tePARSING_ERROR: exit(geTEMPLATE_PARSING_ERROR);
  else
    exit(geUNKNOWN);
  end;
end;

{ --- Public Functions --- }

function GenerateSingle(const src: String; const template_src: String; const out: String)
                       : TGenResult;
var
  generator: TGenerator;
  template_res: TTemplateResult;
  template: TTemplate;
begin
  GenerateSingle.is_ok   := True;
  GenerateSingle.err     := geNONE;
  GenerateSingle.err_msg := '';

  template_res := uTemplate.Parse(template_src);
  if not template_res.is_ok then
  begin
    GenerateSingle.is_ok   := False;
    GenerateSingle.err     := __TemplateErrorToGenError(template_res.err);
    GenerateSingle.err_msg := template_res.err_msg;
    exit;
  end;

  template := template_res.value;

  
end;

end.
