# sprigUI

_a twig of spruce_

![Screenshot_20251016-210046](https://github.com/user-attachments/assets/12f9a825-7b78-4cb9-91d5-f15bceb17431)

## What is sprigUI?
sprig is a custom operating system for the Miyoo Mini Flip, developed by the spruceOS team. Our aim with this project is to find a niche somewhere between the intentional simplicity of MinUI and the more visually-oriented user interfaces of OnionOS or spruceOS.

## Features

- Custom Python-based frontend that can shapeshift between the visual styles of Miyoo's MainUI, Daijisho, MinUI, or even EmulationStation, courtesy of chrisj951.

- Over 60 supported emulated systems, ranging from retro favorites like the Game Boy, to modern fantasy and homebrew consoles such as Pico-8 and GameTank.

- Quick save and shutdown while in game, and boot right back to where you left off.

- Game Switcher to jump back into your most recently played games at any time.

- Scraper app to easily grab box art for your library.

- Over-the-air updates to make updating your device a snap.

- Apps borrowed from our friends on the Onion and MinUI teams, including a file manager, ebook reader, bootlogo flasher, and more.

- SSH and ADB over wifi support for the advanced users.

## Required Firmware

https://github.com/spruceUI/sprigUI/releases/tag/sprigOSv0.0

## Operating Manual

- Game Switcher:
    - Default behavior: Hold Menu button for 1 second to jump to your 5 most recent games.
    - Button press time and number of recents is configurable from the Main Menu -> Settings -> Extra Settings -> Game Switcher Settings.


- Power Button behavior:
    - Quick tap to sleep/wake.
    - Hold 1-2 seconds for quick save and shutdown; game will autoresume on boot. (short triple vibrate)
    - Hold 3 seconds to force close a frozen app or emulator. (longer double vibrate)
    - Hold 10 seconds to hard shutdown a device as a last resort.


- Changing emulator cores for a system:
    - Some systems, such as Game Boy, have multiple emulator options.
    - To launch a system using a different core, press X while in that system's game list, then highlight **Retroarch Core** and press left or right to select your new core, then press B to close this menu and return to the game list. This will set that core as the default for all games in that system.
    - To set an override to get a particular game to always use one core, regardlesss of what default you have set: press X while hovering over the game you wish to set the core association for, then change its **Retroarch Core** as described above. Then, before going back to the game list, press X or Y. An asterisk will appear next to the **Retroarch Core** text, indicating that the override is set.

- Wireless connectivity:
    - sprigUI automatically enables wireless ADB and SSH access on boot. You can connect to your device using these services by running the following commands from your computer.
        - ADB: `adb connect 192.168.x.x:5555`
        - SSH: `ssh root@192.168.x.x`

- Boot Logo flasher
    - Running this app will replace the boot logo on your device with a custom sprigUI logo.
    - Please use this tool responsibly if attempting to use any logo other than the one provided. Custom bootlogos can in some rare instances cause a soft-bricked device. To recover from this state, or to reinstate the stock Miyoo boot logo, place [this firmware](https://github.com/spruceUI/sprigUI/releases/tag/sprigOSv0.0) at the root of your SD card, then, while holding the MENU button, plug the device into a power supply. You can release the MENU button once the "Super Upgrade" rocket comes up - then just let it do its thing and it will eventually reboot.

- DraStic emulator hotkeys:
    - Please see [the readme on Steward Fu's nds repository](https://github.com/steward-fu/nds?tab=readme-ov-file#hotkey) for a list of hotkeys and other DraStic-Steward functions.

## Known Issues

- Pico-8: Audio volume cannot be controlled using the side keys, and can only be manually set in-game by pressing Start -> Options -> Volume.
- OpenBOR: Audio volume cannot be controlled using the side keys, and can only be manually set in-game by pressing Start -> Options -> Volume.

## Special Thanks

- Miyoo for providing us with development units.
- OnionOS team for sharing their wealth of knowledge and a couple of apps.
- Shaun Inman of MinUI for the same.
- XK9274 for the SDL2 build that allows PyUI to even run on this device.
- Steward Fu for all his work on the Miyoo Mini, including but not limited to porting the DraStic emulator.
- XanXic for a lot of the helperFunction code from spruce that we implemented in sprig.
- The thememaking community, including tenlevels, 369px, Kyle Bing, HeyDW, and fagnerpc.

## Need help? Want to contribute?

Come chat with the spruce team in [our Discord server](https://discord.gg/KjR5uMQQt9)!
