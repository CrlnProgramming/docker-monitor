#!/bin/bash

overlay_dir="/var/lib/docker/overlay2"

temp_file=$(mktemp)

used_subfolders=()

for image_id in $(docker image ls -q); do
  
  image_info=$(docker inspect "$image_id")

  repo_tag=$(docker inspect --format '{{index .RepoTags 0}}' "$image_id")

  while IFS= read -r -d '' subfolder; do
    if echo "$image_info" | grep -q "$subfolder"; then
      space_used=$(du -sh "$subfolder" | cut -f1)

      space_used_bytes=$(du -sb "$subfolder" | cut -f1)

      echo "$space_used_bytes $space_used Image ID: $image_id Image Name: $repo_tag Subfolder: $subfolder" >> "$temp_file"

      used_subfolders+=("$subfolder")
    fi
  done < <(find "$overlay_dir" -maxdepth 1 -mindepth 1 -type d -print0)
done

while IFS= read -r -d '' subfolder; do
  if ! [[ " ${used_subfolders[@]} " =~ " $subfolder " ]]; then
    space_used=$(du -sh "$subfolder" | cut -f1)

    space_used_bytes=$(du -sb "$subfolder" | cut -f1)

    echo "$space_used_bytes $space_used Image ID: N/A Image Name: N/A Subfolder: $subfolder" >> "$temp_file"
  fi
done < <(find "$overlay_dir" -maxdepth 1 -mindepth 1 -type d -print0)

sort -nr "$temp_file" | cut -d' ' -f2- | column -t

rm "$temp_file"
