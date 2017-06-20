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

import flash.geom.Rectangle;
import starling.display.Stage;
import starling.rendering.FilterEffect;
import starling.rendering.Painter;
import starling.textures.Texture;
import flash.display.BitmapDataChannel;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.geom.Matrix3D;
import starling.core.Starling;
import openfl.Vector;

import starling.rendering.Program;
import starling.rendering.VertexDataFormat;

import starling.utils.RenderUtil;

/** The DisplacementMapFilter class uses the pixel values from the specified texture (called
 *  the map texture) to perform a displacement of an object. You can use this filter
 *  to apply a warped or mottled effect to any object that inherits from the DisplayObject
 *  class.
 *
 *  <p>The filter uses the following formula:</p>
 *  <listing>dstPixel[x, y] = srcPixel[x + ((componentX(x, y) - 128) &#42; scaleX) / 256,
 *                      y + ((componentY(x, y) - 128) &#42; scaleY) / 256]
 *  </listing>
 *
 *  <p>Where <code>componentX(x, y)</code> gets the componentX property color value from the
 *  map texture at <code>(x - mapPoint.x, y - mapPoint.y)</code>.</p>
 */
class DisplacementMapFilter extends FragmentFilter
{
  public var componentX(get, set):Int;
  public var componentY(get, set):Int;
  public var scaleX(get, set):Float;
  public var scaleY(get, set):Float;
  public var mapX(get, set):Float;
  public var mapY(get, set):Float;
  public var mapTexture(get, set):Texture;
  public var mapRepeat(get, set):Bool;
  private var dispEffect(get, never):DisplacementMapEffect;

  private var _mapX:Float = 0;
  private var _mapY:Float = 0;

  // helpers
  private static var sBounds:Rectangle = new Rectangle();

  /** Creates a new displacement map filter that uses the provided map texture. */
  public function new(mapTexture:Texture,
      componentX:Int = 0, componentY:Int = 0,
      scaleX:Float = 0.0, scaleY:Float = 0.0)
  {
    super();
    _mapX = _mapY = 0;

    this.mapTexture = mapTexture;
    this.componentX = componentX;
    this.componentY = componentY;
    this.scaleX = scaleX;
    this.scaleY = scaleY;
  }

  /** @private */
  override public function process(painter:Painter, pool:IFilterHelper,
      input0:Texture = null, input1:Texture = null,
      input2:Texture = null, input3:Texture = null):Texture
  {
    var offsetX:Float = 0.0;
    var offsetY:Float = 0.0;
    var targetBounds:Rectangle = pool.targetBounds;
    var stage:Stage = pool.target.stage;

    if (stage != null && (targetBounds.x < 0 || targetBounds.y < 0))
    {
      // 'targetBounds' is actually already intersected with the stage bounds.
      // If the target is partially outside the stage at the left or top, we need
      // to adjust the map coordinates accordingly. That's what 'offsetX/Y' is for.

      pool.target.getBounds(stage, sBounds);
      sBounds.inflate(padding.left, padding.top);
      offsetX = sBounds.x - pool.targetBounds.x;
      offsetY = sBounds.y - pool.targetBounds.y;
    }

    updateVertexData(input0, mapTexture, offsetX, offsetY);
    return super.process(painter, pool, input0);
  }

  /** @private */
  override private function createEffect():FilterEffect
  {
    return new DisplacementMapEffect();
  }

  private function updateVertexData(inputTexture:Texture, mapTexture:Texture,
      mapOffsetX:Float = 0.0, mapOffsetY:Float = 0.0):Void
  {
    // The size of input texture and map texture may be different. We need to calculate
    // the right values for the texture coordinates at the filter vertices.

    var mapX:Float = (_mapX + mapOffsetX + padding.left) / mapTexture.width;
    var mapY:Float = (_mapY + mapOffsetY + padding.top) / mapTexture.height;
    var maxU:Float = inputTexture.width / mapTexture.width;
    var maxV:Float = inputTexture.height / mapTexture.height;

    mapTexture.setTexCoords(vertexData, 0, "mapTexCoords", -mapX, -mapY);
    mapTexture.setTexCoords(vertexData, 1, "mapTexCoords", -mapX + maxU, -mapY);
    mapTexture.setTexCoords(vertexData, 2, "mapTexCoords", -mapX, -mapY + maxV);
    mapTexture.setTexCoords(vertexData, 3, "mapTexCoords", -mapX + maxU, -mapY + maxV);
  }

  private function updatePadding():Void
  {
    var paddingX:Float = Math.ceil(Math.abs(dispEffect.scaleX) / 2);
    var paddingY:Float = Math.ceil(Math.abs(dispEffect.scaleY) / 2);

    padding.setTo(paddingX, paddingX, paddingY, paddingY);
  }

  // properties

  /** Describes which color channel to use in the map image to displace the x result.
   *  Possible values are constants from the BitmapDataChannel class. */
  private function get_componentX():Int
  {
    return dispEffect.componentX;
  }
  private function set_componentX(value:Int):Int
  {
    if (dispEffect.componentX != value)
    {
      dispEffect.componentX = value;
      setRequiresRedraw();
    }
    return value;
  }

  /** Describes which color channel to use in the map image to displace the y result.
   *  Possible values are constants from the BitmapDataChannel class. */
  private function get_componentY():Int
  {
    return dispEffect.componentY;
  }
  private function set_componentY(value:Int):Int
  {
    if (dispEffect.componentY != value)
    {
      dispEffect.componentY = value;
      setRequiresRedraw();
    }
    return value;
  }

  /** The multiplier used to scale the x displacement result from the map calculation. */
  private function get_scaleX():Float
  {
    return dispEffect.scaleX;
  }
  private function set_scaleX(value:Float):Float
  {
    if (dispEffect.scaleX != value)
    {
      dispEffect.scaleX = value;
      updatePadding();
    }
    return value;
  }

  /** The multiplier used to scale the y displacement result from the map calculation. */
  private function get_scaleY():Float
  {
    return dispEffect.scaleY;
  }
  private function set_scaleY(value:Float):Float
  {
    if (dispEffect.scaleY != value)
    {
      dispEffect.scaleY = value;
      updatePadding();
    }
    return value;
  }

  /** The horizontal offset of the map texture relative to the origin. @default 0 */
  private function get_mapX():Float
  {
    return _mapX;
  }
  private function set_mapX(value:Float):Float
  {
    _mapX = value;setRequiresRedraw();
    return value;
  }

  /** The vertical offset of the map texture relative to the origin. @default 0 */
  private function get_mapY():Float
  {
    return _mapY;
  }
  private function set_mapY(value:Float):Float
  {
    _mapY = value;setRequiresRedraw();
    return value;
  }

  /** The texture that will be used to calculate displacement. */
  private function get_mapTexture():Texture
  {
    return dispEffect.mapTexture;
  }
  private function set_mapTexture(value:Texture):Texture
  {
    if (dispEffect.mapTexture != value)
    {
      dispEffect.mapTexture = value;
      setRequiresRedraw();
    }
    return value;
  }

  /** Indicates how the pixels of the map texture will be wrapped at the edge. */
  private function get_mapRepeat():Bool
  {
    return dispEffect.mapRepeat;
  }
  private function set_mapRepeat(value:Bool):Bool
  {
    if (dispEffect.mapRepeat != value)
    {
      dispEffect.mapRepeat = value;
      setRequiresRedraw();
    }
    return value;
  }

  private function get_dispEffect():DisplacementMapEffect
  {
    return cast(this.effect, DisplacementMapEffect);
  }
}




class DisplacementMapEffect extends FilterEffect
{
  public var componentX(get, set):Int;
  public var componentY(get, set):Int;
  public var scaleX(get, set):Float;
  public var scaleY(get, set):Float;
  public var mapTexture(get, set):Texture;
  public var mapRepeat(get, set):Bool;

  public static var VERTEX_FORMAT:VertexDataFormat =
    FilterEffect.VERTEX_FORMAT.extend("mapTexCoords:float2");

  private var _mapTexture:Texture = null;
  private var _mapRepeat:Bool = false;
  private var _componentX:Int = 0;
  private var _componentY:Int = 0;
  private var _scaleX:Float = 0;
  private var _scaleY:Float = 0;

  // helper objects
  private static var sOffset:Vector<Float> = Vector.ofArray([0.5, 0.5, 0.0, 0.0]);
  private static var sMatrix:Matrix3D = new Matrix3D();
  private static var sMatrixData:Vector<Float> =
    Vector.ofArray([0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);

  public function new()
  {
    super();
    _componentX = _componentY = 0;
    _scaleX = _scaleY = 0;
  }

  override private function createProgram():Program
  {
    if (_mapTexture != null)
    {
      // vc0-3: mvpMatrix
      // va0:   vertex position
      // va1:   input texture coords
      // va2:   map texture coords

      var vertexShader:String = [
          "m44  op, va0, vc0",   // 4x4 matrix transform to output space
          "mov  v0, va1",   // pass input texture coordinates to fragment program
          "mov  v1, va2"  // pass map texture coordinates to fragment program
      ].join("\n");

      // v0:    input texCoords
      // v1:    map texCoords
      // fc0:   offset (0.5, 0.5)
      // fc1-4: matrix

      var fragmentShader:String = [
          FilterEffect.tex("ft0", "v1", 1, _mapTexture, false),   // read map texture
          "sub ft1, ft0, fc0",   // subtract 0.5 -> range [-0.5, 0.5]
          "mul ft1.xy, ft1.xy, ft0.ww",   // zero displacement when alpha == 0
          "m44 ft2, ft1, fc1",   // multiply matrix with displacement values
          "add ft3,  v0, ft2",   // add displacement values to texture coords
          FilterEffect.tex("oc", "ft3", 0, texture)  // read input texture at displaced coords
      ].join("\n");

      return Program.fromSource(vertexShader, fragmentShader);
    }
    else
    {
      return super.createProgram();
    }
  }

  override private function beforeDraw(context:Context3D):Void
  {
    super.beforeDraw(context);

    if (_mapTexture != null)
    {
      // already set by super class:
      //
      // vertex constants 0-3: mvpMatrix (3D)
      // vertex attribute 0:   vertex position (FLOAT_2)
      // vertex attribute 1:   texture coordinates (FLOAT_2)
      // texture 0:            input texture

      getMapMatrix(sMatrix);

      vertexFormat.setVertexBufferAt(2, vertexBuffer, "mapTexCoords");
      context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, sOffset);
      context.setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT, 1, sMatrix, true);
      RenderUtil.setSamplerStateAt(1, _mapTexture.mipMapping, textureSmoothing, _mapRepeat);
      context.setTextureAt(1, _mapTexture.base);
    }
  }

  override private function afterDraw(context:Context3D):Void
  {
    if (_mapTexture != null)
    {
      context.setVertexBufferAt(2, null);
      context.setTextureAt(1, null);
    }

    super.afterDraw(context);
  }

  override private function get_vertexFormat():VertexDataFormat
  {
    return VERTEX_FORMAT;
  }

  /** This matrix maps RGBA values of the map texture to UV-offsets in the input texture. */
  private function getMapMatrix(out:Matrix3D):Matrix3D
  {
    if (out == null)
    {
      out = new Matrix3D();
    }

    var columnX:Int;
    var columnY:Int;
    var scale:Float = Starling.contentScaleFactor_();
    var textureWidth:Float = texture.root.nativeWidth;
    var textureHeight:Float = texture.root.nativeHeight;

    for (i in 0...16)
    {
      sMatrixData[i] = 0;
    }

    if (_componentX == Std.int(BitmapDataChannel.RED))
    {
      columnX = 0;
    }
    else
    {
      if (_componentX == Std.int(BitmapDataChannel.GREEN))
      {
        columnX = 1;
      }
      else
      {
        if (_componentX == Std.int(BitmapDataChannel.BLUE))
        {
          columnX = 2;
        }
        else
        {
          columnX = 3;
        }
      }
    }

    if (_componentY == Std.int(BitmapDataChannel.RED))
    {
      columnY = 0;
    }
    else
    {
      if (_componentY == Std.int(BitmapDataChannel.GREEN))
      {
        columnY = 1;
      }
      else
      {
        if (_componentY == Std.int(BitmapDataChannel.BLUE))
        {
          columnY = 2;
        }
        else
        {
          columnY = 3;
        }
      }
    }

    sMatrixData[columnX * 4] = _scaleX * scale / textureWidth;
    sMatrixData[columnY * 4 + 1] = _scaleY * scale / textureHeight;

    out.copyRawDataFrom(sMatrixData);

    return out;
  }

  // properties

  private function get_componentX():Int
  {
    return _componentX;
  }
  private function set_componentX(value:Int):Int
  {
    _componentX = value;
    return value;
  }

  private function get_componentY():Int
  {
    return _componentY;
  }
  private function set_componentY(value:Int):Int
  {
    _componentY = value;
    return value;
  }

  private function get_scaleX():Float
  {
    return _scaleX;
  }
  private function set_scaleX(value:Float):Float
  {
    _scaleX = value;
    return value;
  }

  private function get_scaleY():Float
  {
    return _scaleY;
  }
  private function set_scaleY(value:Float):Float
  {
    _scaleY = value;
    return value;
  }

  private function get_mapTexture():Texture
  {
    return _mapTexture;
  }
  private function set_mapTexture(value:Texture):Texture
  {
    _mapTexture = value;
    return value;
  }

  private function get_mapRepeat():Bool
  {
    return _mapRepeat;
  }
  private function set_mapRepeat(value:Bool):Bool
  {
    _mapRepeat = value;
    return value;
  }
}
