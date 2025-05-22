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

# --- Script Logic ---

echo "Starting dotfiles update process..."
echo "Changing directory to $DOTFILES_REPO_DIR"
cd "$DOTFILES_REPO_DIR" || {
    echo "Error: Could not navigate to $DOTFILES_REPO_DIR. Aborting."
    exit 1
}

# --- Update Submodules ---
echo ""
echo "Updating Git submodules (like .oh-my-zsh)..."
# This will fetch the latest from their configured remotes and check out the default branch
# Or, more precisely, it updates them to the commit specified in the superproject if they are "out of sync"
# or pulls the latest from their remote if you use `git submodule update --remote`
# For simply pulling the latest from the submodule's own default branch:
if [ -d ".oh-my-zsh" ] && [ -d ".oh-my-zsh/.git" ]; then # Check if it's a directory and a git repo (submodule)
    echo "Updating .oh-my-zsh submodule..."
    ( # Run in a subshell to not change the main script's directory
        cd .oh-my-zsh
        git pull origin master # Or main, or whatever branch OMZ uses
        # If you want it to update to the specific commit registered in the superproject (less common for this script's purpose)
        # you'd use `git submodule update --init --recursive .oh-my-zsh` from the parent dir.
        # But usually for "updating dotfiles" you want the latest from the submodule's source.
    )
    echo ".oh-my-zsh submodule updated."
else
    echo "Warning: .oh-my-zsh is not a recognized submodule or does not exist. Skipping submodule update."
fi
# You might want to do this for all submodules if you have more:
# git submodule update --init --remote --recursive # Fetches latest from remote for all submodules

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
