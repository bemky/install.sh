#!/bin/zsh
# ==============================================================================
# Title: install.sh
# Author: Daniel Vier
# Email: daniel.vier@gmail.com
# Description: Automates the setup and configuration of macOS, including
#              installation of essential applications and system preferences.
# Last Updated: March 1, 2024
# ==============================================================================

source ./config

# COLOR
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#########
# Start #
#########

clear
echo " _           _        _ _       _     "
echo "(_)         | |      | | |     | |    "
echo " _ _ __  ___| |_ __ _| | |  ___| |__  "
echo "| | |_ \/ __| __/ _  | | | / __| |_ \ "
echo "| | | | \__ \ || (_| | | |_\__ \ | | |"
echo "|_|_| |_|___/\__\__,_|_|_(_)___/_| |_|"
echo
echo
echo Enter root password

# Ask for the administrator password upfront.
sudo -v

# Keep Sudo until script is finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

# Update macOS
echo
echo "${GREEN}Looking for updates.."
echo
sudo softwareupdate -i -a

# Install Rosetta
# sudo softwareupdate --install-rosetta --agree-to-license

# Install Homebrew
echo
echo "${GREEN}Installing Homebrew"
echo
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Append Homebrew initialization to .zprofile
# echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>${HOME}/.zprofile
# Immediately evaluate the Homebrew environment settings for the current session
# eval "$(/opt/homebrew/bin/brew shellenv)"
# ^^^ unsure what this does -BE

# Check installation and update
echo
echo "${GREEN}Checking installation.."
echo
brew update && brew doctor
export HOMEBREW_NO_INSTALL_CLEANUP=1

# Check for Brewfile in the current directory and use it if present
if [ -f "./Brewfile" ]; then
  echo
  echo "${GREEN}Brewfile found. Using it to install packages..."
  brew bundle
  echo "${GREEN}Installation from Brewfile complete."
else
  # If no Brewfile is present, continue with the default installation

  # Install Casks and Formulae
  echo
  echo "${GREEN}Installing formulae..."
  for formula in "${FORMULAE[@]}"; do
    brew install "$formula"
    if [ $? -ne 0 ]; then
      echo "${RED}Failed to install $formula. Continuing...${NC}"
    fi
  done

  echo "${GREEN}Installing casks..."
  for cask in "${CASKS[@]}"; do
    brew install --cask "$cask"
    if [ $? -ne 0 ]; then
      echo "${RED}Failed to install $cask. Continuing...${NC}"
    fi
  done

  # App Store
  if ${#APPSTORE[@]} > 0; then
    echo
    echo -n "${RED}Installing apps from App Store...${NC}"
    brew install mas
    for app in "${APPSTORE[@]}"; do
      eval "mas install $app"
    done
  fi
fi

# VS Code Extensions
if ${#VSCODE[@]} > 0; then
  echo
  echo -n "${RED}Installing VSCode Extensions...${NC}"
  for extension in "${VSCODE[@]}"; do
    code --install-extension "$extension"
  done
fi

# Install Node.js if not Installed by Brew
if ${#NPMPACKAGES[@]} > 0; then
  if brew ls --versions node == /dev/null; then
    echo
    echo -n "${RED}Install Node.js via NVM or Brew? ${NC}[N/b]"
    read REPLY
    if [[ -z $REPLY || $REPLY =~ ^[Nn]$ ]]; then
      echo "${GREEN}Installing NVM..."
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

      # Loads NVM
      export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

      echo "${GREEN}Installing Node via NVM..."
      nvm install --lts
      nvm install node
      nvm alias default node
      nvm use default

    fi
    if [[ $REPLY =~ ^[Bb]$ ]]; then
      echo "${GREEN}Installing Node via Homebrew..."
      brew install node
    fi
  fi

  # Install NPM Packages
  echo
  echo "${GREEN}Installing Global NPM Packages..."
  npm install -g ${NPMPACKAGES[@]}
fi

# Cleanup
echo
echo "${GREEN}Cleaning up..."
brew update && brew upgrade && brew cleanup && brew doctor
mkdir -p ~/Library/LaunchAgents
brew tap homebrew/autoupdate
brew autoupdate start $HOMEBREW_UPDATE_FREQUENCY --upgrade --cleanup --immediate --sudo

# Settings
echo
echo -n "${RED}Configure default system settings? ${NC}[Y/n]"
read REPLY
if [[ -z $REPLY || $REPLY =~ ^[Yy]$ ]]; then
  echo "${GREEN}Configuring default settings..."
  for setting in "${SETTINGS[@]}"; do
    eval $setting
  done
fi

# Dock settings
echo
echo -n "${RED}Apply Dock settings?? ${NC}[y/N]"
read REPLY
if [[ $REPLY =~ ^[Yy]$ ]]; then
  brew install dockutil
  # Handle replacements
  for item in "${DOCK_REPLACE[@]}"; do
    IFS="|" read -r add_app replace_app <<<"$item"
    dockutil --add "$add_app" --replacing "$replace_app" &>/dev/null
  done
  # Handle additions
  for app in "${DOCK_ADD[@]}"; do
    dockutil --add "$app" &>/dev/null
  done
  # Handle removals
  for app in "${DOCK_REMOVE[@]}"; do
    dockutil --remove "$app" &>/dev/null
  done
fi

# Git Login
echo
echo "${GREEN}SET UP GIT"
echo

echo "${RED}Please enter your git username:${NC}"
read name
echo "${RED}Please enter your git email:${NC}"
read email

git config --global user.name "$name"
git config --global user.email "$email"
git config --global color.ui true

echo
echo "${GREEN}GITTY UP!"

# Sync Files
echo
echo "${GREEN}SYNCING"
echo
if [[ ! -z $SYNC_FILES ]]; then
  echo -n "${RED}Proceed to syncing $SYNC_DIR? ${NC}[c]"
  read REPLY
  if [[ $REPLY =~ ^[Cc]$ ]]; then
    for file in "${SYNC_FILES[@]}"; do
      dest=$(echo "$file" | sed 's/~/$SYNC_DIR')
      mkdir -p $dest
      ln -s $dest $file
    done
  fi
fi

# Migrate Files
echo
echo "${GREEN}MIGRATING"
echo
if [[ ! -z $MIGRATION_DIRS ]]; then
  echo -n "${RED}Proceed to migrating $dir? ${NC}[c]"
  read REPLY
  if [[ $REPLY =~ ^[Cc]$ ]]; then
    for dest dir in ${(kv)MIGRATION_DIRS}; do
      copy_children $dir $dest
    done
  fi
fi

clear
echo "${GREEN}______ _____ _   _  _____ "
echo "${GREEN}|  _  \  _  | \ | ||  ___|"
echo "${GREEN}| | | | | | |  \| || |__  "
echo "${GREEN}| | | | | | | .   ||  __| "
echo "${GREEN}| |/ /\ \_/ / |\  || |___ "
echo "${GREEN}|___/  \___/\_| \_/\____/ "

echo
echo
printf "${RED}"
read -s -k $'?Press ANY KEY to REBOOT\n'
sudo reboot
exit
