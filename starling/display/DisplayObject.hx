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
import haxe.Constraints.Function;
import flash.errors.IllegalOperationError;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.system.Capabilities;
import flash.ui.Mouse;
import flash.ui.MouseCursor;
import starling.core.Starling;
import starling.errors.AbstractClassError;
import starling.errors.AbstractMethodError;
import starling.events.Event;
import starling.events.EventDispatcher;
import starling.events.TouchEvent;
import starling.filters.FragmentFilter;
import starling.rendering.BatchToken;
import starling.rendering.Painter;
import starling.utils.Align;
import starling.utils.MathUtil;
import starling.utils.MatrixUtil;
import openfl.Vector;

/** Dispatched when an object is added to a parent. */
@:meta(Event(name="added",type="starling.events.Event"))

/** Dispatched when an object is connected to the stage (directly or indirectly). */
@:meta(Event(name="addedToStage",type="starling.events.Event"))

/** Dispatched when an object is removed from its parent. */
@:meta(Event(name="removed",type="starling.events.Event"))

/** Dispatched when an object is removed from the stage and won't be rendered any longer. */
@:meta(Event(name="removedFromStage",type="starling.events.Event"))

/** Dispatched once every frame on every object that is connected to the stage. */
@:meta(Event(name="enterFrame",type="starling.events.EnterFrameEvent"))

/** Dispatched when an object is touched. Bubbles. */
@:meta(Event(name="touch",type="starling.events.TouchEvent"))

/** Dispatched when a key on the keyboard is released. */
@:meta(Event(name="keyUp",type="starling.events.KeyboardEvent"))

/** Dispatched when a key on the keyboard is pressed. */
@:meta(Event(name="keyDown",type="starling.events.KeyboardEvent"))

/**
 *  The DisplayObject class is the base class for all objects that are rendered on the
 *  screen.
 *
 *  <p><strong>The Display Tree</strong></p>
 *
 *  <p>In Starling, all displayable objects are organized in a display tree. Only objects that
 *  are part of the display tree will be displayed (rendered).</p>
 *
 *  <p>The display tree consists of leaf nodes (Image, Quad) that will be rendered directly to
 *  the screen, and of container nodes (subclasses of "DisplayObjectContainer", like "Sprite").
 *  A container is simply a display object that has child nodes - which can, again, be either
 *  leaf nodes or other containers.</p>
 *
 *  <p>At the base of the display tree, there is the Stage, which is a container, too. To create
 *  a Starling application, you create a custom Sprite subclass, and Starling will add an
 *  instance of this class to the stage.</p>
 *
 *  <p>A display object has properties that define its position in relation to its parent
 *  (x, y), as well as its rotation and scaling factors (scaleX, scaleY). Use the
 *  <code>alpha</code> and <code>visible</code> properties to make an object translucent or
 *  invisible.</p>
 *
 *  <p>Every display object may be the target of touch events. If you don't want an object to be
 *  touchable, you can disable the "touchable" property. When it's disabled, neither the object
 *  nor its children will receive any more touch events.</p>
 *
 *  <strong>Transforming coordinates</strong>
 *
 *  <p>Within the display tree, each object has its own local coordinate system. If you rotate
 *  a container, you rotate that coordinate system - and thus all the children of the
 *  container.</p>
 *
 *  <p>Sometimes you need to know where a certain point lies relative to another coordinate
 *  system. That's the purpose of the method <code>getTransformationMatrix</code>. It will
 *  create a matrix that represents the transformation of a point in one coordinate system to
 *  another.</p>
 *
 *  <strong>Customization</strong>
 *
 *  <p>DisplayObject is an abstract class, which means you cannot instantiate it directly,
 *  but have to use one of its many subclasses instead. For leaf nodes, this is typically
 *  'Mesh' or its subclasses 'Quad' and 'Image'. To customize rendering of these objects,
 *  you can use fragment filters (via the <code>filter</code>-property on 'DisplayObject')
 *  or mesh styles (via the <code>style</code>-property on 'Mesh'). Look at the respective
 *  class documentation for more information.</p>
 *
 *  @see DisplayObjectContainer
 *  @see Sprite
 *  @see Stage
 *  @see Mesh
 *  @see starling.filters.FragmentFilter
 *  @see starling.styles.MeshStyle
 */
class DisplayObject extends EventDispatcher
{
  private var isMask(get, never):Bool;
  public var requiresRedraw(get, never):Bool;
  public var transformationMatrix(get, set):Matrix;
  public var transformationMatrix3D(get, never):Matrix3D;
  public var is3D(get, never):Bool;
  public var useHandCursor(get, set):Bool;
  public var bounds(get, never):Rectangle;
  public var width(get, set):Float;
  public var height(get, set):Float;
  public var x(get, set):Float;
  public var y(get, set):Float;
  public var pivotX(get, set):Float;
  public var pivotY(get, set):Float;
  public var scaleX(get, set):Float;
  public var scaleY(get, set):Float;
  public var scale(get, set):Float;
  public var skewX(get, set):Float;
  public var skewY(get, set):Float;
  public var rotation(get, set):Float;
  private var isRotated(get, never):Bool;
  public var alpha(get, set):Float;
  public var visible(get, set):Bool;
  public var touchable(get, set):Bool;
  public var blendMode(get, set):String;
  public var name(get, set):String;
  public var filter(get, set):FragmentFilter;
  public var mask(get, set):DisplayObject;
  public var parent(get, never):DisplayObjectContainer;
  public var base(get, never):DisplayObject;
  public var root(get, never):DisplayObject;
  public var stage(get, never):Stage;

  // private members

  private var _x:Float = 0;
  private var _y:Float = 0;
  private var _pivotX:Float = 0;
  private var _pivotY:Float = 0;
  private var _scaleX:Float = 0;
  private var _scaleY:Float = 0;
  private var _skewX:Float = 0;
  private var _skewY:Float = 0;
  private var _rotation:Float = 0;
  private var _alpha:Float = 0;
  private var _visible:Bool = false;
  private var _touchable:Bool = false;
  private var _blendMode:String = null;
  private var _name:String = null;
  private var _useHandCursor:Bool = false;
  private var _transformationMatrix:Matrix = null;
  private var _transformationMatrix3D:Matrix3D = null;
  private var _orientationChanged:Bool = false;
  private var _is3D:Bool = false;
  private var _maskee:DisplayObject = null;

  // internal members (for fast access on rendering)

  /** @private */@:allow(starling.display)
  private var _parent:DisplayObjectContainer = null;
  /** @private */@:allow(starling.display)
  private var _lastParentOrSelfChangeFrameID:Int = 0;
  /** @private */@:allow(starling.display)
  private var _lastChildChangeFrameID:Int = 0;
  /** @private */@:allow(starling.display)
  private var _tokenFrameID:Int = 0;
  /** @private */@:allow(starling.display)
  private var _pushToken:BatchToken = new BatchToken();
  /** @private */@:allow(starling.display)
  private var _popToken:BatchToken = new BatchToken();
  /** @private */@:allow(starling.display)
  private var _hasVisibleArea:Bool = false;
  /** @private */@:allow(starling.display)
  private var _filter:FragmentFilter = null;
  /** @private */@:allow(starling.display)
  private var _mask:DisplayObject = null;

  // helper objects

  private static var sAncestors:Vector<DisplayObject> = new Vector();
  private static var sHelperPoint:Point = new Point();
  private static var sHelperPoint3D:Vector3D = new Vector3D();
  private static var sHelperPointAlt3D:Vector3D = new Vector3D();
  private static var sHelperRect:Rectangle = new Rectangle();
  private static var sHelperMatrix:Matrix = new Matrix();
  private static var sHelperMatrixAlt:Matrix = new Matrix();
  private static var sHelperMatrix3D:Matrix3D = new Matrix3D();
  private static var sHelperMatrixAlt3D:Matrix3D = new Matrix3D();

  /** @private */
  public function new()
  {
    super();
    if (Capabilities.isDebugger &&
      Type.getClassName(Type.getClass(this)) == "starling.display::DisplayObject")
    {
      throw new AbstractClassError();
    }

    _x = _y = _pivotX = _pivotY = _rotation = _skewX = _skewY = 0.0;
    _scaleX = _scaleY = _alpha = 1.0;
    _visible = _touchable = _hasVisibleArea = true;
    _blendMode = BlendMode.AUTO;
    _transformationMatrix = new Matrix();
  }

  /** Disposes all resources of the display object.
  * GPU buffers are released, event listeners are removed, filters and masks are disposed. */
  public function dispose():Void
  {
    if (_filter != null)
    {
      _filter.dispose();
    }
    if (_mask != null)
    {
      _mask.dispose();
    }
    removeEventListeners();
    mask = null;
  }

  /** Removes the object from its parent, if it has one, and optionally disposes it. */
  public function removeFromParent(dispose:Bool = false):Void
  {
    if (_parent != null)
    {
      _parent.removeChild(this, dispose);
    }
    else
    {
      if (dispose)
      {
        this.dispose();
      }
    }
  }

  /** Creates a matrix that represents the transformation from the local coordinate system
   *  to another. If you pass an <code>out</code>-matrix, the result will be stored in this
   *  matrix instead of creating a new object. */
  public function getTransformationMatrix(targetSpace:DisplayObject,
      out:Matrix = null):Matrix
  {
    var commonParent:DisplayObject;
    var currentObject:DisplayObject;

    if (out != null)
    {
      out.identity();
    }
    else
    {
      out = new Matrix();
    }

    if (targetSpace == this)
    {
      return out;
    }
    else
    {
      if (targetSpace == _parent || (targetSpace == null && _parent == null))
      {
        out.copyFrom(transformationMatrix);
        return out;
      }
      else
      {
        if (targetSpace == null || targetSpace == base)
        {
          // targetCoordinateSpace 'null' represents the target space of the base object.
          // -> move up from this to base

          currentObject = this;
          while (currentObject != targetSpace)
          {
            out.concat(currentObject.transformationMatrix);
            currentObject = currentObject._parent;
          }

          return out;
        }
        else
        {
          if (targetSpace._parent == this)
          {
            // optimization
            {
              targetSpace.getTransformationMatrix(this, out);
              out.invert();

              return out;
            }
          }
        }
      }
    }

    // 1. find a common parent of this and the target space

    commonParent = findCommonParent(this, targetSpace);

    // 2. move up from this to common parent

    currentObject = this;
    while (currentObject != commonParent)
    {
      out.concat(currentObject.transformationMatrix);
      currentObject = currentObject._parent;
    }

    if (commonParent == targetSpace)
    {
      return out;
    }

    // 3. now move up from target until we reach the common parent

    sHelperMatrix.identity();
    currentObject = targetSpace;
    while (currentObject != commonParent)
    {
      sHelperMatrix.concat(currentObject.transformationMatrix);
      currentObject = currentObject._parent;
    }

    // 4. now combine the two matrices

    sHelperMatrix.invert();
    out.concat(sHelperMatrix);

    return out;
  }

  /** Returns a rectangle that completely encloses the object as it appears in another
   *  coordinate system. If you pass an <code>out</code>-rectangle, the result will be
   *  stored in this rectangle instead of creating a new object. */
  public function getBounds(targetSpace:DisplayObject, out:Rectangle = null):Rectangle
  {
    throw new AbstractMethodError();
  }

  /** Returns the object that is found topmost beneath a point in local coordinates, or nil
   *  if the test fails. Untouchable and invisible objects will cause the test to fail. */
  public function hitTest(localPoint:Point):DisplayObject
  {
    // on a touch test, invisible or untouchable objects cause the test to fail
    if (!_visible || !_touchable)
    {
      return null;
    }

    // if we've got a mask and the hit occurs outside, fail
    if (_mask != null && !hitTestMask(localPoint))
    {
      return null;
    }

    // otherwise, check bounding box
    if (getBounds(this, sHelperRect).containsPoint(localPoint))
    {
      return this;
    }
    else
    {
      return null;
    }
  }

  /** Checks if a certain point is inside the display object's mask. If there is no mask,
   *  this method always returns <code>true</code> (because having no mask is equivalent
   *  to having one that's infinitely big). */
  public function hitTestMask(localPoint:Point):Bool
  {
    if (_mask != null)
    {
      if (_mask.stage != null)
      {
        getTransformationMatrix(_mask, sHelperMatrixAlt);
      }
      else
      {
        sHelperMatrixAlt.copyFrom(_mask.transformationMatrix);
        sHelperMatrixAlt.invert();
      }

      var helperPoint:Point = (localPoint == sHelperPoint) ? new Point():sHelperPoint;
      MatrixUtil.transformPoint(sHelperMatrixAlt, localPoint, helperPoint);
      return _mask.hitTest(helperPoint) != null;
    }
    else
    {
      return true;
    }
  }

  /** Transforms a point from the local coordinate system to global (stage) coordinates.
   *  If you pass an <code>out</code>-point, the result will be stored in this point instead
   *  of creating a new object. */
  public function localToGlobal(localPoint:Point, out:Point = null):Point
  {
    if (is3D)
    {
      sHelperPoint3D.setTo(localPoint.x, localPoint.y, 0);
      return local3DToGlobal(sHelperPoint3D, out);
    }
    else
    {
      getTransformationMatrix(base, sHelperMatrixAlt);
      return MatrixUtil.transformPoint(sHelperMatrixAlt, localPoint, out);
    }
  }

  /** Transforms a point from global (stage) coordinates to the local coordinate system.
   *  If you pass an <code>out</code>-point, the result will be stored in this point instead
   *  of creating a new object. */
  public function globalToLocal(globalPoint:Point, out:Point = null):Point
  {
    if (is3D)
    {
      globalToLocal3D(globalPoint, sHelperPoint3D);
      stage.getCameraPosition(this, sHelperPointAlt3D);
      return MathUtil.intersectLineWithXYPlane(sHelperPointAlt3D, sHelperPoint3D, out);
    }
    else
    {
      getTransformationMatrix(base, sHelperMatrixAlt);
      sHelperMatrixAlt.invert();
      return MatrixUtil.transformPoint(sHelperMatrixAlt, globalPoint, out);
    }
  }

  /** Renders the display object with the help of a painter object. Never call this method
   *  directly, except from within another render method.
   *
   *  @param painter Captures the current render state and provides utility functions
   *                 for rendering.
   */
  public function render(painter:Painter):Void
  {
    throw new AbstractMethodError();
  }

  /** Moves the pivot point to a certain position within the local coordinate system
   *  of the object. If you pass no arguments, it will be centered. */
  public function alignPivot(horizontalAlign:String = "center",
      verticalAlign:String = "center"):Void
  {
    var bounds:Rectangle = getBounds(this, sHelperRect);
    setOrientationChanged();

    if (horizontalAlign == Align.LEFT)
    {
      _pivotX = bounds.x;
    }
    else
    {
      if (horizontalAlign == Align.CENTER)
      {
        _pivotX = bounds.x + bounds.width / 2.0;
      }
      else
      {
        if (horizontalAlign == Align.RIGHT)
        {
          _pivotX = bounds.x + bounds.width;
        }
        else
        {
          throw new ArgumentError("Invalid horizontal alignment: " + horizontalAlign);
        }
      }
    }

    if (verticalAlign == Align.TOP)
    {
      _pivotY = bounds.y;
    }
    else
    {
      if (verticalAlign == Align.CENTER)
      {
        _pivotY = bounds.y + bounds.height / 2.0;
      }
      else
      {
        if (verticalAlign == Align.BOTTOM)
        {
          _pivotY = bounds.y + bounds.height;
        }
        else
        {
          throw new ArgumentError("Invalid vertical alignment: " + verticalAlign);
        }
      }
    }
  }

  // 3D transformation

  /** Creates a matrix that represents the transformation from the local coordinate system
   *  to another. This method supports three dimensional objects created via 'Sprite3D'.
   *  If you pass an <code>out</code>-matrix, the result will be stored in this matrix
   *  instead of creating a new object. */
  public function getTransformationMatrix3D(targetSpace:DisplayObject,
      out:Matrix3D = null):Matrix3D
  {
    var commonParent:DisplayObject;
    var currentObject:DisplayObject;

    if (out != null)
    {
      out.identity();
    }
    else
    {
      out = new Matrix3D();
    }

    if (targetSpace == this)
    {
      return out;
    }
    else
    {
      if (targetSpace == _parent || (targetSpace == null && _parent == null))
      {
        out.copyFrom(transformationMatrix3D);
        return out;
      }
      else
      {
        if (targetSpace == null || targetSpace == base)
        {
          // targetCoordinateSpace 'null' represents the target space of the base object.
          // -> move up from this to base

          currentObject = this;
          while (currentObject != targetSpace)
          {
            out.append(currentObject.transformationMatrix3D);
            currentObject = currentObject._parent;
          }

          return out;
        }
        else
        {
          if (targetSpace._parent == this)
          {
            // optimization
            {
              targetSpace.getTransformationMatrix3D(this, out);
              out.invert();

              return out;
            }
          }
        }
      }
    }

    // 1. find a common parent of this and the target space

    commonParent = findCommonParent(this, targetSpace);

    // 2. move up from this to common parent

    currentObject = this;
    while (currentObject != commonParent)
    {
      out.append(currentObject.transformationMatrix3D);
      currentObject = currentObject._parent;
    }

    if (commonParent == targetSpace)
    {
      return out;
    }

    // 3. now move up from target until we reach the common parent

    sHelperMatrix3D.identity();
    currentObject = targetSpace;
    while (currentObject != commonParent)
    {
      sHelperMatrix3D.append(currentObject.transformationMatrix3D);
      currentObject = currentObject._parent;
    }

    // 4. now combine the two matrices

    sHelperMatrix3D.invert();
    out.append(sHelperMatrix3D);

    return out;
  }

  /** Transforms a 3D point from the local coordinate system to global (stage) coordinates.
   *  This is achieved by projecting the 3D point onto the (2D) view plane.
   *
   *  <p>If you pass an <code>out</code>-point, the result will be stored in this point
   *  instead of creating a new object.</p> */
  public function local3DToGlobal(localPoint:Vector3D, out:Point = null):Point
  {
    var stage:Stage = this.stage;
    if (stage == null)
    {
      throw new IllegalOperationError("Object not connected to stage");
    }

    getTransformationMatrix3D(stage, sHelperMatrixAlt3D);
    MatrixUtil.transformPoint3D(sHelperMatrixAlt3D, localPoint, sHelperPoint3D);
    return MathUtil.intersectLineWithXYPlane(stage.cameraPosition, sHelperPoint3D, out);
  }

  /** Transforms a point from global (stage) coordinates to the 3D local coordinate system.
   *  If you pass an <code>out</code>-vector, the result will be stored in this vector
   *  instead of creating a new object. */
  public function globalToLocal3D(globalPoint:Point, out:Vector3D = null):Vector3D
  {
    var stage:Stage = this.stage;
    if (stage == null)
    {
      throw new IllegalOperationError("Object not connected to stage");
    }

    getTransformationMatrix3D(stage, sHelperMatrixAlt3D);
    sHelperMatrixAlt3D.invert();
    return MatrixUtil.transformCoords3D(
        sHelperMatrixAlt3D, globalPoint.x, globalPoint.y, 0, out
    );
  }

  // internal methods

  /** @private */
  private function setParent(value:DisplayObjectContainer):Void
  {
    // check for a recursion
    var ancestor:DisplayObject = value;
    while (ancestor != this && ancestor != null)
    {
      ancestor = ancestor._parent;
    }

    if (ancestor == this)
    {
      throw new ArgumentError("An object cannot be added as a child to itself or one " +
      "of its children (or children's children, etc.)");
    }
    else
    {
      _parent = value;
    }
  }

  /** @private */
  @:allow(starling.display)
  private function setIs3D(value:Bool):Void
  {
    _is3D = value;
  }

  /** @private */
  @:allow(starling.display)
  private function get_isMask():Bool
  {
    return _maskee != null;
  }

  // render cache

  /** Forces the object to be redrawn in the next frame.
   *  This will prevent the object to be drawn from the render cache.
   *
   *  <p>This method is called every time the object changes in any way. When creating
   *  custom mesh styles or any other custom rendering code, call this method if the object
   *  needs to be redrawn.</p>
   *
   *  <p>If the object needs to be redrawn just because it does not support the render cache,
   *  call <code>painter.excludeFromCache()</code> in the object's render method instead.
   *  That way, Starling's <code>skipUnchangedFrames</code> policy won't be disrupted.</p>
   */
  public function setRequiresRedraw():Void
  {
    var parent:DisplayObject = _parent != null ? parent : _maskee;
    var frameID:Int = Starling.frameID_();

    _lastParentOrSelfChangeFrameID = frameID;
    _hasVisibleArea = _alpha != 0.0 && _visible && _maskee == null &&
        _scaleX != 0.0 && _scaleY != 0.0;

    while (parent != null && parent._lastChildChangeFrameID != frameID)
    {
      parent._lastChildChangeFrameID = frameID;
      parent = parent._parent != null ? parent._parent : parent._maskee;
    }
  }

  /** Indicates if the object needs to be redrawn in the upcoming frame, i.e. if it has
   *  changed its location relative to the stage or some other aspect of its appearance
   *  since it was last rendered. */
  private function get_requiresRedraw():Bool
  {
    var frameID:Int = Starling.frameID_();

    return _lastParentOrSelfChangeFrameID == frameID ||
    _lastChildChangeFrameID == frameID;
  }

  /** @private Makes sure the object is not drawn from cache in the next frame.
   *  This method is meant to be called only from <code>Painter.finishFrame()</code>,
   *  since it requires rendering to be concluded. */
  @:allow(starling) private function excludeFromCache():Void
  {
    var object:DisplayObject = this;
    var max:Int = 0xffffffff;

    while (object != null && object._tokenFrameID != max)
    {
      object._tokenFrameID = max;
      object = object._parent;
    }
  }

  // helpers

  private function setOrientationChanged():Void
  {
    _orientationChanged = true;
    setRequiresRedraw();
  }

  private static function findCommonParent(object1:DisplayObject,
      object2:DisplayObject):DisplayObject
  {
    var currentObject:DisplayObject = object1;

    while (currentObject != null)
    {
      sAncestors[sAncestors.length] = currentObject;  // avoiding 'push'
      currentObject = currentObject._parent;
    }

    currentObject = object2;
    while (currentObject != null && sAncestors.indexOf(currentObject) == -1)
    {
      currentObject = currentObject._parent;
    }

    sAncestors.length = 0;

    if (currentObject != null)
    {
      return currentObject;
    }
    else
    {
      throw new ArgumentError("Object not connected to target");
    }
  }

  // stage event handling

  /** @private */
  override public function dispatchEvent(event:Event):Void
  {
    if (event.type == Event.REMOVED_FROM_STAGE && stage == null)
    {
      return;
    }
    else
    {
      // special check to avoid double-dispatch of RfS-event.
      super.dispatchEvent(event);
    }
  }

  // enter frame event optimization

  // To avoid looping through the complete display tree each frame to find out who's
  // listening to ENTER_FRAME events, we manage a list of them manually in the Stage class.
  // We need to take care that (a) it must be dispatched only when the object is
  // part of the stage, (b) it must not cause memory leaks when the user forgets to call
  // dispose and (c) there might be multiple listeners for this event.

  /** @inheritDoc */
  override public function addEventListener(type:String, listener:Function):Void
  {
    if (type == Event.ENTER_FRAME && !hasEventListener(type))
    {
      addEventListener(Event.ADDED_TO_STAGE, addEnterFrameListenerToStage);
      addEventListener(Event.REMOVED_FROM_STAGE, removeEnterFrameListenerFromStage);
      if (this.stage != null)
      {
        addEnterFrameListenerToStage();
      }
    }

    super.addEventListener(type, listener);
  }

  /** @inheritDoc */
  override public function removeEventListener(type:String, listener:Function):Void
  {
    super.removeEventListener(type, listener);

    if (type == Event.ENTER_FRAME && !hasEventListener(type))
    {
      removeEventListener(Event.ADDED_TO_STAGE, addEnterFrameListenerToStage);
      removeEventListener(Event.REMOVED_FROM_STAGE, removeEnterFrameListenerFromStage);
      removeEnterFrameListenerFromStage();
    }
  }

  /** @inheritDoc */
  override public function removeEventListeners(type:String = null):Void
  {
    if ((type == null || type == Event.ENTER_FRAME) && hasEventListener(Event.ENTER_FRAME))
    {
      removeEventListener(Event.ADDED_TO_STAGE, addEnterFrameListenerToStage);
      removeEventListener(Event.REMOVED_FROM_STAGE, removeEnterFrameListenerFromStage);
      removeEnterFrameListenerFromStage();
    }

    super.removeEventListeners(type);
  }

  private function addEnterFrameListenerToStage():Void
  {
    Starling.current.stage.addEnterFrameListener(this);
  }

  private function removeEnterFrameListenerFromStage():Void
  {
    Starling.current.stage.removeEnterFrameListener(this);
  }

  // properties

  /** The transformation matrix of the object relative to its parent.
   *
   *  <p>If you assign a custom transformation matrix, Starling will try to figure out
   *  suitable values for <code>x, y, scaleX, scaleY,</code> and <code>rotation</code>.
   *  However, if the matrix was created in a different way, this might not be possible.
   *  In that case, Starling will apply the matrix, but not update the corresponding
   *  properties.</p>
   *
   *  <p>CAUTION: not a copy, but the actual object!</p> */
  private function get_transformationMatrix():Matrix
  {
    if (_orientationChanged)
    {
      _orientationChanged = false;

      if (_skewX == 0.0 && _skewY == 0.0)
      {
        // optimization: no skewing / rotation simplifies the matrix math

        if (_rotation == 0.0)
        {
          _transformationMatrix.setTo(_scaleX, 0.0, 0.0, _scaleY,
              _x - _pivotX * _scaleX, _y - _pivotY * _scaleY
        );
        }
        else
        {
          var cos:Float = Math.cos(_rotation);
          var sin:Float = Math.sin(_rotation);
          var a:Float = _scaleX * cos;
          var b:Float = _scaleX * sin;
          var c:Float = _scaleY * -sin;
          var d:Float = _scaleY * cos;
          var tx:Float = _x - _pivotX * a - _pivotY * c;
          var ty:Float = _y - _pivotX * b - _pivotY * d;

          _transformationMatrix.setTo(a, b, c, d, tx, ty);
        }
      }
      else
      {
        _transformationMatrix.identity();
        _transformationMatrix.scale(_scaleX, _scaleY);
        MatrixUtil.skew(_transformationMatrix, _skewX, _skewY);
        _transformationMatrix.rotate(_rotation);
        _transformationMatrix.translate(_x, _y);

        if (_pivotX != 0.0 || _pivotY != 0.0)
        {
          // prepend pivot transformation
          _transformationMatrix.tx = _x - _transformationMatrix.a * _pivotX - _transformationMatrix.c * _pivotY;
          _transformationMatrix.ty = _y - _transformationMatrix.b * _pivotX - _transformationMatrix.d * _pivotY;
        }
      }
    }

    return _transformationMatrix;
  }

  private function set_transformationMatrix(matrix:Matrix):Matrix
  {
    var PI_Q:Float = Math.PI / 4.0;

    setRequiresRedraw();
    _orientationChanged = false;
    _transformationMatrix.copyFrom(matrix);
    _pivotX = _pivotY = 0;

    _x = matrix.tx;
    _y = matrix.ty;

    _skewX = Math.atan(-matrix.c / matrix.d);
    _skewY = Math.atan(matrix.b / matrix.a);

    // NaN check ("isNaN" causes allocation)
    if (_skewX != _skewX)
    {
      _skewX = 0.0;
    }
    if (_skewY != _skewY)
    {
      _skewY = 0.0;
    }

    _scaleY = ((_skewX > -PI_Q && _skewX < PI_Q)) ? matrix.d / Math.cos(_skewX):-matrix.c / Math.sin(_skewX);
    _scaleX = ((_skewY > -PI_Q && _skewY < PI_Q)) ? matrix.a / Math.cos(_skewY):matrix.b / Math.sin(_skewY);

    if (MathUtil.isEquivalent(_skewX, _skewY))
    {
      _rotation = _skewX;
      _skewX = _skewY = 0;
    }
    else
    {
      _rotation = 0;
    }
    return matrix;
  }

  /** The 3D transformation matrix of the object relative to its parent.
   *
   *  <p>For 2D objects, this property returns just a 3D version of the 2D transformation
   *  matrix. Only the 'Sprite3D' class supports real 3D transformations.</p>
   *
   *  <p>CAUTION: not a copy, but the actual object!</p> */
  private function get_transformationMatrix3D():Matrix3D
  {
    // this method needs to be overridden in 3D-supporting subclasses (like Sprite3D).

    if (_transformationMatrix3D == null)
    {
      _transformationMatrix3D = new Matrix3D();
    }

    return MatrixUtil.convertTo3D(transformationMatrix, _transformationMatrix3D);
  }

  /** Indicates if this object or any of its parents is a 'Sprite3D' object. */
  private function get_is3D():Bool
  {
    return _is3D;
  }

  /** Indicates if the mouse cursor should transform into a hand while it's over the sprite.
   *  @default false */
  private function get_useHandCursor():Bool
  {
    return _useHandCursor;
  }
  private function set_useHandCursor(value:Bool):Bool
  {
    if (value == _useHandCursor)
    {
      return value;
    }
    _useHandCursor = value;

    if (_useHandCursor)
    {
      addEventListener(TouchEvent.TOUCH, onTouch);
    }
    else
    {
      removeEventListener(TouchEvent.TOUCH, onTouch);
    }
    return value;
  }

  private function onTouch(event:TouchEvent):Void
  {
    Mouse.cursor = (event.interactsWith(this)) ? MouseCursor.BUTTON:MouseCursor.AUTO;
  }

  /** The bounds of the object relative to the local coordinates of the parent. */
  private function get_bounds():Rectangle
  {
    return getBounds(_parent);
  }

  /** The width of the object in pixels.
   *  Note that for objects in a 3D space (connected to a Sprite3D), this value might not
   *  be accurate until the object is part of the display list. */
  private function get_width():Float
  {
    return getBounds(_parent, sHelperRect).width;
  }
  private function set_width(value:Float):Float
  {
    // this method calls 'this.scaleX' instead of changing _scaleX directly.
    // that way, subclasses reacting on size changes need to override only the scaleX method.

    var actualWidth:Float;
    var scaleIsNaN:Bool = _scaleX != _scaleX;  // avoid 'isNaN' call

    if (_scaleX == 0.0 || scaleIsNaN)
    {
      scaleX = 1.0;actualWidth = width;
    }
    else
    {
      actualWidth = Math.abs(width / _scaleX);
    }

    if (actualWidth != 0 && !Math.isNaN(actualWidth))
    {
      scaleX = value / actualWidth;
    }
    return value;
  }

  /** The height of the object in pixels.
   *  Note that for objects in a 3D space (connected to a Sprite3D), this value might not
   *  be accurate until the object is part of the display list. */
  private function get_height():Float
  {
    return getBounds(_parent, sHelperRect).height;
  }
  private function set_height(value:Float):Float
  {
    var actualHeight:Float;
    var scaleIsNaN:Bool = _scaleY != _scaleY;  // avoid 'isNaN' call

    if (_scaleY == 0.0 || scaleIsNaN)
    {
      scaleY = 1.0;actualHeight = height;
    }
    else
    {
      actualHeight = Math.abs(height / _scaleY);
    }

    if (actualHeight != 0 && !Math.isNaN(actualHeight))
    {
      scaleY = value / actualHeight;
    }
    return value;
  }

  /** The x coordinate of the object relative to the local coordinates of the parent. */
  private function get_x():Float
  {
    return _x;
  }
  private function set_x(value:Float):Float
  {
    if (_x != value)
    {
      _x = value;
      setOrientationChanged();
    }
    return value;
  }

  /** The y coordinate of the object relative to the local coordinates of the parent. */
  private function get_y():Float
  {
    return _y;
  }
  private function set_y(value:Float):Float
  {
    if (_y != value)
    {
      _y = value;
      setOrientationChanged();
    }
    return value;
  }

  /** The x coordinate of the object's origin in its own coordinate space (default: 0). */
  private function get_pivotX():Float
  {
    return _pivotX;
  }
  private function set_pivotX(value:Float):Float
  {
    if (_pivotX != value)
    {
      _pivotX = value;
      setOrientationChanged();
    }
    return value;
  }

  /** The y coordinate of the object's origin in its own coordinate space (default: 0). */
  private function get_pivotY():Float
  {
    return _pivotY;
  }
  private function set_pivotY(value:Float):Float
  {
    if (_pivotY != value)
    {
      _pivotY = value;
      setOrientationChanged();
    }
    return value;
  }

  /** The horizontal scale factor. '1' means no scale, negative values flip the object.
   *  @default 1 */
  private function get_scaleX():Float
  {
    return _scaleX;
  }
  private function set_scaleX(value:Float):Float
  {
    if (_scaleX != value)
    {
      _scaleX = value;
      setOrientationChanged();
    }
    return value;
  }

  /** The vertical scale factor. '1' means no scale, negative values flip the object.
   *  @default 1 */
  private function get_scaleY():Float
  {
    return _scaleY;
  }
  private function set_scaleY(value:Float):Float
  {
    if (_scaleY != value)
    {
      _scaleY = value;
      setOrientationChanged();
    }
    return value;
  }

  /** Sets both 'scaleX' and 'scaleY' to the same value. The getter simply returns the
   *  value of 'scaleX' (even if the scaling values are different). @default 1 */
  private function get_scale():Float
  {
    return scaleX;
  }
  private function set_scale(value:Float):Float
  {
    scaleX = scaleY = value;
    return value;
  }

  /** The horizontal skew angle in radians. */
  private function get_skewX():Float
  {
    return _skewX;
  }
  private function set_skewX(value:Float):Float
  {
    value = MathUtil.normalizeAngle(value);

    if (_skewX != value)
    {
      _skewX = value;
      setOrientationChanged();
    }
    return value;
  }

  /** The vertical skew angle in radians. */
  private function get_skewY():Float
  {
    return _skewY;
  }
  private function set_skewY(value:Float):Float
  {
    value = MathUtil.normalizeAngle(value);

    if (_skewY != value)
    {
      _skewY = value;
      setOrientationChanged();
    }
    return value;
  }

  /** The rotation of the object in radians. (In Starling, all angles are measured
   *  in radians.) */
  private function get_rotation():Float
  {
    return _rotation;
  }
  private function set_rotation(value:Float):Float
  {
    value = MathUtil.normalizeAngle(value);

    if (_rotation != value)
    {
      _rotation = value;
      setOrientationChanged();
    }
    return value;
  }

  /** @private Indicates if the object is rotated or skewed in any way. */
  @:allow(starling.display)
  private function get_isRotated():Bool
  {
    return _rotation != 0.0 || _skewX != 0.0 || _skewY != 0.0;
  }

  /** The opacity of the object. 0 = transparent, 1 = opaque. @default 1 */
  private function get_alpha():Float
  {
    return _alpha;
  }
  private function set_alpha(value:Float):Float
  {
    if (value != _alpha)
    {
      _alpha = (value < 0.0) ? 0.0:((value > 1.0) ? 1.0:value);
      setRequiresRedraw();
    }
    return value;
  }

  /** The visibility of the object. An invisible object will be untouchable. */
  private function get_visible():Bool
  {
    return _visible;
  }
  private function set_visible(value:Bool):Bool
  {
    if (value != _visible)
    {
      _visible = value;
      setRequiresRedraw();
    }
    return value;
  }

  /** Indicates if this object (and its children) will receive touch events. */
  private function get_touchable():Bool
  {
    return _touchable;
  }
  private function set_touchable(value:Bool):Bool
  {
    _touchable = value;
    return value;
  }

  /** The blend mode determines how the object is blended with the objects underneath.
   *   @default auto
   *   @see starling.display.BlendMode */
  private function get_blendMode():String
  {
    return _blendMode;
  }
  private function set_blendMode(value:String):String
  {
    if (value != _blendMode)
    {
      _blendMode = value;
      setRequiresRedraw();
    }
    return value;
  }

  /** The name of the display object (default: null). Used by 'getChildByName()' of
   *  display object containers. */
  private function get_name():String
  {
    return _name;
  }
  private function set_name(value:String):String
  {
    _name = value;
    return value;
  }

  /** The filter that is attached to the display object. The <code>starling.filters</code>
   *  package contains several classes that define specific filters you can use. To combine
   *  several filters, assign an instance of the <code>FilterChain</code> class; to remove
   *  all filters, assign <code>null</code>.
   *
   *  <p>Beware that a filter instance may only be used on one object at a time! Furthermore,
   *  when you remove or replace a filter, it is NOT disposed automatically (since you might
   *  want to reuse it on a different object).</p>
   *
   *  @default null
   *  @see starling.filters.FragmentFilter
   *  @see starling.filters.FilterChain
   */
  private function get_filter():FragmentFilter
  {
    return _filter;
  }
  private function set_filter(value:FragmentFilter):FragmentFilter
  {
    if (value != _filter)
    {
      if (_filter != null)
      {
        _filter.setTarget(null);
      }
      if (value != null)
      {
        value.setTarget(this);
      }

      _filter = value;
      setRequiresRedraw();
    }
    return value;
  }

  /** The display object that acts as a mask for the current object.
   *  Assign <code>null</code> to remove it.
   *
   *  <p>A pixel of the masked display object will only be drawn if it is within one of the
   *  mask's polygons. Texture pixels and alpha values of the mask are not taken into
   *  account. The mask object itself is never visible.</p>
   *
   *  <p>If the mask is part of the display list, masking will occur at exactly the
   *  location it occupies on the stage. If it is not, the mask will be placed in the local
   *  coordinate system of the target object (as if it was one of its children).</p>
   *
   *  <p>For rectangular masks, you can use simple quads; for other forms (like circles
   *  or arbitrary shapes) it is recommended to use a 'Canvas' instance.</p>
   *
   *  <p>Beware that a mask will typically cause at least two additional draw calls:
   *  one to draw the mask to the stencil buffer and one to erase it. However, if the
   *  mask object is an instance of <code>starling.display.Quad</code> and is aligned
   *  parallel to the stage axes, rendering will be optimized: instead of using the
   *  stencil buffer, the object will be clipped using the scissor rectangle. That's
   *  faster and reduces the number of draw calls, so make use of this when possible.</p>
   *
   *  @see Canvas
   *  @default null
   */
  private function get_mask():DisplayObject
  {
    return _mask;
  }
  private function set_mask(value:DisplayObject):DisplayObject
  {
    if (_mask != value)
    {
      if (_mask != null)
      {
        _mask._maskee = null;
      }
      if (value != null)
      {
        value._maskee = this;
        value._hasVisibleArea = false;
      }

      _mask = value;
      setRequiresRedraw();
    }
    return value;
  }

  /** The display object container that contains this display object. */
  private function get_parent():DisplayObjectContainer
  {
    return _parent;
  }

  /** The topmost object in the display tree the object is part of. */
  private function get_base():DisplayObject
  {
    var currentObject:DisplayObject = this;
    while (currentObject._parent != null)
    {
      currentObject = currentObject._parent;
    }
    return currentObject;
  }

  /** The root object the display object is connected to (i.e. an instance of the class
   *  that was passed to the Starling constructor), or null if the object is not connected
   *  to the stage. */
  private function get_root():DisplayObject
  {
    var currentObject:DisplayObject = this;
    while (currentObject._parent != null)
    {
      if (Std.is(currentObject._parent, Stage))
      {
        return currentObject;
      }
      else
      {
        currentObject = currentObject.parent;
      }
    }

    return null;
  }

  /** The stage the display object is connected to, or null if it is not connected
   *  to the stage. */
  private function get_stage():Stage
  {
    return Std.is(this.base, Stage) ? cast(this.base) : null;
  }
}

