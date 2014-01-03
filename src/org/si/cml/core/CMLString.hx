//--------------------------------------------------
// CML statement for string class
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------
/*
public function get string():String
*/


package org.si.cml.core;

    
/** @private */
class CMLString extends CMLState
{
    // variables
    //------------------------------------------------------------
    public var _string:String;
        

    // functions
    //------------------------------------------------------------
    public function new(str:String)
    {
        super(CMLState.ST_STRING);
        _string = str;
    }
    
    public override function _setCommand(cmd:String) : CMLState
    {
        return this;
    }
}

