//----------------------------------------------------------------------------------------------------
// CML parser class
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml.core;

using EReg;
using StringTools;
//using Stack;

import org.si.cml.CMLSequence;
import flash.errors.Error;    
import haxe.CallStack;

/** @private */
class CMLParser
{
        
    // variables
    //------------------------------------------------------------
    // user defined reference
    static private var mapUsrDefRef:Map<String, CMLFiber->Float> = new Map<String, CMLFiber->Float>();
    // user defined command
    static private var mapUsrDefCmd:Map<String, CMLUserDefine> = new Map<String, CMLUserDefine>();

        static private var listState:CMLList = new CMLList();       // statement chain
        static private var loopstac :Array<CMLState> = new Array<CMLState>();  // loop stac
        static private var childstac:Array<CMLState> = new Array<CMLState>();  // child cast "{}" stac
        static private var cmdKey :String   = "";                   // current parsing key
        static private var cmdTemp:CMLState = null;                 // current parsing statement
        static private var fmlTemp:CMLFormula = null;               // current parsing formula

        // functor for allocate CMLState instance.
        static private var newCMLState:Void->CMLState = function():CMLState { return new CMLState(); }
        
        

    // constructor
    //------------------------------------------------------------
        // constructor
            public function new()
        {
        }




    // operations
    //------------------------------------------------------------
        // set user define getter
        static public function userReference(name:String, func:CMLFiber->Float) : Void
        {
            mapUsrDefRef[name] = func;
        }


        // set user define setter
        static public function userCommand(name:String, func:CMLFiber->Array<Dynamic>, argc:Int, requireSequence:Bool) : Void
        {
            var target : CMLUserDefine = new CMLUserDefine({func:func, argc:argc, reqseq:requireSequence});
            trace('**** Defining new user command \"$name\".');
            mapUsrDefCmd[name] = target;
        }




    // parsing
    //------------------------------------------------------------
        static public function _parse(seq:CMLSequence, cml_string:String) : Void
        {
            trace('In CMLParser._parse() for string \"$cml_string\"');
            
            // create regular expression
            var regexp:EReg = _createCMLRegExp();
            var res:Array<String> = new Array<String>();
            var i:Int;
            
            // parsing
            try {
                // initialize
                _initialize(seq);
                
                while (regexp.match(cml_string)) {

                    // Convert to the array format expected by all the functions
                    for (i in 0...REX_ERROR) {
                        res.push(regexp.matched(i));
                    }
                    trace('CMLParser: Matched: \"$res\"');
                    
                    //trace(res);
                    if (!_parseFormula(res)) {              // parse formula first
                        _append();                          // append previous formula and statement
                        // check the result of matching
                        if (!_parseStatement(res))          // new normal statement
                        if (!_parseLabelDefine(res))        // labeled sequence definition
                        if (!_parseNonLabelDefine(res))     // non-labeled sequence definition
                        if (!_parsePreviousReference(res))  // previous reference
                        if (!_parseCallSequence(res))       // call sequence
                        if (!_parseAssign(res))             // assign 
                        if (!_parseUserDefined(res))        // user define statement
                        if (!_parseComment(res))            // comment
                        if (!_parseString(res))             // string
                        {
                            // command is not defined
                            // TODO (haxe conversion): Does null work for undefined?
                            if (res[REX_ERROR] != null) {
                                throw new Error(res[REX_ERROR]+" ?");
                            } else {
                                throw new Error("BUG!! unknown error in CMLParser._parse()");
                            }
                        }
                    }
                    
                    // Update the string so we can look for the next match
                    cml_string = regexp.matchedRight();
                    // Reset the matching array
                    res.splice(0,res.length);
                    trace('_parse-next match is \"$cml_string\".');
                }
                trace('CMLParser: Done matching');

                // throw error when stacs are still remain.
                if (loopstac.length  != 0) throw new Error("[[...] ?");
                if (childstac.length != 1) throw new Error("{{...} ?");
                
                _append();     // append last statement
                _terminate();  // terminate the tail of sequence

                seq.verify();  // verification
            }
            catch (err:Error) {
                listState.cut(listState.head, listState.tail);
                seq.clear();
                trace("Exception after matching");
                trace("Stack: " + CallStack.toString(CallStack.exceptionStack()));
                throw err;
            }
        }




    // parsing subroutines
    //------------------------------------------------------------
        static private function _initialize(seq_:CMLSequence) : Void
        {
            listState.clear();
            listState.push(seq_);
            loopstac.splice(0, loopstac.length);
            childstac.splice(0, childstac.length);
            childstac.unshift(seq_);
            cmdKey = "";
            cmdTemp = null;
            fmlTemp = null;
        }


        static private function _append() : Void
        {
            // append previous statement and formula
            if (cmdTemp != null) {
                _append_formula(fmlTemp);
                _append_statement(cmdTemp.setCommand(cmdKey));
                fmlTemp = null;
            }
            // reset
            cmdKey = "";
            cmdTemp = null;
        }


        static private function _terminate() : Void
        {
            var terminator:CMLState = new CMLState(CMLState.ST_END);
            _append_statement(terminator);
            listState.cut(listState.head, listState.tail);
        }
            
        
        static private function _parseFormula(res:Array<String>) : Bool
        {
            var form:String = res[REX_FORMULA];
            trace('In _parseFormula for \"$form\" with cmdTemp \"$cmdTemp\".');
            if (res[REX_FORMULA] == null) return false;
            trace("We have a formula!");
            // formula, argument, ","
            if (cmdTemp == null) throw new Error("in formula " + res[REX_FORMULA]);
            if (res[REX_FORMULA] == ",") {
                _append_formula(fmlTemp);                       // append old formula
                fmlTemp = _check_argument(cmdTemp, res, true);  // push new argument
            } else { // + - * / % ( )
                if (fmlTemp == null) fmlTemp = new CMLFormula(cmdTemp, true);   // new formula
                if (!fmlTemp.pushOperator(res[REX_FORMULA], false)) throw new Error("in formula " + res[1]);
                fmlTemp.pushPrefix (res[REX_ARG_PREFIX], true);
                fmlTemp.pushLiteral(res[REX_ARG_LITERAL]);
                fmlTemp.pushPostfix(res[REX_ARG_POSTFIX], true);
            }
            return true;
        }
    
        static private function _parseStatement(res:Array<String>) : Bool
        {
            if (res[REX_NORMAL] == null) return false;
            
            cmdKey = res[REX_NORMAL];           // command key
            cmdTemp = newCMLState();            // new command
            trace('in _parseStatement: cmdKey: $cmdKey cmdTemp: $cmdTemp');
            
            // individual operations
            switch (cmdKey) {
            case "[": 
                loopstac.push(cmdTemp);         // push loop stac
            case "[?":
                loopstac.push(cmdTemp);         // push loop stac
            case "[s?":
                loopstac.push(cmdTemp);         // push loop stac
            case ":":
                cmdTemp.jump = loopstac.pop();  // pop loop stac
                cmdTemp.jump.jump = cmdTemp;    // create jump chain
                loopstac.push(cmdTemp);         // push new loop stac
            case "]":
                if (loopstac.length == 0) throw new Error("[...]] ?");
                cmdTemp.jump = loopstac.pop();  // pop loop stac
                cmdTemp.jump.jump = cmdTemp;    // create jump chain
            case "}":
                if (childstac.length <= 1) throw new Error("{...}} ?");
                _append_statement(cmdTemp.setCommand(cmdKey));
                var seq:CMLState = _cut_sequence(childstac.shift(), cmdTemp);
                cmdKey = "";
                // non-labeled sequence is exchenged into reference
                cmdTemp = (seq.type == CMLState.ST_NO_LABEL) ? _new_reference(seq, null) : null;
            }

            // push new argument
            if (cmdTemp != null) {
                fmlTemp = _check_argument(cmdTemp, res);
            }
        
            return true;
        }

        static private function _parseLabelDefine(res:Array<String>) : Bool
        {
            if (res[REX_LABELDEF] == null) return false;
            trace("*** Found a label define: \""+res[REX_LABELDEF]+"\".");
            cmdTemp = _new_sequence(cast(childstac[0],CMLSequence), res[REX_LABELDEF]);   // new sequence with label
            fmlTemp = _check_argument(cmdTemp, res);                    // push new argument
            childstac.unshift(cmdTemp);                                 // push child stac
            return true;
        }

        static private function _parseNonLabelDefine(res:Array<String>) : Bool
        {
            if (res[REX_NONLABELDEF] == null) return false;
            cmdTemp = _new_sequence(cast(childstac[0],CMLSequence), null);        // new sequence without label
            fmlTemp = _check_argument(cmdTemp, res);            // push new argument
            childstac.unshift(cmdTemp);                         // push child stac
            return true;
        }

        static private function _parsePreviousReference(res:Array<String>) : Bool
        {
            if (res[REX_PREVREFER] == null) return false;
            cmdTemp = _new_reference(null, null);               // new reference command
            fmlTemp = _check_argument(cmdTemp, res);            // push new argument
            return true;
        }

        static private function _parseCallSequence(res:Array<String>) : Bool
        {
            if (res[REX_CALLSEQ] == null) return false;
            cmdTemp = _new_reference(null, res[REX_CALLSEQ]);   // new reference command
            fmlTemp = _check_argument(cmdTemp, res);            // push new argument
            return true;
        }
    
        static private function _parseAssign(res:Array<String>) : Bool
        {
            if (res[REX_ASSIGN] == null) return false;
            cmdTemp = _new_assign(res[REX_ASSIGN]);             // new command
            fmlTemp = _check_argument(cmdTemp, res);            // push new argument
            return true;
        }

        static private function _parseUserDefined(res:Array<String>) : Bool
        {
            if (res[REX_USERDEF] == null) return false;
            trace("**** Pushing new user defined: \"" + res[REX_USERDEF] + "\"");
            cmdTemp = _new_user_defined(res[REX_USERDEF]);      // new command
            fmlTemp = _check_argument(cmdTemp, res);            // push new arguments
            return true;
        }

        static private function _parseString(res:Array<String>) : Bool
        {
            if (res[REX_STRING] == null) return false;
            cmdTemp = new CMLString(res[REX_STRING]);       // new string
            return true;
        }

        static private function _parseComment(res:Array<String>) : Bool
        {
            if (res[REX_COMMENT] == null) return false;
            return true;
        }



    // private functions
    //------------------------------------------------------------
        // regular expression indexes
        static private inline var REX_COMMENT:Int     = 1;  // comment
        static private inline var REX_STRING:Int      = 2;  // string
        static private inline var REX_FORMULA:Int     = 5;  // formula and arguments
        static private inline var REX_USERDEF:Int     = 6;  // user define commands
        static private inline var REX_NORMAL:Int      = 7;  // normal commands
        static private inline var REX_ASSIGN:Int      = 8;  // assign
        static private inline var REX_CALLSEQ:Int     = 9;  // call sequence
        static private inline var REX_PREVREFER:Int   = 10; // previous reference
        static private inline var REX_LABELDEF:Int    = 11; // labeled sequence definition
        static private inline var REX_NONLABELDEF:Int = 12; // non-labeled sequence definition
        static private inline var REX_ARG_PREFIX:Int  = 13; // argument prefix
        static private inline var REX_ARG_LITERAL:Int = 15; // argument literal
        static private inline var REX_ARG_POSTFIX:Int = 17; // argument postfix
        static private inline var REX_ERROR:Int       = 19; // error
    
        static private var _regexp:EReg = null;             // regular expression
    
    
        // create regular expression once
        static private function _createCMLRegExp() : EReg
        {
            if (_regexp == null) {
                var rexstr:String = "(//[^\\n]*$|/\\*.*?\\*/)";     // comment (res[1])
                rexstr += "|'(.*?)'";                               // string (res[2])
                rexstr += "|((";                                    // ---all--- (res[3,4])
                rexstr += "(,|\\+|-|\\*|/|%|==|!=|>=|<=|>|<)";      // formula and arguments (res[5])
                rexstr += "|&(" + _userCommandRegExp + ")";         // user defined commands (res[6])
                rexstr += "|" + CMLState.command_rex;               // normal commands (res[7])
                rexstr += "|" + CMLAssign.assign_rex;               // assign (res[8])
                rexstr += "|([A-Z_.][A-Z0-9_.]*)";                  // call sequence (res[9])
                rexstr += "|(\\{\\.\\})";                           // previous reference (res[10])
                rexstr += "|#([A-Z_][A-Z0-9_]*)[ \t]*\\{";          // labeled sequence definition (res[11])
                rexstr += "|(\\{)";                                 // non-labeled sequence definition (res[12])
                rexstr += ")[ \t]*" + CMLFormula.operand_rex + ")"; // argument(res[13,14];prefix, res[15,16];literal, res[17,18];postfix)
                rexstr += "|([a-z]+)";                              // error (res[19])
                _regexp = new EReg(rexstr, "gms");

                // NOTE: CMLFormula.operand_rex is a property and it initializes CMLFormula.
            }

            // TODO (haxe conversion): Is this needed?
            //_regexp.lastIndex = 0;
            return _regexp;
        }
                
        
        // append new command
        static private function _append_statement(state:CMLState) : Void
        {
            listState.push(state);
        }

        
        // append new formula
        static private function _append_formula(fml:CMLFormula) : Void
        {
            if (fml != null) {
                if (!fml.construct()) throw new Error("in formula");
                listState.push(fml);
                _update_max_reference(fml.max_reference);
            }
        }


        // cut sequence from the list
        static private function _cut_sequence(start:CMLState, end:CMLState) : CMLState
        {
            listState.cut(start, end);
            end.jump = start;
            return start;
        }
        
        
        // create new sequence
        static private function _new_sequence(parent:CMLSequence, label:String) : CMLSequence
        {
            return parent.newChildSequence(label);
        }
                
        
        // create new reference
        // (null,   null) means previous call "{.}"
        // (define, null) means non-labeled call "{...}"
        // (null, define) means label call "ABC"
        static private function _new_reference(seq:CMLState, name:String) : CMLState
        {   
            // append "@" command, when previous command isn't STF_CALLREF.
            if ((cast(listState.tail,CMLState).type & CMLState.STF_CALLREF) == 0) {
                _append_statement((new CMLState()).setCommand("@"));
            }
            // create reference
            return new CMLRefer(seq, name);
        }

        
        // create new user defined command
        static private function _new_user_defined(str:String) : CMLUserDefine
        {
            if (mapUsrDefCmd[str] == null) throw new Error("&"+str+" ? (not defined)");  // not defined
            return mapUsrDefCmd[str];
        }
        
                
        // create new assign command
        static private function _new_assign(str:String) : CMLAssign
        {
            var asg:CMLAssign = new CMLAssign(str);
            _update_max_reference(asg.max_reference);
            return asg;
        }
        

        // check and update max reference of sequence
        static private function _update_max_reference(max_reference:Int) : Void
        {
            if (cast(childstac[0],CMLSequence).require_argc < max_reference) {
                cast(childstac[0],CMLSequence).require_argc = max_reference;
            }
        }
        

        // set arguments 
        static private function _check_argument(state:CMLState, res:Array<String>, isComma:Bool=false) : CMLFormula
        {
            var prefix:String  = res[REX_ARG_PREFIX];
            var literal:String = res[REX_ARG_LITERAL];
            var postfix:String = res[REX_ARG_POSTFIX];
            
            trace('CMLParser: _check_argument: prefix \"$prefix\" literal \"$literal\" postfix \"$postfix\"');
            
            // push 0 before ","
            if (isComma && state._args.length==0) state._args.push(Math.NaN);

            // push argument
            var fml:CMLFormula = null;
            if (literal != null) {
                // set number when this argument is constant value
                if (literal.charAt(0) != "$") {
                    if (postfix == null) {
                        if      (prefix == null) { state._args.push(Std.parseFloat(literal));    return null; } 
                        else if (prefix == "-")  { state._args.push(-(Std.parseFloat(literal))); return null; }
                    } else 
                    if (postfix == ")") {
                        if      (prefix == "(")  { state._args.push(Std.parseFloat(literal));    return null; }
                        else if (prefix == "-(") { state._args.push(-(Std.parseFloat(literal))); return null; }
                    }
                }
                
                // set formula when this argument is variable
                state._args.push(0);
                fml = new CMLFormula(state, false);
                fml.pushPrefix (prefix, true);
                fml.pushLiteral(literal);
                fml.pushPostfix(postfix, true);
            } else {
                // push NaN when there are no arguments in "," command
                if (isComma) state._args.push(Math.NaN);
            }
            
            trace('CMLParser: check_argument: returning $fml');
            return fml;
        }

        static private function strSort(a:String, b:String):Int
        {
            a = a.toLowerCase();
            b = b.toLowerCase();
            
            if (a < b) return -1;
            if (a > b) return 1;
            return 0;
        }
    
        // regular expression string of user command. call from _createCMLRegExp()
        static private var _userCommandRegExp(get,null) : String;
        static private function get__userCommandRegExp() : String
        {
            var cmdlist:Array<String> = new Array<String>();
            var cmd:String;
            trace("*** Getting user command: " + mapUsrDefCmd);
            for (cmd in mapUsrDefCmd.keys()) { cmdlist.push(cmd); }
            cmdlist.sort(strSort);
            return cmdlist.join('|');
        }


        // regular expression string of user command. call from CMLFormula
        static public var _userReferenceRegExp(get,null):String;
        static public function get__userReferenceRegExp() : String
        {
            var reflist:Array<String> = new Array<String>();
            var ref:String;
            for (ref in mapUsrDefRef.keys()) {
                reflist.push(ref);
            }
            reflist=reflist.concat(CMLFormulaLiteral.defaultReferences);
            reflist.sort(strSort);
            ref = reflist.join('|');
            var search:String = "\\.";
            trace('*** userReference string: $ref');
            return StringTools.replace(ref, search,  '\\\\.');
        }


        // call from CMLFormula
        static public function _getUserReference(name:String) : CMLFiber->Float
        {
            return mapUsrDefRef[name];
        }
    }




