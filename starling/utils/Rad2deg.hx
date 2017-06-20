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


/**
 * Class for rad2deg
 */
@:final class Rad2deg
{
  /** Converts an angle from radians into degrees. */
  public static function rad2deg(rad:Float):Float
  {
    return rad / Math.PI * 180.0;
  }

  public function new()
  {
  }
}
