//----------------------------------------------------------------------------------------------------
// CML statement for assign class
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml {
    /** @private */
    internal class CMLAssign extends CMLState
    {
    // variables
    //------------------------------------------------------------
        private  var _index:int = 0;
        internal var max_reference:int = 0;

        static internal var assign_rex:String = "l\\$([1-9r][+\\-*/]?)=";

        
    // functions
    //------------------------------------------------------------
        function CMLAssign(str:String)
        {
            super(ST_NORMAL);
            
            var indexStr:String = str.charAt(0);
            if (indexStr == 'r') {
                _index = -1;
            } else {
                _index = int(indexStr)-1;
                max_reference = _index+1;
            }
            
            if (str.length == 1) {
                func = (_index == -1) ? _asgr:_asg;
            } else {
                var ope:String = (str.charAt(1));
                switch(ope) {
                case '+':   func = (_index == -1) ? _addr:_add;  break;
                case '-':   func = (_index == -1) ? _subr:_sub;  break;
                case '*':   func = (_index == -1) ? _mulr:_mul;  break;
                case '/':   func = (_index == -1) ? _divr:_div;  break;
                default:    throw Error("BUG!! unknown error in assign");
                }
            }
        }


        internal override function _setCommand(cmd:String) : CMLState
        {
            return this;
        }

        
        private function _asgrg(fbr:CMLFiber):Boolean { CMLObject._globalRank[_index]  = _args[0]; return true; }
        private function _addrg(fbr:CMLFiber):Boolean { CMLObject._globalRank[_index] += _args[0]; return true; }
        private function _subrg(fbr:CMLFiber):Boolean { CMLObject._globalRank[_index] -= _args[0]; return true; }
        private function _mulrg(fbr:CMLFiber):Boolean { CMLObject._globalRank[_index] *= _args[0]; return true; }
        private function _divrg(fbr:CMLFiber):Boolean { CMLObject._globalRank[_index] /= _args[0]; return true; }
        
        private function _asgr(fbr:CMLFiber):Boolean { fbr.object.rank  = _args[0]; return true; }
        private function _addr(fbr:CMLFiber):Boolean { fbr.object.rank += _args[0]; return true; }
        private function _subr(fbr:CMLFiber):Boolean { fbr.object.rank -= _args[0]; return true; }
        private function _mulr(fbr:CMLFiber):Boolean { fbr.object.rank *= _args[0]; return true; }
        private function _divr(fbr:CMLFiber):Boolean { fbr.object.rank /= _args[0]; return true; }
        
        private function _asg(fbr:CMLFiber):Boolean { fbr.vars[_index]  = _args[0]; return true; }
        private function _add(fbr:CMLFiber):Boolean { fbr.vars[_index] += _args[0]; return true; }
        private function _sub(fbr:CMLFiber):Boolean { fbr.vars[_index] -= _args[0]; return true; }
        private function _mul(fbr:CMLFiber):Boolean { fbr.vars[_index] *= _args[0]; return true; }
        private function _div(fbr:CMLFiber):Boolean { fbr.vars[_index] /= _args[0]; return true; }
    }
}

