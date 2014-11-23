//----------------------------------------------------------------------------------------------------
// Literal class of formula
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------
// Ported to haxe by Brian Gunn (gunnbr@gmail.com) in 2014


package org.si.cml.core;

import org.si.cml.CMLFiber;
import org.si.cml.CMLObject;
import flash.errors.Error;

/** @private */
class CMLFormulaLiteral extends CMLFormulaElem
{
        // Refer from CMLParser._userReferenceRegExp() to sort all reference names.
        static public var defaultReferences:Array<String> = [
            'i', 'r', 'l', 'x', 'y', 'sx', 'sy', 'v', 'vx', 'vy', 'ho', 'td', 'o', 
            'p.x', 'p.y', 'p.sx', 'p.sy', 'p.v', 'p.vx', 'p.vy', 'p.ho', 'p.td', 'p.o', 
            't.x', 't.y', 't.sx', 't.sy', 't.v', 't.vx', 't.vy', 't.ho', 't.td', 't.o'
        ];
        
        // Initialize all statics (call from CMLParser._createCMLRegExp())
        static private var _literal_rex:String = null;
        static public var literal_rex(get,null) : String;
        static public function get_literal_rex() : String {
            if (_literal_rex == null) {
                _literal_rex = "(0x[0-9a-f]{1,8}|\\d+\\.?\\d*|\\$(\\?\\?|\\?|" + CMLParser._userReferenceRegExp + "|)[0-9]?)";
            }
            return _literal_rex;
        }

        public var func:CMLFiber->Float = null;
        public var num: Float   = 0;
        public var name:String   = "";

        public function new()
        {
            super();
            func = ltrl;
        }
        
        public function parseLiteral(opr:String="") : Int
        {
            var ret:Int = 0;

            // Floats
            if (opr.charAt(0) != "$") {
                func = ltrl;
                num = Std.parseFloat(opr);
                return 0;
            }
            
            
            // Variables
            num = Std.parseFloat(opr.charAt(opr.length-1));
            if (Math.isNaN(num)) {
                num = 0;
            } else {
                opr = opr.substr(0, opr.length-1);
            }
            
            
            switch (opr) {
            case "$":
                func = vars;
                ret = Std.int(num);
                if (num == 0) throw new Error('$0 is not available, $[1-9] only.');
                num--;

            case "$?":    func = rand;    
            case "$??":   func = rands;   
            case "$i":    func = refer_i; 
            case "$r":    func = (num==0) ? rank : rankg;
            case "$l":    func = loop; 

            case "$x":    func = posx; 
            case "$y":    func = posy; 
            case "$sx":   func = sgnx; 
            case "$sy":   func = sgny; 
            case "$v":    func = vell; 
            case "$vx":   func = velx; 
            case "$vy":   func = vely; 
            case "$ho":   func = objh; 
            case "$td":   func = dist; 
            case "$o":    func = (num==0) ? cnta : cntc;
            
            case "$p.x":  func = prt_posx; 
            case "$p.y":  func = prt_posy; 
            case "$p.sx": func = prt_sgnx; 
            case "$p.sy": func = prt_sgny; 
            case "$p.v":  func = prt_vell; 
            case "$p.vx": func = prt_velx; 
            case "$p.vy": func = prt_vely; 
            case "$p.ho": func = prt_objh; 
            case "$p.td": func = prt_dist; 
            case "$p.o":  func = (num==0) ? prt_cnta : prt_cntc; 

            case "$t.x":  func = tgt_posx; 
            case "$t.y":  func = tgt_posy; 
            case "$t.sx": func = tgt_sgnx; 
            case "$t.sy": func = tgt_sgny; 
            case "$t.v":  func = tgt_vell; 
            case "$t.vx": func = tgt_velx; 
            case "$t.vy": func = tgt_vely; 
            case "$t.ho": func = tgt_objh; 
            case "$t.td": func = ltrl; num = 0; 
            case "$t.o":  func = (num==0) ? tgt_cnta : tgt_cntc; 

            default:
                func = CMLParser._getUserReference(opr.substr(1));
                if (func == null) throw new Error(opr +" ?");
            }

            
            return ret;
        }


        public override function calc(fbr:CMLFiber) : Float
        {
            return func(fbr);
        }


        private function ltrl(fbr:CMLFiber): Float { return num; }
        
        private function rand(fbr:CMLFiber): Float { return CMLObject.rand(); }
        private function rands(fbr:CMLFiber):Float { return CMLObject.rand()*2-1; }
        private function rank(fbr:CMLFiber): Float { return fbr.object.rank; }
        private function rankg(fbr:CMLFiber):Float { return CMLObject._globalRank[Std.int(num)]; }
        private function vars(fbr:CMLFiber): Float { return fbr.getVeriable(Std.int(num)); }
        private function loop(fbr:CMLFiber): Float { return fbr.getLoopCounter(Std.int(num)); }
        
        private function posx(fbr:CMLFiber): Float { return fbr.object.x; }
        private function posy(fbr:CMLFiber): Float { return fbr.object.y; }
        private function sgnx(fbr:CMLFiber): Float { return (fbr.object.x<0) ? -1 : 1; }
        private function sgny(fbr:CMLFiber): Float { return (fbr.object.y<0) ? -1 : 1; }
        private function velx(fbr:CMLFiber): Float { return fbr.object.vx; }
        private function vely(fbr:CMLFiber): Float { return fbr.object.vy; }
        private function vell(fbr:CMLFiber): Float { return fbr.object.velocity; }
        private function objh(fbr:CMLFiber): Float { return fbr.object.angleOnStage; }
        private function dist(fbr:CMLFiber): Float { return fbr.object.getDistance(fbr.target); }
        private function cnta(fbr:CMLFiber): Float { return fbr.object.countAllIDedChildren(); }
        private function cntc(fbr:CMLFiber): Float { return fbr.object.countIDedChildren(Std.int(num)); }

        private function prt_posx(fbr:CMLFiber): Float { return fbr.object.parent.x; }
        private function prt_posy(fbr:CMLFiber): Float { return fbr.object.parent.y; }
        private function prt_sgnx(fbr:CMLFiber): Float { return (fbr.object.parent.x<0) ? -1 : 1; }
        private function prt_sgny(fbr:CMLFiber): Float { return (fbr.object.parent.y<0) ? -1 : 1; }
        private function prt_velx(fbr:CMLFiber): Float { return fbr.object.parent.vx; }
        private function prt_vely(fbr:CMLFiber): Float { return fbr.object.parent.vy; }
        private function prt_vell(fbr:CMLFiber): Float { return fbr.object.parent.velocity; }
        private function prt_objh(fbr:CMLFiber): Float { return fbr.object.parent.angleOnStage; }
        private function prt_dist(fbr:CMLFiber): Float { return fbr.object.parent.getDistance(fbr.target); }
        private function prt_cnta(fbr:CMLFiber): Float { return fbr.object.parent.countAllIDedChildren(); }
        private function prt_cntc(fbr:CMLFiber): Float { return fbr.object.parent.countIDedChildren(Std.int(num)); }

        private function tgt_posx(fbr:CMLFiber): Float { return fbr.target.x; }
        private function tgt_posy(fbr:CMLFiber): Float { return fbr.target.y; }
        private function tgt_sgnx(fbr:CMLFiber): Float { return (fbr.target.x<0) ? -1 : 1; }
        private function tgt_sgny(fbr:CMLFiber): Float { return (fbr.target.y<0) ? -1 : 1; }
        private function tgt_velx(fbr:CMLFiber): Float { return fbr.target.vx; }
        private function tgt_vely(fbr:CMLFiber): Float { return fbr.target.vy; }
        private function tgt_vell(fbr:CMLFiber): Float { return fbr.target.velocity; }
        private function tgt_objh(fbr:CMLFiber): Float { return fbr.target.angleOnStage; }
        private function tgt_cnta(fbr:CMLFiber): Float { return fbr.target.countAllIDedChildren(); }
        private function tgt_cntc(fbr:CMLFiber): Float { return fbr.target.countIDedChildren(Std.int(num)); }

        private function refer_i(fbr:CMLFiber): Float { return fbr.getInterval(); }
}


