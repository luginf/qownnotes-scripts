import QtQuick 2.0
import QtQuick.Window 2.0

Window {
    id: root
    title: "Insert Zettelkasten link"
    width: 620
    height: 420
    minimumWidth: 480
    minimumHeight: 300
    modality: Qt.ApplicationModal
    flags: Qt.Dialog | Qt.WindowCloseButtonHint

    property var entries: []
    signal linkSelected(string linkTarget, string zkId)
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
            margins: 10
        }
        height: 30
        radius: 3
        color: pal.base
        border.color: searchInput.activeFocus ? "#1cb27e" : pal.mid
        border.width: 1

        Text {
            anchors {
                fill: parent
                leftMargin: 8
            }
            verticalAlignment: Text.AlignVCenter
            text: "Filter by name…"
            color: pal.mid
            font.pixelSize: 13
            visible: searchInput.text === ""
        }

        TextInput {
            id: searchInput
            anchors {
                fill: parent
                margins: 8
            }
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: 13
            color: pal.text
            clip: true
            onTextChanged: applyFilter()
            Keys.onReturnPressed: acceptSelection()
            Keys.onDownPressed: moveSelection(1)
            Keys.onUpPressed: moveSelection(-1)
        }
    }

    // ── Note list ─────────────────────────────────────────────────────────────
    Rectangle {
        id: listBox
        anchors {
            top: searchBox.bottom
            topMargin: 6
            left: parent.left
            right: parent.right
            margins: 10
            bottom: bottomBar.top
            bottomMargin: 6
        }
        radius: 3
        color: pal.base
        border.color: pal.mid
        border.width: 1
        clip: true

        ListView {
            id: resultList
            anchors {
                fill: parent
                margins: 1
                rightMargin: scrollBar.visible ? 8 : 1
            }
            model: filtered
            currentIndex: 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                width: resultList.width
                height: 28

                Rectangle {
                    anchors.fill: parent
                    color: index === resultList.currentIndex ? "#1cb27e" : (rowMouse.containsMouse ? "#e4f5ef" : "transparent")
                }

                Text {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        margins: 8
                    }
                    text: modelData.label
                    color: index === resultList.currentIndex ? "white" : pal.text
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: resultList.currentIndex = index
                    onDoubleClicked: acceptSelection()
                }
            }
        }

        // Minimal scrollbar
        Rectangle {
            id: scrollBar
            visible: resultList.contentHeight > resultList.height
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
                height: Math.max(24, resultList.height * resultList.height / Math.max(resultList.contentHeight, 1))
                y: resultList.height > 0 ? resultList.contentY / Math.max(resultList.contentHeight - resultList.height, 1) * (resultList.height - height) : 0
            }
        }

        Text {
            anchors.centerIn: parent
            visible: filtered.length === 0
            text: "No matching note found."
            color: pal.mid
            font.pixelSize: 13
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

        Text {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
            }
            text: filtered.length + " note(s)"
            color: pal.mid
            font.pixelSize: 12
        }

        // Cancel
        Rectangle {
            id: cancelBtn
            anchors {
                verticalCenter: parent.verticalCenter
                right: insertBtn.left
                rightMargin: 8
            }
            width: 76
            height: 26
            radius: 4
            color: cancelMouse.pressed ? pal.dark : pal.button
            border.color: pal.mid
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Cancel"
                color: pal.buttonText
                font.pixelSize: 13
            }
            MouseArea {
                id: cancelMouse
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        // Insert
        Rectangle {
            id: insertBtn
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }
            width: 76
            height: 26
            radius: 4
            opacity: (resultList.currentIndex >= 0 && filtered.length > 0) ? 1.0 : 0.4
            color: insertMouse.pressed ? "#15896b" : "#1cb27e"

            Text {
                anchors.centerIn: parent
                text: "Insert"
                color: "white"
                font.pixelSize: 13
            }
            MouseArea {
                id: insertMouse
                anchors.fill: parent
                enabled: resultList.currentIndex >= 0 && filtered.length > 0
                onClicked: acceptSelection()
            }
        }
    }

    // ── Logic ─────────────────────────────────────────────────────────────────
    function moveSelection(delta) {
        var next = resultList.currentIndex + delta;
        if (next >= 0 && next < resultList.count)
            resultList.currentIndex = next;
    }

    function applyFilter() {
        var f = searchInput.text ? searchInput.text.toLowerCase() : "";
        var result = [];
        for (var i = 0; i < entries.length; i++) {
            if (!f || entries[i].label.toLowerCase().indexOf(f) >= 0)
                result.push(entries[i]);
        }
        filtered = result;
        resultList.currentIndex = result.length > 0 ? 0 : -1;
    }

    function acceptSelection() {
        var idx = resultList.currentIndex;
        if (idx < 0 || idx >= filtered.length)
            return;
        linkSelected(filtered[idx].linkTarget, filtered[idx].zkId);
        root.close();
    }
}
