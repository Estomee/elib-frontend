import QtQuick
import QtQuick.Controls

TextField {
    property alias hint: textFieldHint.text
    property alias hintTextSize: textFieldHint.font.pixelSize
    property alias mainTextSize: mainTextField.font.pixelSize
    property alias textFieldVolume: volume.height

    id: mainTextField

    width: 250
    height: 55
    opacity: 1
    color: "#daf1de"
    topPadding: -height * 0.16
    topInset: 0
    selectionColor: "#daf1de"
    scale: 1
    rightInset: 0
    padding: 0
    leftInset: 0
    hoverEnabled: true
    leftPadding: 15
    font.family: "Montserrat"
    font.pixelSize: height * 0.36
    cursorVisible: true
    bottomInset: height * 0.18
    z: 1
    cursorDelegate: Rectangle {
        id: mainTextFieldCursor
        width: 2
        height: mainTextField.font.pixelSize * 1.2

        color: "#daf1de"
        visible: mainTextField.activeFocus && !mainTextField.readOnly

        SequentialAnimation on visible {
            running: mainTextField.activeFocus
            loops: Animation.Infinite
            PropertyAnimation {
                to: false
                duration: 500
            }
            PropertyAnimation {
                to: true
                duration: 500
            }
        }
    }

    Text {
        id: textFieldHint
        font.family: mainTextField.font.family
        font.pixelSize: mainTextField.height * 0.3
        color: "#8eb69b"
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 15
            topMargin: mainTextField.height * 0.27
        }

        states: [
            State {
                name: "visible"
                when: mainTextField.text === ""
                      && (!mainTextField.activeFocus || mainTextField.readOnly)
                PropertyChanges {
                    target: textFieldHint
                    opacity: 1
                    scale: 1
                }
            },
            State {
                name: "hidden"
                when: mainTextField.text !== "" || (mainTextField.activeFocus && !mainTextField.readOnly)
                PropertyChanges {
                    target: textFieldHint
                    opacity: 0
                    scale: 0.8
                }
            }
        ]

        transitions: Transition {
            NumberAnimation {
                properties: "opacity, scale"
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }

    background: Rectangle {
        id: textFieldBackground
        color: "#235347"
        border.width: 2
        border.color: "#051F20"
        radius: mainTextField.height * 0.29
    }

    Rectangle {
        id: volume
        color: "#163832"
        border.color: "#051F20"
        border.width: 2
        anchors.fill: parent
        z: -3
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        width: parent.width
        height: parent.heigh
        radius: textFieldBackground.radius
    }

    onEditingFinished: {
        //logic of presenter
    }
}
