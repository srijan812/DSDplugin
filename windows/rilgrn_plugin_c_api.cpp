#include "include/rilgrn/rilgrn_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "rilgrn_plugin.h"

void RilgrnPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  rilgrn::RilgrnPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
