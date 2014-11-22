package org.si.b3.modules;

/** Extend this class to make your own scenes. **/
class CMLScene {
    public function new() {
    }


    /** Called when we first transition to this scene. */
    public function enter():Void {
    }

    /** Called each frame when the scene needs to be updated.
      * Looks like is handled specially to maybe add extra
      * frames to match the frame rate properly or something.
     **/
    public function update():Void {
    }

    /** Called once per frame to draw? **/
    public function draw():Void {
    }

    /** Called when the frame exits, before the next frame is entered. **/
    public function exit():Void {
    }

}
