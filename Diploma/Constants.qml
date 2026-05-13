pragma Singleton
import QtQuick

QtObject {
    readonly property int width: 1920
    readonly property int height: 1080

    readonly property font font: Qt.font({
        family: "Montserrat",
        pixelSize: 14
    })
    readonly property font largeFont: Qt.font({
        family: "Montserrat",
        pixelSize: 22
    })

    readonly property color backgroundColor: "#051F20"
}
