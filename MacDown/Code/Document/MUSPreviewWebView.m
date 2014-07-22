//
//  MUSWebView.m
//  MacDown
//
//  Created by Foster Yin on 7/3/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

#import "MUSPreviewWebView.h"

@implementation MUSPreviewWebView


- (instancetype)initWithFrame:(NSRect)frame frameName:(NSString *)frameName groupName:(NSString *)groupName
{
    self = [super initWithFrame:frame frameName:frameName groupName:groupName];
    if (self)
    {
        self.frameLoadDelegate = self;
        self.policyDelegate = self;

    }
    return self;
}


- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
    if (!self.previewFlushDisabled && sender.window)
    {
        self.previewFlushDisabled = YES;
        [sender.window disableFlushWindow];
    }
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    self.isLoadingPreview = NO;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.previewFlushDisabled)
        {
            [sender.window enableFlushWindow];
            self.previewFlushDisabled = NO;
        }
        [self.previewDelegate previewNeedSyncScroller:self];
    }];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error
       forFrame:(WebFrame *)frame
{
    [self webView:sender didFinishLoadForFrame:frame];
}


#pragma mark - WebPolicyDelegate

- (void)webView:(WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)information
        request:(NSURLRequest *)request frame:(WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener
{
    if (self.isLoadingPreview)
    {
        // We are rendering ourselves.
        [listener use];
    }
    else
    {
        // An external location is requested. Hijack.
        [listener ignore];
        [[NSWorkspace sharedWorkspace] openURL:request.URL];
    }
}


@end
