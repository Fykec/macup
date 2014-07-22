//
//  MUSDocument.swift
//  MacDown
//
//  Created by Foster Yin on 6/30/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

import Foundation

enum MUS_HOEDOWN_EXTENSIONS: CInt {
    case HOEDOWN_EXT_NO_INTRA_EMPHASIS = 1,
    HOEDOWN_EXT_TABLES = 2,
    HOEDOWN_EXT_FENCED_CODE = 4,
    HOEDOWN_EXT_AUTOLINK = 8,
    HOEDOWN_EXT_STRIKETHROUGH = 16,
    HOEDOWN_EXT_UNDERLINE = 32,
    HOEDOWN_EXT_SPACE_HEADERS = 64,
    HOEDOWN_EXT_SUPERSCRIPT = 128,
    HOEDOWN_EXT_LAX_SPACING = 256,
    HOEDOWN_EXT_DISABLE_INDENTED_CODE = 512,
    HOEDOWN_EXT_HIGHLIGHT = 1024,
    HOEDOWN_EXT_FOOTNOTES = 2018,
    HOEDOWN_EXT_QUOTE = 4036
};

extension MPPreferences {

    //Hoedown
    func extensionFlags() -> CInt
    {
        var flags:CInt = MUS_HOEDOWN_EXTENSIONS.HOEDOWN_EXT_LAX_SPACING.toRaw()
        if (self.extensionAutolink)
        {
            flags |= MUS_HOEDOWN_EXTENSIONS.HOEDOWN_EXT_AUTOLINK.toRaw()
        }
        if (self.extensionFencedCode)
        {
            flags |= MUS_HOEDOWN_EXTENSIONS.HOEDOWN_EXT_FENCED_CODE.toRaw()
        }
        if (self.extensionFootnotes)
        {
            flags |= MUS_HOEDOWN_EXTENSIONS.HOEDOWN_EXT_FOOTNOTES.toRaw()
        }
        if (self.extensionHighlight)
        {
            flags |= MUS_HOEDOWN_EXTENSIONS.HOEDOWN_EXT_HIGHLIGHT.toRaw()
        }
        if (self.extensionIntraEmphasis)
        {
            flags |= MUS_HOEDOWN_EXTENSIONS.HOEDOWN_EXT_NO_INTRA_EMPHASIS.toRaw()
        }
        if (self.extensionQuote)
        {
            flags |= MUS_HOEDOWN_EXTENSIONS.HOEDOWN_EXT_QUOTE.toRaw()
        }
        if (self.extensionStrikethough)
        {
            flags |= MUS_HOEDOWN_EXTENSIONS.HOEDOWN_EXT_STRIKETHROUGH.toRaw()
        }
        if (self.extensionSuperscript)
        {
            flags |= MUS_HOEDOWN_EXTENSIONS.HOEDOWN_EXT_SUPERSCRIPT.toRaw()
        }
        if (self.extensionTables)
        {
            flags |= MUS_HOEDOWN_EXTENSIONS.HOEDOWN_EXT_TABLES.toRaw()
        }
        if (self.extensionUnderline)
        {
            flags |= MUS_HOEDOWN_EXTENSIONS.HOEDOWN_EXT_UNDERLINE.toRaw()
        }

        return flags
    }
}

//http://stackoverflow.com/questions/24274533/xcode-6-swift-nstextviewdelegate-compile-error
class TextViewDelegate: NSObject
{
    //NSTextViewDelegate

    func textView(textView: NSTextView!, doCommandBySelector commandSelector: Selector) -> Bool
    {

        if (commandSelector == NSSelectorFromString("insertTab:"))
        {
            return !(self.textViewShouldInsertTab(textView))
        }
        else if (commandSelector == NSSelectorFromString("insertNewline:"))
        {
            return !self.textViewShouldInsertNewline(textView)
        }
        else if (commandSelector == NSSelectorFromString("deleteBackward:"))
        {
            return !self.textViewShouldDeleteBackward(textView)
        }
        return false
    }

    func textView(textView: NSTextView!, shouldChangeTextInRange affectedCharRange: NSRange, replacementString: String!) -> Bool
    {
        if (MPPreferences.sharedInstance().editorCompleteMatchingCharacters)
        {
            let strikethrough:Bool = MPPreferences.sharedInstance().extensionStrikethough
            if (textView.completeMatchingCharactersForTextInRange(affectedCharRange, withString: replacementString, strikethroughEnabled: strikethrough))
            {
                return false;
            }
        }
        return true
    }

    //Fake NSTextViewDelegate

    func textViewShouldInsertTab(textView:NSTextView!) ->Bool
    {
        if (MPPreferences.sharedInstance().editorConvertTabs)
        {
            textView.insertSpacesForTab()
            return false
        }
        return true
    }

    func textViewShouldInsertNewline(textView:NSTextView!) ->Bool
    {
        if (textView.insertMappedContent())
        {
            return false
        }
        return true
    }

    func textViewShouldDeleteBackward(textView:NSTextView!) ->Bool
    {
        if (MPPreferences.sharedInstance().editorCompleteMatchingCharacters)
        {
            let location = textView.selectedRange().location
            textView.deleteMatchingCharactersAround(location)
        }
        if (MPPreferences.sharedInstance().editorConvertTabs)
        {
            let location = textView.selectedRange().location
            textView.unindentForSpacesBefore(location)
        }
        return true
    }
    
}

class MUSTextView : NSTextView
{
    let mus_delegate = TextViewDelegate()

    override func doCommandBySelector(aSelector: Selector) {
        if !mus_delegate.textView(self, doCommandBySelector: aSelector) {
            super.doCommandBySelector(aSelector)
        }
    }

    override func shouldChangeTextInRange(affectedCharRange: NSRange, replacementString: String!) -> Bool
    {
        return mus_delegate.textView(self, shouldChangeTextInRange: affectedCharRange, replacementString: replacementString);
    }

    override func insertNewline(sender: AnyObject!)
    {
        if (self.insertMappedContent())
        {
            return
        }
        else if (self.completeNextLine())
        {
            return
        }

        super.insertNewline(sender)
    }

    override func insertTab(sender: AnyObject!)
    {
        if (mus_delegate.textViewShouldInsertTab(self))
        {
            super.insertTab(sender)
        }
    }

    override func deleteBackward(sender: AnyObject!)
    {
        if (mus_delegate.textViewShouldDeleteBackward(self))
        {
            super.deleteBackward(sender)
        }
    }

    func completeNextLine() -> Bool
    {
        let selectedRange = self.selectedRange
        var location = selectedRange.location
        let content = self.string

        if (selectedRange.length > 0)
        {
            return false
        }

        if (content.isEmpty)
        {
            return false
        }


        let start = content.locationOfFirstNewlineBefore(location) + 1
        let end = location
        let nonwhitespace = content.locationOfFirstNonWhitespaceCharacterInLineBefore(location)

        if (nonwhitespace == location)
        {
            return false
        }

        let range = NSMakeRange(start, end - start)
        let line = content.substring(start, length: end-start)

        let options = NSRegularExpressionOptions.AnchorsMatchLines

        let regex = NSRegularExpression(pattern:"^(\\s*)((?:(?:\\*|\\+|-|)\\s+)?)((?:\\d+\\.\\s+)?)(\\S)?", options: options, error: nil)
        let result:NSTextCheckingResult! = regex.firstMatchInString(line, options: NSMatchingOptions(0), range:NSMakeRange(0, 0)) as NSTextCheckingResult!
        if (!result || result.range.location == NSNotFound)
        {
            return false
        }

        var indent = ""

        for (var i = 0; i < result.rangeAtIndex(1).length; i++)
        {
            indent += " "
        }


        var t = ""

        let isUl = result.rangeAtIndex(2).length != 0
        let isOl = result.rangeAtIndex(3).length != 0

        let previousLineEmpty = result.rangeAtIndex(4).length == 0
        if (previousLineEmpty)
        {
            var replaceRange = NSMakeRange(NSNotFound, 0)
            if (isUl)
            {
                replaceRange = result.rangeAtIndex(2)
            }
            else if (isOl)
            {
                replaceRange = result.rangeAtIndex(3)
            }

            if (replaceRange.length > 0)
            {
                let location = replaceRange.location + start
                self.replaceCharactersInRange(NSMakeRange(location, replaceRange.length), withString: "")
            }
        }
        else if (isUl)
        {
            let range = result.rangeAtIndex(2)
            let length = range.length - 1
            t = line.substring(range.location, length: length)

        }
        else if (isOl)
        {
            let range = result.rangeAtIndex(3)
            let length = range.length - 1
            let captured = line.substring(range.location, length: length)
            let i = captured.toInt()! + 1
            t = NSString(format: "%ld.", i) as String
        }

        super.insertNewline(self)

        if (t.isEmpty)
        {
            return true
        }


        location += 1
        let it = indent + t

        let contentLength = content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)

        var r = NSMakeRange(location, countElements(t))
        if (contentLength > location + t.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
            && content.substring(r.location, length: r.length) == t)
        {
            super.insertText(indent)
            return true
        }

        r = NSMakeRange(location, it.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        if (contentLength > location + it.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
            && content.substring(r.location, length: r.length) == it)
        {
            return true
        }

        super.insertText(it + " ")
        return true
    }

}

class MUSDocument : NSDocument, MUSRendererDataSource, MUSRendererDelegate, MUSPreviewDelegate
{
    let preferences:MPPreferences = MPPreferences.sharedInstance()

    @IBOutlet weak var splitView:NSSplitView
    var editor:MUSTextView!
    @IBOutlet weak var preview:MUSWebView
    var highlighter:HGMarkdownHighlighter!
    var renderer:MUSRenderer!
    var manualRender:Bool?
    var loadedString:NSString?



    init()
    {
        super.init()

    }

    deinit
    {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self)
    }


//Overrride

    override var windowNibName: String {
    // Returns the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
    return "MUSDocument"
    }

    override func windowControllerDidLoadNib(controller: NSWindowController!)
    {
        super.windowControllerDidLoadNib(controller)

        let contentSubViews = controller.window.contentView.subviews as [NSView]
        let splitView = contentSubViews[0]
        let splitSubviews = splitView.subviews as [NSView]
        let scrollView = splitSubviews[0]
        let scrollSubViews = scrollView.subviews as [NSView]
        let clipView = scrollSubViews[0]
        let clipSubViews = clipView.subviews as [NSView]
        self.editor = clipSubViews[0] as MUSTextView

        var autosaveName = "Markdown"
        if (self.fileURL)
        {
            autosaveName = self.fileURL.absoluteString;
        }

        controller.window.setFrameAutosaveName(autosaveName)

        self.highlighter = HGMarkdownHighlighter(textView: self.editor, waitInterval: 0.1)
        self.renderer = MUSRenderer()
        self.renderer.dataSource = self
        self.renderer.delegate = self

        self.editor.automaticQuoteSubstitutionEnabled = false
        self.editor.automaticLinkDetectionEnabled = false
        self.editor.automaticDashSubstitutionEnabled = false
        self.setupEditor()

        self.preview.previewDelegate = self

        println(self.preview)

        let center = NSNotificationCenter.defaultCenter()

        center.addObserver(self, selector: "textDidChange:", name: NSTextDidChangeNotification, object: self.editor)
        center.addObserver(self, selector: "userDefaultsDidChange:", name: NSUserDefaultsDidChangeNotification, object: NSUserDefaults.standardUserDefaults())
        center.addObserver(self, selector: "boundsDidChange:", name: NSViewBoundsDidChangeNotification, object: self.editor.enclosingScrollView.contentView)

        if (self.loadedString)
        {
            self.editor.string = self.loadedString
            self.loadedString = nil;
            self.renderer.parseAndRenderNow()
            self.highlighter.parseAndHighlightNow()
        }
    }


    override class func autosavesInPlace() -> Bool {
        return true
    }

    // MARK: NSDocument Overrides

    // Create window controllers from a storyboard, if desired (based on `makesWindowControllers`).
    // The window controller that's used is the initial controller set in the storyboard.
    override func makeWindowControllers() {
        super.makeWindowControllers()
    }


    override func dataOfType(typeName: String!, error outError: NSErrorPointer) -> NSData!
    {
        return self.editor.string.dataUsingEncoding(NSUTF8StringEncoding)
    }

    override func readFromData(data: NSData!, ofType typeName: String!, error outError: NSErrorPointer) -> Bool
    {
        self.loadedString = NSString(data: data, encoding: NSUTF8StringEncoding)
        return true
    }

    override func prepareSavePanel(savePanel: NSSavePanel!) -> Bool
    {
        let title = self.editor.string.titleString()
        if (title)
        {
            savePanel.nameFieldStringValue = title
        }
        return super.prepareSavePanel(savePanel)
    }

    override func printOperationWithSettings(printSettings: [NSObject : AnyObject]!, error outError: AutoreleasingUnsafePointer<NSError?>) -> NSPrintOperation!
    {
        let frameView:WebFrameView = self.preview.mainFrame.frameView
        let printInfo = self.printInfo
        return frameView.printOperationWithPrintInfo(printInfo)
    }

    func previewNeedSyncScroller(preview:WebView!)
    {
        self.syncScrollers()
    }

    //MUSRendererDataSource

    func rendererMarkdown(renderer: MUSRenderer!) -> String!
    {
        return self.editor.string
    }

    func rendererHTMLTitle(renderer: MUSRenderer!) -> String!
    {
        var name = self.fileURL?.lastPathComponent

        if (name)
        {
            if (name!.hasSuffix(".md"))
            {
                name = name!.substringToIndex(-3)
            }
            else if (name!.hasSuffix(".markdown"))
            {
                name = name!.substringToIndex(-9)
            }

            if (name)
            {
                return name;
            }
        }

        return ""
    }

    func rendererExtensions(renderer: MUSRenderer!) -> Int
    {
        return Int(self.preferences.extensionFlags())
    }

    func rendererHasSmartyPants(renderer: MUSRenderer!) -> Bool
    {
        return self.preferences.extensionSmartyPants
    }

    func rendererStyleName(renderer: MUSRenderer!) -> String!
    {
        return self.preferences.htmlStyleName
    }

    func rendererHasSyntaxHighlighting(renderer: MUSRenderer!) -> Bool
    {
        return self.preferences.htmlSyntaxHighlighting
    }

    func rendererHasMathJax(renderer: MUSRenderer!) -> Bool
    {
        return self.preferences.htmlMathJax
    }

    func rendererHighlightingThemeName(renderer: MUSRenderer!) -> String!
    {
        return self.preferences.htmlHighlightingThemeName
    }

    func renderer(renderer: MUSRenderer!, didProduceHTMLOutput html: String!)
    {
        self.manualRender = self.preferences.markdownManualRender

        var baseURL = self.fileURL
        if (!baseURL)
        {
            baseURL = self.preferences.htmlDefaultDirectoryUrl
        }
        self.preview.isLoadingPreview = true
        self.preview.mainFrame.loadHTMLString(html, baseURL: baseURL)
    }



    func textDidChange(notification:NSNotification)
    {
        if (!self.preferences.markdownManualRender)
        {
            self.renderer.parseAndRenderLater()
        }
    }

    func userDefaultsDidChange(notification:NSNotification)
    {
        let renderer = self.renderer

        if (!self.preferences.markdownManualRender && self.manualRender)
        {
            renderer.parseAndRenderLater()
        }
        else
        {
            renderer.parseLaterWithCommand("parseIfPreferencesChanged", completionHandler: {
                renderer.render()
                })
            renderer.renderIfPreferencesChanged()
        }

        self.setupEditor()
    }

    func boundsDidChange(notification:NSNotification)
    {
        self.syncScrollers()
    }

    @IBAction func copyHtml(sender:AnyObject)
    {
        if (self.renderer.currentHtml)
        {
            self.preview.setSelectedDOMRange(nil, affinity: NSSelectionAffinity.Upstream)
            let pasteboard = NSPasteboard.generalPasteboard()
            pasteboard.clearContents()
            pasteboard.writeObjects([self.renderer.currentHtml!])
        }
    }

    @IBAction func exportHtml(sender:AnyObject)
    {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["html"]
        if (self.fileURL)
        {
            var fileName = self.fileURL.lastPathComponent
            if (fileName.hasSuffix(".md"))
            {
                fileName = fileName.substringToIndex(-3)
            }
            panel.nameFieldStringValue = fileName
        }

        let controller:MUSExportPanelAccessoryViewController = MUSExportPanelAccessoryViewController()
        panel.accessoryView = controller.view

        var w:NSWindow?

        let windowControllers = self.windowControllers

        if (windowControllers.count > 0)
        {
            w = windowControllers[0].window as? NSWindow
        }

        panel.beginSheetModalForWindow(w, completionHandler: {
            (result:NSInteger) in
            if (result != NSFileHandlingPanelOKButton)
            {
                return
            }

            let styles = controller.isStylesIncluded()
            let highlighting = controller.isHighlightingIncluded()

            let html = self.renderer.HTMLForExportWithStyles(styles, highlighting: highlighting)
            html.writeToURL(panel.URL, atomically: false, encoding: NSUTF8StringEncoding, error: nil)
            })
    }

    @IBAction func toggleStrong(sender:AnyObject)
    {
        self.editor.toggleForMarkupPrefix("**", suffix: "**")
    }

    @IBAction func toggleEmphasis(sender:AnyObject)
    {
        self.editor.toggleForMarkupPrefix("*", suffix: "*")
    }

    @IBAction func toggleInlineCode(sender:AnyObject)
    {
        self.editor.toggleForMarkupPrefix("`", suffix: "`")
    }

    @IBAction func toggleStrikethrough(sender:AnyObject)
    {
        self.editor.toggleForMarkupPrefix("~~", suffix: "~~")
    }

    @IBAction func toggleUnderline(sender:AnyObject)
    {
        self.editor.toggleForMarkupPrefix("_", suffix: "_")
    }

    @IBAction func toggleHighlight(sender:AnyObject)
    {
        self.editor.toggleForMarkupPrefix("==", suffix: "==")
    }

    @IBAction func toggleComment(sender:AnyObject)
    {
        self.editor.toggleForMarkupPrefix("<!--", suffix: "-->")
    }

    @IBAction func toggleLink(sender:AnyObject)
    {
        if (self.editor.toggleForMarkupPrefix("[", suffix: "]()"))
        {
            let selectedRange = self.editor.selectedRange()
            let location = selectedRange.location + selectedRange.length + 2
            self.editor.selectedRange = NSMakeRange(location, 0)
        }
    }

    @IBAction func toggleImage(sender:AnyObject)
    {
        if (self.editor.toggleForMarkupPrefix("![", suffix: "]()"))
        {
            let selectedRange = self.editor.selectedRange()
            let location = selectedRange.location + selectedRange.length + 2
            self.editor.selectedRange = NSMakeRange(location, 0)
        }
    }

    @IBAction func toggleUnorderedList(sender:AnyObject)
    {
        self.editor.toggleBlockWithPattern("^[\\*\\+-] \\S", prefix:"* ")
    }

    @IBAction func toggleBlockquote(sender:AnyObject)
    {
        self.editor.toggleBlockWithPattern("^> \\S", prefix:"> ")
    }

    @IBAction func indent(sender:AnyObject)
    {
        var padding = "\t"
        if (self.preferences.editorConvertTabs)
        {
            padding = "    "
        }
        self.editor.indentSelectedLinesWithPadding(padding)
    }

    @IBAction func unindent(sender:AnyObject)
    {
        self.editor.unindentSelectedLines()
    }

    @IBAction func insertNewParagraph(sender:AnyObject)
    {
        let range = self.editor.selectedRange()
        let location = range.location
        let length = range.length
        let content = self.editor.string
        let newlineBefore = content.locationOfFirstNewlineBefore(location)
        let newlineAfter = content.locationOfFirstNewlineAfter(location + length - 1)

        if (location == newlineBefore + 1 && location == newlineAfter)
        {
            self.editor.insertNewline(self)
            return
        }

        self.editor.selectedRange = NSMakeRange(newlineAfter, 0)
        self.editor.insertText("\n\n")
    }

    @IBAction func insertAmp(sender:AnyObject)
    {
        self.editor.insertText("&amp;")
    }

    @IBAction func insertLt(sender:AnyObject)
    {
        self.editor.insertText("&lt;")
    }

    @IBAction func insertGt(sender:AnyObject)
    {
        self.editor.insertText("&gt;")
    }

    @IBAction func insertNbsp(sender:AnyObject)
    {
        self.editor.insertText("&nbsp;")
    }

    @IBAction func insertQuot(sender:AnyObject)
    {
        self.editor.insertText("&quot;")
    }

    @IBAction func insert39(sender:AnyObject)
    {
        self.editor.insertText("&#39;")
    }

    @IBAction func resetSplit(sender:AnyObject)
    {
        let dividerThickness = self.splitView.dividerThickness
        let width = (self.splitView.frame.size.width - dividerThickness) / 2.0
        let parts = self.splitView.subviews

        let left = parts[0] as NSView
        let right = parts[1] as NSView

        left.frame = NSMakeRect(0, 0, width, left.frame.size.height)
        right.frame = NSMakeRect(width + dividerThickness, 0, width, right.frame.size.height)

        self.splitView.setPosition(width, ofDividerAtIndex: 0)
    }

    @IBAction func render(sender:AnyObject)
    {
        self.renderer.parseAndRenderLater()
    }



    func setupEditor()
    {
        self.highlighter.deactivate()

        self.editor.font = self.preferences.editorBaseFont.copy() as NSFont

        var extensions = pmh_EXT_NOTES
        if (self.preferences.extensionFootnotes)
        {
            extensions = pmh_EXT_NONE
        }
        self.highlighter.extensions = reinterpretCast(extensions)

        let x = self.preferences.editorHorizontalInset
        let y = self.preferences.editorVerticalInset

        self.editor.textContainerInset = NSMakeSize(x, y)

        let style = NSMutableParagraphStyle()
        style.lineSpacing == self.preferences.editorLineSpacing
        self.editor.defaultParagraphStyle = style as NSMutableParagraphStyle

        self.editor.textColor = nil
        self.editor.backgroundColor = nil
        self.highlighter.styles = nil

        self.highlighter.readClearTextStylesFromTextView()

        let themeName = self.preferences.editorStyleName as NSString

        if (themeName.length > 0)
        {
            let path = MPThemePathForName(themeName)
            let themeString = MPReadFileOfPath(path)

            self.highlighter.applyStylesFromStylesheet(themeString, withErrorHandler: {
                (errorMessages:[AnyObject]!) in
                self.preferences.editorStyleName = nil
                })
        }

        let contentView = self.editor.enclosingScrollView.contentView
        contentView.postsBoundsChangedNotifications = true

        self.highlighter.activate()
    }

    func syncScrollers()
    {
        if (!self.preferences.editorSyncScrolling)
        {
            return
        }

        let editorScrollView = self.editor.enclosingScrollView
        let editorContentView = editorScrollView.contentView
        let editorDocumentView = editorScrollView.documentView as NSView
        let editorDocumentFrame = editorDocumentView.frame
        let editorContentBounds = editorContentView.bounds

        var ratio = 0.0

        if (editorDocumentFrame.size.height > editorContentBounds.size.height)
        {
            ratio = editorContentBounds.origin.y / (editorDocumentFrame.size.height - editorContentBounds.size.height)
        }

        let previewScrollView = self.preview.mainFrame.frameView.documentView.enclosingScrollView
        let previewContentView = previewScrollView.contentView
        let previewDocumentView = previewScrollView.documentView as NSView

        var previewContentBounds = previewContentView.bounds

        previewContentBounds.origin.y = ratio * (previewDocumentView.frame.size.height - previewContentBounds.size.height)
        previewContentView.bounds = previewContentBounds
    }

}
