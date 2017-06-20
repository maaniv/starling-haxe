/**
 * Created by redge on 16.12.15.
 */
package starling.text;

import flash.display3D.Context3DTextureFormat;
import starling.core.Starling;

/** The TextOptions class contains data that describes how the letters of a text should
 *  be assembled on text composition.
 *
 *  <p>Note that not all properties are supported by all text compositors.</p>
 */
class TextOptions
{
  public var wordWrap(get, set):Bool;
  public var autoSize(get, set):String;
  public var autoScale(get, set):Bool;
  public var isHtmlText(get, set):Bool;
  public var textureScale(get, set):Float;
  public var textureFormat(get, set):String;

  private var _wordWrap:Bool = false;
  private var _autoScale:Bool = false;
  private var _autoSize:String = null;
  private var _isHtmlText:Bool = false;
  private var _textureScale:Float = 0;
  private var _textureFormat:String = null;

  /** Creates a new TextOptions instance with the given properties. */
  public function new(wordWrap:Bool = true, autoScale:Bool = false)
  {
    _wordWrap = wordWrap;
    _autoScale = autoScale;
    _autoSize = TextFieldAutoSize.NONE;
    _textureScale = Starling.contentScaleFactor_();
    _textureFormat = Context3DTextureFormat.BGR_PACKED;
    _isHtmlText = false;
  }

  /** Copies all properties from another TextOptions instance. */
  public function copyFrom(options:TextOptions):Void
  {
    _wordWrap = options._wordWrap;
    _autoScale = options._autoScale;
    _autoSize = options._autoSize;
    _isHtmlText = options._isHtmlText;
    _textureScale = options._textureScale;
    _textureFormat = options._textureFormat;
  }

  /** Creates a clone of this instance. */
  public function clone():TextOptions
  {
    var clone:TextOptions = new TextOptions();
    clone.copyFrom(this);
    return clone;
  }

  /** Indicates if the text should be wrapped at word boundaries if it does not fit into
   *  the TextField otherwise. @default true */
  private function get_wordWrap():Bool
  {
    return _wordWrap;
  }
  private function set_wordWrap(value:Bool):Bool
  {
    _wordWrap = value;
    return value;
  }

  /** Specifies the type of auto-sizing set on the TextField. Custom text compositors may
   *  take this into account, though the basic implementation (done by the TextField itself)
   *  is often sufficient: it passes a very big size to the <code>fillMeshBatch</code>
   *  method and then trims the result to the actually used area. @default none */
  private function get_autoSize():String
  {
    return _autoSize;
  }
  private function set_autoSize(value:String):String
  {
    _autoSize = value;
    return value;
  }

  /** Indicates whether the font size is automatically reduced if the complete text does
   *  not fit into the TextField. @default false */
  private function get_autoScale():Bool
  {
    return _autoScale;
  }
  private function set_autoScale(value:Bool):Bool
  {
    _autoScale = value;
    return value;
  }

  /** Indicates if text should be interpreted as HTML code. For a description
   *  of the supported HTML subset, refer to the classic Flash 'TextField' documentation.
   *  Beware: Only supported for TrueType fonts. @default false */
  private function get_isHtmlText():Bool
  {
    return _isHtmlText;
  }
  private function set_isHtmlText(value:Bool):Bool
  {
    _isHtmlText = value;
    return value;
  }

  /** The scale factor of any textures that are created during text composition.
   *  @default Starling.contentScaleFactor */
  private function get_textureScale():Float
  {
    return _textureScale;
  }
  private function set_textureScale(value:Float):Float
  {
    _textureScale = value;
    return value;
  }

  /** The Context3DTextureFormat of any textures that are created during text composition.
   *  @default Context3DTextureFormat.BGRA_PACKED */
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

