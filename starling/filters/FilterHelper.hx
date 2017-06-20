// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters;

import flash.display3D.Context3DProfile;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.textures.SubTexture;
import starling.textures.Texture;
import starling.utils.MathUtil;
import openfl.Vector;

/** @private
 *
 *  This class manages texture creation, pooling and disposal of all textures
 *  during filter processing.
 */
class FilterHelper implements IFilterHelper
{
  public var projectionMatrix3D(get, set):Matrix3D;
  public var renderTarget(get, set):Texture;
  public var targetBounds(get, set):Rectangle;
  public var target(get, set):DisplayObject;
  public var textureScale(get, set):Float;
  public var textureFormat(get, set):String;

  private var _width:Float = 0;
  private var _height:Float = 0;
  private var _nativeWidth:Int = 0;
  private var _nativeHeight:Int = 0;
  private var _pool:Vector<Texture> = null;
  private var _usePotTextures:Bool = false;
  private var _textureFormat:String = null;
  private var _preferredScale:Float = 0;
  private var _scale:Float = 0;
  private var _sizeStep:Int = 0;
  private var _numPasses:Int = 0;
  private var _projectionMatrix:Matrix3D = null;
  private var _renderTarget:Texture = null;
  private var _targetBounds:Rectangle = null;
  private var _target:DisplayObject = null;

  // helpers
  private var sRegion:Rectangle = new Rectangle();

  /** Creates a new, empty instance. */
  @:allow(starling.filters)
  private function new(textureFormat:String = "bgra")
  {
    _usePotTextures = Starling.current.profile == Context3DProfile.BASELINE_CONSTRAINED;
    _preferredScale = Starling.contentScaleFactor_();
    _textureFormat = textureFormat;
    _sizeStep = 64;  // must be POT!
    _pool = new Vector();
    _projectionMatrix = new Matrix3D();
    _targetBounds = new Rectangle();

    setSize(_sizeStep, _sizeStep);
  }

  /** Purges the pool. */
  public function dispose():Void
  {
    purge();
  }

  /** Starts a new round of rendering. If <code>numPasses</code> is greater than zero, each
   *  <code>getTexture()</code> call will be counted as one pass; the final pass will then
   *  return <code>null</code> instead of a texture, to indicate that this pass should be
   *  rendered to the back buffer.
   */
  public function start(numPasses:Int, drawLastPassToBackBuffer:Bool):Void
  {
    _numPasses = (drawLastPassToBackBuffer) ? numPasses:-1;
  }

  /** @inheritDoc */
  public function getTexture(resolution:Float = 1.0):Texture
  {
    var texture:Texture;
    var subTexture:SubTexture;

    if (_numPasses >= 0)
    {
      if (_numPasses-- == 0)
      {
        return null;
      }
    }

    if (_pool.length > 0)
    {
      texture = _pool.pop();
    }
    else
    {
      texture = Texture.empty(_nativeWidth / _scale, _nativeHeight / _scale,
              true, false, true, _scale, _textureFormat
        );
    }

    if (!MathUtil.isEquivalent(texture.width, _width, 0.1) ||
      !MathUtil.isEquivalent(texture.height, _height, 0.1) ||
      !MathUtil.isEquivalent(texture.scale, _scale * resolution))
    {
      sRegion.setTo(0, 0, _width * resolution, _height * resolution);

      if (Std.is(texture, SubTexture))
      {
        subTexture = cast(texture, SubTexture);
        subTexture.setTo(texture.root, sRegion, true, null, false, resolution);
      }
      else
      {
        texture = new SubTexture(texture.root, sRegion, true, null, false, resolution);
      }
    }

    texture.root.clear();
    return texture;
  }

  /** @inheritDoc */
  public function putTexture(texture:Texture):Void
  {
    if (texture != null)
    {
      if (texture.root.nativeWidth == _nativeWidth && texture.root.nativeHeight == _nativeHeight)
      {
        _pool.insertAt(_pool.length, texture);
      }
      else
      {
        texture.dispose();
      }
    }
  }

  /** Purges the pool and disposes all textures. */
  public function purge():Void
  {
    var i:Int = 0;
    var len:Int = _pool.length;
    while (i < len)
    {
      _pool[i].dispose();
      ++i;
    }

    _pool.length = 0;
  }

  /** Updates the size of the returned textures. Small size changes may allow the
   *  existing textures to be reused; big size changes will automatically dispose
   *  them. */
  private function setSize(width:Float, height:Float):Void
  {
    var factor:Float;
    var newScale:Float = _preferredScale;
    var maxNativeSize:Int = Texture.maxSize;
    var newNativeWidth:Int = getNativeSize(width, newScale);
    var newNativeHeight:Int = getNativeSize(height, newScale);

    if (newNativeWidth > maxNativeSize || newNativeHeight > maxNativeSize)
    {
      factor = maxNativeSize / Math.max(newNativeWidth, newNativeHeight);
      newNativeWidth = Std.int(newNativeWidth * factor);
      newNativeHeight = Std.int(newNativeHeight * factor);
      newScale *= factor;
    }

    if (_nativeWidth != newNativeWidth || _nativeHeight != newNativeHeight ||
      _scale != newScale)
    {
      purge();

      _scale = newScale;
      _nativeWidth = newNativeWidth;
      _nativeHeight = newNativeHeight;
    }

    _width = width;
    _height = height;
  }

  private function getNativeSize(size:Float, textureScale:Float):Int
  {
    var nativeSize:Float = size * textureScale;

    if (_usePotTextures)
    {
      return (nativeSize > _sizeStep) ? MathUtil.getNextPowerOfTwo(nativeSize):_sizeStep;
    }
    else
    {
      return Math.ceil(nativeSize / _sizeStep) * _sizeStep;
    }
  }

  /** The projection matrix that was active when the filter started processing. */
  private function get_projectionMatrix3D():Matrix3D
  {
    return _projectionMatrix;
  }
  private function set_projectionMatrix3D(value:Matrix3D):Matrix3D
  {
    _projectionMatrix.copyFrom(value);
    return value;
  }

  /** The render target that was active when the filter started processing. */
  private function get_renderTarget():Texture
  {
    return _renderTarget;
  }
  private function set_renderTarget(value:Texture):Texture
  {
    _renderTarget = value;
    return value;
  }

  /** @inheritDoc */
  private function get_targetBounds():Rectangle
  {
    return _targetBounds;
  }
  private function set_targetBounds(value:Rectangle):Rectangle
  {
    _targetBounds.copyFrom(value);
    setSize(value.width, value.height);
    return value;
  }

  /** @inheritDoc */
  private function get_target():DisplayObject
  {
    return _target;
  }
  private function set_target(value:DisplayObject):DisplayObject
  {
    _target = value;
    return value;
  }

  /** The scale factor of the returned textures. */
  private function get_textureScale():Float
  {
    return _preferredScale;
  }
  private function set_textureScale(value:Float):Float
  {
    _preferredScale = (value > 0) ? value : Starling.contentScaleFactor_();
    return value;
  }

  /** The texture format of the returned textures. @default BGRA */
  private function get_textureFormat():String
  {
    return _textureFormat;
  }
  private function set_textureFormat(value:String):String
  {
    _textureFormat = value;
    return value;
  }
}

