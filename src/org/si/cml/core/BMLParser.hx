//----------------------------------------------------------------------------------------------------
// Translator from BulletML to CannonML
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml.core;

import org.si.cml.CMLSequence;
import flash.utils.*;
import flash.errors.Error;    

using StringTools;

class Seqinfo
{
    public var bseq:String = "nws";
    public var bv:String = "0";
    public function new() {}
}

/** You can use the XML object of BulletML in CMLSequence constructor directly, So this class is only for a translation purpose.
 *  @example
<listing version="3.0">
    // Create CMLSequence from bulletML directly.
    var seq:CMLSequence = new CMLSequence(cast(bulletML,Xml));
    
    // You can refer the translation result of bulletML if you need.
    trace(BMLParser.cmlString);
    
     ...
    
    // "enemy" is an instance of CMLObject. You can execute bulletML from CMLObject.execute().
    enemy.execute(seq);
</listing>
 *  @see CMLSequence#CMLSequence()
 *  @see BMLParser#cmlString
 */
class BMLParser
{
        /** The namespace of bulletML, xmlnx='http://www.asahi-net.or.jp/~cs8k-cyu/bulletml'. */
    //static public var bulletMLNameSpace:Namespace = new Namespace("http://www.asahi-net.or.jp/~cs8k-cyu/bulletml");

        
        /** @private */
        function new()
        {
        }
        
        
        // Parse BulletML, and create sequence.
        /** @private */
        static public function _parse(seq:CMLSequence, bulletML:Xml) : Void
        {
            CMLParser._parse(seq, translate(bulletML));
        }
        
        
        /** Translate BulletML to CannonML. 
        * @param  bulletML XML of BulletML
        * @return cannonML string. Returns "" when there are no <bulletml>s in XML.
        */
        static public function translate(bulletML:Xml) : String
        {
            // XML parsing rules
            // TODO (haxe conversion): None of these exist in haxe Xml. Are they
            // necessary? Do we need to find another workaround?
            //Xml.ignoreComments = true;
            //Xml.ignoreProcessingInstructions = true;
            //Xml.ignoreWhitespace = true;
            
            // bulletML default namespace
            // TODO (haxe conversion): Fix the next line!!
            //default xml namespace = bulletMLNameSpace;

            // pick up <bulletml>
            // TODO (haxe conversion): Is bulletML.firstElement() appropriate instead of bulletML.bulletml[0]?
            var xml:Xml = (bulletML.nodeName == 'bulletml') ? bulletML : bulletML.firstElement();

            // start parsing
            _cml = "";
            _cmlStac.splice(_cmlStac.length, 0);
            _label.splice(_label.length, 0);
            _pushStac();
            if (!bulletml(xml)) return "";
            _flush();
            _popStac();
            
            return _cml;
        }
        

        /** CannonML string after translate() and constructor of CMLSequence. 
         *  You can pick up the cml string after "new CMLSequence(bulletML as XML)".
         */
        static public var cmlString(get,null):String;
        static public function get_cmlString() : String
        {
            return _cml;
        }


        /** Errored XML. Returns null when there are no error. */
        static public var erroredXML(get,null) : Xml;
        static public function get_erroredXML() : Xml
        {
            return _erroredXML;
        }
        
        


    // errors
    //--------------------------------------------------
        static private function _errorElement(xml:Xml, elem:String) : Error
        {
            _erroredXML = xml;
            return new Error("<"+elem+"> in <"+xml.nodeName+">");
        }

        
        static private function _errorNoElement(xml:Xml, elem:String) : Error
        {
            _erroredXML = xml;
            return new Error("no <"+elem+"> in <"+xml.nodeName+">");
        }
        
        
        static private function _errorAttribute(xml:Xml, attr:String, err:String) : Error
        {
            _erroredXML = xml;
            return new Error("attribute:"+attr+" cannot be "+err);
        }

        
        static private function _errorNoAttribute(xml:Xml, attr:String) : Error
        {
            _erroredXML = xml;
            return new Error("no attribute:"+attr+" in <"+xml.nodeName+">");
        }

        
        static private function _errorSimpleOnly(xml:Xml) : Error
        {
            _erroredXML = xml;
            return new Error("<"+xml.nodeName+"> has simple content only.");
        }
        
        
        static private function _errorHasOnlyOne(xml:Xml, only:String) : Error
        {
            _erroredXML = xml;
            return new Error("<"+xml.nodeName+"> must have only one <"+only+"> in it.");
        }

    // bulletML elements with complex contents
    //--------------------------------------------------
        static private var _cml:String = "";
        static private var _cmlStac:Array<String> = new Array<String>();
        static private var _seqStac:Array<Seqinfo> = new Array<Seqinfo>();
        static private var _label:Array<String>   = new Array<String>();
        static private var _erroredXML:Xml = null;
        
        
        static private function bulletml(xml:Xml, defaultFunc:Function=null) : Bool
        {
            if (xml.nodeName != "bulletml") return false;
            
            var type:String = xml.get("type");
            var elem:Xml;
            for (elem in xml.iterator()) {
                if (!action(elem, false))
                    if (!fire(elem, false))
                        if (!bullet(elem, false)) 
                        {
                            // parse other elements here
                            if (defaultFunc != null) {
                                if (!defaultFunc(elem)) throw _errorElement(xml, elem.nodeName);
                            }
                        }
            }
            
            return true;
        }
        
        
        static private function action(xml:Xml, reference:Bool=true) : Bool
        {
            if (xml.nodeName != "action") return false;
            
            // get parameters
            var lbl:String = _getLabel(xml, false);
            // parse contents
            _pushStac();

            // TODO (haxe conversion): Maybe there's a way to make this work
            //_parseContentsSequencial(xml, fire, fireRef, action, actionRef, repeat, changeDirection, changeSpeed, accel, wait, vanish);
            if (!fire(xml))
                if (!fireRef(xml))
                    if (!action(xml))
                        if (!actionRef(xml))
                            if (!repeat(xml))
                                if (!changeDirection(xml))
                                    if (!changeSpeed(xml))
                                        if (!accel(xml))
                                            if (!wait(xml))
                                                vanish(xml);
            var seq:String = _popStac();

            // write
            if (lbl!=null) {
                _pushStac();
                _write("#"+lbl+"{ "+seq+"}");
                _flush();
                _popStac();
                if (reference) {
                    _write("&"+lbl+_cmlArgumentProp(seq));
                    _seqStac[0].bseq = "nws";
                    _seqStac[0].bv   = "nws";
               }
            } else {
                _write_ns(seq);
            }
            
            return true;
        }
        
        
        static private function fire(xml:Xml, reference:Bool=true) : Bool
        {
            if (xml.nodeName != "fire") return false;

            // check contents
            var len:Int = 0;
            var children:Xml;
            for (child in xml.elements()) {
                if ((child.nodeName == "bullet") || (child.nodeName == "bulletRef")) {
                    len++;
                }
            }
            
            if (len == 0) throw _errorNoElement(xml, "bullet|bulletRef");
            if (len > 1)  throw _errorHasOnlyOne(xml, "bullet|bulletRef");
            
            
            // get parameters
            var lbl:String = _getLabel(xml, false);
            var dir:String = _getDirection(xml);
            var spd:String = _getSpeed(xml);

            // parse contents
            _pushStac();
            _write((dir!=null)?dir:"ha");
            _write((spd!=null)?spd:"f1");
            // TODO (haxe conversion): find a way to make this work)
            //_parseContentsSequencial(xml, bullet, bulletRef, skipDirSpd);
            if (!bullet(xml))
                if (!bulletRef(xml))
                    skipDirSpd(xml);
            
            var seq:String = _popStac();
            
            // write
            if (lbl!=null) {
                _pushStac();
                _write("#"+lbl+"{ "+seq+"}");
                _flush();
                _popStac();
                if (reference) {
                    _write("&"+lbl+_cmlArgumentProp(seq));
                    _seqStac[0].bseq = "nws";
                    _seqStac[0].bv   = "nws";
                }
            } else {
                _write_ns(seq);
            }

            return true;
        }
        
        
        static private function bullet(xml:Xml, reference:Bool=true) : Bool
        {
            if (xml.nodeName != "bullet") return false;
            
            // get parameters
            var lbl:String = _getLabel(xml, false);
            var dir:String = _getDirection(xml);
            var spd:String = _getSpeed(xml);
            
            // parse contents
            _pushStac();
            if (dir!=null) _write(dir + " cd");
            if (spd!=null) _write(spd);
            // TODO (haxe conversion): find a way to make this work)
            //_parseContentsSequencial(xml, action, actionRef, skipDirSpd);
            if (!action(xml))
                if (!actionRef(xml))
                    skipDirSpd(xml);
            
            var seq:String = _popStac();
            
            // write
            if (lbl!=null) {
                _pushStac();
                _write("#"+lbl+"{ "+seq+"}");
                _flush();
                _popStac();
                if (reference) _write(lbl+_cmlArgumentProp(seq));
            } else {
                if (reference) {
                    if (_seqStac[0].bseq != seq) {
                        _write("{ "+seq+"}"+_cmlArgumentProp(seq));
                        _seqStac[0].bseq = seq;
                    }
                }
            }
            
            return true;
        }

        
        static private function skipDirSpd(xml:Xml) : Bool
        {
            var str:String = xml.nodeName;
            return (str == "direction" || str == "speed");
        }
        
        
        static private function changeDirection(xml:Xml) : Bool
        {
            if (xml.nodeName != "changeDirection") return false;
            var dir:String = _getDirection(xml);
            if (dir==null) throw _errorNoElement(xml, "direction");
            _write(dir);
            _write("i"+_getTerm(xml));
            _write("cd");
            return true;
        }


        static private function changeSpeed(xml:Xml) : Bool
        {
            if (xml.nodeName != "changeSpeed") return false;
            var spd:String = _getSpeed(xml);
            if (spd==null) throw _errorNoElement(xml, "speed");
            _write("i"+_getTerm(xml));
            _write(spd);
            return true;
        }


        static private function accel(xml:Xml) : Bool
        {
            if (xml.nodeName != "accel") return false;
            // (TODO haxe): _write("i"+_getTerm(xml));
            // (TODO haxe): _write(_typeStringH[_getType(xml.vertical[0], TYPE_ABSOLUTE)]);
            // (TODO haxe): _write_ns("ad");
            // (TODO haxe): _write_ns((xml.horizontal != null) ? _cmlArgument(xml.horizontal[0]) : "0");
            // (TODO haxe): _write_ns(",");
            // (TODO haxe): _write((xml.vertical != null) ? _cmlArgument(xml.vertical[0]) : "0");
            return true;
        }

        
        static private function repeat(xml:Xml) : Bool
        {
            if (xml.nodeName != "repeat") return false;
            var times:String = _getTimes(xml);
            if (times != "1") _write("["+times);
            // (TODO haxe): var len:Int = xml.action.length() + xml.actionRef.length();
            // (TODO haxe): if (len == 0) throw _errorNoElement(xml, "action|actionRef");
            // (TODO haxe): if (len > 1 || xml.children.length() > 2) throw _errorHasOnlyOne(xml, "action|actionRef");
            // (TODO haxe): if (xml.action.length()==1) action(xml.action[0]);
            // (TODO haxe): else if (xml.actionRef.length()==1) actionRef(xml.actionRef[0]);
            // (TODO haxe): if (times != "1") _write("]");
            return true;
        }


        static private function vanish(xml:Xml) : Bool
        {
            if (xml.nodeName != "vanish") return false;
            _write("ko");
            return true;
        }


        static private function wait(xml:Xml) : Bool
        {
            if (xml.nodeName != "wait") return false;
            // (TODO haxe): var frame:String = _cmlArgument(xml.text()[0]);
            // (TODO haxe): if (frame != "0") _write("w"+frame);
            return true;
        }


        static private function bulletRef(xml:Xml) : Bool
        {
            if (xml.nodeName != "bulletRef") return false;
            var lbl:String = _getLabel(xml, true);
            _write(lbl);
            _write(_getParam(xml));
            return true;
        }

        
        static private function actionRef(xml:Xml) : Bool
        {
            if (xml.nodeName != "actionRef") return false;
            var lbl:String = _getLabel(xml, true);
            _write("&"+lbl);
            _write(_getParam(xml));
            _seqStac[0].bseq = "nws";
            _seqStac[0].bv   = "nws";
            return true;
        }

        
        static private function fireRef(xml:Xml) : Bool
        {
            if (xml.nodeName != "fireRef") return false;
            var lbl:String = _getLabel(xml, true);
            _write("&"+lbl);
            _write(_getParam(xml));
            _seqStac[0].bseq = "nws";
            _seqStac[0].bv   = "nws";
            return true;
        }




    // bulletML elements with single content
    //--------------------------------------------------
        static private inline var TYPE_NULL:Int = -1;
        static private inline var TYPE_AIM:Int      = 0;
        static private inline var TYPE_ABSOLUTE:Int = 1;
        static private inline var TYPE_RELATIVE:Int = 2;
        static private inline var TYPE_SEQUENCE:Int = 3;
        static private var _typeString:Array<String>   = ["aim", "absolute", "relative", "sequence"];
        static private var _typeStringH:Array<String>  = ["ht",  "ha",       "ho",       "hs"];
        static private var _typeStringCS:Array<String> = ["",    "csa",      "csr",      "css"];
            
        static private function _getDirection(xml:Xml) : String
        {
            var direction:Xml = null;
            for (child in xml.elements()) {
                if (child.nodeName == "direction") {
                    direction = child;
                    break;
                }
            }
                
            if (direction == null) return null;
            
            var type:Int = _getType(direction, TYPE_AIM);
            var arg:String = _cmlArgument(direction.firstChild());
            if (type == TYPE_ABSOLUTE) {
                var argn:Float = Std.parseFloat(arg);
                arg = (Math.isNaN(argn)) ? (arg+"-180") : (argn == -180) ? ("0") : Std.string(argn-180);
            }
            return _typeStringH[type] + arg;
        }

        
        static private function _getSpeed(xml:Xml) : String
        {
            var type:Int;
            var speed:Xml = null;
            var child:Xml;
            for (child in xml.elements()) {
                if (child.nodeName == "speed") {
                    speed = child;
                    break;
                }
            }
            if (speed == null) return null;
            
            switch (xml.nodeName) {
                case 'bullet': {
                    type = _getType(speed, TYPE_ABSOLUTE);
                    return _typeStringCS[type] + _cmlArgument(speed);
                }
                case 'changeSpeed': {
                    type = _getType(speed, TYPE_ABSOLUTE);
                    return _typeStringCS[type] + _cmlArgument(speed);
                }
                case 'fire': {
                    type = _getType(speed, TYPE_ABSOLUTE);
                    var spd:String = _cmlArgument(speed);
                    var pre:String = "";
                    switch(type) {
                    case TYPE_RELATIVE:
                        return "f$v+"+ spd;
                    case TYPE_SEQUENCE:
                        if (_seqStac[0].bv == spd) return "f";
                        _seqStac[0].bv = spd;
                        return "bv"+spd+" f";
                    }
                    return "f"+spd;
                }
                default:
                    throw _errorElement(xml, "speed"); // TODO (haxe): 'xml' may not be right
            }
        }

        
        static private function _getTerm(xml:Xml) : String
        {
            // (TODO haxe): return (xml.term[0] != null) ? _cmlArgument(xml.term[0]) : "0";
            return "0";
        }

        
        static private function _getTimes(xml:Xml) : String
        {
            // (TODO haxe): return (xml.times[0] != null) ? _cmlArgument(xml.times[0]) : "";
            return "";
        }
        
        
        static private function _getParam(xml:Xml) : String
        {
            return null;
            // (TODO haxe): var imax:Int = xml.param.length();
            // (TODO haxe): if (imax == 0) return null;
            // (TODO haxe): var str:String = _cmlArgument(xml.param[0]);
            // (TODO haxe): var i:Int;
            // (TODO haxe): for (i in 1...imax) {
            // (TODO haxe): str += "," + _cmlArgument(xml.param[i]);
            // (TODO haxe): }
            // (TODO haxe): return str;
        }
        
        
        

    // sub routine for CML writing
    //--------------------------------------------------
        static private function _write(str:String) : Void
        {
            if (str == null) return;
            _cmlStac[0] += str + " ";
        }

        
        static private function _write_ns(str:String) : Void
        {
            if (str == null) return;
            _cmlStac[0] += str;
        }
        
        
        static private function _flush() : Void
        {
            _cml+=_cmlStac[0];
        }

    
        static private function _pushStac() : Void
        {
            _cmlStac.unshift("");
            _seqStac.unshift(new Seqinfo());
        }
    
        
        static private function _popStac() : String
        {
            _seqStac.shift();
            return _cmlStac.shift();
        }

        
        
    
    // sub routine for XML
    //--------------------------------------------------
        static private function _parseContentsSequencial(xml:Xml, elements:Array<Xml->Bool>) : Void
        {
            var imax:Int = elements.length;
            var elem:Xml;
            for (elem in xml.elements()) {
                var i:Int = 0;
                for (i in 0...imax) {
                    if (elements[i](elem)) break;
                }
                if (i == imax) throw _errorElement(xml, elem.nodeName);
            }
        }


        static private function _getType(xml:Xml, defaultAtt:Int) : Int
        {
            var type:String = xml.get("type");
            var att:Int = -1;
            if (type.length == 0) {
                att = defaultAtt;
            } else {
                var i:Int = -1;
                for (i in 0..._typeString.length) {
                    if (_typeString[i] == type) {
                        att = i;
                        break;
                    }
                }
                if (att == -1) {
                    att = defaultAtt;
                }
            }
            
            if (att == TYPE_NULL) throw _errorAttribute(xml, "type", type);
            return att;
        }
        
        
        static private function _getLabel(xml:Xml, reference:Bool) : String
        {
            var label:String = xml.get("label");
            if (label == null) {
                if (reference) throw _errorNoAttribute(xml, "label");
                else return null;
            }
            return _cmlLabel(label, reference);
        }
        
        
        static private function _cmlLabel(label:String, reference:Bool) : String
        {
            var cmlLabel:String;
            if (_dictLabel[label] != null) {
                cmlLabel = _dictLabel[label];
            } else {
                // convert to uppercase
                cmlLabel = label.toUpperCase();
                
                // If the first character is a number, prefix the string with "_$"
                // TODO (haxe conversion): Check to see if this works
                var search:String = "^[0-9]";
                cmlLabel = search.replace(cmlLabel,'_$&');

                // I don't know what this does, so I'm ignoring it for now.
                // TODO (haxe conversion): Figure out what this does.
                //search = "[^A-Z0-9]+";
                //cmlLabel = search.replace(cmlLabel,'_');
                _dictLabel[label] = cmlLabel;
            }
            if (!reference) {
                // TODO (haxe conversion): Fix all this logic. Disabled temporarily for now since I'm getting sick of this not working yet. :)
                //if (_label.indexOf(cmlLabel) != -1) {
                //    var i:Int = 0;
                //    while (_label.indexOf(cmlLabel+String(i)) != -1) { ++i; }
                //    cmlLabel += String(i);
                //}
                _label.push(cmlLabel);
            }
            return cmlLabel;
        }
        static private var _dictLabel:Map<String, String> = new Map<String, String>();
        
        
        static private function _cmlArgument(arg:Xml) : String
        {
            var rString:String = arg.toString();
            var search:String = "\\s+";

            // TODO (haxe conversion): see if this works!
            
            rString = search.replace(rString, "");

            search = "\\$rank";
            rString = search.replace(rString, "$$r");

            search = "\\$rand";
            rString = search.replace(rString, "$$?");
            
            return rString;
        }
        
        
        static private function _cmlArgumentProp(cmlString:String) : String
        {
            // TODO (haxe conversion): See if this function works correctly
            trace("In _cmlArgumentProp($cmlString)");
            var rex = ~/\$([1-9][0-9]?)/g;
            var argCount:Int = 0;
            var idx:Int = 0;
            while (rex.match(cmlString)) {
                idx = Std.parseInt(rex.matched(0));
                if (argCount < idx) argCount = idx;
                cmlString=rex.matchedRight();
            }
            if (argCount == 0) return "";
            var str:String = "$1";
            for (idx in 1...argCount) { str+=",$"+Std.string(idx+1); }
            return str;
        }


        

}



