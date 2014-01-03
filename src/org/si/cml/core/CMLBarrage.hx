//--------------------------------------------------
// CML barrage class
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml.core;

    
    
    /** The implement of bm/bs/br commands.
     *  <p>
     *  USAGE<br/>
     *  1) Get the barrage setting of fiber by CMLFiber.barrage.<br/>
     *  2) CMLBarrage.clear(); sets the parameter "bm1,0,0,0".<br/>
     *  3) CMLBarrage.append[Multiple|Sequence|Random](); multiply new barrage shape.
     *  </p>
     * @see CMLFiber#barrage
     * @see CMLBarrage#clear();
     * @see CMLBarrage#appendMultiple()
     * @see CMLBarrage#appendSequence()
     * @see CMLBarrage#appendRandom()
     */
class CMLBarrage
{
        // CMLBarrageElem list
        /** @private */
        public var qrtList:CMLList;


        /** Constructor.
         *  Usually you get CMLBarrage instance by CMLFiber.barrage.
         *  @default bm1,0,0,0
         *  @see CMLFiber#barrage
         */
        public function new()
        {
            qrtList = new CMLList();
        }
        



    // setting
    //--------------------------------------------------
        /** Clear all barrage setting. 
         *  Reset to "bm1,0,0,0".
         */
        public function clear() : Void
        {
            freeList.cat(qrtList);
        }
        
        
        /** Append copy of other CLMBarrage.
         *  @param copy source.
         */
        public function appendCopyOf(src:CMLBarrage) : Void
        {
            var qrt:CMLListElem;
            qrt=src.qrtList.begin;
            while (qrt!=src.qrtList.end) {
                _appendElementCopyOf(cast(qrt,CMLBarrageElem));
                qrt=qrt.next;
            }
        }
        

        /** Append append new element "bs"
         *  @param count_ bullet count.
         *  @param angle_ center angle of fan-shaped barrage.
         *  @param speed_ speed difference of barrage.
         *  @param interval_ rapid interval frame.
         */
        public function appendSequence(count_:Int, angle_:Float, speed_:Float, interval_:Float) : Void
        {
            qrtList.push(alloc().setSequence(count_, angle_, speed_, interval_));
        }
        
        
        /** Append append new element "bm"
         *  @param count_ bullet count.
         *  @param angle_ center angle of fan-shaped barrage.
         *  @param speed_ speed difference of barrage.
         *  @param interval_ rapid interval frame.
         */
        public function appendMultiple(count_:Int, angle_:Float, speed_:Float, interval_:Float) : Void
        {
            qrtList.push(alloc().setMultiple(count_, angle_, speed_, interval_));
        }
        
        
        /** Append append new element "br"
         *  @param count_ bullet count.
         *  @param angle_ center angle of fan-shaped barrage.
         *  @param speed_ speed difference of barrage.
         *  @param interval_ rapid interval frame.
         */
        public function appendRandom(count_:Int, angle_:Float, speed_:Float, interval_:Float) : Void
        {
            qrtList.push(alloc().setRandom(count_, angle_, speed_, interval_));
        }
        
        
        // append copy of other elements
        /** @private */
        public function _appendElementCopyOf(src:CMLBarrageElem) : Void
        {
            qrtList.push(alloc().copy(src));
        }




    // element factroy
    //----------------------------------------
        static private var freeList:CMLList = new CMLList();
        static private function alloc() : CMLBarrageElem
        {
            var qrt:CMLBarrageElem = cast(freeList.pop(),CMLBarrageElem);
            if (qrt == null) qrt = new CMLBarrageElem();
            return qrt;
        }
    }



