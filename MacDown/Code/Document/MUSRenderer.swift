//
//  MUSRenderer.swift
//  MacDown
//
//  Created by Foster Yin on 7/3/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

import Foundation

//http://stackoverflow.com/questions/24635202/swift-closure-as-values-in-dictionary
class ClosureType {
    var closure:(() -> Void)?
}

class MUSRenderer : NSObject
{
    var dataSource:MUSRendererDataSource?
    var delegate:MUSRendererDelegate?

    var htmlRenderer:UnsafePointer<hoedown_renderer>!
    {
    willSet
    {
        cleanHtmlRenderer(htmlRenderer)
    }
    didSet {

        setupHtmlRendererWithOwner(htmlRenderer, reinterpretCast(self))
    }
    }
    var currentLanguages:NSMutableArray!

    var prismStylesheets:Array<NSURL>
    {
    get {
        let name = self.delegate!.rendererHighlightingThemeName(self)
        return [MPHighlightingThemeURLForName(name)]
    }
    }

    var prismScripts:Array<NSURL>
    {
    get {
        let bundle = NSBundle.mainBundle()
        var urls = Array<NSURL>()
        urls.append(bundle.URLForResource("prism-core.min", withExtension: "js", subdirectory: kMUSPrismScriptDirectory))
        currentLanguages.enumerateObjectsUsingBlock({(language: AnyObject!, index:Int, stop:UnsafePointer<ObjCBool>) in
            urls.extend(MUSPrismScriptURLsForLanguage(language as NSString))
            })
        return urls
    }
    }

    var stylesheets:Array<NSURL>
    {
    get {
        let d = self.delegate
        let defaultStyle = MPStylePathForName(d!.rendererStyleName(self))
        var urls = Array<NSURL>()
        urls.append(NSURL.fileURLWithPath(defaultStyle))
        if (d!.rendererHasSyntaxHighlighting(self))
        {
            urls.extend(self.prismStylesheets)
        }
        return urls
    }
    }

    var scripts:Array<NSURL>
    {
    get {
        let d = self.delegate
        var urls = Array<NSURL>()
        if (d!.rendererHasSyntaxHighlighting(self))
        {
            urls.extend(self.prismScripts)
        }
        if (d!.rendererHasMathJax(self))
        {
            urls.append(NSURL.URLWithString(kMUSMathJaxCDN))
        }
        return urls
    }
    }
    var currentHtml:String?
    var parseDelayTimer:NSTimer?
    var extensions:Int!
    var smartypants:Bool!
    var styleName:String!
    var mathjax:Bool!
    var syntaxHighlighting:Bool!
    var manualRender:Bool!
    var highlightingThemeName:String!

    init()
    {
        super.init()
        currentHtml = ""
        currentLanguages = NSMutableArray()
        htmlRenderer = hoedown_html_renderer_new(0, 0)
    }

    deinit
    {
        htmlRenderer = nil
    }
    

    func parseAndRenderNow()
    {
        parseLater(0.0, command:Selector("parse"), completionHandler:
            {
                self.render()
            })
    }

    func parseAndRenderLater()
    {
        parseLaterWithCommand(Selector("parse"), completionHandler:
            {
                self.render()
            })
    }

    func parseLaterWithCommand(action:Selector, completionHandler handler:(() -> Void)?)
    {
        parseLater(0.5, command: Selector("parse"), completionHandler: handler)
    }


    func parseLater(delay:NSTimeInterval, command action:Selector, completionHandler handler:(() -> Void)?)
    {

        self.parseDelayTimer?.invalidate()

        var closure:ClosureType?
        if (handler)
        {
            closure = ClosureType()
            closure!.closure = handler
        }

        let timer = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: action, userInfo: closure, repeats: true)

        self.parseDelayTimer = timer
    }

    func parseIfPreferencesChanged()
    {
        if (self.delegate!.rendererExtensions(self) != self.extensions ||
            self.delegate!.rendererHasSmartyPants(self) != self.smartypants)
        {
            self.parse()
        }
    }

    func parse()
    {
        var nextAction:(() -> Void)?

        if (self.parseDelayTimer)
        {
            if (self.parseDelayTimer!.valid)
            {
                nextAction = (self.parseDelayTimer!.userInfo as? ClosureType)?.closure
                self.parseDelayTimer!.invalidate()
                self.parseDelayTimer = nil
            }
        }

        self.currentLanguages.removeAllObjects()

        let delegate = self.delegate

        let ext = delegate!.rendererExtensions(self)
        let smtpa = delegate!.rendererHasSmartyPants(self)
        let markdown = self.dataSource!.rendererMarkdown(self)
        self.currentHtml = MUSHTMLFromMarkdown(markdown, CUnsignedInt(ext), smtpa, self.htmlRenderer)
        self.extensions = ext
        self.smartypants = smtpa

        if (nextAction)
        {
            nextAction!()
        }
    }

    func renderIfPreferencesChanged()
    {
        var changed = false
        let d = self.delegate

        if (d!.rendererHasSyntaxHighlighting(self) != self.syntaxHighlighting)
        {
            changed = true
        }
        else if (d!.rendererHasMathJax(self) != self.mathjax)
        {
            changed = true
        }
        else if (d!.rendererHighlightingThemeName(self) != self.highlightingThemeName)
        {
            changed = true
        }
        else if (d!.rendererStyleName(self) != self.styleName)
        {
            changed = true
        }

        if (changed)
        {
            self.render()
        }
    }

    func render()
    {
        if (self.currentHtml)
        {
            let d = self.delegate

            let title = self.dataSource!.rendererHTMLTitle(self)
            let html = MUSGetHTML(title, self.currentHtml!, self.stylesheets, MUSAssetsOption.FullLink, self.scripts, MUSAssetsOption.FullLink)
            d!.renderer(self, didProduceHTMLOutput: html)

            self.styleName = d!.rendererStyleName(self)
            self.mathjax = d!.rendererHasMathJax(self)
            self.syntaxHighlighting = d!.rendererHasSyntaxHighlighting(self)
            self.highlightingThemeName = d!.rendererHighlightingThemeName(self)
        }
        
    }

    func HTMLForExportWithStyles(withStyles:Bool, highlighting withHighlighting:Bool) -> NSString
    {
        if (self.currentHtml)
        {
            var stylesOption = MUSAssetsOption.None
            var scriptsOption = MUSAssetsOption.None

            var styles = Array<NSURL>()
            var scripts = Array<NSURL>()

            if (withStyles)
            {
                stylesOption = MUSAssetsOption.Embedded
                styles.append(NSURL.fileURLWithPath(MPStylePathForName(self.styleName)))
            }

            if (withHighlighting)
            {
                stylesOption = MUSAssetsOption.Embedded
                scriptsOption = MUSAssetsOption.Embedded
                styles.extend(self.prismStylesheets)
                scripts.extend(self.prismScripts)
            }

            if (self.delegate!.rendererHasMathJax(self))
            {
                scriptsOption = MUSAssetsOption.Embedded
                scripts.append(NSURL.URLWithString(kMUSMathJaxCDN))
            }

            var title = self.dataSource?.rendererHTMLTitle(self)
            if (!title)
            {
                title = ""
            }

            return MUSGetHTML(title!, self.currentHtml!, styles, stylesOption, scripts, scriptsOption)
        }
        else
        {
            return ""
        }

    }

}

protocol MUSRendererDataSource
{
    func rendererMarkdown(renderer:MUSRenderer!) -> String!

    func rendererHTMLTitle(renderer:MUSRenderer!) -> String!
}

protocol MUSRendererDelegate
{
    func rendererExtensions(renderer:MUSRenderer!) -> Int

    func rendererHasSmartyPants(renderer:MUSRenderer!) -> Bool

    func rendererStyleName(renderer:MUSRenderer!) -> String!

    func rendererHasSyntaxHighlighting(renderer:MUSRenderer!) -> Bool

    func rendererHasMathJax(renderer:MUSRenderer!) -> Bool

    func rendererHighlightingThemeName(renderer:MUSRenderer!) -> String!

    func renderer(renderer:MUSRenderer!, didProduceHTMLOutput html:String!)
}

