unit uShared;

{$H+}

interface

uses uTemplate, uSADParser;

type
  TGeneratorOptions = record
    auto_break: Boolean; { True: automatically inserts <br> tags on line-breaks }
  end;

  TGenerator = record
    template : TTemplate;
    source   : TSADocument;
    options  : TGeneratorOptions;
  end;

implementation
end.
