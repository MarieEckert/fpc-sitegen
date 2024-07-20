program sitegen;

{
  fpc-sitegen -- A more featured replacement for sadhtml

  SYNOPSIS
    fpc-sitegen [-i <input file>] [-o <output file>] [additional options]

  ABOUT
  fpc-sitgen takes in a simple-ansi-document (see https://github.com/FelixEcker/sad) and a
  .sgt (sitegen template) to generate a final document.

  Templates define formatting for every kind of SAD switch, see data/template.sgt for a simple
  example of a template to convert to HTML.

  OPTIONS
    -t <template file>
      Specify the template to be used for generation
}

{$H+}

uses uGenerator;

const
  PROGRAM_NAME = 'fpc-sitegen';
  PROGRAM_VERSION = '0.1';
  DEFAULT_TEMPLATE_PATH = 'data/template.sgt';

function __Handle_Arg(const ix: Integer; var dest: String; const name: String): Integer;
begin
  __Handle_Arg := 0;
  if ix + 1 > ParamCount then
  begin
    writeln('Argument Error');
    writeln('==> Missing filename for argument "', name,'"');
    halt(1);
  end;

  dest := ParamStr(ix+1);

  inc(__Handle_Arg);
end;

procedure ShowVersion;
begin
  writeln(PROGRAM_NAME, ' v', PROGRAM_VERSION);
  writeln;
  halt;
end;

procedure ShowHelp;
begin
  writeln('usage: fpc-sitgen [-i <input file>] [-o <output file>] [additional options]');
  writeln;
  writeln('OPTIONS');
  writeln('  -i <input file>    Path to the input, if not given STDIN will be used');
  writeln('  -o <output file>   Path to the output, if not given STDOUT will be used');
  writeln('  -t <template file> Path to the template, if not given "', DEFAULT_TEMPLATE_PATH,
          '" will be used');
  writeln;
  halt;
end;

procedure ParseArguments(var input_path: String; var output_path: String;
                         var template_path: String);
var
  ix, skip: Integer;
  curr_arg: String;
begin
  skip := 0;

  for ix := 1 to ParamCount do
  begin
    if skip > 0 then
    begin
      dec(skip);
      continue;
    end;

    curr_arg := ParamStr(ix);

    if curr_arg = '-i' then
      skip := __Handle_Arg(ix, input_path, '-i')
    else if curr_arg = '-o' then
      skip := __Handle_Arg(ix, output_path, '-o')
    else if curr_arg = '-t' then
      skip := __Handle_Arg(ix, template_path, '-o')
    else if curr_arg = '-V' then
      ShowVersion
    else if (curr_arg = '-?') or (curr_arg = '-h') then
      ShowHelp
    else begin
      writeln('Argument Error');
      writeln('==> Invalid argument "', curr_arg, '"');
      halt(1);
    end;
  end;
end;

var
  res: TGenResult;
  input_path, output_path, template_path: String;
begin
  template_path := DEFAULT_TEMPLATE_PATH;

  ParseArguments(input_path, output_path, template_path);

  res := uGenerator.GenerateSingle(input_path, template_path, output_path); 

  if res.is_ok then
  begin
    halt;
  end;

  writeln('Generation Error: ', res.err);
  writeln('==> ', res.err_msg);
  halt(1);
end.
