# sprigUI

_a twig of spruce_

![Screenshot_20251016-210046](https://github.com/user-attachments/assets/12f9a825-7b78-4cb9-91d5-f15bceb17431)

## What is sprigUI?
sprig is a custom operating system for the Miyoo Mini Flip, developed by the spruceOS team. Our aim with this project is to find a niche somewhere between the intentional simplicity of MinUI and the more visually-oriented user interfaces of OnionOS or spruceOS.

## Installation

[Please check out our Wiki page for detailed instructions.](https://github.com/spruceUI/sprigUI/wiki/1.-Installation-Instructions)

[You will also need to Flash the new Miyoo Firmware to fix shoulder button mappings being swapped on brand new units.](https://github.com/spruceUI/sprigUI/wiki/2.-Updating-the-Onboard-Miyoo-Firmware) 

## Features

- Custom Python-based frontend that can shapeshift between the visual styles of Miyoo's MainUI, Daijisho, MinUI, or even EmulationStation, courtesy of chrisj951.

- Over 60 supported emulated systems, ranging from retro favorites like the Game Boy, to modern fantasy and homebrew consoles such as Pico-8 and GameTank.

- Quick save and shutdown while in game, and boot right back to where you left off.

- Game Switcher to jump back into your most recently played games at any time.

- Scraper app to easily grab box art for your library.

- Over-the-air updates to make updating your device a snap.

- The Game Nursery returns: an OTA free homebrew downloader, straight to your device.

- SSH, Telnet, Samba, and ADB over wifi support for the advanced users.

## Required Firmware

[Official Firmware From Miyoo](https://github.com/spruceUI/sprigUI/releases/download/Official_Miyoo_Firmware/miyoo285_fw.img)

## Operating Manual

- Universal hotkeys:
    - Launch Game Switcher: Hold MENU button
    - Brightness up/down: SELECT + Volume keys

- RetroArch hotkeys:
    - Screenshot: SELECT + A
    - Exit to sprigUI: SELECT + B
    - Open menu: SELECT + X
    - Toggle FPS display: SELECT + Y
    - Load state: SELECT + L1
    - Save state: SELECT + R1
    - Toggle slow-motion: SELECT + L2
    - Toggle fast-forward: SELECT + R2
    - Cycle state slots: SELECT + D-Pad LEFT/D-Pad RIGHT

- DraStic emulator hotkeys:
    - Please see [the readme on Steward Fu's nds repository](https://github.com/steward-fu/nds?tab=readme-ov-file#hotkey) for a list of hotkeys and other DraStic-Steward functions.

- Power Button behavior:
    - Quick tap to sleep/wake.
    - Hold 1-2 seconds for quick save and shutdown; game will autoresume on boot. (short triple vibrate)
    - Hold 3 seconds to force close a frozen app or emulator. (longer double vibrate)
    - Hold 10 seconds to hard shutdown the device as a last resort.

- Changing emulator cores for a system:
    - Some systems, such as Game Boy, have multiple emulator options.
    - To launch a system using a different core, press X while in that system's game list, then highlight **Retroarch Core** and press left or right to select your new core, then press B to close this menu and return to the game list. This will set that core as the default for all games in that system.
    - To set an override to get a particular game to always use one core, regardlesss of what default you have set: press X while hovering over the game you wish to set the core association for, then change its **Retroarch Core** as described above. Then, before going back to the game list, press X or Y. An asterisk will appear next to the **Retroarch Core** text, indicating that the override is set.

- Native Pico-8
    - By placing your own copies of `pico8.dat` and `pico8_dyn` (from the "Raspberry Pi" version of [Pico-8](https://www.lexaloffle.com/pico-8.php)) directly in your `BIOS/` folder, you will gain access to the Pico-8 system in your Games section. From there, if you are connected to Wi-Fi, you can launch Splore, a wonderful repository of hundreds of free games. You can also add your own games to `Roms/PICO8` and launch them directly through sprigUI.
    - Please note that without these commercial binaries, you can instead use the `Roms/FAKE08` folder, which allows you to emulate Pico-8, but without Splore access.

- Wireless connectivity:
    - sprigUI comes with wireless ADB enabled by default. You can also enable additional connectivity options by going to Settings -> CFW System Settings -> Network Settings. If set to "True", you can connect to your device using these services by running the following commands from your computer. (Reload the UI after toggling for the services to launch or close.) The username and password for each of these, if prompted, are `sprig` and `happygaming`, respectively.
        - ADB: `adb connect 192.168.x.x:5555`
        - SSH: `ssh sprig@192.168.x.x`
        - Samba: Enter `smb://192.168.x.x/SDCARD` in your OS's file browser.
        - Telnet: `telnet 192.168.x.x`
        - Syncthing: `http://192.168.x.x:8384` in your web browser.

- Box Art Scraper
    - Run this app to automatically search the LibRetro thumbnails database for box art matching the names of your Roms.
    - Press the MENU button at any time to stop scraping.

- Boot Logo flasher
    - Running this app will replace the boot logo on your device with a custom sprigUI logo.
    - Please use this tool responsibly if attempting to use any logo other than the one provided. Custom bootlogos can in some rare instances cause a soft-bricked device. To recover from this state, or to reinstate the stock Miyoo boot logo, place [this firmware](https://github.com/spruceUI/sprigUI/releases/tag/sprigOSv0.0) at the root of your SD card, then, while holding the MENU button, plug the device into a power supply. You can release the MENU button once the "Super Upgrade" rocket comes up - then just let it do its thing and it will eventually reboot.


## Known Issues

- Pico-8: Audio volume cannot be controlled using the side keys, and can only be manually set in-game by pressing Start -> Options -> Volume.
- OpenBOR: Audio volume cannot be controlled using the side keys, and can only be manually set in-game by pressing Start -> Options -> Volume.

## Special Thanks

- Miyoo for providing us with development units.
- OnionOS team for sharing their wealth of knowledge, a couple of apps, and an updated RetroArch + cores.
- Shaun Inman of MinUI for the same.
- XK9274 for the SDL2 build that allows PyUI to even run on this device.
- Steward Fu for all his work on the Miyoo Mini, including but not limited to porting the DraStic emulator.
- XanXic for a lot of the helperFunction code from spruce that we implemented in sprig.
- The thememaking community, including tenlevels, 369px, Kyle Bing, HeyDW, Anthony Caccese, and fagnerpc.
- [Icons8.com](icons8.com) for the logo, icons and their generosity in giving us expanded access to icons for our projects.

## Need help? Want to contribute?

Come chat with the spruce team in [our Discord server](https://discord.gg/KjR5uMQQt9)!


