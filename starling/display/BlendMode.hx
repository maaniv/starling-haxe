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

import flash.errors.ArgumentError;
import flash.display3D.Context3DBlendFactor;
import starling.core.Starling;

/** A class that provides constant values for visual blend mode effects.
 *
 *  <p>A blend mode is always defined by two 'Context3DBlendFactor' values. A blend factor
 *  represents a particular four-value vector that is multiplied with the source or destination
 *  color in the blending formula. The blending formula is:</p>
 *
 *  <pre>result = source × sourceFactor + destination × destinationFactor</pre>
 *
 *  <p>In the formula, the source color is the output color of the pixel shader program. The
 *  destination color is the color that currently exists in the color buffer, as set by
 *  previous clear and draw operations.</p>
 *
 *  <p>You can add your own blend modes via <code>BlendMode.register</code>.
 *  To get the math right, remember that all colors in Starling use premultiplied alpha (PMA),
 *  which means that their RGB values were multiplied with the alpha value.</p>
 *
 *  @see flash.display3D.Context3DBlendFactor
 */
class BlendMode
{
  public var sourceFactor(get, never):String;
  public var destinationFactor(get, never):String;
  public var name(get, never):String;

  private var _name:String = null;
  private var _sourceFactor:String = null;
  private var _destinationFactor:String = null;

  private static var sBlendModes:Map<String, BlendMode> = null;

  /** Creates a new BlendMode instance. Don't call this method directly; instead,
   *  register a new blend mode using <code>BlendMode.register</code>. */
  public function new(name:String, sourceFactor:String, destinationFactor:String)
  {
    _name = name;
    _sourceFactor = sourceFactor;
    _destinationFactor = destinationFactor;
  }

  /** Inherits the blend mode from this display object's parent. */
  public static inline var AUTO:String = "auto";

  /** Deactivates blending, i.e. disabling any transparency. */
  public static inline var NONE:String = "none";

  /** The display object appears in front of the background. */
  public static inline var NORMAL:String = "normal";

  /** Adds the values of the colors of the display object to the colors of its background. */
  public static inline var ADD:String = "add";

  /** Multiplies the values of the display object colors with the the background color. */
  public static inline var MULTIPLY:String = "multiply";

  /** Multiplies the complement (inverse) of the display object color with the complement of
  * the background color, resulting in a bleaching effect. */
  public static inline var SCREEN:String = "screen";

  /** Erases the background when drawn on a RenderTexture. */
  public static inline var ERASE:String = "erase";

  /** When used on a RenderTexture, the drawn object will act as a mask for the current
   *  content, i.e. the source alpha overwrites the destination alpha. */
  public static inline var MASK:String = "mask";

  /** Draws under/below existing objects; useful especially on RenderTextures. */
  public static inline var BELOW:String = "below";

  // static access methods

  /** Returns the blend mode with the given name.
   *  Throws an ArgumentError if the mode does not exist. */
  public static function get(modeName:String):BlendMode
  {
    if (sBlendModes == null)
    {
      registerDefaults();
    }
    if (sBlendModes.exists(modeName))
    {
      return sBlendModes.get(modeName);
    }
    else
    {
      throw new ArgumentError("Blend mode not found: " + modeName);
    }
  }

  /** Registers a blending mode under a certain name. */
  public static function register(name:String, srcFactor:String, dstFactor:String):BlendMode
  {
    if (sBlendModes == null)
    {
      registerDefaults();
    }
    var blendMode:BlendMode = new BlendMode(name, srcFactor, dstFactor);
    sBlendModes.set(name, blendMode);
    return blendMode;
  }

  private static function registerDefaults():Void
  {
    if (sBlendModes != null)
    {
      return;
    }

    sBlendModes = new Map();
    register("none", Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
    register("normal", Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
    register("add", Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
    register("multiply", Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
    register("screen", Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR);
    register("erase", Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
    register("mask", Context3DBlendFactor.ZERO, Context3DBlendFactor.SOURCE_ALPHA);
    register("below", Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA);
  }

  // instance methods / properties

  /** Sets the appropriate blend factors for source and destination on the current context. */
  public function activate():Void
  {
    Starling.context_().setBlendFactors(_sourceFactor, _destinationFactor);
  }

  /** Returns the name of the blend mode. */
  public function toString():String
  {
    return _name;
  }

  /** The source blend factor of this blend mode. */
  private function get_sourceFactor():String
  {
    return _sourceFactor;
  }

  /** The destination blend factor of this blend mode. */
  private function get_destinationFactor():String
  {
    return _destinationFactor;
  }

  /** Returns the name of the blend mode. */
  private function get_name():String
  {
    return _name;
  }
}
