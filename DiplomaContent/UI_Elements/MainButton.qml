import QtQuick
import QtQuick.Controls

Button {
    property alias buttonText: parentText.text
    property alias buttonTextSize: parentText.font.pointSize
    property alias buttonVolume: volume.height


    id: parentButton
    //define of presenter

    width: 250
    height: 60

    contentItem: Text {
        id: parentText
        font.family: "Montserrat"
        text: buttonText
        color: "#daf1de"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    hoverEnabled: true

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    background: Rectangle {
        id: buttonBackground
        color: parentButton.down ? "#163832" : (hoverHandler.hovered ? "#1e4040" : "#235347")
        radius: 30
        border.color: "#051f20"
        border.width: 2
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Rectangle {
        id: volume
        color: parentButton.down ? "#0B2B26" : "#163832"
        border.color: "#051F20"
        border.width: 2
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        width: parent.width
        height: parent.height * 1.17
        z: -3
        radius: buttonBackground.radius
    }



    Behavior on scale {
        NumberAnimation {
            duration: 160
            easing.type: parentButton.down ? Easing.InQuad : Easing.OutBack
        }
    }

    scale: parentButton.down ? 0.95 : 1.0

    onClicked: {
        //logic with presenter
    }


}

