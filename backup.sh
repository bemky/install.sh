source ./config
source ./utils.sh

# COLOR
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "BACKUP.sh"

# Sync Files
echo
echo "${GREEN}SYNCING"
echo
if [[ ! -z $SYNC_FILES ]]; then
  for file in "${SYNC_FILES[@]}"; do
    dest=$(echo "$file" | sed 's/~/$SYNC_DIR')
    mkdir -p $dest
    cp $file $dest
    rm $file
    ln -s $dest $file
  done
fi

echo
echo "${GREEN}MIGRATING"
echo
if [[ ! -z $MIGRATION_DIRS ]]; then
  for dir dest in ${(kv)MIGRATION_DIRS}; do
    copy_children $dir $dest
  done
fi