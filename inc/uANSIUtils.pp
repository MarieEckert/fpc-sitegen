{$mode fpc}
unit uANSIUtils;

{ uANSIUtils.pp ; ANSI utility functions }
{ Author: Marie Eckert                   }

{************************************************************************}
{ This file requires the ansicodes.inc file to be in                     }
{ the same directory, find it at:                                        }
{ <github/FelixEcker/delphi-fpc-unit-collection/master/src/ansicodes.inc }
{************************************************************************}

interface
  (* Get the escape code corresponding to the given name, the names are
     case-insensitive and share the names of the constants in ansicodes.inc
     without their prefix. *)
  function NameToEscape(const AName: String): String;

  {$INCLUDE ansicodes.inc}
implementation
  function NameToEscape(const AName: String): String;
  begin
    NameToEscape := '';
    case Lowercase(AName) of
    'reset':                  NameToEscape := STYLE_RESET;
    'bold':                   NameToEscape := STYLE_BOLD;
    'dim':                    NameToEscape := STYLE_DIM;
    'italic':                 NameToEscape := STYLE_ITALIC;
    'underline':              NameToEscape := STYLE_UNDERLINE;
    'slowblink':              NameToEscape := STYLE_SLOWBLINK;
    'rapidblink':             NameToEscape := STYLE_RAPIDBLINK;
    'invert':                 NameToEscape := STYLE_INVERT;
    'hid':                    NameToEscape := STYLE_HID;
    'strike':                 NameToEscape := STYLE_STRIKE;
    'default_font':           NameToEscape := STYLE_DEFAULT_FONT;
    'double_underline':       NameToEscape := STYLE_DOUBLE_UNDERLINE;
    'normal_intensity':       NameToEscape := STYLE_NORMAL_INTENSITY;
    'non_italic_blackletter': NameToEscape := STYLE_NON_ITALIC_BLACKLETTER;
    'not_underlined':         NameToEscape := STYLE_NOT_UNDERLINED;
    'not_blinking':           NameToEscape := STYLE_NOT_BLINKING;
    'proportional_spacing':   NameToEscape := STYLE_PROPORTIONAL_SPACING;
    'not_reversed':           NameToEscape := STYLE_NOT_REVERSED;
    'reveal':                 NameToEscape := STYLE_REVEAL;
    'not_crossed_out':        NameToEscape := STYLE_NOT_CROSSED_OUT;
    'fore_black':             NameToEscape := COLOR_FORE_BLACK;
    'fore_red':               NameToEscape := COLOR_FORE_RED;
    'fore_green':             NameToEscape := COLOR_FORE_GREEN;
    'fore_yellow':            NameToEscape := COLOR_FORE_YELLOW;
    'fore_blue':              NameToEscape := COLOR_FORE_BLUE;
    'fore_magenta':           NameToEscape := COLOR_FORE_MAGENTA;
    'fore_cyan':              NameToEscape := COLOR_FORE_CYAN;
    'fore_white':             NameToEscape := COLOR_FORE_WHITE;
    'fore_gray':              NameToEscape := COLOR_FORE_GRAY;
    'fore_bright_red':        NameToEscape := COLOR_FORE_BRIGHT_RED;
    'fore_bright_green':      NameToEscape := COLOR_FORE_BRIGHT_GREEN;
    'fore_bright_yellow':     NameToEscape := COLOR_FORE_BRIGHT_YELLOW;
    'fore_bright_blue':       NameToEscape := COLOR_FORE_BRIGHT_BLUE;
    'fore_bright_magenta':    NameToEscape := COLOR_FORE_BRIGHT_MAGENTA;
    'fore_bright_cyan':       NameToEscape := COLOR_FORE_BRIGHT_CYAN;
    'fore_bright_white':      NameToEscape := COLOR_FORE_BRIGHT_WHITE;
    'back_black':             NameToEscape := COLOR_BACK_BLACK;
    'back_red':               NameToEscape := COLOR_BACK_RED;
    'back_green':             NameToEscape := COLOR_BACK_GREEN;
    'back_yellow':            NameToEscape := COLOR_BACK_YELLOW;
    'back_blue':              NameToEscape := COLOR_BACK_BLUE;
    'back_magenta':           NameToEscape := COLOR_BACK_MAGENTA;
    'back_cyan':              NameToEscape := COLOR_BACK_CYAN;
    'back_white':             NameToEscape := COLOR_BACK_WHITE;
    'back_gray':              NameToEscape := COLOR_BACK_GRAY;
    'back_bright_red':        NameToEscape := COLOR_BACK_BRIGHT_RED;
    'back_bright_green':      NameToEscape := COLOR_BACK_BRIGHT_GREEN;
    'back_bright_yellow':     NameToEscape := COLOR_BACK_BRIGHT_YELLOW;
    'back_bright_blue':       NameToEscape := COLOR_BACK_BRIGHT_BLUE;
    'back_bright_magenta':    NameToEscape := COLOR_BACK_BRIGHT_MAGENTA;
    'back_bright_cyan':       NameToEscape := COLOR_BACK_BRIGHT_CYAN;
    'back_bright_white':      NameToEscape := COLOR_BACK_BRIGHT_WHITE;
    end;
  end;
end.
