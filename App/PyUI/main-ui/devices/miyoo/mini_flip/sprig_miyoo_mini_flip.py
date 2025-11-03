

from devices.miyoo.mini_flip.miyoo_mini_flip import MiyooMiniFlip
from devices.utils.process_runner import ProcessRunner
from utils.logger import PyUiLogger
import math


class SprigMiyooMiniFlip(MiyooMiniFlip):
    def __init__(self, device_name):
        super().__init__(device_name)

    def _set_lumination_to_config(self):
        """Set backlight using Sprig's helper functions"""
        try:
            backlight = self.system_config.backlight
            # Call the shell script helper function to set backlight
            ProcessRunner.run([
                "/bin/sh", "-c",
                f". /mnt/SDCARD/sprig/helperFunctions.sh && set_backlight {backlight}"
            ])
            PyUiLogger.get_logger().info(f"Sprig backlight set to {backlight}")
        except Exception as e:
            PyUiLogger.get_logger().error(f"Failed to set Sprig backlight: {e}")

    def get_volume(self):
        """Get volume from system config instead of mainui_volume"""
        return self.system_config.get_volume()

    def change_volume(self, amount):
        """Override to handle Sprig's 0-50 volume range (displays as 0-10)"""
        from display.display import Display
        self.system_config.reload_config()
        
        # Get current volume (0-50 range for display as 0-10)
        volume = self.get_volume() + amount
        
        # Clamp to 0-50 for Sprig
        if volume < 0:
            volume = 0
        elif volume > 50:
            volume = 50
        
        self._set_volume(volume)
        
        Display.volume_changed(self.get_volume())
        PyUiLogger.get_logger().info(f"Volume changed by {amount} to {volume}")

    def _set_volume(self, volume: int) -> int:
        """Set volume using Sprig's helper functions"""
        try:
            # Clamp volume between 0 and 50 (displays as 0-10)
            volume = max(0, min(50, volume))
            
            # Scale for the shell script
            volume_scaled = int(volume * 20 / 50)  # Maps 0-50 to 0-20
            
            ProcessRunner.run([
                "/bin/sh", "-c",
                f". /mnt/SDCARD/sprig/helperFunctions.sh && set_volume {volume_scaled}"
            ])
            
            self.system_config.set_volume(volume)
            self.system_config.save_config()
            
            PyUiLogger.get_logger().info(f"Sprig volume set to {volume} (scaled to {volume_scaled} for hardware)")
            return volume
        except Exception as e:
            PyUiLogger.get_logger().error(f"Failed to set Sprig volume: {e}")
            return volume