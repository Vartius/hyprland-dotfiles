#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Path to your dotfiles repository
DOTFILES_REPO_DIR="$HOME/Downloads/dotfiles"

# Source directories in $HOME/.config to copy
# These will be copied to $DOTFILES_REPO_DIR/.config/
CONFIG_DIRS_TO_COPY=(
    "alacritty"
    "gtk-2.0"
    "gtk-3.0"
    "gtk-4.0"
    "hypr"
    "neofetch"
    "nvim"
    "nwg-look"
    "rofi"
    "tmux"
    "waybar"
)

# Individual files in $HOME to copy
# These will be copied to $DOTFILES_REPO_DIR/
HOME_FILES_TO_COPY=(
    ".zshrc"
)

# --- Script Logic ---

echo "Starting dotfiles update process..."

# Navigate to the dotfiles repository
echo "Changing directory to $DOTFILES_REPO_DIR"
cd "$DOTFILES_REPO_DIR" || {
    echo "Error: Could not navigate to $DOTFILES_REPO_DIR. Aborting."
    exit 1
}

# Ensure the .config directory exists in the repo
TARGET_CONFIG_DIR="$DOTFILES_REPO_DIR/.config"
echo "Ensuring $TARGET_CONFIG_DIR exists..."
mkdir -p "$TARGET_CONFIG_DIR"

# Copy .config subdirectories
echo ""
echo "Copying .config directories..."
for dir_name in "${CONFIG_DIRS_TO_COPY[@]}"; do
    SOURCE_PATH="$HOME/.config/$dir_name"
    DEST_PATH="$TARGET_CONFIG_DIR/$dir_name"

    if [ -d "$SOURCE_PATH" ]; then
        echo "Syncing $SOURCE_PATH/ to $DEST_PATH/"
        # rsync -avh --delete source/ destination/
        # --delete will remove files in destination that are not in source
        rsync -avh --delete "$SOURCE_PATH/" "$DEST_PATH/"
    else
        echo "Warning: Source directory $SOURCE_PATH not found. Skipping."
    fi
done

# Copy individual files from $HOME
echo ""
echo "Copying files from HOME directory..."
for file_name in "${HOME_FILES_TO_COPY[@]}"; do
    SOURCE_PATH="$HOME/$file_name"
    DEST_PATH="$DOTFILES_REPO_DIR/$file_name"

    if [ -f "$SOURCE_PATH" ]; then
        echo "Syncing $SOURCE_PATH to $DEST_PATH"
        rsync -avh "$SOURCE_PATH" "$DEST_PATH"
    else
        echo "Warning: Source file $SOURCE_PATH not found. Skipping."
    fi
done

# Note on .oh-my-zsh:
# The tree output shows .oh-my-zsh already exists in your dotfiles repo.
# If it's a git submodule, you should update it separately if needed:
#   git submodule update --remote .oh-my-zsh
# This script will simply commit its current state within your dotfiles repo.
# If you run 'omz update' (which updates ~/.oh-my-zsh), and .oh-my-zsh in your
# dotfiles repo is a submodule, 'git status' in DOTFILES_REPO_DIR will show
# '.oh-my-zsh' as modified (new commits). 'git add .oh-my-zsh' will stage this.
# If it's just a copy, then you'd need to rsync $HOME/.oh-my-zsh/ to $DOTFILES_REPO_DIR/.oh-my-zsh/
# For simplicity, and given the .git inside, this script assumes it's managed
# (either as submodule or you manually keep it in sync and just want to commit changes).

echo ""
echo "Git operations..."
# Add all changes to staging
echo "Staging changes (git add .)"
git add .

# Check if there are any changes to commit
if git diff --staged --quiet; then
    echo "No changes to commit. Dotfiles are up-to-date."
else
    # Commit changes
    COMMIT_MESSAGE="Automated dotfiles update: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "Committing changes with message: \"$COMMIT_MESSAGE\""
    git commit -m "$COMMIT_MESSAGE"

    # Ask to push
    echo ""
    read -p "Do you want to push changes to the remote repository? (y/N): " PUSH_CHOICE
    if [[ "$PUSH_CHOICE" =~ ^[Yy]$ ]]; then
        echo "Pushing changes..."
        git push
        echo "Changes pushed."
    else
        echo "Skipping push. Run 'git push' manually if desired."
    fi
fi

echo ""
echo "Dotfiles update process finished."
