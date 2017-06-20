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

import flash.errors.Error;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Vector3D;
import starling.events.Event;
import starling.rendering.Painter;
import starling.utils.MathUtil;
import starling.utils.MatrixUtil;
import starling.utils.Rad2deg;

/** A container that allows you to position objects in three-dimensional space.
 *
 *  <p>Starling is, at its heart, a 2D engine. However, sometimes, simple 3D effects are
 *  useful for special effects, e.g. for screen transitions or to turn playing cards
 *  realistically. This class makes it possible to create such 3D effects.</p>
 *
 *  <p><strong>Positioning objects in 3D</strong></p>
 *
 *  <p>Just like a normal sprite, you can add and remove children to this container, which
 *  allows you to group several display objects together. In addition to that, Sprite3D
 *  adds some interesting properties:</p>
 *
 *  <ul>
 *    <li>z - Moves the sprite closer to / further away from the camera.</li>
 *    <li>rotationX — Rotates the sprite around the x-axis.</li>
 *    <li>rotationY — Rotates the sprite around the y-axis.</li>
 *    <li>scaleZ - Scales the sprite along the z-axis.</li>
 *    <li>pivotZ - Moves the pivot point along the z-axis.</li>
 *  </ul>
 *
 *  <p>With the help of these properties, you can move a sprite and all its children in the
 *  3D space. By nesting several Sprite3D containers, it's even possible to construct simple
 *  volumetric objects (like a cube).</p>
 *
 *  <p>Note that Starling does not make any z-tests: visibility is solely established by the
 *  order of the children, just as with 2D objects.</p>
 *
 *  <p><strong>Setting up the camera</strong></p>
 *
 *  <p>The camera settings are found directly on the stage. Modify the 'focalLength' or
 *  'fieldOfView' properties to change the distance between stage and camera; use the
 *  'projectionOffset' to move it to a different position.</p>
 *
 *  <p><strong>Limitations</strong></p>
 *
 *  <p>On rendering, each Sprite3D requires its own draw call — except if the object does not
 *  contain any 3D transformations ('z', 'rotationX/Y' and 'pivotZ' are zero). Furthermore,
 *  it interrupts the render cache, i.e. the cache cannot contain objects within different
 *  3D coordinate systems. Flat contents within the Sprite3D will be cached, though.</p>
 *
 */
class Sprite3D extends DisplayObjectContainer
{
  public var z(get, set):Float;
  public var pivotZ(get, set):Float;
  public var scaleZ(get, set):Float;
  public var rotationX(get, set):Float;
  public var rotationY(get, set):Float;
  public var rotationZ(get, set):Float;

  private static inline var E:Float = 0.00001;

  private var _rotationX:Float = 0;
  private var _rotationY:Float = 0;
  private var _scaleZ:Float = 0;
  private var _pivotZ:Float = 0;
  private var _z:Float = 0;

  //private var _transformationMatrix:Matrix;
  //private var _transformationMatrix3D:Matrix3D;
  private var _transformationChanged:Bool = false;
  private var _is2D:Bool = false;

  /** Helper objects. */
  private static var sHelperPoint:Vector3D = new Vector3D();
  private static var sHelperPointAlt:Vector3D = new Vector3D();
  private static var sHelperMatrix:Matrix3D = new Matrix3D();

  /** Creates an empty Sprite3D. */
  public function new()
  {
    super();
    _scaleZ = 1.0;
    _rotationX = _rotationY = _pivotZ = _z = 0.0;
    _transformationMatrix = new Matrix();
    _transformationMatrix3D = new Matrix3D();
    _is2D = true;  // meaning: this 3D object contains only 2D content
    setIs3D(true);  // meaning: this display object supports 3D transformations

    addEventListener(Event.ADDED, onAddedChild);
    addEventListener(Event.REMOVED, onRemovedChild);
  }

  /** @inheritDoc */
  override public function render(painter:Painter):Void
  {
    if (_is2D)
    {
      super.render(painter);
    }
    else
    {
      painter.finishMeshBatch();
      painter.pushState();
      painter.state.transformModelviewMatrix3D(transformationMatrix3D);

      super.render(painter);

      painter.finishMeshBatch();
      painter.excludeFromCache(this);
      painter.popState();
    }
  }

  /** @inheritDoc */
  override public function hitTest(localPoint:Point):DisplayObject
  {
    if (_is2D)
    {
      return super.hitTest(localPoint);
    }
    else
    {
      if (!visible || !touchable)
      {
        return null;
      }

      // We calculate the interception point between the 3D plane that is spawned up
      // by this sprite3D and the straight line between the camera and the hit point.

      sHelperMatrix.copyFrom(transformationMatrix3D);
      sHelperMatrix.invert();

      stage.getCameraPosition(this, sHelperPoint);
      MatrixUtil.transformCoords3D(sHelperMatrix, localPoint.x, localPoint.y, 0, sHelperPointAlt);
      MathUtil.intersectLineWithXYPlane(sHelperPoint, sHelperPointAlt, localPoint);

      return super.hitTest(localPoint);
    }
  }

  /** @private */
  override public function setRequiresRedraw():Void
  {
    _is2D = _z > -E && _z < E &&
        _rotationX > -E && _rotationX < E &&
        _rotationY > -E && _rotationY < E &&
        _pivotZ > -E && _pivotZ < E;

    super.setRequiresRedraw();
  }

  // helpers

  private function onAddedChild(event:Event):Void
  {
    recursivelySetIs3D(cast(event.target, DisplayObject), true);
  }

  private function onRemovedChild(event:Event):Void
  {
    recursivelySetIs3D(cast(event.target, DisplayObject), false);
  }

  private function recursivelySetIs3D(object:DisplayObject, value:Bool):Void
  {
    if (Std.is(object, Sprite3D))
    {
      return;
    }

    if (Std.is(object, DisplayObjectContainer))
    {
      var container:DisplayObjectContainer = cast(object);
      var numChildren:Int = container.numChildren;

      for (i in 0...numChildren)
      {
        recursivelySetIs3D(container.getChildAt(i), value);
      }
    }

    object.setIs3D(value);
  }

  private function updateMatrices():Void
  {
    var x:Float = this.x;
    var y:Float = this.y;
    var scaleX:Float = this.scaleX;
    var scaleY:Float = this.scaleY;
    var pivotX:Float = this.pivotX;
    var pivotY:Float = this.pivotY;
    var rotationZ:Float = this.rotation;

    _transformationMatrix3D.identity();

    if (scaleX != 1.0 || scaleY != 1.0 || _scaleZ != 1.0)
    {
      _transformationMatrix3D.appendScale(scaleX != 0 ? scaleX : E, scaleY != 0 ? scaleY : E, _scaleZ != 0 ? _scaleZ : E);
    }
    if (_rotationX != 0.0)
    {
      _transformationMatrix3D.appendRotation(Rad2deg.rad2deg(_rotationX), Vector3D.X_AXIS);
    }
    if (_rotationY != 0.0)
    {
      _transformationMatrix3D.appendRotation(Rad2deg.rad2deg(_rotationY), Vector3D.Y_AXIS);
    }
    if (rotationZ != 0.0)
    {
      _transformationMatrix3D.appendRotation(Rad2deg.rad2deg(rotationZ), Vector3D.Z_AXIS);
    }
    if (x != 0.0 || y != 0.0 || _z != 0.0)
    {
      _transformationMatrix3D.appendTranslation(x, y, _z);
    }
    if (pivotX != 0.0 || pivotY != 0.0 || _pivotZ != 0.0)
    {
      _transformationMatrix3D.prependTranslation(-pivotX, -pivotY, -_pivotZ);
    }

    if (_is2D)
    {
      MatrixUtil.convertTo2D(_transformationMatrix3D, _transformationMatrix);
    }
    else
    {
      _transformationMatrix.identity();
    }
  }

  // properties

  /** The 2D transformation matrix of the object relative to its parent — if it can be
   *  represented in such a matrix (the values of 'z', 'rotationX/Y', and 'pivotZ' are
   *  zero). Otherwise, the identity matrix. CAUTION: not a copy, but the actual object! */
  override private function get_transformationMatrix():Matrix
  {
    if (_transformationChanged)
    {
      updateMatrices();
      _transformationChanged = false;
    }

    return _transformationMatrix;
  }

  override private function set_transformationMatrix(value:Matrix):Matrix
  {
    super.transformationMatrix = value;
    _rotationX = _rotationY = _pivotZ = _z = 0;
    _transformationChanged = true;
    return value;
  }

  /**  The 3D transformation matrix of the object relative to its parent.
   *   CAUTION: not a copy, but the actual object! */
  override private function get_transformationMatrix3D():Matrix3D
  {
    if (_transformationChanged)
    {
      updateMatrices();
      _transformationChanged = false;
    }

    return _transformationMatrix3D;
  }

  /** @inheritDoc */
  override private function set_x(value:Float):Float
  {
    super.x = value;
    _transformationChanged = true;
    return value;
  }

  /** @inheritDoc */
  override private function set_y(value:Float):Float
  {
    super.y = value;
    _transformationChanged = true;
    return value;
  }

  /** The z coordinate of the object relative to the local coordinates of the parent.
   *  The z-axis points away from the camera, i.e. positive z-values will move the object further
   *  away from the viewer. */
  private function get_z():Float
  {
    return _z;
  }
  private function set_z(value:Float):Float
  {
    _z = value;
    _transformationChanged = true;
    setRequiresRedraw();
    return value;
  }

  /** @inheritDoc */
  override private function set_pivotX(value:Float):Float
  {
    super.pivotX = value;
    _transformationChanged = true;
    return value;
  }

  /** @inheritDoc */
  override private function set_pivotY(value:Float):Float
  {
    super.pivotY = value;
    _transformationChanged = true;
    return value;
  }

  /** The z coordinate of the object's origin in its own coordinate space (default: 0). */
  private function get_pivotZ():Float
  {
    return _pivotZ;
  }
  private function set_pivotZ(value:Float):Float
  {
    _pivotZ = value;
    _transformationChanged = true;
    setRequiresRedraw();
    return value;
  }

  /** @inheritDoc */
  override private function set_scaleX(value:Float):Float
  {
    super.scaleX = value;
    _transformationChanged = true;
    return value;
  }

  /** @inheritDoc */
  override private function set_scaleY(value:Float):Float
  {
    super.scaleY = value;
    _transformationChanged = true;
    return value;
  }

  /** The depth scale factor. '1' means no scale, negative values flip the object. */
  private function get_scaleZ():Float
  {
    return _scaleZ;
  }
  private function set_scaleZ(value:Float):Float
  {
    _scaleZ = value;
    _transformationChanged = true;
    setRequiresRedraw();
    return value;
  }

  /** @private */
  override private function set_scale(value:Float):Float
  {
    scaleX = scaleY = scaleZ = value;
    return value;
  }

  /** @private */
  override private function set_skewX(value:Float):Float
  {
    throw new Error("3D objects do not support skewing");
    return value;
  }

  /** @private */
  override private function set_skewY(value:Float):Float
  {
    throw new Error("3D objects do not support skewing");
    return value;
  }

  /** The rotation of the object about the z axis, in radians.
   *  (In Starling, all angles are measured in radians.) */
  override private function set_rotation(value:Float):Float
  {
    super.rotation = value;
    _transformationChanged = true;
    return value;
  }

  /** The rotation of the object about the x axis, in radians.
   *  (In Starling, all angles are measured in radians.) */
  private function get_rotationX():Float
  {
    return _rotationX;
  }
  private function set_rotationX(value:Float):Float
  {
    _rotationX = MathUtil.normalizeAngle(value);
    _transformationChanged = true;
    setRequiresRedraw();
    return value;
  }

  /** The rotation of the object about the y axis, in radians.
   *  (In Starling, all angles are measured in radians.) */
  private function get_rotationY():Float
  {
    return _rotationY;
  }
  private function set_rotationY(value:Float):Float
  {
    _rotationY = MathUtil.normalizeAngle(value);
    _transformationChanged = true;
    setRequiresRedraw();
    return value;
  }

  /** The rotation of the object about the z axis, in radians.
   *  (In Starling, all angles are measured in radians.) */
  private function get_rotationZ():Float
  {
    return rotation;
  }
  private function set_rotationZ(value:Float):Float
  {
    rotation = value;
    return value;
  }
}
