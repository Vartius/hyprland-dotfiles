#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
DOTFILES_REPO_DIR="$HOME/Downloads/dotfiles"
CONFIG_DIRS_TO_COPY=(
    "alacritty" "gtk-2.0" "gtk-3.0" "gtk-4.0" "hypr"
    "neofetch" "nvim" "nwg-look" "rofi" "tmux" "waybar"
)
HOME_FILES_TO_COPY=(
    ".zshrc"
)
# Add .oh-my-zsh to a new list or handle it specially
# For simplicity, let's assume you want to sync the whole thing
OH_MY_ZSH_SOURCE="$HOME/.oh-my-zsh"
OH_MY_ZSH_DEST="$DOTFILES_REPO_DIR/.oh-my-zsh"

# --- Script Logic ---

echo "Starting dotfiles update process..."
echo "Changing directory to $DOTFILES_REPO_DIR"
cd "$DOTFILES_REPO_DIR" || {
    echo "Error: Could not navigate to $DOTFILES_REPO_DIR. Aborting."
    exit 1
}

# Remove the old submodule update logic if it was there

TARGET_CONFIG_DIR="$DOTFILES_REPO_DIR/.config"
echo "Ensuring $TARGET_CONFIG_DIR exists..."
mkdir -p "$TARGET_CONFIG_DIR"

echo ""
echo "Copying .config directories..."
for dir_name in "${CONFIG_DIRS_TO_COPY[@]}"; do
    SOURCE_PATH="$HOME/.config/$dir_name"
    DEST_PATH="$TARGET_CONFIG_DIR/$dir_name"
    if [ -d "$SOURCE_PATH" ]; then
        echo "Syncing $SOURCE_PATH/ to $DEST_PATH/"
        rsync -avh --delete "$SOURCE_PATH/" "$DEST_PATH/"
    else
        echo "Warning: Source directory $SOURCE_PATH not found. Skipping."
    fi
done

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

# Sync .oh-my-zsh directory
echo ""
echo "Syncing .oh-my-zsh directory..."
if [ -d "$OH_MY_ZSH_SOURCE" ]; then
    echo "Syncing $OH_MY_ZSH_SOURCE/ to $OH_MY_ZSH_DEST/"
    mkdir -p "$OH_MY_ZSH_DEST" # Ensure destination exists
    # Be careful with --delete here. If OMZ generates cache or logs you don't want in the repo,
    # you might want a .gitignore inside $OH_MY_ZSH_DEST or exclude them in rsync.
    # For a full mirror:
    rsync -avh --delete --exclude '.git/' --exclude 'cache/' --exclude 'log/' "$OH_MY_ZSH_SOURCE/" "$OH_MY_ZSH_DEST/"
    # The --exclude '.git/' is important if your source ~/.oh-my-zsh is a git repo itself.
    # You might want to refine --exclude further based on what's in your ~/.oh-my-zsh (e.g., 'custom/plugins/some_plugin_with_its_own_git/')
else
    echo "Warning: Source directory $OH_MY_ZSH_SOURCE not found. Skipping .oh-my-zsh sync."
fi

echo ""
echo "Git operations..."
echo "Staging changes (git add .)"
git add .

if git diff --staged --quiet; then
    echo "No changes to commit. Dotfiles are up-to-date."
else
    COMMIT_MESSAGE="Automated dotfiles update: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "Committing changes with message: \"$COMMIT_MESSAGE\""
    git commit -m "$COMMIT_MESSAGE"
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
