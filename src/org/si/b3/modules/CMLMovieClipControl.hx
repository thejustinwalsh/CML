//--------------------------------------------------------------------------------
// Controller operating module
//--------------------------------------------------------------------------------
package org.si.b3.modules;

import openfl._v2.events.TouchEvent;
import openfl._v2.events.Event;
import openfl._v2.events.KeyboardEvent;
import openfl.errors.Error;
import openfl._v2.Vector;
import openfl.ui.Keyboard;

import openfl.events.JoystickEvent;

#if ouya
import openfl.utils.JNI;
import tv.ouya.console.api.OuyaController;
#end

class CMLMovieClipControl
{
// constant variables
//--------------------------------------------------------------------------------
    static public inline var KEY_UP      :Int = 0;
    static public inline var KEY_DOWN    :Int = 1;
    static public inline var KEY_LEFT    :Int = 2;
    static public inline var KEY_RIGHT   :Int = 3;
    static public inline var KEY_BUTTON0 :Int = 4;
    static public inline var KEY_BUTTON1 :Int = 5;
    static public inline var KEY_BUTTON2 :Int = 6;
    static public inline var KEY_BUTTON3 :Int = 7;
    static public inline var KEY_BUTTON4 :Int = 8;
    static public inline var KEY_BUTTON5 :Int = 9;
    static public inline var KEY_BUTTON6 :Int = 10;
    static public inline var KEY_BUTTON7 :Int = 11;
    static public inline var KEY_START   :Int = 12;
    static public inline var KEY_RESET   :Int = 13;
    static public inline var KEY_ESCAPE  :Int = 14;
    static public inline var KEY_SYSTEM  :Int = 15;
    static public inline var KEY_MAX     :Int  = 16;
    
    static private var _keycode_map:Map<String, Int> = [
        "A"=>65, "B"=>66, "C"=>67, "D"=>68, "E"=>69, "F"=>70, "G"=>72, "I"=>73, "J"=>74,
        "K"=>75, "L"=>76, "M"=>77, "N"=>78, "O"=>79, "P"=>80, "Q"=>81, "R"=>82, "S"=>83, "T"=>84, 
        "U"=>85, "V"=>86, "W"=>87, "X"=>88, "Y"=>89, "Z"=>90, ";"=>186, ","=>188, "."=>190, 
        "0"=>48, "1"=>49, "2"=>50, "3"=>51, "4"=>52, "5"=>53, "6"=>54, "7"=>55, "8"=>56, "9"=>57, 
        "NUM0"=>96, "NUM1"=>97, "NUM2"=>98, "NUM3"=>99, "NUM4"=>100,
        "NUM5"=>101, "NUM6"=>102, "NUM7"=>103, "NUM8"=>104, "NUM9"=>105,
        "CONTROL"=>Keyboard.CONTROL, "SHIFT"=>Keyboard.SHIFT, "ENTER"=>Keyboard.ENTER, "SPACE"=>Keyboard.SPACE,
        "BACKSPACE"=>Keyboard.BACKSPACE, "DELETE"=>Keyboard.DELETE, "INSERT"=>Keyboard.INSERT,
        "END"=>Keyboard.END, "HOME"=>Keyboard.HOME, "PAGE_DOWN"=>Keyboard.PAGE_DOWN, "PAGE_UP"=>Keyboard.PAGE_UP, 
        "UP"=>Keyboard.UP, "DOWN"=>Keyboard.DOWN, "LEFT"=>Keyboard.LEFT, "RIGHT"=>Keyboard.RIGHT
    ];
    
    
    
    
// variables
//----------------------------------------
    /** @private unique instance */
    static public var instance:CMLMovieClipControl;
    
    private var _flagPressed:Int;           // button status flag
    private var _supportJoyServer:Bool;  // support JoyServer
   
    private var _keyCode:Vector<Vector<Int>> = new Vector<Vector<Int>>(KEY_MAX); // key code
    private var _counter:Vector<Int> = new Vector<Int>(KEY_MAX);                 // key counter
    
    
    
    
// properties
//----------------------------------------
    /** get x input (-1 <-> +1).
     *  @return -1 for left, 1 for right
     */
    public var x(get,null) : Float;
    public function get_x() : Float
    {
        return (((_flagPressed & 8) >> 3) - ((_flagPressed & 4) >> 2));
    }
    
    
    /** get y input (-1 <-> +1).
     *  @return -1 for up, 1 for down
     */
    public var y(get,null) : Float;
    public function get_y() : Float
    {
        return (((_flagPressed & 2) >> 1) - (_flagPressed & 1));
    }
    
    
    /** get button status flag. you can get the pressing status by (flag >> [key enum]) & 1 for each key. */
    public var flag(get,null) : Int;
    public function get_flag() : Int
    {
        return _flagPressed;
    }
    
    
    
    
// constructor
//----------------------------------------
    /** @public constructor */
    public function new()
    {
        initialize();
        mapArrowKeys();
        mapNumKeys();
        mapWSAD();
        mapButtons(["Z","N","CONTROL"], ["X","M","SHIFT"], ["C",","], ["V","."]);
        instance = this;
    }
    
    
    
    
// operations
//----------------------------------------
    /** initialize all assigned keys
     *  @return this instance
     */
    public function initialize() : CMLMovieClipControl
    {
        var i:Int;
        for(i in 0...KEY_MAX){
            _keyCode[i] = new Vector<Int>();
        }
        _supportJoyServer = false;
        reset();
        return this;
    }
    
    
    /** reset all flags
     *  @return this instance
     */
    public function reset() : CMLMovieClipControl
    {
        _flagPressed = 0;
        var i:Int;
        for(i in 0...KEY_MAX) { _counter[i] = 0; }
        return this;
    }
    
    
    /** assign keycode to the BUTTON_NUMBER 
     *  @param buttonNumber button Float to assign
     *  @param args keycodes or names of assigning buttons
     *  @return this instance
     */
    public function map(buttonNumber:Int, args:Array<Dynamic>) : CMLMovieClipControl
    {
        var codeList:Vector<Int> = _keyCode[buttonNumber];
        if (args.length == 1 && Std.is(args[0], Array)) args = args[0];
        var i:Int;
        for (i in 0...args.length) {
            if (Std.is(args[i], String)) {
                if (_keycode_map.exists(args[i])) {
                    codeList.push(_keycode_map[args[i]]);
                }
                else {
                    throw new Error("No keycode for String '" + args[i] + "'");
                }
            }
            else if (Std.is(args[i], Int)) {
                var keycode:Int = cast(args[i], Int);
                if (keycode > 0) codeList.push(keycode);
            }
            else {
                trace('Unknown argument type ${args[i]} to map');
            }
        }
        return this;
    }
    
    
    /** assign arrow keys as moving button
     *  @param button0 Array, keycode or name for button0
     *  @param button1 Array, keycode or name for button1
     *  @param button2 Array, keycode or name for button2
     *  @param button3 Array, keycode or name for button3
     *  @return this instance
     */
    public function mapArrowKeys(button0:Array<Dynamic>=null, button1:Array<Dynamic>=null, button2:Array<Dynamic>=null, button3:Array<Dynamic>=null) : CMLMovieClipControl
    {
        map(KEY_UP, ["UP"]).map(KEY_DOWN, ["DOWN"]).map(KEY_LEFT, ["LEFT"]).map(KEY_RIGHT, ["RIGHT"]);
        return mapButtons(button0, button1, button2, button3);
    }
    
    
    /** assign number keys (8246) as moving button
     *  @param button0 Array, keycode or name for button0
     *  @param button1 Array, keycode or name for button1
     *  @param button2 Array, keycode or name for button2
     *  @param button3 Array, keycode or name for button3
     *  @return this instance
     */
    public function mapNumKeys(button0:Array<Dynamic>=null, button1:Array<Dynamic>=null, button2:Array<Dynamic>=null, button3:Array<Dynamic>=null) : CMLMovieClipControl
    {
        map(KEY_UP, ["NUM8"]).map(KEY_DOWN, ["NUM2"]).map(KEY_LEFT, ["NUM4"]).map(KEY_RIGHT, ["NUM6"]);
        return mapButtons(button0, button1, button2, button3);
    }
    
    
    /** assign "WASD" keys as moving button
     *  @param button0 Array, keycode or name for button0
     *  @param button1 Array, keycode or name for button1
     *  @param button2 Array, keycode or name for button2
     *  @param button3 Array, keycode or name for button3
     *  @return this instance
     */
    public function mapWSAD(button0:Array<Dynamic>=null, button1:Array<Dynamic>=null, button2:Array<Dynamic>=null, button3:Array<Dynamic>=null) : CMLMovieClipControl
    {
        map(KEY_UP, ["W"]).map(KEY_DOWN, ["S"]).map(KEY_LEFT, ["A"]).map(KEY_RIGHT, ["D"]);
        return mapButtons(button0, button1, button2, button3);
    }
    
    
    /** assign all buttons
     *  @param button0 Array, keycode or name for button0
     *  @param button1 Array, keycode or name for button1
     *  @param button2 Array, keycode or name for button2
     *  @param button3 Array, keycode or name for button3
     *  @return this instance
     */
    public function mapButtons(button0:Array<Dynamic>=null, button1:Array<Dynamic>=null, button2:Array<Dynamic>=null, button3:Array<Dynamic>=null) : CMLMovieClipControl
    {
        map(KEY_BUTTON0, [button0]);
        map(KEY_BUTTON1, [button1]);
        map(KEY_BUTTON2, [button2]);
        map(KEY_BUTTON3, [button3]);
        return this;
    }
    
    
    /** Check button state, this property returns true while the key pressed.
     *  @param buttonNumber button Float
     *  @return key pressing status
     */
    public function isPressed(buttonNumber:Int) : Bool
    {
        return ((_flagPressed & (1<<buttonNumber)) == (1<<buttonNumber));
    }
    
    
    /** Check button state, this property returns true only at the first frame of pressing key.
     *  @param buttonNumber button Float
     *  @return key pressing status
     */
    public function isHitted(buttonNumber:Int) : Bool
    {
        return (_counter[buttonNumber] == 1);
    }
    
    
    /** Get pressed frames 
     *  @param buttonNumber button Float
     *  @return frame count the key pressed.
     */
    public function getPressedFrame(buttonNumber:Int) : Int
    {
        return _counter[buttonNumber];
    }
    
    
    
    
// event handlers
//----------------------------------------
    // handler for KeyboardEvent.KEY_DOWN
    private function _onKeyDown(event:KeyboardEvent) : Void
    {
        var i:Int, j:Int, jmax:Int, kc:Vector<Int>,
            targetCode:Int = event.keyCode;
        for (i in 0...KEY_MAX) {
            kc = _keyCode[i];
            jmax = kc.length;
            for (j in 0...jmax) {
                if (kc[j] == targetCode) {
                    _flagPressed |= (1 << i);
                }
            }
        }
    }
    
    
    // handler for KeyboardEvent.KEY_UP
    private function _onKeyUp(event:KeyboardEvent) : Void
    {
        var i:Int, j:Int, jmax:Int, kc:Vector<Int>,
            targetCode:Int = event.keyCode;
        for (i in 0...KEY_MAX) {
            kc = _keyCode[i];
            jmax = kc.length;
            for (j in 0...jmax) {
                if (kc[j] == targetCode) {
                    _flagPressed &= ~(1 << i);
                }
            }
        }
    }

    // TODO: Make better joystick button mapping support!
    // This existing (and temporary) support is pretty specific to the Nomltest game.

#if ouya
    static inline public var BUTTON_FIRE1A:Int = OuyaController.BUTTON_O;
    static inline public var BUTTON_FIRE1B:Int = OuyaController.BUTTON_L1;
    static inline public var BUTTON_FIRE2:Int = OuyaController.BUTTON_R1;

	static inline public var STICK_DEADZONE:Float = 0.25;
#else
    static inline public var BUTTON_FIRE1A:Int = 0;
    static inline public var BUTTON_FIRE1B:Int = 4;
    static inline public var BUTTON_FIRE2:Int = 5;

    static inline public var STICK_DEADZONE:Float = 0.4;
#end

    private function _onJoyAxisMove (event:JoystickEvent):Void {
        // you can handle multiple joysticks by checking event.device
#if ouya
        var leftX:Float = event.axis[OuyaController.AXIS_LS_X];
        var leftY:Float = event.axis[OuyaController.AXIS_LS_Y];
        //trace('OUYA: JoyID: ${event.id}  Dev: ${event.device}  X: $leftX  Y: $leftY');
#else
        var leftX:Float = event.x;
        var leftY:Float = event.y;
        //trace('JoyID: ${event.id}  Dev: ${event.device}  X: $leftX  Y: $leftY');
#end
    
        if (event.x < -STICK_DEADZONE) {
            _flagPressed |= (1 << KEY_LEFT);
        } else if (event.x > STICK_DEADZONE) {
            _flagPressed |= (1 << KEY_RIGHT);
        }
        else {
            _flagPressed &= ~(1 << KEY_LEFT);
            _flagPressed &= ~(1 << KEY_RIGHT);
        }
    
        if (event.y < -STICK_DEADZONE) {
            _flagPressed |= (1 << KEY_UP);
        } else if (event.y > STICK_DEADZONE) {
            _flagPressed |= (1 << KEY_DOWN);
        }
        else {
            _flagPressed &= ~(1 << KEY_UP);
            _flagPressed &= ~(1 << KEY_DOWN);
        }
    }

    public function _onJoyButtonDown (event:JoystickEvent):Void {
        trace('joy button down, id ${event.id}');
        if (event.id == BUTTON_FIRE1A || event.id == BUTTON_FIRE1B) {
            _flagPressed |= (1 << KEY_BUTTON0);
        }
        else if (event.id == BUTTON_FIRE2) {
            _flagPressed |= (1 << KEY_BUTTON1);
        }
    }

    public function _onJoyButtonUp (event:JoystickEvent):Void {
        if (event.id == BUTTON_FIRE1A || event.id == BUTTON_FIRE1B) {
            _flagPressed &= ~(1 << KEY_BUTTON0);
        }
        else if (event.id == BUTTON_FIRE2) {
            _flagPressed &= ~(1 << KEY_BUTTON1);
        }
    }


    // internals
//----------------------------------------
    /** @public call from Event.ENTER_FRAME */
    public function _updateCounter() : Void
    {
        var i:Int;
        var flag:Int = _flagPressed;
        for (i in 0...KEY_MAX) {
            if ((flag & 1) == 1) {
                _counter[i] = _counter[i] + 1;
            }
            else {
                _counter[i] = 0;
            }
            flag >>= 1;
        }
    }
    
    
    /** @public call from Event.ADDED_TO_STAGE */
    public function _onAddedToStage(e:Event) : Void
    {
        e.target.stage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown);
        e.target.stage.addEventListener(KeyboardEvent.KEY_UP,   _onKeyUp);
        e.target.stage.addEventListener(JoystickEvent.AXIS_MOVE, _onJoyAxisMove);
        e.target.stage.addEventListener(JoystickEvent.BUTTON_DOWN, _onJoyButtonDown);
        e.target.stage.addEventListener(JoystickEvent.BUTTON_UP, _onJoyButtonUp);
    }
}


