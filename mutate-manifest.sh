#!/bin/bash
input_file="$1"
base_path="$2"

echo "Removing leading +/- from manifest file"
sed -i -E "s/^[+-] //" "$input_file"

echo "Adding missing directories to manifest file"

# Initialize an empty array to store unique directories
unique_dirs=()

# Loop through the input file line by line
while read file_path; do
  # Check if the directory of the file path exists
  dir_path=$(dirname "${base_path}${file_path}")
  if [ ! -d "$dir_path" ]; then

    rel_dir_path=$(dirname "${file_path}")
    # If the directory does not exist, add it to the array
    if [[ ! " ${unique_dirs[@]} " =~ " ${rel_dir_path} " ]]; then
      unique_dirs+=("$rel_dir_path")
    fi
  fi
done < "$input_file"

# Print each directory on a separate line
for dir in "${unique_dirs[@]}"; do
  echo "$dir" >> "$input_file"
done