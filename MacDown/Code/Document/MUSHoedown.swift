//
//  MUSHoedown.swift
//  MacDown
//
//  Created by Foster Yin on 7/3/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

import Foundation


enum MUSAssetsOption : Int
{
    case None,
    Embedded,
    FullLink
};

let kMUSMathJaxCDN = "http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
let kMUSPrismScriptDirectory = "Prism/components"
let kMUSPrismThemeDirectory = "Prism/themes"

func MUSPrismScriptURLsForLanguage(language:NSString) -> Array<NSURL>
{

    var baseUrl:NSURL!
    var extraUrl:NSURL!
    let bundle = NSBundle.mainBundle()

    let lang = language.lowercaseString

    let baseFileName = NSString(format: "prism-%@", lang)
    let extraFileName = NSString(format: "prism-%@-extras", lang)

    for ext in ["min.js", "js"]
    {
        if (!baseUrl)
        {
            baseUrl = bundle.URLForResource(baseFileName, withExtension: ext, subdirectory: kMUSPrismScriptDirectory)
        }

        if (!extraUrl)
        {
            extraUrl = bundle.URLForResource(extraFileName, withExtension: ext, subdirectory: kMUSPrismScriptDirectory)
        }
    }


    var urls = Array<NSURL>()

    if (baseUrl)
    {
        urls.append(baseUrl)
    }
    if (extraUrl)
    {
        urls.append(extraUrl)
    }

    return urls
}


func MUSHTMLFromMarkdown(text:NSString, flags:CUnsignedInt, smartypants:Bool, renderer:CConstPointer<hoedown_renderer>) -> NSString
{
    let inputData:NSData = text.dataUsingEncoding(NSUTF8StringEncoding)

    var markdown = hoedown_markdown_new(flags, 15, renderer)
    var ob = hoedown_buffer_new(64)
    let size:size_t = inputData.length.asUnsigned()
    var byteData = UInt8[]()
    inputData.getBytes(&byteData)
    //http://stackoverflow.com/questions/24303040/nsmutabledata-to-cconstpointer-conversion-in-swift-needed
    hoedown_markdown_render(ob, byteData, size, markdown)


    if (smartypants)
    {
        var ib = ob
        ob = hoedown_buffer_new(64)
        hoedown_html_smartypants(ob, ib.memory.data, ib.memory.size)
        hoedown_buffer_free(ib)
    }

    let result:NSString = NSString.stringWithUTF8String(hoedown_buffer_cstr(ob))
    hoedown_markdown_free(markdown)
    hoedown_buffer_free(ob)
    return result
}

func MUSGetHTML(title:NSString?, body:NSString, stylesrc:Array<NSURL>, styleopt:MUSAssetsOption, scriptsrc:Array<NSURL>, scriptopt:MUSAssetsOption) -> NSString
{
    var styles:NSMutableArray = NSMutableArray()
    var styleOption = styleopt
    var scriptOption = scriptopt

    for url in stylesrc as Array<NSURL>
    {
        var s:NSString?
        if (!url.fileURL)
        {
            styleOption = MUSAssetsOption.FullLink
        }

        switch (styleOption)
            {
        case MUSAssetsOption.FullLink:
            s = NSString(format: "<link rel=\"stylesheet\" type=\"text/css\" href=\"%@\">", url.absoluteString)
        case MUSAssetsOption.Embedded:
            s = NSString(format: "<style>\n%@\n</style>", MPReadFileOfPath(url.path))
        default:
            s = ""
        }
        if (s)
        {
            styles.addObject(s)
        }
    }

    let style = styles.componentsJoinedByString("\n")

    var scripts:NSMutableArray = NSMutableArray()
    for url in scriptsrc as Array<NSURL>
    {
        var s:NSString?
        if (!url.fileURL)
        {
            scriptOption = MUSAssetsOption.FullLink
        }

        switch (scriptOption)
            {
        case MUSAssetsOption.FullLink:
            s = NSString(format: "<script type=\"text/javascript\" src=\"%@\"></script>", url.absoluteString)
        case MUSAssetsOption.Embedded:
            s = NSString(format: "<script type=\"text/javascript\">%@</script>", MPReadFileOfPath(url.path))
        default:
            s = ""
        }
        if (s)
        {
            scripts.addObject(s)
        }
    }

    let script = scripts.componentsJoinedByString("\n")



    var t = title
    if (t)
    {
        t = NSString(format: "<title>%@</title>\n", t!)
    }
    else
    {
        t = ""
    }

    return  NSString(format:"<!DOCTYPE html><html>\n\n<head>\n<meta charset=\"utf-8\">\n%@%@\n</head><body>\n%@\n%@\n</body>\n\n</html>\n", t!, style, body, script)
}

//let aliasMap = [
//    "objective-c": "objectivec",
//    "obj-c": "objectivec",
//    "objc": "objectivec",
//    "html": "markup",
//    "xml": "markup"]
//
//let dependencyMap = [
//    "aspnet": "markup",
//    "bash": "clike",
//    "c": "clike",
//    "coffeescript": "javascript",
//    "cpp": "c",
//    "csharp": "clike",
//    "go": "clike",
//    "groovy": "clike",
//    "java": "clike",
//    "javascript": "clike",
//    "objectivec": "c",
//    "php": "clike",
//    "ruby": "clike",
//    "scala": "java",
//    "scss": "css",
//    "swift": "clike"]
//
//func laguage_addition(language:UnsafePointer<hoedown_buffer>, owner:MUSRenderer) -> UnsafePointer<hoedown_buffer>!
//{
//    let renderer = owner as MUSRenderer
//
//    var lang:NSString?
//    lang = NSString(bytes: language.memory.data, length: Int(language.memory.size), encoding: NSUTF8StringEncoding)
//
//    var mapped:UnsafePointer<hoedown_buffer>?
//    if (aliasMap[lang!])
//    {
//        lang = aliasMap[lang!]
//        let data = lang!.dataUsingEncoding(NSUTF8StringEncoding)
//        mapped = hoedown_buffer_new(64)
//        hoedown_buffer_put(mapped!, data.bytes, UInt(data.length))
//    }
//
//    var langugates = renderer.currentLanguages
//    while (lang)
//    {
//        let index = langugates.indexOfObject(lang!)
//        if (index != NSNotFound)
//        {
//            langugates.removeObjectAtIndex(index)
//        }
//        langugates.insertObject(lang, atIndex: 0)
//        lang = dependencyMap[lang!]
//    }
//
//    return mapped!
//}

