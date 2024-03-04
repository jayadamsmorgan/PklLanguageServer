import Foundation
import SwiftTreeSitter

extension InputEdit {
    // Helper function to find byte offsets for changes in the document
    private static func findChangeOffsets(in oldString: String, and newString: String) -> (firstChangeOffset: Int, lastChangeOffsetInOld: Int, lastNewCharOffsetInNew: Int) {
        let oldCharacters = Array(oldString)
        let newCharacters = Array(newString)

        // Default values set to 0, assuming 0 can signify no changes when applicable
        var firstChangeOffset = 0
        var lastChangeOffsetInOld = 0
        var lastNewCharOffsetInNew = 0

        var foundFirstChange = false

        // Check from the beginning for the first change
        for index in 0 ..< min(oldCharacters.count, newCharacters.count) {
            if oldCharacters[index] != newCharacters[index], !foundFirstChange {
                firstChangeOffset = oldString.utf16.index(oldString.startIndex, offsetBy: index).utf16Offset(in: oldString)
                foundFirstChange = true
                break
            }
        }

        // If the strings are of different lengths but identical up to the length of the shorter string,
        // the first change is at the end of the shorter string.
        if !foundFirstChange, oldCharacters.count != newCharacters.count {
            firstChangeOffset = min(oldCharacters.count, newCharacters.count)
            foundFirstChange = true
        }

        // If no change was found and strings are the same length, indicate no change explicitly
        if !foundFirstChange {
            return (0, 0, 0) // Indicating no change for all
        }

        // Check from the end for the last change
        var indexFromEnd = 0
        while indexFromEnd < oldCharacters.count, indexFromEnd < newCharacters.count {
            if oldCharacters[oldCharacters.count - 1 - indexFromEnd] != newCharacters[newCharacters.count - 1 - indexFromEnd] {
                lastChangeOffsetInOld = oldString.utf16.index(oldString.startIndex, offsetBy: oldCharacters.count - indexFromEnd - 1).utf16Offset(in: oldString)
                lastNewCharOffsetInNew = newString.utf16.index(newString.startIndex, offsetBy: newCharacters.count - indexFromEnd - 1).utf16Offset(in: newString)
                break
            }
            indexFromEnd += 1
        }

        // Adjust for cases where the strings are of different lengths
        if oldCharacters.count != newCharacters.count {
            if oldCharacters.count > newCharacters.count {
                lastChangeOffsetInOld = oldString.utf16.index(oldString.startIndex, offsetBy: oldCharacters.count - 1).utf16Offset(in: oldString)
            } else { // newCharacters.count > oldCharacters.count
                lastNewCharOffsetInNew = newString.utf16.index(newString.startIndex, offsetBy: newCharacters.count - 1).utf16Offset(in: newString)
            }
        }

        return (firstChangeOffset, lastChangeOffsetInOld, lastNewCharOffsetInNew)
    }

    // Helper function to find Point for given UTF-16 offset
    private static func pointInText(forUtf16Offset utf16Offset: Int, in text: String) -> Point {
        // Splitting the text into lines
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)

        var currentOffset = 0
        var row = 0
        var column = 0

        // Iterate over each line
        for line in lines {
            let lineLength = line.utf16.count

            // Check if the currentOffset + lineLength surpasses the target utf16Offset
            if currentOffset + lineLength >= utf16Offset {
                // Found the row, now find the column
                column = utf16Offset - currentOffset
                break
            }

            // Move to the next line
            currentOffset += lineLength + 1 // +1 for the newline character
            row += 1
        }

        return Point(row: row, column: column)
    }

    public static func from(oldString: String, newString: String) -> InputEdit {
        let changeOffsets = findChangeOffsets(in: oldString, and: newString)

        let startByte = changeOffsets.firstChangeOffset
        let oldEndByte = changeOffsets.lastChangeOffsetInOld
        let newEndByte = changeOffsets.lastNewCharOffsetInNew

        let startPoint = pointInText(forUtf16Offset: startByte, in: oldString)
        let oldEndPoint = pointInText(forUtf16Offset: oldEndByte, in: oldString)
        let newEndPoint = pointInText(forUtf16Offset: newEndByte, in: newString)

        return InputEdit(startByte: startByte, oldEndByte: oldEndByte, newEndByte: newEndByte,
                         startPoint: startPoint, oldEndPoint: oldEndPoint, newEndPoint: newEndPoint)
    }
}
