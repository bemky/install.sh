source ./config
source ./utils.sh

# COLOR
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#########
# Start #
#########

clear
echo "BACKUP.sh"

if [[ ! -z $MIGRATION_DIRS ]]; then
  for dir dest in ${(kv)MIGRATION_DIRS}; do
    copy_children $dir $dest
  done
fi