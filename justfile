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
