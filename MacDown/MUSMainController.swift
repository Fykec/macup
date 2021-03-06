//
//  MUSMainController.swift
//  MacDown
//
//  Created by Foster Yin on 6/27/14.
//  Copyright (c) 2014 Foster Yin . All rights reserved.
//

import Foundation

func initPreferencesWindowController() -> MASPreferencesWindowController
{
    let vcs:NSArray = [MUSMarkdownPreferencesViewController(),
        MUSEditorPreferencesViewController(),
        MUSHtmlPreferencesViewController()]
    let title:NSString =  NSLocalizedString("Preferences", comment: "Preferences window title.")
    return MASPreferencesWindowController(viewControllers: vcs, title:title)
}

class MUSMainController : NSObject
{

    var prefereces:MUSPreferences {
    get {
        return MUSPreferences.sharedInstance()
    }
    }

    var preferencesWindowController:MASPreferencesWindowController!

    @IBAction func showPreferencesWindow(sender:AnyObject!) {
        if (!preferencesWindowController)
        {
            preferencesWindowController = initPreferencesWindowController()
        }
        preferencesWindowController.showWindow(nil)
    }

    @IBAction func showHelp(sender:AnyObject) {
        let c:NSDocumentController = NSDocumentController.sharedDocumentController() as NSDocumentController
        let source:NSURL = NSBundle.mainBundle().URLForResource("help", withExtension: "md")
        let target:NSURL = NSURL.fileURLWithPathComponents([NSTemporaryDirectory(), "help.md"])

        var ok = false

        let manager:NSFileManager = NSFileManager.defaultManager()

        manager.removeItemAtURL(target, error: nil)
        ok = manager.copyItemAtURL(source, toURL: target, error: nil)
        if (ok)
        {
            c.openDocumentWithContentsOfURL(target, display: true, completionHandler:{ (document: NSDocument!, wasOpen: Bool, error: NSError!) -> Void in
                //check
                let frame:NSRect = NSScreen.mainScreen().visibleFrame

                for  wc in (document.windowControllers as [NSWindowController])
                {
                    wc.window.setFrame(frame, display:true)
                }
                })
        }
    }

    init()
    {
        super.init()

        let vcs:NSArray = [MUSMarkdownPreferencesViewController(),
            MUSEditorPreferencesViewController(),
            MUSHtmlPreferencesViewController()]
        let title =  NSLocalizedString("Preferences", comment: "Preferences window title.")
        preferencesWindowController = MASPreferencesWindowController(viewControllers: vcs, title:title)

        let center:NSNotificationCenter = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "showFirstLaunchTips", name: MUSDidDetectFreshInstallationNotification, object: nil)
        self.copyFiles()


    }

    func copyFiles()
    {
        let manager:NSFileManager = NSFileManager.defaultManager()
        let root:NSString = MUSDataDirectory(nil)
        if (manager.fileExistsAtPath(root))
        {
            return
        }

        manager.createDirectoryAtPath(root
            , withIntermediateDirectories: true, attributes: nil, error: nil)
        let bundle:NSBundle = NSBundle.mainBundle()
        var target:NSURL = NSURL.fileURLWithPath(MUSDataDirectory(kMUSStylesDirectoryName))
        if (!manager.fileExistsAtPath(target.path))
        {
            let source:NSURL = bundle.URLForResource("Styles", withExtension: "")
            manager.copyItemAtURL(source, toURL: target, error: nil)
        }
        target = NSURL.fileURLWithPath(MUSDataDirectory(kMUSThemesDirectoryName))
        if (!manager.fileExistsAtPath(target.path))
        {
            let source:NSURL = bundle.URLForResource("Themes", withExtension: "")
            manager.copyItemAtURL(source, toURL: target, error: nil)
        }

    }

    func showFirstLaunchTips()
    {
        //check
        self.showHelp("")
    }
}
