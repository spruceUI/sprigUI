
from devices.device import Device
from display.resize_type import ResizeType
from menus.games.recents_menu import RecentsMenu
from views.view_type import ViewType


class RecentsMenuGS(RecentsMenu):
    def __init__(self):
        super().__init__()

    def get_view_type(self):
        return ViewType.FULLSCREEN_GRID
    
    def full_screen_grid_resize_type(self):
        return ResizeType.FIT

    def get_set_top_bar_text_to_game_selection(self):
        return True
    
    def run_rom_selection(self) :
        return self._run_rom_selection("Game Switcher")

    def get_amount_of_recents_to_allow(self):
        return Device.get_system_config().game_switcher_game_count()

    def default_to_last_game_selection(self):
        return False
   