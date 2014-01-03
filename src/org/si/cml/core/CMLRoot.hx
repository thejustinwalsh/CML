package org.si.cml.core;

import org.si.cml.CMLObject;


/** @private */
class CMLRoot extends CMLObject
{
    /** scroll angle */
    public var _scrollAngle:Float;
        
    /** constructor */
    function new()
    {
        super();
        _scrollAngle = -90;
    }
}


