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
import haxe.Constraints.Function;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.RectangleTexture;
import flash.display3D.textures.TextureBase;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.NetStream;
import flash.system.Capabilities;
import flash.utils.ByteArray;
import starling.core.Starling;
import starling.errors.AbstractClassError;
import starling.errors.MissingContextError;
import starling.errors.NotSupportedError;
import starling.rendering.VertexData;
import starling.utils.MathUtil;
import starling.utils.MatrixUtil;

/** <p>A texture stores the information that represents an image. It cannot be added to the
 *  display list directly; instead it has to be mapped onto a display object. In Starling,
 *  the most probably candidate for this job is the <code>Image</code> class.</p>
 *
 *  <strong>Creating a texture</strong>
 *
 *  <p>The <code>Texture</code> class is abstract, i.e. you cannot create instance of this
 *  class through its constructor. Instead, it offers a variety of factory methods, like
 *  <code>fromBitmapData</code> or <code>fromEmbeddedAsset</code>.</p>
 *
 *  <strong>Texture Formats</strong>
 *
 *  <p>Since textures can be created from a "BitmapData" object, Starling supports any bitmap
 *  format that is supported by Flash. And since you can render any Flash display object into
 *  a BitmapData object, you can use this to display non-Starling content in Starling - e.g.
 *  Shape objects.</p>
 *
 *  <p>Starling also supports ATF textures (Adobe Texture Format), which is a container for
 *  compressed texture formats that can be rendered very efficiently by the GPU. Refer to
 *  the Flash documentation for more information about this format.</p>
 *
 *  <p>Beginning with AIR 17, you can use Starling textures to show video content (if the
 *  current platform supports it; see "SystemUtil.supportsVideoTexture").
 *  The two factory methods "fromCamera" and "fromNetStream" allow you to make use of
 *  this feature.</p>
 *
 *  <strong>Mip Mapping</strong>
 *
 *  <p>MipMaps are scaled down versions of a texture. When an image is displayed smaller than
 *  its natural size, the GPU may display the mip maps instead of the original texture. This
 *  reduces aliasing and accelerates rendering. It does, however, also need additional memory;
 *  for that reason, mipmapping is disabled by default.</p>
 *
 *  <strong>Texture Frame</strong>
 *
 *  <p>The frame property of a texture allows you to let a texture appear inside the bounds of
 *  an image, leaving a transparent border around the texture. The frame rectangle is specified
 *  in the coordinate system of the texture (not the image):</p>
 *
 *  <listing>
 *  var frame:Rectangle = new Rectangle(-10, -10, 30, 30);
 *  var texture:Texture = Texture.fromTexture(anotherTexture, null, frame);
 *  var image:Image = new Image(texture);</listing>
 *
 *  <p>This code would create an image with a size of 30x30, with the texture placed at
 *  <code>x=10, y=10</code> within that image (assuming that 'anotherTexture' has a width and
 *  height of 10 pixels, it would appear in the middle of the image).</p>
 *
 *  <p>The texture atlas makes use of this feature, as it allows to crop transparent edges
 *  of a texture and making up for the changed size by specifying the original texture frame.
 *  Tools like <a href="http://www.texturepacker.com/">TexturePacker</a> use this to
 *  optimize the atlas.</p>
 *
 *  <strong>Texture Coordinates</strong>
 *
 *  <p>If, on the other hand, you want to show only a part of the texture in an image
 *  (i.e. to crop the the texture), you can either create a subtexture (with the method
 *  'Texture.fromTexture()' and specifying a rectangle for the region), or you can manipulate
 *  the texture coordinates of the image object. The method <code>image.setTexCoords</code>
 *  allows you to do that.</p>
 *
 *  <strong>Context Loss</strong>
 *
 *  <p>When the current rendering context is lost (which can happen on all platforms, but is
 *  especially common on Android and Windows), all texture data is destroyed. However,
 *  Starling will try to restore the textures. To do that, it will keep the bitmap
 *  and ATF data in memory - at the price of increased RAM consumption. You can optimize
 *  this behavior, though, by restoring the texture directly from its source, like in this
 *  example:</p>
 *
 *  <listing>
 *  var texture:Texture = Texture.fromBitmap(new EmbeddedBitmap());
 *  texture.root.onRestore = function():void
 *  {
 *      texture.root.uploadFromBitmap(new EmbeddedBitmap());
 *  };</listing>
 *
 *  <p>The <code>onRestore</code>-method will be called when the context was lost and the
 *  texture has been recreated (but is still empty). If you use the "AssetManager" class to
 *  manage your textures, this will be done automatically.</p>
 *
 *  @see starling.display.Image
 *  @see starling.utils.AssetManager
 *  @see starling.utils.SystemUtil
 *  @see TextureAtlas
 */
class Texture
{
  public var frame(get, never):Rectangle;
  public var frameWidth(get, never):Float;
  public var frameHeight(get, never):Float;
  public var width(get, never):Float;
  public var height(get, never):Float;
  public var nativeWidth(get, never):Float;
  public var nativeHeight(get, never):Float;
  public var scale(get, never):Float;
  public var base(get, never):TextureBase;
  public var root(get, never):ConcreteTexture;
  public var format(get, never):String;
  public var mipMapping(get, never):Bool;
  public var premultipliedAlpha(get, never):Bool;
  public var transformationMatrix(get, never):Matrix;
  public var transformationMatrixToRoot(get, never):Matrix;
  public static var maxSize(get, never):Int;

  // helper objects
  private static var sDefaultOptions:TextureOptions = new TextureOptions();
  private static var sRectangle:Rectangle = new Rectangle();
  private static var sMatrix:Matrix = new Matrix();
  private static var sPoint:Point = new Point();

  /** @private */
  public function new()
  {
    if (Capabilities.isDebugger &&
      Type.getClassName(Type.getClass(this)) == "starling.textures::Texture")
    {
      throw new AbstractClassError();
    }
  }

  /** Disposes the underlying texture data. Note that not all textures need to be disposed:
   *  SubTextures (created with 'Texture.fromTexture') just reference other textures and
   *  and do not take up resources themselves; this is also true for textures from an
   *  atlas. */
  public function dispose():Void
  {  // override in subclasses

  }

  /** Creates a texture from any of the supported data types, using the specified options.
   *
   *  @param data     Either an embedded asset class, a Bitmap, BitmapData, or a ByteArray
   *                  with ATF data.
   *  @param options  Specifies options about the texture settings, e.g. the scale factor.
   *                  If left empty, the default options will be used.
   */
  public static function fromData(data:Dynamic, options:TextureOptions = null):Texture
  {
    if (Std.is(data, Bitmap))
    {
      data = cast(data, Bitmap).bitmapData;
    }
    if (options == null)
    {
      options = sDefaultOptions;
    }

    if (Std.is(data, Class))
    {
      return fromEmbeddedAsset(Type.getClass(data),
          options.mipMapping, options.optimizeForRenderToTexture,
          options.scale, options.format, options.forcePotTexture
      );
    }
    else
    {
      if (Std.is(data, BitmapData))
      {
        return fromBitmapData(cast(data, BitmapData),
            options.mipMapping, options.optimizeForRenderToTexture,
            options.scale, options.format, options.forcePotTexture
      );
      }
      else
      {
        if (Std.is(data, ByteArray))
        {
          return fromAtfData(cast(data, ByteArray),
              options.scale, options.mipMapping, options.onReady
        );
        }
        else
        {
          throw new ArgumentError("Unsupported 'data' type: " + Type.getClassName(data));
        }
      }
    }
  }

  /** Creates a texture from a <code>TextureBase</code> object.
   *
   *  @param base     a Stage3D texture object created through the current context.
   *  @param width    the width of the texture in pixels (not points!).
   *  @param height   the height of the texture in pixels (not points!).
   *  @param options  specifies options about the texture settings, e.g. the scale factor.
   *                  If left empty, the default options will be used. Note that not all
   *                  options are supported by all texture types.
   */
  public static function fromTextureBase(base:TextureBase, width:Int, height:Int,
      options:TextureOptions = null):ConcreteTexture
  {
    if (options == null)
    {
      options = sDefaultOptions;
    }

    if (Std.is(base, flash.display3D.textures.Texture))
    {
      return new ConcretePotTexture(cast(base, flash.display3D.textures.Texture),
        options.format, width, height, options.mipMapping,
        options.premultipliedAlpha, options.optimizeForRenderToTexture,
        options.scale);
    }
    else
    {
      if (Std.is(base, RectangleTexture))
      {
        return new ConcreteRectangleTexture(cast(base, RectangleTexture),
          options.format, width, height, options.premultipliedAlpha,
          options.optimizeForRenderToTexture, options.scale);
      }
      else
      {
        // if (Std.is(base, VideoTexture))
        // {
        //   return new ConcreteVideoTexture(try cast(base, VideoTexture) catch(e:Dynamic) null, options.scale);
        // }
        // else
        // {
          throw new ArgumentError("Unsupported 'base' type: " + Type.getClassName(Type.getClass(base)));
        // }
      }
    }
  }

  /** Creates a texture object from an embedded asset class. Textures created with this
   *  method will be restored directly from the asset class in case of a context loss,
   *  which guarantees a very economic memory usage.
   *
   *  @param assetClass  must contain either a Bitmap or a ByteArray with ATF data.
   *  @param mipMapping  for Bitmaps, indicates if mipMaps will be created;
   *                     for ATF data, indicates if the contained mipMaps will be used.
   *  @param optimizeForRenderToTexture  indicates if this texture will be used as
   *                     render target.
   *  @param scale       the scale factor of the created texture.
   *  @param format      the context3D texture format to use. Ignored for ATF data.
   *  @param forcePotTexture  indicates if the underlying Stage3D texture should be created
   *                     as the power-of-two based "Texture" class instead of the more memory
   *                     efficient "RectangleTexture". (Only applicable to bitmaps; ATF
   *                     textures are always POT-textures, anyway.)
   */
  public static function fromEmbeddedAsset(assetClass:Class<Dynamic>, mipMapping:Bool = false,
      optimizeForRenderToTexture:Bool = false,
      scale:Float = 1, format:String = "bgra",
      forcePotTexture:Bool = false):Texture
  {
    var texture:Texture;
    var asset:Dynamic = Type.createInstance(assetClass, []);

    if (Std.is(asset, Bitmap))
    {
      texture = Texture.fromBitmap(cast(asset, Bitmap), mipMapping,
              optimizeForRenderToTexture, scale, format, forcePotTexture
        );
      texture.root.onRestore = function():Void
          {
            texture.root.uploadBitmap(Type.createInstance(assetClass, []));
          };
    }
    else
    {
      if (Std.is(asset, ByteArray))
      {
        texture = Texture.fromAtfData(cast(asset, ByteArray), scale, mipMapping, null);
        texture.root.onRestore = function():Void
            {
              texture.root.uploadAtfData(Type.createInstance(assetClass, []));
            };
      }
      else
      {
        throw new ArgumentError("Invalid asset type: " + Type.getClassName(asset));
      }
    }

    asset = null;  // avoid that object stays in memory (through 'onRestore' functions)
    return texture;
  }

  /** Creates a texture object from a bitmap.
   *  Beware: you must not dispose the bitmap's data if Starling should handle a lost device
   *  context alternatively, you can handle restoration yourself via "texture.root.onRestore".
   *
   *  @param bitmap   the texture will be created with the bitmap data of this object.
   *  @param generateMipMaps  indicates if mipMaps will be created.
   *  @param optimizeForRenderToTexture  indicates if this texture will be used as
   *                  render target
   *  @param scale    the scale factor of the created texture. This affects the reported
   *                  width and height of the texture object.
   *  @param format   the context3D texture format to use. Pass one of the packed or
   *                  compressed formats to save memory (at the price of reduced image
   *                  quality).
   *  @param forcePotTexture  indicates if the underlying Stage3D texture should be created
   *                  as the power-of-two based "Texture" class instead of the more memory
   *                  efficient "RectangleTexture".
   */
  public static function fromBitmap(bitmap:Bitmap, generateMipMaps:Bool = false,
      optimizeForRenderToTexture:Bool = false,
      scale:Float = 1, format:String = "bgra",
      forcePotTexture:Bool = false):Texture
  {
    return fromBitmapData(bitmap.bitmapData, generateMipMaps, optimizeForRenderToTexture,
        scale, format, forcePotTexture
    );
  }

  /** Creates a texture object from bitmap data.
   *  Beware: you must not dispose 'data' if Starling should handle a lost device context;
   *  alternatively, you can handle restoration yourself via "texture.root.onRestore".
   *
   *  @param data     the bitmap data to upload to the texture.
   *  @param generateMipMaps  indicates if mipMaps will be created.
   *  @param optimizeForRenderToTexture  indicates if this texture will be used as
   *                  render target
   *  @param scale    the scale factor of the created texture. This affects the reported
   *                  width and height of the texture object.
   *  @param format   the context3D texture format to use. Pass one of the packed or
   *                  compressed formats to save memory (at the price of reduced image
   *                  quality).
   *  @param forcePotTexture  indicates if the underlying Stage3D texture should be created
   *                  as the power-of-two based "Texture" class instead of the more memory
   *                  efficient "RectangleTexture".
   */
  public static function fromBitmapData(data:BitmapData, generateMipMaps:Bool = false,
      optimizeForRenderToTexture:Bool = false,
      scale:Float = 1, format:String = "bgra",
      forcePotTexture:Bool = false):Texture
  {
    var texture:Texture = Texture.empty(data.width / scale, data.height / scale, true,
        generateMipMaps, optimizeForRenderToTexture, scale,
        format, forcePotTexture
    );

    texture.root.uploadBitmapData(data);
    texture.root.onRestore = function():Void
        {
          texture.root.uploadBitmapData(data);
        };

    return texture;
  }

  /** Creates a texture from ATF data (Adobe Texture Compression).
   *  Beware: you must not dispose 'data' if Starling should handle a lost device context;
   *  alternatively, you can handle restoration yourself via "texture.root.onRestore".
   *
   *  @param data       the raw data from an ATF file.
   *  @param scale      the scale factor of the created texture. This affects the reported
   *                    width and height of the texture object.
   *  @param useMipMaps If the ATF data contains mipmaps, this parameter controls if they
   *                    are used; if it does not, this parameter has no effect.
   *  @param async      If you pass a callback function, the texture will be decoded
   *                    asynchronously, which allows a smooth framerate even during the
   *                    loading process. However, don't use the texture before the callback
   *                    has been executed. This is the expected function definition:
   *                    <code>function(texture:Texture):void;</code>
   *  @param premultipliedAlpha  Indicates if the ATF data contains pixels in PMA format.
   *                    This is "false" for most ATF files, but can be customized in some
   *                    tools.
   */
  public static function fromAtfData(data:ByteArray, scale:Float = 1, useMipMaps:Bool = true,
      async:Function = null, premultipliedAlpha:Bool = false):Texture
  {
    var context:Context3D = Starling.context_();
    if (context == null)
    {
      throw new MissingContextError();
    }

    var atfData:AtfData = new AtfData(data);
    var nativeTexture:flash.display3D.textures.Texture = context.createTexture(
        atfData.width, atfData.height, atfData.format, false
    );
    var concreteTexture:ConcreteTexture = new ConcretePotTexture(nativeTexture,
    atfData.format, atfData.width, atfData.height, useMipMaps && atfData.numTextures > 1,
    premultipliedAlpha, false, scale);

    concreteTexture.uploadAtfData(data, 0, async);
    concreteTexture.onRestore = function():Void
        {
          concreteTexture.uploadAtfData(data, 0);
        };

    return concreteTexture;
  }

  /** Creates a video texture from a NetStream.
   *
   *  <p>Below, you'll find  a minimal sample showing how to stream a video from a file.
   *  Note that <code>ns.play()</code> is called only after creating the texture, and
   *  outside the <code>onComplete</code>-callback. It's recommended to always make the
   *  calls in this order; otherwise, playback won't start on some platforms.</p>
   *
   *  <listing>
   *  var nc:NetConnection = new NetConnection();
   *  nc.connect(null);
   *
   *  var ns:NetStream = new NetStream(nc);
   *  var texture:Texture = Texture.fromNetStream(ns, 1, function():void
   *  {
   *      addChild(new Image(texture));
   *  });
   *
   *  var file:File = File.applicationDirectory.resolvePath("bugs-bunny.m4v");
   *  ns.play(file.url);</listing>
   *
   *  @param stream  the NetStream from which the video data is streamed. Beware that 'play'
   *                 should be called only after the method returns, and outside the
   *                 <code>onComplete</code> callback.
   *  @param scale   the scale factor of the created texture. This affects the reported
   *                 width and height of the texture object.
   *  @param onComplete will be executed when the texture is ready. Contains a parameter
   *                 of type 'Texture'.
   */
  public static function fromNetStream(stream:NetStream, scale:Float = 1,
      onComplete:Function = null):Texture
  {
    // workaround for bug in NetStream class:
    if (stream.client == stream)
    {
      stream.client = {
            onMetaData: function(md:Dynamic):Void
            {
            }
          };
    }

    return fromVideoAttachment("NetStream", stream, scale, onComplete);
  }

  private static function fromVideoAttachment(type:String, attachment:Dynamic,
      scale:Float, onComplete:Function):Texture
  {
    throw new NotSupportedError("Video Textures are not supported on this platform");
    // if (!SystemUtil.supportsVideoTexture)
    // {
    //   throw new NotSupportedError("Video Textures are not supported on this platform");
    // }

    // var context:Context3D = Starling.current.context;
    // if (context == null)
    // {
    //   throw new MissingContextError();
    // }

    // var base:VideoTexture = context.createVideoTexture();
    // var texture:ConcreteTexture = new ConcreteVideoTexture(base, scale);
    // texture.attachVideo(type, attachment, onComplete);
    // texture.onRestore = function():Void
    //     {
    //       texture.root.attachVideo(type, attachment);
    //     };

    // return texture;
  }

  /** Creates a texture with a certain size and color.
   *
   *  @param width   in points; number of pixels depends on scale parameter
   *  @param height  in points; number of pixels depends on scale parameter
   *  @param color   the RGB color the texture will be filled up
   *  @param alpha   the alpha value that will be used for every pixel
   *  @param optimizeForRenderToTexture  indicates if this texture will be used as render target
   *  @param scale   if you omit this parameter, 'Starling.contentScaleFactor' will be used.
   *  @param format  the context3D texture format to use. Pass one of the packed or
   *                 compressed formats to save memory.
   *  @param forcePotTexture  indicates if the underlying Stage3D texture should be created
   *                 as the power-of-two based "Texture" class instead of the more memory
   *                 efficient "RectangleTexture".
   */
  public static function fromColor(width:Float, height:Float,
      color:Int = 0xffffff, alpha:Float = 1.0,
      optimizeForRenderToTexture:Bool = false,
      scale:Float = -1, format:String = "bgra",
      forcePotTexture:Bool = false):Texture
  {
    var texture:Texture = Texture.empty(width, height, true, false,
        optimizeForRenderToTexture, scale, format, forcePotTexture
    );
    texture.root.clear(color, alpha);
    texture.root.onRestore = function():Void
        {
          texture.root.clear(color, alpha);
        };

    return texture;
  }

  /** Creates an empty texture of a certain size.
   *  Beware that the texture can only be used after you either upload some color data
   *  ("texture.root.upload...") or clear the texture ("texture.root.clear()").
   *
   *  @param width   in points; number of pixels depends on scale parameter
   *  @param height  in points; number of pixels depends on scale parameter
   *  @param premultipliedAlpha  the PMA format you will use the texture with. If you will
   *                 use the texture for bitmap data, use "true"; for ATF data, use "false".
   *  @param mipMapping  indicates if mipmaps should be used for this texture. When you upload
   *                 bitmap data, this decides if mipmaps will be created; when you upload ATF
   *                 data, this decides if mipmaps inside the ATF file will be displayed.
   *  @param optimizeForRenderToTexture  indicates if this texture will be used as render target
   *  @param scale   if you omit this parameter, 'Starling.contentScaleFactor' will be used.
   *  @param format  the context3D texture format to use. Pass one of the packed or
   *                 compressed formats to save memory (at the price of reduced image quality).
   *  @param forcePotTexture  indicates if the underlying Stage3D texture should be created
   *                 as the power-of-two based "Texture" class instead of the more memory
   *                 efficient "RectangleTexture".
   */
  public static function empty(width:Float, height:Float, premultipliedAlpha:Bool = true,
      mipMapping:Bool = false, optimizeForRenderToTexture:Bool = false,
      scale:Float = -1, format:String = "bgra",
      forcePotTexture:Bool = false):Texture
  {
    if (scale <= 0)
    {
      scale = Starling.contentScaleFactor_();
    }

    var actualWidth:Int;
    var actualHeight:Int;
    var nativeTexture:TextureBase;
    var concreteTexture:ConcreteTexture;
    var context:Context3D = Starling.context_();

    if (context == null)
    {
      throw new MissingContextError();
    }

    var origWidth:Float = width * scale;
    var origHeight:Float = height * scale;
    var useRectTexture:Bool = !forcePotTexture && !mipMapping &&
    Starling.current.profile != "baselineConstrained" &&
    format.indexOf("compressed") == -1;

    if (useRectTexture)
    {
      actualWidth = Math.ceil(origWidth - 0.000000001);  // avoid floating point errors
      actualHeight = Math.ceil(origHeight - 0.000000001);

      nativeTexture = context.createRectangleTexture(
              actualWidth, actualHeight, format, optimizeForRenderToTexture
        );

      concreteTexture = new ConcreteRectangleTexture(
          cast(nativeTexture, RectangleTexture), format, actualWidth, actualHeight,
          premultipliedAlpha, optimizeForRenderToTexture, scale);
    }
    else
    {
      actualWidth = MathUtil.getNextPowerOfTwo(origWidth);
      actualHeight = MathUtil.getNextPowerOfTwo(origHeight);

      nativeTexture = context.createTexture(
              actualWidth, actualHeight, format, optimizeForRenderToTexture
        );

      concreteTexture = new ConcretePotTexture(
          cast(nativeTexture, flash.display3D.textures.Texture), format,
          actualWidth, actualHeight, mipMapping, premultipliedAlpha,
          optimizeForRenderToTexture, scale);
    }

    concreteTexture.onRestore = concreteTexture.clear;

    if (actualWidth - origWidth < 0.001 && actualHeight - origHeight < 0.001)
    {
      return concreteTexture;
    }
    else
    {
      return new SubTexture(concreteTexture, new Rectangle(0, 0, width, height), true);
    }
  }

  /** Creates a texture that contains a region (in pixels) of another texture. The new
   *  texture will reference the base texture; no data is duplicated.
   *
   *  @param texture  The texture you want to create a SubTexture from.
   *  @param region   The region of the parent texture that the SubTexture will show
   *                  (in points).
   *  @param frame    If the texture was trimmed, the frame rectangle can be used to restore
   *                  the trimmed area.
   *  @param rotated  If true, the SubTexture will show the parent region rotated by
   *                  90 degrees (CCW).
   *  @param scaleModifier  The scale factor of the new texture will be calculated by
   *                  multiplying the parent texture's scale factor with this value.
   */
  public static function fromTexture(texture:Texture, region:Rectangle = null,
      frame:Rectangle = null, rotated:Bool = false,
      scaleModifier:Float = 1.0):Texture
  {
    return new SubTexture(texture, region, false, frame, rotated, scaleModifier);
  }

  /** Sets up a VertexData instance with the correct positions for 4 vertices so that
   *  the texture can be mapped onto it unscaled. If the texture has a <code>frame</code>,
   *  the vertices will be offset accordingly.
   *
   *  @param vertexData  the VertexData instance to which the positions will be written.
   *  @param vertexID    the start position within the VertexData instance.
   *  @param attrName    the attribute name referencing the vertex positions.
   *  @param bounds      useful only for textures with a frame. This will position the
   *                     vertices at the correct position within the given bounds,
   *                     distorted appropriately.
   */
  public function setupVertexPositions(vertexData:VertexData, vertexID:Int = 0,
      attrName:String = "position",
      bounds:Rectangle = null):Void
  {
    var frame:Rectangle = this.frame;
    var width:Float = this.width;
    var height:Float = this.height;

    if (frame != null)
    {
      sRectangle.setTo(-frame.x, -frame.y, width, height);
    }
    else
    {
      sRectangle.setTo(0, 0, width, height);
    }

    vertexData.setPoint(vertexID, attrName, sRectangle.left, sRectangle.top);
    vertexData.setPoint(vertexID + 1, attrName, sRectangle.right, sRectangle.top);
    vertexData.setPoint(vertexID + 2, attrName, sRectangle.left, sRectangle.bottom);
    vertexData.setPoint(vertexID + 3, attrName, sRectangle.right, sRectangle.bottom);

    if (bounds != null)
    {
      var scaleX:Float = bounds.width / frameWidth;
      var scaleY:Float = bounds.height / frameHeight;

      if (scaleX != 1.0 || scaleY != 1.0 || bounds.x != 0 || bounds.y != 0)
      {
        sMatrix.identity();
        sMatrix.scale(scaleX, scaleY);
        sMatrix.translate(bounds.x, bounds.y);
        vertexData.transformPoints(attrName, sMatrix, vertexID, 4);
      }
    }
  }

  /** Sets up a VertexData instance with the correct texture coordinates for
   *  4 vertices so that the texture is mapped to the complete quad.
   *
   *  @param vertexData  the vertex data to which the texture coordinates will be written.
   *  @param vertexID    the start position within the VertexData instance.
   *  @param attrName    the attribute name referencing the vertex positions.
   */
  public function setupTextureCoordinates(vertexData:VertexData, vertexID:Int = 0,
      attrName:String = "texCoords"):Void
  {
    setTexCoords(vertexData, vertexID, attrName, 0.0, 0.0);
    setTexCoords(vertexData, vertexID + 1, attrName, 1.0, 0.0);
    setTexCoords(vertexData, vertexID + 2, attrName, 0.0, 1.0);
    setTexCoords(vertexData, vertexID + 3, attrName, 1.0, 1.0);
  }

  /** Transforms the given texture coordinates from the local coordinate system
   *  into the root texture's coordinate system. */
  public function localToGlobal(u:Float, v:Float, out:Point = null):Point
  {
    if (out == null)
    {
      out = new Point();
    }
    if (this == root)
    {
      out.setTo(u, v);
    }
    else
    {
      MatrixUtil.transformCoords(transformationMatrixToRoot, u, v, out);
    }
    return out;
  }

  /** Transforms the given texture coordinates from the root texture's coordinate system
   *  to the local coordinate system. */
  public function globalToLocal(u:Float, v:Float, out:Point = null):Point
  {
    if (out == null)
    {
      out = new Point();
    }
    if (this == root)
    {
      out.setTo(u, v);
    }
    else
    {
      sMatrix.identity();
      sMatrix.copyFrom(transformationMatrixToRoot);
      sMatrix.invert();
      MatrixUtil.transformCoords(sMatrix, u, v, out);
    }
    return out;
  }

  /** Writes the given texture coordinates to a VertexData instance after transforming
   *  them into the root texture's coordinate system. That way, the texture coordinates
   *  can be used directly to sample the texture in the fragment shader. */
  public function setTexCoords(vertexData:VertexData, vertexID:Int, attrName:String,
      u:Float, v:Float):Void
  {
    localToGlobal(u, v, sPoint);
    vertexData.setPoint(vertexID, attrName, sPoint.x, sPoint.y);
  }

  /** Reads a pair of texture coordinates from the given VertexData instance and transforms
   *  them into the current texture's coordinate system. (Remember, the VertexData instance
   *  will always contain the coordinates in the root texture's coordinate system!) */
  public function getTexCoords(vertexData:VertexData, vertexID:Int,
      attrName:String = "texCoords", out:Point = null):Point
  {
    if (out == null)
    {
      out = new Point();
    }
    vertexData.getPoint(vertexID, attrName, out);
    return globalToLocal(out.x, out.y, out);
  }

  // properties

  /** The texture frame if it has one (see class description), otherwise <code>null</code>.
   *  <p>CAUTION: not a copy, but the actual object! Do not modify!</p> */
  private function get_frame():Rectangle
  {
    return null;
  }

  /** The height of the texture in points, taking into account the frame rectangle
   *  (if there is one). */
  private function get_frameWidth():Float
  {
    return (frame != null) ? frame.width:width;
  }

  /** The width of the texture in points, taking into account the frame rectangle
   *  (if there is one). */
  private function get_frameHeight():Float
  {
    return (frame != null) ? frame.height:height;
  }

  /** The width of the texture in points. */
  private function get_width():Float
  {
    return 0;
  }

  /** The height of the texture in points. */
  private function get_height():Float
  {
    return 0;
  }

  /** The width of the texture in pixels (without scale adjustment). */
  private function get_nativeWidth():Float
  {
    return 0;
  }

  /** The height of the texture in pixels (without scale adjustment). */
  private function get_nativeHeight():Float
  {
    return 0;
  }

  /** The scale factor, which influences width and height properties. */
  private function get_scale():Float
  {
    return 1.0;
  }

  /** The Stage3D texture object the texture is based on. */
  private function get_base():TextureBase
  {
    return null;
  }

  /** The concrete texture the texture is based on. */
  private function get_root():ConcreteTexture
  {
    return null;
  }

  /** The <code>Context3DTextureFormat</code> of the underlying texture data. */
  private function get_format():String
  {
    return Context3DTextureFormat.BGRA;
  }

  /** Indicates if the texture contains mip maps. */
  private function get_mipMapping():Bool
  {
    return false;
  }

  /** Indicates if the alpha values are premultiplied into the RGB values. */
  private function get_premultipliedAlpha():Bool
  {
    return false;
  }

  /** The matrix that is used to transform the texture coordinates into the coordinate
   *  space of the parent texture, if there is one. @default null
   *
   *  <p>CAUTION: not a copy, but the actual object! Never modify this matrix!</p> */
  private function get_transformationMatrix():Matrix
  {
    return null;
  }

  /** The matrix that is used to transform the texture coordinates into the coordinate
   *  space of the root texture, if this instance is not the root. @default null
   *
   *  <p>CAUTION: not a copy, but the actual object! Never modify this matrix!</p> */
  private function get_transformationMatrixToRoot():Matrix
  {
    return null;
  }

  /** Returns the maximum size constraint (for both width and height) for textures in the
   *  current Context3D profile. */
  private static function get_maxSize():Int
  {
    var target:Starling = Starling.current;
    var profile:String = (target != null) ? target.profile:"baseline";

    if (profile == "baseline" || profile == "baselineConstrained")
    {
      return 2048;
    }
    else
    {
      return 4096;
    }
  }
}

