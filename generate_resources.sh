#!/usr/bin/env bash

# Define the input directory and output Swift file
STDLIB_PATH="pkl/stdlib"
OUTPUT_FILE="Sources/pkl-lsp/Resources.swift"

# Start the Resources struct and hashMap
echo "// This file is auto-generated. Do not edit directly." > "$OUTPUT_FILE"
echo "public enum Resources {" >> "$OUTPUT_FILE"
echo "    public static let stdlib: [String: String] = [" >> "$OUTPUT_FILE"

# Process each .pkl file
while IFS= read -r file; do
    filename=$(basename -- "$file")
    echo "Processing $filename..."
    echo "        \"${filename}\": \"\"\"" >> "$OUTPUT_FILE"

    # Append file contents, escaping backslashes and double quotes
    while IFS= read -r line; do
        escapedLine=$(echo "$line" | sed 's/\\/\\\\/g; s/\"/\\"/g')
        echo "$escapedLine" >> "$OUTPUT_FILE"
    done < "$file"
    echo "\"\"\"," >> "$OUTPUT_FILE"
done < <(find "$STDLIB_PATH" -name "*.pkl")

# Use sed to remove the last comma. This approach is compatible across both GNU and BSD sed.
# -i '' -e: For BSD sed compatibility, specifying an empty extension for in-place editing without backup.
# $!N; $!ba; : For GNU sed, to accumulate the whole file into pattern space.
# s/,\n    \]/\n    ]/: To remove the last comma before the closing square bracket.
sed -i '' -e '$!N; $!ba; s/,\n    \]/\n    ]/' "$OUTPUT_FILE"

echo "]}" >> "$OUTPUT_FILE"

echo "Done!"
