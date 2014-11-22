//--------------------------------------------------------------------------------
// CMLMovieClip Scene management module
//--------------------------------------------------------------------------------


package org.si.b3;

import openfl._v2.geom.Matrix;
import openfl.display.BitmapDataChannel;
import openfl._v2.geom.ColorTransform;
import openfl._v2.Vector;
import openfl._v2.geom.Point;
import openfl.geom.Rectangle;
import openfl._v2.display.BitmapData;


/** CMLMovieClipTexture provides BitmapData for CMLMovieClip. */
class CMLMovieClipTexture {
// variables
//--------------------------------------------------
    /** source bitmap data */
    public var bitmapData:BitmapData;
    
    /** cutout rectangle */
    public var rect:Rectangle;
    /** texture center */
    public var center:Point;
    /** cutout bitmap data */
    public var cutoutBitmapData:BitmapData = null;
    /** alpha map */
    public var alphaMap:CMLMovieClipTexture = null;
    /** animation pattern */
    public var animationPattern:Vector<CMLMovieClipTexture> = null;
    
    
    
    
// properties
//--------------------------------------------------
    /** texture width */
    public var width(get,null) : Int;
    public function get_width() : Int { return Math.round(rect.width); }
    /** texture height */
    public var height(get,null) : Int;
    public function get_height() : Int { return Math.round(rect.height); }
    /** true if you want to use CMLMovieClip.draw() */
    public var drawable(get,set) : Bool;
    public function get_drawable() : Bool { return (cutoutBitmapData != null); }
    public function set_drawable(b:Bool) : Bool {
        if (cutoutBitmapData != null) {
            cutoutBitmapData.dispose();
            cutoutBitmapData = null;
        }
        if (b) {
            cutoutBitmapData = new BitmapData(Math.round(rect.width), Math.round(rect.height), bitmapData.transparent, 0);
            cutoutBitmapData.copyPixels(bitmapData, rect, new Point(0, 0));
        }
        if ((animationPattern != null) && animationPattern.length > 1) {
            var i:Int;
            for (i in 1...animationPattern.length) {
                animationPattern[i].drawable = b;
            }
        }
        return b;
    }
    /** animation count */
    public var animationCount(get,null) : Int;
    public function get_animationCount() : Int { return (animationPattern != null) ? animationPattern.length : 0; }
    
    
    
    
// constructor
//--------------------------------------------------
    /** constructor 
     *  @param bitmapData source texture
     *  @param texX x coordinate of left edge on source texture
     *  @param texY y coordinate of top edge on source texture
     *  @param texWidth texture width
     *  @param texHeight texture height
     *  @param drawable true to use CMLMovieClip.drawTexture()
     *  @param animationCount animation count
     *  @param areaWidth area width of animation sequence
     *  @param areaHeight area height of animation sequence
     *  @param columnPriority scanning direction of animation sequence, true for horizontal
     */
    public function new(bitmapData:BitmapData, texX:Int=0, texY:Int=0, texWidth:Int=0, texHeight:Int=0, drawable:Bool=false, animationCount:Int=1, areaWidth:Int=0, areaHeight:Int=0, columnPriority:Bool=true)
    {
        if (texWidth  == 0) texWidth  = bitmapData.width;
        if (texHeight == 0) texHeight = bitmapData.height;
        this.cutoutBitmapData = null;
        this.bitmapData = bitmapData;
        this.rect = new Rectangle(texX, texY, texWidth, texHeight);
        this.center = new Point(texWidth * 0.5, texHeight * 0.5);
        this.drawable = drawable;
        this.alphaMap = null;
        if (animationCount > 0) {
            animationPattern = new Vector<CMLMovieClipTexture>(animationCount, true);
            animationPattern[0] = this;
            
            if (animationCount > 1) {
                var x:Int = texX + texWidth, y:Int = texY, xmax:Int = texX + areaWidth - texWidth, ymax:Int = texY + areaHeight - texHeight;
                if (areaWidth == 0)  xmax = bitmapData.width  - texWidth;
                if (areaHeight == 0) ymax = bitmapData.height - texHeight;

                var i:Int;
                for (i in 1...animationCount) {
                    animationPattern[i] = new CMLMovieClipTexture(bitmapData, x, y, texWidth, texHeight, drawable, 0);
                    if (columnPriority) {
                        x += texWidth;
                        if (x > xmax) {
                            x = texX;
                            y += texHeight;
                        }
                    } else {
                        y += texHeight;
                        if (y > ymax) {
                            x += texWidth;
                            y = texY;
                        }
                    }
                }
            }
        }
    }
    
    
    /** cloning */
    public function clone() : CMLMovieClipTexture
    {
        var newTexture:CMLMovieClipTexture = new CMLMovieClipTexture(bitmapData,
                Math.round(rect.x), Math.round(rect.y),
                Math.round(rect.width), Math.round(rect.height));
        var i:Int;
        var imax:Int = animationCount;

        newTexture.cutoutBitmapData = cutoutBitmapData;
        newTexture.alphaMap = alphaMap;
        newTexture.center.x = center.x;
        newTexture.center.y = center.y;
        if(imax != 0) {
            newTexture.animationPattern = new Vector<CMLMovieClipTexture>(imax, true);
            newTexture.animationPattern[0] = newTexture;
            for (i in 1...imax) {
                newTexture.animationPattern[i] = animationPattern[i].clone();
            }
        }
        return newTexture;
    }
    
    
    /** cut out texture with scaling and rotation
     *  @param scaleX horizontal scaling factor
     *  @param scaleY vertical scaling factor
     *  @param angle rotation angle in degree
     *  @param colorTransform color transform
     *  @param backgroundColor bacground color
     *  @param margin margin around the result texture
     *  @return cut out texture. property "drawable" is true.
     */
    public function cutout(scaleX:Float=1, scaleY:Float=1, angle:Float=0, colorTransform:ColorTransform=null, backgroundColor:Int=0, margin:Int=0) : CMLMovieClipTexture
    {
        var newTexture:CMLMovieClipTexture = _cutout(scaleX, scaleY, angle, colorTransform, backgroundColor, margin);
        var i:Int, imax:Int = animationPattern.length;
        newTexture.animationPattern = new Vector<CMLMovieClipTexture>(imax, true);
        newTexture.animationPattern[0] = newTexture;
        for (i in 1...imax) {
            newTexture.animationPattern[i] = animationPattern[i]._cutout(scaleX, scaleY, angle, colorTransform, backgroundColor, margin);
        }
        return newTexture;
    }
    
    
    /** create rotate animation
     *  @param scaleX horizontal scaling factor
     *  @param scaleY vertical scaling factor
     *  @param minAngle start angle in degree
     *  @param maxAngle end angle in degree
     *  @param animationCount animation count 
     *  @param colorTransform color transform
     *  @param backgroundColor bacground color
     *  @param margin margin around the result texture
     *  @return animation sequence of cut out textures. property "drawable" is true.
     */
    public function createRotateAnimation(scaleX:Float=1, scaleY:Float=1, minAngle:Float=-180, maxAngle:Float=180, animationCount:Int=32, 
                                          colorTransform:ColorTransform=null, backgroundColor:Int=0, margin:Int=0) : CMLMovieClipTexture
    {
        var i:Int, step:Float = (maxAngle - minAngle) / animationCount, angle:Float = minAngle, patterns:Vector<CMLMovieClipTexture>;
        patterns = new Vector<CMLMovieClipTexture>(animationCount, true);
        for (i in 0...animationCount) {
            patterns[i] = _cutout(scaleX, scaleY, angle, colorTransform, backgroundColor, margin);
            angle+=step;
        }
        patterns[0].animationPattern = patterns;
        return patterns[0];
        
    }
    
    
    /** create alpha map 
     *  @param fillColor filling color
     */
    public function createAlphaMap(fillColor:Int=0xffffffff) : CMLMovieClipTexture
    {
        var alphaBitmap:BitmapData = new BitmapData(Math.round(rect.width), Math.round(rect.height), true, fillColor);
        alphaBitmap.copyChannel(bitmapData, rect, new Point(0, 0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
        alphaMap = new CMLMovieClipTexture(alphaBitmap, 0, 0, 0, 0, drawable);
        if ((animationPattern != null) && animationPattern.length > 1) {
            var i:Int;
            for (i in 1...animationPattern.length) {
                animationPattern[i].createAlphaMap(fillColor);
            }
        }
        return this;
    }
    
    
    private function _cutout(sx:Float, sy:Float, rot:Float, colt:ColorTransform, bg:Int, margin:Int) : CMLMovieClipTexture
    {
        var mat:Matrix = new Matrix(), srcx:Float, srcy:Float, srcxmin:Float ,srcymin:Float, srcxmax:Float ,srcymax:Float, 
            x:Int, y:Int, xmax:Int, ymax:Int, dst:BitmapData, ma:Float, mb:Float, mc:Float, md:Float, tx:Float, ty:Float;
        mat.translate(-center.x, -center.y);
        mat.scale(sx, sy);
        mat.rotate(rot * 0.017453292519943295);
        var lt:Point = mat.transformPoint(new Point(0, 0)),
            rt:Point = mat.transformPoint(new Point(rect.width, 0)),
            lb:Point = mat.transformPoint(new Point(0, rect.height)),
            rb:Point = mat.transformPoint(new Point(rect.width, rect.height)),
            dstrb:Point = new Point(_max4(lt.x, rt.x, lb.x, rb.x), _max4(lt.y, rt.y, lb.y, rb.y));
        xmax = Math.round(dstrb.x + margin + 0.9999847412109375) * 2;
        ymax = Math.round(dstrb.y + margin + 0.9999847412109375) * 2;
        dst = new BitmapData(xmax, ymax, bitmapData.transparent, bg);
        mat.translate(dst.width * 0.5, dst.height * 0.5);
        mat.invert();
        ma = mat.a;
        mb = mat.b;
        mc = mat.c;
        md = mat.d;
        tx = mat.tx + rect.x;
        ty = mat.ty + rect.y;
        srcxmin = rect.x;
        srcymin = rect.y;
        srcxmax = rect.x + rect.width;
        srcymax = rect.y + rect.height;
        for (x in 0...xmax)
        {
            for (y in 0...ymax) {
                srcx = x * ma + y * mc + tx;
                srcy = x * mb + y * md + ty;
                if (srcx>=srcxmin && srcx<srcxmax && srcy>=srcymin && srcy<srcymax) {
                    dst.setPixel32(x, y, bitmapData.getPixel32(Math.floor(srcx), Math.floor(srcy)));
                }
            }
        }
        if (colt != null) dst.colorTransform(dst.rect, colt);
        var ret:CMLMovieClipTexture = new CMLMovieClipTexture(dst, 0, 0, xmax, ymax, false, 0);
        ret.cutoutBitmapData = dst;
        return ret;
    }
    
    
    private function _min4(a:Float, b:Float, c:Float, d:Float) : Float {
        return (a < b) ? ((a < c) ? ((a < d) ? a : d) : ((c < d) ? c : d)) : ((b < c) ? ((b < d) ? b : d) : ((c < d) ? c : d));
    }
    
    
    private function _max4(a:Float, b:Float, c:Float, d:Float) : Float {
        return (a > b) ? ((a > c) ? ((a > d) ? a : d) : ((c > d) ? c : d)) : ((b > c) ? ((b > d) ? b : d) : ((c > d) ? c : d));
    }
}


