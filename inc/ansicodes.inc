{*********************************************************************}
{     Freepascal Include file for ANSI Color & Style Escape Codes     }
{                                                                     }
{ Author: Marie Eckert                                                }
{ Original Filename: ansicodes.inc                                    }
{ Licensed under the WTFPL.                                           }
{                                                                     }
{             DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE             }
{                       Version 2, December 2004                      }
{                                                                     }
{ Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>                    }
{                                                                     }
{ Everyone is permitted to copy and distribute verbatim or modified   }
{ copies of this license document, and changing it is allowed as long }
{ as the name is changed.                                             }
{                                                                     }
{             DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE             }
{   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION   }
{                                                                     }
{  0. You just DO WHAT THE FUCK YOU WANT TO.                          }
{*********************************************************************}

{ Constant Prefixes and Description              }
{ F - Is a Format String                         }
{ STYLE_ - Control Sequence modifying text-style }
{ COLOR_ - Control Sequence modifying text-color }

const
  { ANSI Control Sequence Introducer }
  CSI = #27'[';

  STYLE_RESET      = CSI + '0m';
  STYLE_BOLD       = CSI + '1m';
  STYLE_DIM        = CSI + '2m';
  STYLE_ITALIC     = CSI + '3m';
  STYLE_UNDERLINE  = CSI + '4m';
  STYLE_SLOWBLINK  = CSI + '5m';
  STYLE_RAPIDBLINK = CSI + '6m';
  STYLE_INVERT     = CSI + '7m';

  { NOTE: not widely supported }
  STYLE_HID        = CSI + '8m';

  STYLE_STRIKE       = CSI + '9m';
  STYLE_DEFAULT_FONT = CSI + '10m';
  FSTYLE_ALT_FONT    = CSI + '1%dm';

  { NOTE: not widely supported }
  STYLE_FRAKTUR = CSI + '20m';

  STYLE_DOUBLE_UNDERLINE       = CSI + '21m';
  STYLE_NORMAL_INTENSITY       = CSI + '22m';
  STYLE_NON_ITALIC_BLACKLETTER = CSI + '23m';
  STYLE_NOT_UNDERLINED         = CSI + '24m';
  STYLE_NOT_BLINKING           = CSI + '25m';
  STYLE_PROPORTIONAL_SPACING   = CSI + '26m';
  STYLE_NOT_REVERSED           = CSI + '27m';
  STYLE_REVEAL                 = CSI + '28m';
  STYLE_NOT_CROSSED_OUT        = CSI + '29m';

  COLOR_FORE_BLACK          = CSI + '30m';
  COLOR_FORE_RED            = CSI + '31m';
  COLOR_FORE_GREEN          = CSI + '32m';
  COLOR_FORE_YELLOW         = CSI + '33m';
  COLOR_FORE_BLUE           = CSI + '34m';
  COLOR_FORE_MAGENTA        = CSI + '35m';
  COLOR_FORE_CYAN           = CSI + '36m';
  COLOR_FORE_WHITE          = CSI + '37m';
  COLOR_FORE_GRAY           = CSI + '90m';
  COLOR_FORE_BRIGHT_RED     = CSI + '91m';
  COLOR_FORE_BRIGHT_GREEN   = CSI + '92m';
  COLOR_FORE_BRIGHT_YELLOW  = CSI + '93m';
  COLOR_FORE_BRIGHT_BLUE    = CSI + '94m';
  COLOR_FORE_BRIGHT_MAGENTA = CSI + '95m';
  COLOR_FORE_BRIGHT_CYAN    = CSI + '96m';
  COLOR_FORE_BRIGHT_WHITE   = CSI + '97m';
  COLOR_BACK_BLACK          = CSI + '40m';
  COLOR_BACK_RED            = CSI + '41m';
  COLOR_BACK_GREEN          = CSI + '42m';
  COLOR_BACK_YELLOW         = CSI + '43m';
  COLOR_BACK_BLUE           = CSI + '44m';
  COLOR_BACK_MAGENTA        = CSI + '45m';
  COLOR_BACK_CYAN           = CSI + '46m';
  COLOR_BACK_WHITE          = CSI + '47m';
  COLOR_BACK_GRAY           = CSI + '100m';
  COLOR_BACK_BRIGHT_RED     = CSI + '101m';
  COLOR_BACK_BRIGHT_GREEN   = CSI + '102m';
  COLOR_BACK_BRIGHT_YELLOW  = CSI + '103m';
  COLOR_BACK_BRIGHT_BLUE    = CSI + '104m';
  COLOR_BACK_BRIGHT_MAGENTA = CSI + '105m';
  COLOR_BACK_BRIGHT_CYAN    = CSI + '106m';
  COLOR_BACK_BRIGHT_WHITE   = CSI + '107m';
