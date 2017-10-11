//--------------------------------------------------
// CML statement class for reference of sequence
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml {
    /** @private */
    internal class CMLRefer extends CMLState
    {
    // variables
    //------------------------------------------------------------
        internal var _label:String = null;
    
        // meaning of reference
        // label=null,   jump=null   means previous call "{.}"
        // label=null,   jump=define means non-labeled call
        // label=define, jump=null   means unsolved label call
        // label=define, jump=define means solved label call

        
    // functions
    //------------------------------------------------------------
        function CMLRefer(pointer:CMLState=null, label_:String=null)
        {
            super(ST_REFER);

            jump = pointer;
            _label = label_;
        }
        
        
        internal override function _setCommand(cmd:String) : CMLState
        {
            return this;
        }
        
        
        internal function isLabelUnsolved() : Boolean
        {
            return (jump==null && _label!=null);
        }
    }
}

