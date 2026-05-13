import QtQuick
import QtQuick.Controls

CheckBox {
    id: checkBox
    property alias checkText: checkBoxText.text
    property alias checkTextSize: checkBoxText.font.pixelSize
    //define of presenter
    width: 200
    height: 40

    // Стилизация текста
    contentItem: Text {
        id: checkBoxText
        text: checkBox.text
        font.family: "Montserrat"
        font.pixelSize: 14
        color: "#daf1de"
        verticalAlignment: Text.AlignVCenter
        leftPadding: checkBox.indicator.width + checkBox.spacing
    }

    //Override of checkbox
    indicator: Rectangle {
        id: indicator
        width: 26
        height: 26
        x: checkBox.leftPadding
        y: parent.height / 2 - height / 2
        radius: 6
        border.color: checkBox.down ? "#8eb69b" : "#daf1de"
        border.width: 2
        color: checkBox.down ? "#0B2B26" : "#163832"

        //Checkmarker
        Rectangle {
            id: checkMark
            width: parent.width - 9
            height: parent.height - 8
            x: 4
            y: 4
            radius: 3
            color: "#8EB69B"
            scale: checkBox.checked ? 1 : 0
            opacity: checkBox.checked ? 1 : 0

            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }
    }


    Behavior on scale {
        NumberAnimation {
            duration: 120
            easing.type: checkBox.down ? Easing.InQuad : Easing.OutBack
        }
    }

    scale: checkBox.down ? 0.95 : 1.0

    onCheckedChanged: {

    }
}
