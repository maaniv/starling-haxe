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

/** A utility class with methods related to the String class. */
class StringUtil
{
  /** @private */
  public function new()
  {
    throw new AbstractClassError();
  }

  /** Formats a String in .Net-style, with curly braces ("{0}"). Does not support any
   *  number formatting options yet. */
  public static function format(format:String, args:Array<Dynamic> = null):String
  {
    // TODO: add number formatting options
    for (i in 0...args.length)
    {
      format = kFormatRegexps[i].replace(format, Std.string(args[i]));
    }

    return format;
  }

  /** Replaces a string's "master string" — the string it was built from —
   *  with a single character to save memory. Find more information about this AS3 oddity
   *  <a href="http://jacksondunstan.com/articles/2260">here</a>.
   *
   *  @param  string The String to clean
   *  @return The input string, but with a master string only one character larger than it.
   *  @author Jackson Dunstan, JacksonDunstan.com
   */
  public static function clean(string:String):String
  {
    return ("_" + string).substr(1);
  }

  /** Removes all leading white-space and control characters from the given String.
   *
   *  <p>Beware: this method does not make a proper Unicode white-space check,
   *  but simply trims all character codes of '0x20' or below.</p>
   */
  public static function trimStart(string:String):String
  {
    var pos:Int = 0;
    var length:Int = string.length;

    while(pos < length)
    {
      if (string.charCodeAt(pos) > 0x20)
      {
        break;
      }
      ++pos;
    }

    return string.substring(pos, length);
  }

  /** Removes all trailing white-space and control characters from the given String.
   *
   *  <p>Beware: this method does not make a proper Unicode white-space check,
   *  but simply trims all character codes of '0x20' or below.</p>
   */
  public static function trimEnd(string:String):String
  {
    var pos:Int = string.length - 1;
    while (pos >= 0)
    {
      if (string.charCodeAt(pos) > 0x20)
      {
        break;
      }
      --pos;
    }

    return string.substring(0, pos + 1);
  }

  /** Removes all leading and trailing white-space and control characters from the given
   *  String.
   *
   *  <p>Beware: this method does not make a proper Unicode white-space check,
   *  but simply trims all character codes of '0x20' or below.</p>
   */
  public static function trim(string:String):String
  {
    var startPos:Int = 0;
    var endPos:Int;
    var length:Int = string.length;

    while(startPos < length)
    {
      if (string.charCodeAt(startPos) > 0x20)
      {
        break;
      }
      ++startPos;
    }

    endPos = string.length - 1;
    while (endPos >= startPos)
    {
      if (string.charCodeAt(endPos) > 0x20)
      {
        break;
      }
      --endPos;
    }

    return string.substring(startPos, endPos + 1);
  }

  public static function toFixed(val:Float, precision):String {
    var pow = Math.pow(10, precision);
    return Std.string(Math.round(val * pow) / pow);
  }

  static var kFormatRegexps:Array<EReg> = [
    new EReg("\\{0\\}", "g"),
    new EReg("\\{1\\}", "g"),
    new EReg("\\{2\\}", "g"),
    new EReg("\\{3\\}", "g"),
    new EReg("\\{4\\}", "g"),
    new EReg("\\{5\\}", "g"),
    new EReg("\\{6\\}", "g"),
    new EReg("\\{7\\}", "g"),
    new EReg("\\{8\\}", "g"),
    new EReg("\\{9\\}", "g"),
  ];
}

