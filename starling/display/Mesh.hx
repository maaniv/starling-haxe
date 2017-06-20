// =================================================================================================
//
//  Starling Framework
//  Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display;

import flash.errors.ArgumentError;
import haxe.Constraints.Function;
import flash.geom.Point;
import flash.geom.Rectangle;
import starling.geom.Polygon;
import starling.rendering.IndexData;
import starling.rendering.Painter;
import starling.rendering.VertexData;
import starling.rendering.VertexDataFormat;
import starling.styles.MeshStyle;
import starling.textures.Texture;
import starling.utils.MatrixUtil;
import starling.utils.MeshUtil;

/** The base class for all tangible (non-container) display objects, spawned up by a number
 *  of triangles.
 *
 *  <p>Since Starling uses Stage3D for rendering, all rendered objects must be constructed
 *  from triangles. A mesh stores the information of its triangles through VertexData and
 *  IndexData structures. The default format stores position, color and texture coordinates
 *  for each vertex.</p>
 *
 *  <p>How a mesh is rendered depends on its style. Per default, this is an instance
 *  of the <code>MeshStyle</code> base class; however, subclasses may extend its behavior
 *  to add support for color transformations, normal mapping, etc.</p>
 *
 *  @see MeshBatch
 *  @see starling.styles.MeshStyle
 *  @see starling.rendering.VertexData
 *  @see starling.rendering.IndexData
 */
class Mesh extends DisplayObject
{
  private var vertexData(get, never):VertexData;
  private var indexData(get, never):IndexData;
  public var style(get, set):MeshStyle;
  public var texture(get, set):Texture;
  public var color(get, set):UInt;
  public var textureSmoothing(get, set):String;
  public var textureRepeat(get, set):Bool;
  public var pixelSnapping(get, set):Bool;
  public var numVertices(get, never):Int;
  public var numIndices(get, never):Int;
  public var numTriangles(get, never):Int;
  public var vertexFormat(get, never):VertexDataFormat;
  public static var defaultStyle(get, set):Class<Dynamic>;
  public static var defaultStyleFactory(get, set):Function;

  /** @private */@:allow(starling.display)
  private var _style:MeshStyle = null;
  /** @private */@:allow(starling.display)
  private var _vertexData:VertexData = null;
  /** @private */@:allow(starling.display)
  private var _indexData:IndexData = null;
  /** @private */@:allow(starling.display)
  private var _pixelSnapping:Bool = false;

  private static var sDefaultStyle:Class<Dynamic> = MeshStyle;
  private static var sDefaultStyleFactory:Function = null;

  /** Creates a new mesh with the given vertices and indices.
   *  If you don't pass a style, an instance of <code>MeshStyle</code> will be created
   *  for you. Note that the format of the vertex data will be matched to the
   *  given style right away. */
  public function new(vertexData:VertexData, indexData:IndexData, style:MeshStyle = null)
  {
    super();
    if (vertexData == null)
    {
      throw new ArgumentError("VertexData must not be null");
    }
    if (indexData == null)
    {
      throw new ArgumentError("IndexData must not be null");
    }

    _vertexData = vertexData;
    _indexData = indexData;

    setStyle(style, false);
  }

  /** @inheritDoc */
  override public function dispose():Void
  {
    _vertexData.clear();
    _indexData.clear();

    super.dispose();
  }

  /** @inheritDoc */
  override public function hitTest(localPoint:Point):DisplayObject
  {
    if (!visible || !touchable || !hitTestMask(localPoint))
    {
      return null;
    }
    else
    {
      return (MeshUtil.containsPoint(_vertexData, _indexData, localPoint)) ? this:null;
    }
  }

  /** @inheritDoc */
  override public function getBounds(targetSpace:DisplayObject, out:flash.geom.Rectangle = null):flash.geom.Rectangle
  {
    return MeshUtil.calculateBounds(_vertexData, this, targetSpace, out);
  }

  /** @inheritDoc */
  override public function render(painter:Painter):Void
  {
    if (_pixelSnapping)
    {
      MatrixUtil.snapToPixels(painter.state.modelviewMatrix, painter.pixelSize);
    }

    painter.batchMesh(this);
  }

  /** Sets the style that is used to render the mesh. Styles (which are always subclasses of
   *  <code>MeshStyle</code>) provide a means to completely modify the way a mesh is rendered.
   *  For example, they may add support for color transformations or normal mapping.
   *
   *  <p>When assigning a new style, the vertex format will be changed to fit it.
   *  Do not use the same style instance on multiple objects! Instead, make use of
   *  <code>style.clone()</code> to assign an identical style to multiple meshes.</p>
   *
   *  @param meshStyle             the style to assign. If <code>null</code>, the default
   *                               style will be created.
   *  @param mergeWithPredecessor  if enabled, all attributes of the previous style will be
   *                               be copied to the new one, if possible.
   *  @see #defaultStyle
   *  @see #defaultStyleFactory
   */
  public function setStyle(meshStyle:MeshStyle = null, mergeWithPredecessor:Bool = true):Void
  {
    if (meshStyle == null)
    {
      meshStyle = createDefaultMeshStyle();
    }
    else
    {
      if (meshStyle == _style)
      {
        return;
      }
      else
      {
        if (meshStyle.target != null)
        {
          meshStyle.target.setStyle();
        }
      }
    }

    if (_style != null)
    {
      if (mergeWithPredecessor)
      {
        meshStyle.copyFrom(_style);
      }
      _style.setTarget(null);
    }

    _style = meshStyle;
    _style.setTarget(this, _vertexData, _indexData);
  }

  private function createDefaultMeshStyle():MeshStyle
  {
    var meshStyle:MeshStyle = null;

    if (sDefaultStyleFactory != null)
    {
      // if (as3hx.Compat.getFunctionLength(sDefaultStyleFactory) == 0)
      // {
      //   meshStyle = sDefaultStyleFactory();
      // }
      // else
      // {
      //   meshStyle = sDefaultStyleFactory(this);
      // }
      meshStyle = sDefaultStyleFactory(this);
    }

    if (meshStyle == null)
    {
      meshStyle = Type.createInstance(sDefaultStyle, []);
    }

    return meshStyle;
  }

  /** This method is called whenever the mesh's vertex data was changed.
   *  The base implementation simply forwards to <code>setRequiresRedraw</code>. */
  public function setVertexDataChanged():Void
  {
    setRequiresRedraw();
  }

  /** This method is called whenever the mesh's index data was changed.
   *  The base implementation simply forwards to <code>setRequiresRedraw</code>. */
  public function setIndexDataChanged():Void
  {
    setRequiresRedraw();
  }

  // vertex manipulation

  /** The position of the vertex at the specified index, in the mesh's local coordinate
   *  system.
   *
   *  <p>Only modify the position of a vertex if you know exactly what you're doing, as
   *  some classes might not work correctly when their vertices are moved. E.g. the
   *  <code>Quad</code> class expects its vertices to spawn up a perfectly rectangular
   *  area; some of its optimized methods won't work correctly if that premise is no longer
   *  fulfilled or the original bounds change.</p>
   */
  public function getVertexPosition(vertexID:Int, out:Point = null):Point
  {
    return _style.getVertexPosition(vertexID, out);
  }

  public function setVertexPosition(vertexID:Int, x:Float, y:Float):Void
  {
    _style.setVertexPosition(vertexID, x, y);
  }

  /** Returns the alpha value of the vertex at the specified index. */
  public function getVertexAlpha(vertexID:Int):Float
  {
    return _style.getVertexAlpha(vertexID);
  }

  /** Sets the alpha value of the vertex at the specified index to a certain value. */
  public function setVertexAlpha(vertexID:Int, alpha:Float):Void
  {
    _style.setVertexAlpha(vertexID, alpha);
  }

  /** Returns the RGB color of the vertex at the specified index. */
  public function getVertexColor(vertexID:Int):Int
  {
    return _style.getVertexColor(vertexID);
  }

  /** Sets the RGB color of the vertex at the specified index to a certain value. */
  public function setVertexColor(vertexID:Int, color:Int):Void
  {
    _style.setVertexColor(vertexID, color);
  }

  /** Returns the texture coordinates of the vertex at the specified index. */
  public function getTexCoords(vertexID:Int, out:Point = null):Point
  {
    return _style.getTexCoords(vertexID, out);
  }

  /** Sets the texture coordinates of the vertex at the specified index to the given values. */
  public function setTexCoords(vertexID:Int, u:Float, v:Float):Void
  {
    _style.setTexCoords(vertexID, u, v);
  }

  // properties

  /** The vertex data describing all vertices of the mesh.
   *  Any change requires a call to <code>setRequiresRedraw</code>. */
  private function get_vertexData():VertexData
  {
    return _vertexData;
  }

  /** The index data describing how the vertices are interconnected.
   *  Any change requires a call to <code>setRequiresRedraw</code>. */
  private function get_indexData():IndexData
  {
    return _indexData;
  }

  /** The style that is used to render the mesh. Styles (which are always subclasses of
   *  <code>MeshStyle</code>) provide a means to completely modify the way a mesh is rendered.
   *  For example, they may add support for color transformations or normal mapping.
   *
   *  <p>The setter will simply forward the assignee to <code>setStyle(value)</code>.</p>
   *
   *  @default MeshStyle
   */
  private function get_style():MeshStyle
  {
    return _style;
  }
  private function set_style(value:MeshStyle):MeshStyle
  {
    setStyle(value);
    return value;
  }

  /** The texture that is mapped to the mesh (or <code>null</code>, if there is none). */
  private function get_texture():Texture
  {
    return _style.texture;
  }
  private function set_texture(value:Texture):Texture
  {
    _style.texture = value;
    return value;
  }

  /** Changes the color of all vertices to the same value.
   *  The getter simply returns the color of the first vertex. */
  private function get_color():UInt
  {
    return _style.color;
  }
  private function set_color(value:UInt):UInt
  {
    _style.color = value;
    return value;
  }

  /** The smoothing filter that is used for the texture.
   *  @default bilinear */
  private function get_textureSmoothing():String
  {
    return _style.textureSmoothing;
  }
  private function set_textureSmoothing(value:String):String
  {
    _style.textureSmoothing = value;
    return value;
  }

  /** Indicates if pixels at the edges will be repeated or clamped. Only works for
   *  power-of-two textures; for a solution that works with all kinds of textures,
   *  see <code>Image.tileGrid</code>. @default false */
  private function get_textureRepeat():Bool
  {
    return _style.textureRepeat;
  }
  private function set_textureRepeat(value:Bool):Bool
  {
    _style.textureRepeat = value;
    return value;
  }

  /** Controls whether or not the instance snaps to the nearest pixel. This can prevent the
   *  object from looking blurry when it's not exactly aligned with the pixels of the screen.
   *  @default false */
  private function get_pixelSnapping():Bool
  {
    return _pixelSnapping;
  }
  private function set_pixelSnapping(value:Bool):Bool
  {
    _pixelSnapping = value;
    return value;
  }

  /** The total number of vertices in the mesh. */
  private function get_numVertices():Int
  {
    return _vertexData.numVertices;
  }

  /** The total number of indices referencing vertices. */
  private function get_numIndices():Int
  {
    return _indexData.numIndices;
  }

  /** The total number of triangles in this mesh.
   *  (In other words: the number of indices divided by three.) */
  private function get_numTriangles():Int
  {
    return _indexData.numTriangles;
  }

  /** The format used to store the vertices. */
  private function get_vertexFormat():VertexDataFormat
  {
    return _style.vertexFormat;
  }

  // static properties

  /** The default style used for meshes if no specific style is provided. The default is
   *  <code>starling.rendering.MeshStyle</code>, and any assigned class must be a subclass
   *  of the same. */
  private static function get_defaultStyle():Class<Dynamic>
  {
    return sDefaultStyle;
  }
  private static function set_defaultStyle(value:Class<Dynamic>):Class<Dynamic>
  {
    sDefaultStyle = value;
    return value;
  }

  /** A factory method that is used to create the 'MeshStyle' for a mesh if no specific
   *  style is provided. That's useful if you are creating a hierarchy of objects, all
   *  of which need to have a certain style. Different to the <code>defaultStyle</code>
   *  property, this method allows plugging in custom logic and passing arguments to the
   *  constructor. Return <code>null</code> to fall back to the default behavior (i.e.
   *  to instantiate <code>defaultStyle</code>). The <code>mesh</code>-parameter is optional
   *  and may be omitted.
   *
   *  <listing>
   *  Mesh.defaultStyleFactory = function(mesh:Mesh):MeshStyle
   *  {
   *      return new ColorizeMeshStyle(Math.random() * 0xffffff);
   *  }</listing>
   */
  private static function get_defaultStyleFactory():Function
  {
    return sDefaultStyleFactory;
  }
  private static function set_defaultStyleFactory(value:Function):Function
  {
    sDefaultStyleFactory = value;
    return value;
  }

  // static methods

  /** Creates a mesh from the specified polygon.
   *  Vertex positions and indices will be set up according to the polygon;
   *  any other vertex attributes (e.g. texture coordinates) need to be set up manually.
   */
  public static function fromPolygon(polygon:Polygon, style:MeshStyle = null):Mesh
  {
    var vertexData:VertexData = new VertexData(null, polygon.numVertices);
    var indexData:IndexData = new IndexData(polygon.numTriangles);

    polygon.copyToVertexData(vertexData);
    polygon.triangulate(indexData);

    return new Mesh(vertexData, indexData, style);
  }
}

