import QtQuick
import QtQuick.Controls

Switch {

    property alias switchWidth: switchIndicator.implicitWidth
    property alias switchHeight: switchIndicator.implicitHeight
    property alias textSize: switchText.font.pointSize
    //define of presenter

    id: mainSwitch
    font.family: "Montserrat"
    contentItem: Text {

        id: switchText
        font: mainSwitch.font
        color: "#daf1de"
        text: parent.text
        verticalAlignment: Text.AlignVCenter
        leftPadding: mainSwitch.indicator.width + mainSwitch.spacing
    }

    indicator: Rectangle {
        id: switchIndicator
        implicitHeight: 26
        implicitWidth: 48
        x: mainSwitch.leftPadding
        y: parent.height / 2 - height / 2
        radius: 13
        color: mainSwitch.checked ? "#163832" : "#9eb69b"
        border.color: mainSwitch.checked ? "#8eb69b" : "#8eb69b"
        border.width: 2

        Rectangle {
            id: switchHandle
            x: mainSwitch.checked ? parent.width - width : 0
            width: 26
            height: 26
            radius: 13
            color: mainSwitch.down ? "#0b2b26" : "#8eb69b"
            border.color: mainSwitch.checked ? "#163832" : "#235347"
            border.width: 2

            Behavior on x {
                NumberAnimation {
                    duration: 200
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }
    }

    onToggled: {
        //logic with presenter
    }
}
