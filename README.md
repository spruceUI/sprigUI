# sprigUI

_a twig of spruce_

![Screenshot_20251016-210046](https://github.com/user-attachments/assets/12f9a825-7b78-4cb9-91d5-f15bceb17431)

## What is sprigUI?
sprig is a custom operating system for the Miyoo Mini Flip, developed by the spruceOS team. Our aim with this project is to find a niche somewhere between the intentional simplicity of MinUI and the more visually-oriented user interfaces of OnionOS or spruceOS.

## Features:

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
    - Button press time and number of recents is configurable from the Main Menu -> Settings -> Game Switcher Settings.


- Power Button behavior:
    - Quick tap to sleep/wake.
    - Hold 1-2 seconds for quick save and shutdown; game will autoresume on boot. (short triple vibrate)
    - Hold 3 seconds to force close a frozen app or emulator. (longer double vibrate)
    - Hold 10 seconds to hard shutdown a device as a last resort.


- sprigUI automatically enables wireless ADB and SSH access on boot. You can connect to your device using these services by running the following commands from your computer.
    - ADB: `adb connect 192.168.x.x:5555`
    - SSH: `ssh root@192.168.x.x`

## Special Thanks

- Miyoo for providing us with development units.
- OnionOS team for sharing their wealth of knowledge and a couple of apps.
- Shaun Inman of MinUI for the same.
- XanXic for a lot of the helperFunction code from spruce that we implemented in sprig.
- The thememaking community, including tenlevels, 369px, Kyle Bing, HeyDW, and fagnerpc.

## Need help? Want to contribute?

Come chat with the spruce team in [our Discord server](https://discord.gg/KjR5uMQQt9)!
