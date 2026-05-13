// PDF viewer component with zoom animation, scroll, and fit-to-width using PdfScrollablePageView.
import QtQuick
import QtQuick.Pdf

Item {
    id: root

    property string filePath:    ""
    property int    currentPage: 0
    property int    pageCount:   0
    property real   renderScale: pdfView.renderScale

    function _fitScale() {
        var pw = pdfDoc.pagePointSize(0).width
        return pw > 0 ? Math.max(0.25, (pdfView.width - 16) / pw) : 1.0
    }

    function _zoomTo(newScale) {
        var cw = pdfView.contentWidth
        var ch = pdfView.contentHeight

        zoomAnim.savedCx = (cw > 0) ? (pdfView.contentX + pdfView.width  / 2) / cw : 0.5
        zoomAnim.savedCy = (ch > 0) ? (pdfView.contentY + pdfView.height / 2) / ch : 0.5
        zoomAnim.from    = pdfView.renderScale
        zoomAnim.to      = newScale
        zoomAnim.restart()
    }

    function _applySavedCenter() {
        var cw = pdfView.contentWidth
        var ch = pdfView.contentHeight
        if (cw > pdfView.width)
            pdfView.contentX = Math.max(0, Math.min(cw - pdfView.width,
                                                    zoomAnim.savedCx * cw - pdfView.width  / 2))
        else
            pdfView.contentX = -pdfView.leftMargin

        if (ch > pdfView.height)
            pdfView.contentY = Math.max(0, Math.min(ch - pdfView.height,
                                                    zoomAnim.savedCy * ch - pdfView.height / 2))
    }

    NumberAnimation {
        id: zoomAnim
        target: pdfView
        property: "renderScale"
        duration: 200
        easing.type: Easing.OutCubic

        property real savedCx: 0.5
        property real savedCy: 0.5

        onStopped: Qt.callLater(_applySavedCenter)
    }

    Timer {
        interval: 16
        repeat:   true
        running:  zoomAnim.running
        onTriggered: _applySavedCenter()
    }

    PdfDocument {
        id: pdfDoc
        source: root.filePath !== "" ? root.filePath : ""
        onStatusChanged: {
            if (pdfDoc.status === PdfDocument.Ready) {
                root.pageCount      = pdfDoc.pageCount
                pdfView.renderScale = _fitScale()
            }
        }
        onPageCountChanged: root.pageCount = pdfDoc.pageCount
    }

    Rectangle {
        anchors.fill: parent
        color: "#1a1a1a"
    }

    PdfScrollablePageView {
        id: pdfView
        anchors.fill: parent
        document: pdfDoc

        leftMargin: {
            if (pdfDoc.status !== PdfDocument.Ready || pdfDoc.pageCount === 0) return 8
            var pw = pdfDoc.pagePointSize(0).width * renderScale
            return pw > 0 && pw < width ? Math.max(8, Math.round((width - pw) / 2)) : 8
        }
        rightMargin: {
            if (pdfDoc.status !== PdfDocument.Ready || pdfDoc.pageCount === 0) return 8
            var pw2 = pdfDoc.pagePointSize(0).width * renderScale
            return pw2 > 0 && pw2 < width ? Math.max(8, Math.round((width - pw2) / 2)) : 8
        }

        topMargin: {
            if (pdfDoc.status !== PdfDocument.Ready || pdfDoc.pageCount === 0) return 8
            var ph = pdfDoc.pagePointSize(0).height * renderScale
            return ph > 0 && ph < height ? Math.max(8, Math.round((height - ph) / 2)) : 8
        }
        bottomMargin: {
            if (pdfDoc.status !== PdfDocument.Ready || pdfDoc.pageCount === 0) return 8
            var ph2 = pdfDoc.pagePointSize(0).height * renderScale
            return ph2 > 0 && ph2 < height ? Math.max(8, Math.round((height - ph2) / 2)) : 8
        }

        onCurrentPageChanged: root.currentPage = pdfView.currentPage
    }

    MouseArea {
        anchors.fill: pdfView
        acceptedButtons: Qt.NoButton
        z: pdfView.z + 1

        DragHandler {
            target: null
            acceptedButtons: Qt.LeftButton
            grabPermissions: PointerHandler.CanTakeOverFromItems |
                             PointerHandler.CanTakeOverFromHandlersOfSameType |
                             PointerHandler.CanTakeOverFromHandlersOfDifferentType
        }

        onWheel: function(wheel) {
            if (wheel.modifiers & Qt.ControlModifier) {
                var factor = wheel.angleDelta.y > 0 ? Math.sqrt(2) : 1.0 / Math.sqrt(2)
                _zoomTo(Math.max(0.25, Math.min(8.0, pdfView.renderScale * factor)))
            } else {
                var delta  = wheel.angleDelta.y / 120
                var newY   = pdfView.contentY - delta * pdfView.height * 0.20
                pdfView.contentY = Math.max(0,
                    Math.min(pdfView.contentHeight - pdfView.height, newY))
            }
            wheel.accepted = true
        }
    }

    function _centerH() {
        var cw = pdfView.contentWidth
        pdfView.contentX = cw > pdfView.width
            ? (cw - pdfView.width) / 2
            : -pdfView.leftMargin
    }

    function goToPage(pageIndex) {
        pdfView.goToPage(pageIndex)
        _centerH()
        Qt.callLater(_centerH)
    }

    function zoomIn() {
        _zoomTo(Math.min(pdfView.renderScale * Math.sqrt(2), 8.0))
    }

    function zoomOut() {
        _zoomTo(Math.max(pdfView.renderScale / Math.sqrt(2), 0.25))
    }

    function resetZoom() {
        _zoomTo(_fitScale())
    }
}
