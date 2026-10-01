//
//  VGlobal.h
//  RDPDFReader
//
//  Created by Radaee on 16/11/19.
//  Copyright © 2016年 radaee. All rights reserved.
//
#pragma once
#import <pthread.h>
#import "PDFObjc.h"

#define GLOBAL [RDVGlobal sharedInstance]
#define RD_COLOR [UIColor colorWithRed:(float)255/255 green:(float)149/255 blue:(float)0/255 alpha:1.0]
#define RD_TEXT_BLACK [UIColor colorWithRed:(float)27/255 green:(float)36/255 blue:(float)42/255 alpha:1.0]
#define RD_TEXT_GRAY [UIColor colorWithRed:(float)124/255 green:(float)124/255 blue:(float)124/255 alpha:1.0]
#define RD_BACKGROUND_GRAY [UIColor colorWithRed:(float)244/255 green:(float)244/255 blue:(float)244/255 alpha:1]
#define RD_DISABLED_BUTTON_GRAY [UIColor colorWithRed:(float)124/255 green:(float)124/255 blue:(float)124/255 alpha:1.0]
#define RD_FONT(x) ([UIFont fontWithName:@"PublicSans-Regular" size:x] ?: [UIFont systemFontOfSize:x])
#define RD_FONT_BOLD(x) ([UIFont fontWithName:@"PublicSans-Bold" size:x] ?: [UIFont boldSystemFontOfSize:x])
#define RD_TITLE_FONT(x) ([UIFont fontWithName:@"TekneLDO-Regular" size:x] ?: [UIFont systemFontOfSize:x])
#define RD_TITLE_FONT_BOLD(x) ([UIFont fontWithName:@"TekneLDO-Bold" size:x] ?: [UIFont systemFontOfSize:x])

extern NSString *g_serial;

@interface RDVLocker :NSObject
{
    pthread_mutex_t mutex;
}
-(void)lock;
-(void)unlock;
@end

@interface RDVEvent :NSObject
{
    unsigned int flags;
    pthread_cond_t m_event;
    pthread_mutex_t mutex;
}
-(void)reset;
-(void)notify;
-(void)wait;
@end

@interface RDVGlobal :NSObject

@property (strong, nonatomic) NSString *g_custom_button_name;

@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSMutableString *pdfName;
@property (strong, nonatomic) NSMutableString *pdfPath;
@property (strong, nonatomic) NSString *g_author;

@property (nonatomic) uint g_rect_color;
@property (nonatomic) uint g_line_color;
@property (nonatomic) uint g_ink_color;
@property (nonatomic) uint g_sel_color;
@property (nonatomic) uint g_oval_color;
@property (nonatomic) uint g_rect_fill_color;
@property (nonatomic) uint g_oval_fill_color;

@property (nonatomic) bool g_case_sensitive;
@property (nonatomic) bool g_match_whole_word;
@property (nonatomic) bool g_screen_awake;
@property (nonatomic) bool g_dark_mode;
@property (nonatomic) bool g_save_doc;
@property (nonatomic) bool g_show_outline_sidebar;

@property (nonatomic) float g_ink_width;
@property (nonatomic) float g_rect_width;
@property (nonatomic) float g_line_width;
@property (nonatomic) float g_oval_width;
@property (nonatomic) float g_swipe_speed;
@property (nonatomic) float g_swipe_distance;

@property (nonatomic) int g_line_style_start;
@property (nonatomic) int g_line_style_end;

@property (nonatomic) int g_render_mode;
@property (nonatomic) float g_zoom_level;
@property (nonatomic) bool g_static_scale;
@property (nonatomic) bool g_paging_enabled;
@property (nonatomic) bool g_double_page_enabled;
@property (nonatomic) bool g_curl_enabled;
@property (nonatomic) bool g_cover_page_enabled;
@property (nonatomic) bool g_fit_signature_to_field;
@property (nonatomic) bool g_execute_annot_JS;
@property (nonatomic) bool g_annot_lock;
@property (nonatomic) bool g_annot_readonly;
@property (nonatomic) bool g_auto_launch_link;
@property (nonatomic) bool g_enable_fab;
@property (nonatomic) bool g_enable_double_tap;
@property (nonatomic) bool g_highlight_annotation;

@property (nonatomic) uint g_annot_highlight_clr;
@property (nonatomic) uint g_annot_underline_clr;
@property (nonatomic) uint g_annot_strikeout_clr;
@property (nonatomic) uint g_annot_squiggly_clr;

@property (nonatomic) CGFloat g_floatingbutton_alpha;

@property (nonatomic) bool g_zoomed_stop_on_boundaries;
@property (nonatomic) bool g_layout_rtol;

// DOCX viewer (DOCXLayout, Premium only)
@property (nonatomic) int g_view_mode;
@property (nonatomic) float g_tap_zoom_level;
@property (nonatomic) float g_layout_zoom_level;
@property (nonatomic) float g_zoom_step;
@property (nonatomic) bool g_auto_scale;
@property (nonatomic) uint g_readerview_bg_color;
@property (nonatomic) uint g_find_primary_color;
@property (nonatomic) uint g_find_secondary_color;

+ (RDVGlobal *)sharedInstance;
+ (void)Init;

- (void)setup;

@end

