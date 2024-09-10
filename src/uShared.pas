unit uShared;

{
  fpc-sitegen -- A more featured replacement for sadhtml

  Copyright (c) 2024, Marie Eckert
  Licensed under the BSD 3-Clause License.
}

{$H+}

interface

uses uTemplate, uSADParser;

type
  TPreserveMode = (pmCOLOR, pmSTYLE);

  TAutoBreakMode = (abmOFF, abmLF, abmEL, abmINVALID);

  TGeneratorOptions = record
    auto_break    : TAutoBreakMode;
    preserve_mode : TPreserveMode;
  end;

  TGenerator = record
    template : TTemplate;
    source   : TSADocument;
    options  : TGeneratorOptions;
  end;

function StrToAutoBreakMode(_str: String): TAutoBreakMode;

implementation

function StrToAutoBreakMode(_str: String): TAutoBreakMode;
begin
  _str := LowerCase(_str);

  if _str = 'off' then
    exit(abmOFF);
  if _str = 'lf' then
    exit(abmLF);
  if _str = 'el' then
    exit(abmEL);

  exit(abmINVALID);
end;

end.
