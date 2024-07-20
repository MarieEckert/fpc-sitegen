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

  TGeneratorOptions = record
    auto_break    : Boolean; { True: automatically inserts <br> tags on line-breaks }
    preserve_mode : TPreserveMode;
  end;

  TGenerator = record
    template : TTemplate;
    source   : TSADocument;
    options  : TGeneratorOptions;
  end;

implementation
end.
