//
//  SourceEditorCommand.swift
//  JZTest
//
//  Created by Joey on 2019/11/4.
//  Copyright © 2019 Dachen. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        
        if invocation.commandIdentifier == "command.arrange" {
            performArrange(with: invocation, completionHandler: completionHandler)
        } else if invocation.commandIdentifier == "command.insert" {
            performInsert(with: invocation, completionHandler: completionHandler)
        }
    }
    
    func performArrange(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        let linesToSort = invocation.buffer.lines.filter { line in
            if case let lineStr as String = line {
                return lineStr.hasPrefix("#import") || lineStr.hasPrefix("@import")
            }
            return false
        }

        guard linesToSort.count > 0 else {
            let error = NSError(domain: "no import line to arrange", code: 1, userInfo: nil)
            completionHandler(error)
            return
        }

        let firstLineIndex = invocation.buffer.lines.index(of: linesToSort[0]) // For insert

        invocation.buffer.lines.removeObjects(in: linesToSort)
        let linesSorted = (linesToSort as? [String] ?? []).sorted() {$0 <= $1}
        linesSorted.reversed().forEach { (line) in
            invocation.buffer.lines.insert(line, at: firstLineIndex)
        }
        let selectionsUpdated: [XCSourceTextRange] = (0..<linesSorted.count).map { (index) in
            let lineIndex = firstLineIndex + index
            let endColumn = linesSorted[index].count - 1
            return XCSourceTextRange(start: XCSourceTextPosition(line: lineIndex, column: 0), end: XCSourceTextPosition(line: lineIndex, column: endColumn))
        }
        invocation.buffer.selections.setArray(selectionsUpdated)
        
        completionHandler(nil)
    }
    
    func performInsert(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
        guard let selection : XCSourceTextRange = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            let error = NSError(domain: "no availibale selection, pls select import class name", code: 0, userInfo: nil)
            completionHandler(error)
            return
        }
        
        if selection.start.line != selection.end.line || selection.start.column >= selection.end.column {
            let error = NSError(domain: "no availibale selection, pls select import class name", code: 0, userInfo: nil)
            completionHandler(error)
            return
        }
        
        let lines = invocation.buffer.lines
        let curLine : String = lines[selection.start.line] as! String
        let startSlicingIndex = curLine.index(curLine.startIndex, offsetBy: selection.start.column)
        let endSlicingIndex = curLine.index(curLine.startIndex, offsetBy: selection.end.column-1)
        let selectStr = curLine[startSlicingIndex...endSlicingIndex]
        let insertImportStr = "#import \"\(selectStr).h\""
        
        // insert import
        var insertIndex = 0
        
        for i in (0...lines.count-1).reversed() {
            let line : String = lines[i] as! String
            if line.hasPrefix("#import") {
                insertIndex = i + 1
                break
            }
        }
        
        // can not find import, then find @interface
        if insertIndex == 0 {
            for i in (0...lines.count-1) {
                let line : String = lines[i] as! String
                if line.hasPrefix("@interface") || line.hasPrefix("@implementation") {
                    let index = lines.index(of: line)
                    if index > 2 {
                        insertIndex = index - 2
                    }
                    break
                }
            }
        }
        
        lines.insert(insertImportStr, at: insertIndex)
        
        // insert success, clear selections
        let endPosition = XCSourceTextPosition(line: selection.end.line, column: selection.end.column)
        let range = XCSourceTextRange(start: endPosition, end: endPosition)
        invocation.buffer.selections.setArray([range])
        
        completionHandler(nil)
    }
    
}
