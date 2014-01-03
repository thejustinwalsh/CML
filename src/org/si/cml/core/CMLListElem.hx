//--------------------------------------------------
// list structure element for CML
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml.core;
    
// TODO: Make an iterator so we can use that on this.

/** @private */
class CMLListElem
{
    public var prev:CMLListElem;
    public var next:CMLListElem;
    
    public function new()
    {
    }
    
    public function clear() : Void
    {
        prev = null;
        next = null;
    }
    
    public function remove_from_list() : Void
    {
        prev.next = next;
        next.prev = prev;
        prev = null;
        next = null;
    }
    
    public function insert_before(next_:CMLListElem) : Void
    {
        next = next_;
        prev = next_.prev;
        next_.prev.next = this;
        next_.prev = this;
    }
    
    public function insert_after(prev_:CMLListElem) : Void
    {
        prev = prev_;
        next = prev_.next;
        prev_.next.prev = this;
        prev_.next = this;
    }
}



