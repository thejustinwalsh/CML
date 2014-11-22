//--------------------------------------------------------------------------------
// CMLMovieClip FPS controling module
//--------------------------------------------------------------------------------


package org.si.b3.modules;

import openfl._v2.Lib;
import openfl._v2.events.Event;
import flash.events.*;
import flash.display.*;


/** FPS controling module */
class CMLMovieClipFPS
{
// valiables
//----------------------------------------
    /** @private unique instance */
    static public var instance:CMLMovieClipFPS;

    private var _frameRateMS:Float;    // frame rate on [ms]

    private var _frameCounter:Int;     // frame count
    private var _startTime:Int;         // starting time
    private var _delayedFrames:Float;  // delayed frame count
    private var _frameSkipLevel:Int;    // frame skip level

    private var _frameSkipFilter:Array<Int> = [
        0xffffffff, // level 0 = no skipping
        63,         // level 1 = skipped by 64 frames each
        31,         // level 2 = skipped by 32 frames each
        15,         // level 3 = skipped by 16 frames each
        7,          // level 4 = skipped by 8 frames each
        3,          // level 5 = skipped by 4 frames each
        1,          // level 6 = skipped by 2 frames each
        0           // level 7 = skip all frames
    ];



// properties
//----------------------------------------
    /** frame skip level */
    public var frameSkipLevel(get, null) : Int;
    public function get_frameSkipLevel() : Int
    {
        return _frameSkipLevel;
    }


    /** delayed frame count */
    public var delayedFrames(get,null) : Float;
    public function get_delayedFrames() : Float
    {
        return _delayedFrames;
    }


    /** total frame count */
    public var totalFrame(get,null) : Int;
    public function get_totalFrame() : Int
    {
        return _frameCounter;
    }




// constructor
//----------------------------------------
    /** constructor */
    public function new()
    {
        _frameRateMS = 0;
        initialize();
        instance = this;
    }




// operations
//----------------------------------------
    /** initialize FPS setting */
    public function initialize() : CMLMovieClipFPS
    {
        reset();
        return this;
    }


    /** reset counters */
    public function reset() : CMLMovieClipFPS
    {
        _startTime = Lib.getTimer();
        _frameCounter = 0;
        _delayedFrames = 0;
        return this;
    }




// event handlers
//----------------------------------------
    /** @public call from Event.ENTER_FRAME */
    public function _sync() : Bool
    {
        _frameCounter++;
        if ((_frameCounter & 15) == 0 || _delayedFrames > 5) {
            _delayedFrames = (Lib.getTimer() - _startTime) * _frameRateMS - _frameCounter;
            _frameSkipLevel = (_delayedFrames < 2) ? 0 : (_delayedFrames > 14) ? 7 : Math.round(_delayedFrames * 0.5);
        }
        return ((_frameCounter & _frameSkipFilter[_frameSkipLevel]) == 0);
    }


    /** @public call from Event.ADDED_TO_STAGE */
    public function _onAddedToStage(e:Event) : Void
    {
        _frameRateMS = e.target.stage.frameRate * 0.001;
    }
}

