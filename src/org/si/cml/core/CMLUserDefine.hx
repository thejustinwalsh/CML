//--------------------------------------------------
// CML statement class for user defined function
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------
// Ported to haxe by Brian Gunn (gunnbr@gmail.com) in 2014


package org.si.cml.core;

import org.si.cml.CMLFiber;

/** @private */
class CMLUserDefine extends CMLState
{
    // variables
    //------------------------------------------------------------
        private var _funcUserDefine:CMLFiber->Array<Dynamic>->Void;
        private var _argumentCount:Int;
        private var _requireSequence:Bool;


    // functions
    //------------------------------------------------------------
        public function new(obj:Dynamic)
        {
            super(CMLState.ST_NORMAL);
            _funcUserDefine  = obj.func;
            _argumentCount   = obj.argc;
            _requireSequence = obj.reqseq;
            if (_requireSequence) type = CMLState.ST_RESTRICT | CMLState.STF_CALLREF;
            func = _call;
        }


        public override function _setCommand(cmd:String) : CMLState
        {
            _resetParameters(_argumentCount);
            return this;
        }


        private function _call(fbr:CMLFiber): Bool
        {
            _funcUserDefine(fbr, _args);
            return true;
        }
}


