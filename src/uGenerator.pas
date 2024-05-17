unit uGenerator;

{$H+}

interface

uses uSADParser, uTemplate;

type
  TGenError = (geNONE, geUNKNOWN, geSRC_NOT_FOUND, geTEMPLATE_NOT_FOUND, geSRC_PARSING_ERROR,
               geTEMPLATE_PARSING_ERROR, geTRANSLATION_ERROR, geTEMPLATE_INCOMPLETE);

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

const
  TEMPLATE_TO_GEN_ERRORS: array[TTemplateError] of TGenError = (
    geNONE, geTEMPLATE_NOT_FOUND, geTEMPLATE_PARSING_ERROR, geTEMPLATE_INCOMPLETE, geUNKNOWN
  );

implementation

{ --- Local Functions --- }

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
    GenerateSingle.err     := TEMPLATE_TO_GEN_ERRORS[template_res.err];
    GenerateSingle.err_msg := template_res.err_msg;
    exit;
  end;

  template := template_res.value;


end;

end.
