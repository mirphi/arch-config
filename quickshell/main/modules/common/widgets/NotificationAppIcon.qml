import qs.modules.common
import qs.modules.common.functions
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

MaterialShape { // App icon
    id: root
    property var appIcon: ""
    property var summary: ""
    property var urgency: NotificationUrgency.Normal
    property bool isUrgent: urgency === NotificationUrgency.Critical
    property var image: ""
    property string appName: ""
    property string desktopEntry: ""
    property bool appIconFailed: false
    property bool imageFailed: false
    property real materialIconScale: 0.57
    property real appIconScale: 0.8
    property real smallAppIconScale: 0.49
    property real materialIconSize: implicitSize * materialIconScale
    property real appIconSize: implicitSize * appIconScale
    property real smallAppIconSize: implicitSize * smallAppIconScale

    function resolveIcon(iconName) {
        const icon = String(iconName ?? "").trim();
        if (icon === "") return "";

        const iconProviderPrefix = "image://icon/";
        if (icon.startsWith(iconProviderPrefix)) {
            const request = icon.slice(iconProviderPrefix.length).split("?")[0];
            if (request.startsWith("/")) return icon;
            return Quickshell.hasThemeIcon(request) ? Quickshell.iconPath(request) : "";
        }

        if (icon.startsWith("image://") || icon.startsWith("file:") ||
                icon.startsWith("qrc:") || icon.startsWith("/"))
            return icon;
        return Quickshell.hasThemeIcon(icon) ? Quickshell.iconPath(icon) : "";
    }

    readonly property string directAppIcon: resolveIcon(root.appIcon)
    readonly property string guessedAppIconName: {
        if (root.desktopEntry !== "") return AppSearch.guessIcon(root.desktopEntry);
        if (root.appName !== "") return AppSearch.guessIcon(root.appName);
        return "";
    }
    readonly property string resolvedAppIcon: root.directAppIcon || resolveIcon(root.guessedAppIconName)
    readonly property string resolvedNotificationImage: resolveIcon(root.image)
    readonly property bool hasAppIcon: root.resolvedAppIcon !== "" && !root.appIconFailed
    readonly property bool hasNotificationImage: root.resolvedNotificationImage !== "" && !root.imageFailed

    onResolvedAppIconChanged: root.appIconFailed = false
    onResolvedNotificationImageChanged: root.imageFailed = false

    implicitSize: 38 * scale
    property list<var> urgentShapes: [
        MaterialShape.Shape.VerySunny,
        MaterialShape.Shape.SoftBurst,
    ]
    shape: isUrgent ? urgentShapes[Math.floor(Math.random() * urgentShapes.length)] : MaterialShape.Shape.Circle

    color: isUrgent ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer
    Loader {
        id: materialSymbolLoader
        active: !root.hasAppIcon && !root.hasNotificationImage
        anchors.fill: parent
        sourceComponent: MaterialSymbol {
            text: {
                const defaultIcon = NotificationUtils.findSuitableMaterialSymbol("")
                const guessedIcon = NotificationUtils.findSuitableMaterialSymbol(root.summary)
                return (root.urgency == NotificationUrgency.Critical && guessedIcon === defaultIcon) ?
                    "priority_high" : guessedIcon
            }
            anchors.fill: parent
            color: isUrgent ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
            iconSize: root.materialIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    Loader {
        id: appIconLoader
        active: !root.hasNotificationImage && root.hasAppIcon
        anchors.centerIn: parent
        sourceComponent: IconImage {
            id: appIconImage
            implicitSize: root.appIconSize
            asynchronous: true
            source: root.resolvedAppIcon
            onStatusChanged: {
                if (status === Image.Error) root.appIconFailed = true;
            }
        }
    }
    Loader {
        id: notifImageLoader
        active: root.hasNotificationImage
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            StyledImage {
                id: notifImage
                anchors.fill: parent
                readonly property int size: parent.width

                source: root.resolvedNotificationImage
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true
                asynchronous: true

                onStatusChanged: {
                    if (status === Image.Error) root.imageFailed = true;
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: notifImage.size
                        height: notifImage.size
                        radius: Appearance.rounding.full
                    }
                }
            }
            Loader {
                id: notifImageAppIconLoader
                active: root.hasAppIcon
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                sourceComponent: IconImage {
                    implicitSize: root.smallAppIconSize
                    asynchronous: true
                    source: root.resolvedAppIcon
                    onStatusChanged: {
                        if (status === Image.Error) root.appIconFailed = true;
                    }
                }
            }
        }
    }
}
