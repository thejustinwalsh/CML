package org.si.cml.core;

/** interpolating calculation @private */
class Interpolation
{
    // variables
    //--------------------------------------------------
    public var P:Float = 0;
    public var Q:Float = 0;
    public var R:Float = 0;
    public var S:Float = 0;
    
    
    // constructor
    //--------------------------------------------------
    public function new()
    {
    }
    
    
    // calculation
    //--------------------------------------------------
    public function calc(t:Float) : Float
    {
        return ((P*t+Q)*t+R)*t+S;
    }
    
    
    // interpolation setting
    //--------------------------------------------------
    // linear interpolation
    public function setLinear(x0:Float, x1:Float) : Interpolation
    {
        P = 0;
        Q = 0;
        R = x1 - x0;
        S = x0;
        return this;
    }
    
    // 2-dimensional bezier interpolation
    public function setBezier2(x0:Float, x1:Float, p:Float) : Interpolation
    {
        P = 0;
        Q = x0+x1-p*2;
        R = (p-x0)*2;
        S = x0;
        return this;
    }
    
    // 3-dimensional bezier interpolation
    public function setBezier3(x0:Float, x1:Float, p0:Float, p1:Float) : Interpolation
    {
        P = -x0+(p0-p1)*3+x1;
        Q = (x0-p0*2+p1)*3;
        R = (-x0+p0)*3;
        S = x0;
        return this;
    }
    
    // ferguson-coons interpolation
    public function setFergusonCoons(x0:Float, x1:Float, v0:Float, v1:Float) : Interpolation
    {
        P = (x0-x1)*2+v0+v1;
        Q = -x0+x1-v0-P;
        R = v0;
        S = x0;
        return this;
    }
    
    // lagrange interpolation
    public function setLagrange(x0:Float, x1:Float, x2:Float, x3:Float) : Interpolation
    {
        P = x3-x2-x0+x1;
        Q = x0-x1-P;
        R = x2-x0;
        S = x1;
        return this;
    }
    
    // catmull-rom interpolation
    public function setCatmullRom(x0:Float, x1:Float, x2:Float, x3:Float) : Interpolation
    {
        P = (-x0+x1-x2+x3)*0.5+x1-x2;
        Q = x0+(x2-x1)*2-(x1+x3)*0.5;
        R = (x2-x0)*0.5;
        S = x1;
        return this;
    }
    
    // catmull-rom interpolation for starting point
    public function setCatmullRomStart(x1:Float, x2:Float, x3:Float) : Interpolation
    {
        P = 0;
        Q = (x1+x3)*0.5-x2;
        R = (x2-x1)*2+(x1-x3)*0.5;
        S = x1;
        return this;
    }
    
    // catmull-rom interpolation for line end
    public function setCatmullRomEnd(x0:Float, x1:Float, x2:Float) : Interpolation
    {
        P = 0;
        Q = (x0+x2)*0.5-x1;
        R = (x2-x0)*0.5;
        S = x1;
        return this;
    }
}

