//
//  MUSEditorPreferencesViewController.swift
//  MacDown
//
//  Created by Foster Yin on 7/23/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

import Foundation

class MUSEditorPreferencesViewController : MUSPreferencesViewController, MASPreferencesViewController, NSTextFieldDelegate
{
    @IBOutlet var fontPreviewField:NSTextField!

    @IBOutlet var themeSelect:NSPopUpButton!

    @IBOutlet var themeFunctions:NSSegmentedControl!


    init()
    {
        super.init()
    }
    
    override var identifier:String! {
    get {
        return "EditorPreferences"
    }
    set {

    }
    }

    var toolbarItemImage:NSImage {
    get {
        return NSImage(named:NSImageNameFontPanel);
    }
    set {

    }
    }

    var toolbarItemLabel:String {
    get {
        return NSLocalizedString("Editor", comment: "Preference pane title.")
    }
    set {
        
    }
    }

    override func viewWillAppear()
    {
        refreshPreviewForFont(self.preferences.editorBaseFont.copy() as NSFont)
        loadThemes()
    }

    func refreshPreviewForFont(font:NSFont)
    {
        let text = "\(font.displayName) - \(font.pointSize)"
        fontPreviewField.stringValue = text
        fontPreviewField.font = font
    }

    func loadThemes()
    {
        themeSelect.enabled = false
        themeSelect.removeAllItems()

        let itemTitles = MPListEntriesForDirectory(kMPThemesDirectoryName, MPFileNameHasSuffixProcessor(kMPThemeFileExtension))

        themeSelect.addItemWithTitle("")
        themeSelect.addItemsWithTitles(itemTitles)

        let title = self.preferences.editorStyleName.copy() as? String
        if (title)
        {
            themeSelect.selectItemWithTitle(title)
        }

        themeSelect.enabled = true
    }


    override func changeFont(sender: AnyObject!)
    {
        let font = (sender as NSFontManager).convertFont((sender as NSFontManager).selectedFont)
        refreshPreviewForFont(font)
        self.preferences.editorBaseFont = font
    }


    func control(control: NSControl!, textShouldEndEditing fieldEditor: NSText!) -> Bool
    {
        if (!fieldEditor.string)
        {
            fieldEditor.string = "0"
        }
        return true
    }

    @IBAction func showFontPanel(sender:AnyObject!)
    {
        let manager = NSFontManager.sharedFontManager()
        manager.target = self
        manager.action = NSSelectorFromString("changeFont:")
        manager.setSelectedFont(self.preferences.editorBaseFont, isMultiple: false)

        let panel = manager.fontPanel(true)
        panel.orderFront(sender)
    }

    @IBAction func changeTheme(sender: AnyObject!)
    {
        let title = (sender as NSPopUpButton).selectedItem.title

        if (title)
        {
            self.preferences.editorStyleName = title
        }
        else
        {
            self.preferences.editorStyleName = nil
        }
    }

    @IBAction func invokeStylesheetFunction(sender: AnyObject!)
    {
        switch ((sender as NSSegmentedControl).selectedSegment)
            {
        case 0:
                let dirPath = MPDataDirectory(kMPThemesDirectoryName)
                let url = NSURL.fileURLWithPath(dirPath)
                NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs([url])

        case 1:

                loadThemes()

        default:
                break
        }
    }
}