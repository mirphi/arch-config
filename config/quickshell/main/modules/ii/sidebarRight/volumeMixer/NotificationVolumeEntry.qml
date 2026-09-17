import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 8
    property bool soundEnabled: Config.options.sounds.notifications

    IconToolbarButton {
        Layout.alignment: Qt.AlignVCenter
        Layout.fillHeight: false
        implicitWidth: 36
        implicitHeight: 36
        text: root.soundEnabled ? "notifications_active" : "notifications_off"
        onClicked: Config.options.sounds.notifications = !root.soundEnabled
        StyledToolTip {
            text: root.soundEnabled ? Translation.tr("Click to mute") : Translation.tr("Click to unmute")
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: -4

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Notifications")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: Config.options.sounds.notificationsVolume + "%"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }

        StyledSlider {
            from: 0
            to: 100
            stepSize: 1
            value: Config.options.sounds.notificationsVolume
            configuration: StyledSlider.Configuration.S
            onMoved: Config.options.sounds.notificationsVolume = Math.round(value)
        }
    }

    IconToolbarButton {
        Layout.alignment: Qt.AlignVCenter
        Layout.fillHeight: false
        implicitWidth: 32
        implicitHeight: 32
        text: "play_arrow"
        enabled: root.soundEnabled
        onClicked: Audio.playSystemSound("elementary-notification", Config.options.sounds.notificationsVolume)
        StyledToolTip { text: Translation.tr("Test sound") }
    }
}
