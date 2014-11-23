//----------------------------------------------------------------------------------------------------
// Element interface class of formula
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------
// Ported to haxe by Brian Gunn (gunnbr@gmail.com) in 2014


package org.si.cml.core;

import org.si.cml.CMLFiber;
    
/** @private */
class CMLFormulaElem
{
    public function new() { }
    public function calc(fbr:CMLFiber) : Float { return 0.0; }
}


