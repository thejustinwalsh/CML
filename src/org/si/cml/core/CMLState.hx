//----------------------------------------------------------------------------------------------------
// CML statement class
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml.core;

import org.si.cml.CMLFiber;
import org.si.cml.CMLObject;
import org.si.cml.CMLSequence;
import flash.errors.Error;    
    
/** @private */
class CMLState extends CMLListElem
{
        static private var sin:CMLSinTable;
    
    // variables
    //------------------------------------------------------------
        public var type:Int;     // statement type
        public var func:CMLFiber->Bool; // execution function
        public var jump:CMLState; // jump pointer
        public var _args:Array<Dynamic>;   // arguments array
        
        static inline public var ST_NORMAL  :Int = 0;   // normal command
        static inline public var ST_REFER   :Int = 1;   // refer sequence
        static inline public var ST_LABEL   :Int = 2;   // labeled sequence define "#*.{...}"
        static inline public var ST_NO_LABEL:Int = 3;   // non-labeled sequence define "{...}"
        static inline public var ST_RESTRICT:Int = 4;   // restrict to put reference after this command ("&","@*","n*")
        static inline public var ST_LOOP    :Int = 5;   // loop "["
        static inline public var ST_IF      :Int = 6;   // if "[?"
        static inline public var ST_ELSE    :Int = 7;   // else ":"
        static inline public var ST_SELECT  :Int = 8;   // select "[s?"
        static inline public var ST_BLOCKEND:Int = 9;   // block end "]"
        static inline public var ST_FORMULA :Int =10;   // formula 
        static inline public var ST_STRING  :Int =11;   // string
        static inline public var ST_END     :Int =12;   // end
        static inline public var ST_BARRAGE :Int =13;   // multiple barrage
        static inline public var ST_W4D     :Int =14;   // wait for destruction
        static inline public var ST_RAPID   :Int =16;   // rapid fire sequence
        static inline public var STF_CALLREF:Int =32;   // flag to require reference after this command ("&","@*","f*","n*")

        // invert flag
        static public var _invert_flag:Int = 0;
        
        // speed ratio
        static public var _speed_ratio:Float = 1;
        
        // command regular expressions
        static public var command_rex:String = //{
        "(\\[s\\?|\\[\\?|\\[|\\]|\\}|:|\\^&|&|w\\?|w|~|pd|px|py|p|vd|vx|vy|v|ad|ax|ay|a|gp|gt|rc|r|ko|i|m|cd|csa|csr|css|\\^@|@ko|@o|@|\\^n|nc|n|\\^f|fc|f|qx|qy|q|bm|bs|br|bv|hax|ha|hox|ho|hpx|hp|htx|ht|hvx|hv|hs|td|tp|to|kf)";
        
        
        
        
    // functions
    //------------------------------------------------------------
        public function new(type_:Int = ST_NORMAL)
        {
            super();
            _args = [];
            jump = null;
            type = type_;
            sin = new CMLSinTable();
            
            switch (type) {
            case ST_RAPID:    func = _rapid_fire;
            case ST_BARRAGE:  func = _initialize_barrage;
            case ST_W4D:
                func = _wait4destruction;
                next = this;
            default:          func = _nop;
            }
        }
    
    
        override public function clear() : Void
        {
            _args.splice(_args.length,0);
            jump = null;
            super.clear();
        }

        static public var speedRatio(get,set):Float;
        static public function set_speedRatio(r:Float) : Float { _speed_ratio = r; return _speed_ratio;}
        static public function get_speedRatio() : Float { return _speed_ratio; }
        
        public function setCommand(cmd:String) : CMLState { return _setCommand(cmd); }
        
        
        
        
    // private fuctions
    //------------------------------------------------------------
        /** set command by key string @private */
        public function _setCommand(cmd:String) : CMLState
        {
            switch (cmd) {
            // waiting 
            case "w":
                if (_args.length == 0) {
                    func = _w0;
                } else {
                    func = _w1;
                    if (_args[0]==0) _args[0]=0x7FFFFFFF;
                }
            case "~":   func = _wi;
            case "w?":  func = _waitif;
            // sequence
            case "}":   func = _ret;         type = ST_END;
            // repeat and branch
            case "[":   func = _loop_start;  type = ST_LOOP;     _resetParameters(1);
            case "[?":  func = _if_start;    type = ST_IF;       if (_args.length==0) throw new Error("no arguments in [?");
            case "[s?": func = _level_start; type = ST_SELECT;   if (_args.length==0) throw new Error("no arguments in [s?");
            case ":":   func = _else_start;  type = ST_ELSE;     _resetParameters(1);
            case "]":   func = _block_end;   type = ST_BLOCKEND; _resetParameters(1);
            // interval
            case "i":   func = _i;  _resetParameters(1);
            // position
            case "p":   func = _p;  _resetParameters(2);
            case "px":  func = _px; _resetParameters(1);
            case "py":  func = _py; _resetParameters(1);
            case "pd":  func = _pd; _resetParameters(2);
            // velocity
            case "v":   func = _v;  _resetParameters(2);
            case "vx":  func = _vx; _resetParameters(1);
            case "vy":  func = _vy; _resetParameters(1);
            case "vd":  func = _vd; _resetParameters(2);
            // accelaration
            case "a":   func = _a;  _resetParameters(2);
            case "ax":  func = _ax; _resetParameters(1);
            case "ay":  func = _ay; _resetParameters(1);
            case "ad":  func = _ad; _resetParameters(2);
            // rotation
            case "r":   func = _r;  _resetParameters(2);
            case "rc":  func = _rc; _resetParameters(1);
            // gravity
            case "gp":  func = _gp; _resetParameters(3);
            // bml
            case "cd":  func = _cd;  _resetParameters(2);
            case "csa": func = _csa; _resetParameters(2);
            case "csr": func = _csr; _resetParameters(2);
            case "css": func = _css; _resetParameters(2);
            // kill object
            case "ko":  func = _ko;  _resetParameters(1);
            // sub routine
            case "&":   func = _gosub;                     type = ST_RESTRICT | STF_CALLREF;
            case "^&":  func = _fgosub;                    type = ST_RESTRICT | STF_CALLREF;
            // fiber
            case "@":   func = _at;   _resetParameters(1); type = ST_RESTRICT | STF_CALLREF;
            case "@o":  func = _ato;  _resetParameters(1); type = ST_RESTRICT | STF_CALLREF;
            case "@ko": func = _atko; _resetParameters(1); type = ST_RESTRICT | STF_CALLREF;
            case "^@":  func = _fat;                       type = ST_RESTRICT | STF_CALLREF;
            case "kf":  func = _kf;
            // new
            case "n":   func = _n;    _resetParameters(1); type = ST_RESTRICT | STF_CALLREF;
            case "nc":  func = _nc;   _resetParameters(1); type = ST_RESTRICT | STF_CALLREF;
            case "^n":  func = _fn;   _resetParameters(1); type = ST_RESTRICT | STF_CALLREF;
            // fire
            case "f":   _resetParameters(2); func = (Math.isNaN(_args[0])) ? _f0  : _f1;  type = STF_CALLREF;
            case "fc":  _resetParameters(2); func = (Math.isNaN(_args[0])) ? _fc0 : _fc1; type = STF_CALLREF;
            case "^f":  _resetParameters(2); func = (Math.isNaN(_args[0])) ? _ff0 : _ff1; type = STF_CALLREF;
            // fiber position
            case "q":   func = _q;  _resetParameters(2);
            case "qx":  func = _qx; _resetParameters(1);
            case "qy":  func = _qy; _resetParameters(1);
            // head
            case "ha":  func = _ha;  _resetParameters(1);
            case "hax": func = _ha;  _resetParameters(1);
            case "hp":  func = _hp;  _resetParameters(1);
            case "ht":  func = _ht;  _resetParameters(1);
            case "ho":  func = _ho;  _resetParameters(1);
            case "hv":  func = _hv;  _resetParameters(1);
            case "hpx": func = _hpx; _resetParameters(1);
            case "htx": func = _htx; _resetParameters(1);
            case "hox": func = _hox; _resetParameters(1);
            case "hvx": func = _hvx; _resetParameters(1);
            case "hs":  func = _hs;  _resetParameters(1);
            // barrage
            case "bm": func = _bm; _resetParameters(4); type = ST_BARRAGE;
            case "bs": func = _bs; _resetParameters(4); type = ST_BARRAGE;
            case "br": func = _br; _resetParameters(4); type = ST_BARRAGE;
            case "bv": func = _bv; _resetParameters(1);
            // target
            case "td": func = _td;
            case "tp": func = _tp;
            case "to": func = _to; _resetParameters(1);
            // mirror
            case "m":  func = _m;  _resetParameters(1);
            
            default:
                throw new Error("Unknown command; " + cmd + " ?");
            }
            
            // set undefined augments to 0.
            var idx:Int;
            for (idx in 0..._args.length) {
                if (Math.isNaN(_args[idx])) _args[idx] = 0;
            }

            return this;
        }
        
        // set default arguments
        public function _resetParameters(argc:Int) : Void
        {
            var ibegin:Int = _args.length;
            if (ibegin < argc) {
                var i:Int;
                for (i in ibegin...argc) {
                    _args.push(Math.NaN);
                }
            }
        }

        
        
        
    // command executer
    //------------------------------------------------------------
        // set invertion flag (call from CMLFiber.execute())
        static public function _setInvertionFlag(invt_:Int) : Void
        {
            _invert_flag = invt_;
        }
        
        // no operation or end
        public function _nop(fbr:CMLFiber) : Bool { return true; }
        
        // looping, branching
        private function _loop_start(fbr:CMLFiber) : Bool {
            fbr.lcnt.unshift(0);
            return true;
        }
        private function _if_start(fbr:CMLFiber) : Bool {
            if (_args[0]==0) fbr._pointer = jump;
            return true;
        }
        private function _level_start(fbr:CMLFiber) : Bool {
            while (fbr._pointer.jump.type == ST_ELSE) {
                if (_args[0] < fbr._pointer.jump._args[0]) return true;
                fbr._pointer = fbr._pointer.jump;
            }
            return true;
        }
        private function _else_start(fbr:CMLFiber) : Bool {
            do {
                fbr._pointer = fbr._pointer.jump;
            } while (fbr._pointer.type == ST_ELSE);
            return true;
        }
        private function _block_end(fbr:CMLFiber) : Bool {
            if (jump.type == ST_LOOP) {
                var lmax:Int = Std.int(_args[0] != null ? _args[0] : jump._args[0]);
                if (++fbr.lcnt[0] != lmax) {
                    fbr._pointer = jump;
                    return true;
                }
                fbr.lcnt.shift();
            }
            return true;
        }

        // wait
        private function _w0(fbr:CMLFiber) : Bool {                      fbr.wcnt = fbr.wtm1; return false; }
        private function _w1(fbr:CMLFiber) : Bool { fbr.wtm1 = _args[0]; fbr.wcnt = fbr.wtm1; return false; }
        private function _wi(fbr:CMLFiber) : Bool {                      fbr.wcnt = fbr.wtm2; return (fbr.wcnt == 0); }
        
        // waitif
        private function _waitif(fbr:CMLFiber) : Bool {
            if (_args[0] == 0) return true;
            fbr._pointer = (cast(prev,CMLState).type == ST_FORMULA) ? cast(prev.prev,CMLState) : cast(prev,CMLState);
            return false;
        }
        
        // interpolation interval
        private function _i(fbr:CMLFiber) : Bool { 
            fbr.chgt = Std.int(_args[0]);
            fbr.wtm2 = fbr.chgt;
            return true;
        }
        
        // mirroring
        private function _m(fbr:CMLFiber) : Bool {
            // invert flag
            _invert_flag = fbr.invt ^ (Std.int(_args[0]) + 1);
            // execute next statement
            fbr._pointer = cast(fbr._pointer.next,CMLState);
            var res:Bool = cast(fbr._pointer,CMLState).func(fbr);
            // reset flag
            _invert_flag = fbr.invt;
            return res;
        }

        // position of fiber
        private function _q(fbr:CMLFiber)  : Bool { fbr.fx=_invertX(_args[0]); fbr.fy=_invertY(_args[1]); return true; }
        private function _qx(fbr:CMLFiber) : Bool { fbr.fx=_invertX(_args[0]); return true; }
        private function _qy(fbr:CMLFiber) : Bool { fbr.fy=_invertY(_args[0]); return true; }

        // position
        private function _p(fbr:CMLFiber)  : Bool { fbr.object.setPosition(_invertX(_args[0]), _invertY(_args[1]), fbr.chgt); return true; }
        private function _px(fbr:CMLFiber) : Bool { fbr.object.setPosition(_invertX(_args[0]), fbr.object._getY(), fbr.chgt); return true; }
        private function _py(fbr:CMLFiber) : Bool { fbr.object.setPosition(fbr.object._getX(), _invertY(_args[0]), fbr.chgt); return true; }
        private function _pd(fbr:CMLFiber) : Bool {
            var iang:Int;
            if (fbr.hopt != CMLFiber.HO_SEQ) iang = sin.index(fbr._getAngleForRotationCommand()+CMLObject.scrollAngle);
            else                             iang = sin.index(fbr.object.anglePosition-fbr._getAngleForRotationCommand());
            var c:Float = sin[iang+sin.cos_shift],
                s:Float = sin[iang];
            fbr.object.setPosition(c*_args[0]-s*_args[1], s*_args[0]+c*_args[1], fbr.chgt);
            return true;
        }

        // velocity
        private function _v(fbr:CMLFiber)  : Bool { fbr.object.setVelocity(_invertX(_args[0]*_speed_ratio), _invertY(_args[1]*_speed_ratio), fbr.chgt); return true; }
        private function _vx(fbr:CMLFiber) : Bool { fbr.object.setVelocity(_invertX(_args[0]*_speed_ratio), fbr.object.vy,                   fbr.chgt); return true; }
        private function _vy(fbr:CMLFiber) : Bool { fbr.object.setVelocity(fbr.object.vx,                   _invertY(_args[0]*_speed_ratio), fbr.chgt); return true; }
        private function _vd(fbr:CMLFiber) : Bool {
            var iang:Int;
            if (fbr.hopt != CMLFiber.HO_SEQ) iang = sin.index(fbr._getAngleForRotationCommand()+CMLObject.scrollAngle);
            else                             iang = sin.index(fbr.object.angleVelocity-fbr._getAngle(0));
            var c:Float = sin[iang+sin.cos_shift],
                s:Float = sin[iang],
                h:Float = _args[0] * _speed_ratio,
                v:Float = _args[1] * _speed_ratio;
            fbr.object.setVelocity(c*h-s*v, s*h+c*v, fbr.chgt);
            return true;
        }

        // acceleration
        private function _a(fbr:CMLFiber)  : Bool { fbr.object.setAccelaration(_invertX(_args[0]*_speed_ratio), _invertY(_args[1]*_speed_ratio), 0); return true; }
        private function _ax(fbr:CMLFiber) : Bool { fbr.object.setAccelaration(_invertX(_args[0]*_speed_ratio), fbr.object._getAy(),            0); return true; }
        private function _ay(fbr:CMLFiber) : Bool { fbr.object.setAccelaration(fbr.object._getAx(),            _invertY(_args[0]*_speed_ratio), 0); return true; }
        private function _ad(fbr:CMLFiber) : Bool {
            var iang:Int;
            if (fbr.hopt != CMLFiber.HO_SEQ) iang = sin.index(fbr._getAngleForRotationCommand()+CMLObject.scrollAngle);
            else                             iang = sin.index(fbr.object.angleAccel-fbr._getAngle(0));
            var c:Float = sin[iang+sin.cos_shift],
                s:Float = sin[iang],
                h:Float = _args[0] * _speed_ratio,
                v:Float = _args[1] * _speed_ratio;
            fbr.object.setAccelaration(c*h-s*v, s*h+c*v, 0);
            return true;
        }

        // gravity
        private function _gp(fbr:CMLFiber) : Bool {
            fbr.chgt = 0;
            fbr.object.setGravity(_args[0] * _speed_ratio, _args[1] * _speed_ratio, _args[2]);
            return true;
        }
        
        // It's very tough to implement bulletML...('A`)
        private function _csa(fbr:CMLFiber) : Bool { fbr.object.setChangeSpeed(_args[0]*_speed_ratio,                     fbr.chgt); return true; }
        private function _csr(fbr:CMLFiber) : Bool { fbr.object.setChangeSpeed(_args[0]*_speed_ratio+fbr.object.velocity, fbr.chgt); return true; }
        private function _css(fbr:CMLFiber) : Bool { 
            if (fbr.chgt == 0) fbr.object.setChangeSpeed(_args[0]*_speed_ratio+fbr.object.velocity,          0);
            else               fbr.object.setChangeSpeed(_args[0]*_speed_ratio*fbr.chgt+fbr.object.velocity, fbr.chgt);
            return true; 
        }
        private function _cd(fbr:CMLFiber) : Bool { 
            fbr.object.setChangeDirection(fbr._getAngleForRotationCommand(), fbr.chgt, _args[0]*_speed_ratio, fbr._isShortestRotation());
            return true;
        }
        // rotation
        private function _r(fbr:CMLFiber)  : Bool {
            fbr.object.setRotation(fbr._getAngleForRotationCommand(), fbr.chgt, _args[0], _args[1], fbr._isShortestRotation());
            return true;
        }
        private function _rc(fbr:CMLFiber) : Bool {
            fbr.object.setConstantRotation(fbr._getAngleForRotationCommand(), fbr.chgt, _args[0]*_speed_ratio, fbr._isShortestRotation());
            return true;
        }

        // kill object
        private function _ko(fbr:CMLFiber) : Bool {
            fbr.object.destroy(_args[0]);
            return false;
        }
        // kill all children fiber
        private function _kf(fbr:CMLFiber) : Bool {
            fbr.destroyAllChildren();
            return true;
        }
        
        // initialize barrage
        private function _initialize_barrage(fbr:CMLFiber)  : Bool { fbr.barrage.clear(); return true; }
        // multiple barrage
        private function _bm(fbr:CMLFiber) : Bool { fbr.barrage.appendMultiple(_args[0], _invertRotation(_args[1]), _args[2], _args[3]); return true; }
        // sequencial barrage
        private function _bs(fbr:CMLFiber) : Bool { fbr.barrage.appendSequence(_args[0], _invertRotation(_args[1]), _args[2], _args[3]); return true; }
        // random barrage
        private function _br(fbr:CMLFiber) : Bool { fbr.barrage.appendRandom(_args[0], _invertRotation(_args[1]), _args[2], _args[3]);   return true; }
        
        // bullet sequence of verocity
        private function _bv(fbr:CMLFiber) : Bool { fbr.bul.setSpeedStep(_args[0]*_speed_ratio); return true; }

        // head angle
        private function _ha(fbr:CMLFiber)  : Bool { fbr.hang=_invertAngle(_args[0]); fbr.hopt=CMLFiber.HO_ABS; return true; }
        private function _ho(fbr:CMLFiber)  : Bool { fbr.hang=_invertAngle(_args[0]); fbr.hopt=CMLFiber.HO_REL; return true; }
        private function _hp(fbr:CMLFiber)  : Bool { fbr.hang=_invertAngle(_args[0]); fbr.hopt=CMLFiber.HO_PAR; return true; }
        private function _ht(fbr:CMLFiber)  : Bool { fbr.hang=_invertAngle(_args[0]); fbr.hopt=CMLFiber.HO_AIM; return true; }
        private function _hv(fbr:CMLFiber)  : Bool { fbr.hang=_invertAngle(_args[0]); fbr.hopt=CMLFiber.HO_VEL; return true; }
        private function _hox(fbr:CMLFiber) : Bool { fbr.hang=_invertAngle(_args[0]); fbr.hopt=CMLFiber.HO_REL; _fix(fbr); return true; }
        private function _hpx(fbr:CMLFiber) : Bool { fbr.hang=_invertAngle(_args[0]); fbr.hopt=CMLFiber.HO_PAR; _fix(fbr); return true; }
        private function _htx(fbr:CMLFiber) : Bool { fbr.hang=_invertAngle(_args[0]); fbr.hopt=CMLFiber.HO_AIM; _fix(fbr); return true; }
        private function _hvx(fbr:CMLFiber) : Bool { fbr.hang=_invertAngle(_args[0]); fbr.hopt=CMLFiber.HO_VEL; _fix(fbr); return true; }
        private function _hs(fbr:CMLFiber)  : Bool { fbr.hang=_invertRotation(_args[0]); fbr.hopt=CMLFiber.HO_SEQ; return true; }
        private function _fix(fbr:CMLFiber) : Void { fbr.hang=fbr._getAngle(0); fbr.hopt=CMLFiber.HO_FIX; }

        // set target
        private function _td(fbr:CMLFiber) : Bool { fbr.target = null; return true; }
        private function _tp(fbr:CMLFiber) : Bool { fbr.target = fbr.object.parent; return true; }
        private function _to(fbr:CMLFiber) : Bool { fbr.target = fbr.object.findChild(Std.int(_args[0])); return true; }
        
        // call sequence (create new fiber directry)
        // gosub
        private function _gosub(fbr:CMLFiber) : Bool {
            // execution error
            if (fbr.jstc.length > CMLFiber._stacmax) {
                throw new Error("CML Execution error. The '&' command calls deeper than stac limit.");
            }
            
            // next statement is referential sequence
            var ref:CMLRefer = cast(next,CMLRefer);
            var seq:CMLSequence  = (ref.jump != null) ? cast(ref.jump,CMLSequence) : (fbr.seqSub);
            fbr.jstc.push(ref);
            fbr._unshiftInvertion(_invert_flag);
            fbr._unshiftArguments(seq.require_argc, ref._args);
            fbr._pointer = seq;
            return true;
        }
        // fake gosub
        private function _fgosub(fbr:CMLFiber) : Bool {
            if (cast(next,CMLState).jump != null) fbr.seqSub = cast(cast(next,CMLState).jump, CMLSequence);
            return true;
        }
        
        // return
        private function _ret(fbr:CMLFiber) : Bool {
            // pop jump stac
            if (fbr.jstc.length > 0) {
                fbr._shiftArguments();
                fbr._shiftInvertion();
                fbr._pointer = fbr.jstc.pop();
                fbr.seqSub = cast(jump,CMLSequence);
            }
            return true;
        }
        
        // execute new fiber, fiber on child
        private function _at(fbr:CMLFiber)   : Bool { _fiber(fbr, _args[0]); return true; }
        private function _ato(fbr:CMLFiber)  : Bool { _fiber_child(fbr, fbr.object, _args); return true; }
    private function _fat(fbr:CMLFiber)  : Bool { if (cast(next,CMLState).jump != null) fbr.seqExec = cast(cast(next,CMLState).jump,CMLSequence); return true; }
        private function _atko(fbr:CMLFiber) : Bool { _fiber_destruction(fbr, _args[0]); return true; }

        // new
        private function _n(fbr:CMLFiber)  : Bool { _new(fbr, Std.int(_args[0]), false); return true; }
        private function _nc(fbr:CMLFiber) : Bool { _new(fbr, Std.int(_args[0]), true);  return true; }
    private function _fn(fbr:CMLFiber) : Bool { if (cast(next,CMLState).jump != null) fbr.seqNew = cast(cast(next,CMLState).jump,CMLSequence); return true; }
        
        // fire
        private function _f0(fbr:CMLFiber)  : Bool {                                        _fire(fbr, Std.int(_args[1]), false); fbr.bul.update(); return true; }
        private function _f1(fbr:CMLFiber)  : Bool { fbr.bul.speed = _args[0]*_speed_ratio; _fire(fbr, Std.int(_args[1]), false); fbr.bul.update(); return true; }
        private function _fc0(fbr:CMLFiber) : Bool {                                        _fire(fbr, Std.int(_args[1]), true);  fbr.bul.update(); return true; }
        private function _fc1(fbr:CMLFiber) : Bool { fbr.bul.speed = _args[0]*_speed_ratio; _fire(fbr, Std.int(_args[1]), true);  fbr.bul.update(); return true; }

        // fake fire
        private function _ff0(fbr:CMLFiber) : Bool { 
            var refer:CMLRefer = cast(next,CMLRefer);
            if (refer.jump != null) fbr.seqFire = cast(refer.jump,CMLSequence);
            fbr.fang = fbr._getAngle(fbr.fang);
            fbr._pointer = refer;
            fbr.bul.update();
            return true;
        }
        private function _ff1(fbr:CMLFiber) : Bool {
            fbr.bul.speed = _args[0]*_speed_ratio;
            return _ff0(fbr);
        }
        
        // statement for rapid fire
        private function _rapid_fire(fbr:CMLFiber) : Bool {
            // end
            if (fbr.bul.isEnd()) return false;

            // create new bullet object and initialize
            _create_multi_bullet(fbr, fbr.wtm1, (fbr.wtm2 == 0)?false:true, null);
            
            // calc bullet and set wait counter
            fbr.bul.update();
            fbr.wcnt = Std.int(fbr.bul.interval);
            
            // repeat
            fbr._pointer = CMLFiber.seqRapid;
            
            return false;
        }
        
        // statement to wait for destruction
        private function _wait4destruction(fbr:CMLFiber) : Bool {
            if (fbr.object.destructionStatus == fbr._access_id) {
                fbr._pointer = jump;
                return true;
            }
            return false;
        }
        
        
        
        
    // invertion
    //--------------------------------------------------
        private function _invertAngle(ang:Float) : Float
        {
            if (_invert_flag&(2-CMLObject.vertical) != 0) ang = -ang;
            if (_invert_flag&(1+CMLObject.vertical) != 0) ang = 180-ang;
            return ang;
        }

        
        private function _invertRotation(rot:Float) : Float
        {
            return (_invert_flag==1 || _invert_flag==2) ? -rot : rot;
        }

        
        private function _invertX(x:Float) : Float
        {
            return ((_invert_flag&(2-CMLObject.vertical)) != 0) ? -x : x;
        }
        

        private function _invertY(y:Float) : Float
        {
            return ((_invert_flag&(1+CMLObject.vertical)) != 0) ? -y : y;
        }

        
        

    // creating routine
    //--------------------------------------------------
        // run new fiber
        private function _fiber(fbr:CMLFiber, fiber_id:Int) : Void
        {
            var ref:CMLRefer = cast(next,CMLRefer);                                                 // next statement is referential sequence
            var seq:CMLSequence  = (ref.jump != null) ? cast(ref.jump,CMLSequence) : (fbr.seqExec);      // executing sequence
            fbr._newChildFiber(seq, fiber_id, _invert_flag, ref._args, (seq.type==ST_NO_LABEL));    // create and initialize fiber
            fbr.seqExec = seq;                                                                      // update executing sequence
            fbr._pointer = ref;                                                                     // skip next statement
        }
        

        // run new destruction fiber
        private function _fiber_destruction(fbr:CMLFiber, destStatus:Int) : Void
        {
            var ref:CMLRefer = cast(next,CMLRefer);                                                 // next statement is referential sequence
            var seq:CMLSequence = (ref.jump != null) ? cast(ref.jump,CMLSequence) : (fbr.seqExec);       // executing sequence
            fbr._newDestFiber(seq, destStatus, _invert_flag, ref._args);                            // create and initialize destruction fiber
            fbr.seqExec = seq;                                                                      // update executing sequence
            fbr._pointer = ref;                                                                     // skip next statement
        }


        // run new fiber on child object
        private function _fiber_child(fbr:CMLFiber, obj:CMLObject, object_id:Array<Dynamic>) : Void
        {
            var ref:CMLRefer = cast(next,CMLRefer);                                             // next statement is referential sequence
            var seq:CMLSequence = (ref.jump != null) ? cast(ref.jump,CMLSequence) : (fbr.seqExec);   // executing sequence
            var idxmax:Int = object_id.length-1;
            
            // ('A`) chaos...
            function _reflective_fiber_creation(_parent:CMLObject, _idx:Int) : Void {

                function __nof(obj:CMLObject):Bool {
                    fbr._newObjectFiber(obj, seq, _invert_flag, ref._args);
                    return false;
                }
                
                function __rfc(obj:CMLObject):Bool {
                    _reflective_fiber_creation(obj, _idx+1);
                    return false;
                }

                _parent.findAllChildren(object_id[_idx], (_idx == idxmax) ? __nof : __rfc);
            }

            _reflective_fiber_creation(obj, 0);                                                 // find child by object_id and create new fiber
            
            fbr.seqExec = seq;                                                                  // update executing sequence
            fbr._pointer = ref;                                                                 // skip next statement

        }


        // new
        private function _new(fbr:CMLFiber, access_id:Int, isParts:Bool) : Void
        {
            // next statement is referential sequence
            var ref:CMLRefer = cast(next,CMLRefer);
            
            // update new pointer, ref.jump shows executing sequence            
            if (ref.jump != null) fbr.seqNew = cast(ref.jump,CMLSequence);

            // creating center position
            var x:Float = fbr.fx,
                y:Float = fbr.fy;
            // calculate fiber position on absolute coordinate, when it's not relative creation.
            if (!isParts) {
                var sang:Int = sin.index(fbr.object.angleOnStage),
                    cang:Int = sang + sin.cos_shift;
                x = fbr.object.x + sin[cang]*fbr.fx - sin[sang]*fbr.fy;
                y = fbr.object.y + sin[sang]*fbr.fx + sin[cang]*fbr.fy;
            }

            // create object
            var childObject:CMLObject = fbr.object.onNewObject(fbr.seqNew._args);
            if (childObject == null) return;
            childObject._initialize(fbr.object, isParts, access_id, x, y, 0, 0, 0);

            // create fiber
            fbr._newObjectFiber(childObject, fbr.seqNew, _invert_flag, ref._args);

            // skip next statement
            fbr._pointer = ref;
        }

        
        // fire
        private function _fire(fbr:CMLFiber, access_id:Int, isParts:Bool) : Void
        {
            // next statement is referential sequence
            var ref:CMLRefer = cast(next,CMLRefer);
            
            // update fire pointer, ref.jump shows executing sequence
            if (ref.jump != null) fbr.seqFire = cast(ref.jump,CMLSequence);

            // create multi bullet
            _create_multi_bullet(fbr, access_id, isParts, ref._args);

            // skip next statement
            fbr._pointer = ref;
        }

        
        // fire reflective implement
        private function _create_multi_bullet(fbr:CMLFiber, access_id:Int, isParts:Bool, arg:Array<Dynamic>) : Void
        {
            // multipurpose
            var sang:Int, cang:Int;

            // creating center position
            var x:Float = fbr.fx,
                y:Float = fbr.fy;
            // calculate fiber position on absolute coordinate, when it's not relative creation.
            if (!isParts) {
                sang = sin.index(fbr.object.angleOnStage);
                cang = sang + sin.cos_shift;
                x = fbr.object.x + sin[cang]*fbr.fx - sin[sang]*fbr.fy;
                y = fbr.object.y + sin[sang]*fbr.fx + sin[cang]*fbr.fy;
            }

            // calculate angle
            fbr.fang = fbr._getAngle(fbr.fang);

            // create bullets
            if (fbr.barrage.qrtList.isEmpty()) {
                // create single bullet
                __create_bullet(fbr, isParts, access_id, x, y, arg, fbr.fang + fbr.bul.angle, fbr.bul.speed);
            } else {
                // reflexive call
                fbr.bul.next = fbr.barrage.qrtList.head;
                __reflexive_call(fbr.bul, fbr.barrage.qrtList.end, fbr, isParts, access_id, x, y, arg);
            }
        }
    
        private function __reflexive_call(qrt:CMLBarrageElem, end:CMLListElem, fbr:CMLFiber, isParts:Bool,
                                          access_id:Int, x:Float, y:Float, arg:Array<Dynamic>) : Void
        {
            var qrt_next:CMLBarrageElem = cast(qrt.next,CMLBarrageElem);
                
            if (qrt_next.interval == 0) {
                if (qrt_next.next == end) {
                    // create bullet
                    qrt_next.init(qrt);
                    while (!qrt_next.isEnd()) {
                        __create_bullet(fbr, isParts, access_id, x, y, arg, fbr.fang + qrt_next.angle, qrt_next.speed);
                        qrt_next.update();
                    }
                } else {
                    // reflexive call
                    qrt_next.init(qrt);
                    while (!qrt_next.isEnd()) {
                        __reflexive_call(qrt_next, end, fbr, isParts, access_id, x, y, arg);
                        qrt_next.update();
                    }
                }
            } else {
                // create new fiber and initialize
                var childFiber:CMLFiber = fbr._newChildFiber(CMLFiber.seqRapid, 0, _invert_flag, null, false);
                
                // copy bullet setting and bullet multiplyer
                childFiber.bul.copy(qrt_next);
                childFiber.bul.init(qrt);
                var elem:CMLListElem = qrt_next.next;
                while (elem!=end) {
                    childFiber.barrage._appendElementCopyOf(cast(elem,CMLBarrageElem));
                    elem=elem.next;
                }
                
                // copy other parameters
                childFiber.fx = fbr.fx;
                childFiber.fy = fbr.fy;
                childFiber.hopt = fbr.hopt;
                childFiber.hang = (fbr.hopt==CMLFiber.HO_SEQ) ? 0 : fbr.hang;
                childFiber.fang = fbr.fang;
                childFiber.seqFire = fbr.seqFire;
                childFiber.wtm1 = access_id;
                childFiber.wtm2 = isParts?1:0;
            }
        }

        // internal function to create object
        private function __create_bullet(fbr:CMLFiber, isParts:Bool, access_id:Int, x:Float,
                                         y:Float, arg:Array<Dynamic>, a:Float, v:Float) : Void
        {
            var sang:Int;
            var childObject:CMLObject = fbr.object.onFireObject(fbr.seqFire._args);     // create object
            if (childObject == null) return;
            sang = sin.index(a+CMLObject.scrollAngle);                                  // initialize object
            var mvx:Float = sin[sang+sin.cos_shift];
            var mvy:Float = sin[sang];
            childObject._initialize(fbr.object, isParts, access_id, x, y, sin[sang+sin.cos_shift]*v, sin[sang]*v, a);
            fbr._newObjectFiber(childObject, fbr.seqFire, _invert_flag, arg);           // create fiber
        }
}


