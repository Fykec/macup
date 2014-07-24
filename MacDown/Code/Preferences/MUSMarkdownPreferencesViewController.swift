//
//  MUSMarkdownPreferencesViewController.swift
//  MacDown
//
//  Created by Foster Yin on 7/23/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

import Foundation
import AppKit

class MUSMarkdownPreferencesViewController : MUSPreferencesViewController, MASPreferencesViewController
{

    //http://pastebin.com/ErTLF5nz

//    var viewIdentifier: NSString! = "MarkdownPreferences"
//    var toolbarItemImage: NSImage! = NSImage(named: "MarkdownPreferences")
//    var toolbarItemLabel: NSString! =  NSLocalizedString("Markdown", comment: "Preference pane title.")

    init()
    {
        super.init()
    }
    
    override var identifier:String! {
    get {
        return "MarkdownPreferences"
    }
    set {

    }
    }

    var toolbarItemImage:NSImage {
    get {
        return NSImage(named:"MarkdownPreferences");
    }
    set {

    }
    }

    var toolbarItemLabel:String {
    get {
        return NSLocalizedString("Markdown", comment: "Preference pane title.")
    }
    set {
        
    }
    }

}