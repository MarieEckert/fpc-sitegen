program sitegen;

uses uGenerator;

const
  SOURCE = 'data/example.sad';
  TEMPLATE = 'data/template.sgt';
  DESTINATION = 'test/index.html';
begin
  uGenerator.GenerateSingle(SOURCE, TEMPLATE, DESTINATION); 
end.
