program sitegen;

{
  fpc-sitegen -- A more featured replacement for sadhtml

  Copyright (c) 2024, Marie Eckert
  Licensed under the BSD 3-Clause License.

  SYNOPSIS
    fpc-sitegen [-i <input file>] [-o <output file>] [additional options]

  ABOUT
  fpc-sitegen takes in a simple-ansi-document (see https://github.com/FelixEcker/sad) and a
  .sgt (sitegen template) to generate a final document.

  Templates define formatting for every kind of SAD switch, see data/template.sgt for a simple
  example of a template to convert to HTML.

  OPTIONS
    -i <input file>
      Specify the input file. If not set, fpc-sitegen will read from STDIN.
    -o <output file>
      Specify the output file. If not set, fpc-sitegen will read from STDERR.
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
    writeln(stderr, 'Argument Error');
    writeln(stderr, '==> Missing filename for argument "', name,'"');
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
  writeln(stderr, 'usage: fpc-sitgen [-i <input file>] [-o <output file>] [additional options]');
  writeln;
  writeln(stderr, 'OPTIONS');
  writeln(stderr, '  -i <input file>    Path to the input, if not given STDIN will be used');
  writeln(stderr, '  -o <output file>   Path to the output, if not given STDOUT will be used');
  writeln(stderr, '  -t <template file> Path to the template, if not given "', DEFAULT_TEMPLATE_PATH,
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
      writeln(stderr, 'Argument Error');
      writeln(stderr, '==> Invalid argument "', curr_arg, '"');
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

  writeln(stderr, 'Generation Error: ', res.err);
  writeln(stderr, '==> ', res.err_msg);
  halt(1);
end.
