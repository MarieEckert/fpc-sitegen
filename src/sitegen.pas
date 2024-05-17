program sitegen;

{
  fpc-sitegen -- A more featured replacement for sadhtml

  ABOUT
  fpc-sitgen takes in a simple-ansi-document (see https://github.com/FelixEcker/sad) and a
  .sgt (sitegen template) to generate a final document.

  Templates define formatting for every kind of SAD switch, see data/template.sgt for a simple
  example of a template to convert to HTML.
}

uses uGenerator;

const
  SOURCE = 'data/example.sad';
  TEMPLATE = 'data/template.sgt';
  DESTINATION = 'test/index.html';
var
  res: TGenResult;
begin
  res := uGenerator.GenerateSingle(SOURCE, TEMPLATE, DESTINATION); 

  if res.is_ok then
    halt;

  writeln('Generation Error: ', res.err);
  writeln('==> ', res.err_msg);
  halt(1);
end.
