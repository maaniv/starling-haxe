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

import flash.display3D.textures.TextureBase;
import flash.geom.Matrix;
import flash.geom.Rectangle;

/** A SubTexture represents a section of another texture. This is achieved solely by
 *  manipulation of texture coordinates, making the class very efficient.
 *
 *  <p><em>Note that it is OK to create subtextures of subtextures.</em></p>
 */
class SubTexture extends Texture
{
  public var parent(get, never):Texture;
  public var ownsParent(get, never):Bool;
  public var rotated(get, never):Bool;
  public var region(get, never):Rectangle;

  private var _parent:Texture = null;
  private var _ownsParent:Bool = false;
  private var _region:Rectangle = null;
  private var _frame:Rectangle = null;
  private var _rotated:Bool = false;
  private var _width:Float = 0;
  private var _height:Float = 0;
  private var _scale:Float = 0;
  private var _transformationMatrix:Matrix = null;
  private var _transformationMatrixToRoot:Matrix = null;

  /** Creates a new SubTexture containing the specified region of a parent texture.
   *
   *  @param parent     The texture you want to create a SubTexture from.
   *  @param region     The region of the parent texture that the SubTexture will show
   *                    (in points). If <code>null</code>, the complete area of the parent.
   *  @param ownsParent If <code>true</code>, the parent texture will be disposed
   *                    automatically when the SubTexture is disposed.
   *  @param frame      If the texture was trimmed, the frame rectangle can be used to restore
   *                    the trimmed area.
   *  @param rotated    If true, the SubTexture will show the parent region rotated by
   *                    90 degrees (CCW).
   *  @param scaleModifier  The scale factor of the SubTexture will be calculated by
   *                    multiplying the parent texture's scale factor with this value.
   */
  public function new(parent:Texture, region:Rectangle = null,
      ownsParent:Bool = false, frame:Rectangle = null,
      rotated:Bool = false, scaleModifier:Float = 1)
  {
    super();
    setTo(parent, region, ownsParent, frame, rotated, scaleModifier);
  }

  /** @private
   *
   *  <p>Textures are supposed to be immutable, and Starling uses this assumption for
   *  optimizations and simplifications all over the place. However, in some situations where
   *  the texture is not accessible to the outside, this can be overruled in order to avoid
   *  allocations.</p>
   */
  @:allow(starling) private function setTo(parent:Texture, region:Rectangle = null,
      ownsParent:Bool = false, frame:Rectangle = null,
      rotated:Bool = false, scaleModifier:Float = 1):Void
  {
    if (_region == null)
    {
      _region = new Rectangle();
    }
    if (region != null)
    {
      _region.copyFrom(region);
    }
    else
    {
      _region.setTo(0, 0, parent.width, parent.height);
    }

    if (frame != null)
    {
      if (_frame != null)
      {
        _frame.copyFrom(frame);
      }
      else
      {
        _frame = frame.clone();
      }
    }
    else
    {
      _frame = null;
    }

    _parent = parent;
    _ownsParent = ownsParent;
    _rotated = rotated;
    _width = ((rotated) ? _region.height:_region.width) / scaleModifier;
    _height = ((rotated) ? _region.width:_region.height) / scaleModifier;
    _scale = _parent.scale * scaleModifier;

    if (_frame != null && (_frame.x > 0 || _frame.y > 0 ||
      _frame.right < _width || _frame.bottom < _height))
    {
      trace("[Starling] Warning: frames inside the texture's region are unsupported.");
    }

    updateMatrices();
  }

  private function updateMatrices():Void
  {
    if (_transformationMatrix != null)
    {
      _transformationMatrix.identity();
    }
    else
    {
      _transformationMatrix = new Matrix();
    }

    if (_transformationMatrixToRoot != null)
    {
      _transformationMatrixToRoot.identity();
    }
    else
    {
      _transformationMatrixToRoot = new Matrix();
    }

    if (_rotated)
    {
      _transformationMatrix.translate(0, -1);
      _transformationMatrix.rotate(Math.PI / 2.0);
    }

    _transformationMatrix.scale(_region.width / _parent.width,
        _region.height / _parent.height
    );
    _transformationMatrix.translate(_region.x / _parent.width,
        _region.y / _parent.height
    );

    var texture:SubTexture = this;
    while (texture != null)
    {
      _transformationMatrixToRoot.concat(texture._transformationMatrix);
      if (Std.is(texture.parent, SubTexture)) {
        texture = cast(texture.parent, SubTexture);
      } else  {
        texture = null;
      }

    }
  }

  /** Disposes the parent texture if this texture owns it. */
  override public function dispose():Void
  {
    if (_ownsParent)
    {
      _parent.dispose();
    }
    super.dispose();
  }

  /** The texture which the SubTexture is based on. */
  private function get_parent():Texture
  {
    return _parent;
  }

  /** Indicates if the parent texture is disposed when this object is disposed. */
  private function get_ownsParent():Bool
  {
    return _ownsParent;
  }

  /** If true, the SubTexture will show the parent region rotated by 90 degrees (CCW). */
  private function get_rotated():Bool
  {
    return _rotated;
  }

  /** The region of the parent texture that the SubTexture is showing (in points).
   *
   *  <p>CAUTION: not a copy, but the actual object! Do not modify!</p> */
  private function get_region():Rectangle
  {
    return _region;
  }

  /** @inheritDoc */
  override private function get_transformationMatrix():Matrix
  {
    return _transformationMatrix;
  }

  /** @inheritDoc */
  override private function get_transformationMatrixToRoot():Matrix
  {
    return _transformationMatrixToRoot;
  }

  /** @inheritDoc */
  override private function get_base():TextureBase
  {
    return _parent.base;
  }

  /** @inheritDoc */
  override private function get_root():ConcreteTexture
  {
    return _parent.root;
  }

  /** @inheritDoc */
  override private function get_format():String
  {
    return _parent.format;
  }

  /** @inheritDoc */
  override private function get_width():Float
  {
    return _width;
  }

  /** @inheritDoc */
  override private function get_height():Float
  {
    return _height;
  }

  /** @inheritDoc */
  override private function get_nativeWidth():Float
  {
    return _width * _scale;
  }

  /** @inheritDoc */
  override private function get_nativeHeight():Float
  {
    return _height * _scale;
  }

  /** @inheritDoc */
  override private function get_mipMapping():Bool
  {
    return _parent.mipMapping;
  }

  /** @inheritDoc */
  override private function get_premultipliedAlpha():Bool
  {
    return _parent.premultipliedAlpha;
  }

  /** @inheritDoc */
  override private function get_scale():Float
  {
    return _scale;
  }

  /** @inheritDoc */
  override private function get_frame():Rectangle
  {
    return _frame;
  }
}
