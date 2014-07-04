//
//  MUSHoedownHelper.m
//  MacDown
//
//  Created by Foster Yin on 7/4/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

#import "MUSHoedownHelper.h"
#import <hoedown/html.h>
#import <hoedown/markdown.h>
#import "hoedown_html_patch.h"

static hoedown_buffer *language_addition(const hoedown_buffer *language,
                                         void *owner)
{
    NSObject* renderer = (__bridge NSObject *)owner;
    NSString *lang = [[NSString alloc] initWithBytes:language->data
                                              length:language->size
                                            encoding:NSUTF8StringEncoding];

    static NSDictionary *aliasMap = nil;
    static NSDictionary *dependencyMap = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        aliasMap = @{@"objective-c": @"objectivec",
                     @"obj-c": @"objectivec", @"objc": @"objectivec",
                     @"html": @"markup", @"xml": @"markup"};
        dependencyMap = @{
                          @"aspnet": @"markup", @"bash": @"clike", @"c": @"clike",
                          @"coffeescript": @"javascript", @"cpp": @"c", @"csharp": @"clike",
                          @"go": @"clike", @"groovy": @"clike", @"java": @"clike",
                          @"javascript": @"clike", @"objectivec": @"c", @"php": @"clike",
                          @"ruby": @"clike", @"scala": @"java", @"scss": @"css",
                          @"swift": @"clike",
                          };
    });

    // Try to identify alias and point it to the "real" language name.
    hoedown_buffer *mapped = NULL;
    if ([aliasMap objectForKey:lang])
    {
        lang = [aliasMap objectForKey:lang];
        NSData *data = [lang dataUsingEncoding:NSUTF8StringEncoding];
        mapped = hoedown_buffer_new(64);
        hoedown_buffer_put(mapped, data.bytes, data.length);
    }

    // Walk dependencies to include all required scripts.
    NSMutableArray *languages = nil;

    if ([renderer respondsToSelector:NSSelectorFromString(@"currentLanguages")])
    {
        languages = [renderer performSelector:NSSelectorFromString(@"currentLanguages") withObject:nil];
    }

    while (lang)
    {
        NSUInteger index = [languages indexOfObject:lang];
        if (index != NSNotFound)
            [languages removeObjectAtIndex:index];
        [languages insertObject:lang atIndex:0];
        lang = dependencyMap[lang];
    }

    return mapped;
}


void setupHtmlRendererWithOwner(hoedown_renderer *htmlRenderer, void *owner)
{
    if (htmlRenderer)
    {
        htmlRenderer->blockcode = hoedown_patch_render_blockcode;

        rndr_state_ex *state = malloc(sizeof(rndr_state_ex));
        memcpy(state, htmlRenderer->opaque, sizeof(rndr_state));
        state->language_addition = language_addition;
        state->owner = owner;
        
        free(htmlRenderer->opaque);
        htmlRenderer->opaque = state;
    }
    
}


void cleanHtmlRenderer(hoedown_renderer *htmlRenderer)
{
    if (htmlRenderer)
    {
        hoedown_html_renderer_free(htmlRenderer);
    }
}
