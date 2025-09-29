unit uGenerator;

{
  fpc-sitegen -- A more featured replacement for sadhtml

  Copyright (c) 2024, Marie Eckert
  Licensed under the BSD 3-Clause License.
}

{$H+}

interface

uses sad, SysUtils, uShared, uTemplate, uTranslator;

type
  TGenError = (geNONE, geUNKNOWN, geSRC_NOT_FOUND, geTEMPLATE_NOT_FOUND, geSRC_PARSING_ERROR,
               geTEMPLATE_PARSING_ERROR, geTRANSLATION_ERROR, geTEMPLATE_INCOMPLETE);

  TGenElement = record
    src      : String;
    template : String;
    out      : String;
  end;

  TGenElementDynArray = array of TGenElement;

  TGenResult = record
    is_ok   : Boolean;
    err     : TGenError;
    err_msg : String;
  end;

function GenerateSingle(const src: String; const template_src: String; const out: String;
                        const opts: TGeneratorOptions)
                       : TGenResult;

const
  TEMPLATE_TO_GEN_ERRORS: array[TTemplateError] of TGenError = (
    geNONE, geTEMPLATE_NOT_FOUND, geTEMPLATE_PARSING_ERROR, geTEMPLATE_INCOMPLETE, geUNKNOWN
  );
  TRANSLATE_TO_GEN_ERRORS: array[TTranslateError] of TGenError = (
    geNONE, geUNKNOWN, geTRANSLATION_ERROR, geUNKNOWN, geTRANSLATION_ERROR, geTRANSLATION_ERROR,
    geTRANSLATION_ERROR
  );

implementation

{ --- Local Functions --- }


{ --- Public Functions --- }

function GenerateSingle(const src: String; const template_src: String; const out: String;
                        const opts: TGeneratorOptions)
                       : TGenResult;
var
  generator: TGenerator;
  template_res: TTemplateResult;
  translate_res: TTranslateResult;
  source_file: TextFile;
  output_file: TextFile;
  parseRes: sad.TParseResult;
begin
  generator.options := opts;

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

  if (not FileExists(src)) and (Length(src) > 0) then
  begin
    GenerateSingle.is_ok   := False;
    GenerateSingle.err     := geSRC_NOT_FOUND;
    GenerateSingle.err_msg := 'can''t open source: No such file or directory';
    exit;
  end;

  if Length(src) > 0 then
  begin
    Assign(source_file, src);
    ReSet(source_file);
  end else
    source_file := Input;

  parseRes := sad.ParseOpenFile(source_file);
  if parseRes.status <> TParseStatus.Ok then
  begin
    GenerateSingle.is_ok   := False;
    GenerateSingle.err     := geSRC_PARSING_ERROR;
    GenerateSingle.err_msg := Format('failed to parse source %s', [
                                  MakeResultString(parseRes, src)
                                ]
                              );
    exit;
  end;

  Close(source_file);

  generator.source := parseRes.document;

  translate_res := uTranslator.TranslateSource(generator);
  GenerateSingle.is_ok   := translate_res.is_ok;
  GenerateSingle.err     := TRANSLATE_TO_GEN_ERRORS[translate_res.err];
  GenerateSingle.err_msg := translate_res.err_msg;

  if not GenerateSingle.is_ok then
    exit;

  Assign(output_file, out);
  ReWrite(output_file);
  Write(output_file, translate_res.value);
  Close(output_file);
end;

end.
