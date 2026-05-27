import QtQuick 2.0
import QtQuick.Window 2.0

Window {
    id: root
    title: "Manage Snippets"
    width: 720
    height: 480
    minimumWidth: 520
    minimumHeight: 320
    modality: Qt.ApplicationModal
    flags: Qt.Dialog | Qt.WindowCloseButtonHint

    property var primarySnippets: []
    property var extraSnippets: []
    property string extraLabel: ""
    property int initialTab: 0
    property int initialSnippet: -1
    signal snippetsSaved(var updatedSnippets, int fileIndex)

    property var items: []
    property bool updating: false
    property bool _editorLoaded: false
    property bool isDirty: false
    property bool listDirty: false
    property bool showHelp: false
    property int activeFile: 0
    property var _tabItems: [[], []]
    property var _tabListDirty: [false, false]

    readonly property int baseWidth: 720
    property real helpPanelWidth: 320

    SystemPalette {
        id: pal
    }

    Component.onCompleted: {
        var pi = JSON.parse(JSON.stringify(primarySnippets));
        var ei = JSON.parse(JSON.stringify(extraSnippets));
        _tabItems = [pi, ei];
        items = JSON.parse(JSON.stringify(pi));
        if (initialTab === 1 && extraLabel !== "")
            switchTab(1);
        if (initialSnippet >= 0 && initialSnippet < items.length) {
            snippetList.currentIndex = initialSnippet;
            loadItem(initialSnippet);
        }
    }

    // ── Tab bar ───────────────────────────────────────────────────────────────
    Item {
        id: tabBar
        visible: extraLabel !== ""
        anchors {
            top: parent.top
            topMargin: 10
            left: parent.left
            leftMargin: 10
        }
        width: 210
        height: visible ? 26 : 0

        Rectangle {
            id: tab0Btn
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: 101
            radius: 3
            color: activeFile === 0 ? "#1cb27e" : (tab0Mouse.containsMouse ? pal.light : pal.button)
            border.color: activeFile === 0 ? "#1cb27e" : pal.mid
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Primary"
                color: activeFile === 0 ? "white" : pal.buttonText
                font.pixelSize: 12
            }

            MouseArea {
                id: tab0Mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: switchTab(0)
            }
        }

        Rectangle {
            id: tab1Btn
            anchors {
                left: tab0Btn.right
                leftMargin: 4
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            radius: 3
            color: activeFile === 1 ? "#1cb27e" : (tab1Mouse.containsMouse ? pal.light : pal.button)
            border.color: activeFile === 1 ? "#1cb27e" : pal.mid
            border.width: 1

            Text {
                anchors {
                    fill: parent
                    margins: 4
                }
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: extraLabel
                color: activeFile === 1 ? "white" : pal.buttonText
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            MouseArea {
                id: tab1Mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: switchTab(1)
            }
        }
    }

    // ── Bottom bar ────────────────────────────────────────────────────────────
    Item {
        id: bottomBar
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: 10
        }
        height: 34

        Rectangle {
            id: placeholdersBtn
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
            }
            width: 110
            height: 26
            radius: 4
            color: phMouse.pressed ? pal.dark : pal.button
            border.color: pal.mid
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: showHelp ? "Hide" : "Placeholders…"
                color: pal.buttonText
                font.pixelSize: 13
            }

            MouseArea {
                id: phMouse
                anchors.fill: parent
                onClicked: {
                    showHelp = !showHelp;
                    root.width = showHelp ? baseWidth + helpPanelWidth + 16 : baseWidth;
                }
            }
        }

        Rectangle {
            id: closeBtn
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }
            width: 76
            height: 26
            radius: 4
            color: closeMouse.pressed ? pal.dark : pal.button
            border.color: pal.mid
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Close"
                color: pal.buttonText
                font.pixelSize: 13
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                onClicked: confirmClose()
            }
        }
    }

    // ── Left panel: list ──────────────────────────────────────────────────────

    // +/− ↑↓ buttons
    Item {
        id: listButtons
        anchors {
            top: tabBar.visible ? tabBar.bottom : parent.top
            topMargin: tabBar.visible ? 6 : 10
            left: parent.left
            leftMargin: 10
        }
        width: 210
        height: 30

        Rectangle {
            id: addBtn
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
            }
            width: 32
            height: 26
            radius: 4
            color: addMouse.pressed ? pal.dark : pal.button
            border.color: pal.mid
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "+"
                color: pal.buttonText
                font.pixelSize: 16
            }

            MouseArea {
                id: addMouse
                anchors.fill: parent
                onClicked: addSnippet()
            }
        }

        Rectangle {
            id: removeBtn
            anchors {
                verticalCenter: parent.verticalCenter
                left: addBtn.right
                leftMargin: 4
            }
            width: 32
            height: 26
            radius: 4
            opacity: snippetList.currentIndex >= 0 ? 1.0 : 0.4
            color: removeMouse.pressed ? pal.dark : pal.button
            border.color: pal.mid
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "−"
                color: pal.buttonText
                font.pixelSize: 16
            }

            MouseArea {
                id: removeMouse
                anchors.fill: parent
                enabled: snippetList.currentIndex >= 0
                onClicked: removeSnippet(snippetList.currentIndex)
            }
        }

        Rectangle {
            id: moveUpBtn
            anchors {
                verticalCenter: parent.verticalCenter
                left: removeBtn.right
                leftMargin: 4
            }
            width: 32
            height: 26
            radius: 4
            opacity: snippetList.currentIndex > 0 ? 1.0 : 0.4
            color: moveUpMouse.pressed ? pal.dark : pal.button
            border.color: pal.mid
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "↑"
                color: pal.buttonText
                font.pixelSize: 14
            }

            MouseArea {
                id: moveUpMouse
                anchors.fill: parent
                enabled: snippetList.currentIndex > 0
                onClicked: moveItem(snippetList.currentIndex, -1)
            }
        }

        Rectangle {
            id: moveDownBtn
            anchors {
                verticalCenter: parent.verticalCenter
                left: moveUpBtn.right
                leftMargin: 4
            }
            width: 32
            height: 26
            radius: 4
            opacity: snippetList.currentIndex >= 0 && snippetList.currentIndex < items.length - 1 ? 1.0 : 0.4
            color: moveDownMouse.pressed ? pal.dark : pal.button
            border.color: pal.mid
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "↓"
                color: pal.buttonText
                font.pixelSize: 14
            }

            MouseArea {
                id: moveDownMouse
                anchors.fill: parent
                enabled: snippetList.currentIndex >= 0 && snippetList.currentIndex < items.length - 1
                onClicked: moveItem(snippetList.currentIndex, 1)
            }
        }
    }

    Rectangle {
        id: listPanel
        anchors {
            top: listButtons.bottom
            topMargin: 4
            left: parent.left
            leftMargin: 10
            bottom: bottomBar.top
            bottomMargin: 6
        }
        width: 210
        radius: 3
        color: pal.base
        border.color: pal.mid
        border.width: 1
        clip: true

        ListView {
            id: snippetList
            anchors {
                fill: parent
                margins: 1
                rightMargin: listScroll.visible ? 8 : 1
            }
            model: items
            currentIndex: -1
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            focus: true

            Keys.onDeletePressed: {
                if (currentIndex >= 0)
                    removeSnippet(currentIndex);
            }
            Keys.onPressed: function(event) {
                if ((event.key === Qt.Key_Up) && (event.modifiers & Qt.ControlModifier)) {
                    moveItem(currentIndex, -1);
                    event.accepted = true;
                } else if ((event.key === Qt.Key_Down) && (event.modifiers & Qt.ControlModifier)) {
                    moveItem(currentIndex, 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) {
                    if ((isDirty && editorEnabled) || listDirty)
                        saveCurrentItem();
                    event.accepted = true;
                } else if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
                    addSnippet();
                    event.accepted = true;
                }
            }

            delegate: Item {
                width: snippetList.width
                height: 28

                Rectangle {
                    anchors.fill: parent
                    color: index === snippetList.currentIndex ? "#1cb27e" : (rowMouse.containsMouse ? "#e4f5ef" : "transparent")
                }

                Text {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        margins: 8
                    }
                    text: modelData.name
                    color: index === snippetList.currentIndex ? "white" : pal.text
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        var target = index;
                        var curIdx = snippetList.currentIndex;
                        if (_editorLoaded && curIdx >= 0 && target !== curIdx && curIdx < items.length &&
                                (nameInput.text !== items[curIdx].name || contentEdit.text !== items[curIdx].content)) {
                            var answer = script.questionMessageBox("\"" + nameInput.text + "\" has unsaved changes.\nDiscard and switch?", "Unsaved changes", 16384 | 65536, 65536);
                            if (answer !== 16384)
                                return;
                        }
                        snippetList.currentIndex = target;
                        loadItem(target);
                    }
                }
            }
        }

        Rectangle {
            id: listScroll
            visible: snippetList.contentHeight > snippetList.height
            width: 5
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                margins: 1
            }
            color: "transparent"

            Rectangle {
                width: parent.width
                radius: 2
                color: pal.mid
                height: Math.max(24, snippetList.height * snippetList.height / Math.max(snippetList.contentHeight, 1))
                y: snippetList.height > 0 ? snippetList.contentY / Math.max(snippetList.contentHeight - snippetList.height, 1) * (snippetList.height - height) : 0
            }
        }
    }

    // ── Right panel: editor ───────────────────────────────────────────────────
    property bool editorEnabled: snippetList.currentIndex >= 0

    // Name row
    Text {
        id: nameLabel
        anchors {
            verticalCenter: listButtons.verticalCenter
            left: listPanel.right
            leftMargin: 16
        }
        text: "Name:"
        color: editorEnabled ? pal.text : pal.mid
        font.pixelSize: 13
    }

    Rectangle {
        id: nameBox
        anchors {
            verticalCenter: listButtons.verticalCenter
            left: nameLabel.right
            leftMargin: 6
            right: showHelp ? helpSep.left : parent.right
            rightMargin: 10
        }
        height: 28
        radius: 3
        color: pal.base
        border.color: nameInput.activeFocus ? "#1cb27e" : pal.mid
        border.width: 1
        opacity: editorEnabled ? 1.0 : 0.5

        TextInput {
            id: nameInput
            anchors {
                fill: parent
                margins: 6
            }
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: 13
            color: pal.text
            clip: true
            enabled: editorEnabled
            onTextChanged: {
                if (!updating)
                    isDirty = true;
            }
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) {
                    if ((isDirty && editorEnabled) || listDirty)
                        saveCurrentItem();
                    event.accepted = true;
                } else if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
                    addSnippet();
                    event.accepted = true;
                }
            }
        }
    }

    // Content label
    Text {
        id: contentLabel
        anchors {
            top: nameBox.bottom
            topMargin: 8
            left: listPanel.right
            leftMargin: 16
        }
        text: "Content"
        color: editorEnabled ? pal.text : pal.mid
        font.pixelSize: 13
    }

    // Save button (Ctrl+S)
    Rectangle {
        id: saveBtn
        anchors {
            verticalCenter: contentLabel.verticalCenter
            right: showHelp ? helpSep.left : parent.right
            rightMargin: 10
        }
        width: 76
        height: 26
        radius: 4
        opacity: (isDirty && editorEnabled) || listDirty ? 1.0 : 0.4
        color: saveMouse.pressed ? "#15896b" : "#1cb27e"

        Text {
            anchors.centerIn: parent
            text: "Save"
            color: "white"
            font.pixelSize: 13
        }

        MouseArea {
            id: saveMouse
            anchors.fill: parent
            enabled: (isDirty && editorEnabled) || listDirty
            onClicked: saveCurrentItem()
        }
    }

    // Content editor
    Rectangle {
        id: contentBox
        anchors {
            top: contentLabel.bottom
            topMargin: 4
            left: listPanel.right
            leftMargin: 10
            right: showHelp ? helpSep.left : parent.right
            rightMargin: 10
            bottom: bottomBar.top
            bottomMargin: 6
        }
        radius: 3
        color: editorEnabled ? pal.base : pal.window
        border.color: contentEdit.activeFocus ? "#1cb27e" : pal.mid
        border.width: 1
        clip: true

        Flickable {
            id: contentFlick
            anchors {
                fill: parent
                margins: 8
                rightMargin: contentScroll.visible ? 14 : 8
            }
            contentWidth: width
            contentHeight: contentEdit.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            clip: true

            TextEdit {
                id: contentEdit
                width: contentFlick.width
                height: Math.max(contentFlick.height, implicitHeight)
                wrapMode: Text.Wrap
                selectByMouse: true
                font.pixelSize: 13
                font.family: "monospace"
                color: pal.text
                enabled: editorEnabled
                onTextChanged: {
                    if (!updating)
                        isDirty = true;
                }
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) {
                        if ((isDirty && editorEnabled) || listDirty)
                            saveCurrentItem();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
                        addSnippet();
                        event.accepted = true;
                    }
                }
            }
        }

        Rectangle {
            id: contentScroll
            visible: contentFlick.contentHeight > contentFlick.height
            width: 5
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                margins: 1
            }
            color: "transparent"

            Rectangle {
                width: parent.width
                radius: 2
                color: pal.mid
                height: Math.max(24, contentFlick.height * contentFlick.height / Math.max(contentFlick.contentHeight, 1))
                y: contentFlick.height > 0 ? contentFlick.contentY / Math.max(contentFlick.contentHeight - contentFlick.height, 1) * (contentFlick.height - height) : 0
            }
        }
    }

    // ── Help panel ────────────────────────────────────────────────────────────
    Rectangle {
        id: helpSep
        visible: showHelp
        width: 8
        color: "transparent"
        // x computed from helpPanelWidth; no horizontal anchor so drag can update it
        x: root.width - 10 - helpPanelWidth - 8 - width
        anchors {
            top: parent.top
            topMargin: 10
            bottom: bottomBar.top
            bottomMargin: 6
        }

        Rectangle {
            anchors.centerIn: parent
            width: 1
            height: parent.height
            color: sepMouse.containsMouse || sepMouse.pressed ? "#1cb27e" : pal.mid
        }

        MouseArea {
            id: sepMouse
            anchors.fill: parent
            cursorShape: Qt.SplitHCursor
            hoverEnabled: true
            property real pressGlobalX: 0
            property real pressHelpWidth: 0
            onPressed: {
                pressGlobalX = mapToItem(null, mouseX, 0).x;
                pressHelpWidth = helpPanelWidth;
            }
            onPositionChanged: {
                if (pressed) {
                    var delta = mapToItem(null, mouseX, 0).x - pressGlobalX;
                    helpPanelWidth = Math.max(150, Math.min(root.width - 430, pressHelpWidth - delta));
                }
            }
        }
    }

    Rectangle {
        id: helpPanel
        visible: showHelp
        width: helpPanelWidth
        anchors {
            top: parent.top
            topMargin: 10
            right: parent.right
            rightMargin: 10
            bottom: bottomBar.top
            bottomMargin: 6
        }
        color: "transparent"

        TextEdit {
            anchors.fill: parent
            readOnly: true
            selectByMouse: true
            wrapMode: Text.NoWrap
            font.pixelSize: 12
            font.family: "monospace"
            color: pal.text
            text: "Date & time\n" + "  $CURRENT_YEAR             four-digit year    2026\n" + "  $CURRENT_YEAR_SHORT        two-digit year     26\n" + "  $CURRENT_MONTH             month              04\n" + "  $CURRENT_MONTH_NAME        full name          April\n" + "  $CURRENT_MONTH_NAME_SHORT  short name         Apr\n" + "  $CURRENT_DAY               day                29\n" + "  $CURRENT_DATE              day (deprecated)   29\n" + "  $CURRENT_HOUR              hour 00–23         14\n" + "  $CURRENT_MINUTE            minute             07\n" + "  $CURRENT_SECOND            second             03\n" + "  $CURRENT_SECONDS_UNIX      Unix timestamp     1745920023\n\n" + "Identifiers\n" + "  $UUID                      UUID v4\n\n" + "Note context\n" + "  $NOTE_TITLE                note title\n" + "  $NOTE_FILENAME             note filename\n\n" + "Editor context\n" + "  $CLIPBOARD                 clipboard text\n" + "  $SELECTION                 selected text\n" + "  $CURSOR                    cursor position after insert\n\n" + "System\n" + "  $OS_NAME                   Linux / macOS / Windows\n\n" + "Zettelkasten\n" + "  $ZK_ID                     ID (format in settings)"
        }
    }

    // ── Functions ─────────────────────────────────────────────────────────────
    function addSnippet() {
        if (isDirty && snippetList.currentIndex >= 0) {
            var answer = script.questionMessageBox("\"" + nameInput.text + "\" has unsaved changes.\nSave before adding a new snippet?", "Unsaved changes", 2048 | 8388608 | 4194304, 2048);
            if (answer === 2048) {
                saveCurrentItem();
            } else if (answer !== 8388608) {
                return;
            }
        }
        var copy = items.slice();
        copy.push({
            "name": "New snippet",
            "content": ""
        });
        items = copy;
        var idx = items.length - 1;
        snippetList.currentIndex = idx;
        loadItem(idx);
        nameInput.selectAll();
        nameInput.forceActiveFocus();
    }

    function removeSnippet(idx) {
        var copy = items.slice();
        copy.splice(idx, 1);
        items = copy;
        listDirty = true;
        var next = Math.min(idx, items.length - 1);
        snippetList.currentIndex = next;
        if (next >= 0)
            loadItem(next);
        else
            clearEditor();
    }

    function moveItem(idx, direction) {
        var newIdx = idx + direction;
        if (newIdx < 0 || newIdx >= items.length)
            return;
        var copy = items.slice();
        var tmp = copy[idx];
        copy[idx] = copy[newIdx];
        copy[newIdx] = tmp;
        items = copy;
        snippetList.currentIndex = newIdx;
        listDirty = true;
    }

    function loadItem(idx) {
        if (idx < 0 || idx >= items.length)
            return;
        updating = true;
        nameInput.text = items[idx].name;
        contentEdit.text = items[idx].content;
        updating = false;
        isDirty = false;
        _editorLoaded = true;
    }

    function clearEditor() {
        updating = true;
        nameInput.text = "";
        contentEdit.text = "";
        updating = false;
        isDirty = false;
        _editorLoaded = false;
    }

    function saveCurrentItem() {
        var idx = snippetList.currentIndex;
        if (idx >= 0) {
            var copy = items.slice();
            copy[idx] = {
                "name": nameInput.text,
                "content": contentEdit.text
            };
            items = copy;
            snippetList.currentIndex = idx;
        }
        var ti = _tabItems.slice();
        ti[activeFile] = JSON.parse(JSON.stringify(items));
        _tabItems = ti;
        var td = _tabListDirty.slice();
        td[activeFile] = false;
        _tabListDirty = td;
        isDirty = false;
        listDirty = false;
        snippetsSaved(items, activeFile);
    }

    function hasUnsavedChanges() {
        var curIdx = snippetList.currentIndex;
        if (_editorLoaded && curIdx >= 0 && curIdx < items.length) {
            if (nameInput.text !== items[curIdx].name || contentEdit.text !== items[curIdx].content)
                return true;
        }
        if (JSON.stringify(items) !== JSON.stringify(_tabItems[activeFile]))
            return true;
        var otherTab = activeFile === 0 ? 1 : 0;
        return !!_tabListDirty[otherTab];
    }

    function confirmClose() {
        if (hasUnsavedChanges()) {
            var answer = script.questionMessageBox("There are unsaved changes. Close without saving?", "Unsaved changes", 8388608 | 4194304, 4194304);
            if (answer !== 8388608)
                return;
        }
        root.close();
    }

    function switchTab(newTab) {
        if (newTab === activeFile)
            return;
        var _curIdx = snippetList.currentIndex;
        var _editorDirty = _editorLoaded && _curIdx >= 0 && _curIdx < items.length &&
            (nameInput.text !== items[_curIdx].name || contentEdit.text !== items[_curIdx].content);
        var _tabDirty = JSON.stringify(items) !== JSON.stringify(_tabItems[activeFile]);
        if (_editorDirty || _tabDirty) {
            var answer = script.questionMessageBox("Current tab has unsaved changes.\nSave before switching?", "Unsaved changes", 2048 | 8388608 | 4194304, 2048);
            if (answer === 2048) {
                saveCurrentItem();
            } else if (answer !== 8388608) {
                return;
            } else {
                isDirty = false;
            }
        }
        // Flush editor state into items before leaving current tab
        var curIdx = snippetList.currentIndex;
        if (curIdx >= 0 && isDirty) {
            var copy = items.slice();
            copy[curIdx] = {
                "name": nameInput.text,
                "content": contentEdit.text
            };
            items = copy;
        }
        // Persist current tab state
        var ti = _tabItems.slice();
        ti[activeFile] = JSON.parse(JSON.stringify(items));
        _tabItems = ti;
        var td = _tabListDirty.slice();
        td[activeFile] = isDirty || listDirty;
        _tabListDirty = td;
        // Activate new tab
        activeFile = newTab;
        items = JSON.parse(JSON.stringify(_tabItems[newTab]));
        snippetList.currentIndex = -1;
        clearEditor();
        listDirty = _tabListDirty[newTab];
    }
}
