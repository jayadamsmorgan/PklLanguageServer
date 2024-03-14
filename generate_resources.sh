#!/bin/bash

# Define the input directory and output Swift file
INPUT_DIR="pkl/stdlib"
OUTPUT_FILE="Sources/pkl-lsp/Resources.swift"

# Start the Resources struct and hashMap
echo "// This file is auto-generated. Do not edit directly.\n" > $OUTPUT_FILE
echo "struct Resources {" >> $OUTPUT_FILE
echo "    static let stdlib: [String: String] = [" >> $OUTPUT_FILE

# Process each .pkl file
find "$INPUT_DIR" -name "*.pkl" | while read file; do
    filename=$(basename -- "$file")
    echo "        \"${filename}\": \"\"\"" >> $OUTPUT_FILE

    # Append file contents, escaping backslashes and double quotes
    while IFS= read -r line; do
        escapedLine=$(echo "$line" | sed 's/\\/\\\\/g; s/\"/\\"/g')
        echo "$escapedLine" >> $OUTPUT_FILE
    done < "$file"
    echo "\"\"\"," >> $OUTPUT_FILE
done

# Finish the hashMap and Resources struct
# Use `head` and `tail` to remove the last comma from the hashMap
echo "    ]" >> $OUTPUT_FILE
echo "}" >> $OUTPUT_FILE

# Correctly format the Swift dictionary to remove the last comma
# Temporary file for intermediate output
TMP_FILE="${OUTPUT_FILE}.tmp"

# Leave the last two lines (closing brackets) untouched, remove the last comma from the rest
head -n -2 "$OUTPUT_FILE" | sed '$ s/,$//' > "$TMP_FILE"
tail -n 2 "$OUTPUT_FILE" >> "$TMP_FILE"

# Replace original file with corrected one
mv "$TMP_FILE" "$OUTPUT_FILE"
