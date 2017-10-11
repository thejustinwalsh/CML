package org.si.cml {
    /** @private */
    internal class CMLRoot extends CMLObject
    {
        private var _funcNewObject:Function;
        
        function CMLRoot(funcNewObject_:Function)
        {
            _initialize(this, false, ID_NOT_SPECIFYED, 0, 0, 0, 0, 0);
            _funcNewObject = funcNewObject_;
        }
        
        public override function onNewObject(arg:Array) : CMLObject
        {
            return _funcNewObject(arg);
        }
        
        public override function onFireObject(arg:Array) : CMLObject
        {
            return _funcNewObject(arg);
        }
    }
}

