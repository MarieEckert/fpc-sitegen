{$mode fpc}
unit uSADParser;

{ uSADParser.pp ; Parsing functions for simple-ansi-documents }
{ Author: Marie Eckert                                        }

(* Copyright (c) 2022, Marie Eckert                                           *)
(*                                                                            *)
(* Redistribution and use in source and binary forms, with or without         *)
(* modification, are permitted provided that the following conditions are met:*)
(*                                                                            *)
(* 1. Redistributions of source code must retain the above copyright notice,  *)
(* this list of conditions and the following disclaimer.                      *)
(*                                                                            *)
(* 2. Redistributions in binary form must reproduce the above copyright       *)
(*    notice, this list of conditions and the following disclaimer in the     *)
(*    documentation   and/or other materials provided with the distribution.  *)
(*                                                                            *)
(* 3. Neither the name of the copyright holder nor the names of its           *)
(*    contributors may be used to endorse or promote products derived from    *)
(*    this software without specific prior written permission.                *)
(*                                                                            *)
(* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS        *)
(* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED  *)
(* TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR *)
(* PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR          *)
(* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,      *)
(* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,        *)
(* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;*)
(* OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,   *)
(* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR    *)
(* OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF     *)
(* ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                                 *)

{$H+}

interface
  uses SysUtils, StrUtils, Types, uANSIUtils;

  type
    PSADocument = ^TSADocument;

    TSection = record
      owning_document : PSADocument;
      name            : String;
      children        : array of TSection;
      contents        : String;
    end;

    PSection = ^TSection;
    TPSectionDynArray = array of PSection;

    TMetaData = record
      name    : String;
      content : String;
    end;
    TMetaDataDynArray = array of TMetaData;

    TSADocument = record
      doc_file      : TextFile;
      current_line  : String;
      line_number   : Integer;
      meta_data     : TMetaDataDynArray;
      root_section  : TSection;
      title         : String;
      preserve_mode : String;
    end;

  function MergeStringArray(AArray: TStringDynArray;
                            const AJoinStr: String): String;
  function FindSection(const ADocument: TSADocument;
                     const AName: String): TSection;
  function FindSectionByPath(const ADocument: TSADocument;
                             const APath: String): TSection;
  function ParseStructure(var ADocument: TSADocument): Boolean;
  function ParseSection(const ASection: TSection;
                        const ADoChildren: Boolean): String;
{$IFDEF DEBUG}
  procedure DebugPrintDocument(const ADocument: TSADocument);
{$ENDIF}

  const
    { Constants of valid switches }
    DEFINE_META    = '{$meta';
    START_DOCUMENT = '{$start}';
    DOCUMENT_TITLE = '{$title}';
    PRESERVE_MODE  = '{$preserve-mode';
    SECTION_BEGIN  = '{$begin-section}';
    SECTION_END    = '{$end-section}';
    HEADER         = '{$head}';
    SUB_HEADER     = '{$sub-head}';
    STYLE          = '{$style';
    COLOR          = '{$color';
    RESET_         = '{$reset}';
    RESET_ALL      = '{$reset-all}';

    { Styling Constants }
    STYLE_HEADER     = STYLE_BOLD+STYLE_UNDERLINE;
    STYLE_SUB_HEADER = STYLE_UNDERLINE;

  var
    parse_error : String;
implementation
  { Private Functions and Procedures }

  procedure SetupSection(var ASection: TSection; const AName: String);
  begin
    ASection.name := AName;
    ASection.contents := '';
    SetLength(ASection.children, 0);
  end;

  procedure AddSectionChild(var ASection: TSection; const AChild: TSection);
  begin
    SetLength(ASection.children, Length(ASection.children)+1);
    ASection.children[HIGH(ASection.children)] := AChild;
  end;

  { Public Functions and Procedures }


  function MergeStringArray(AArray: TStringDynArray;
                            const AJoinStr: String): String;
  var
    str: String;
  begin
    MergeStringArray := '';
    MergeStringArray := '';
    if Length(AArray) < 1 then exit;

    MergeStringArray := AArray[0];
    AArray := Copy(AArray, 1, Length(AArray)-1);

    for str in AArray do
      MergeStringArray := MergeStringArray + AJoinStr + str;
  end;

  function FindSection(const ADocument: TSADocument;
                     const AName: String): TSection;
    (* Local function for recursive section search *)
    function _FindSection(const ASec: TSection; const ASecName: String): TSection;
    var
      sec: TSection;
    begin
      _FindSection := ASec;
      for sec in ASec.children do
      begin
        if sec.name = ASecName then
        begin
          _FindSection := sec;
          exit;
        end;
      end;

      for sec in ASec.children do
        _FindSection := _FindSection(sec, ASecName);
    end;
  begin

    FindSection := ADocument.root_section;
    if AName = '.' then exit;

    FindSection := _FindSection(ADocument.root_section, AName);
  end;

  function FindSectionByPath(const ADocument: TSADocument;
                             const APath: String): TSection;
  var
    path_split: TStringDynArray;
    elem: String;
    curr_sec: PSection;
    sec: TSection;
  begin
    path_split := SplitString(APath, ':');
    
    curr_sec := @ADocument.root_section;
    for elem in path_split do
    begin
      for sec in curr_sec^.children do
      begin
        if sec.name = elem then
        begin
          curr_sec := @sec;
          break;
        end;
      end;
    end;

    exit(curr_sec^);
  end;

  function ParseStructure(var ADocument: TSADocument): Boolean;
  var
    finished_head: Boolean;
    section_path: TPSectionDynArray;
    {curr_section: PSection;}
    tmp_section: TSection;
    split_line: TStringDynArray;
  begin
    ParseStructure := False;

    { Clean Document }
    ADocument.current_line := '';
    ADocument.line_number  := 0;
    SetupSection(ADocument.root_section, '.');
    ADocument.root_section.owning_document := @ADocument;

    if (ADocument.preserve_mode <> STYLE)
    and (ADocument.preserve_mode <> COLOR) then
      ADocument.preserve_mode := '';

    if TTextRec(ADocument.doc_file).Handle = 0 then
    begin
      parse_error := 'No TextFile assigned to ADocument.doc_file!';
      exit;
    end;

    { The section_path holds the internal indexes of the sections we are
      currently in }
    SetLength(section_path, 1);
    section_path[0] := @ADocument.root_section;
    {curr_section := section_path[0];}

    finished_head := False;
    while not eof(ADocument.doc_file) do
    begin
      inc(ADocument.line_number);
      readln(ADocument.doc_file, ADocument.current_line);

      if (Length(ADocument.current_line) = 0)
      or (Trim(ADocument.current_line) = '') then
        continue;

      split_line := SplitString(ADocument.current_line, ' ');

      case split_line[0] of
      DEFINE_META: begin
        if finished_head then
        begin
          parse_error := 'Meta-Data can only be delcared inside the '+
                         'document head!';
          exit;
        end;

        if Length(split_line) = 1 then
        begin
          parse_error := 'The Meta-Data switch requires a Name!';
          exit;
        end;

        SetLength(ADocument.meta_data, Length(ADocument.meta_data)+1);
        ADocument.meta_data[HIGH(ADocument.meta_data)].name :=
          Copy(split_line[1], 1, Length(split_line[1])-1);

        if Length(split_line) = 2 then
          continue;

        ADocument.meta_data[HIGH(ADocument.meta_data)].content :=
          MergeStringArray(Copy(split_line, 2, Length(split_line)-1), ' ');
      end;
      START_DOCUMENT: begin
        if finished_head then
        begin
          parse_error := 'Cannot start document body twice!';
          exit;
        end;

        finished_head := True;
      end;
      DOCUMENT_TITLE: begin
        if not finished_head then
        begin
          parse_error := 'Cannot declare documents title in document header!';
          exit;
        end;

        ADocument.title := MergeStringArray(
                              Copy(split_line, 1, Length(split_line) - 1),
                              ' '
                            );
      end;
      PRESERVE_MODE: begin
        if finished_head then
        begin
          parse_error := 'Cannot set preservation mode outside of the '+
                         'document header';
          exit;
        end;

        if Length(split_line) < 2 then
        begin
          parse_error := 'preserve-mode switch requires one parameter: '+
                         '"style" or "color"';
          exit;
        end;

        case Copy(split_line[1], 1, Length(split_line[1])-1) of
        'style': ADocument.preserve_mode := STYLE;
        'color': ADocument.preserve_mode := COLOR;
        else
        begin
          parse_error := 'Invalid parameter "'+ split_line[1] +
                         '" for preserve-mode switch';
          exit;
        end; { end else } end; { end case }
      end;
      SECTION_BEGIN: begin
        if not finished_head then
        begin
          parse_error := 'Cannot begin a section in document header!';
          exit;
        end;

        if Length(split_line) = 1 then
        begin
          parse_error := 'Cannot begin-section without a section name!';
          exit;
        end;

        { Add Section }
        SetupSection(tmp_section, split_line[1]);
        tmp_section.owning_document := @ADocument;
        AddSectionChild(section_path[HIGH(section_path)]^, tmp_section);

        { Update Section-Path }
        SetLength(section_path, Length(section_path)+1);

        { Using curr_section leads to a SEGFAULT which im not up to debug
          at the moment }
        section_path[HIGH(section_path)] :=
                     @(section_path[HIGH(section_path)-1]^.children[
                        HIGH(section_path[HIGH(section_path)-1]^.children)]);
        {curr_section := @(section_path[HIGH(section_path)]);}
      end;
      SECTION_END: begin
        if not finished_head then
        begin
          parse_error := 'Cannot begin a section in document header!';
          exit;
        end;

        if Length(section_path) = 1 then
        begin
          parse_error := 'Cannot end section outside of a section';
          exit;
        end;

        SetLength(section_path, HIGH(section_path));
        {curr_section := section_path[HIGH(section_path)];}
      end;
      else
      begin
        section_path[HIGH(section_path)]^.contents :=
                    section_path[HIGH(section_path)]^.contents +
                    MergeStringArray(split_line, ' ') +
                    sLineBreak;
      end; { end else }
      end; { end case }
    end;

    ParseStructure := True;
  end;

  function ParseSection(const ASection: TSection;
                        const ADoChildren: Boolean): String;
  var
    lines, line_split: TStringDynArray;
    current_line, last_look_switch, last_look_value: String;
    i, skip: Integer;
    section: TSection;
  begin
    ParseSection := '';

    lines := SplitString(ASection.contents, sLineBreak);

    last_look_switch := '';
    last_look_value := '';

    for current_line in lines do
    begin
      line_split := SplitString(current_line, ' ');

      skip := 0;
      for i := 0 to Length(line_split) - 1 do
      begin
        if skip > 0 then
        begin
          dec(skip);
          continue;
        end;

        case line_split[i] of
        HEADER: begin
          ParseSection := ParseSection + STYLE_HEADER +
                          MergeStringArray(
                              Copy(line_split, i+1, Length(line_split)-1),
                              ' '
                          ) + STYLE_RESET;
          skip := Length(line_split);
        end;
        SUB_HEADER: begin
          ParseSection := ParseSection + STYLE_SUB_HEADER +
                          MergeStringArray(
                              Copy(line_split, i+1, Length(line_split)-1),
                              ' '
                          ) + STYLE_RESET;
          skip := Length(line_split);
        end;
        STYLE, COLOR: begin
          if Length(line_split) <= i+1 then
            continue;

          last_look_switch := line_split[i];
          last_look_value  := Copy(
            line_split[i+1], 1, Length(line_split[i+1])-1);

          ParseSection := ParseSection + NameToEscape(last_look_value);

          skip := 1;
        end;
        RESET_: begin
          ParseSection := ParseSection + STYLE_RESET;

          if last_look_switch = ASection.owning_document^.preserve_mode then
            ParseSection := ParseSection + NameToEscape(last_look_value);

          last_look_switch := '';
        end;
        RESET_ALL: ParseSection := ParseSection + STYLE_RESET;
        else
        begin
          { Leave out any unimplemented Switches }
          if pos('{$', line_split[i]) = 1 then
            continue;
          ParseSection := ParseSection + line_split[i] + ' ';
        end;
        end;
      end;

      ParseSection := ParseSection + sLineBreak;
    end;

    if not ADoChildren then exit;

    for section in ASection.children do
      ParseSection := ParseSection + ParseSection(section, True);
  end;

{$IFDEF DEBUG}
  function MakeIndent(const AAmount: Integer): String;
  var
    i: Integer;
  begin
    MakeIndent := '';
    for i := 1 to AAmount do
      MakeIndent := MakeIndent + ' ';
  end;

  procedure DebugPrintSection(const ASection: TSection;
                              const AIndent, AIndentIncrease: Integer);
  var
    sec: TSection;
  begin
    writeln(MakeIndent(AIndent), 'TSection { ');
    writeln(MakeIndent(AIndent+AIndentIncrease), 'name := ', ASection.name);
    writeln(MakeIndent(AIndent+AIndentIncrease), 'contents := ''', sLineBreak,
            ASection.contents);
    writeln(MAkeIndent(AIndent+AIndentIncrease), '''');
    writeln(MakeIndent(AIndent+AIndentIncrease),
            'children: array of TSection {');
    for sec in ASection.children do
      DebugPrintSection(sec, AIndent+AIndentIncrease, AIndentIncrease);
    writeln(MakeIndent(AIndent+AIndentIncrease), '}');
    writeln(MakeIndent(AIndent), '}');
  end;

  procedure DebugPrintDocument(const ADocument: TSADocument);
  const
    INDENT_INCREASE = 2;
  var
    indent: Integer;
    sec: TSection;
  begin
    indent := INDENT_INCREASE;

    writeln('TSADocument {');
    writeln(MakeIndent(indent), 'current_line := ', ADocument.current_line);
    writeln(MakeIndent(indent), 'line_number  := ', ADocument.line_number);
    writeln(MakeIndent(indent), 'title        := ', ADocument.title);
    writeln(MakeIndent(indent), 'root_section: TSection {');
    indent := INDENT_INCREASE + indent;
    writeln(MakeIndent(indent), 'name := ', ADocument.root_section.name);
    writeln(MakeIndent(indent), 'contents := ''', sLineBreak,
            ADocument.root_section.contents);
    writeln(MakeIndent(indent), '''');
    writeln(MakeIndent(indent), 'children: array of TSection {');
    indent := INDENT_INCREASE + indent;
    for sec in ADocument.root_section.children do
      DebugPrintSection(sec, indent, INDENT_INCREASE);
    indent := indent - INDENT_INCREASE;
    writeln(MakeIndent(indent), '}');
    indent := indent - INDENT_INCREASE;
    writeln(MakeIndent(indent), '}');
    writeln('}');
  end;
{$ENDIF}
end.
