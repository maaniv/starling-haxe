// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.rendering;

import flash.errors.ArgumentError;

/** Holds the properties of a single attribute in a VertexDataFormat instance.
 *  The member variables must never be changed; they are only <code>public</code>
 *  for performance reasons. */
class VertexDataAttribute
{
  public var name:String = null;
  public var format:String = null;
  public var isColor:Bool = false;
  public var offset:Int = 0;  // in bytes
  public var size:Int = 0;  // in bytes

  /** Creates a new instance with the given properties. */
  @:allow(starling.rendering)
  private function new(name:String, format:String, offset:Int)
  {
    var size:Int = 0;
    switch(format) {
      case "bytes4": size = 4;
      case "float1": size = 4;
      case "float2": size = 8;
      case "float3": size = 12;
      case "float4": size = 16;
      default: {
        throw new ArgumentError(
        "Invalid attribute format: " + format + ". " +
        "Use one of the following: 'float1'-'float4', 'bytes4'");
      }
    }

    this.name = name;
    this.format = format;
    this.offset = offset;
    this.size = size;
    this.isColor = name.indexOf("color") != -1 || name.indexOf("Color") != -1;
  }
}

