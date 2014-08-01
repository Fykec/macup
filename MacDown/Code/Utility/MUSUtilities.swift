//
//  MUSUtilities.swift
//  MacDown
//
//  Created by Foster Yin on 8/1/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

import Foundation


let kMUSStylesDirectoryName = "Styles"
let kMUSStyleFileExtension = ".css"
let kMUSThemesDirectoryName = "Themes"
let kMUSThemeFileExtension = ".style"

func MUSDataRootDirectory() -> String!
{
    var paths:Array<String> = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true) as Array<String>
    let infoDictionary = NSBundle.mainBundle().infoDictionary
    let bundleName = infoDictionary["CFBundleName"] as AnyObject! as String!
    let path = "\(paths[0])/\(bundleName)"
    return path
}

func MUSDataDirectory(relativePath:String?) -> String!
{
    if (!relativePath)
    {
        return MUSDataRootDirectory()
    }

    return "\(MUSDataRootDirectory())/\(relativePath!)"
}

func MUSPathToDataFile(name:String, dirPath:String) -> String!
{
    return "\(MUSDataDirectory(dirPath))/\(name)"
}

func MUSCharacterIsWhitespace(character:unichar) -> Bool
{
    return NSCharacterSet.whitespaceCharacterSet().characterIsMember(character)
}

func MUSCharacterIsNewline(character:unichar) -> Bool
{
    return NSCharacterSet.newlineCharacterSet().characterIsMember(character)
}

func MUSStringIsNewline(str:String) -> Bool
{
    return NSCharacterSet.newlineCharacterSet().characterIsMember((str[0] as Character).toUnichar())
}

func MPStylePathForName(name:String) -> String
{
    var theName = name
    if (!name.hasSuffix(kMUSStyleFileExtension))
    {
        theName = "\(name)\(kMUSStyleFileExtension)"
    }
    return MUSPathToDataFile(theName, kMUSStylesDirectoryName)
}

func MPThemePathForName(name:String) -> String
{
    var theName = name
    if (!name.hasSuffix(kMUSThemeFileExtension))
    {
        theName = "\(name)\(kMUSThemeFileExtension)"
    }
    return MUSPathToDataFile(theName, kMUSThemesDirectoryName)
}

func MUSHighlightingThemeURLForName(name:String) -> NSURL
{
    var theName = "prism-\(name.lowercaseString)"
    if (name.hasSuffix(".css"))
    {
        theName = theName.substringToIndex(-4)
    }

    let bundle = NSBundle.mainBundle()
    var url = bundle.URLForResource(name, withExtension: "css", subdirectory: "Prism/themes")
    if (url == nil)
    {
        url = bundle.URLForResource("prism", withExtension: "css", subdirectory: "Prism/themes")
    }
    return url
}

func MUSReadFileOfPath(path:String) -> String
{
    var error:NSError?
    let content = String.stringWithContentsOfFile(path, encoding: NSUTF8StringEncoding, error: &error)
    if (error)
    {
        return ""
    }
    return content!
}

func MUSListEntriesForDirectory(dirName:String, processor:((String) -> String)?) -> Array<String>
{
    let dirPath = MUSDataDirectory(dirName)
    var error:NSError?
    let manager = NSFileManager.defaultManager()
    let fileNames = manager.contentsOfDirectoryAtPath(dirPath, error: &error)
    if (error)
    {
        return Array<String>()
    }
    var items:Array<String> = Array<String>()
    for fileName in fileNames
    {
        var item = "\(dirPath)\(fileName)"

        if (processor)
        {
            item = processor!(item)
        }

        if (item != nil)
        {
            items.append(item)
        }
    }

    return items
}

let MUSFileNameHasSuffixProcessor:((String) -> ((String) -> String)) = { (suffix:String) -> ((String) -> String) in
    let block:((String) -> String) = { (absPath:String) -> String in
        let manager = NSFileManager.defaultManager()
        let name = absPath.lastPathComponent
        var processed = ""
        if (name.hasSuffix(suffix) && manager.fileExistsAtPath(absPath))
        {
            let end = name.lengthOfUTF8() - suffix.lengthOfUTF8()
            processed = name.substringToIndex(end)
        }
        return processed
    }
    return block
}


