import QtQuick
import Quickshell

import qs.modules.ii.bar
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.notificationPopup
import qs.modules.ii.sidebarRight

Scope {
    PanelLoader { component: Bar {} }
    PanelLoader { component: OnScreenKeyboard {} }

    // Всплывающие уведомления
    PanelLoader { component: NotificationPopup {} }

    // История уведомлений и быстрые настройки
    PanelLoader { component: SidebarRight {} }
}
