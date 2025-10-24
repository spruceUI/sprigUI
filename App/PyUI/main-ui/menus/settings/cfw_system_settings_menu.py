
from menus.settings import settings_menu
from utils.cfw_system_config import CfwSystemConfig


class CfwSystemSettingsMenu(settings_menu.SettingsMenu):
    def __init__(self):
        super().__init__()


    def build_options_list(self):
        option_list = []
        
        for category in CfwSystemConfig.get_categories():
            menu_options = self.build_options_list_from_config_menu_options(category)
            option_list.extend(menu_options)

        return option_list
