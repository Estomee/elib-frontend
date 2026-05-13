import QtQuick
import QtQuick.Effects

Item {
    id: glowEffect

    // Целевой элемент, к которому применяется свечение
    property Item target: parent
    property color glowColor: "#8eb69b"
    property real baseRadius: 8
    property real hoverRadius: 16
    property real clickRadius: 20
    property int samples: 20
    property int duration: 1000

    signal clicked()
    signal hoverStopped()
    signal hoverStarted()

    // Привязываем размер к целевому элементу
    anchors.fill: target

    // Эффект свечения через MultiEffect
    MultiEffect {
        id: glow
        source: glowEffect.target
        anchors.fill: parent
        blurEnabled: true
        blur: Math.min(glowEffect.baseRadius / 32.0, 1.0)
        blurMax: 32
        colorization: 1.0
        colorizationColor: glowEffect.glowColor
    }

    // Анимация для плавного изменения радиуса
    Behavior on baseRadius {
        NumberAnimation {
            duration: glowEffect.duration / 2
            easing.type: Easing.OutCubic
        }
    }

    // Анимация при наведении
    SequentialAnimation {
        id: hoverAnimation
        loops: Animation.Infinite
        running: false

        NumberAnimation {
            target: glowEffect
            property: "baseRadius"
            from: 8
            to: hoverRadius
            duration: duration
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: glowEffect
            property: "baseRadius"
            from: hoverRadius
            to: 8
            duration: duration
            easing.type: Easing.InOutQuad
        }
    }

    // Анимация при клике
    SequentialAnimation {
        id: clickAnimation
        running: false

        NumberAnimation {
            target: glowEffect
            property: "baseRadius"
            from: baseRadius
            to: clickRadius
            duration: duration / 3
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: glowEffect
            property: "baseRadius"
            from: clickRadius
            to: 8
            duration: duration / 1.5
            easing.type: Easing.OutCubic
        }
    }

    onHoverStarted: {
        console.log("Hover started")
        if (!clickAnimation.running) {
            hoverAnimation.start()
        }
    }

    onHoverStopped: {
        console.log("Hover stopped")
        hoverAnimation.stop()
        baseRadius = 8
    }

    onClicked: {
        console.log("Clicked")
        hoverAnimation.stop()
        clickAnimation.start()
    }

    function startHover() {
        hoverStarted()
    }

    function stopHover() {
        hoverStopped()
    }

    function executedClick() {
        clicked()
    }
}
