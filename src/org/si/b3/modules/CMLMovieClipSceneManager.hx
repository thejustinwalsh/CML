//--------------------------------------------------------------------------------
// CMLMovieClip Scene management module
//--------------------------------------------------------------------------------


package org.si.b3.modules;

import openfl._v2.events.Event;
import flash.display.*;
import flash.events.*;
import org.si.b3.*;


/** CMLMovieClipScene manages scene transition. */
class CMLMovieClipSceneManager
{
// member values
//----------------------------------------
    private var _currentSceneID:String;
    private var _nextSceneID:String;
    private var _currentScene:CMLScene;
    private var _sceneList:Map<String, CMLScene>;


// constructor
//----------------------------------------
    /** @private constructor */
    public function new()
    {
        initialize();
    }


// operations
//----------------------------------------
    /** initialize */
    public function initialize() : CMLMovieClipSceneManager
    {
        _sceneList = new Map<String, CMLScene>();
        return reset();
    }


    /** reset */
    public function reset() : CMLMovieClipSceneManager
    {
        _currentSceneID = _nextSceneID = null;
        return this;
    }


    /** register scene */
    public function register(sceneID:String, scene:CMLScene) : CMLMovieClipSceneManager
    {
        _sceneList.set(sceneID, scene);
        return this;
    }




// references
//----------------------------------------
    /** current scene id. if you set this property the sceneID is changed at the head of next frame. */
    public var id(get,set) : String;
    public function get_id() : String
    {
        return _currentSceneID;
    }
    public function set_id(sceneID:String) : String
    {
        _nextSceneID = sceneID;
        return _nextSceneID;
    }




// internals
//----------------------------------------
    /** @public call from CMLMovieClip.update() */
    public function _onUpdate() : Void
    {
        CMLMovieClipControl.instance._updateCounter();

        do {
            if (_currentScene != null) _currentScene.update();
            if (_currentSceneID != _nextSceneID) {
                if (_currentScene != null) _currentScene.exit();
                do {
                    _currentSceneID = _nextSceneID;
                    if ((_currentSceneID != null) && (_sceneList[_currentSceneID] != null)) {
                        _currentScene = _sceneList[_currentSceneID];

                        _currentScene.enter();
                    } else {
                        _currentScene = null;
                    }
                } while (_currentSceneID != _nextSceneID);
            }
        } while (CMLMovieClipFPS.instance._sync());
        if (_currentScene != null) _currentScene.draw();
    }
}


