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
    -V
      Print the version and exit.
    -i <input file>
      Specify the input file. If not set, fpc-sitegen will read from STDIN.
    -o <output file>
      Specify the output file. If not set, fpc-sitegen will read from STDERR.
    -t <template file>
      Specify the template to be used for generation
    -a <mode>
      Automatically insert a html br tag
      mode can be:
        * lf : Causes the tag to be inserted after every linefeed
        * el : Causes the tag to be inserted at every empty line
    -d <name> <file>
      Define a name associated to a file for the insert switch.
}

{$H+}

uses fgl, uGenerator, uShared;

const
  PROGRAM_NAME = 'fpc-sitegen';
  PROGRAM_VERSION = '2.0';
  DEFAULT_TEMPLATE_PATH = 'data/template.sgt';

type
  TCliArgs = record
    input_path    : String;
    output_path   : String;
    template_path : String;

    generator_options : TGeneratorOptions;
  end;

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
  writeln(stderr, '  -V                 Print the version and exit');
  writeln(stderr, '  -i <input file>    Path to the input, if not given STDIN will be used');
  writeln(stderr, '  -o <output file>   Path to the output, if not given STDOUT will be used');
  writeln(stderr, '  -t <template file> Path to the template, if not given "', DEFAULT_TEMPLATE_PATH,
          '" will be used');
  writeln(stderr, '  -a <mode> Automatically insert a html br tag.');
  writeln(stderr, '      mode can be: lf (to insert on every linefeed), el (to insert on every ',
          'empty line)');
  writeln(stderr, '  -d <name> <file>');
  writeln(stderr, '      Define a name associated to a file for the insert switch.');
  writeln;
  halt;
end;

function ParseArguments: TCliArgs;
var
  ix, skip: Integer;
  curr_arg, autobreak_tmp: String;
begin
  ParseArguments.generator_options.file_defs := TStringMap.Create;
  ParseArguments.input_path                  := '';
  ParseArguments.output_path                 := '';
  ParseArguments.template_path               := DEFAULT_TEMPLATE_PATH;

  autobreak_tmp := 'off';

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
      skip := __Handle_Arg(ix, ParseArguments.input_path, '-i')
    else if curr_arg = '-o' then
      skip := __Handle_Arg(ix, ParseArguments.output_path, '-o')
    else if curr_arg = '-t' then
      skip := __Handle_Arg(ix, ParseArguments.template_path, '-t')
    else if (curr_arg = '-a') then
      skip := __Handle_Arg(ix, autobreak_tmp, '-a')
    else if (curr_arg = '-d') then
    begin
      if ix + 2 > ParamCount then
      begin
        writeln(stderr, 'Argument Error');
        writeln(stderr, '==> Missing parameters for "-d", requires two: name & path');
        halt(1);
      end;

      ParseArguments.generator_options.file_defs.Add(ParamStr(ix + 1), ParamStr(ix + 2));
      skip := 2;
    end else if curr_arg = '-V' then
      ShowVersion
    else if (curr_arg = '-?') or (curr_arg = '-h') then
      ShowHelp
    else begin
      writeln(stderr, 'Argument Error');
      writeln(stderr, '==> Invalid argument "', curr_arg, '"');
      halt(1);
    end;
  end;

  ParseArguments.generator_options.preserve_mode := pmSTYLE;
  ParseArguments.generator_options.auto_break    := StrToAutoBreakMode(autobreak_tmp);

  if ParseArguments.generator_options.auto_break = abmINVALID then
  begin
    writeln(stderr, 'Argument Error');
    writeln(stderr, '==> Invalid auto break mode "', autobreak_tmp, '"');
    halt(1);
  end;
end;

var
  res: TGenResult;
  args: TCliArgs;
begin
  args := ParseArguments;

  res := uGenerator.GenerateSingle(args.input_path, args.template_path, args.output_path,
                                   args.generator_options);

  if res.is_ok then
  begin
    halt;
  end;

  writeln(stderr, 'Generation Error: ', res.err);
  writeln(stderr, '==> ', res.err_msg);
  halt(1);
end.
