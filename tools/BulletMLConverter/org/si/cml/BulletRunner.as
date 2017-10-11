//----------------------------------------------------------------------------------------------------
// Extention of CMLObject
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml {
    import flash.utils.Dictionary;
    
    
    /** <b>Extension of CMLObject</b> that executes the sequence by calling 5 event listners.
     *  This class provides the execution of CMLSequence by 5 callback functions, onCreate(), onDestroy(), onUpdate(), onNewObject() and onFireObject(), and the function type is function (br : BulletRunner) : Object.
     *  These 5 functions are called at certain time as the CMLObject does.<br/>
     *  You have to call BulletRunner.initialize() first and CMLObject.update() for each frame.
     *  @see CMLObject#onCreate()
     *  @see CMLObject#onDestroy()
     *  @see CMLObject#onUpdate()
     *  @see CMLObject#onNewObject()
     *  @see CMLObject#onFireObject()
     *  @example Start from BulletRunner.addSequence(). You specify the sequence and the object that has callback functions.
<listing varsion="3.0">
// Create sequence
var seq:CMLSequence = new CMLSequence(cannonML_String or bulletML_XML);

// Create enemy
var e:Enemy = new Enemy();

// Set callback functions and execute sequence
BulletRunner.addSequence(seq, {onCreate:e.start, onDeatroy:e.end, onUpdate:e.update, onNewObject:e.fire})
</listing>
<listing varsion="3.0">
// Enemy class has certain callback functions
class Enemy extends Sprite
{
    ...

    public function start(br:BulletRunner) : Object
    {
        // Initialize the position
        this.x = br.x;
        this.y = br.y;
        this.rotation = br.angle;
    }

    public function end(br:BulletRunner) : Object
    {
        // Create explosion if the destructionStatus == 1.
        if (br.destructionStatus == 1) createExplosion();
    }

    public function update(br:BulletRunner) : Object
    {
        // Update the position
        this.x = br.x;
        this.y = br.y;
        this.rotation = br.angle;
        
        // Call BulletRunner.destroy() when you need to destroy.
        if (y>SCREEN_HEIGHT || y<0) br.destroy(0);
    }

    public function fire(br:BulletRunner) : Object
    {
        var b:Bullet = new Bullet();
        return {onCreate:b.start, onDeatroy:b.end, onUpdate:b.update, onNewObject:fire};
    }
}
</listing>
     * @see BulletRunner#addSequence()
     */
    public class BulletRunner extends CMLObject
    {
        /** Arguments for event listner of onNewObject and onFireObject. */
        public var args:Array = null;
        
        // Callback functions
        private var _funcCreate    :Function = _defaultCallback;
        private var _funcDestroy   :Function = _defaultCallback;
        private var _funcUpdate    :Function = _defaultCallback;
        private var _funcNewObject :Function = _defaultCallback;
        private var _funcFireObject:Function = _defaultCallback;
        
        static private var _defaultCallback:Function = function(br:BulletRunner) : * { return null; }
        
        /** @private */
        function BulletRunner()
        {
        }
        
        
        /** <b>Call this at first</b> instead of CMLObject.initialize.
         *  @param vertical_ Flag of scrolling direction
         *  @param argumentMax The maximum count of arguments for all onNewObject()/onFireObject().
         */
        static public function initialize(vertical_:Boolean, argumentMax:int=0) : void
        {
            CMLObject.initialize(vertical_, function(args:Array):CMLObject { return null; }, argumentMax);
        }
        
        
        /** Execute sequence with event listner.
         *  @param seq Instance of CMLSequence.
         *  @param callback Object that has callback functions as a property see below.<br/>
         *  <ul>
         *      <li>callback.onCreate;     Callback when the object is created.</li>
         *      <li>callback.onDestroy;    Callback when the object is destroyed.</li>
         *      <li>callback.onUpdate;     Callback when the objects position is updated.</li>
         *      <li>callback.onNewObject;  Callback when the sequence require to create new object by "n" command.</li>
         *      <li>callback.onFireObject; Callback when the sequence require to create new object by "f" command.</li>
         *  </ul>
         *  The type of these functions are function(br:BulletRunner) : Object {} <br/>
         *  The return value is required when it is onNewObject or onFireObject, and return the object that has callback functions for new object.
         *  @return Instance of executing fiber.
         *  @see CMLSequence#CMLSequence()
         */
        static public function addSequence(seq:CMLSequence, callback:*) : CMLFiber
        {
            return _new(callback).execute(seq);
        }
        
        
        /** @private */
        public override function onCreate() : void
        {
            _funcCreate(this);
        }

        
        /** @private */
        public override function onDestroy() : void
        {
            _funcDestroy(this);
            _delete(this);
        }

        
        /** @private */
        public override function onUpdate() : void
        {
            _funcUpdate(this);
        }
        
        
        /** @private */
        public override function onNewObject(args:Array) : CMLObject
        {
            this.args = args;
            return new(_funcNewObject(this));
        }


        /** @private */
        public override function onFireObject(args:Array) : CMLObject
        {
            this.args = args;
            return new(_funcNewObject(this));
        }





        // operation for free list
        //------------------------------------------------------------
        static private var _freeList:CMLList = new CMLList();

        // new instance
        static private function _new(callback:*) : BulletRunner
        {
            var br:BulletRunner = (_freeList.isEmpty()) ? new BulletRunner() : BulletRunner(_freeList.pop());
            br._funcCreate     = callback.onCreate     || _defaultCallback;
            br._funcDestroy    = callback.onDestroy    || _defaultCallback;
            br._funcUpdate     = callback.onUpdate     || _defaultCallback;
            br._funcNewObject  = callback.onNewObject  || _defaultCallback;
            br._funcFireObject = callback.onFireObject || br._funcNewObject || _defaultCallback;
            return br;
        }
        
        // delete instance
        static private function _delete(rnr:BulletRunner) : void
        {
            _freeList.push(rnr);
        }
    }
}




