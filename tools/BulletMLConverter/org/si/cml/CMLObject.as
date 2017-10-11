//----------------------------------------------------------------------------------------------------
// CML object class
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml {
    /** <b>Basic class for all objects.</b>
     * @see CMLObject#initialize()
     * @see CMLObject#update()
     * @see CMLObject#setAsDefaultTarget()
     * @see CMLObject#execute()
     * @see CMLObject#create()
     * @see CMLObject#root
     * @see CMLSequence
     * @see CMLFiber
@example 0) All classes of an object are an extension of CMLObject.<br/>
Override callback functions onCreate(), onDestroy(), onUpdate(), onNewObject() and onFireObject().
<listing version="3.0">
// Enemy class
class Enemy extends CMLObject
{
    ...
    
    // for initializing
    override public function onCreate() : void
    {
        _animationCounter = 0;
    }
    
    // for finalizing
    override public function onDestroy() : void
    {
        // destructionStatus=1 means destruction. So, create an explosion.
        if (destructionStatus == 1) _createExplosion();
    }
    
    // for updating on each frame
    override public function onUpdate() : void
    {
        // Increase animation counter.
        if (++_animationCounter == 100) _animationCounter = 0;
        
        // Drawing
        _drawEnemy(this);
    }

    // for new object created by "n" command
    override public function onNewObject(args:Array) : CMLObject
    {
        return new Enemy();
    }
    
    // for new object created by "f" command
    override public function onFireObject(args:Array) : CMLObject
    {
        return new Bullet();
    }

    ...
}


class Bullet extends CMLObject
{
    ...
}


class Player extends CMLObject
{
    ...
}


class Shot extends CMLObject
{
    ...
}
</listing>
@example 1) Call the CMLObject.initialize() function first of all. 
<listing version="3.0">
// 1st argument is vertical scroll flag.
// 2nd argument is function to create new CMLObject.
CMLObject.initialize(true, newEnemy);

function newEnemy(args:Array) : CMLObject {
    return new Enemy(); // Enemy class is your extention of CMLObject.
}
</listing>
@example 2) Create player object and marking it as "default target".
<listing version="3.0">
var player:CMLObject = new Player();    // Player class is your extention of CMLObject.
player.setAsDefaultTarget();            // Default target is the object to fire.
</listing>
@example 3-1) Create a new CMLSequence from cannonML or bulletML, and call create() and execute().
<listing version="3.0">
// Create sequence from "String of cannonML" or "XML of bulletML".
var motion:CMLSequence = new CMLSequence(String or XML);

 ...
 
enemy.create(x, y);                                     // Create enemy on the stage.
enemy.execute(motion);                                  // Execute sequence.
</listing>
@example 3-2) Or create a new CMLSequence of stage, and call CMLObject.root.execute().
<listing version="3.0">
// Create stage sequence from "String of cannonML" or "XML of bulletML".
var stageSeq:CMLSequence = new CMLSequence(String or XML);

 ...

CMLObject.root.execute(stageSeq);                       // Execute stage sequence.
</listing>
@example 3-3) An example for a shoting CMLSequence of player.
<listing version="3.0">
// Create shot sequence from "String of cannonML" or "XML of bulletML".
var shotSeq:CMLSequence = new CMLSequence(String or XML);
// Fiber to execute shoting sequence.
var shotFbr:CMLFiber = null;

 ...

// player is an inherit of CMLObject. Execute shot sequence when shot button is pressed.
if (isPressed(SHOT_BUTTON)) {
    shotFbr = player.execute(shotSeq);
} else {
    // Stop the sequence when it's active and shot button was released.
    if (shotFbr != null && shotFbr.isActive) {
        shotFbr.destroy();
        shotFbr = null;
    }
}
</listing>
@example 4) Call CMLObject.update() once for each frame.
<listing version="3.0">
addEventListener(Event.ENTER_FRAME, _onEnterFrame); // As you like

function _onEnterFrame(event:Event) : void {
    CMLObject.update();
}
</listing>
     */    
    public class CMLObject extends CMLListElem
    {
    // public constant values
    //------------------------------------------------------------
        // enum for motion
        /** Number for CMLObject.motion_type, Linear motion. */
        static public const MT_CONST:uint    = 0;
        /** Number for CMLObject.motion_type, Accelarating motion. */
        static public const MT_ACCEL:uint    = 1;
        /** Number for CMLObject.motion_type, 3D-Bezier interpolating motion. */
        static public const MT_INTERPOL:uint = 2;
        /** Number for CMLObject.motion_type, BulletML compatible motion. */
        static public const MT_BULLETML:uint = 3;
        /** Number for CMLObject.motion_type, Gravity motion. */
        static public const MT_GRAVITY:uint  = 4;




    // public variables
    //------------------------------------------------------------
        /** You can rewrite this for your own purpose. */
        public var actor:* = this;

        /** X value of position. */
        public var x:Number = 0;
        /** Y value of position. */
        public var y:Number = 0;
        /** X value of velocity. */
        public var vx:Number = 0;
        /** Y value of velocity. */
        public var vy:Number = 0;




    // public properties
    //------------------------------------------------------------
        // static properties
        /** root object. */
        static public function get root():CMLObject { return _root; }
        /** Scrolling angle (vertical=-90, horizontal=180). */
        static public function get scrollAngle() : Number { return _scrollAngle; }
        /** Flag for scrolling direction (vertical=1, horizontal=0). */
        static public function set vertical(v:int) : void {
            _vertical = int(v != 0);
            _scrollAngle = (v) ? -90 : 180;
        }
        /** @private */
        static public function get vertical() : int { return _vertical; }
        /** Ratio of (frame rate to calculate speed) / (screen frame rate). */
        static public function set frameRateRatio(n:Number) : void { CMLState._speedRatio = n; }
        /** @private */
        static public function get frameRateRatio() : Number { return CMLState._speedRatio; }
        /** Function for "$?/$??" variable, The type is function():Number. @default Math.random() */
        static public function set funcRand(func:Function) : void { _funcRand = func; }

        /** Variable for "$r" */
        static public function set globalRank(r:Number) : void { _globalRank[0] = (r<_globalRankRangeMin) ? _globalRankRangeMin : (r>_globalRankRangeMax) ? _globalRankRangeMax : r; }
        static public function get globalRank() : Number { return _globalRank[0]; }
        
        // common properties
        /** Construction ID. When the object is destroyed, its Construction ID is changed. 
         * @example If you want to know the object available, hold and check its id value.
<listing version="3.0">
target_object_id = target_object.id;        // hold the targets id value.
...
if (target_object_id != target_object.id) { // if the id value is different,
    target_object = null;                   // target object was destroyed.
}
</listing>
         */
        public function get id() : uint { return _id; }
        /** CMLObject instance that created this object. Return root, when the parent already destroyed. */
        public function get parent() : CMLObject {
            if (_parent._id != _parent_id) {
                _parent = _root;
                _parent_id = _parent._id;
                _access_id = ID_NOT_SPECIFYED;
            }
            return _parent;
        }
        /** Motion type. 
         * @see CMLObject#MT_CONST
         * @see CMLObject#MT_ACCEL
         * @see CMLObject#MT_INTERPOL
         * @see CMLObject#MT_BULLETML
         * @see CMLObject#MT_GRAVITY
         */
        public function get motion_type() : uint  { return _motion_type; }
        /** Is this object already created ? */
        public function get isActive() : Boolean { return (_parent != null); }
        /** Is this object a part of its parent ? */
        public function get isPart() : Boolean { return _isPart; }
        /** Does this object have another object as a part ? */
        public function get hasParts() : Boolean { return (!_partChildren.isEmpty); }
        /** You can define the "$r" value for each object by override this property. When you don't override this, the return value is CMLObject.globalRank. @see CMLObject#globalRank */
        public function set rank(r:Number) : void { globalRank = r; }
        /** @private */
        public function get rank() : Number { return globalRank; }
        /** Destruction status. You can refer the argument of destroy() or the '@ko' command in the callback function onDestroy(). Returns -1 when the object isnt destroyed.
         *  @see CMLObject#onDestroy()
         *  @see CMLObject#destroy()
         *  @see CMLObject#destroyAll()
         */
        public function get destructionStatus() : int { return _destructionStatus; }


        /** The x value of position parent related */
        public function get relatedX() : Number { return (_isPart) ? _rx : x; }
        /** The y value of position parent related */
        public function get relatedY() : Number { return (_isPart) ? _ry : y; }


        // velocity
        /** Absolute value of velocity. */
        public function set velocity(vel:Number) : void {
            if (_motion_type == MT_BULLETML) {
                _ax = vel; 
            } else {
                var r:Number = vel/velocity;
                vx *= r;
                vy *= r;
            }
        }
        /** @private */
        public function get velocity() : Number { return (_motion_type == MT_BULLETML) ? _ax : (Math.sqrt(vx*vx+vy*vy)); }


        // angles
        /** Angle of this object, The direction(1,0) is 0 degree.*/
        public function set angle(ang:Number)         : void   { _head = ang - ((_isPart) ? (_head_offset + _parent.angleOnScreen) : (_head_offset)) - _scrollAngle; }
        /** @private */
        public function get angle()                   : Number { return ((_isPart) ? (_head_offset + _parent.angleOnScreen) : (_head_offset)) + _head + _scrollAngle; }
        /** Angle of this object, scrolling direction is 0 degree. */
        public function set angleOnScreen(ang:Number) : void   { _head = ang - ((_isPart) ? (_head_offset + _parent.angleOnScreen) : (_head_offset)); }
        /** @private */
        public function get angleOnScreen()           : Number { return ((_isPart) ? (_head_offset + _parent.angleOnScreen) : (_head_offset)) + _head; }
        /** Angle of this parent object, scrolling direction is 0 degree. */
        public function get angleParentOnScreen()     : Number { return ((_isPart) ? (_head_offset + _parent.angleOnScreen) : (_head_offset)); }
        /** Calculate direction of position from origin. */
        public function get anglePosition() : Number { return ((_isPart) ? (Math.atan2(_ry, _rx)) : (Math.atan2(y, x))) * 57.29577951308232 - _scrollAngle; }
        /** Calculate direction of velocity. */
        public function get angleVelocity() : Number { return (_motion_type == MT_BULLETML) ? (angleOnScreen) : (Math.atan2(vy, vx)*57.29577951308232 - _scrollAngle); }
        /** Calculate direction of accelaration. */
        public function get angleAccel()    : Number { return (_motion_type == MT_BULLETML) ? (angleOnScreen) : (Math.atan2(_ay, _ax)*57.29577951308232 - _scrollAngle); }




    // protected variables
    //------------------------------------------------------------
        /** Entrance function in each frame. <br/>
         *  <p>
         *  This function is selected by motion_type automatically.<br/>
         *  The type is function():void. You can rewrite this function for your own use.<br/>
         *  Please refer the private function CMLObject._motion() in source code.
         *  </p>
         */
        protected var _onUpdate:Function = _motion;




    // private variables
    //------------------------------------------------------------
        // statics
        static private  var _activeObjects:CMLList = new CMLList();     // active object list
        static private  var _root:CMLRoot = null;                       // root object instance
        static private  var _scrollAngle:Number = -90;                  // base angle
        static private  var _vertical:int = 1;                          // vertical flag
        static private  var _funcRand:Function = Math.random;           // random function
        static private  var _globalRankRangeMin:Number = 0;             // the range of globalRank
        static private  var _globalRankRangeMax:Number = 1;             // the range of globalRank
        /** @private */
        static internal var _globalRank:Array = new Array(10);          // array of globalRank
        /** @private */
        static internal var _argumentCountOfNew:uint = 0;    // argument count of function onNewObject()
        

        // common parameters
        private var _id:uint = 0;                       // construction id
        private var _parent:CMLObject = null;           // parent object
        private var _parent_id:uint = 0;                // parent object id
        private var _isPart:Boolean = false;            // is a part of another object ?
        private var _access_id:int = ID_NOT_SPECIFYED;  // access id
        private var _destructionStatus:int = -1;        // destruction status
        
        private var _IDedChildren:Array = new Array();  // children list that has access id
        private var _partChildren:Array = new Array();  // children list that is part of this
        
        // motion parameters
        private var _rx:Number = 0;       // relative position
        private var _ry:Number = 0;
        private var _ax:Number = 0;       // accelaration
        private var _ay:Number = 0;
        private var _bx:Number = 0;       // differential of accelaration
        private var _by:Number = 0;
        private var _ac:int    = 0;       // accelaration counter
        private var _motion_type:uint = MT_CONST;  // motion type
        
        // posture
        private var _head:Number = 0;           // head angle
        private var _head_offset:Number = 0;    // head angle offset

        // rotation
        private var _roti:interpolation = new interpolation();    // rotation interpolation
        private var _rott:Number = 0;                             // rotation parameter
        private var _rotd:Number = 0;                             // rotation parameter increament

        // enum for relation
        static private const NO_RELATION:uint = 0;
        static private const REL_ATTRACT:uint = 1;
        
        /** @private */
        static internal const ID_NOT_SPECIFYED:int = 0;




    // constructor
    //------------------------------------------------------------
        /** Constructor. */
        public function CMLObject()
        {
            _id = 0;
            actor = this;
        }




    // callback functions
    //------------------------------------------------------------
        /** Callback function on create. Override this to initialize.*/
        public function onCreate() : void
        {
        }
        
        
        /** Callback function on destroy. Override this to finalize.
         *  @see CMLObject#destroy()
         *  @see CMLObject#destroyAll()
         */
        public function onDestroy() : void
        {
        }
        
        
        /** Callback function when CMLObject.update() is called. This function is called after update position. Override this to update own parameters.*/
        public function onUpdate() : void
        {
        }

        
        /** Statement "n" calls this when it needs. Override this to define the new CMLObject created by "n" command.
         *  @param args The arguments of sequence.
         *  @return The new CMLObject created by "n" command.
         */
        public function onNewObject(args:Array) : CMLObject
        {
            return null;
        }

        
        /** Statement "f" calls this when it needs. Override this to define the new CMLObject created by "f" command.
         *  @param args The arguments of sequence.
         *  @return The new CMLObject created by "n" command.
         */
        public function onFireObject(args:Array) : CMLObject
        {
            return null;
        }




    // static functions
    //------------------------------------------------------------
        /** <b>Call this function first of all</b>.
         *  @param vertical_ Flag of scrolling direction
         *  @param funcNewObject Function for new object created by n*,f* in root object. The type is function(args:Array):CMLObject.
         *  @param argumentMax The maximum count of arguments for all onNewObject()/onFireObject().
         *  @return The root object.
         *  @see CMLObject#onNewObject()
         *  @see CMLObject#onFireObject()
         */
        static public function initialize(vertical_:Boolean, funcNewObject_:Function, argumentMax:int=0) : CMLObject
        {
            vertical = int(vertical_);
            _argumentCountOfNew = argumentMax;
            _root = new CMLRoot(funcNewObject_);
            globalRank = 0;
            return _root;
        }

        
        /** <b>Call this function for each frame</b>. This function execute 1 frame and call all onUpdate()s. */
        static public function update() : void
        {
            CMLFiber._onUpdate();
            
            if (_activeObjects.isEmpty()) return;
            
            var object   :CMLObject, 
                elem     :CMLListElem,
                elem_end :CMLListElem = _activeObjects.end;
            
            for (elem=_activeObjects.begin; elem!=elem_end;) {
                object = CMLObject(elem);
                elem = elem.next;
                if (object._destructionStatus < 0) {
                    object._onUpdate();
                } else {
                    object._finalize();
                }
            }
        }

        
        /** Destroy all active objects except for root. This function <b>must not</b> be called from onDestroy().
         *  @param status A value of the destruction status. This must be greater than or equal to 0. You can refer this by destructionStatus in onDestroy(). 
         *  @see CMLObject#destructionStatus
         *  @see CMLObject#onDestroy()
         */
        static public function destroyAll(status:int) : void
        {
            status = (status<0) ? 0 : status;
            var elem     :CMLListElem, elem_next:CMLListElem, 
                elem_end :CMLListElem = _activeObjects.end;
            for (elem=_activeObjects.begin; elem!=elem_end; elem=elem_next) {
                // CMLObject(elem).destroy(_destructionStatus);
                elem_next= elem.next;
                CMLObject(elem)._destructionStatus = status;
                CMLObject(elem)._finalize();
            }
        }

        
        /** The return value is from CMLObject._funcRand.
         *  @return The random number between 0-1. 
         *  @see CMLObject#_funcRand
         */
        static public function rand() : Number { return _funcRand(); }


        /** Set the range of globalRank. */
        static public function setGlobalRankRange(min:Number, max:Number) : void
        {
            _globalRankRangeMin = min;
            _globalRankRangeMax = max;
        }




    // create / destroy
    //------------------------------------------------------------
        /** Create new object on the stage.
         *  @param x_         X value of this object on a stage or parent(if its a part of parent).
         *  @param y_         Y value of this object on a stage or parent(if its a part of parent).
         *  @param parent_    The instance of parent object. null means child of the root.
         *  @param isPart_    This object is a part of parent or not.
         *  @param access_id_ Access ID from parent.
         *  @return this.
         */
        public function create(x_:Number, y_:Number, parent_:CMLObject=null, isPart_:Boolean=false, access_id_:int=ID_NOT_SPECIFYED) : CMLObject
        {
            _initialize(parent_ || _root, isPart_, access_id_, x_, y_, 0, 0, 0);
            return this;
        }
        
        
        /** Destroy this object.
         *  @param status A value of the destruction status. This must be greater than or equal to 0. You can refer this by CMLObject.destructionStatus.
         *  @see CMLObject#destructionStatus
         *  @see CMLObject#onDestroy()
         */
        public function destroy(status:int) : void
        {
            _destructionStatus = (status<0) ? 0 : status;
        }




    // execute / halt
    //------------------------------------------------------------
        /** Execute a sequence and create a new fiber.
         *  @param seq The sequence to execute.
         *  @param args The array of arguments to execute sequence.
         *  @param invertFlag The flag to invert execution same as 'm' command.
         *  @return Instance of fiber that execute the sequence.
         */
        public function execute(seq:CMLSequence, args:Array=null, invertFlag:uint=0) : CMLFiber
        {
            return CMLFiber._newRootFiber(this, seq, args, invertFlag);
        }
        
        
        /** Destroy all fibers of this object. This function is slow.
         *  If you want to execute faster, keep returned CMLFiber from CMLObject.execute() and call CMLFiber.destroy() wherever possible.
         *  @see CMLObject#execute()
         *  @see CMLFiber#destroy()
         */
        public function halt() : void
        {
            CMLFiber._destroyAllFibers(this);
        }




    // reference
    //------------------------------------------------------------
        /** Calculate distance from another object aproximately. The distance is calculated as an octagnal.
         * @param tgt Another object to calculate distance.
         * @return Rough distance.
         */
        public function getDistance(tgt:CMLObject) : Number
        {
            var dx:Number = x - tgt.x;
            var dy:Number = y - tgt.y;
            dx = (dx<0) ? -dx:dx;
            dy = (dy<0) ? -dy:dy;
            return (dx > dy) ? (dx + dy * 0.2928932188134524) : (dy + dx * 0.2928932188134524);
        }
        
        
        /** Calculate aiming angle to another object.
         * @param target_ Another object to calculate angle.
         * @param offx X position offset to calculate angle.
         * @param offy Y position offset to calculate angle.
         * @return Angle.
         */
        public function getAimingAngle(target_:CMLObject, offx:Number=0, offy:Number=0) : Number
        {            
            var sang:int = sin.index(_head),
                cang:int = sang + sin.cos_shift;
            var absx:Number = x + sin[cang]*offx - sin[sang]*offy;
            var absy:Number = y + sin[sang]*offx + sin[cang]*offy;
            return Math.atan2(target_.y-absy, target_.x-absx)*57.29577951308232 - _scrollAngle;
        }
        
        
        /** Count all children with access id. 
         *  @return The count of child objects with access id.
         *  @see CMLObject#create()
         */
        public function countAllIDedChildren() : int
        {
            return _IDedChildren.length;
        }
        
        
        /** Count children with specifyed id.
         *  @param id Access id specifyed in create() or "n*" command.
         *  @return The count of child objects with specifyed id.
         *  @see CMLObject#create()
         */
        public function countIDedChildren(id:int) : int
        {
            var count:int=0, obj:CMLObject;
            for each (obj in _IDedChildren) {
                count += int(obj._access_id == id);
            }
            return count;
        }

        
        

    // set parameters
    //------------------------------------------------------------
        /** Set position.
         *  @param x_ X value of position.
         *  @param y_ Y value of position.
         *  @param term_ Frames for tweening with bezier interpolation.
         *  @return this object
         */
        public function setPosition(x_:Number, y_:Number, term_:int=0) : CMLObject
        {
            if (term_ == 0) {
                if (_motion_type == MT_GRAVITY) {
                    _rx = x_;
                    _ry = y_;
                } else {
                    if (_isPart) {
                        _rx = x_;
                        _ry = y_;
                        calcAbsPosition();
                    } else {
                        x = x_;
                        y = y_;
                    }
                    _motion_type = MT_CONST;
                    _onUpdate = (_isPart) ? _motion_parts : _motion;
                }
            } else {
                // interlopation
                var t:Number = 1 / term_;
                var dx:Number, dy:Number;
                if (_isPart) {
                    dx = x_ - _rx;
                    dy = y_ - _ry;
                } else {
                    dx = x_ - x;
                    dy = y_ - y;
                }
                _ax = (dx * t * 3 - vx * 2) * t * 2;
                _ay = (dy * t * 3 - vy * 2) * t * 2;
                _bx = (dx * t *-2 + vx) * t * t * 6;
                _by = (dy * t *-2 + vy) * t * t * 6;
                _ac = term_;
                _motion_type = MT_INTERPOL;
                _onUpdate = (_isPart) ? _motion_interpolate_parts : _motion_interpolate;
            }
            return this;
        }


        /** Set velocity.
         *  @param vx_ X value of velocity.
         *  @param vy_ Y value of velocity.
         *  @param term_ Frames for tweening with bezier interpolation.
         *  @return this object
         */
        public function setVelocity(vx_:Number, vy_:Number, term_:int=0) : CMLObject
        {
            if (term_ == 0) {
                vx = vx_;
                vy = vy_;
                _motion_type = MT_CONST;
                _onUpdate = (_isPart) ? _motion_parts : _motion;
            } else {
                var t:Number = 1 / term_;
                if (_motion_type == MT_INTERPOL) {
                    // interlopation
                    _ax -= vx_ * t * 2;
                    _ay -= vy_ * t * 2;
                    _bx += vx_ * t * t * 6;
                    _by += vy_ * t * t * 6;
                    _ac = term_;
                    _motion_type = MT_INTERPOL;
                    _onUpdate = (_isPart) ? _motion_interpolate_parts : _motion_interpolate;
                } else {
                    // accelaration
                    _ax = (vx_ - vx) * t;
                    _ay = (vy_ - vy) * t;
                    _ac = term_;
                    _motion_type = MT_ACCEL;
                    _onUpdate = (_isPart) ? _motion_accel_parts : _motion_accel;
                }
            }
            return this;
        }


        /** Set accelaration.
         *  @param ax_ X value of accelaration.
         *  @param ay_ Y value of accelaration.
         *  @param time_ Frames to stop accelarate. 0 means not to stop.
         *  @return this object
         */
        public function setAccelaration(ax_:Number, ay_:Number, time_:int=0) : CMLObject
        {
            _ax = ax_;
            _ay = ay_;
            _ac = time_;
            if (_ax==0 && _ay==0) {
                _motion_type = MT_CONST;
                _onUpdate = (_isPart) ? _motion_parts : _motion;
            } else {
                _motion_type = MT_ACCEL;
                _onUpdate = (_isPart) ? _motion_accel_parts : _motion_accel;
            }
            return this;
        }


        
        /** Set interpolating motion.
         *  @param x_ X value of position.
         *  @param y_ Y value of position.
         *  @param vx_ X value of velocity.
         *  @param vy_ Y value of velocity.
         *  @param term_ Frames for tweening with bezier interpolation.
         *  @return this object
         */
        public function setInterpolation(x_:Number, y_:Number, vx_:Number, vy_:Number, term_:int=0) : CMLObject
        {
            if (term_ == 0) {
                vx = vx_;
                vy = vy_;
                if (_isPart) {
                    _rx = x_;
                    _ry = y_;
                    calcAbsPosition();
                } else {
                    x = x_;
                    y = y_;
                }
                _motion_type = MT_CONST;
                _onUpdate = (_isPart) ? _motion_parts : _motion;
            } else {
                // 3rd dimensional motion
                var t:Number = 1 / term_;
                var dx:Number, dy:Number;
                if (_isPart) {
                    dx = x_ - _rx;
                    dy = y_ - _ry;
                } else {
                    dx = x_ - x;
                    dy = y_ - y;
                }
                _ax = (dx * t * 3 - vx * 2 - vx_) * t * 2;
                _ay = (dy * t * 3 - vy * 2 - vy_) * t * 2;
                _bx = (dx * t *-2 + vx + vx_) * t * t * 6;
                _by = (dy * t *-2 + vy + vy_) * t * t * 6;
                _ac = term_;
                _motion_type = MT_INTERPOL;
                _onUpdate = (_isPart) ? _motion_interpolate_parts : _motion_interpolate;
            }
            return this;
        }

        

        /** &lt;changeDirection type='absolute'&gt; of bulletML.
         *  @param dir Direction to change.
         *  @param term Frames to change direction.
         *  @param rmax Maxmum speed of rotation [degrees/frame].
         *  @param shortest_rot Flag to rotate on shortest rotation.
         *  @return this object
         */
        public function setChangeDirection(dir:Number, term:int, rmax:Number, shortest_rot:Boolean=true) : CMLObject
        {
            if (term == 0) {
                // set head angle and set velocity to head direction
                setRotation(dir, 0, 1, 1, shortest_rot);
                var sang:int = sin.index(angle),
                    cang:int = sang + sin.cos_shift,
                    spd:Number = velocity;
                vx = sin[cang] * spd;
                vy = sin[sang] * spd;
            } else {
                // set constant rotation
                setConstantRotation(dir, term, rmax, shortest_rot);
                // set verocity
                if (_motion_type != MT_BULLETML) {
                    _ax = velocity;
                    _bx = 0;
                    _ac = 0;
                    _motion_type = MT_BULLETML;
                    _onUpdate = (_isPart) ? _motion_bml_parts : _motion_bml;
                }
            }
            return this;
        }


        
        /** &lt;changeSpeed type='absolute'&gt; of bulletML.
         *  @param spd Speed to change.
         *  @param term Frames to change speed.
         *  @return this object
         */
        public function setChangeSpeed(spd:Number, term:int=0) : CMLObject
        {
            if (term == 0) {
                // turn velocity vector to head direction
                var sang:int = sin.index(angle),
                    cang:int = sang + sin.cos_shift;
                vx = sin[cang] * spd;
                vy = sin[sang] * spd;
            } else {
                // set verocity
                _ax = velocity;
                _bx = (spd - _ax) / term;
                _ac = term;
                _motion_type = MT_BULLETML;
                _onUpdate = (_isPart) ? _motion_bml_parts : _motion_bml;
            }
            return this;
        }



        /** Set gravity motion.
         *  <p>
         *  <b>This function is not available for a part of parent.</b>
         *  After this function, the CMLObject.setPosition() sets the gravity center.
         *  The calculation of the motion is below.<br/>
         *  [accelaration] = [distance] * [atr_a] / 100 - [velocity] * [atr_b] / 100<br/>
         *  </p>
         *  @param atr_a Attracting parameter a[%]. Ratio of attracting force.
         *  @param atr_b Attracting parameter b[%]. Ratio of air fliction.
         *  @param term Frames to enable attracting force.
         *  @return this object
         *  @see CMLObject#setPosition
         */
        public function setGravity(atr_a:Number, atr_b:Number, term:int=0) : CMLObject
        {
            if (_isPart) return this;
            
            if (atr_a == 0 && atr_b == 0) {
                // stop attraction
                _ax = 0;
                _ay = 0;
                _bx = 0;
                _by = 0;
                _ac = 0;
                _motion_type = MT_CONST;
                _onUpdate = (_isPart) ? _motion_parts : _motion;
            } else {
                // attraction
                _bx = atr_a*0.01;
                _by = atr_b*0.01;
                _ac = term;
                _rx = x;
                _ry = y;
                _motion_type = MT_GRAVITY;
                _onUpdate = _motion_gravity;
            }
            return this;
        }

        
        
        /** Set rotation. You can specify the first and last speed.
         *  @param end_angle Final angle when the rotation finished, based on scrolling direction.
         *  @param term Frames to rotate.
         *  @param start_t Ratio of first rotating speed. The value of 1 means the speed of a constant rotation.
         *  @param end_t Ratio of last rotating speed. The value of 1 means the speed of a constant rotation.
         *  @param isShortestRotation Rotate with shortest rotation or not.
         *  @return this object
         */
        public function setRotation(end_angle:Number, term:Number, start_t:Number, end_t:Number, isShortestRotation:Boolean=true) : CMLObject
        {
            // calculate shotest rotation
            var diff:Number;
            if (isShortestRotation) {
                _normalizeHead();
                diff = (end_angle - angleOnScreen + 180) * 0.00277777777777777778;
                diff = (diff-int(diff)) * 360 - 180;
            } else {
                diff = end_angle - angleOnScreen;
            }

            if (term == 0) {
                _head += diff;
                _rott = 0;
                _rotd = 0;
            } else {
                // rotating interpolation
                _roti.setFergusonCoons(_head, _head+diff, diff*start_t, diff*end_t)
                _rott = 0;
                _rotd = 1/term;
            }
            return this;
        }

        
        
        /** Set constant rotation. You can specify the maximum speed.
         *  @param end_angle Final angle when the rotation finished, based on scrolling direction.
         *  @param term Frames to rotate.
         *  @param rmax Maximum speed of rotation [degrees/frame].
         *  @param isShortestRotation Rotate with shortest rotation or not.
         *  @return this object
         */
        public function setConstantRotation(end_angle:Number, term:Number, rmax:Number, isShortestRotation:Boolean=true) : CMLObject
        {
            // rotation max
            rmax *= (term==0) ? 1 : term;
            
            // calculate shotest rotation
            var diff:Number;
            if (isShortestRotation) {
                _normalizeHead();
                diff = (end_angle - angleOnScreen + 180) * 0.00277777777777777778;
                diff = (diff-int(diff)) * 360 - 180;
            } else {
                diff = end_angle - angleOnScreen;
            }
            
            // restriction
            if (rmax != 0) {
                if (diff < -rmax) diff = -rmax;
                else if (diff > rmax) diff = rmax;
            }
            
            if (term == 0) {
                _head += diff;
                _rott = 0;
                _rotd = 0;
            } else {
                _roti.setLinear(_head, _head+diff);
                _rott = 0;
                _rotd = 1/term;
            }
            return this;
        }


        /** Set as a default target object. A default target is the object to target from all objects at default, usually player is as. 
         *  @return this object
         */
        public function setAsDefaultTarget() : CMLObject
        {
            CMLFiber._defaultTarget = this;
            return this;
        }
        
        
        /** Change parent. */
        public function changeParent(parent_:CMLObject=null, isPart_:Boolean=false, access_id_:int=ID_NOT_SPECIFYED) : void
        {
            // remove this from a parents IDed children list.
            if (_access_id != ID_NOT_SPECIFYED) {
                _parent._IDedChildren.splice(_parent._IDedChildren.indexOf(this), 1);
            }
            
            // when this WAS a part object ...
            if (_isPart) {
                // check parents parts
                _parent._partChildren.splice(_parent._partChildren.indexOf(this), 1);
                // calculate absolute angle
                _head = _parent.angleOnScreen + _head;
            }

            // change parameters
            _parent = parent_ || _root;
            _parent_id = _parent._id;
            _access_id = (parent_) ? access_id_ : ID_NOT_SPECIFYED;
            _isPart    = (parent_) ? isPart_ : false;
            if (access_id_ != ID_NOT_SPECIFYED) {
                _parent._IDedChildren.push(this);
            }
            
            // when this WILL BE a part object ...
            if (isPart_) {
                // repush active object list
                _repush(this);
                
                // register this on parent parts list.
                _parent._partChildren.push(this);
            
                // change motion functor
                switch (_motion_type) {
                case MT_CONST:      _onUpdate = _motion_parts;                break;
                case MT_ACCEL:      _onUpdate = _motion_accel_parts;          break;
                case MT_INTERPOL:   _onUpdate = _motion_interpolate_parts;    break;
                case MT_BULLETML:   _onUpdate = _motion_bml_parts;            break;
                default:
                    _motion_type = MT_CONST;
                    _onUpdate = _motion_parts;
                    break;
                }
                
                // calculate related position
                calcRelatedPosition();

                // calculate related angle
                _head = _head - _parent.angleOnScreen;
            } else {
                // change motion functor
                switch (_motion_type) {
                case MT_CONST:      _onUpdate = _motion;                break;
                case MT_ACCEL:      _onUpdate = _motion_accel;          break;
                case MT_INTERPOL:   _onUpdate = _motion_interpolate;    break;
                case MT_BULLETML:   _onUpdate = _motion_bml;            break;
                default:
                    _motion_type = MT_CONST;
                    _onUpdate = _motion;
                    break;
                }
            }
            
            // refrective funciton
            function _repush(obj:CMLObject) : void {
                obj.remove_from_list();
                _activeObjects.push(obj);
                for each (var part:CMLObject in obj._partChildren) { _repush(part); }
            }
        }
        
        
        // calculate the angleOnScreen in a range of -180 to 180.
        private function _normalizeHead() : void
        {
            var offset:Number = (_isPart) ? (_head_offset + _parent.angleOnScreen) : (_head_offset);
            _head += 180 - offset;
            _head *= 0.00277777777777777778;
            _head = (_head-int(_head)) * 360 - 180 + offset;
        }
        

        
        
    // option
    //------------------------------------------------------------
        /** Stop to update x, y and head. */
        public function optionNoMotion() : void
        {
            _onUpdate = onUpdate;
        }


        /** Inactivate "r" and "rc" commands. */
        public function optionNoRotation() : void
        {
            _onUpdate = _motion_without_rotation;
        }


        
        
    // execute in each frame when it's necessary
    //------------------------------------------------------------
        /** Calculate the absolute position when the isPart is true. 
         *  The protected function _motion_parts() is a typical usage of this. 
         */
        protected function calcAbsPosition() : void
        {
            var parent_angle:Number = angleParentOnScreen;
            if (parent_angle != 0) {
                var sang:int = sin.index(parent_angle),
                    cang:int = sang + sin.cos_shift;
                x = _parent.x + sin[cang]*_rx - sin[sang]*_ry;
                y = _parent.y + sin[sang]*_rx + sin[cang]*_ry;
            } else {
                x = _parent.x + _rx;
                y = _parent.y + _ry;
            }
        }


        /** Calculate the parent related position from absolute position.
         */
        protected function calcRelatedPosition() : void
        {
            var parent_angle:Number = angleParentOnScreen;
            if (parent_angle != 0) {
                var sang:int = sin.index(-parent_angle),
                    cang:int = sang + sin.cos_shift,
                    dx:Number = x - _parent.x,
                    dy:Number = y - _parent.y;
                _rx = sin[cang]*dx - sin[sang]*dy;
                _ry = sin[sang]*dx + sin[cang]*dy;
            } else {
                _rx = x - _parent.x;
                _ry = y - _parent.y;
            }
        }


        /** Rotate haed in 1 frame, if rotd > 0. The _motion() is a typical usage exapmle. @see CMLObject#_motion()*/
        protected function rotateHead() : void
        {
            _rott += _rotd;
            if (_rott >= 1) {
                _rott = 1;
                _rotd = 0;
            }
            _head = _roti.calc(_rott);
        }




    // operation for children/parts
    //------------------------------------------------------------
        /** Find first child object with specifyed id. 
         *  @param id Access id specifyed in create() or "n*" command.
         *  @return The first child object with specifyed id. Return null when the seach was failed.
         *  @see CMLObject#create()
         */
        public function findChild(id:int) : CMLObject
        {
            var obj:CMLObject;
            for each (obj in _IDedChildren) {
                if (obj._access_id == id) return obj;
            }
            return null;
        }


        /** Find all child and callback. <br/>
         *  @param id Access id specifyed in create() or "n*" command.
         *  @param func The call back function to operate objects. The type is function(obj:CMLObject):Boolean. Stop finding when this returns true.
         *  @return The count of the executions of call back function.
         *  @see CMLObject#create()
         */
        public function findAllChildren(id:int, func:Function) : int
        {
            var count:int = 0,
                obj:CMLObject;
            for each (obj in _IDedChildren) {
                if (obj._access_id == id) {
                    ++count;
                    if (func(obj)) break;
                }
            }
            return count;
        }


        /** Find all parts and callback. <br/>
         *  @param func The call back function to operate objects. The type is function(obj:CMLObject):Boolean. Stop finding when this returns true.
         *  @return The count of the executions of call back function.
         *  @see CMLObject#create()
         */
        public function findAllParts(func:Function) : int
        {
            var count:int = 0;
            for each (var obj:CMLObject in _partChildren) {
                ++count;
                if (func(obj)) break;
            }
            return count;
        }
                
        
        // back door ...
        /** @private */ internal function _getX() : Number { return (_isPart) ? _rx : x; }
        /** @private */ internal function _getY() : Number { return (_isPart) ? _ry : y; }
        /** @private */ internal function _getAx() : Number { return (_motion_type == MT_CONST || _motion_type == MT_BULLETML) ? 0 : _ax; }
        /** @private */ internal function _getAy() : Number { return (_motion_type == MT_CONST || _motion_type == MT_BULLETML) ? 0 : _ay; }




    // initialize and finalize
    //------------------------------------------------------------
        // initializer (call from CMLState)
        /** @private */ 
        internal function _initialize(parent_:CMLObject, isPart_:Boolean, access_id_:int, x_:Number, y_:Number, vx_:Number, vy_:Number, head_:Number) : CMLObject
        {
            // clear some parameters
            vx = vx_;
            vy = vy_;
            _head = head_;
            _head_offset = 0;
            _rotd = 0;
            _destructionStatus = -1;
            
            // set the relations
            _parent    = parent_;
            _parent_id = _parent._id;
            _IDedChildren.length = 0;
            _partChildren.length = 0;
            
            // add this to the parent id list
            _access_id = access_id_;
            if (access_id_ != ID_NOT_SPECIFYED) {
                _parent._IDedChildren.push(this);
            }
            
            // push the active objects list, initialize position and motion.
            _isPart = isPart_;
            if (isPart_) {
                _parent._partChildren.push(this);
                _rx = x_;
                _ry = y_;
                calcAbsPosition();
                _motion_type = MT_CONST;
                _onUpdate = _motion_parts;
            } else {
                x = x_;
                y = y_;
                _motion_type = MT_CONST;
                _onUpdate = _motion;
            }
            _activeObjects.push(this);
            
            // callback
            onCreate();
            
            return this;
        }


        // finalizer
        protected function _finalize() : void
        {
            if (parent != _root) {
                // remove this from the parent id list.
                if (_access_id != ID_NOT_SPECIFYED) {
                    _parent._IDedChildren.splice(_parent._IDedChildren.indexOf(this), 1);
                }
                // check parents parts
                if (_isPart) {
                    _parent._partChildren.splice(_parent._partChildren.indexOf(this), 1);
                }
            }
            
            // destroy all parts
            for each (var obj:CMLObject in _partChildren) {
                obj._destructionStatus = _destructionStatus;
            }
            
            // callback
            onDestroy();
            
            // remove from list
            remove_from_list();
            
            // update construction id
            _parent = null;
            _id++;
        }



        
    // inside _onUpdate
    //------------------------------------------------------------
        // basic motions
        //------------------------------------------------------------
        private function _motion_without_rotation() : void
        {
            x += vx;
            y += vy;
            onUpdate();
        }
        
        
        private function _motion() : void
        {
            x += vx;
            y += vy;
            if (_rotd != 0) rotateHead();
            onUpdate();
        }
        

        private function _motion_parts() : void
        {
            _rx += vx;
            _ry += vy;
            calcAbsPosition();
            if (_rotd != 0) rotateHead();
            onUpdate();
        }

        
        // motions on absolute position
        //------------------------------------------------------------
        private function _motion_accel() : void
        {
            // update parameters
            x   += vx + _ax*0.5;
            y   += vy + _ay*0.5;
            vx += _ax;
            vy += _ay;

            if (_rotd != 0) rotateHead();

            if (--_ac == 0) {
                _onUpdate = _motion;
                _motion_type = MT_CONST;
            }

            onUpdate();
        }
        

        private function _motion_interpolate() : void
        {
            // update parameters
            x   += vx + _ax*0.5 + _bx*0.16666666666666667;
            y   += vy + _ay*0.5 + _by*0.16666666666666667;
            vx += _ax + _bx*0.5;
            vy += _ay + _by*0.5;
            _ax += _bx;
            _ay += _by;

            if (_rotd != 0) rotateHead();

            if (--_ac == 0) {
                _onUpdate = _motion;
                _motion_type = MT_CONST;
            }

            onUpdate();
        }


        // motions on parent relative position
        //------------------------------------------------------------
        private function _motion_accel_parts() : void
        {
            // update parameters
            _rx += vx + _ax*0.5;
            _ry += vy + _ay*0.5;
            vx += _ax;
            vy += _ay;

            calcAbsPosition()
            if (_rotd != 0) rotateHead();
            if (--_ac == 0) {
                _onUpdate = _motion_parts;
                _motion_type = MT_CONST;
            }
            onUpdate();
        }

        
        private function _motion_interpolate_parts() : void
        {
            // update parameters
            _rx += vx + _ax*0.5 + _bx*0.16666666666666667;
            _ry += vy + _ay*0.5 + _by*0.16666666666666667;
            vx += _ax + _bx*0.5;
            vy += _ay + _by*0.5;
            _ax += _bx;
            _ay += _by;

            calcAbsPosition();
            if (_rotd != 0) rotateHead();
            if (--_ac == 0) {
                _onUpdate = _motion_parts;
                _motion_type = MT_CONST;
            }
            onUpdate();
        }




        // attraction
        //------------------------------------------------------------
        private function _motion_gravity() : void
        {
            // update parameters
            _ax = (_rx - x) * _bx - vx * _by,
            _ay = (_ry - y) * _bx - vy * _by;
            x   += vx + _ax*0.5;
            y   += vy + _ay*0.5;
            vx += _ax;
            vy += _ay;

            if (_rotd != 0) rotateHead();

            if (--_ac == 0) {
                _onUpdate = _motion;
                _motion_type = MT_CONST;
            }

            onUpdate();
        }




        // motion like bulletML
        //------------------------------------------------------------
        private function _motion_bml() : void
        {
            // update parameters
            var sang:int = sin.index(angle),
                cang:int = sang + sin.cos_shift;
            vx = sin[cang] * _ax;
            vy = sin[sang] * _ax;
            _ax += _bx;
            x += vx;
            y += vy;

            if (_rotd != 0) rotateHead();
            
            if (--_ac == 0) _bx=0;
            if (_rotd == 0 && _bx == 0) {
                _onUpdate = _motion;
                _motion_type = MT_CONST;
            }

            onUpdate();
        }

        
        private function _motion_bml_parts() : void
        {
            // update parameters
            var sang:int = sin.index(angle),
                cang:int = sang + sin.cos_shift;
            vx = sin[cang] * _ax;
            vy = sin[sang] * _ax;
            _ax += _bx;
            _rx += vx;
            _ry += vy;
            
            calcAbsPosition();
            if (_rotd != 0) rotateHead();
            if (--_ac == 0) _bx=0;
            if (_rotd == 0 && _bx == 0) {
                _onUpdate = _motion_parts;
                _motion_type = MT_CONST;
            }
            onUpdate();
        }
    }
}



