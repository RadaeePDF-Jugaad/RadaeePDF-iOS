//
//  VCache.m
//  RDPDFReader
//
//  Created by Radaee on 16/11/19.
//  Copyright © 2016年 radaee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDVCache.h"
#import "RDVGlobal.h"

@implementation RDVCache
@synthesize x = m_dibx;
@synthesize y = m_diby;
@synthesize w = m_dibw;
@synthesize h = m_dibh;
@synthesize pageno = m_pageno;
@synthesize thumbMode = m_thumb;

-(id)init:(RDPDFDoc *)doc :(int)pageno :(float) scale :(int)dibx :(int)diby :(int)dibw :(int)dibh;
{
    if( self = [super init] )
    {
        m_doc = doc;
        m_pageno = pageno;
        m_page = NULL;
        m_scale = scale;
        m_dibx = dibx;
        m_diby = diby;
        m_dibw = dibw;
        m_dibh = dibh;
        m_dib = NULL;
        m_status = 0;
        m_render = false;
        m_scale_pix = [[UIScreen mainScreen] scale];
    }
    return self;
}

-(RDVCache *)vClone
{
    RDVCache *vc = [[RDVCache alloc] init :m_doc :m_pageno :m_scale :m_dibx :m_diby :m_dibw :m_dibh];
    vc.thumbMode = m_thumb;
    return vc;
}

-(bool)vStart
{
    if(!m_render)
    {
        m_render = true;
        m_status = 0;
        return true;
    }
    else
        return false;
}

-(bool)vEnd
{
    if(m_render)
    {
        m_render = false;
        if(m_status <= 0) m_status = -1;
        if(m_page) [m_page renderCancel];
        return true;
    }
    else
        return false;
}

-(bool)vIsRenderFinished
{
    return (m_render && m_status > 0);
}

-(bool)vIsRendering
{
    return (m_render && m_status == 0);
}

-(void)vRender
{
    RDPDFDIB *dib = [[RDPDFDIB alloc] init :m_dibw :m_dibh];
    if(m_status < 0)
    {
        dib = NULL;
        return;
    }
    RDPDFPage *page = [m_doc page :m_pageno];
    [page renderPrepare :dib];
    if(m_status < 0) return;
    m_dib = dib;
    //if(!m_thumb) m_page = page;
    m_page = page;
    
    RDPDFMatrix *mat = [[RDPDFMatrix alloc] init :m_scale :-m_scale :-m_dibx :[m_doc pageHeight :m_pageno] * m_scale - m_diby];
    [page render :dib :mat :2];//always render best.
    mat = NULL;
    if(m_status >= 0) m_status = 1;
}

//the layer object must create and destroy on main thread.
-(void)vDestroyLayer
{
    if(m_layer)
    {
        [m_layer removeFromSuperlayer];
        m_layer.contents = nil;
        m_layer = nil;
    }
}

-(void)vDestroy;
{
    m_status = 0;
    m_page = nil;
    m_render = false;
    m_dib = nil;
}

-(CALayer *)ProLayer
{
    if(m_layer) return m_layer;
    if(![self vIsRenderFinished] || !m_dib) return nil;
    Byte *data = (Byte *)[m_dib data];
    int w = [m_dib width];
    int h = [m_dib height];
    m_layer = [[CALayer alloc] init];
    [m_layer removeAllAnimations];

    if (GLOBAL.g_dark_mode) {
        // Invert the rendered page's pixels in place so the page content reads
        // as a dark background/light text without touching the app's own UI.
        for(int ay = 0; ay < h; ay++)
        {
            unsigned char *linePointer = &data[ay * w * 4];
            for(int ax = 0; ax < w; ax++)
            {
                // Premultiplied alpha: divide out the alpha channel before
                // inverting, then re-multiply back in.
                int r, g, b;
                if(linePointer[3])
                {
                    r = linePointer[0] * 255 / linePointer[3];
                    g = linePointer[1] * 255 / linePointer[3];
                    b = linePointer[2] * 255 / linePointer[3];
                }
                else
                    r = g = b = 0;

                r = 255 - r;
                g = 255 - g;
                b = 255 - b;

                linePointer[0] = r * linePointer[3] / 255;
                linePointer[1] = g * linePointer[3] / 255;
                linePointer[2] = b * linePointer[3] / 255;
                linePointer += 4;
            }
        }
    }

    CGDataProviderRef provider = CGDataProviderCreateWithData( NULL, data, w * h * 4, NULL );
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGImageRef img = CGImageCreate( w, h, 8, 32, w<<2, cs,
        kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipFirst,
        provider, NULL, FALSE, kCGRenderingIntentDefault );
    CGColorSpaceRelease(cs);
    CGDataProviderRelease(provider);
    
    if(img)
    {
        m_layer.contents = (__bridge id)img;
        CGImageRelease(img);
        //m_dib = nil;
    }
    else
        m_layer = nil;
    return m_layer;
}

//the layer object must create and destroy on main thread.
-(void)vDraw :(CALayer *)canvas
{
    if(m_layer) return;//already tiled.
    if([self ProLayer])//just finished
    {
        float scale_mul = 1.0f/m_scale_pix;
        m_layer.frame = CGRectMake(scale_mul * m_dibx, scale_mul * m_diby, scale_mul * m_dibw, scale_mul * m_dibh);
        [canvas addSublayer:m_layer];
    }
}

-(void)vDrawZoom :(CALayer *)parent :(float)scale
{
    float scale_mul = scale / (m_scale_pix * m_scale);
    CGRect rect = CGRectMake(scale_mul * m_dibx,
                             scale_mul * m_diby,
                             scale_mul * m_dibw,
                             scale_mul * m_dibh);
    if(m_layer)
    {
        m_layer.frame = rect;
    }
    else if([self ProLayer])//just finished
    {
        m_layer.frame = rect;
        [parent addSublayer:m_layer];
    }
}

-(void)dealloc
{
    [self vDestroyLayer];
    [self vDestroy];
    m_doc = NULL;
}
@end


@implementation RDVCacheSet
@synthesize cols = m_cols;
@synthesize rows = m_rows;
-init
{
    if( self = [super init] )
    {
        m_dat = NULL;
        m_cols = 0;
        m_rows = 0;
    }
    return self;
}

-(id)init :(int)cols :(int) rows
{
    if( self = [super init] )
    {
        m_dat = [[NSMutableArray alloc] initWithCapacity :cols];
        int col;
        for(col = 0; col < cols; col++)
        {
            NSMutableArray *colo = [[NSMutableArray alloc] initWithCapacity :rows];
            [m_dat setObject:colo atIndexedSubscript:col];
            //[m_dat addObject:colo];
        }
        m_cols = cols;
        m_rows = rows;
    }
    return self;
}
-(void)dealloc
{
    m_dat = nil;
    m_cols = 0;
    m_rows = 0;
}

-(RDVCache *)get :(int)col :(int) row
{
    NSMutableArray *colo = (NSMutableArray *)[m_dat objectAtIndex :col];
    return (RDVCache *)[colo objectAtIndex :row];
}
                                             
-(void)set :(int)col :(int) row :(RDVCache *)cache
{
    NSMutableArray *colo = (NSMutableArray *)[m_dat objectAtIndex :col];
    [colo setObject:cache atIndexedSubscript:row];
    //[colo replaceObjectAtIndex :row withObject:cache];
}

@end

