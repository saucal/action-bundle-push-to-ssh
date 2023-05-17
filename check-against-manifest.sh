#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Usage: $0 <manifest_file> <rsync_file>"
  exit 1
fi

manifest_file="$1"
rsync_file="$2"

if [ ! -f "$manifest_file" ] || [ ! -f "$rsync_file" ]; then
  echo "One or both of the files do not exist."
  exit 1
fi

echo "Removing leading +/- from manifest file"
sed -i -E "s/^[+-] //" "$manifest_file"

# Sort and remove empty lines from the files
sorted_file1=$(grep -v '^$' "$manifest_file" | sort)
sorted_file2=$(grep -v '^$' "$rsync_file" | sort)

# Compare the sorted files using diff
diff_output=$(diff -u <(echo "$sorted_file1") <(echo "$sorted_file2"))


# Check if there are any differences
if [ -n "$diff_output" ]; then
  echo "Manifest and Rsync list DO NOT match:"
  echo "$diff_output"
  exit 1
else
  echo "Manifest and Rsync list match."
  exit 0
fi
