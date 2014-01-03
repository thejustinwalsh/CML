//--------------------------------------------------
// CML statement class for reference of sequence
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml.core;

/** @private */
class CMLRefer extends CMLState
{
    // variables
    //------------------------------------------------------------
    public var _label:String = null;
    
        // meaning of reference
        // label=null,   jump=null   means previous call "{.}"
        // label=null,   jump=define means non-labeled call
        // label=define, jump=null   means unsolved label call
        // label=define, jump=define means solved label call

        
    // functions
    //------------------------------------------------------------
    public function new(pointer:CMLState=null, label_:String=null)
    {
        super(CMLState.ST_REFER);
        
        jump = pointer;
        _label = label_;
    }
    
    
    public override function _setCommand(cmd:String) : CMLState
    {
        return this;
    }
    
        
    public function isLabelUnsolved() : Bool
    {
        return (jump==null && _label!=null);
    }
}

