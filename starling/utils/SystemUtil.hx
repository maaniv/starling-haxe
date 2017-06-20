// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils;

import flash.errors.Error;
import haxe.Constraints.Function;
import flash.display3D.Context3D;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.system.Capabilities;
import flash.text.Font;
import flash.text.FontStyle;
import starling.errors.AbstractClassError;

/** A utility class with methods related to the current platform and runtime. */
class SystemUtil
{
  public static var isApplicationActive(get, never):Bool;
  public static var isAIR(get, never):Bool;
  public static var isDesktop(get, never):Bool;
  public static var platform(get, never):String;
  public static var version(get, never):String;
  public static var supportsDepthAndStencil(get, never):Bool;
  public static var supportsVideoTexture(get, never):Bool;

  private static var sInitialized:Bool = false;
  private static var sApplicationActive:Bool = true;
  private static var sWaitingCalls:Array<Dynamic> = new Array();
  private static var sPlatform:String = null;
  private static var sDesktop:Bool = false;
  private static var sVersion:String = null;
  private static var sAIR:Bool = false;
  private static var sEmbeddedFonts:Array<Dynamic> = null;
  private static var sSupportsDepthAndStencil:Bool = true;

  /** @private */
  public function new()
  {
    throw new AbstractClassError();
  }

  /** Initializes the <code>ACTIVATE/DEACTIVATE</code> event handlers on the native
   *  application. This method is automatically called by the Starling constructor. */
  public static function initialize():Void
  {
    if (sInitialized)
    {
      return;
    }

    sInitialized = true;
    sPlatform = Capabilities.version.substr(0, 3);
    sVersion = Capabilities.version.substr(4);
    sDesktop = new EReg('(WIN|MAC|LNX)', "").split("").length > 0;

    // try
    // {
    //   var nativeAppClass:Dynamic = Type.resolveClass("flash.desktop::NativeApplication");
    //   var nativeApp:EventDispatcher = try cast(Reflect.field(nativeAppClass, "nativeApplication"), EventDispatcher) catch(e:Dynamic) null;

    //   nativeApp.addEventListener(Event.ACTIVATE, onActivate, false, 0, true);
    //   nativeApp.addEventListener(Event.DEACTIVATE, onDeactivate, false, 0, true);

    //   var appDescriptor:Xml = nativeApp["applicationDescriptor"];
    //   var ns:Namespace = appDescriptor.namespace();
    //   var ds:String = Std.string(appDescriptor.ns::initialWindow.ns::depthAndStencil).toLowerCase();

    //   sSupportsDepthAndStencil = (ds == "true");
    //   sAIR = true;
    // }
    // catch (e:Error)
    // {
    //   sAIR = false;
    // }

    sAIR = false;
  }

  private static function onActivate(event:Dynamic):Void
  {
    sApplicationActive = true;

    for (call in sWaitingCalls)
    {
      try
      {
        Reflect.field(call, Std.string(0)).apply(null, Reflect.field(call, Std.string(1)));
      }
      catch (e:Error)
      {
        trace("[Starling] Error in 'executeWhenApplicationIsActive' call:", e.message);
      }
    }

    sWaitingCalls = [];
  }

  private static function onDeactivate(event:Dynamic):Void
  {
    sApplicationActive = false;
  }

  /** Executes the given function with its arguments the next time the application is active.
   *  (If it <em>is</em> active already, the call will be executed right away.) */
  public static function executeWhenApplicationIsActive(call:Function, args:Array<Dynamic> = null):Void
  {
    initialize();

    if (sApplicationActive)
    {
      Reflect.callMethod(null, call, args);
    }
    else
    {
      sWaitingCalls.push([call, args]);
    }
  }

  /** Indicates if the application is currently active. On Desktop, this means that it has
   *  the focus; on mobile, that it is in the foreground. In the Flash Plugin, always
   *  returns true. */
  private static function get_isApplicationActive():Bool
  {
    initialize();
    return sApplicationActive;
  }

  /** Indicates if the code is executed in an Adobe AIR runtime (true)
   *  or Flash plugin/projector (false). */
  private static function get_isAIR():Bool
  {
    initialize();
    return sAIR;
  }

  /** Indicates if the code is executed on a Desktop computer with Windows, OS X or Linux
   *  operating system. If the method returns 'false', it's probably a mobile device
   *  or a Smart TV. */
  private static function get_isDesktop():Bool
  {
    initialize();
    return sDesktop;
  }

  /** Returns the three-letter platform string of the current system. These are
   *  the most common platforms: <code>WIN, MAC, LNX, IOS, AND, QNX</code>. Except for the
   *  last one, which indicates "Blackberry", all should be self-explanatory. */
  private static function get_platform():String
  {
    initialize();
    return sPlatform;
  }

  /** Returns the Flash Player/AIR version string. The format of the version number is:
   *  <em>majorVersion,minorVersion,buildNumber,internalBuildNumber</em>. */
  private static function get_version():String
  {
    initialize();
    return sVersion;
  }

  /** Returns the value of the 'initialWindow.depthAndStencil' node of the application
   *  descriptor, if this in an AIR app; otherwise always <code>true</code>. */
  private static function get_supportsDepthAndStencil():Bool
  {
    return sSupportsDepthAndStencil;
  }

  /** Indicates if Context3D supports video textures. At the time of this writing,
   *  video textures are only supported on Windows, OS X and iOS, and only in AIR
   *  applications (not the Flash Player). */
  private static function get_supportsVideoTexture():Bool
  {
    return Context3D.supportsVideoTexture;
  }

  /** Updates the list of embedded fonts. To be called when a font is loaded at runtime. */
  public static function updateEmbeddedFonts():Void
  {
    sEmbeddedFonts = null;
  }

  /** Figures out if an embedded font with the specified style is available.
   *  The fonts are enumerated only once; if you load a font at runtime, be sure to call
   *  'updateEmbeddedFonts' before calling this method.
   *
   *  @param fontName  the name of the font
   *  @param bold      indicates if the font has a bold style
   *  @param italic    indicates if the font has an italic style
   *  @param fontType  the type of the font (one of the constants defined in the FontType class)
   */
  public static function isEmbeddedFont(fontName:String, bold:Bool = false, italic:Bool = false,
      fontType:String = "embedded"):Bool
  {
    if (sEmbeddedFonts == null)
    {
      sEmbeddedFonts = Font.enumerateFonts(false);
    }

    for (font in sEmbeddedFonts)
    {
      var style:String = font.fontStyle;
      var isBold:Bool = style == FontStyle.BOLD || style == FontStyle.BOLD_ITALIC;
      var isItalic:Bool = style == FontStyle.ITALIC || style == FontStyle.BOLD_ITALIC;

      if (fontName == font.fontName && bold == isBold && italic == isItalic &&
        fontType == font.fontType)
      {
        return true;
      }
    }

    return false;
  }
}
