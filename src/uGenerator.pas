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
    value   : String;
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

{
  All __Translate functions are intended to append to TGenResult.value, except
  for __TranslateSource (whose job is to begin translation
}

function __TranslateTitle(generator: TGenerator): TGenResult;
begin
  __TranslateTitle.is_ok   := True;
  __TranslateTitle.err     := geNONE;
  __TranslateTitle.err_msg := '';
end;

function __TranslateHeader(generator: TGenerator; header: String): TGenResult;
begin
  __TranslateHeader.is_ok   := True;
  __TranslateHeader.err     := geNONE;
  __TranslateHeader.err_msg := '';
end;

function __TranslateSubHeader(generator: TGenerator; header: String): TGenResult;
begin
  __TranslateSubHeader.is_ok   := True;
  __TranslateSubHeader.err     := geNONE;
  __TranslateSubHeader.err_msg := '';
end;

function __TranslateSection(generator: TGenerator; section: TSection): TGenResult;
begin
  __TranslateSection.is_ok   := True;
  __TranslateSection.err     := geNONE;
  __TranslateSection.err_msg := '';
end;

function __TranslateSource(generator: TGenerator): TGenResult;
begin
  __TranslateSource.is_ok   := True;
  __TranslateSource.err     := geNONE;
  __TranslateSource.err_msg := '';

  __TranslateSource.value := generator.template.output_format.prefix_text;

  __TranslateSource := __TranslateTitle(generator);
  if not __TranslateSource.is_ok then
    exit;

  __TranslateSource := __TranslateSection(generator, generator.source.root_section);
  if not __TranslateSource.is_ok then
    exit;

  __TranslateSource.value := generator.template.output_format.postfix_text;
end;

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

  GenerateSingle := __TranslateSource(generator);
end;

end.
