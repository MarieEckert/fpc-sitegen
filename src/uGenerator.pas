unit uGenerator;

{$H+}

interface

uses SysUtils, uSADParser, uTemplate;

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

  generator.template := template_res.value;

  if not FileExists(src) then
  begin
    GenerateSingle.is_ok   := False;
    GenerateSingle.err     := geSRC_NOT_FOUND;
    GenerateSingle.err_msg := 'can''t open source: No such file or directory';
    exit;
  end;

  Assign(generator.source.doc_file, src);
  ReSet(generator.source.doc_file);
  if not ParseStructure(generator.source) then
  begin
    GenerateSingle.is_ok   := False;
    GenerateSingle.err     := geSRC_PARSING_ERROR;
    GenerateSingle.err_msg := Format('failed to parse source %s:%d: %s', [
                                  src,
                                  generator.source.line_number,
                                  uSADParser.parse_error
                                ]
                              );
    exit;
  end;
end;

end.
