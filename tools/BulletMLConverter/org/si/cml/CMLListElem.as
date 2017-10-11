//--------------------------------------------------
// list structure element for CML
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml {
    /** @private */
    internal class CMLListElem
    {
        static internal var sin:CMLSinTable = new CMLSinTable();
        
        internal var prev:CMLListElem;
        internal var next:CMLListElem;
        
        function CMLListElem()
        {
        }
        
        internal function _clear() : void
        {
            prev = null;
            next = null;
        }
        
        internal function remove_from_list() : void
        {
            prev.next = next;
            next.prev = prev;
            prev = null;
            next = null;
        }
        
        internal function insert_before(next_:CMLListElem) : void
        {
            next = next_;
            prev = next_.prev;
            next_.prev.next = this;
            next_.prev = this;
        }
        
        internal function insert_after(prev_:CMLListElem) : void
        {
            prev = prev_;
            next = prev_.next;
            prev_.next.prev = this;
            prev_.next = this;
        }
    }
}



