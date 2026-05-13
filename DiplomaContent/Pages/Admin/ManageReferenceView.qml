import QtQuick
import QtQuick.Controls.Basic
import DiplomaContent.UI_Elements
import DiplomaContent.Presenters
import DiplomaContent.Components
import DiplomaContent.Network

// ─────────────────────────────────────────────────────────────
// ManageReferenceView — управление справочниками:
//   Вкладка 1: Уровни логов (LEVEL_OF_LOGS)
//   Вкладка 2: Должности    (POSITIONS)
// ─────────────────────────────────────────────────────────────
Item {
    id: root

    ManageReferencePresenter {
        id: presenter

        onLogLevelsLoaded:  levelsModel.rebuild(presenter.logLevels)
        onLogLevelAdded:    { statusText.show("Уровень добавлен", "success");    levelsModel.rebuild(presenter.logLevels) }
        onLogLevelUpdated:  { statusText.show("Уровень обновлён", "success");    levelsModel.rebuild(presenter.logLevels) }
        onLogLevelDeleted:  { statusText.show("Уровень удалён", "success");      levelsModel.rebuild(presenter.logLevels) }

        onPositionsLoaded:  posModel.rebuild(presenter.positions)
        onPositionAdded:    { statusText.show("Должность добавлена", "success"); posModel.rebuild(presenter.positions) }
        onPositionUpdated:  { statusText.show("Должность обновлена", "success"); posModel.rebuild(presenter.positions) }
        onPositionDeleted:  { statusText.show("Должность удалена", "success");   posModel.rebuild(presenter.positions) }

        onOperationFailed: function(msg) { statusText.show(msg, "error") }
    }

    NotificationToast {
        id: statusText
        anchors.top: root.top; anchors.topMargin: 10
        anchors.horizontalCenter: root.horizontalCenter
    }

    // ─── Диалог подтверждения удаления уровня лога ───────────
    ConfirmDialog {
        id: lvDeleteDialog
        confirmText: "Удалить"
        confirmType: "danger"
        property string pendingId: ""
        onConfirmed: presenter.deleteLogLevel(pendingId)
    }

    // ─── Диалог подтверждения удаления должности ─────────────
    ConfirmDialog {
        id: posDeleteDialog
        confirmText: "Удалить"
        confirmType: "danger"
        property string pendingId: ""
        onConfirmed: presenter.deletePosition(pendingId)
    }

    // ─── HSV пикер цвета ─────────────────────────────────────
    // z: 300 — поверх всех попапов (z: 200)
    Item {
        id: colorPickerPopup
        visible: false
        anchors.fill: parent
        z: 300

        // ── Состояние HSV ──────────────────────────────────────
        property real _h: 0.0    // оттенок 0–1
        property real _s: 1.0    // насыщенность 0–1
        property real _v: 1.0    // яркость 0–1
        property bool _lock: false

        // Парсинг #RRGGBB → [h, s, v]
        function _hexToHsv(hex) {
            var r = parseInt(hex.slice(1,3),16)/255
            var g = parseInt(hex.slice(3,5),16)/255
            var b = parseInt(hex.slice(5,7),16)/255
            var mx=Math.max(r,g,b), mn=Math.min(r,g,b), d=mx-mn
            var h=0, s=mx===0?0:d/mx, v=mx
            if (d > 0) {
                if      (mx===r) h=((g-b)/d + (g<b?6:0))/6
                else if (mx===g) h=((b-r)/d + 2)/6
                else             h=((r-g)/d + 4)/6
            }
            return [h, s, v]
        }

        // HSV → #RRGGBB
        function _hsvToHex(h, s, v) {
            var h6=h*6, i=Math.floor(h6), f=h6-i
            var p=v*(1-s), q=v*(1-f*s), t=v*(1-(1-f)*s)
            var r,g,b
            switch(i%6){
                case 0:r=v;g=t;b=p;break; case 1:r=q;g=v;b=p;break
                case 2:r=p;g=v;b=t;break; case 3:r=p;g=q;b=v;break
                case 4:r=t;g=p;b=v;break; default:r=v;g=p;b=q
            }
            function h2(n){var s=Math.round(n*255).toString(16);return s.length<2?"0"+s:s}
            return "#"+h2(r)+h2(g)+h2(b)
        }

        function openPicker(currentHex) {
            var h = (currentHex && /^#[0-9A-Fa-f]{6}$/.test(currentHex))
                    ? currentHex.toUpperCase() : "#8EB69B"
            _lock = true
            var hsv = _hexToHsv(h)
            _h = hsv[0]; _s = hsv[1]; _v = hsv[2]
            cpHexField.text = h
            _lock = false
            visible = true
            cpScaleAnim.restart()
            svCanvas.requestPaint()
            hueCanvas.requestPaint()
        }

        // Затемняющая подложка
        Rectangle {
            anchors.fill: parent; color: "#000000"; opacity: 0.72
            MouseArea { anchors.fill: parent; onClicked: colorPickerPopup.visible = false }
        }

        // Карточка пикера
        Rectangle {
            id: cpCard
            anchors.centerIn: parent
            width: 380
            height: cpColumn.implicitHeight + 40
            color: "#0B2B26"; radius: 20
            border.color: "#235347"; border.width: 2

            Rectangle { anchors.fill: parent; anchors.topMargin: 7; color: "#051F20"; radius: parent.radius; z: -1 }

            NumberAnimation {
                id: cpScaleAnim; target: cpCard; property: "scale"
                from: 0.86; to: 1.0; duration: 260; easing.type: Easing.OutBack
            }

            Column {
                id: cpColumn
                anchors.top: parent.top; anchors.topMargin: 20
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.right: parent.right; anchors.rightMargin: 20
                spacing: 10

                // Заголовок
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Выбор цвета"
                    font.family: "Montserrat"; font.pixelSize: 17; font.bold: true; color: "#DAF1DE"
                }

                // ── SV-квадрат (насыщенность × яркость) ─────────
                Item {
                    width: parent.width; height: 240; clip: true

                    Canvas {
                        id: svCanvas
                        anchors.fill: parent

                        // Триггер перерисовки при смене оттенка
                        property real watchH: colorPickerPopup._h
                        onWatchHChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d"), w = width, h = height
                            // Вычисляем чистый оттенок (s=1, v=1) без вызова внешних функций
                            var ch=colorPickerPopup._h*6, ci=Math.floor(ch), cf=ch-ci
                            if (ci>=6) ci=5
                            var rv,gv,bv
                            switch(ci){
                                case 0:rv=1;gv=cf;bv=0;break; case 1:rv=1-cf;gv=1;bv=0;break
                                case 2:rv=0;gv=1;bv=cf;break; case 3:rv=0;gv=1-cf;bv=1;break
                                case 4:rv=cf;gv=0;bv=1;break; default:rv=1;gv=0;bv=1-cf
                            }
                            var pureHue = "rgb("+Math.round(rv*255)+","+Math.round(gv*255)+","+Math.round(bv*255)+")"
                            // Белый → Чистый оттенок (горизонталь)
                            var hg = ctx.createLinearGradient(0,0,w,0)
                            hg.addColorStop(0,"#FFFFFF"); hg.addColorStop(1, pureHue)
                            ctx.fillStyle = hg; ctx.fillRect(0,0,w,h)
                            // Прозрачный → Чёрный (вертикаль)
                            var vg = ctx.createLinearGradient(0,0,0,h)
                            vg.addColorStop(0,"rgba(0,0,0,0)"); vg.addColorStop(1,"rgba(0,0,0,1)")
                            ctx.fillStyle = vg; ctx.fillRect(0,0,w,h)
                        }

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: false
                            function pick(mx, my) {
                                if (colorPickerPopup._lock) return
                                colorPickerPopup._lock = true
                                colorPickerPopup._s = Math.max(0, Math.min(1, mx / parent.width))
                                colorPickerPopup._v = Math.max(0, Math.min(1, 1 - my / parent.height))
                                cpHexField.text = colorPickerPopup._hsvToHex(
                                    colorPickerPopup._h, colorPickerPopup._s, colorPickerPopup._v
                                ).toUpperCase()
                                colorPickerPopup._lock = false
                            }
                            onPressed:         pick(mouse.x, mouse.y)
                            onPositionChanged: if (pressed) pick(mouse.x, mouse.y)
                        }
                    }

                    // Кружок-индикатор позиции на SV-квадрате
                    Rectangle {
                        width: 16; height: 16; radius: 8
                        color: "transparent"
                        border.color: "#FFFFFF"; border.width: 2
                        x: colorPickerPopup._s * svCanvas.width  - 8
                        y: (1 - colorPickerPopup._v) * svCanvas.height - 8
                        // Внутренний кружок для контраста
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 3
                            radius: parent.radius; color: "#00000080"
                        }
                    }
                }

                // ── Слайдер оттенка ──────────────────────────────
                Item {
                    width: parent.width; height: 24

                    Canvas {
                        id: hueCanvas
                        anchors.fill: parent

                        onPaint: {
                            var ctx = getContext("2d"), w = width, h = height, r = h/2
                            var grd = ctx.createLinearGradient(0,0,w,0)
                            var stops = ["#FF0000","#FFFF00","#00FF00","#00FFFF","#0000FF","#FF00FF","#FF0000"]
                            for (var i=0; i<stops.length; i++)
                                grd.addColorStop(i/(stops.length-1), stops[i])
                            // Скруглённый прямоугольник через arcTo
                            ctx.save()
                            ctx.beginPath()
                            ctx.moveTo(r, 0); ctx.lineTo(w-r, 0)
                            ctx.arcTo(w,0, w,r, r); ctx.lineTo(w, h-r)
                            ctx.arcTo(w,h, w-r,h, r); ctx.lineTo(r, h)
                            ctx.arcTo(0,h, 0,h-r, r); ctx.lineTo(0, r)
                            ctx.arcTo(0,0, r,0, r)
                            ctx.closePath(); ctx.clip()
                            ctx.fillStyle = grd
                            ctx.fillRect(0,0,w,h)
                            ctx.restore()
                        }

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: false
                            function pick(mx) {
                                if (colorPickerPopup._lock) return
                                colorPickerPopup._lock = true
                                colorPickerPopup._h = Math.max(0, Math.min(0.9999, mx / parent.width))
                                svCanvas.requestPaint()
                                cpHexField.text = colorPickerPopup._hsvToHex(
                                    colorPickerPopup._h, colorPickerPopup._s, colorPickerPopup._v
                                ).toUpperCase()
                                colorPickerPopup._lock = false
                            }
                            onPressed:         pick(mouse.x)
                            onPositionChanged: if (pressed) pick(mouse.x)
                        }
                    }

                    // Линия-индикатор оттенка
                    Rectangle {
                        width: 4; height: parent.height + 8; y: -4
                        x: colorPickerPopup._h * hueCanvas.width - 2
                        radius: 2; color: "#FFFFFF"
                        border.color: "#00000060"; border.width: 1
                    }
                }

                // ── Пресеты (вспомогательная строка) ─────────────
                Flow {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: ["#8EB69B","#DAF1DE","#235347","#163832",
                                "#8B2020","#c97a2a","#E8A030","#2a5a8a",
                                "#3a80C0","#8050D0","#FFFFFF","#111111"]
                        delegate: Rectangle {
                            width: 28; height: 28; radius: 7; color: modelData
                            border.color: cpHexField.text.toUpperCase() === modelData.toUpperCase()
                                          ? "#DAF1DE" : "#235347"
                            border.width:  cpHexField.text.toUpperCase() === modelData.toUpperCase() ? 2 : 1
                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    colorPickerPopup._lock = true
                                    var hsv = colorPickerPopup._hexToHsv(modelData)
                                    colorPickerPopup._h=hsv[0]; colorPickerPopup._s=hsv[1]; colorPickerPopup._v=hsv[2]
                                    cpHexField.text = modelData.toUpperCase()
                                    colorPickerPopup._lock = false
                                    svCanvas.requestPaint()
                                }
                                onEntered: parent.scale = 1.12
                                onExited:  parent.scale = 1.0
                            }
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                        }
                    }
                }

                // ── Превью + HEX поле ─────────────────────────────
                Row {
                    width: parent.width; spacing: 10

                    Rectangle {
                        width: 50; height: 46; radius: 12
                        color: /^#[0-9A-Fa-f]{6}$/.test(cpHexField.text) ? cpHexField.text : "#163832"
                        border.color: "#235347"; border.width: 2
                    }

                    Column {
                        width: parent.width - 60; spacing: 4
                        Text { text: "HEX-код"; font.family: "Montserrat"; font.pixelSize: 11; color: "#8EB69B" }
                        MainTextField {
                            id: cpHexField
                            width: parent.width; height: 38
                            hint: "#8EB69B"; hintTextSize: 12; mainTextSize: 13; maximumLength: 7
                            property bool _fmt: false
                            onTextChanged: {
                                if (_fmt || colorPickerPopup._lock) return
                                _fmt = true
                                var t = text.toUpperCase()
                                if (!t.startsWith("#")) t = "#" + t.replace(/[^0-9A-F]/g, "")
                                else t = "#" + t.slice(1).replace(/[^0-9A-F]/g, "")
                                if (t.length > 7) t = t.slice(0, 7)
                                text = t
                                if (/^#[0-9A-F]{6}$/.test(t)) {
                                    colorPickerPopup._lock = true
                                    var hsv = colorPickerPopup._hexToHsv(t)
                                    colorPickerPopup._h=hsv[0]; colorPickerPopup._s=hsv[1]; colorPickerPopup._v=hsv[2]
                                    svCanvas.requestPaint()
                                    colorPickerPopup._lock = false
                                }
                                _fmt = false
                            }
                        }
                    }
                }

                // ── Кнопки ────────────────────────────────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 12

                    MainButton {
                        width: 200; height: 44; buttonText: "Выбрать"; buttonTextSize: 11
                        onClicked: {
                            if (/^#[0-9A-Fa-f]{6}$/.test(cpHexField.text))
                                lvColorField.text = cpHexField.text.toUpperCase()
                            colorPickerPopup.visible = false
                        }
                    }
                    MainButton {
                        width: 140; height: 44; buttonText: "Отмена"; buttonTextSize: 11
                        onClicked: colorPickerPopup.visible = false
                    }
                }

                Item { width: 1; height: 4 }
            }
        }
    }

    // ─── Попап редактирования уровня лога ────────────────────
    Item {
        id: levelPopup
        visible: false; anchors.fill: parent; z: 200

        property string editingId: ""
        property bool   isEditMode: editingId !== ""

        onVisibleChanged: {
            if (visible) { lvFadeAnim.restart(); lvScaleAnim.restart() }
            else colorPickerPopup.visible = false   // закрыть пикер вместе с попапом
        }

        Rectangle {
            anchors.fill: parent; color: "#000000"; opacity: 0.6
            MouseArea { anchors.fill: parent; onClicked: levelPopup.visible = false }
        }

        Rectangle {
            id: lvCard; anchors.centerIn: parent; width: 400; height: 300
            color: "#0B2B26"; radius: 20; border.color: "#235347"; border.width: 2

            // Тень
            Rectangle { anchors.fill: parent; anchors.topMargin: 7; color: "#051F20"; radius: parent.radius; z: -1 }

            NumberAnimation { id: lvFadeAnim;  target: lvCard; property: "opacity"; from: 0; to: 1;    duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { id: lvScaleAnim; target: lvCard; property: "scale";   from: 0.90; to: 1; duration: 260; easing.type: Easing.OutBack }

            Text {
                anchors.top: parent.top; anchors.topMargin: 22; anchors.horizontalCenter: parent.horizontalCenter
                text: levelPopup.isEditMode ? "Редактировать уровень" : "Добавить уровень"
                font.family: "Montserrat"; font.pixelSize: 17; font.bold: true; color: "#DAF1DE"
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: 70
                width: parent.width - 48; spacing: 16

                Column {
                    width: parent.width; spacing: 4
                    Text { text: "Название уровня *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                    MainTextField { id: lvNameField; width: parent.width; height: 46; hint: "info, warning, error..."; hintTextSize: 12; mainTextSize: 13 }
                }

                // Цвет — текстовое поле HEX + превью + кастомный пикер
                Column {
                    width: parent.width; spacing: 4
                    Text { text: "Цвет (HEX) *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                    Row {
                        width: parent.width; spacing: 10
                        MainTextField {
                            id: lvColorField; width: parent.width - 46 - 46 - 20; height: 46
                            hint: "#8EB69B"; hintTextSize: 12; mainTextSize: 13; maximumLength: 9
                            property bool _fmt: false
                            onTextChanged: {
                                if (_fmt) return; _fmt = true
                                var t = text.toUpperCase()
                                if (t === "") { _fmt = false; return }
                                if (!t.startsWith("#")) t = "#" + t.replace(/[^0-9A-F]/g, "")
                                else t = "#" + t.slice(1).replace(/[^0-9A-F]/g, "")
                                if (t.length > 9) t = t.slice(0, 9)
                                text = t; _fmt = false
                            }
                        }
                        // Превью цвета
                        Rectangle {
                            width: 46; height: 46; radius: 12
                            color: /^#[0-9A-Fa-f]{6,8}$/.test(lvColorField.text) ? lvColorField.text : "#163832"
                            border.color: "#235347"; border.width: 2
                        }
                        // Кнопка-пикер (открывает кастомный попап)
                        Rectangle {
                            width: 46; height: 46; radius: 12
                            color: _pickColorArea.containsMouse ? "#235347" : "#163832"
                            border.color: "#235347"; border.width: 2
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
                                text: "🎨"; font.pixelSize: 20
                            }
                            MouseArea {
                                id: _pickColorArea; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: colorPickerPopup.openPicker(lvColorField.text)
                            }
                        }
                    }
                }
            }

            Row {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 12

                MainButton {
                    width: 200; height: 44; buttonText: levelPopup.isEditMode ? "Сохранить" : "Добавить"; buttonTextSize: 11
                    onClicked: {
                        if (lvNameField.text.trim() === "" || lvColorField.text.trim() === "") return
                        if (levelPopup.isEditMode)
                            presenter.updateLogLevel(levelPopup.editingId, lvNameField.text.trim(), lvColorField.text.trim())
                        else
                            presenter.addLogLevel(lvNameField.text.trim(), lvColorField.text.trim())
                        levelPopup.visible = false
                    }
                }
                MainButton { width: 140; height: 44; buttonText: "Отмена"; buttonTextSize: 11; onClicked: levelPopup.visible = false }
            }
        }
    }

    // ─── Попап редактирования должности ──────────────────────
    Item {
        id: posPopup
        visible: false; anchors.fill: parent; z: 200

        property string editingId: ""
        property bool   isEditMode: editingId !== ""

        onVisibleChanged: { if (visible) { posFadeAnim.restart(); posScaleAnim.restart() } }

        Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.6; MouseArea { anchors.fill: parent; onClicked: posPopup.visible = false } }

        Rectangle {
            id: posCard; anchors.centerIn: parent; width: 440; height: 420
            color: "#0B2B26"; radius: 20; border.color: "#235347"; border.width: 2

            // Тень
            Rectangle { anchors.fill: parent; anchors.topMargin: 7; color: "#051F20"; radius: parent.radius; z: -1 }

            NumberAnimation { id: posFadeAnim;  target: posCard; property: "opacity"; from: 0; to: 1;    duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { id: posScaleAnim; target: posCard; property: "scale";   from: 0.90; to: 1; duration: 260; easing.type: Easing.OutBack }

            Text {
                anchors.top: parent.top; anchors.topMargin: 22; anchors.horizontalCenter: parent.horizontalCenter
                text: posPopup.isEditMode ? "Редактировать должность" : "Добавить должность"
                font.family: "Montserrat"; font.pixelSize: 17; font.bold: true; color: "#DAF1DE"
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: 70
                width: parent.width - 48; spacing: 14

                Column {
                    width: parent.width; spacing: 4
                    Text { text: "Название должности *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                    MainTextField { id: posTitleField; width: parent.width; height: 46; hint: "Библиотекарь..."; hintTextSize: 12; mainTextSize: 13 }
                }

                Column {
                    width: parent.width; spacing: 4
                    Text { text: "Оклад (₽) *"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }
                    MainTextField {
                        id: posSalaryField; width: parent.width; height: 46; hint: "45000"; hintTextSize: 12; mainTextSize: 13
                        validator: DoubleValidator { bottom: 0; top: 9999999; decimals: 2 }
                    }
                }

                Text { text: "Права доступа"; font.family: "Montserrat"; font.pixelSize: 12; color: "#8EB69B" }

                Grid {
                    id: permGrid
                    width: parent.width; columns: 2; rowSpacing: 10; columnSpacing: 16

                    Repeater {
                        id: permRepeater
                        model: [
                            { key: "toRead",   label: "Чтение"         },
                            { key: "toWrite",  label: "Запись"         },
                            { key: "toUpdate", label: "Редактирование" },
                            { key: "toDelete", label: "Удаление"       }
                        ]

                        delegate: Row {
                            id: permRow
                            spacing: 10
                            property bool checked: false

                            Rectangle {
                                width: 22; height: 22; radius: 6
                                color: permRow.checked ? "#235347" : "#163832"
                                border.color: permRow.checked ? "#8EB69B" : "#235347"; border.width: 2
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent; text: "✓"
                                    font.pixelSize: 13; color: "#DAF1DE"
                                    visible: permRow.checked
                                }

                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: permRow.checked = !permRow.checked
                                }
                            }

                            Text {
                                text: modelData.label; font.family: "Montserrat"; font.pixelSize: 13
                                color: "#DAF1DE"; anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            Row {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 18
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 12

                MainButton {
                    width: 200; height: 44; buttonText: posPopup.isEditMode ? "Сохранить" : "Добавить"; buttonTextSize: 11
                    onClicked: {
                        if (posTitleField.text.trim() === "") return
                        var perms = { toRead: false, toWrite: false, toDelete: false, toUpdate: false }
                        var keys = ["toRead", "toWrite", "toUpdate", "toDelete"]
                        for (var i = 0; i < permRepeater.count; i++) {
                            var item = permRepeater.itemAt(i)
                            if (item) perms[keys[i]] = item.checked
                        }
                        var input = {
                            title:       posTitleField.text.trim(),
                            salary:      posSalaryField.text.trim(),
                            permissions: perms
                        }
                        if (posPopup.isEditMode)
                            presenter.updatePosition(posPopup.editingId, input)
                        else
                            presenter.addPosition(input)
                        posPopup.visible = false
                    }
                }
                MainButton { width: 140; height: 44; buttonText: "Отмена"; buttonTextSize: 11; onClicked: posPopup.visible = false }
            }
        }
    }

    // ─────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent; anchors.margins: 28; spacing: 20

        HeadingText { text: "Справочники"; size: 26 }

        // ─── Переключатель вкладок ────────────────────────────
        Row {
            id: tabBar
            spacing: 0
            property int currentTab: 0

            Repeater {
                model: ["Уровни логов", "Должности"]
                delegate: Rectangle {
                    width: 180; height: 40; radius: 0
                    color: tabBar.currentTab === index ? "#235347" : "#163832"
                    border.color: "#051F20"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent; text: modelData
                        font.family: "Montserrat"; font.pixelSize: 13; font.bold: tabBar.currentTab === index
                        color: tabBar.currentTab === index ? "#DAF1DE" : "#8EB69B"
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tabBar.currentTab = index }
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - 26 - 44 - 40 - 44

        // ─── Вкладка: Уровни логов ────────────────────────────
        Item {
            anchors.fill: parent
            opacity: tabBar.currentTab === 0 ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent; spacing: 14

                MainButton {
                    width: 200; height: 40; buttonText: "+ Добавить уровень"; buttonTextSize: 11
                    onClicked: {
                        lvNameField.text  = ""
                        lvColorField.text = ""
                        levelPopup.editingId = ""
                        levelPopup.visible   = true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - 40 - 14
                    color: "#163832"; radius: 16; border.color: "#235347"; border.width: 1; clip: true

                    Column {
                        anchors.fill: parent

                        Rectangle {
                            width: parent.width; height: 44; color: "#0B2B26"; radius: 16
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 16; color: parent.color }
                            Row {
                                anchors.fill: parent
                                Repeater {
                                    model: [{ label: "Название", w: 0.35 }, { label: "Цвет (HEX)", w: 0.30 }, { label: "Превью", w: 0.25 }, { label: "", w: 0.10 }]
                                    delegate: Item {
                                        width: parent.width * modelData.w; height: parent.height
                                        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12; text: modelData.label; font.family: "Montserrat"; font.pixelSize: 12; font.bold: true; color: "#8EB69B" }
                                    }
                                }
                            }
                        }

                        ScrollView {
                            width: parent.width; height: parent.height - 44; clip: true
                            ListView {
                                id: levelsListView
                                model: levelsModel

                                delegate: Item {
                                    width: levelsListView.width; height: 52

                                    Rectangle {
                                        anchors.fill: parent
                                        color: lvRowArea.containsMouse ? "#1e4040" : (index % 2 === 0 ? "#163832" : "#1a3a3a")
                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        MouseArea {
                                            id: lvRowArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                lvNameField.text  = model.levelName || ""
                                                lvColorField.text = model.color     || ""
                                                levelPopup.editingId = model.levelId
                                                levelPopup.visible   = true
                                            }
                                        }

                                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#235347"; opacity: 0.4 }

                                        Row {
                                            anchors.fill: parent
                                            RefCell { w: 0.35; val: model.levelName || "—"; bold: true }
                                            RefCell { w: 0.30; val: model.color     || "—" }
                                            Item {
                                                width: parent.width * 0.25; height: parent.height
                                                Rectangle {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left; anchors.leftMargin: 12
                                                    width: 80; height: 24; radius: 6
                                                    color: model.color || "#333333"
                                                    border.color: "#051F20"; border.width: 1
                                                }
                                            }
                                            Item {
                                                width: parent.width * 0.10; height: parent.height
                                                Rectangle {
                                                    anchors.centerIn: parent; width: 28; height: 28; radius: 8
                                                    color: lvDelArea.containsMouse ? "#7a1a1a" : "#5c1010"
                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                    Text { anchors.centerIn: parent; text: "✕"; color: "#DAF1DE"; font.pixelSize: 12 }
                                                    MouseArea {
                                                        id: lvDelArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            lvDeleteDialog.pendingId = model.levelId
                                                            lvDeleteDialog.show(
                                                                "Удалить уровень?",
                                                                "Уровень «" + model.levelName + "» будет удалён.")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Text { anchors.centerIn: parent; visible: levelsModel.count === 0; text: "Уровни не найдены"; font.family: "Montserrat"; font.pixelSize: 16; color: "#8EB69B" }
                            }
                        }
                    }
                }
            }
        }

        // ─── Вкладка: Должности ───────────────────────────────
        Item {
            anchors.fill: parent
            opacity: tabBar.currentTab === 1 ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent; spacing: 14

                MainButton {
                    width: 200; height: 40; buttonText: "+ Добавить должность"; buttonTextSize: 11
                    onClicked: {
                        posTitleField.text  = ""
                        posSalaryField.text = ""
                        posPopup.editingId  = ""
                        posPopup.visible    = true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - 40 - 14
                    color: "#163832"; radius: 16; border.color: "#235347"; border.width: 1; clip: true

                    Column {
                        anchors.fill: parent

                        Rectangle {
                            width: parent.width; height: 44; color: "#0B2B26"; radius: 16
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 16; color: parent.color }
                            Row {
                                anchors.fill: parent
                                Repeater {
                                    model: [
                                        { label: "Название",  w: 0.28, center: false },
                                        { label: "Оклад (₽)", w: 0.16, center: false },
                                        { label: "Чтение",    w: 0.12, center: true  },
                                        { label: "Запись",    w: 0.12, center: true  },
                                        { label: "Ред-е",     w: 0.12, center: true  },
                                        { label: "Удаление",  w: 0.12, center: true  },
                                        { label: "",          w: 0.08, center: false  }
                                    ]
                                    delegate: Item {
                                        width: parent.width * modelData.w; height: parent.height
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: modelData.center ? Math.round((parent.width - implicitWidth) / 2) : 12
                                            text: modelData.label; font.family: "Montserrat"; font.pixelSize: 12; font.bold: true; color: "#8EB69B"
                                        }
                                    }
                                }
                            }
                        }

                        ScrollView {
                            width: parent.width; height: parent.height - 44; clip: true
                            ListView {
                                id: posListView
                                model: posModel

                                delegate: Item {
                                    width: posListView.width; height: 52

                                    Rectangle {
                                        anchors.fill: parent
                                        color: posRowArea.containsMouse ? "#1e4040" : (index % 2 === 0 ? "#163832" : "#1a3a3a")
                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        MouseArea {
                                            id: posRowArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                posTitleField.text  = model.title      || ""
                                                posSalaryField.text = model.salary > 0 ? model.salary.toString() : ""
                                                posPopup.editingId  = model.positionId
                                                var p = model.permissions
                                                if (permRepeater.itemAt(0)) permRepeater.itemAt(0).checked = p ? (p.toRead   || false) : false
                                                if (permRepeater.itemAt(1)) permRepeater.itemAt(1).checked = p ? (p.toWrite  || false) : false
                                                if (permRepeater.itemAt(2)) permRepeater.itemAt(2).checked = p ? (p.toUpdate || false) : false
                                                if (permRepeater.itemAt(3)) permRepeater.itemAt(3).checked = p ? (p.toDelete || false) : false
                                                posPopup.visible    = true
                                            }
                                        }

                                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#235347"; opacity: 0.4 }

                                        Row {
                                            anchors.fill: parent
                                            RefCell { w: 0.28; val: model.title || "—"; bold: true }
                                            Item {
                                                width: parent.width * 0.16; height: parent.height
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12
                                                    text: model.salary > 0 ? Number(model.salary).toLocaleString(Qt.locale("ru_RU"), "f", 0) + " ₽" : "—"
                                                    font.family: "Montserrat"; font.pixelSize: 13; color: "#DAF1DE"; elide: Text.ElideRight
                                                }
                                            }
                                            PermCell { w: 0.12; val: model.permissions ? model.permissions.toRead   : false }
                                            PermCell { w: 0.12; val: model.permissions ? model.permissions.toWrite  : false }
                                            PermCell { w: 0.12; val: model.permissions ? model.permissions.toUpdate : false }
                                            PermCell { w: 0.12; val: model.permissions ? model.permissions.toDelete : false }
                                            Item {
                                                width: parent.width * 0.08; height: parent.height
                                                Rectangle {
                                                    anchors.centerIn: parent; width: 28; height: 28; radius: 8
                                                    color: posDelArea.containsMouse ? "#7a1a1a" : "#5c1010"
                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                    Text { anchors.centerIn: parent; text: "✕"; color: "#DAF1DE"; font.pixelSize: 12 }
                                                    MouseArea {
                                                        id: posDelArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            posDeleteDialog.pendingId = model.positionId
                                                            posDeleteDialog.show(
                                                                "Удалить должность?",
                                                                "Должность «" + model.title + "» будет удалена.")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Text { anchors.centerIn: parent; visible: posModel.count === 0; text: "Должности не найдены"; font.family: "Montserrat"; font.pixelSize: 16; color: "#8EB69B" }
                            }
                        }
                    }
                }
            }
        }
        } // ─ конец контейнера вкладок
    }

    // ─── Ячейки таблицы ──────────────────────────────────────
    component RefCell: Item {
        property real w: 0.1; property string val: ""; property bool bold: false
        width: parent ? parent.width * w : 100; height: 52
        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 12; text: val; font.family: "Montserrat"; font.pixelSize: 13; font.bold: bold; color: "#DAF1DE"; elide: Text.ElideRight }
    }

    component PermCell: Item {
        property real w: 0.1; property bool val: false
        width: parent ? parent.width * w : 100; height: 52
        Text { anchors.centerIn: parent; text: val ? "✓" : "✗"; font.pixelSize: 15; color: val ? "#8EB69B" : "#5c3030" }
    }

    // ─── Модели ──────────────────────────────────────────────
    ListModel {
        id: levelsModel
        function rebuild(arr) {
            clear()
            for (var i = 0; i < arr.length; i++) append(arr[i])
        }
    }

    ListModel {
        id: posModel
        function rebuild(arr) {
            clear()
            for (var i = 0; i < arr.length; i++) append(arr[i])
        }
    }

    Component.onCompleted: {
        if (!TokenManager.hasValidToken()) return
        presenter.loadLogLevels()
        presenter.loadPositions()
    }

    function reload() {
        presenter.loadLogLevels()
        presenter.loadPositions()
    }
}
