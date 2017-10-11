//--------------------------------------------------------------------------------
// CMLMovieClip
//--------------------------------------------------------------------------------
package org.si.b3;

import openfl.display.BlendMode;
import org.si.cml.extensions.Actor;
import org.si.cml.CMLObject;
import openfl.geom.ColorTransform;
import openfl.geom.ColorTransform;
import openfl.display.IBitmapDrawable;
import openfl.display.DisplayObjectContainer;
import org.si.b3.modules.CMLMovieClipSceneManager;
import org.si.b3.modules.CMLMovieClipControl;
import org.si.b3.modules.CMLMovieClipFPS;
import org.si.cml.extensions.ScopeLimitObject;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import openfl.display.Bitmap;


/** CMLMovieClip is a very simple framework for shmups ! <br/>
 *  This class manages scenes, controler, fps, screen and basic cannonML operations.
 */
class CMLMovieClip extends Bitmap
{
// constants
//--------------------------------------------------------------------------------
    // label for vertical scroll
    static public inline var VERTICAL:String = "vertical";
    // label for horizontal scroll
    static public inline var HORIZONTAL:String = "horizontal";




// variables
//--------------------------------------------------------------------------------
    /** Controler management module */
    public var control:CMLMovieClipControl;
    /** FPS management module */
    public var fps    :CMLMovieClipFPS;
    /** Scene management module */
    public var scene  :CMLMovieClipSceneManager;
    /** Screen */
    public var screen:BitmapData = null;
    /** Pause flag */
    public var pause:Bool = false;

    private var _addEnterFrameListener:Bool;     // flag to add enter frame event listener
    private var _onFirstEnterFrame:Void->Void = null; // callback function whrn first enter frame event appears.
    private var _clearColor:Int = 0;               // clear color
    private var _offsetX:Float = 0;
    private var _offsetY:Float = 0;
    private var _scopeMargin:Float = 32;
    private var _vscrollFlag:Bool = true;

    private var _rc:Rectangle = new Rectangle();             // multi-purpose
    private var _pt:Point = new Point();                     // multi-purpose
    private var _mat:Matrix = new Matrix();                  // multi-purpose



// properties
//--------------------------------------------------------------------------------
    /** margin of object's moving range. */
    public var scopeMargin(get,set) : Float;
    public function get_scopeMargin() : Float { return _scopeMargin; }
    public function set_scopeMargin(margin:Float) : Float {
        var sm2:Float = scopeMargin * 2;
        _scopeMargin = margin;
        ScopeLimitObject.setDefaultScope(-_offsetX-margin, -_offsetY-margin, screen.width+sm2, screen.height+sm2);
        return _scopeMargin;
    }


    /** clear color */
    public var clearColor(get,set) : Int;
    public function get_clearColor() : Int { return _clearColor; }
    public function set_clearColor(col:Int) : Int {
        _clearColor = col;
        return _clearColor;
    }




// enum for keys
//--------------------------------------------------------------------------------
    static public inline var KEY_UP      :Int = CMLMovieClipControl.KEY_UP;
    static public inline var KEY_DOWN    :Int = CMLMovieClipControl.KEY_DOWN;
    static public inline var KEY_LEFT    :Int = CMLMovieClipControl.KEY_LEFT;
    static public inline var KEY_RIGHT   :Int = CMLMovieClipControl.KEY_RIGHT;
    static public inline var KEY_BUTTON0 :Int = CMLMovieClipControl.KEY_BUTTON0;
    static public inline var KEY_BUTTON1 :Int = CMLMovieClipControl.KEY_BUTTON1;
    static public inline var KEY_BUTTON2 :Int = CMLMovieClipControl.KEY_BUTTON2;
    static public inline var KEY_BUTTON3 :Int = CMLMovieClipControl.KEY_BUTTON3;
    static public inline var KEY_BUTTON4 :Int = CMLMovieClipControl.KEY_BUTTON4;
    static public inline var KEY_BUTTON5 :Int = CMLMovieClipControl.KEY_BUTTON5;
    static public inline var KEY_BUTTON6 :Int = CMLMovieClipControl.KEY_BUTTON6;
    static public inline var KEY_BUTTON7 :Int = CMLMovieClipControl.KEY_BUTTON7;
    static public inline var KEY_START   :Int = CMLMovieClipControl.KEY_START;
    static public inline var KEY_RESET   :Int = CMLMovieClipControl.KEY_RESET;
    static public inline var KEY_ESCAPE  :Int = CMLMovieClipControl.KEY_ESCAPE;
    static public inline var KEY_SYSTEM  :Int = CMLMovieClipControl.KEY_SYSTEM;




// constructor
//--------------------------------------------------------------------------------
    /** constructor.
     *  @param parent parent DisplayObjectContainer
     *  @param xpos position x
     *  @param ypos position y
     *  @param width screen width
     *  @param height screen height
     *  @param clearColor clear color
     *  @param addEnterFrameListener add Event.ENTER_FRAME event listener.
     *  @param scopeMargin margin of object's moving range.
     *  @param scrollDirecition scrolling direction CMLMovieClip.VERTICAL or CMLMovieClip.HORIZONTAL is available.
     */
    function new(parent:DisplayObjectContainer, xpos:Int, ypos:Int, width:Int, height:Int, clearColor:Int=0x000000,
                 addEnterFrameListener:Bool=true, onFirstEnterFrame:Void->Void=null, scopeMargin:Float=32, scrollDirecition:String="vertical") : Void
    {
        super(null);

        control = new CMLMovieClipControl();
        fps     = new CMLMovieClipFPS();
        scene   = new CMLMovieClipSceneManager();

        setSize(width, height, clearColor, scopeMargin);
        _vscrollFlag = (scrollDirecition != HORIZONTAL);

        _addEnterFrameListener = addEnterFrameListener;
        _onFirstEnterFrame = onFirstEnterFrame;
        addEventListener(Event.ADDED_TO_STAGE, function(e:Event) : Void {
            // TODO: Fix this. Looks like arguments.callee is an AS3 thing not implemented in hax.
            // e.target.removeEventListener(e.type, arguments.callee);
            control._onAddedToStage(this.stage);
            fps._onAddedToStage(this.stage);
            addEventListener(Event.ENTER_FRAME, _onFirstUpdate);
        });

        this.x = xpos;
        this.y = ypos;
        parent.addChild(this);
    }


    /** Set screen size
     *  @param width screen width
     *  @param height screen height
     *  @param clearColor clear color
     *  @param scopeMargin margin of object's moving range.
     *  @return this instance
     */
    public function setSize(width:Int, height:Int, clearColor:Int=0x000000, scopeMargin:Float=32) : CMLMovieClip
    {
        _clearColor = clearColor;
        if ( (screen == null) || screen.width != width || screen.height != height) {
            if (screen != null) screen.dispose();
            screen = new BitmapData(width, height, false, clearColor);
            this.bitmapData = screen;
            _offsetX = screen.width * 0.5;
            _offsetY = screen.height * 0.5;
        }
        this.scopeMargin = scopeMargin;
        return this;
    }


    /** update for one frame */
    public function update() : Void
    {
        if (!pause) {
            CMLObject.frameUpdate();
        }
        scene._onUpdate();
    }

    private function _update(e:Event) : Void
    {
        update();
    }

    // callback when first update
    private function _onFirstUpdate(e:Event) : Void
    {
        removeEventListener(Event.ENTER_FRAME, _onFirstUpdate);
        Actor.initialize(_vscrollFlag);
        if (_onFirstEnterFrame != null) _onFirstEnterFrame();
        if (_addEnterFrameListener) {
            addEventListener(Event.ENTER_FRAME, _update);
        }
    }




// screen operations
//--------------------------------------------------------------------------------
    /** clear screen. fill all of screen by clearColor */
    public function clearScreen() : CMLMovieClip
    {
        screen.fillRect(screen.rect, _clearColor);
        return this;
    }


    /** call screen.fillRect without Rectangle instance.
     *  @param color fill color
     *  @param x x of left edge
     *  @param y y of top edge
     *  @param width rectangle width
     *  @param height rectangle height
     */
    public function fillRect(color:Int, x:Int, y:Int, width:Int, height:Int) : CMLMovieClip
    {
        _rc.x = x + _offsetX;
        _rc.y = y + _offsetY;
        _rc.width = width;
        _rc.height = height;
        screen.fillRect(_rc, color);
        return this;
    }


    /** call screen.copyPixels without Rectangle instance.
     *  @param src source BitmapData
     *  @param srcX x of copying area's left edge
     *  @param srcY y of copying area's top edge
     *  @param srcWidth width of copying area
     *  @param srcHeight height of copying area
     *  @param dstX paste x
     *  @param dstY paste y
     */
    public function copyPixels(src:BitmapData, srcX:Int, srcY:Int, srcWidth:Int, srcHeight:Int, dstX:Int, dstY:Int) : CMLMovieClip
    {
        _rc.x = srcX;
        _rc.y = srcY;
        _rc.width = srcWidth;
        _rc.height = srcHeight;
        _pt.x = dstX + _offsetX;
        _pt.y = dstY + _offsetY;
        screen.copyPixels(src, _rc, _pt);
        return this;
    }


    /** call screen.draw without Matrix
     *  @param src source IBitmapDrawable
     *  @param xpos left position x of source
     *  @param ypos top position y of source
     *  @param scaleX horizontal scaling factor
     *  @param scaleY vertical scaling factor
     *  @param angle rotating angle in degree
     *  @param blendMode blend mode
     *  @param colorTransform color transform
     */
    public function draw(src:IBitmapDrawable, xpos:Float, ypos:Float, scaleX:Float=1, scaleY:Float=1, angle:Float=0, blendMode:BlendMode=null, colorTransform:ColorTransform=null) : CMLMovieClip
    {
        _mat.a = scaleX;
        _mat.d = scaleY;
        _mat.ty = _mat.tx = _mat.b = _mat.c = 0;
        if (angle != 0) _mat.rotate(angle);
        _mat.translate(xpos + _offsetX, ypos + _offsetY);
        screen.draw(src, _mat, colorTransform, blendMode);
        return this;
    }


    /** copy CMLMovieClipTexture to the screen
     *  @param texture CMLMovieClipTexture instance
     *  @param x x of texture center
     *  @param y y of texture center
     *  @param animIndex animation index
     */
    public function copyTexture(texture:CMLMovieClipTexture, x:Int, y:Int, animIndex:Int=0) : CMLMovieClip
    {
        var tex:CMLMovieClipTexture = texture.animationPattern[animIndex];
        _pt.x = x - tex.center.x + _offsetX;
        _pt.y = y - tex.center.y + _offsetY;
        screen.copyPixels(tex.bitmapData, tex.rect, _pt, null, null, true);
        return this;
    }


    /** draw CMLMovieClipTexture to the screen, you have to set CMLMovieClipTexture.drawable = true.
     *  @param src source IBitmapDrawable
     *  @param xpos center position x of source
     *  @param ypos center position y of source
     *  @param scaleX horizontal scaling factor
     *  @param scaleY vertical scaling factor
     *  @param angle rotating angle in degree
     *  @param blendMode blend mode
     *  @param colorTransform color transform
     *  @param animIndex animation index
     */
    public function drawTexture(texture:CMLMovieClipTexture, xpos:Float, ypos:Float, scaleX:Float=1, scaleY:Float=1, angle:Float=0, blendMode:String=null, colorTransform:ColorTransform=null, animIndex:Int=0) : CMLMovieClip
    {
        var tex:CMLMovieClipTexture = texture.animationPattern[animIndex];
        _mat.a = scaleX;
        _mat.d = scaleY;
        _mat.b = _mat.c = 0;
        _mat.tx = -tex.center.x * scaleX;
        _mat.ty = -tex.center.y * scaleY;
        if (angle != 0) _mat.rotate(angle * 0.017453292519943295);
        _mat.translate(xpos + _offsetX, ypos + _offsetY);
        // The parameters to screen.draw are not correct. Looks like this was never fully implemented.
        // Fortunately it's also not ever called, so leave it commented out for now.
        trace('Unimplemented function CMLMovieClip.drawTexture() called');
        //screen.draw(tex.bitmapData, _mat, colorTransform, blendMode);
        return this;
    }
}




