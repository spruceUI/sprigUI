# List available recipes
default:
    @just --list

# Build a release archive
build:
    @echo "Building release..."
    @bash build/create_sprig_release.sh

# Clean build artifacts
clean:
    @echo "Cleaning build artifacts..."
    @rm -rf dist/*.7z
    @echo "Clean complete"

# Update PyUI submodule to latest from MainPyUI
update-pyui:
    #!/usr/bin/env bash
    echo "Updating PyUI submodule to latest..."
    cd App/PyUI/MainPyUI
    git fetch origin
    git checkout main
    git pull origin main
    echo "Submodule updated to: $(git log -1 --oneline)"
    echo ""
    echo "To commit this update:"
    echo "  git add App/PyUI/MainPyUI"
    echo "  git commit -m 'chore: update PyUI to latest'"

# Check PyUI submodule status and show what would be updated
check-pyui:
    #!/usr/bin/env bash
    cd App/PyUI/MainPyUI
    echo "Current PyUI version:"
    git log -1 --oneline
    echo ""
    echo "Latest available version:"
    git fetch origin main --quiet
    git log origin/main -1 --oneline
    echo ""
    CURRENT=$(git rev-parse HEAD)
    LATEST=$(git rev-parse origin/main)
    if [ "$CURRENT" != "$LATEST" ]; then
        echo "Updates available! Run 'just update-pyui' to update."
    else
        echo "✓ Already up to date"
    fi

