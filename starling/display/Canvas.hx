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

import flash.geom.Point;
import starling.geom.Polygon;
import starling.rendering.IndexData;
import starling.rendering.VertexData;
import openfl.Vector;

/** A display object supporting basic vector drawing functionality. In its current state,
 *  the main use of this class is to provide a range of forms that can be used as masks.
 */
class Canvas extends DisplayObjectContainer
{
  private var _polygons:Vector<Polygon> = null;
  private var _fillColor:Int = 0;
  private var _fillAlpha:Float = 0;

  /** Creates a new (empty) Canvas. Call one or more of the 'draw' methods to add content. */
  public function new()
  {
    super();
    _polygons = new Vector();
    _fillColor = 0xffffff;
    _fillAlpha = 1.0;
    touchGroup = true;
  }

  /** @inheritDoc */
  override public function dispose():Void
  {
    _polygons.length = 0;
    super.dispose();
  }

  /** @inheritDoc */
  override public function hitTest(localPoint:Point):DisplayObject
  {
    if (!visible || !touchable || !hitTestMask(localPoint))
    {
      return null;
    }

    // we could also use the standard hit test implementation, but the polygon class can
    // do that much more efficiently (it contains custom implementations for circles, etc).

    var i:Int = 0;
    var len:Int = _polygons.length;
    while (i < len)
    {
      if (_polygons[i].containsPoint(localPoint))
      {
        return this;
      }
      ++i;
    }

    return null;
  }

  /** Draws a circle. */
  public function drawCircle(x:Float, y:Float, radius:Float):Void
  {
    appendPolygon(Polygon.createCircle(x, y, radius));
  }

  /** Draws an ellipse. */
  public function drawEllipse(x:Float, y:Float, width:Float, height:Float):Void
  {
    var radiusX:Float = width / 2.0;
    var radiusY:Float = height / 2.0;

    appendPolygon(Polygon.createEllipse(x + radiusX, y + radiusY, radiusX, radiusY));
  }

  /** Draws a rectangle. */
  public function drawRectangle(x:Float, y:Float, width:Float, height:Float):Void
  {
    appendPolygon(Polygon.createRectangle(x, y, width, height));
  }

  /** Draws an arbitrary polygon. */
  public function drawPolygon(polygon:Polygon):Void
  {
    appendPolygon(polygon);
  }

  /** Specifies a simple one-color fill that subsequent calls to drawing methods
   *  (such as <code>drawCircle()</code>) will use. */
  public function beginFill(color:Int = 0xffffff, alpha:Float = 1.0):Void
  {
    _fillColor = color;
    _fillAlpha = alpha;
  }

  /** Resets the color to 'white' and alpha to '1'. */
  public function endFill():Void
  {
    _fillColor = 0xffffff;
    _fillAlpha = 1.0;
  }

  /** Removes all existing vertices. */
  public function clear():Void
  {
    removeChildren(0, -1, true);
    _polygons.length = 0;
  }

  private function appendPolygon(polygon:Polygon):Void
  {
    var vertexData:VertexData = new VertexData();
    var indexData:IndexData = new IndexData(polygon.numTriangles * 3);

    polygon.triangulate(indexData);
    polygon.copyToVertexData(vertexData);

    vertexData.colorize("color", _fillColor, _fillAlpha);

    addChild(new Mesh(vertexData, indexData));
    _polygons[_polygons.length] = polygon;
  }
}

