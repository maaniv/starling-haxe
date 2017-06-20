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

import flash.errors.Error;
import haxe.Constraints.Function;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display3D.textures.TextureBase;
import flash.net.NetStream;
import flash.system.Capabilities;
import flash.utils.ByteArray;
import starling.core.Starling;
import starling.errors.AbstractClassError;
import starling.errors.AbstractMethodError;
import starling.errors.NotSupportedError;
import starling.events.Event;
import starling.rendering.Painter;
import starling.utils.Color;

/** A ConcreteTexture wraps a Stage3D texture object, storing the properties of the texture
 *  and providing utility methods for data upload, etc.
 *
 *  <p>This class cannot be instantiated directly; create instances using
 *  <code>Texture.fromTextureBase</code> instead. However, that's only necessary when
 *  you need to wrap a <code>TextureBase</code> object in a Starling texture;
 *  the preferred way of creating textures is to use one of the other
 *  <code>Texture.from...</code> factory methods in the <code>Texture</code> class.</p>
 *
 *  @see Texture
 */
class ConcreteTexture extends Texture
{
  public var optimizedForRenderTexture(get, never):Bool;
  public var isPotTexture(get, never):Bool;
  public var onRestore(get, set):Function;

  private var _base:TextureBase = null;
  private var _format:String = null;
  private var _width:Int = 0;
  private var _height:Int = 0;
  private var _mipMapping:Bool = false;
  private var _premultipliedAlpha:Bool = false;
  private var _optimizedForRenderTexture:Bool = false;
  private var _scale:Float = 0;
  private var _onRestore:Function = null;
  private var _dataUploaded:Bool = false;

  /** @private
   *
   *  Creates a ConcreteTexture object from a TextureBase, storing information about size,
   *  mip-mapping, and if the channels contain premultiplied alpha values. May only be
   *  called from subclasses.
   *
   *  <p>Note that <code>width</code> and <code>height</code> are expected in pixels,
   *  i.e. they do not take the scale factor into account.</p>
   */
  public function new(base:TextureBase, format:String, width:Int, height:Int,
      mipMapping:Bool, premultipliedAlpha:Bool,
      optimizedForRenderTexture:Bool = false, scale:Float = 1)
  {
    super();
    if (Capabilities.isDebugger &&
      Type.getClassName(Type.getClass(this)) == "starling.textures::ConcreteTexture")
    {
      throw new AbstractClassError();
    }

    _scale = (scale <= 0) ? 1.0:scale;
    _base = base;
    _format = format;
    _width = width;
    _height = height;
    _mipMapping = mipMapping;
    _premultipliedAlpha = premultipliedAlpha;
    _optimizedForRenderTexture = optimizedForRenderTexture;
    _onRestore = null;
    _dataUploaded = false;
  }

  /** Disposes the TextureBase object. */
  override public function dispose():Void
  {
    if (_base != null)
    {
      _base.dispose();
    }

    this.onRestore = null;  // removes event listener
    super.dispose();
  }

  // texture data upload

  /** Uploads a bitmap to the texture. The existing contents will be replaced.
   *  If the size of the bitmap does not match the size of the texture, the bitmap will be
   *  cropped or filled up with transparent pixels */
  public function uploadBitmap(bitmap:Bitmap):Void
  {
    uploadBitmapData(bitmap.bitmapData);
  }

  /** Uploads bitmap data to the texture. The existing contents will be replaced.
   *  If the size of the bitmap does not match the size of the texture, the bitmap will be
   *  cropped or filled up with transparent pixels */
  public function uploadBitmapData(data:BitmapData):Void
  {
    throw new NotSupportedError();
  }

  /** Uploads ATF data from a ByteArray to the texture. Note that the size of the
   *  ATF-encoded data must be exactly the same as the original texture size.
   *
   *  <p>The 'async' parameter may be either a boolean value or a callback function.
   *  If it's <code>false</code> or <code>null</code>, the texture will be decoded
   *  synchronously and will be visible right away. If it's <code>true</code> or a function,
   *  the data will be decoded asynchronously. The texture will remain unchanged until the
   *  upload is complete, at which time the callback function will be executed. This is the
   *  expected function definition: <code>function(texture:Texture):void;</code></p>
   */
  public function uploadAtfData(data:ByteArray, offset:Int = 0, async:Dynamic = null):Void
  {
    throw new NotSupportedError();
  }

  /** Specifies a video stream to be rendered within the texture. */
  public function attachNetStream(netStream:NetStream, onComplete:Function = null):Void
  {
    attachVideo("NetStream", netStream, onComplete);
  }

  /** @private */
  @:allow(starling.textures)
  private function attachVideo(type:String, attachment:Dynamic, onComplete:Function = null):Void
  {
    throw new NotSupportedError();
  }

  // texture backup (context loss)

  private function onContextCreated():Void
  {
    _dataUploaded = false;
    _base = createBase();  // recreate the underlying texture
    // _onRestore(this);  // restore contents
    _onRestore();  // restore contents

    // if no texture has been uploaded above, we init the texture with transparent pixels.
    if (!_dataUploaded)
    {
      clear();
    }
  }

  /** Recreates the underlying Stage3D texture object with the same dimensions and attributes
   *  as the one that was passed to the constructor. You have to upload new data before the
   *  texture becomes usable again. Beware: this method does <strong>not</strong> dispose
   *  the current base. */
  private function createBase():TextureBase
  {
    throw new AbstractMethodError();
  }

  /** Recreates the underlying Stage3D texture. May be used to manually restore a texture.
   *  Beware that new data needs to be uploaded to the texture before it can be used. */
  private function recreateBase():Void
  {
    _base = createBase();
  }

  /** Clears the texture with a certain color and alpha value. The previous contents of the
   *  texture is wiped out. */
  public function clear(color:Int = 0x0, alpha:Float = 0.0):Void
  {
    if (_premultipliedAlpha && alpha < 1.0)
    {
      color = Color.rgb(Std.int(Color.getRed(color) * alpha),
              Std.int(Color.getGreen(color) * alpha),
              Std.int(Color.getBlue(color) * alpha)
        );
    }

    var painter:Painter = Starling.painter_();
    painter.pushState();
    painter.state.renderTarget = this;

    // we wrap the clear call in a try/catch block as a workaround for a problem of
    // FP 11.8 plugin/projector: calling clear on a compressed texture doesn't work there
    // (while it *does* work on iOS + Android).

    try
    {
      painter.clear(color, alpha);
    }
    catch (e:Error)
    {
    }

    painter.popState();
    setDataUploaded();
  }

  /** Notifies the instance that the base texture may now be used for rendering. */
  private function setDataUploaded():Void
  {
    _dataUploaded = true;
  }

  // properties

  /** Indicates if the base texture was optimized for being used in a render texture. */
  private function get_optimizedForRenderTexture():Bool
  {
    return _optimizedForRenderTexture;
  }

  /** Indicates if the base texture is a standard power-of-two dimensioned texture of type
   *  <code>flash.display3D.textures.Texture</code>. */
  private function get_isPotTexture():Bool
  {
    return false;
  }

  /** The function that you provide here will be called after a context loss.
   *  On execution, a new base texture will already have been created; however,
   *  it will be empty. Call one of the "upload..." methods from within the callback
   *  to restore the actual texture data.
   *
   *  <listing>
   *  var texture:Texture = Texture.fromBitmap(new EmbeddedBitmap());
   *  texture.root.onRestore = function():void
   *  {
   *      texture.root.uploadFromBitmap(new EmbeddedBitmap());
   *  };</listing>
   */
  private function get_onRestore():Function
  {
    return _onRestore;
  }
  private function set_onRestore(value:Function):Function
  {
    Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);

    if (value != null)
    {
      _onRestore = value;
      Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
    }
    else
    {
      _onRestore = null;
    }
    return value;
  }

  /** @inheritDoc */
  override private function get_base():TextureBase
  {
    return _base;
  }

  /** @inheritDoc */
  override private function get_root():ConcreteTexture
  {
    return this;
  }

  /** @inheritDoc */
  override private function get_format():String
  {
    return _format;
  }

  /** @inheritDoc */
  override private function get_width():Float
  {
    return _width / _scale;
  }

  /** @inheritDoc */
  override private function get_height():Float
  {
    return _height / _scale;
  }

  /** @inheritDoc */
  override private function get_nativeWidth():Float
  {
    return _width;
  }

  /** @inheritDoc */
  override private function get_nativeHeight():Float
  {
    return _height;
  }

  /** @inheritDoc */
  override private function get_scale():Float
  {
    return _scale;
  }

  /** @inheritDoc */
  override private function get_mipMapping():Bool
  {
    return _mipMapping;
  }

  /** @inheritDoc */
  override private function get_premultipliedAlpha():Bool
  {
    return _premultipliedAlpha;
  }
}
