//
//  OUTLINE_ITEM.h
//  PDFViewer
//
//  Created by Radaee on 13-1-20.
//  Copyright (c) 2013年 Radaee. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "PDFObjc.h"

@interface OUTLINE_ITEM : NSObject
@property(nonatomic,strong) NSString *label;
@property(nonatomic,strong) NSString *url;   // Custom JSON parameter
@property(nonatomic,strong) NSString *name;  // Custom JSON parameter
@property(nonatomic,strong) NSString *link;
@property(nonatomic,assign) int gen;         // Custom JSON parameter
@property(nonatomic,strong) NSMutableArray *childIndexes;
@property(nonatomic,assign) int dest;
@property(nonatomic,assign) int level;
@property(nonatomic,strong) RDPDFOutline *child;
@end
