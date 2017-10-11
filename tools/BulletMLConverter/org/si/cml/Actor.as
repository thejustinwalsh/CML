//----------------------------------------------------------------------------------------------------
// Extention of CMLObject
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml {
    import flash.utils.Dictionary;
    
    
    /** <b>Extension of CMLObject</b> that scope, life, hit test, drawing priority and management of instances are implemented. <br/>
     *  You have to call Actor.initialize() first, and you have to call CMLObject.update() and Actor.draw() for each frame.<br/>
     *  Actor.initialize() registers some user define commands as below,
     *  <ul>
     *  <li>$life; Refers the value of Actor.life.</li>
     *  <li>&scon; Enables the available scope.</li>
     *  <li>&scoff; Disables the available scope.</li>
     *  <li>&prior; Changes the drawing priority. Specify the priority (posi/nega value) in argument.</li>
     *  </ul>
     */
    public class Actor extends CMLObject
    {
    // public variables
    //----------------------------------------
        // rectangle of available scope
        /** Minimum x value of the available scope. @default Actor.defaultScopeXmin */
        public var scopeXmin:Number;
        /** Maxmum x value of the available scope. @default Actor.defaultScopeXmax */
        public var scopeXmax:Number;
        /** Minimum y value of the available scope. @default Actor.defaultScopeYmin */
        public var scopeYmin:Number;
        /** Maximum y value of the available scope. @default Actor.defaultScopeYmax */
        public var scopeYmax:Number;
        /** The availabirity of scope check */
        public var scopeAvailable:Boolean = true;

        /** Life, you can use this as you like. Set life to 1 when the object is created. */
        public var life:Number = 1;
        /** Size to use in hit test */
        public var size:Number = 0;

        /** default value of the available scopes range */
        static public var defaultScopeXmin:Number = -160;
        /** default value of the available scopes range */
        static public var defaultScopeXmax:Number = 160;
        /** default value of the available scopes range */
        static public var defaultScopeYmin:Number = -240;
        /** default value of the available scopes range */
        static public var defaultScopeYmax:Number = 240;




    // public properties
    //----------------------------------------
        /** Scope width @default Actor.defaultScopeWidth */
        public function set scopeWidth(w:Number) : void
        {
            scopeXmax = w * 0.5;
            scopeXmin = -scopeXmax;
        }
        /** @private */
        public function get scopeWidth() : Number
        {
            return scopeXmax - scopeXmin;
        }
        
        
        /** Scope height @default Actor.defaultScopeHeight */
        public function set scopeHeight(h:Number) : void
        {
            scopeYmax = h * 0.5;
            scopeYmin = -scopeYmax;
        }
        /** @private */
        public function get scopeHeight() : Number
        {
            return scopeYmax - scopeYmin;
        }


        /** The key of hit test. @default This objects class instance. */
        public function set testKey(key:Object) : void
        {
            _testList = _dictTestList[key];
            enableTest = true;
        }


        /** Enable/disable the hit test. @default true */
        public function set enableTest(enable:Boolean) : void
        {
            var list:Actor = (enable) ? _testList : _noTestList;
            _prevActor._nextActor = _nextActor;
            _nextActor._prevActor = _prevActor
            _prevActor = list._prevActor;
            _nextActor = list;
            _prevActor._nextActor = this;
            _nextActor._prevActor = this;
        }
        
        
        /** Shift the drawing priority. @default 0 */
        public function set drawPriority(prior:int) : void
        {
            var i:int;
            var plain:Actor = _info.drawPlain;
            if (prior > 0) {
                for (i=0; i<prior; ++i) {
                    plain = plain._prevActor;
                    if (plain == _listDrawPlain) return;
                }
            } else {
                for (i=0; i>prior; --i) {
                    plain = plain._nextActor;
                    if (plain == _listDrawPlain) return; 
                }
            }
            drawPlain = plain;
        }
        
        
        /** Drawing plain. You can get it from a return value of registerDrawPriority(). @see Actor#registerDrawPriority() */
        public function set drawPlain(plain:Actor) : void
        {
            _nextDraw._prevDraw = _prevDraw;
            _prevDraw._nextDraw = _nextDraw;
            _prevDraw = plain._prevDraw;
            _nextDraw = plain;
            _prevDraw._nextDraw = this;
            _nextDraw._prevDraw = this;
        }
        public function get drawPlain() : Actor
        {
            return _info.drawPlain;
        }
        

        /** Actor class */
        public function get actorClass() : Class
        {
            return _info.actorClass;
        }
        /** Actor class created by n command */
        public function get newActorClass() : Class
        {
            return _info.newActorClass;
        }
        /** Actor class created by f command */
        public function get fireActorClass() : Class
        {
            return _info.fireActorClass;
        }
        
        
        /** default scope width. @default 320 */
        static public function set defaultScopeWidth(w:Number) : void
        {
            defaultScopeXmax = w * 0.5;
            defaultScopeXmin = -defaultScopeXmax;
        }
        /** @private */
        static public function get defaultScopeWidth() : Number
        {
            return defaultScopeXmax - defaultScopeXmin;
        }

        
        /** default scope height. @default 480  */
        static public function set defaultScopeHeight(h:Number) : void
        {
            defaultScopeYmax = h * 0.5;
            defaultScopeYmin = -defaultScopeYmax;
        }
        /** @private */
        static public function get defaultScopeHeight() : Number
        {
            return defaultScopeYmax - defaultScopeYmin;
        }


    // constructor
    //----------------------------------------
        /** Constructor */
        public function Actor()
        {
            _nextDraw = this;
            _prevDraw = this;
            _nextActor = this;
            _prevActor = this;
        }




    // callback functions
    //----------------------------------------
        /** Callback function on create. Override this to initialize. */
        override public function onCreate() : void { }
        
        /** Callback function on destroy. Override this to finalize. 
         *  @see CMLObject#destroy()
         *  @see CMLObject#destroyAll()
         */
        override public function onDestroy() : void { }
        
        /** Callback function before creation. Override this to refer the arguments of sequence. */
        public function onPreCreate(args:Array) : void { }
        
        /** Callback function when CMLObject.update() is called. This function is called after update position. Override this to update own parameters. */
        public function onRun() : void { }
        
        /** Callback function to draw. This function is called in the order of the property drawPriority. */
        public function onDraw() : void { }

        /** Callback function from Actor.test() when the hit test is true. */
        public function onHit(act:Actor) : void { }
        
        


    // operations
    //----------------------------------------
        /** Set default scope size. */
        static public function defaultScope(width:Number, height:Number) : void
        {
            defaultScopeWidth  = width;
            defaultScopeHeight = height;
        }
        
        
        /** Expand scope size. */
        public function expandScope(x:Number, y:Number) : void
        {
            scopeXmin = defaultScopeXmin - x;
            scopeXmax = defaultScopeXmax + x;
            scopeYmin = defaultScopeYmin - y;
            scopeYmax = defaultScopeYmax + y;
        }
        
        


    // refereneses
    //----------------------------------------
        /** Did this object escape from the scope ? */
        public function isEscaped() : Boolean
        {
            return (y<scopeYmin || x<scopeXmin || y>scopeYmax || x>scopeXmax);
        }




    // override
    //----------------------------------------
        /** @private */
        override public function onNewObject(args:Array) : CMLObject
        {
            var act:Actor = Actor(instance(_info.newActorClass));
            act.onPreCreate(args);
            return act;
        }


        /** @private */
        override public function onFireObject(args:Array) : CMLObject
        {
            var act:Actor = Actor(instance(_info.fireActorClass));
            act.onPreCreate(args);
            return act;
        }

        
        /** @private */
        override public function onUpdate() : void
        {
            if (scopeAvailable && isEscaped()) {
                destroy(0);
            } else {
                onRun();
            }
        }


        /** @private */
        override internal function _initialize(parent_:CMLObject, isParts_:Boolean, access_id_:int, x_:Number, y_:Number, vx_:Number, vy_:Number, head_:Number) : CMLObject
        {
            _register();
            scopeXmin = defaultScopeXmin;
            scopeXmax = defaultScopeXmax;
            scopeYmin = defaultScopeYmin;
            scopeYmax = defaultScopeYmax;
            life = 1;
            return super._initialize(parent_, isParts_, access_id_, x_, y_, vx_, vy_, head_);
        }
        
        
        /** @private */
        override protected function _finalize() : void
        {
            _unregister();
            super._finalize();
        }
        
        
        

    // operation for Actor list
    //----------------------------------------
        private var _testList:Actor = null;
        
        private var _info:ActorInfo  = null;
        private var _nextActor:Actor = null;
        private var _prevActor:Actor = null;
        private var _nextDraw:Actor  = null;
        private var _prevDraw:Actor  = null;
        
        
        /** Register this object on the actor list. */
        protected function _register() : void
        {
            var list:Actor = _testList;
            _prevActor = list._prevActor;
            _nextActor = list;
            _prevActor._nextActor = this;
            _nextActor._prevActor = this;

            list = _info.drawPlain;
            _prevDraw = list._prevDraw;
            _nextDraw = list;
            _prevDraw._nextDraw = this;
            _nextDraw._prevDraw = this;
        }

        
        /** Unregister this object from the actor list. */
        protected function _unregister() : void
        {
            _nextDraw._prevDraw = _prevDraw;
            _prevDraw._nextDraw = _nextDraw;
            _prevDraw = null;
            _nextDraw = null;
            
            var list:Actor = _info.freeList;
            _prevActor._nextActor = _nextActor;
            _nextActor._prevActor = _prevActor;
            _prevActor = list._prevActor;
            _nextActor = list;
            _prevActor._nextActor = this;
            _nextActor._prevActor = this;
        }




    // operation for Actor list
    //----------------------------------------
        static private var _dictActorInfo:Dictionary = null;
        static private var _dictTestList:Dictionary = null;
        static private var _listDrawPlain:Actor = null;
        static private var _noTestList:Actor = null;
        static private var _defaultNewObjectClass:Class = null;
        
        
        /** <b>Call this function first of all</b> instead of CMLObject.initialize(). 
         *  @param vertical_ Flag of scrolling direction
         *  @param defaultNewObjectClass_ Class for new Object created by n*,f* in root object.
         *  @param argumentMax The maximum count of arguments for onPreCreate().
         *  @return The root object.
         *  @see Actor#onPreCreate()
         */
        static public function initialize(vertical_:Boolean, defaultNewObjectClass_:Class, argumentMax:int=0) : CMLObject
        {
            _defaultNewObjectClass = defaultNewObjectClass_;
            
            _dictActorInfo = new Dictionary();
            _dictTestList = new Dictionary();
            _listDrawPlain = new Actor();
            _noTestList = new Actor();
            
            CMLSequence.registerUserValiable("life",  function(f:CMLFiber)          : Number { return Actor(f.object).life; });
            CMLSequence.registerUserCommand ("scon",  function(f:CMLFiber, a:Array) : void   { Actor(f.object).scopeAvailable = true; });
            CMLSequence.registerUserCommand ("scoff", function(f:CMLFiber, a:Array) : void   { Actor(f.object).scopeAvailable = false; });
            CMLSequence.registerUserCommand ("prior", function(f:CMLFiber, a:Array) : void   { Actor(f.object).drawPriority = a[0]; }, 1);

            return CMLObject.initialize(vertical_, _defaultNewObject, argumentMax);
        }
        
        
        static private function _defaultNewObject(args:Array) : CMLObject
        {
            var act:Actor = Actor.instance(_defaultNewObjectClass);
            act.onPreCreate(args);
            return act;
        }
        
        
        /** Register the extention class of Actor to manage the instance. The order of registration is the order of drawing.
         *  @param actorClass Extention Class of Actor.
         *  @param newActorClass Class of an object creates by n* command.
         *  @param fireActorClass Class of an object creates by f* command.
         *  @param countMaxLimit Maximum count of this actors instances. O means no limit.
         *  @see Actor#registerDrawPriority()
         *  @example Typical initializing.
<listing version="3.0">
// Bullet, Enemy, Player and Shot are the extention classes of Actor.
Actor.initialize(true, Enemy);
Actor.register(Shot,   Shot,  Shot);    // Shotcreates Shot by n/f command.
Actor.registerDrawPriority();           // Register the priority here to draw Enemy with low drawing priority.
Actor.register(Enemy,  Enemy, Bullet);  // Enemy creates Enemy by n command and creates Bullet by fcommand.
Actor.registerDrawPriority();           // Register the priority here to draw Enemy with high drawing priority. 
Actor.register(Player, Shot,  Shot);    // Player creates Shot  by n/f command.
Actor.register(Bullet, Enemy, Bullet);  // Bullet creates Enemy by n command and creates Bullet by fcommand.
</listing>
         */
        static public function register(actorClass:Class, newActorClass:Class, fireActorClass:Class, countMaxLimit:int=0) : void
        {
            var drawPlain:Actor = new Actor();
            var testList:Actor = new Actor();
            _dictActorInfo[actorClass] = new ActorInfo(actorClass, newActorClass, fireActorClass, testList, drawPlain, countMaxLimit);
            _dictTestList[actorClass] = testList;
            drawPlain._prevActor = _listDrawPlain._prevActor;
            drawPlain._nextActor = _listDrawPlain;
            drawPlain._prevActor._nextActor = drawPlain;
            drawPlain._nextActor._prevActor = drawPlain;
        }
        
        
        /** Register drawing priority. Call this function between register() to insert the drawing priority layer.
         *  @see Actor#register()
         */
        static public function registerDrawPriority() : Actor
        {
            var actorDrawPlain:Actor = new Actor();
            actorDrawPlain._prevActor = _listDrawPlain._prevActor;
            actorDrawPlain._nextActor = _listDrawPlain;
            actorDrawPlain._prevActor._nextActor = actorDrawPlain;
            actorDrawPlain._nextActor._prevActor = actorDrawPlain;
            return actorDrawPlain;
        }
        
        
        /** Register the hit test key. Usually you dont have to call this, because the default key is the Class instance and its already registered.
         *  @param key The key object.
         *  @return The key object.
         */
        static public function registerTestKey(key:Object) : Object
        {
            _dictTestList[key] = new Actor();
            return key;
        }
        
        
        /** Set maximum count of instances.
         *  @param actorClass The class of actor.
         *  @param countMaxLimit The maximum count of that instances.
         */
        static public function setMaxLimit(actorClass:Class, countMaxLimit:int) : void
        {
            _dictActorInfo[actorClass].countMaxLimit = countMaxLimit;
        }
        
        
        /** The instance count at maximum. 
         *  @param actorClass The class of actor.
         *  @return The instance count at maximum.
         */
        static public function getInstanceCountMax(actorClass:Class) : int
        {
            return _dictActorInfo[actorClass].count;
        }
        
        
        /** <b>Call this function for each frame</b> to call all onDraw()s. */
        static public function draw() : void
        {
            var term:Actor = _listDrawPlain;
            for (var list:Actor=term._nextActor; list!=term; list=list._nextActor) {
                for (var act:Actor=list._nextDraw;  act!=list; act=act._nextDraw) {
                    act.onDraw();
                }
            }
        }

        
        /** Hit test of the instances. 
         *  @param key0 testKey of act0 in the eval's argument. Usually specify the Class instance.
         *  @param key1 testKey of act1 in the eval's argument. Usually specify the Class instance.
         *  @param evalfunc Function to evaluate. The type is function(act0:Actor, act1:Actor):Boolean and return true when the evaluation succeeded.
         *  @see Actor#evalTypical
         *  @see Actor#evalFast
         *  @example Typical hit test.
<listing version="3.0">
// Bullet, Enemy, Player and Shot are the extention classes of Actor.
Actor.test(Enemy,  Shot,   Actor.evalTypical);  // evaluate by typical shooting hit test 
Actor.test(Player, Bullet, Actor.evalTypical);  // evaluate by typical shooting hit test
</listing>
         */
        static public function test(key0:Object, key1:Object, evalfunc:Function) : void
        {
            var act0:Actor, act1:Actor, act0_id:int,
                list0:Actor = _dictTestList[key0],
                list1:Actor = _dictTestList[key1];

            for (act0=list0._nextActor; act0!=list0; act0=act0._nextActor) {
                act0_id = act0.id;
                for (act1=list1._nextActor; act1!=list1; act1=act1._nextActor) {
                    if (evalfunc(act0, act1)) {
                        act0.onHit(act1);
                        act1.onHit(act0);
                    }
                    if (act0_id != act0.id) break;
                }
            }
        }
        
        
        /** <b>Get new instance from free list. You CANNOT create the new instance of registered class by "new" operator. </b>
         *  @see Actor#register()
         *  @example Call instanece() instead of new operator.
<listing version="3.0">
// Same as new Player(), but if you register Player Class you have to use Actor.instance().
player = Actor.instance(Player);
</listing>
         */
        static public function instance(actorClass:Class) : *
        {
            var info:ActorInfo = _dictActorInfo[actorClass];
            var list:Actor     = info.freeList;
            var act :Actor     = list._prevActor;
            if (list == act) {
                if (++info.count > info.countMaxLimit) {
                    throw new Error("CML Execution error. The count of "+actorClass+" achieves the limit.");
                    return null;
                }
                act = new actorClass();
                act._info = info;
                act._testList = info.testList;
            } else {
                // remove from freeList
                act._prevActor._nextActor = act._nextActor;
                act._nextActor._prevActor = act._prevActor;
            }
            return act;
        }
        
        
        
        
    // Typical functions for evaluation (3rd ARG of Actor.test())
    //--------------------------------------------------
        /** Typical shooting hit test evaluator for the 3rd ARG of Actor.test(). 
         *  Specify slower actor as key0 and faster actor as key1 in Actor.test() for the purpse of accuracy.
         *  @see Actor#test
         */
        static public function evalTypical(act0:Actor, act1:Actor) :Boolean
        {
            var dx:Number  = act0.x - act1.x;
            var dy:Number  = act0.y - act1.y;
            var dot:Number = - dx*act1.vx - dy*act1.vy;
            var sz:Number  = act0.size + act1.size;
            
            var dln2:Number = dx*dx+dy*dy;
            if (dot<0) return (dln2<=sz*sz);
            
            var vln2:Number = act1.vx*act1.vx+act1.vy*act1.vy;
            dot *= dot;
            if (dot>vln2) return false;
            
            var dist:Number = dln2 - dot/vln2;
            return (dist>=0 && dist<=sz*sz);
        }
        
        
        /** Fast evaluator by aproximate distance for the 3rd ARG of Actor.test(). 
         *  The distance is calculated as an octagnal.
         *  @see Actor#test
         */
        static public function evalFast(act0:Actor, act1:Actor) :Boolean
        {
            return (act0.getDistance(act1) <= act0.size+act1.size);
        }
    }
}




import org.si.cml.Actor;

class ActorInfo
{
    internal var freeList:Actor = null;
    internal var testList:Actor = null;
    internal var drawPlain:Actor = null;
    internal var actorClass:Class     = null;
    internal var newActorClass:Class  = null;
    internal var fireActorClass:Class = null;
    internal var count:int         = 0;
    internal var countMaxLimit:int = 0;
    
    function ActorInfo(actorClass_:Class, newActorClass_:Class, fireActorClass_:Class, testList_:Actor, drawPlain_:Actor, countMaxLimit_:int) 
    {
        freeList       = new Actor();
        testList       = testList_;
        drawPlain      = drawPlain_;
        actorClass     = actorClass_;
        newActorClass  = newActorClass_;
        fireActorClass = fireActorClass_;
        countMaxLimit  = (countMaxLimit_==0) ? 999999 : countMaxLimit_;
        count          = 0;
    }
}



