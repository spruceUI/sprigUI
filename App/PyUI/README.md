# PyUI for Sprig

The `main-ui/` directory is a **symlink** to `MainPyUI/main-ui/`, which is a git submodule pointing to:
**https://github.com/spruceUI/MainPyUI**

## First-Time Setup

For new contributors cloning this repo:

```bash
git clone https://github.com/spruceUI/sprigUI.git
cd sprigUI
git submodule update --init --recursive
```

The symlink `App/PyUI/main-ui -> MainPyUI/main-ui` is tracked in git and will be created automatically.


## Updating the Shared UI Code

```bash
git submodule update --remote App/PyUI/MainPyUI
git add App/PyUI/MainPyUI
git commit -m "chore: update MainPyUI submodule to latest"
```

## Device-Specific Files (Sprig)

These files are specific to Sprig and should NOT be moved to the shared repo:

- **`launch.sh`**: Sets environment variables and launches PyUI with Sprig-specific paths
  - Uses `/mnt/SDCARD/sprig/` paths
  - Launches with `-device SPRIG_MIYOO_MINI_FLIP`
  - Points to sprig-specific config: `/mnt/SDCARD/Saves/sprig/sprig-config.json`

- **`py-ui-config.json`**: Sprig runtime configuration
  - Theme directory paths
  - UI preferences
  - Device-specific settings

- **`lang/`**: Language files with Sprig-specific text overrides
  - Currently has minor differences from upstream (e.g., "Reload UI" vs "Exit PyUI")

- **`python3.10/`**: ARM Python runtime and libraries (device-specific build)

- **`libs/`**: SDL2 and other shared libraries compiled for Miyoo Mini Flip

### Working on Sprig-Specific Code
When making Sprig-only changes:

1. Edit files in `App/PyUI/` (launch.sh, config files, etc.)
2. Commit directly to sprigUI repo
3. No submodule update needed