//----------------------------------------------------------------------------------------------------
// Scope Limited CMLObject
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------
// Ported to haxe by Brian Gunn (gunnbr@gmail.com) in 2014


package org.si.cml.extensions;

import org.si.cml.*;

    
/** Extension of CMLObject that implements scope limitation. <br/>
 *  You have to call ScopeLimitObject.initialize() first, and you have to call CMLObject.frameUpdate() for each frame.<br/>
 *  ScopeLimitObject.initialize() registers some user define commands as below,
 *  <ul>
 *  <li>&scon; Enables the available scope.</li>
 *  <li>&scoff; Disables the available scope.</li>
 *  </ul>
 */
class ScopeLimitObject extends CMLObject
{
// public variables
//----------------------------------------
    // rectangle of available scope
    /** Minimum x value of the available scope. @default Actor.defaultScopeXmin */
    public var scopeXmin:Float;
    /** Maxmum x value of the available scope. @default Actor.defaultScopeXmax */
    public var scopeXmax:Float;
    /** Minimum y value of the available scope. @default Actor.defaultScopeYmin */
    public var scopeYmin:Float;
    /** Maximum y value of the available scope. @default Actor.defaultScopeYmax */
    public var scopeYmax:Float;
    /** The availabirity of scope check */
    public var scopeEnabled:Bool = true;

    /** default value of the available scopes range */
    static public var defaultScopeXmin:Float = -160;
    /** default value of the available scopes range */
    static public var defaultScopeXmax:Float = 160;
    /** default value of the available scopes range */
    static public var defaultScopeYmin:Float = -240;
    /** default value of the available scopes range */
    static public var defaultScopeYmax:Float = 240;




// public properties
//----------------------------------------
    /** Scope width @default ScopeLimitObject.defaultScopeWidth */
    public var scopeWidth(get,set) : Float;
    public function get_scopeWidth() : Float { return scopeXmax - scopeXmin; }
    public function set_scopeWidth(w:Float) : Float
    {
        scopeXmax = w * 0.5;
        scopeXmin = -scopeXmax;
        return scopeXmax - scopeXmin;
    }


    /** Scope height @default Actor.defaultScopeHeight */
    public var scopeHeight(get,set) : Float;
    public function get_scopeHeight() : Float { return scopeYmax - scopeYmin; }
    public function set_scopeHeight(h:Float) : Float
    {
        scopeYmax = h * 0.5;
        scopeYmin = -scopeYmax;
        return scopeYmax - scopeYmin;
    }


    /** Did this object escape from the scope ? */
    public var isEscaped(get,null) : Bool;
    public function get_isEscaped() : Bool
    {
        return (scopeEnabled && (y<scopeYmin || x<scopeXmin || y>scopeYmax || x>scopeXmax));
    }


    /** default scope width. @default 320 */
    static public var defaultScopeWidth(get,set) : Float;
    static public function get_defaultScopeWidth() : Float { return defaultScopeXmax - defaultScopeXmin; }
    static public function set_defaultScopeWidth(w:Float) : Float
    {
        defaultScopeXmax = w * 0.5;
        defaultScopeXmin = -defaultScopeXmax;
        return defaultScopeXmax - defaultScopeXmin;
    }


    /** default scope height. @default 480  */
    static public var defaultScopeHeight(get,set) : Float;
    static public function get_defaultScopeHeight() : Float { return defaultScopeYmax - defaultScopeYmin; }
    static public function set_defaultScopeHeight(h:Float) : Float
    {
        defaultScopeYmax = h * 0.5;
        defaultScopeYmin = -defaultScopeYmax;
        return defaultScopeYmax - defaultScopeYmin;
    }




// constructor
//----------------------------------------
    /** Constructor */
    public function new()
    {
        super();
    }




// operations
//----------------------------------------
    /** set default scope rectangle. @default Rectangle(-160, -240, 320, 480)  */
    static public function setDefaultScope(x:Float, y:Float, width:Float, height:Float) : Void
    {
        defaultScopeXmin = x;
        defaultScopeXmax = x + width;
        defaultScopeYmin = y;
        defaultScopeYmax = y + height;
    }


    /** Expand scope size from defaultScope. */
    public function expandScope(x:Float, y:Float) : Void
    {
        scopeXmin = defaultScopeXmin - x;
        scopeXmax = defaultScopeXmax + x;
        scopeYmin = defaultScopeYmin - y;
        scopeYmax = defaultScopeYmax + y;
    }


    /** Check scope and call destroy(0) when escaped.
     *  @return flag escaped
     */
    public function checkScope() : Bool
    {
        if (isEscaped) {
            destroy(0);
            return true;
        }
        return false;
    }


    /** Check scope and stay inside of scope.
     *  @return flag limited
     */
    public function limitScope() : Bool
    {
        var ret:Bool = false;
        if (x<scopeXmin) {
            x = scopeXmin;
            ret = true;
        } else if (x>scopeXmax) {
            x = scopeXmax;
            ret = true;
        }
        if (y<scopeYmin) {
            y = scopeYmin;
            ret = true;
        } else if (y>scopeYmax) {
            y = scopeYmax;
            ret = true;
        }
        return ret;
    }





// override
//----------------------------------------
    /**
     * Callback function from CMLObject.frameUpdate(). This function destroys objects that have escaped from scope. It is called after updating position.
     * Override this to update own parameters, and remember to call super.onUpdate() or handle scope escape yourself.
     */
    override public function onUpdate() : Void
    {
        // basic operation to check escaping
        if (isEscaped) destroy(0);
    }


    /** @private */
    override public function _initialize(parent_:CMLObject, isParts_:Bool, access_id_:Int, x_:Float, y_:Float, vx_:Float, vy_:Float, head_:Float) : CMLObject
    {
        scopeXmin = defaultScopeXmin;
        scopeXmax = defaultScopeXmax;
        scopeYmin = defaultScopeYmin;
        scopeYmax = defaultScopeYmax;
        return super._initialize(parent_, isParts_, access_id_, x_, y_, vx_, vy_, head_);
    }




// operation for Actor list
//----------------------------------------
    /** <b>Call this function first of all</b> instead of CMLObject.initialize().
     *  @param vertical_ Flag of scrolling direction
     *  @return The root object.
     *  @see Actor#onPreCreate()
     */
    static public function initialize(vertical_:Bool=true) : CMLObject
    {
        if (CMLObject.root == null) {
            CMLSequence.registerUserCommand("scon",  function(f:CMLFiber, a:Array<Dynamic>) : Void   { var fiberActor : Actor = cast(f.object, Actor); fiberActor.scopeEnabled = true; });
            CMLSequence.registerUserCommand("scoff", function(f:CMLFiber, a:Array<Dynamic>) : Void   { var fiberActor : Actor = cast(f.object, Actor); fiberActor.scopeEnabled = false; });
        }
        return CMLObject.initialize(vertical_);
    }
}

