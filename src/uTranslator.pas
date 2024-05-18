unit uTranslator;

{$H+}

interface

uses uSADParser, uShared;

type
  TTranslateError = (treNONE, treUNKNOWN, treINVALID_SYNTAX);
  
  TTranslateResult = record
    is_ok   : Boolean;
    err     : TTranslateError;
    err_msg : String;
    value   : String;
  end;

{
  All Translate functions are intended to append to TTranslateResult.value, except
  for TranslateSource (whose job is to begin translation
}

function TranslateTitle(generator: TGenerator): TTranslateResult;
function TranslateHeader(generator: TGenerator; header: String): TTranslateResult;
function TranslateSubHeader(generator: TGenerator; header: String): TTranslateResult;
function TranslateSection(generator: TGenerator; section: TSection): TTranslateResult;
function TranslateSource(generator: TGenerator): TTranslateResult;

implementation


function TranslateTitle(generator: TGenerator): TTranslateResult;
begin
  TranslateTitle.is_ok   := True;
  TranslateTitle.err     := treNONE;
  TranslateTitle.err_msg := '';
end;

function TranslateHeader(generator: TGenerator; header: String): TTranslateResult;
begin
  TranslateHeader.is_ok   := True;
  TranslateHeader.err     := treNONE;
  TranslateHeader.err_msg := '';
end;

function TranslateSubHeader(generator: TGenerator; header: String): TTranslateResult;
begin
  TranslateSubHeader.is_ok   := True;
  TranslateSubHeader.err     := treNONE;
  TranslateSubHeader.err_msg := '';
end;

function TranslateSection(generator: TGenerator; section: TSection): TTranslateResult;
begin
  TranslateSection.is_ok   := True;
  TranslateSection.err     := treNONE;
  TranslateSection.err_msg := '';
end;

function TranslateSource(generator: TGenerator): TTranslateResult;
begin
  TranslateSource.is_ok   := True;
  TranslateSource.err     := treNONE;
  TranslateSource.err_msg := '';

  TranslateSource.value := generator.template.output_format.prefix_text;

  TranslateSource := TranslateTitle(generator);
  if not TranslateSource.is_ok then
    exit;

  TranslateSource := TranslateSection(generator, generator.source.root_section);
  if not TranslateSource.is_ok then
    exit;

  TranslateSource.value := generator.template.output_format.postfix_text;
end;

end.
