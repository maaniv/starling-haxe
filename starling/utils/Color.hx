// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils;

import starling.errors.AbstractClassError;
import openfl.Vector;

/** A utility class containing predefined colors and methods converting between different
 *  color representations. */
class Color
{
  public static inline var WHITE:Int = 0xffffff;
  public static inline var SILVER:Int = 0xc0c0c0;
  public static inline var GRAY:Int = 0x808080;
  public static inline var BLACK:Int = 0x000000;
  public static inline var RED:Int = 0xff0000;
  public static inline var MAROON:Int = 0x800000;
  public static inline var YELLOW:Int = 0xffff00;
  public static inline var OLIVE:Int = 0x808000;
  public static inline var LIME:Int = 0x00ff00;
  public static inline var GREEN:Int = 0x008000;
  public static inline var AQUA:Int = 0x00ffff;
  public static inline var TEAL:Int = 0x008080;
  public static inline var BLUE:Int = 0x0000ff;
  public static inline var NAVY:Int = 0x000080;
  public static inline var FUCHSIA:Int = 0xff00ff;
  public static inline var PURPLE:Int = 0x800080;

  /** Returns the alpha part of an ARGB color (0 - 255). */
  public static function getAlpha(color:Int):Int
  {
    return (color >> 24) & 0xff;
  }

  /** Returns the red part of an (A)RGB color (0 - 255). */
  public static function getRed(color:Int):Int
  {
    return (color >> 16) & 0xff;
  }

  /** Returns the green part of an (A)RGB color (0 - 255). */
  public static function getGreen(color:Int):Int
  {
    return (color >> 8) & 0xff;
  }

  /** Returns the blue part of an (A)RGB color (0 - 255). */
  public static function getBlue(color:Int):Int
  {
    return color & 0xff;
  }

  /** Creates an RGB color, stored in an unsigned integer. Channels are expected
   *  in the range 0 - 255. */
  public static function rgb(red:Int, green:Int, blue:Int):Int
  {
    return (red << 16) | (green << 8) | blue;
  }

  /** Creates an ARGB color, stored in an unsigned integer. Channels are expected
   *  in the range 0 - 255. */
  public static function argb(alpha:Int, red:Int, green:Int, blue:Int):Int
  {
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
  }

  /** Converts a color to a vector containing the RGBA components (in this order) scaled
   *  between 0 and 1. */
  public static function toVector(color:Int, out:Vector<Float> = null):Vector<Float>
  {
    if (out == null)
    {
      out = new Vector<Float>(4, true);
    }

    out[0] = ((color >> 16) & 0xff) / 255.0;
    out[1] = ((color >> 8) & 0xff) / 255.0;
    out[2] = (color & 0xff) / 255.0;
    out[3] = ((color >> 24) & 0xff) / 255.0;

    return out;
  }

  /** Multiplies all channels of an (A)RGB color with a certain factor. */
  public static function multiply(color:Int, factor:Float):Int
  {
    var alpha:Int = Std.int(((color >> 24) & 0xff) * factor);
    var red:Int = Std.int(((color >> 16) & 0xff) * factor);
    var green:Int = Std.int(((color >> 8) & 0xff) * factor);
    var blue:Int = Std.int((color & 0xff) * factor);

    if (alpha > 255)
    {
      alpha = 255;
    }
    if (red > 255)
    {
      red = 255;
    }
    if (green > 255)
    {
      green = 255;
    }
    if (blue > 255)
    {
      blue = 255;
    }

    return argb(alpha, red, green, blue);
  }

  /** Calculates a smooth transition between one color to the next.
   *  <code>ratio</code> is expected between 0 and 1. */
  public static function interpolate(startColor:Int, endColor:Int, ratio:Float):Int
  {
    var startA:Int = (startColor >> 24) & 0xff;
    var startR:Int = (startColor >> 16) & 0xff;
    var startG:Int = (startColor >> 8) & 0xff;
    var startB:Int = (startColor) & 0xff;

    var endA:Int = (endColor >> 24) & 0xff;
    var endR:Int = (endColor >> 16) & 0xff;
    var endG:Int = (endColor >> 8) & 0xff;
    var endB:Int = (endColor) & 0xff;

    var newA:Int = Std.int(startA + (endA - startA) * ratio);
    var newR:Int = Std.int(startR + (endR - startR) * ratio);
    var newG:Int = Std.int(startG + (endG - startG) * ratio);
    var newB:Int = Std.int(startB + (endB - startB) * ratio);

    return (newA << 24) | (newR << 16) | (newG << 8) | newB;
  }

  /** @private */
  public function new()
  {
    throw new AbstractClassError();
  }
}
