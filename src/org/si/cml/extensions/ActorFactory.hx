//----------------------------------------------------------------------------------------------------
// Factory class of Actors.
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------
// Ported to haxe by Brian Gunn (gunnbr@gmail.com) in 2014


package org.si.cml.extensions;

import openfl.errors.Error;
import org.si.cml.extensions.Actor;
import flash.errors.Error;

    
    /** Factory class of Actors.
@example basic usage.
<listing version="3.0">
public class Bullet extends Actor {
}
    ...
    
var bulletFactory:ActorFactory = new ActorFactory(Bullet);

    ...
    
var newBullet:Bullet = bulletFactory.newInstance();
</listing>
     */
class ActorFactory
{
// variables
//--------------------------------------------------
    /** @private */
    public var _freeList:Actor   = null;
    /** @private */
    private var _actorClass:Class<Dynamic> = null;
    /** @private */
    private var _instanceCount:Int = 0;
    /** @private */
    private var _countMaxLimit:Int = 0;
    /** @private */
    public var _defaultEvalIDNumber:Int = 0;
    /** @private */
    public var _defaultDrawPriority:Int = 0;
    
    
    
    
// properties
//--------------------------------------------------
    /** id number for hitting evaluation. */
    public var evalIDNumber(get,null) : Int;
    public function get_evalIDNumber() : Int
    {
        return _defaultEvalIDNumber;
    }
    
    
    /** drawing priority, young number drawing first. */
    public var drawPriority(get,null) : Int;
    public function get_drawPriority() : Int
    {
        return _defaultDrawPriority;
    }
    
    
    
    
// constructor
//--------------------------------------------------
    /** create new Actor factory. 
     *  @param actorClass class to create new instance
     *  @param countMaxLimit maximum limit of instance count
     *  @param evalIDNumber id nubmer for hitting evaluation. Must be >= 0. Negative value to apply number automatically.
     *  @param drawPriority drawing priority number, young number drawing first. Must be >= 0. Negative value to apply number automatically.
     */
    public function new(actorClass:Class<Dynamic>, countMaxLimit:Int=0, evalIDNumber:Int=-1, drawPriority:Int=-1)
    {
        _freeList      = new Actor();
        _actorClass    = actorClass;
        _countMaxLimit = (countMaxLimit==0) ? 999999 : countMaxLimit;
        _instanceCount = 0;
        _defaultEvalIDNumber = (evalIDNumber>=0) ? evalIDNumber : Actor._evalLayers.length;
        _defaultDrawPriority = (drawPriority>=0) ? drawPriority : Actor._drawLayers.length;
        if (Actor._evalLayers[_defaultEvalIDNumber] == null) Actor._evalLayers[_defaultEvalIDNumber] = new Actor();
        if (Actor._drawLayers[_defaultDrawPriority] == null) Actor._drawLayers[_defaultDrawPriority] = new Actor();
    }
    
    
    /** <b>Get new instance from free list. You CANNOT create the new instance of registered class by "new" operator. </b> 
     *  @return new instance
     */
    public function newInstance() : Dynamic
    {
        var act:Actor = _freeList;
        if (act == act._prevEval) {
            if (++_instanceCount > _countMaxLimit) {
                throw new Error("ActorFactory Execution Exception. The number of " + _actorClass + " achieves to the maximum limit.");
                return null;
            }
            act = Type.createInstance( _actorClass, [] );
            if (act == null) {
                throw new Error('Failed to create actor of class $_actorClass');
            }
            act._factory = this;
        } else {
            // remove from freeList
            act = act._prevEval;
            act._prevEval._nextEval = act._nextEval;
            act._nextEval._prevEval = act._prevEval;
        }
        return act;
    }
}




