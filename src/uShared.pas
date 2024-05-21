unit uShared;

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
