// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.textures;

import flash.errors.ArgumentError;
import flash.errors.Error;
import flash.display3D.Context3DTextureFormat;
import flash.utils.ByteArray;

/** A parser for the ATF data format. */
class AtfData
{
  public var format(get, never):String;
  public var width(get, never):Int;
  public var height(get, never):Int;
  public var numTextures(get, never):Int;
  public var isCubeMap(get, never):Bool;
  public var data(get, never):ByteArray;

  private var _format:String = null;
  private var _width:Int = 0;
  private var _height:Int = 0;
  private var _numTextures:Int = 0;
  private var _isCubeMap:Bool = false;
  private var _data:ByteArray = null;

  /** Create a new instance by parsing the given byte array. */
  public function new(data:ByteArray)
  {
    if (!isAtfData(data))
    {
      throw new ArgumentError("Invalid ATF data");
    }

    if (data[6] == 255)
    {
      data.position = 12;
    }
    else
    {
      // new file versiondata.position = 6;
    }  // old file version

    var format:Int = data.readUnsignedByte();
    var _sw0_ = (format & 0x7f);

    switch (_sw0_)
    {
      case 0, 1:_format = Context3DTextureFormat.BGRA;
      case 12, 2, 3:_format = Context3DTextureFormat.COMPRESSED;
      case 13, 4, 5:_format = "compressedAlpha";  // explicit string for compatibility
      default:throw new Error("Invalid ATF format");
    }

    _width =Std.int(Math.pow(2, data.readUnsignedByte()));
    _height = Std.int(Math.pow(2, data.readUnsignedByte()));
    _numTextures = data.readUnsignedByte();
    _isCubeMap = (format & 0x80) != 0;
    _data = data;

    // version 2 of the new file format contains information about
    // the "-e" and "-n" parameters of png2atf

    if (data[5] != 0 && data[6] == 255)
    {
      var emptyMipmaps:Bool = (data[5] & 0x01) == 1;
      var numTextures:Int = (data[5] >> 1) & 0x7f;
      _numTextures = (emptyMipmaps) ? 1:numTextures;
    }
  }

  /** Checks the first 3 bytes of the data for the 'ATF' signature. */
  public static function isAtfData(data:ByteArray):Bool
  {
    if (data.length < 3)
    {
      return false;
    }
    else
    {
      var signature:String = String.fromCharCode(data[0]) + String.fromCharCode(data[1]) + String.fromCharCode(data[2]);
      return signature == "ATF";
    }
  }

  /** The texture format. @see flash.display3D.textures.Context3DTextureFormat */
  private function get_format():String
  {
    return _format;
  }

  /** The width of the texture in pixels. */
  private function get_width():Int
  {
    return _width;
  }

  /** The height of the texture in pixels. */
  private function get_height():Int
  {
    return _height;
  }

  /** The number of encoded textures. '1' means that there are no mip maps. */
  private function get_numTextures():Int
  {
    return _numTextures;
  }

  /** Indicates if the ATF data encodes a cube map. Not supported by Starling! */
  private function get_isCubeMap():Bool
  {
    return _isCubeMap;
  }

  /** The actual byte data, including header. */
  private function get_data():ByteArray
  {
    return _data;
  }
}
