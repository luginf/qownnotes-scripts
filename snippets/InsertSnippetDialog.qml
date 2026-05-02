import QtQuick 2.0
import QtQuick.Window 2.0

Window {
    id: root
    title: "Insert Snippet"
    width: 580
    height: 200
    minimumWidth: 400
    minimumHeight: 160
    modality: Qt.ApplicationModal
    flags: Qt.Dialog | Qt.WindowCloseButtonHint

    // entries: [{name, preview, originalIndex}]
    property var entries: []
    signal snippetChosen(int index)
    signal manageRequested
    property var filtered: []

    SystemPalette {
        id: pal
    }

    Component.onCompleted: {
        applyFilter();
        searchInput.forceActiveFocus();
    }

    // ── Search field ──────────────────────────────────────────────────────────
    Rectangle {
        id: searchBox
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 8
        }
        height: 26
        radius: 3
        color: pal.base
        border.color: searchInput.activeFocus ? "#1cb27e" : pal.mid
        border.width: 1

        Text {
            anchors {
                fill: parent
                leftMargin: 7
            }
            verticalAlignment: Text.AlignVCenter
            text: "Filter…"
            color: pal.mid
            font.pixelSize: 12
            visible: searchInput.text === ""
        }

        TextInput {
            id: searchInput
            anchors {
                fill: parent
                margins: 7
            }
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: 12
            color: pal.text
            clip: true
            onTextChanged: applyFilter()
            Keys.onReturnPressed: acceptSelection()
            Keys.onDownPressed: moveSelection(1)
            Keys.onUpPressed: moveSelection(-1)
        }
    }

    // ── Bottom bar ────────────────────────────────────────────────────────────
    Item {
        id: bottomBar
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: 8
        }
        height: 30

        // Manage button (left side)
        Rectangle {
            id: manageBtn
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
            }
            width: 70
            height: 24
            radius: 4
            color: manageMouse.pressed ? pal.dark : pal.button
            border.color: pal.mid
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Manage…"
                color: pal.buttonText
                font.pixelSize: 12
            }

            MouseArea {
                id: manageMouse
                anchors.fill: parent
                onClicked: {
                    manageRequested();
                    root.close();
                }
            }
        }

        Rectangle {
            id: cancelBtn
            anchors {
                verticalCenter: parent.verticalCenter
                right: insertBtn.left
                rightMargin: 6
            }
            width: 64
            height: 24
            radius: 4
            color: cancelMouse.pressed ? pal.dark : pal.button
            border.color: pal.mid
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Cancel"
                color: pal.buttonText
                font.pixelSize: 12
            }

            MouseArea {
                id: cancelMouse
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: insertBtn
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }
            width: 64
            height: 24
            radius: 4
            opacity: snippetList.currentIndex >= 0 && filtered.length > 0 ? 1.0 : 0.4
            color: insertMouse.pressed ? "#15896b" : "#1cb27e"

            Text {
                anchors.centerIn: parent
                text: "Insert"
                color: "white"
                font.pixelSize: 12
            }

            MouseArea {
                id: insertMouse
                anchors.fill: parent
                enabled: snippetList.currentIndex >= 0 && filtered.length > 0
                onClicked: acceptSelection()
            }
        }
    }

    // ── Left panel: snippet list ──────────────────────────────────────────────
    Rectangle {
        id: listPanel
        anchors {
            top: searchBox.bottom
            topMargin: 5
            left: parent.left
            leftMargin: 8
            bottom: bottomBar.top
            bottomMargin: 5
        }
        width: 180
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
            model: filtered
            currentIndex: filtered.length > 0 ? 0 : -1
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                width: snippetList.width
                height: 24

                Rectangle {
                    anchors.fill: parent
                    color: index === snippetList.currentIndex ? "#1cb27e" : (rowMouse.containsMouse ? "#e4f5ef" : "transparent")
                }

                Text {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        margins: 7
                    }
                    text: modelData.name
                    color: index === snippetList.currentIndex ? "white" : pal.text
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: snippetList.currentIndex = index
                    onDoubleClicked: acceptSelection()
                }
            }

            onCurrentIndexChanged: {
                if (currentIndex >= 0 && currentIndex < filtered.length)
                    previewEdit.text = filtered[currentIndex].preview;
                else
                    previewEdit.text = "";
            }
        }

        Rectangle {
            id: listScroll
            visible: snippetList.contentHeight > snippetList.height
            width: 4
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
                height: Math.max(20, snippetList.height * snippetList.height / Math.max(snippetList.contentHeight, 1))
                y: snippetList.height > 0 ? snippetList.contentY / Math.max(snippetList.contentHeight - snippetList.height, 1) * (snippetList.height - height) : 0
            }
        }

        Text {
            anchors.centerIn: parent
            visible: filtered.length === 0
            text: "No match."
            color: pal.mid
            font.pixelSize: 12
        }
    }

    // ── Right panel: preview ──────────────────────────────────────────────────
    Text {
        id: previewLabel
        anchors {
            top: searchBox.bottom
            topMargin: 8
            left: listPanel.right
            leftMargin: 10
        }
        text: "Preview"
        color: pal.mid
        font.pixelSize: 10
    }

    Rectangle {
        id: previewPanel
        anchors {
            top: previewLabel.bottom
            topMargin: 2
            left: listPanel.right
            leftMargin: 8
            right: parent.right
            rightMargin: 8
            bottom: bottomBar.top
            bottomMargin: 5
        }
        radius: 3
        color: pal.base
        border.color: pal.mid
        border.width: 1
        clip: true

        Flickable {
            id: previewFlick
            anchors {
                fill: parent
                margins: 7
                rightMargin: previewScroll.visible ? 12 : 7
            }
            contentWidth: width
            contentHeight: previewEdit.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            clip: true

            TextEdit {
                id: previewEdit
                width: previewFlick.width
                height: Math.max(previewFlick.height, implicitHeight)
                readOnly: true
                selectByMouse: true
                wrapMode: Text.Wrap
                font.pixelSize: 12
                font.family: "monospace"
                color: pal.text
            }
        }

        Rectangle {
            id: previewScroll
            visible: previewFlick.contentHeight > previewFlick.height
            width: 4
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
                height: Math.max(20, previewFlick.height * previewFlick.height / Math.max(previewFlick.contentHeight, 1))
                y: previewFlick.height > 0 ? previewFlick.contentY / Math.max(previewFlick.contentHeight - previewFlick.height, 1) * (previewFlick.height - height) : 0
            }
        }
    }

    // ── Logic ─────────────────────────────────────────────────────────────────
    function moveSelection(delta) {
        var next = snippetList.currentIndex + delta;
        if (next >= 0 && next < snippetList.count)
            snippetList.currentIndex = next;
    }

    function applyFilter() {
        var f = searchInput.text ? searchInput.text.toLowerCase() : "";
        var result = [];
        for (var i = 0; i < entries.length; i++) {
            if (!f || entries[i].name.toLowerCase().indexOf(f) >= 0)
                result.push(entries[i]);
        }
        filtered = result;
        snippetList.currentIndex = result.length > 0 ? 0 : -1;
    }

    function acceptSelection() {
        var idx = snippetList.currentIndex;
        if (idx < 0 || idx >= filtered.length)
            return;
        snippetChosen(filtered[idx].originalIndex);
        root.close();
    }
}
