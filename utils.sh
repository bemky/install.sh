contains_any_substring() {
  local main_string="$1"
  shift
  
  for substr in "$@"; do
    if [[ "$main_string" == *"$substr"* ]]; then
      return 0
    fi
  done
  return 1
}


copy_children () {
  # Usage: copy_children <parent_dir> <destination_dir>
  # Example: copy_children "../src" "../dest"
  setopt extended_glob
  setopt glob_dots
  setopt null_glob
  local dest="$2"
  local dir=$1
  local files="$dir/*(.D)"
  local folders="$dir/*(/D)"
  mkdir -p "$dest"
  echo "Migrating: $dir"
  
  for file in ${~files}; do
    mkdir -p $dest
    cp $file $dest
  done
  
  for folder_path in ${~folders}; do
    if contains_any_substring $folder_path $MIGRATION_IGNORES; then
      continue
    else
      folder=${folder_path##*/}
      copy_children $folder_path "$dest/$folder"
    fi
  done
}