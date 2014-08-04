//
//  MUSPreferences.swift
//  MacDown
//
//  Created by Foster Yin on 7/24/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

import Foundation

let MUSDidDetectFreshInstallationNotification = "MUSDidDetectFreshInstallationNotification"

class MUSPreferences : PAPreferences
{

    let kMUSDefaultEditorFontNameKey = "name"
    let kMUSDefaultEditorFontPointSizeKey = "size"
    let kMUSDefaultEditorFontName = "Menlo-Regular"
    let kMUSDefaultEditorFontPointSize:CGFloat = 14.0
    let kMUSDefaultEditorHorizontalInset:CGFloat = 15.0
    let kMUSDefaultEditorVerticalInset:CGFloat = 30.0
    let kMUSDefaultEditorLineSpacing:CGFloat = 3.0
    let kMUSDefaultEditorSyncScrolling = true
    let kMUSDefaultEditorThemeName = "Tomorrow+"
    let kMUSDefaultHtmlStyleName = "GitHub2"


    dynamic var firstVersionInstalled:String?

    dynamic var latestVersionInstalled:String?

    dynamic var extensionIntraEmphasis:Bool = false
    dynamic var extensionTables:Bool = false
    dynamic var extensionFencedCode:Bool = false
    dynamic var extensionAutolink:Bool = false
    dynamic var extensionStrikethough:Bool = false
    dynamic var extensionUnderline:Bool = false
    dynamic var extensionSuperscript:Bool = false
    dynamic var extensionHighlight:Bool = false
    dynamic var extensionFootnotes:Bool = false
    dynamic var extensionQuote:Bool = false
    dynamic var extensionSmartyPants:Bool = false


    dynamic var markdownManualRender:Bool = false

    dynamic var editorBaseFontInfo:Dictionary<String, NSObject>?

    dynamic var editorConvertTabs:Bool = false
    dynamic var editorCompleteMatchingCharacters:Bool = false
    dynamic var editorSyncScrolling:Bool = false
    dynamic var editorStyleName:String?
    dynamic var editorHorizontalInset:CGFloat = 0.0
    dynamic var editorVerticalInset:CGFloat = 0.0
    dynamic var editorLineSpacing:CGFloat = 0.0

    dynamic var htmlStyleName:String?
    dynamic var htmlMathJax:Bool = false
    dynamic var htmlSyntaxHighlighting:Bool = false
    dynamic var htmlHighlightingThemeName:String?
    dynamic var htmlDefaultDirectoryUrl:NSURL?

    var editorBaseFont:NSFont?
    {
    get {
        let info = self.editorBaseFontInfo!
        let name = info[kMUSDefaultEditorFontNameKey] as AnyObject! as String!
        let size:NSNumber = info[kMUSDefaultEditorFontPointSizeKey] as AnyObject! as NSNumber
        return NSFont(name:name, size: CGFloat(size.floatValue))
    }
    set {
        let newFont = newValue!
        self.editorBaseFontInfo = [kMUSDefaultEditorFontNameKey: newFont.fontName, kMUSDefaultEditorFontPointSizeKey: NSNumber(float:  Float(kMUSDefaultEditorFontPointSize))]
    }
    }

    init()
    {
        super.init()

        let version = NSBundle.mainBundle().infoDictionary["CFBundleVersion"]  as AnyObject!  as String
        if (!self.firstVersionInstalled)
        {
            self.firstVersionInstalled = version
            self.loadDefaultPreferences()

            NSOperationQueue.mainQueue().addOperationWithBlock({
                NSNotificationCenter.defaultCenter().postNotificationName(MUSDidDetectFreshInstallationNotification, object: self)
                })

        }
        self.latestVersionInstalled = version
    }

    func loadDefaultPreferences()
    {
        self.extensionIntraEmphasis = true
        self.extensionTables = true
        self.extensionFencedCode = true
        self.extensionFootnotes = true
        let defaultFontSize = NSNumber(float:  Float(kMUSDefaultEditorFontPointSize))
        let defaultFontDic = [kMUSDefaultEditorFontNameKey:kMUSDefaultEditorFontName, kMUSDefaultEditorFontPointSizeKey: defaultFontSize]
        self.editorBaseFontInfo = defaultFontDic
        self.editorStyleName = kMUSDefaultEditorThemeName
        self.editorHorizontalInset = kMUSDefaultEditorHorizontalInset
        self.editorVerticalInset = kMUSDefaultEditorVerticalInset
        self.editorLineSpacing = kMUSDefaultEditorLineSpacing
        self.editorSyncScrolling = kMUSDefaultEditorSyncScrolling
        self.htmlStyleName = kMUSDefaultHtmlStyleName
        self.htmlDefaultDirectoryUrl = NSURL.fileURLWithPath(NSHomeDirectory(), isDirectory: true)
    }
}