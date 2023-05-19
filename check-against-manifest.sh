#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Usage: $0 <manifest_file> <rsync_file> <gitignore_rules>"
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

echo "Removing leading deleting from rsync file"
sed -i -E "s/^deleting //" "$rsync_file"

echo "Removing directories from rsync file"
sed -i -E "/\/$/d" "$rsync_file"

# Function to check if a file path matches any gitignore pattern
matches_gitignore() {
    local file_path=$1
    for pattern in "${gitignore_patterns[@]}"; do
        if echo "$file_path" | grep -qE "$pattern"; then
            return 0  # Match found, return success
        fi
    done
    return 1  # No match found, return failure
}

# Process gitignore rules if they are not empty
if [ -n "$3" ]; then
  echo "Applying Gitignore rules:"
  echo "$3"
  readarray -t gitignore_patterns <<<"$3"

  # Remove lines matching gitignore patterns from files
  while IFS= read -r file_path; do
      if matches_gitignore "$file_path"; then
          sed -i "/$file_path/d" "$manifest_file"
          echo "Removed $file_path from manifest file"
      fi
  done < "$manifest_file"
fi

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
