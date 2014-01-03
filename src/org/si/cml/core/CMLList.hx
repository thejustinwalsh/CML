//--------------------------------------------------
// list structure for CML
//  Copyright (c) 2007 keim All rights reserved.
//  Distributed under BSD-style license (see license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.cml.core;    
    
/** @private */
class CMLList
{
    private var term:CMLListElem;
        
    public function new()
    {
        term = new CMLListElem();
        term.next = term;
        term.prev = term;
    }
    
    public function clear() : Void
    {
        term.next = term;
        term.prev = term;
    }
        
    public function remove(elem:CMLListElem) : CMLListElem
    {
        if (elem == term) return null;
        elem.remove_from_list();
        return elem;
    }

    public function unshift(elem:CMLListElem) : CMLListElem
    {
        elem.next = term.next;
        elem.prev = term;
        term.next.prev = elem;
        term.next      = elem;
        return elem;
    }
    
    public function shift() : CMLListElem
    {
        var elem:CMLListElem = term.next;
        if (elem == term) return null;
        term.next = elem.next;
        term.next.prev = term;
        elem.clear();
        return elem;
    }
    
    public function push(elem:CMLListElem) : CMLListElem
    {
        elem.prev = term.prev;
        elem.next = term;
        term.prev.next = elem;
        term.prev      = elem;
        return elem;
    }
        
    public function pop() : CMLListElem
    {
        var elem:CMLListElem = term.prev;
        if (elem == term) return null;
        term.prev = elem.prev;
        term.prev.next = term;
        elem.clear();
        return elem;
    }
    
    public function cut(start:CMLListElem, end:CMLListElem) : Void
    {
        end.next.prev = start.prev;
        start.prev.next = end.next;
        start.prev = null;
        end.next = null;
    }
    
    public function cat(list:CMLList) : Void
    {
        if (list.isEmpty()) return;
        list.head.prev = term.prev;
        list.tail.next = term;
        term.prev.next = list.head;
        term.prev      = list.tail;
        list.clear();
    }

    public var begin(get,null) : CMLListElem;
    public function get_begin() : CMLListElem
    {
        return term.next;
    }

    public var end(get,null) : CMLListElem;
    public function get_end() : CMLListElem
    {
        return term;
    }

    public var head(get,null) : CMLListElem;
    public function get_head() : CMLListElem
    {
        return term.next;
    }

    public var tail(get,null) : CMLListElem;
    public function get_tail() : CMLListElem
    {
        return term.prev;
    }
    
    public function isEmpty() : Bool
    {
        return (term.next == term);
    }
}


