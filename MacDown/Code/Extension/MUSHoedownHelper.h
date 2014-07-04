//
//  MUSHoedownHelper.h
//  MacDown
//
//  Created by Foster Yin on 7/4/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hoedown/markdown.h>


void setupHtmlRendererWithOwner(hoedown_renderer *htmlRenderer, void *owner);

void cleanHtmlRenderer(hoedown_renderer *htmlRenderer);