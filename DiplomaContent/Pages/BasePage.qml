// Base page component providing background image and focus-clearing mouse area.
import QtQuick
import QtQuick.Controls.Basic

Page {
    id: basePage
    anchors.fill: parent
    property string backgroundImage: "../images/REG.png"
    MouseArea {
               anchors.fill: parent
               onClicked: forceActiveFocus()
    }
}
