unit uGenerator;

{$H+}

interface

uses SysUtils, uSADParser, uShared, uTemplate, uTranslator;

type
  TGenError = (geNONE, geUNKNOWN, geSRC_NOT_FOUND, geTEMPLATE_NOT_FOUND, geSRC_PARSING_ERROR,
               geTEMPLATE_PARSING_ERROR, geTRANSLATION_ERROR, geTEMPLATE_INCOMPLETE);

  TGenResult = record
    is_ok   : Boolean;
    err     : TGenError;
    err_msg : String;
    value   : String;
  end;

function GenerateSingle(const src: String; const template_src: String; const out: String)
                       : TGenResult;

const
  TEMPLATE_TO_GEN_ERRORS: array[TTemplateError] of TGenError = (
    geNONE, geTEMPLATE_NOT_FOUND, geTEMPLATE_PARSING_ERROR, geTEMPLATE_INCOMPLETE, geUNKNOWN
  );
  TRANSLATE_TO_GEN_ERRORS: array[TTranslateError] of TGenError = (
    geNONE, geUNKNOWN, geTRANSLATION_ERROR, geUNKNOWN, geTRANSLATION_ERROR, geTRANSLATION_ERROR
  );

implementation

{ --- Local Functions --- }


{ --- Public Functions --- }

function GenerateSingle(const src: String; const template_src: String; const out: String)
                       : TGenResult;
var
  generator: TGenerator;
  template_res: TTemplateResult;
  translate_res: TTranslateResult;
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
  if not uSADParser.ParseStructure(generator.source) then
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

  generator.options.auto_break := True;
  generator.options.preserve_mode := pmSTYLE;

  translate_res := uTranslator.TranslateSource(generator);
  GenerateSingle.is_ok   := translate_res.is_ok;
  GenerateSingle.err     := TRANSLATE_TO_GEN_ERRORS[translate_res.err];
  GenerateSingle.err_msg := translate_res.err_msg;
  GenerateSingle.value   := translate_res.value;
end;

end.
