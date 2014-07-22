//
//  MUSHoedownHelper.h
//  MacDown
//
//  Created by Foster Yin on 7/4/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hoedown/markdown.h>

//swift do not support function pointer, so put the code in this helper
//http://stackoverflow.com/questions/24088312/does-swift-not-work-with-function-pointers
void setupHtmlRendererWithOwner(hoedown_renderer *htmlRenderer, void *owner);

void cleanHtmlRenderer(hoedown_renderer *htmlRenderer);