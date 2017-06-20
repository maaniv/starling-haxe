// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display;

import starling.errors.AbstractClassError;

/** A class that provides constant values for the states of the Button class. */
class ButtonState
{
  /** @private */
  public function new()
  {
    throw new AbstractClassError();
  }
  
  /** The button's default state. */
  public static inline var UP:String = "up";
  
  /** The button is pressed. */
  public static inline var DOWN:String = "down";
  
  /** The mouse hovers over the button. */
  public static inline var OVER:String = "over";
  
  /** The button was disabled altogether. */
  public static inline var DISABLED:String = "disabled";
}