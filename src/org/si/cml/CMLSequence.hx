//----------------------------------------------------------------------------------------------------
// CML sequence class (head of the statement chain)
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml;

import org.si.cml.core.*;
import flash.errors.Error;
    
    /** Class for the sequences created from the cannonML or the bulletML.
     *  <p>
     *  USAGE<br/>
     *  1) CMLSequence(cannonML_String or bulletML_XML); creates a new sequence from certain cannonML/bulletML.<br/>
     *  2) CMLObject.execute(CMLSequence); apply sequence to CMLObject.<br/>
     *  3) CMLSequence.global; makes it global. You can access the child sequences of global sequence from everywhere.<br/>
     *  4) CMLSequence.findSequence(); finds labeled sequence in cannonML/bulletML.<br/>
     *  5) CMLSequence.getParameter(); accesses parameters of sequence.<br/>
     *  6) CMLSequence.registerUserCommand(); registers the function called from cannonML.<br/>
     *  7) CMLSequence.registerUserVariable(); registers the function refered by cannonML.<br/>
     *  </p>
     * @see CMLObject#execute()
     * @see CMLSequence#CMLSequence()
     * @see CMLSequence#global
     * @see CMLSequence#findSequence()
     * @see CMLSequence#getParameter()
     * @see CMLSequence#registerUserCommand()
     * @see CMLSequence#registerUserVariable()
@example Typical usage.
<listing version="3.0">
// Create enemys sequence from "String of cannonML" or "XML of bulletML".
var motion:CMLSequence = new CMLSequence(String or XML);

 ...

enemy.create(x, y);                                     // Create enemy on the stage.
enemy.execute(motion);                                  // Execute sequence.
</listing>
     */
class CMLSequence extends CMLState
{
    // variables
    //------------------------------------------------------------
        private  var _label:String = null;
        private  var _childSequence:Map<String, CMLSequence> = null;
        private  var _parent:CMLSequence = null;
        private  var _non_labeled_count:Int = 0;
        private  var _global:Bool = false;
        /** @private */ 
        public var require_argc:Int = 0;

        // global sequence
        static private var globalSequences:Array<CMLSequence> = new Array();
        
        
        
        
    // properties
    //------------------------------------------------------------
        /** dictionary of child sequence, you can access by label */
    public var childSequence(get, null) : Map<String, CMLSequence>;
    public function get_childSequence() : Map<String, CMLSequence> { return _childSequence; }
        
        /** label of this sequence */
    public var label(get, null) : String;
        public function get_label() : String { return _label; }
        
        /** Flag of global sequence.
         *  <p>
         *  Child sequences of a global sequence are accessable from other sequences.<br/>
         *  </p>
@example
<listing version="3.0">
var seqG:CMLSequence = new CMLSequence("#LABEL_G{...}");

seqG.global = true;
var seqA:CMLSequence = new CMLSequence("&LABEL_G");    // Success; you can refer the LABEL_G.

seqG.global = false;
var seqB:CMLSequence = new CMLSequence("&LABEL_G");    // Error; you cannot refer the LABEL_G.
</listing>
         */
    public var global(get,set) : Bool;
        public function get_global() : Bool { return _global; }
        public function set_global(makeGlobal:Bool) : Bool
        {
            if (_global == makeGlobal) return _global;
            _global = makeGlobal;
            if (makeGlobal) {
                globalSequences.unshift(this);
            } else {
                var imax:Int = globalSequences.length;
                var i:Int;
                for (i in 0...imax) {
                    if (globalSequences[i] == this) {
                        globalSequences.splice(i, 1);
                        return _global;
                    }
                }
            }
            return _global;
        }


        /** Is this sequence empty ? */
      public var isEmpty(get,null) : Bool;
        public function get_isEmpty() : Bool
        {
            return (next==null || cast(next,CMLState).type==CMLState.ST_END);
        }
        
        
        
        
    // functions
    //------------------------------------------------------------
        /** Construct new sequence by a String of cannonML or an XML of bulletML.
         *  @param data Sequence data. Intstance of String or XML is available. String data is for CannonML, and XML data is for BulletML.
         *  @param globalSequence Flag of global sequence.
         */
        public function new(data:Dynamic = null, globalSequence:Bool = false)
        {
            super(CMLState.ST_NO_LABEL);

            _label  = null;
            _parent = null;
            _childSequence = new Map<String, CMLSequence>();
            _non_labeled_count = 0;
            require_argc = 0;
            _global = false;
            global = globalSequence;

            if (data != null) {
                if (Std.is(data,Xml)) BMLParser._parse(this, data);
                else                  CMLParser._parse(this, data);
            }
        }
        
        
        /** @private */ 
        public override function _setCommand(cmd:String) : CMLState
        {
            //_resetParameters(CMLObject._argumentCountOfNew);
            return this;
        }
        
        
        
        
    // statics
    //------------------------------------------------------------
        /** Register user defined variable "$[a-z_]+".
         *  <p>
         *  This function registers the variables that can use in CML-string. <br/>
         *  </p>
         *  @param name The name of variable that appears like "$name" in CML-string.
         *  @param func The callback function when the reference appears in sequence.<br/>
         *  The type of callback is <code>function(fbr:CMLFiber):Float</code>. The argument gives a fiber that execute the sequence.
         *  @see CMLFiber
@example 
<listing version="3.0">
// In the cml-string, you can use "$life" that returns Enemy's life.
CMLSequence.registerUserValiable("life", referLife);

function referLife(fbr:CMLFiber) : Float
{
    // Enemy class is your extention of CMLObject.
    return Enemy(fbr.object).life;
}
</listing>
         */
        static public function registerUserValiable(name:String, func:CMLFiber->Float) : Void
        {
            CMLParser.userReference(name, func);
        }


        /** Register user defined command "&[a-z_]+".
         *  <p>
         *  This function registers the command that can use in CML string. <br/>
         *  </p>
         *  @param name The name of command that appears like "&name" in CML string.
         *  @param func The callback function when the command appears in sequence.<br/>
         *  The type of callback is <code>function(fbr:CMLFiber, args:Array):Void</code>.
         *  The 1st argument gives a reference of the fiber that execute the sequence.
         *  And the 2nd argument gives the arguments of the command.
         *  @param argc The count of argument that this command requires.<br/>
         *  @param requireSequence Specify true if this command require the sequence as the '&', '@' and 'n' commands.
         *  @see CMLFiber
@example 
<listing version="3.0">
// In the cml-string, you can use "&sound[sound_index],[volume]" that plays sound.
CMLSequence.registerUserCommand("sound", playSound, 2);

function playSound(fbr:CMLFiber, args:Array) : Void
{
    // function _playSound(index, volume) plays sound.
    if (args.length >= 2) _playSound(args[0], args[1]);
}
</listing>
        */
        static public function registerUserCommand(name:String, func:CMLFiber->Array<Dynamic>, argc:Int=0, requireSequence:Bool=false) : Void
        {
            trace('*** Registering user command \"$name\".');
            CMLParser.userCommand(name, func, argc, requireSequence);
        }




    // references
    //------------------------------------------------------------
        /** Get parameter of this sequence.
         *  <p>
         *  This function gives the parameters of this sequence.<br/>
         *  Parameters of a sequence are shown like "#LABEL{0,1,2 ... }" in cml-string.
         *  </p>
         *  @param  Index of argument.
         *  @return Value of argument.
@example
<listing version='3.0'>
var seq:CMLSequence = new CMLSequence("#A{10,20 v0,2[w30f3]}");
var seqA:CMLSequence = seq.findSequence("A");
trace(seqA.getParameter(0), seqA.getParameter(1), seqA.getParameter(2));    // 10, 20, 0
</listing>
         */
        public function getParameter(idx:Int) : Float
        {
            return (idx < _args.length) ? _args[idx] : 0;
        }
        
        
        

    // operations
    //------------------------------------------------------------
        /** Make this sequence empty.
         *  <p>
         *  This function disconnects all statement chains and enable to be caught by GC.
         *  </p>
         */
        override public function clear() : Void
        {
            // remove from global list
            global = false;
            
            // disconnect all chains
            var cmd:CMLState, cmd_next:CMLState;
            cmd=cast(next,CMLState);
            while (cmd!=null) {
                cmd_next = cast(cmd.next,CMLState);
                cmd.clear();
                cmd=cmd_next;
            }
            
            // clear children
            var key:String;
            for (key in _childSequence.keys()) {
                _childSequence[key].clear();
                _childSequence.remove(key);
            }
            
            // call clear in super class
            super.clear();
        }
        
        
        /** Parse CannonML-String or BulletML-XML.
         *  @param String or XML is available. String is for CannonML, and XML is for BulletML.
         */
        public function parse(data:Dynamic) : Void
        {
            clear();
            if (Std.is(data,Xml)) BMLParser._parse(this, data);
            else                  CMLParser._parse(this, data);
        }
        
        
        /** Find child sequence that has specified label.
         *  @param Label to find.
         *  @return Found sequence.
@example
<listing version="3.0">
// You can access the child sequence.
var seq:CMLSequence = new CMLSequence("#A{v0,2[w30f3]}");
var seqA:CMLSequence = seq.findSequence("A");       // seqA is "v0,2[w30f]".

// You can use the access operator.
var seq:CMLSequence = new CMLSequence("#A{ #B{v0,2[w30f4]} #C{v0,4[w10f2]} }");
var seqAB:CMLSequence = seq.findSequence("A.B");    // seqAB is "v0,2[w30f4]". Same as seq.findSequence("A").findSequence("B")
var seqAC:CMLSequence = seq.findSequence("A.C");    // seqAB is "v0,4[w10f2]". Same as seq.findSequence("A").findSequence("C")
</listing>
         */
        public function findSequence(label_:String) : CMLSequence
        {
            var idx:Int = label_.indexOf(".");
            if (idx == -1) {
                // label_ does not include access operator "."
                if (_childSequence[label_] != null) return _childSequence[label_];
            } else {
                if (idx == 0) {
                    // first "." means root label
                    var root:CMLSequence = _parent;
                    while (root._parent != null) { root = root._parent; }
                    return root.findSequence(label_.substr(1));
                }
                // label_ includes access operator "."
                var parent_label:String = label_.substr(0, idx);
                if (_childSequence[parent_label] != null) { 
                    var child_label:String = label_.substr(idx+1);
                    return _childSequence[parent_label].findSequence(child_label);
                }
            }
            
            // seek brothers
            return (_parent != null) ? _parent.findSequence(label_) : null;
        }

        
        // seek in global sequence
        private function _findGlobalSequence(label_:String) : CMLSequence
        {
            var seq:CMLSequence;
            for (seq in globalSequences) {
                var findseq:CMLSequence = seq.findSequence(label_);
                if (findseq != null) return findseq;
            }
            return null;
        }
        
        
        
       
    // internals
    //------------------------------------------------------------
        // create new child sequence
        /** @private */ 
        public function newChildSequence(label_:String) : CMLSequence
        {
            var seq:CMLSequence = new CMLSequence();
            trace('*** Making new child sequence for label \"$label_\".');
            seq.type = (label_ == null) ? CMLState.ST_NO_LABEL : CMLState.ST_LABEL;
            seq._label = label_;
            _addChild(seq);
            return seq;
        }
        
        
        // add child.
        private function _addChild(seq:CMLSequence) : Void
        {
            if (seq._label == null) {
                // non-labeled sequence
                // TODO (haxe conversion): Does this do the right thing?
                seq._label = "#" + _non_labeled_count;
                ++_non_labeled_count;
            }
            
            if (_childSequence[seq._label] != null) throw new Error("sequence label confliction; "+seq._label+" in "+label);
            seq._parent = this;
            _childSequence[seq._label] = seq;
        }


        // verification (call after all parsing)
        /** @private */ 
        public function verify() : Void
        {
            var cmd:CMLState, cmd_next:CMLState, cmd_verify:CMLState, new_cmd:CMLState;
            
            // verification
            cmd=cast(next,CMLState);
            while (cmd!=null) {
                cmd_next = cast(cmd.next,CMLState);
                // solve named reference
                if (cmd.type == CMLState.ST_REFER) {
                    if (cast(cmd,CMLRefer).isLabelUnsolved()) {
                        cmd.jump = findSequence(cast(cmd,CMLRefer)._label);
                        if (cmd.jump == null) {
                            cmd.jump = _findGlobalSequence(cast(cmd,CMLRefer)._label);
                            if (cmd.jump == null) throw new Error("Not defined label; " + cast(cmd,CMLRefer)._label);
                        }
                    }
                } else
                // check a sequence after CMLState.STF_CALLREF (&,@,f and n commands).
                if ((cmd.type & CMLState.STF_CALLREF) != 0) {
                    // skip formula command
                    cmd_verify = cmd_next;
                    while (cmd_verify.type == CMLState.ST_FORMULA) {
                        cmd_verify = cast(cmd_verify.next,CMLState);
                    }
                    // if there are no references, ... 
                    if (cmd_verify.type != CMLState.ST_REFER) {
                        if ((cmd.type & CMLState.ST_RESTRICT) != 0) {
                            // throw error
                            throw new Error("No sequences after &/@/n ?");
                        } else {
                            // insert reference after call command.
                            new_cmd = new CMLRefer();
                            new_cmd.insert_after(cmd);
                        }
                    } else 
                    // if there are fomulas between call and reference, shift the call command after fomulas.
                    if (cmd_verify != cmd_next) {
                        cmd.remove_from_list();
                        cmd.insert_before(cmd_verify);
                        cmd_next = cmd_verify;
                    }
                } else
                // verify barrage commands
                if (cmd.type == CMLState.ST_BARRAGE) {
                    // insert barrage initialize command first
                    new_cmd = new CMLState(CMLState.ST_BARRAGE);
                    new_cmd.insert_before(cmd);
                    // skip formula and barrage command
                    cmd_verify = cmd_next;
                    while (cmd_verify.type == CMLState.ST_FORMULA || cmd_verify.type == CMLState.ST_BARRAGE) {
                        cmd_verify = cast(cmd_verify.next,CMLState);
                    }
                    cmd_next = cmd_verify;
                }
                cmd=cmd_next;
            }
         
            // verify all child sequences
            var seq:CMLSequence;
            for (seq in _childSequence) { seq.verify(); }
        }


        // default sequence do nothing. call from CMLFiber
        /** @private */ 
        static public function newDefaultSequence() : CMLSequence
        {
            var seq:CMLSequence = new CMLSequence();
            seq.next = new CMLState(CMLState.ST_END);
            seq.next.prev = seq;
            cast(seq.next,CMLState).jump = seq;
            seq._setCommand(null);
            return seq;
        }


        // rapid sequence execute rapid sequence. call from CMLFiber
        /** @private */ 
        static public function newRapidSequence() : CMLSequence
        {
            var seq:CMLSequence = new CMLSequence();
            seq.next = new CMLState(CMLState.ST_RAPID);
            seq.next.prev = seq;
            cast(seq.next,CMLState).jump = seq;
            seq._setCommand(null);
            return seq;
        }


        // sequence to wait for object destruction. call from CMLFiber
        /** @private */ 
        static public function newWaitDestuctionSequence() : CMLSequence
        {
            var seq:CMLSequence = new CMLSequence();
            seq.next = new CMLState(CMLState.ST_W4D);
            seq.next.prev = seq;
            cast(seq.next,CMLState).jump = seq;
            return seq;
        }
    }

