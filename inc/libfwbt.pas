unit libfwbt;

{
  libfwbt -- fixed width binary table library

  This unit is a manual translation of the main header file of libfwbt with some
  wrapper functions to make working with libfwbt using fpc a bit more pleasant.
  All functions which are directly linked to the libfwbt functions are prefixed
  with "__extern_"

  See: https://github.com/FelixEcker/libfwbt

  Original File   : include/fwbt.h
  API Version     : 1.0
  FPC API Version : 0.1
  Format Version  : 1
  Author          : Marie Eckert

  Copyright (c) 2024, Marie Eckert
  This Unit is licensed under the BSD 3-Clause license.
}

interface

{$linklib fwbt}

uses baseunix, ctypes, Types;

const
  sharedobject = 'fwbt';
  fpc_fwbt_version = '0.1';

  { --- from fwbt.h --- }
  FWBT_SIGNATURE: array[0..3] of CChar = (
                                      CChar('F'),
                                      CChar('W'),
                                      CChar('B'),
                                      CChar('T')
                                  );
  FWBT_VERSION = 1; { Format Version }
  FWBT_API_VERSION = '1.0'; { API Version }

  FWBT_DATA_VERSION_INDEX     = 4;
  FWBT_DATA_KEY_WIDTH_INDEX   = FWBT_DATA_VERSION_INDEX     + 1;
  FWBT_DATA_VALUE_WIDTH_INDEX = FWBT_DATA_KEY_WIDTH_INDEX   + 4;
  FWBT_DATA_ENTRY_COUNT_INDEX = FWBT_DATA_VALUE_WIDTH_INDEX + 4;
  FWBT_DATA_BODY_START        = FWBT_DATA_ENTRY_COUNT_INDEX + 1;

type

  PUInt8 = ^UInt8;
  PPUInt8 = ^PUInt8;
  Psize_t = ^size_t;

  {$PACKRECORDS 1}
  TFWBTHeader = packed record
    signature  : array[0..3] of CChar;
    version    : UInt8;
    key_width  : UInt32;
    value_width: UInt32;
    entry_count: UInt32;
  end;

  {$PACKRECORDS C}
  TFWBTBody = record
    keys  : PPUInt8;
    values: PPUInt8;
  end;

  TFWBT = record
    header: TFWBTHeader;
    body  : TFWBTBody;
  end;

  PFWBT = ^TFWBT;

  {$PACKRECORDS DEFAULT}

  TFWBTError = (FWBT_OK,FWBT_NO_SIGNATURE,FWBT_UNSUPPORTED_VERSION,
    FWBT_INVALID_KEY_WIDTH,FWBT_INVALID_VALUE_WIDTH,
    FWBT_INVALID_ENTRY_COUNT,FWBT_INVALID_BODY_SIZE,
    FWBT_TOO_SHORT,FWBT_NULLPTR,FWBT_MALLOC_FAIL,
    FWBT_DUPLICATE_KEYS,FWBT_KEY_NOT_FOUND,
    FWBT_OUT_OF_RANGE,FWBT_TABLE_FULL);

{ --- functions linked in from libfwbt --- }

{
  @brief Parse the given data into a FWBT.
  @note To avoid memcpying every single key/value pair of the body, define
  FWBT_BODY_NO_MEMCPY whilst compiling. This will cause the parsing code
  to just point into the raw data received by the function.
  When defined MAKE SURE NOT TO FREE THE ORIGINAL DATA

  @param data Pointer to the data
  @param data_size Size of the data
  @param out_fwbt Destination pointer for the parsed FWBT
  @return FWBT_OK if parsing succeeds, any other possible error if not
}
function __extern_fwbt_parse_bytes(data:PUInt8; data_size:size_t; out_fwbt:PFWBT):TFWBTError;cdecl;external sharedobject name 'fwbt_parse_bytes';

{
  @brief Serialize the given FWBT into bytes
  @param fwbt The FWBT to be serialized
  @param out_bytes Output location for the serialized bytes
  @param out_size The size of the serialized FWBT in bytes
  @return FWBT_OK if serialization succeeds.
}
function __extern_fwbt_serialize(fwbt:TFWBT; out_bytes:PPUInt8; out_size:Psize_t):TFWBTError;cdecl;external sharedobject name 'fwbt_serialize';

{
  @brief Finds the index of a value in a FWBT
  @param fwbt The FWBT to search through
  @param key The key to search with
  @return The index of the the value, UINT32_MAX if not found
}
function __extern_fwbt_find_value(fwbt:TFWBT; key:PUInt8):UInt32;cdecl;external sharedobject name 'fwbt_find_value';

{
  @brief Set a value within the given FWBT. If successful, the pointers to the
  key and value are to be viewed as being owned by the table now.
  @param fwbt The FWBT to modify
  @param key The key of the new value
  @param value The value
  @param replace_existing Should an existing value with the same key be
  replaced?
  @return FWBT_OK on success
}
function __extern_fwbt_set_value(fwbt:PFWBT; key:PUInt8; value:PUInt8; replace_existing:boolean):TFWBTError;cdecl;external sharedobject name 'fwbt_set_value';

{
  @brief Remove a value within the given FWBT
  @param fwbt The FWBT to modify
  @param key The key of the value to remove
  @return FWBT_OK on success
}
function __extern_fwbt_remove_value(fwbt:PFWBT; key:PUInt8):TFWBTError;cdecl;external sharedobject name 'fwbt_remove_value';

{
  @brief Remove a value within the given FWBT
  @param fwbt The FWBT to modify
  @param index The index of the value to remove
  @return FWBT_OK on success
}
function __extern_fwbt_remove_value_by_index(fwbt:PFWBT; index:UInt32):TFWBTError;cdecl;external sharedobject name 'fwbt_remove_value_by_index';

{ --- wrapper functions --- }

{
  @brief Equivalent to FWBT_HEADER_SIZE macro from fwbt.h
}
function FWBT_HEADER_SIZE: Integer;

{
  @brief Parse the given data Byte-Array into a FWBT record
  @return FWBT_OK if successfull.
}
function FwbtParseBytes(var out_fwbt: TFWBT; constref data: TByteDynArray): TFWBTError;

{
  @brief Serialize the given FWBT into a Byte-Array
  @return FWBT_OK if successfull.
}
function FwbtSerialize(constref fwbt: TFWBT; var outbytes: TByteDynArray): TFWBTError;

{
  @brief Finds the value corresponding to the given key
  @return Index of key/value pair. (2^32)-1 (UINT32_MAX) if not found
}
function FwbtFindValue(constref fwbt: TFWBT; const key: TByteDynArray): UInt32;

{
  @brief Sets the value for the given key
  @note Each key and value should be an unique array, as libfwbt only ever
        stores the raw pointers to the keys and values it receives.
  @param replace_existing Should an existing value be replaced?
  @return FWBT_OK if successfull.
}
function FwbtSetValue(var fwbt: TFWBT; constref key: TByteDynArray;
                      constref value: TByteDynArray;
                      const replace_existing: Boolean): TFWBTError;

{
  @brief Removes the key/value pair using the given key
  @return FWBT_OK if successfull.
}
function FwbtRemoveValue(var fwbt: TFWBT; constref key: TByteDynArray): TFWBTError;

{
  @brief Removes the key/value pair at the given index
  @return FWBT_OK if successfull.
}
function FwbtRemoveValueByIndex(var fwbt: TFWBT; const index: UInt32): TFWBTError;

implementation

function FWBT_HEADER_SIZE: Integer;
begin
  FWBT_HEADER_SIZE := sizeof(TFWBTHeader);
end;

function FwbtParseBytes(var out_fwbt: TFWBT; constref data: TByteDynArray): TFWBTError;
begin
  FwbtParseBytes := __extern_fwbt_parse_bytes(@data[0], Length(data), @out_fwbt);
end;

function FwbtSerialize(constref fwbt: TFWBT; var outbytes: TByteDynArray): TFWBTError;
var
  c_outbytes: PUInt8;
  out_size: SizeUInt;
begin
  FwbtSerialize := __extern_fwbt_serialize(fwbt, @c_outbytes, @out_size);

  if FwbtSerialize <> FWBT_OK then
    exit;

  SetLength(outbytes, out_size);
  Move(c_outbytes^, outbytes[0], out_size);
end;

function FwbtFindValue(constref fwbt: TFWBT; const key: TByteDynArray): UInt32;
begin
  FwbtFindValue := __extern_fwbt_find_value(fwbt, @key[0]);
end;

function FwbtSetValue(var fwbt: TFWBT; constref key: TByteDynArray;
                      constref value: TByteDynArray;
                      const replace_existing: Boolean): TFWBTError;
begin
  FwbtSetValue := __extern_fwbt_set_value(@fwbt, @key[0], @value[0], replace_existing);
end;

function FwbtRemoveValue(var fwbt: TFWBT; constref key: TByteDynArray): TFWBTError;
begin
  FwbtRemoveValue := __extern_fwbt_remove_value(@fwbt, @key[0]);
end;

function FwbtRemoveValueByIndex(var fwbt: TFWBT; const index: UInt32): TFWBTError;
begin
  FwbtRemoveValueByIndex := __extern_fwbt_remove_value_by_index(@fwbt, index);
end;

end.
