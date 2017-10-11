//--------------------------------------------------
// CML statement for string class
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------
/*
public function get string():String
*/


package org.si.cml {
    /** @private */
    internal class CMLString extends CMLState
    {
    // variables
    //------------------------------------------------------------
        internal var _string:String;
        

    // functions
    //------------------------------------------------------------
        public function CMLString(str:String)
        {
            super(ST_STRING);
            _string = str;
        }


        internal override function _setCommand(cmd:String) : CMLState
        {
            return this;
        }
    }
}

