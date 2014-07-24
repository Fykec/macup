//
//  MUSHtmlPreferencesViewController.swift
//  MacDown
//
//  Created by Foster Yin on 7/23/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

import Foundation


class MUSHtmlPreferencesViewController : MUSPreferencesViewController, MASPreferencesViewController
{
    let MUSPrismDefaultThemeName = NSLocalizedString("(Default)", comment: "Prism theme title")

    @IBOutlet var stylesheetSelect:NSPopUpButton!

    @IBOutlet var stylesheetFunctions:NSSegmentedControl!

    @IBOutlet var highlightingThemeSelect:NSPopUpButton!


    init()
    {
        super.init()
    }


    override var identifier:String! {
    get {
        return "HtmlPreferences"
    }
    set {

    }
    }

    var toolbarItemImage:NSImage {
    get {
        return NSImage(named:NSImageNameColorPanel);
    }
    set {

    }
    }

    var toolbarItemLabel:String {
    get {
        return NSLocalizedString("Rendering", comment: "Preference pane title.")
    }
    set {
        
    }
    }

    override func viewWillAppear()
    {
        loadStylesheets()
        loadHighlithtingThemes()
    }


    @IBAction func changeStylesheet(sender: AnyObject!)
    {
        let title = (sender as NSPopUpButton).selectedItem.title

        if (title)
        {
            self.preferences.htmlStyleName = title
        }
        else
        {
            self.preferences.htmlStyleName = nil
        }
    }

    @IBAction func changeHighlightingTheme(sender: AnyObject!)
    {
        let title = (sender as NSPopUpButton).selectedItem.title

        if (title == self.MUSPrismDefaultThemeName)
        {
            self.preferences.htmlHighlightingThemeName = ""
        }
        else
        {
            self.preferences.htmlHighlightingThemeName = title
        }
    }

    @IBAction func invokeStylesheetFunction(sender :AnyObject!)
    {
        switch ((sender as NSSegmentedControl).selectedSegment)
            {
        case 0:
            let dirPath = MPDataDirectory(kMPStylesDirectoryName)
            let url = NSURL.fileURLWithPath(dirPath)
            NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs([url])

        case 1:

            loadStylesheets()

        default:
            break
        }

    }

    func loadStylesheets()
    {
        stylesheetSelect.enabled = false
        self.stylesheetSelect.removeAllItems()

        let itemTitles = MPListEntriesForDirectory(kMPStylesDirectoryName, MPFileNameHasSuffixProcessor(kMPStyleFileExtension))

        stylesheetSelect.addItemWithTitle("")
        stylesheetSelect.addItemsWithTitles(itemTitles)

        let title = self.preferences.htmlStyleName.copy() as? String
        if (title)
        {
            stylesheetSelect.selectItemWithTitle(title)
        }

        stylesheetSelect.enabled = true
        
    }

    func loadHighlithtingThemes()
    {
        highlightingThemeSelect.enabled = false
        highlightingThemeSelect.removeAllItems()

        let bundle = NSBundle.mainBundle()
        let urls = bundle.URLsForResourcesWithExtension("css", subdirectory: "Prism/themes")

        var titles = [String]()

        for url in urls
        {
            var name:String = url.lastPathComponent
            if (countElements(name) - 10 < 0)
            {
                continue
            }
            name = name.substring(6, length: countElements(name) - 10)
            titles.append(name.capitalizedString)
        }

        highlightingThemeSelect.addItemWithTitle(MUSPrismDefaultThemeName)
        highlightingThemeSelect.addItemsWithTitles(titles)

        let currentName = self.preferences.htmlHighlightingThemeName
        if (currentName)
        {
            highlightingThemeSelect.selectItemWithTitle(currentName)
        }

        if (self.preferences.htmlSyntaxHighlighting)
        {
            self.highlightingThemeSelect.enabled = true
        }
    }

}