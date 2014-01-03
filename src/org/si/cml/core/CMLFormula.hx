//----------------------------------------------------------------------------------------------------
// CML statement class for formula
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml.core;
//package org.si.cml;

import org.si.cml.CMLFiber;
    
    
/** @private statemant for formula calculation */
class CMLFormula extends CMLState
{
        
        
    // variables
    //------------------------------------------------------------
        private  var _arg_index:Int = 0;
        private  var _form:CMLFormulaElem = null;
        public var max_reference:Int = 0;
        static private var stacOperator:Array<CMLFormulaElem> = new Array<CMLFormulaElem>();
        static private var stacOperand :Array<CMLFormulaElem> = new Array<CMLFormulaElem>();

        static private  var _prefixRegExp :EReg; 
        static private  var _postfixRegExp:EReg; 
        static private  var _operand_rex:String = null;
       
        // Initialize all statics (call from CMLParser._createCMLRegExp())
        static public var operand_rex(get,null) : String;
        static public function get_operand_rex() : String {
            if (_operand_rex == null) {
                _operand_rex  = "(" + CMLFormulaOperator.prefix_rex + "+)?";
                _operand_rex += CMLFormulaLiteral.literal_rex + "?";
                _operand_rex += "(" + CMLFormulaOperator.postfix_rex + "+)?";
                _prefixRegExp  = new EReg(CMLFormulaOperator.prefix_rex, 'g');
                _postfixRegExp = new EReg(CMLFormulaOperator.postfix_rex, 'g');
                // NOTE: CMLFormulaLiteral.literal_rex is a property.
            }
            return _operand_rex;
        }
        
        
        
        
    // functions
    //------------------------------------------------------------
        public function new(state:CMLState, pnfa:Bool)
        {
            super(CMLState.ST_FORMULA);
            
            jump = state;
            func = _calc;
            _arg_index = state._args.length - 1;
            stacOperator.splice(stacOperator.length, 0);
            max_reference = 0;
            
            // Pickup Number From Argument ?
            if (pnfa) {
                stacOperand.splice(stacOperand.length,0);
                stacOperand.push(new CMLFormulaLiteral());
                cast(stacOperand[0],CMLFormulaLiteral).num = state._args[_arg_index];
            } else {
                stacOperand.splice(stacOperand.length, 0);
            }
        }

        
        override public function _setCommand(cmd:String) : CMLState
        {
            return this;
        }


        
        
    // function to create formula structure
    //------------------------------------------------------------
        // push operator stac
        public function pushOperator(operator:Dynamic, isSingle:Bool) : Bool
        {
            if (operator == null) return false;
            var ope:CMLFormulaOperator = new CMLFormulaOperator(operator, isSingle);
            while (stacOperator.length > 0 && cast(stacOperator[0],CMLFormulaOperator).priorL > ope.priorR) {
                var oprcnt:Int = cast(stacOperator[0],CMLFormulaOperator).oprcnt;
                if (stacOperand.length < oprcnt) return false;
                cast(stacOperator[0],CMLFormulaOperator).opr1 = (oprcnt > 1) ? (stacOperand.shift()) : (null);
                cast(stacOperator[0],CMLFormulaOperator).opr0 = (oprcnt > 0) ? (stacOperand.shift()) : (null);
                stacOperand.unshift(stacOperator.shift());
            }
            
            // closed by ()
            if (stacOperator.length>0 && cast(stacOperator[0],CMLFormulaOperator).priorL==1 && ope.priorR==1) stacOperator.shift();
            else stacOperator.unshift(ope);
            return true;
        }
        
        
        // push operand stac
        public function pushLiteral(literal:Dynamic) : Void
        {
            if (literal == null) return;
            var lit:CMLFormulaLiteral = new CMLFormulaLiteral();
            var ret:Int = lit.parseLiteral(literal);
            if (max_reference < ret) max_reference = ret;
            stacOperand.unshift(lit);
        }

        
        // push prefix
        public function pushPrefix(prefix:Dynamic, isSingle:Bool) : Bool
        {
            return (prefix != null) ? _parse_and_push(_prefixRegExp, prefix, isSingle) : true;
        }

        
        // push postfix
        public function pushPostfix(postfix:Dynamic, isSingle:Bool) : Bool
        {
            return (postfix != null) ? _parse_and_push(_postfixRegExp, postfix, isSingle) : true;
        }
        
        
        // call from pushPostfix and pushPrefix.
        private function _parse_and_push(rex:EReg, str:String, isSingle:Bool) : Bool
        {
            // TODO (haxe conversion): Is this needed?
            //rex.lastIndex = 0;
            var res:String;
            while (rex.match(str)) {
                res = rex.matched(1);
                if (!pushOperator(res, isSingle)) return false;
                str = rex.matchedRight();
            }
            return true;
        }

        
        // construct formula structure
        public function construct() : Bool
        {
            while (stacOperator.length > 0) {
                var oprcnt:Int = cast(stacOperator[0],CMLFormulaOperator).oprcnt;
                if (stacOperand.length < oprcnt) return false;
                cast(stacOperator[0],CMLFormulaOperator).opr1 = (oprcnt > 1) ? (stacOperand.shift()) : (null);
                cast(stacOperator[0],CMLFormulaOperator).opr0 = (oprcnt > 0) ? (stacOperand.shift()) : (null);
                stacOperand.unshift(stacOperator.shift());
            }
            if (stacOperand.length==1) _form=stacOperand.shift();
            return (_form != null);
        }

        
        

    // calculation
    //------------------------------------------------------------
        private function _calc(fbr:CMLFiber) : Bool
        {
            jump._args[_arg_index] = _form.calc(fbr);
            return true;
        }
}



