//
//  MUSWebView.h
//  MacDown
//
//  Created by Foster Yin on 7/3/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@protocol MUSPreviewDelegate <NSObject>

- (void)previewNeedSyncScroller:(WebView *)webView;

@end


@interface MUSPreviewWebView : WebView

@property (nonatomic) BOOL previewFlushDisabled;

@property (nonatomic) BOOL isLoadingPreview;

@property (nonatomic, weak) id<MUSPreviewDelegate> previewDelegate;

@end
