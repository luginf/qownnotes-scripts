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

    property var snippets: []
    signal snippetsSaved(var updatedSnippets)

    property var items: []
    property bool updating: false
    property bool isDirty: false
    property bool showHelp: false

    readonly property int baseWidth: 720
    readonly property int helpPanelWidth: 320

    SystemPalette {
        id: pal
    }

    Component.onCompleted: {
        items = JSON.parse(JSON.stringify(snippets));
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
                onClicked: root.close()
            }
        }
    }

    // ── Left panel: list ──────────────────────────────────────────────────────

    // +/- buttons
    Item {
        id: listButtons
        anchors {
            top: parent.top
            topMargin: 10
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
                onClicked: {
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
                onClicked: {
                    var idx = snippetList.currentIndex;
                    var copy = items.slice();
                    copy.splice(idx, 1);
                    items = copy;
                    snippetsSaved(items);
                    var next = Math.min(idx, items.length - 1);
                    snippetList.currentIndex = next;
                    if (next >= 0)
                        loadItem(next);
                    else
                        clearEditor();
                }
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
                        snippetList.currentIndex = index;
                        loadItem(index);
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

    // Save button
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
        opacity: isDirty && editorEnabled ? 1.0 : 0.4
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
            enabled: isDirty && editorEnabled
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
        width: 1
        color: pal.mid
        anchors {
            top: parent.top
            topMargin: 10
            bottom: bottomBar.top
            bottomMargin: 6
            right: helpPanel.left
            rightMargin: 8
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
            text: "Date & time\n" + "  $CURRENT_YEAR             four-digit year    2026\n" + "  $CURRENT_YEAR_SHORT        two-digit year     26\n" + "  $CURRENT_MONTH             month              04\n" + "  $CURRENT_MONTH_NAME        full name          April\n" + "  $CURRENT_MONTH_NAME_SHORT  short name         Apr\n" + "  $CURRENT_DATE              day                29\n" + "  $CURRENT_HOUR              hour 00–23         14\n" + "  $CURRENT_MINUTE            minute             07\n" + "  $CURRENT_SECOND            second             03\n" + "  $CURRENT_SECONDS_UNIX      Unix timestamp     1745920023\n\n" + "Identifiers\n" + "  $UUID                      UUID v4\n\n" + "Note context\n" + "  $NOTE_TITLE                note title\n" + "  $NOTE_FILENAME             note filename\n\n" + "System\n" + "  $OS_NAME                   Linux / macOS / Windows\n\n" + "Zettelkasten\n" + "  $ZK_ID                     ID (format in settings)"
        }
    }

    // ── Functions ─────────────────────────────────────────────────────────────
    function loadItem(idx) {
        if (idx < 0 || idx >= items.length)
            return;
        updating = true;
        nameInput.text = items[idx].name;
        contentEdit.text = items[idx].content;
        updating = false;
        isDirty = false;
    }

    function clearEditor() {
        updating = true;
        nameInput.text = "";
        contentEdit.text = "";
        updating = false;
        isDirty = false;
    }

    function saveCurrentItem() {
        var idx = snippetList.currentIndex;
        if (idx < 0)
            return;
        var copy = items.slice();
        copy[idx] = {
            "name": nameInput.text,
            "content": contentEdit.text
        };
        items = copy;
        snippetList.currentIndex = idx;
        isDirty = false;
        snippetsSaved(items);
    }
}
