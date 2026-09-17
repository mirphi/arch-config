//@ pragma IconTheme Papirus-Dark

import qs.modules.common
import qs.panelFamilies

import QtQuick
import QtQuick.Window
import Quickshell

ShellRoot {
    id: root

    // Stuff for every panel family
    ReloadPopup {}

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.panelFamily === identifier && extraCondition
    }
    
    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }
}
