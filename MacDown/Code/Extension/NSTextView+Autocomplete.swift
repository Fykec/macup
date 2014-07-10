//
//  NSTextView+Autocomplete.swift
//  MacDown
//
//  Created by Foster Yin on 7/7/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

import Cocoa

let kMUSMatchingCharactersMap:Character[][] = [
    ["(", ")"],
    ["[", "]"],
    ["[", "]"],
    ["<", ">"],
    ["\"", "\""],
    ["\"", "\""],
    ["\uff08", "\uff09"],     // full-width parentheses
    ["\u300c", "\u300d"],     // corner brackets
    ["\u300e", "\u300f"],     // white corner brackets
    ["\u2018", "\u2019"],     // single quotes
    ["\u201c", "\u201d"],     // double quotes
    ["\0", "\0"],]

let kMUSStrikethroughCharacter:Character = "~"

let kMUSMarkupCharacters:Character[] = [
    "*", "_", "`", "=", "\0",]

let kMUSListLineHeadPattern = "^(\\s*)((?:(?:\\*|\\+|-|)\\s+)?)((?:\\d+\\.\\s+)?)(\\S)?"

let kMUSDataMap:Dictionary<String, NSData> = {
    let bundle = NSBundle.mainBundle()
    let filePath = bundle.pathForResource("data", ofType: "map", inDirectory:"data")
    let map : AnyObject! = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath)
    return map as Dictionary<String, NSData>
}()

extension NSTextView
{
    func substringInRange(range:NSRange, isSurroundedByPrefix prefix:String?, suffix:String?) -> Bool
    {
        let content = self.string

        let location = range.location
        let length = range.length

        if (content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) < location + length + suffix!.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        {
            return false
        }

        if (location < prefix!.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        {
            return false
        }

        if (!content.substringFromIndex(location + length).hasPrefix(suffix!) ||
            !content.substringToIndex(location).hasSuffix(prefix!))
        {
            return false
        }

        if (!(prefix! == "*") || !(suffix! == "*"))
        {
            return true
        }
        if (self.substringInRange(range, isSurroundedByPrefix: "***", suffix: "***"))
        {
            return true
        }
        if (self.substringInRange(range, isSurroundedByPrefix: "**", suffix: "**"))
        {
            return false
        }

        return true

    }

    func insertSpacesForTab()
    {
        var spaces = "    "
        let currentLocation = self.selectedRange.location
        let p = self.string.locationOfFirstNewlineBefore(currentLocation)
        let offset = (currentLocation - p - 1) % 4
        if (offset > 0)
        {
            spaces = spaces.substringFromIndex(offset)
        }

        self.insertText(spaces)
    }

    func completeMatchingCharactersForTextInRange(range:NSRange, withString string:String?, strikethroughEnabled:Bool) -> Bool
    {
        let stringLength = string!.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)

        if (range.length == 0 && stringLength == 1)
        {
            let location = range.location
            if (self.completeMatchingCharacterForText(string, atLocation: location))
            {
                return true
            }
        }
        else if (range.length > 0 && stringLength == 1)
        {
            let char:Character = string![0]
            if (self.wrapMatchingCharactersOfCharacter(char, aroundTextInRange: range, strikethroughEnabled: strikethroughEnabled))
            {
                return true
            }
        }
        
        return false
    }


    func completeMatchingCharacterForText(string:String?, atLocation location:Int) -> Bool
    {
        let content = self.string
        let contentLength = content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)

        let c:Character = string![0]
        var n:Character = " "
        var p:Character = " "

        if (location < contentLength)
        {
            n = content[location]
        }
        if (location > 0 && location <= contentLength)
        {
            p = content[location - 1]
        }

        let delims = NSCharacterSet.whitespaceAndNewlineCharacterSet()

        for cs:Character[] in kMUSMatchingCharactersMap
        {
            if (delims.characterIsMember(n.toUnichar())
                && (c == cs[0])
                && (n != cs[1])
                && (delims.characterIsMember(p.toUnichar()) || "\(cs[0])" != "\(cs[1])"))
            {
                let range = NSMakeRange(location, 0)
                let completion = "" + cs[0] + cs[1]
                self.insertText(completion, replacementRange: range)

                self.selectedRange = NSMakeRange(range.location, range.location + string!.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
                return true
            }
            else if (c == cs[1] && n == cs[1])
            {
                let range = NSMakeRange(location + 1, 0)
                self.selectedRange = range
                return true
            }
        }

        return false
    }

    func wrapTextInRange(range:NSRange, withPrefix prefix:Character, suffix:Character)
    {
        let string = self.string.substring(range.location, length: range.length)
        let wrapped = prefix + string + suffix
        self.insertText(wrapped, replacementRange: range)
        self.selectedRange = NSMakeRange(range.location + 1, range.length)
    }

    func wrapMatchingCharactersOfCharacter(character:Character, aroundTextInRange range:NSRange, strikethroughEnabled:Bool) -> Bool
    {
        for cs:Character[] in kMUSMatchingCharactersMap
        {
            if (character == cs[0])
            {
                self.wrapTextInRange(range, withPrefix: cs[0], suffix: cs[1])
                return true
            }
        }

        for char in kMUSMarkupCharacters
        {
            if (character == char)
            {
                self.wrapTextInRange(range, withPrefix: character, suffix: character)
                return true
            }
        }

        if (strikethroughEnabled && character == kMUSStrikethroughCharacter)
        {
            self.wrapTextInRange(range, withPrefix: character, suffix: character)
            return true
        }

        return false
    }

    func deleteMatchingCharactersAround(location:Int)
    {
        let string = self.string
        if (location == 0 || location == string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        {
            return
        }

        let f:Character = string[location - 1]
        let b:Character = string[location]

        for cs:Character[] in kMUSMatchingCharactersMap
        {
            if (f == cs[0] && b == cs[1])
            {
                self.replaceCharactersInRange(NSMakeRange(location, 1), withString: "")
                break
            }
        }
    }

    func unindentForSpacesBefore(location:Int)
    {
        let string = self.string

        var whitespaceCount = 0

        while ((location - whitespaceCount > 0)
            && (string[location - whitespaceCount - 1] == " "))
        {
            whitespaceCount++
            if (whitespaceCount >= 4)
            {
                break
            }
        }

        if (whitespaceCount < 2)
        {
            return
        }

        var offset = (self.string.locationOfFirstNewlineBefore(location) + 1) % 4
        if (offset == 0)
        {
            offset = 4
        }

        offset = offset > whitespaceCount ? whitespaceCount : 4
        let range = NSMakeRange(location - offset, offset)
        self.replaceCharactersInRange(range, withString: " ")
    }

    func toggleForMarkupPrefix(prefix:String, suffix:String) -> Bool
    {
        var range = self.selectedRange

        let selection = self.string.substring(range.location, length: range.length)

        var isOn = false

        let poff = prefix.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)

        if (self.substringInRange(range, isSurroundedByPrefix: prefix, suffix: suffix))
        {
            let sub = NSMakeRange(range.location - poff, selection.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) + poff + suffix.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
            self.insertText(selection, replacementRange: sub)
            range.location = sub.location
            isOn = false
        }
        else
        {
            let text = prefix + selection + suffix
            self.insertText(text, replacementRange: range)
            range.location += poff
            isOn = true
        }

        self.selectedRange = range
        return isOn
    }

    func toggleBlockWithPattern(pattern:String, prefix:String)
    {
        let regex = NSRegularExpression(pattern: pattern, options:NSRegularExpressionOptions(0) , error: nil)

        let content = self.string

        var selectedRange = self.selectedRange

        let lineRange = content.lineRangeForRange(content.NSRangeToRange(selectedRange))

        let toProcess = content.substringWithRange(lineRange)
        let lines:Array<String> = toProcess.componentsSeparatedByString("\n")

        var isMarked = true

        for line in lines
        {
            let lineLength = line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
            if (lineLength == 0)
            {
                continue
            }

            let matchRange = regex.rangeOfFirstMatchInString(line, options: NSMatchingOptions(0), range: NSMakeRange(0, lineLength))

            if (matchRange.location == NSNotFound)
            {
                isMarked = false
                break
            }
        }

        let prefixLength = prefix.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)

        var modLines = Array<String>()


        var totalShift = 0
        for line in lines
        {
            var theLine = line
            if (line.lengthOfUTF8() > 0)
            {
                totalShift += prefixLength

                if (!isMarked)
                {
                    theLine = prefix + line
                }
                else
                {
                    theLine = line.substringFromIndex(prefixLength)
                }
            }
            modLines.append(theLine)
        }

        let processed = (modLines as NSArray).componentsJoinedByString("\n")

        self.insertText(processed, replacementRange: content.RangeToNSRange(lineRange))

        if (!isMarked)
        {
            selectedRange.location += prefixLength
            selectedRange.length += (totalShift - prefixLength)
        }
        else
        {
            selectedRange.location -= prefixLength
            selectedRange.length -= (totalShift - prefixLength)

            if (selectedRange.location < content.RangeToNSRange(lineRange).location)
            {
                selectedRange.length -= (content.RangeToNSRange(lineRange).location - selectedRange.location)
                selectedRange.location = content.RangeToNSRange(lineRange).location
            }
        }

        self.selectedRange = selectedRange

    }

    func indentSelectedLinesWithPadding(padding:String)
    {
        let content = self.string
        var selectedRange = self.selectedRange
        let lineRange = content.lineRangeForRange(content.NSRangeToRange(selectedRange))

        let toProcess = content.substringWithRange(lineRange)
        let lines:Array<String> = toProcess.componentsSeparatedByString("\n")

        var modLines = Array<String>()
        let paddingLength = padding.lengthOfUTF8()

        var totalShift = 0

        for line in lines
        {
            var theLine = line
            if (line.lengthOfUTF8() > 0)
            {
                totalShift += paddingLength
                theLine = padding.stringByAppendingString(line)
            }

            modLines += theLine
        }

        let processed = (modLines as NSArray).componentsJoinedByString("\n")
        self.insertText(processed, replacementRange: content.RangeToNSRange(lineRange))

        selectedRange.location += paddingLength
        selectedRange.length += (totalShift - paddingLength)
        self.selectedRange = selectedRange
    }

    func unindentSelectedLines()
    {
        let content = self.string
        var selectedRange = self.selectedRange
        let lineRange = content.lineRangeForRange(content.NSRangeToRange(selectedRange))

        let toProcess = content.substringWithRange(lineRange)
        let lines:Array<String> = toProcess.componentsSeparatedByString("\n")

        var modLines = Array<String>()

        var firstShift = 0
        var totalShift = 0
        for (index, line) in enumerate(lines)
        {
            let lineLength = line.lengthOfUTF8()
            var theLine = line
            var shift = 0
            for (shift = 0; shift <= 4; shift++)
            {
                if (shift >= lineLength)
                {
                    break
                }

                let char = line.substring(shift, length: 1)
                if (char == "\t")
                {
                    shift++
                }
                if (char != " ")
                {
                    break
                }

                if (index == 0)
                {
                    firstShift += shift
                }

                totalShift += shift

                if ((shift > 0) && (shift < lineLength))
                {
                    theLine = line.substringFromIndex(shift)
                }
                modLines += theLine
            }
        }

        let processed = (modLines as NSArray).componentsJoinedByString("\n")
        self.insertText(processed, replacementRange: content.RangeToNSRange(lineRange))

        selectedRange.location -= firstShift
        selectedRange.length -= (totalShift - firstShift)
        self.selectedRange = selectedRange

    }


    func insertMappedContent() -> Bool
    {
        let content = self.string
        let contentLength = content.lengthOfUTF8()
        if (contentLength > 20)
        {
            return false

        }

        let mapped = kMUSDataMap[content]
        if (!mapped)
        {
            return false
        }

        let path = NSTemporaryDirectory() + "/" + "\(content.hash)"
        mapped!.writeToFile(path, atomically: false)
        let text = "![\(content)](\(path))"
        self.insertText(text, replacementRange: NSMakeRange(0, contentLength))
        self.selectedRange = NSMakeRange(2, contentLength)
        return true
    }
}
