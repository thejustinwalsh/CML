//--------------------------------------------------
// CML barrage element class
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------
// Ported to haxe by Brian Gunn (gunnbr@gmail.com) in 2014


package org.si.cml.core;

import org.si.cml.CMLObject;
    
    
    /** @private */
class CMLBarrageElem extends CMLListElem
{
        // Quartarnion
        private var count:Int = 1;
        
        // Result reference
        public var angle   :Float = 0;
        public var speed   :Float = 1;
        public var interval:Float = 0;
        
        // internal parameters
        public var counter     :Int    = 1;
        public var angle_offset:Float = 0;
        public var speed_offset:Float = 0;
        public var angle_step  :Float = 0;
        public var speed_step  :Float = 0;
        public var random      :Bool = false;

        // update function
        public var init  :CMLBarrageElem->Void;
        public var update:Void->Void;
        
        
        public function new()
        {
            super();
            init   = _init;
            update = _update;
        }



        
    // setting
    //--------------------------------------------------
        // set sequencial step
        public function setSequence(count_:Int, angle_:Float, speed_:Float, interval_:Float) : CMLBarrageElem
        {
            count = (count_>0) ? count_ : ((interval_>0) ? -1 : 1);
            angle = 0;
            speed = 1;
            
            counter      = count;
            angle_offset = 0;
            speed_offset = 0;
            angle_step   = angle_;
            speed_step   = speed_;
            interval     = (interval_>0) ? interval_ : 0;
            random       = false;
            
            init   = _init;
            update = _update;
            
            return this;
        }

        
        // set multiple parameters
        public function setMultiple(count_:Int, angle_:Float, speed_:Float, interval_:Float) : CMLBarrageElem
        {
            count = (count_>0) ? count_ : 1;
            angle = 0;
            speed = 1;
            
            counter      = count;
            angle_offset = -angle_ * 0.5;
            speed_offset = -speed_ * 0.5;
            angle_step   = (angle_ == 360 || angle_ == -360) ? (angle_/count) : ((count < 2) ? 0 : angle_/(count-1));
            speed_step   = (count < 2) ? 0 : speed_/(count-1);
            interval     = (interval_>0) ? interval_ : 0;
            random       = false;
            
            init   = _init;
            update = _update;
            
            return this;
        }
        
        
        // set random parameters
        public function setRandom(count_:Int, angle_:Float, speed_:Float, interval_:Float) : CMLBarrageElem
        {
            count = (count_>0) ? count_ : ((interval_>0) ? -1 : 1);
            angle = 0;
            speed = 1;
            
            counter      = count;
            angle_offset = 0;
            speed_offset = 0;
            angle_step   = angle_;
            speed_step   = speed_;
            interval     = (interval_>0) ? interval_ : 0;
            random       = true;
            
            init   = _init_random;
            update = _update_random;
            
            return this;
        }
        
        
        // copy all parameters
        public function copy(src:CMLBarrageElem) : CMLBarrageElem
        {
            count = src.count;
            angle = src.angle;
            speed = src.speed;
            
            counter      = src.counter;
            angle_offset = src.angle_offset;
            speed_offset = src.speed_offset;
            angle_step   = src.angle_step;
            speed_step   = src.speed_step;
            interval     = src.interval;
            random       = src.random;

            if (!random) {
                init   = _init;
                update = _update;
            } else {
                init   = _init_random;
                update = _update_random;
            }

            return this;
        }
        
        
        // set speed step
        public function setSpeedStep(ss:Float) : Void
        {
            speed_step = ss;
        }


        // check end
        public function isEnd() : Bool
        {
            return (counter == 0);
        }




    // calculation of sequencial bullet
    //--------------------------------------------------
        /** @private initialize */
        public function _init(parent:CMLBarrageElem) : Void
        {
            counter = count;
            angle   = parent.angle + angle_offset;
            speed   = parent.speed + speed_offset;
        }
        
        /** @private initialize random */
        public function _init_random(parent:CMLBarrageElem) : Void
        {
            counter = count;
            angle_offset = parent.angle - angle_step * 0.5;
            speed_offset = parent.speed - speed_step * 0.5;
            angle = angle_offset + angle_step * CMLObject.rand();
            speed = speed_offset + speed_step * CMLObject.rand();
        }

        /** @private update */
        public function _update() : Void
        {
            angle += angle_step;
            speed += speed_step;
            --counter;
        }
        
        /** @private update random */
        public function _update_random() : Void
        {
            angle = angle_offset + angle_step * CMLObject.rand();
            speed = speed_offset + speed_step * CMLObject.rand();
            --counter;
        }
    }
