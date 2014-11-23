//----------------------------------------------------------------------------------------------------
// CML fiber class
//  Copyright (c) 2007 kei mesuda(keim) ALL RIGHTS RESERVED.
//  This code is under BSD-style(license.txt) licenses.
//----------------------------------------------------------------------------------------------------
// Ported to haxe by Brian Gunn (gunnbr@gmail.com) in 2014


package org.si.cml;

import org.si.cml.core.CMLBarrageElem;
import org.si.cml.core.CMLList;
import org.si.cml.core.CMLState;
import org.si.cml.core.CMLBarrage;
import org.si.cml.core.CMLListElem;
import org.si.cml.core.*;
import flash.errors.Error;
import haxe.CallStack;
    
/** Class for the fiber (Fiber is called as "micro thread" in some other languages). 
 *  <p>
 *  USAGE<br/>
 *  1) Get the CMLFiber instance from CMLObject.execute().<br/>
 *  2) CMLFiber.destroy(); stops this fiber.<br/>
 *  3) CMLFiber.object; accesses to the CMLObject this fiber controls.<br/>
 *  4) CMLFiber.target; accesses to the CMLObject this fiber targets to.<br/>
 *  </p>
 * @see CMLObject#execute()
 * @see CMLFiber#destroy()
 * @see CMLFiber#object
 * @see CMLFiber#target
 */
class CMLFiber extends CMLListElem
{
    // static variables
    //------------------------------------------------------------
        static public var _defaultTarget:CMLObject = null;        // default target instance
        
        
    // variables
    //------------------------------------------------------------
        public  var _id       :Int       = 0;     // id
        public  var _gene     :Int       = 0;     // child generation
        public  var _object   :CMLObject = null;  // running object
        public  var _object_id:Int       = 0;     // running object id
        public  var _target   :CMLObject = null;  // target object
        public  var _target_id:Int       = 0;     // target object id
        public  var _barrage  :CMLBarrage;        // bullet multiplyer
        public  var _pointer  :CMLState  = null;  // executing pointer
        public  var _access_id:Int       = 0;     // access id
        
        // children list
        public var _listChild:CMLList;
        public var _firstDest:CMLListElem; // first destruction fiber

        // setting parameters
        // TODO (haxe conversion): Is there a better replacement for "internal"?
        public var fx  :Float = 0;         // fiber position
        public var fy  :Float = 0;
        public var chgt:Int   = 0;         // pos/vel/rot changing time
        public var hopt:Int   = HO_AIM;    // head option
        public var hang:Float = 0;         // head angle [degree]
        public var fang:Float = 0;         // previous fired angle (due to the compatiblity with bulletML)
        public var bul :CMLBarrageElem;    // primary setting of bullet
        
        public var invt:Int    = 0;         // invertion flag (0=no, 1=x_reverse, 2=y_reverse, 3=xy_reverse)
        public var wtm1:Int    = 1;         // waiting time for "w"
        public var wtm2:Int    = 1;         // waiting time for "~"
        public var seqSub :CMLSequence = null; // previous calling sequence from "&"
        public var seqExec:CMLSequence = null; // previous calling sequence from "@"
        public var seqNew :CMLSequence = null; // previous calling sequence from "n"
        public var seqFire:CMLSequence = null; // previous calling sequence from "f"

        // runtime parameters
        public var wcnt:Int   = 0;          // waiting counter
        public var lcnt:Array<Dynamic>;     // loop counter
        public var jstc:Array<Dynamic>;     // sub routine call stac
        public var istc:Array<Dynamic>;     // invertion flag stac
        public var vars:Array<Dynamic>;     // arguments
        public var varc:Array<Dynamic>;     // argument counts
        
        // head option
        static inline public var HO_ABS:Int = 0;
        static inline public var HO_PAR:Int = 1;
        static inline public var HO_AIM:Int = 2;
        static inline public var HO_FIX:Int = 3;
        static inline public var HO_REL:Int = 4;
        static inline public var HO_VEL:Int = 5;
        static inline public var HO_SEQ:Int = 6;
        
        // I know these are very nervous implementations ('A`)...
        static public var seqDefault:CMLSequence;   // default sequence
        static public var seqRapid  :CMLSequence;   // rapid fire sequence
        
        // statement to wait for object destruction
        private var _stateWaitDest:CMLSequence = null;
        
        // executable looping max limitation in 1 frame
        public static var _loopmax:Int = 1024;
        
        // executable gosub max limitation
        public static var _stacmax:Int = 64;
        
        // id not specified 
        public static inline var ID_NOT_SPECIFIED:Int = 0;




    // properties
    //------------------------------------------------------------
        /** Maximum limitation of the executable looping count in 1 frame. @default 1024*/
        static public var maxLoopInFrame(null,set):Int;
    static public function set_maxLoopInFrame(lm:Int):Int { _loopmax = lm; return _loopmax;}
        /** Maximum limitation of the executable gosub nest count. @default 64*/
        static public var maxStacCount(null,set):Int;
    static public function set_maxStacCount(sc:Int):Int   { _stacmax = sc; return _stacmax;}
            
        /** CMLObject that this fiber controls. */
        public var object(get,null) : CMLObject;
        public function get_object()  : CMLObject  { return _object; }
        /** CMLObject that this fiber targets to. */
        public var target(get,set) : CMLObject;
        public function get_target() : CMLObject  { return _target; }
        public function set_target(t:CMLObject) : CMLObject { (t==null)?_setTarget(_defaultTarget):_setTarget(t); return _target;}

        /** CMLBarrage that this fiber uses. */
        public var barrage(get,null) : CMLBarrage;
        public function get_barrage() : CMLBarrage { return _barrage; }
        /** Angle of this fiber. The value is set by "h*" commands. */
        public var angle(get,null) : Float;
        public function get_angle()   : Float     { return _getAngle(0) + CMLObject.scrollAngle; }
        /** String argument. <br/>
         *  This property is used in callback function of CMLSequence.registerUserCommand().<br/>
         *  When the next statement of user command is not '...', this property shows null.
         *  @example
<listing version="3.0">
    // Register the user command
    CMLSequence.registerUserCommand("print", callbackPrint);

    function callbackPrint(fbr:CMLFiber) {
        // You can refer the string after user command.
        _drawText(fbr.string);
    }

    // String comment after the user command in sequence.
    // In this sequence, you call _drawText('Hello World !!').
    var seq:CMLSequence = new CMLSequence("&print'Hello World !!'");
</listing>
         */
        public var string(get,null) : String;
        public function get_string()  : String { 
            var stateString:CMLString = cast(_pointer.next,CMLString);
            return (stateString != null) ? stateString._string : null;
        }
        /** Sequence argument. <br/>
         *  This property is used in callback function of CMLSequence.registerUserCommand() with the option 'requireSequence' is true.<br/>
         *  When the next statement of user command is not sequence. outputs parsing error. Or, when the next statement is '{.}', returns null.
         */
        public var sequence(get,null) : CMLSequence;
        public function get_sequence() : CMLSequence {
            var stateRefer:CMLRefer = cast(_pointer.next,CMLRefer);
            return (stateRefer != null) ? (cast(stateRefer.jump,CMLSequence)) : null;
        }
        /** Is active ? When this property shows false, this fiber is already destroyed. */
        public var isActive(get,null) : Bool;
        public function get_isActive() : Bool { return (_object != null); }
        /** Is sequence executing ? */
        public var isExecuting(get,null) : Bool;
        public function get_isExecuting() : Bool { return (_pointer != null); }
        /** Does this fiber have any children ? */
        public var isParent(get,null) : Bool;
        public function get_isParent() : Bool { return (!_listChild.isEmpty()); }
        /** Does this fiber have any destruction fiber ? */
        public var hasDestFiber(get,null) : Bool;
        public function get_hasDestFiber() : Bool { return (_firstDest != _listChild.end); }
        

        
        
    // Constructor
    //------------------------------------------------------------
        /** <b>You cannot create new CMLFiber().</b> You can get CMLFiber instance only from
         *  CMLObject.execute().
         *  @see CMLObject#execute()
         */
        function new()
        {
            super();
            _gene = 0;
            _listChild = new CMLList();
            _firstDest = _listChild.end;
            _barrage   = new CMLBarrage();  
            bul        = new CMLBarrageElem();   
            lcnt       = new Array(); 
            jstc       = new Array();
            istc       = new Array();
            vars       = new Array();
            varc       = new Array();
            seqDefault = CMLSequence.newDefaultSequence();
            seqRapid   = CMLSequence.newRapidSequence();
        }




    // operations
    //------------------------------------------------------------
        /** Stop the fiber.<br/>
         *  This function stops all child fibers also.
         */
        public function destroy() : Void
        {
            if (isActive) _finalize();
        }
        



    // operations to children
    //------------------------------------------------------------
        /** Stop all child fibers. */
        public function destroyAllChildren() : Void
        {
            var elem     :CMLListElem;
            var elem_next:CMLListElem;
            var elem_end :CMLListElem = _listChild.end;
            elem=_listChild.begin;
            while (elem!=elem_end) {
                elem_next = elem.next;
                cast(elem,CMLFiber).destroy();
                elem=elem_next;
            }
        }
        

        /** Stop child fiber with specified id. */
        public function destroyChild(child_id:Int) : Bool
        {
            var fbr:CMLFiber = findChild(child_id);
            if (fbr != null) {
                fbr.destroy();
                return true;
            }
            return false;
        }


        /** Find child fiber with specified id. */
        public function findChild(child_id:Int) : CMLFiber
        {
            var elem    :CMLListElem;
            var elem_end:CMLListElem = _firstDest;
            elem=_listChild.begin;
            while  (elem!=elem_end) {
                if (cast(elem,CMLFiber)._access_id == child_id) return cast(elem,CMLFiber);
                elem=elem.next;
            }
            return null;
        }


        /** Find child fiber with specified id. @private */
        function _destroyDestFiber(destructionStatus:Int) : Void
        {
            if (hasDestFiber) {
                var fbr:CMLFiber = cast(_firstDest,CMLFiber);

                if (fbr._access_id == destructionStatus) {
                    _firstDest = fbr.next;
                    fbr.destroy();
                } else {
                    var elem:CMLListElem, elem_end:CMLListElem = _listChild.end;
                    elem=_firstDest.next;
                    while (elem!=elem_end) {
                        if (cast(elem,CMLFiber)._access_id == destructionStatus) {
                            cast(elem,CMLFiber).destroy();
                            return;
                        }
                        elem = elem.next;
                    }
                }
            }
        }




    // reference
    //------------------------------------------------------------
        /** Get the variables of the sequence "$1...$9". 
         *  @param Index of variable.
         *  @return Value of variable.
         */
        public function getVeriable(idx:Int) : Float
        {
            return (idx < varc[0]) ? vars[idx] : 0;
        }


        /** Get the loop counter of this fiber. 
         *  @param Nested loop index. The index of 0 means the most inner loop, and 1 means the loop 1 outside.
         *  @return Loop count. Start at 0, and end at [loop_count]-1.
         */
        public function getLoopCounter(nest:Int=0) : Int
        {
            return (lcnt.length > nest) ? lcnt[nest] : 0;
        }
        
        
        /** Get the interval value (specified by "i" command) of this fiber. 
         *  @return Interval.
         */
        public function getInterval() : Int
        {
            return chgt;
        }
        



    // internal functions
    //------------------------------------------------------------
        // initializer (call from CMLState._fiber())
        private function _initialize(parent:CMLFiber, obj:CMLObject, seq:CMLSequence, access_id_:Int, invt_:Int=0, args_:Array<Dynamic>=null) : Bool
        {
            _setObject(obj);            // set running object
            _access_id = access_id_;    // access id
            _gene = parent._gene + 1;   // set generation
            _clear_param();             // clear parameters
            invt = invt_;               // set invertion flag

            _pointer = cast(seq.next,CMLState);  // set cml pointer
            wcnt = 0;                       // reset waiting counter
            lcnt.splice(0,lcnt.length);     // clear loop counter stac
            jstc.splice(0,jstc.length);                // clear sub-routine call stac
            istc.splice(0,istc.length);                // clear invertion stac
            
            _firstDest = _listChild.end;    // reset last child
            
            _unshiftArguments(seq.require_argc, args_);  // set argument

            return (_gene < _stacmax);
        }
        
        
        // finalizer 
        private function _finalize() : Void
        {
            destroyAllChildren();

            _pointer = null;
            _object = null;
            _target = null;
            ++_id;

            remove_from_list();
            _freeFibers.push(this);
        }


        // set object
        private function _setObject(obj:CMLObject) : Void { _object = obj; _object_id = obj.id; }
        private function _setTarget(tgt:CMLObject) : Void { _target = tgt; _target_id = tgt.id; }

        
        // clear parameters
        private function _clear_param() : Void
        {
            _setTarget(_defaultTarget); // set target object
            
            fx   = 0;       // fiber position
            fy   = 0;
            chgt = 0;       // changing time
            hopt = HO_AIM;  // head option
            hang = 0;       // head angle [degree]
            fang = 0;       // previous fired angle (due to the compatiblity with bulletML)
            
            bul.setSequence(1,0,0,0);
            _barrage.clear();
            
            invt = 0;       // invertion flag
            wtm1 = 1;       // waiting time for "w"
            wtm2 = 1;       // waiting time for "~"

            if (vars.length > 0) {
                // TODO (haxe conversion): Is there a better way to do this?
                vars.splice(0,vars.length);
            }
            if (varc.length > 0) {
                // TODO (haxe conversion): Is there a better way to do this?
                varc.splice(0,varc.length);
            }

            seqSub  = seqDefault;
            seqExec = seqDefault;
            seqNew  = seqDefault;
            seqFire = seqDefault;
        }


        // copy parameters
        private function _copy_param(src:CMLFiber) : CMLFiber
        {
            _setTarget(src.target);  // set target object

            fx   = src.fx;      // fiber position
            fy   = src.fy;
            chgt = src.chgt;    // changing time
            hopt = src.hopt;    // head option
            hang = src.hang;    // head angle [degree]
            fang = src.fang;    // previous fired angle (due to the compatiblity with bulletML)
            
            bul.copy(src.bul);
            
            _barrage.appendCopyOf(src._barrage);

            wtm1 = src.wtm1;    // waiting time for "w"
            wtm2 = src.wtm2;    // waiting time for "~"

            seqSub  = src.seqSub;
            seqExec = src.seqExec;
            seqNew  = src.seqNew;
            seqFire = src.seqFire;

            return this;
        }
        
        
        // execution in 1 frame and returns next fiber
        private function _onUpdate() : CMLListElem
        {
            // next fiber
            var nextElem:CMLListElem = next;
            
            // kill fiber, if object was destroyed.
            if (_object.id != _object_id) {
                destroy();
                return nextElem;
            }
            
            // set target to default, if target was destroyed.
            if (_target.id != _target_id) {
                _setTarget(_defaultTarget);
            }
            
            // execution
            CMLState._setInvertionFlag(invt);           // set invertion flag
            if (--wcnt <= 0) {                          // execute only if waiting counte<=0
                var i:Int = 0;
                var res:Bool = true;
                while (res && _pointer!=null) {
                    res = _pointer.func(this);           // execute CMLState function
                    _pointer = cast(_pointer.next,CMLState);  // increment pointer

                    // too many loops error, script may has no wait.
                    if (++i == _loopmax) {
                        throw new Error("CML Exection error. No wait command in the loop ?");
                    }
                }
            }
            
            // run all children
            var elem     :CMLListElem;
            var elem_end :CMLListElem = _listChild.end;
            elem = _listChild.begin;
            while (elem!=elem_end) {
                elem = cast(elem,CMLFiber)._onUpdate();
            } 

            // update next fiber
            nextElem = next;
            
            // destroy if no children and no pointer
            if (_pointer==null && _listChild.isEmpty()) {
                destroy();
            }

            // return next fiber
            return nextElem;
        }


        // destroy by object
        private function _destroyByObject(obj:CMLObject) : CMLListElem
        {
            // check all children
            var elem     :CMLListElem = _listChild.begin;
            var elem_end :CMLListElem = _listChild.end;
            while(elem!=elem_end) {
                try {
                    elem = cast(elem,CMLFiber)._destroyByObject(obj);
                }
                catch (e:Dynamic) {
                    trace('Failed to destroy by object on elem <$elem>: $e');
                }
            }

            elem = next;
            if (_object == obj) destroy();
            return elem;
        }
        
        
        
        // push arguments
        /** @private */ 
        public function _unshiftArguments(argCount:Int=0, argArray:Array<Dynamic>=null) : Void
        {
            var i:Int;
            
            if (argCount==0 && (argArray==null || argArray.length==0)) {
                varc.unshift(0);
            } else {
                if (argArray!=null) {
                    argCount = (argCount > argArray.length) ? argCount : argArray.length;
                    varc.unshift(argCount);
                    i = argCount-1;
                    while (i>=argArray.length){ vars.unshift(0); --i; }
                    while (i>=0) { vars.unshift(argArray[i]); --i;}
                } else {
                    varc.unshift(argCount);
                    i=argCount-1;
                    while (i>=0) { vars.unshift(0); --i;}
                }
            }
        }
        
        
        // pop arguments
        /** @private */ 
        public function _shiftArguments() : Void
        {
            vars.splice(0, varc.shift());
        }

        
        // push invertion
        /** @private */ 
        public function _unshiftInvertion(invt_:Int) : Void
        {
            istc.unshift(invt);
            invt = invt_;
        }

        
        // pop invertion
        /** @private */ 
        public function _shiftInvertion() : Void
        {
            invt = istc.shift();
        }
        
        
        // return fiber's head angle (angle in this game's screen, the scroll direction is 0[deg]).
        /** @private */ 
        public function _getAngle(base:Float) : Float
        {
            switch(hopt) {
            case HO_AIM:  // based on the angle to the target
                base = _object.getAimingAngle(_target, fx, fy);
            case HO_ABS:  // based on the angle in the absolute coordination
                base = 0;
            case HO_FIX:  // based on the fixed angle
                base = 0;
            case HO_REL:  // based on the angle of this object
                base = _object.angleOnStage;
            case HO_PAR:  // based on the angle of the parent object
                base = _object.angleParentOnStage;
            case HO_VEL:  // based on the angle of velocity
                base = _object.angleVelocity;
            case HO_SEQ:  // sequencial do nothing
            default:
                throw new Error("BUG!! unknown error in CMLFiber._getAngle()"); // ???
            }
            return base + hang;
        }
        
        
        // return angle for rotation command(r, rc, cd). HO_AIM is aiming angle from the object.
        /** @private */ 
        public function _getAngleForRotationCommand() : Float
        {
            switch(hopt) {
            case HO_AIM: return _object.getAimingAngle(_target) + hang;  // based on the angle to the target
            case HO_ABS: return hang;                                    // based on the angle in the absolute coordination
            case HO_FIX: return hang;                                    // based on the fixed angle
            case HO_REL: return _object.angleOnStage + hang;             // based on the angle of this object
            case HO_PAR: return _object.angleParentOnStage + hang;       // based on the angle of the parent object
            case HO_VEL: return _object.angleVelocity + hang;            // based on the angle of velocity
            case HO_SEQ: return _object.angleOnStage + hang * chgt;      // sequencial
            default:
                throw new Error("BUG!! unknown error in CMLFiber._getAngleForRotationCommand()"); // ???
            }
            return 0;
        }
        
        
        // rotate object in minimum rotation (call from CMLState.r())
        /** @private */ 
        public function _isShortestRotation() : Bool
        {
            return (hopt==HO_AIM || hopt==HO_VEL || hopt==HO_FIX);
        }




    // static function
    //------------------------------------------------------------
        static private var _freeFibers:CMLList  = new CMLList();    // free list
        static private var _rootFiber :CMLFiber = new CMLFiber();   // root fiber of active fibers

        /** @private destroy all */
        static public function _destroyAll() : Void
        {
            var activeFibers:CMLList = _rootFiber._listChild;
            if (activeFibers.isEmpty()) return;
            
            var elem    :CMLListElem;
            var elem_end:CMLListElem = activeFibers.end;
            elem=activeFibers.begin;
            while (elem!=elem_end) {
                var nextElem:CMLListElem = elem.next;
                cast(elem,CMLFiber)._finalize();
                elem = nextElem;
            }
        }
        

        // 1 frame execution for all fibers
        /** @private */ 
        static public function _onUpdateAll() : Void
        {
            var activeFibers:CMLList = _rootFiber._listChild;
            if (activeFibers.isEmpty()) return;
            
            var elem    :CMLListElem;
            var elem_end:CMLListElem = activeFibers.end;
            
            elem=activeFibers.begin; 
            while (elem!=elem_end) {
                elem = cast(elem,CMLFiber)._onUpdate();
            }
        }
        
        
        // new fiber
        /** call only from CMLObject.execute() @private */ 
        static public function _newRootFiber(obj:CMLObject, seq:CMLSequence, args_:Array<Dynamic>, invt_:Int) : CMLFiber
        {
            if (seq == null || seq.isEmpty) return null;
            var fbr:CMLFiber = cast(_freeFibers.pop(),CMLFiber);
            if (fbr == null) {
                fbr = new CMLFiber();
            }
            fbr.insert_before(_rootFiber._firstDest);                   // child of root
            fbr._initialize(_rootFiber, obj, seq, 0, invt_, args_);     // the generation is counted from root
            return fbr;
        }

        /** call only from the '@' command (CMLState._fiber()) @private */ 
        public function _newChildFiber(seq:CMLSequence, id:Int, invt_:Int, args_:Array<Dynamic>, copyParam:Bool) : CMLFiber
        {
            if (id != ID_NOT_SPECIFIED) destroyChild(id);                   // destroy old fiber, when id is obtained
            if (seq.isEmpty) return null;
            var fbr:CMLFiber = cast(_freeFibers.pop(),CMLFiber);
            if (fbr == null) {
                fbr = new CMLFiber();
            }
            fbr.insert_before(_firstDest);                                  // child of this
            if (!fbr._initialize(this, _object, seq, id, invt_, args_)) {   // the generation is counted from root
                throw new Error("CML Exection error. The '@' command calls depper than stac limit.");
            }
            if (copyParam) fbr._copy_param(this);                           // copy parameters from parent
            return fbr;
        }
        
        /** call only from the '@ko' command (CMLState._fiber_destruction()) @private */
        public function _newDestFiber(seq:CMLSequence, id:Int, invt_:Int, args_:Array<Dynamic>) : CMLFiber
        {
            _destroyDestFiber(id);                                          // destroy old fiber
            
            if (seq.isEmpty) return null;
            var fbr:CMLFiber = cast(_freeFibers.pop(),CMLFiber);
            if (fbr == null) {
                fbr = new CMLFiber();
            }
            // set destruction sequence
            if (fbr._stateWaitDest == null) {
                fbr._stateWaitDest = CMLSequence.newWaitDestuctionSequence();
            }
            cast(fbr._stateWaitDest.next,CMLState).jump = seq;
            
            fbr.insert_before(_firstDest);                                  // child of this
            _firstDest = fbr;                                               // overwrite first destruction fiber
            if (!fbr._initialize(this, _object, fbr._stateWaitDest, id, invt_, args_)) {
                throw new Error("CML Exection error. The '@ko' command calls depper than stac limit.");
            }
            return fbr;
        }

        /** call from the 'n', 'f' or '@o' command (search in CMLState) @private */ 
        public function _newObjectFiber(obj:CMLObject, seq:CMLSequence, invt_:Int, args_:Array<Dynamic>) : CMLFiber
        {
            if (seq.isEmpty) return null;
            var fbr:CMLFiber = cast(_freeFibers.pop(),CMLFiber);
            if (fbr == null) {
                fbr = new CMLFiber();
            }
            fbr.insert_before(_rootFiber._firstDest);                       // child of root
            if (!fbr._initialize(this, obj, seq, 0, invt_, args_)) {        // the generation is counted from this
                throw new Error("CML Exection error. The 'n', 'f' or '@o' command calls depper than stac limit.");
            }
            return fbr;
        }
        
        
        // destroy all fibers
        /** call from CMLObject.halt() @private */ 
        static public function _destroyAllFibers(obj:CMLObject) : Void
        {
            var fibers  :CMLList = _rootFiber._listChild,
                elem    :CMLListElem,
                elem_end:CMLListElem = fibers.end;
            elem=fibers.begin;
            while (elem!=elem_end) {
                elem = cast(elem,CMLFiber)._destroyByObject(obj);
            }
        }
    }



