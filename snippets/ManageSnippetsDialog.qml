import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
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

    // Input / output
    property var snippets: []
    signal snippetsSaved(var updatedSnippets)

    // Internal state
    property var items: []
    property bool updating: false
    property bool isDirty: false

    Component.onCompleted: {
        items = JSON.parse(JSON.stringify(snippets));
    }

    // ── Layout ───────────────────────────────────────────────────────────────

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // ── Left panel: list + +/- buttons ───────────────────────────────
            ColumnLayout {
                Layout.preferredWidth: 200
                Layout.minimumWidth: 140
                Layout.fillHeight: true
                spacing: 4

                RowLayout {
                    spacing: 4

                    Button {
                        text: "+"
                        implicitWidth: 32
                        implicitHeight: 28
                        onClicked: {
                            var copy = items.slice();
                            copy.push({ name: "New snippet", content: "" });
                            items = copy;
                            var idx = items.length - 1;
                            snippetList.currentIndex = idx;
                            loadItem(idx);
                            nameField.selectAll();
                            nameField.forceActiveFocus();
                        }
                    }

                    Button {
                        text: "−"
                        implicitWidth: 32
                        implicitHeight: 28
                        enabled: snippetList.currentIndex >= 0
                        onClicked: {
                            var idx = snippetList.currentIndex;
                            var copy = items.slice();
                            copy.splice(idx, 1);
                            items = copy;
                            snippetsSaved(items);
                            var next = Math.min(idx, items.length - 1);
                            snippetList.currentIndex = next;
                            if (next >= 0) loadItem(next);
                            else clearEditor();
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    border.color: palette.mid
                    border.width: 1
                    radius: 3
                    clip: true

                    ListView {
                        id: snippetList
                        anchors.fill: parent
                        anchors.margins: 1
                        model: items
                        currentIndex: -1
                        clip: true

                        delegate: ItemDelegate {
                            width: snippetList.width
                            text: modelData.name
                            highlighted: ListView.isCurrentItem
                            onClicked: {
                                snippetList.currentIndex = index;
                                loadItem(index);
                            }
                        }

                        ScrollBar.vertical: ScrollBar {}
                    }
                }
            }

            // ── Right panel: editor ──────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6
                enabled: snippetList.currentIndex >= 0

                RowLayout {
                    spacing: 6
                    Label { text: "Name:" }
                    TextField {
                        id: nameField
                        Layout.fillWidth: true
                        placeholderText: "Snippet name"
                        selectByMouse: true
                        onTextChanged: if (!updating) isDirty = true
                    }
                }

                Label {
                    text: "Content"
                    color: palette.dark
                    font.pointSize: font.pointSize - 1
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        id: contentArea
                        width: parent.width
                        wrapMode: Text.Wrap
                        selectByMouse: true
                        placeholderText: "Snippet content…"
                        background: Rectangle {
                            border.color: contentArea.activeFocus ? palette.highlight : palette.mid
                            border.width: 1
                            radius: 3
                            color: palette.base
                        }
                        onTextChanged: if (!updating) isDirty = true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Save"
                        enabled: isDirty && snippetList.currentIndex >= 0
                        onClicked: saveCurrentItem()
                    }
                }
            }
        }

        // ── Bottom bar ───────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            Button {
                text: "Close"
                onClicked: root.close()
            }
        }
    }

    // ── Functions ─────────────────────────────────────────────────────────────

    function loadItem(idx) {
        if (idx < 0 || idx >= items.length) return;
        updating = true;
        nameField.text    = items[idx].name;
        contentArea.text  = items[idx].content;
        updating = false;
        isDirty = false;
    }

    function clearEditor() {
        updating = true;
        nameField.text   = "";
        contentArea.text = "";
        updating = false;
        isDirty = false;
    }

    function saveCurrentItem() {
        var idx = snippetList.currentIndex;
        if (idx < 0) return;
        var copy = items.slice();
        copy[idx] = { name: nameField.text, content: contentArea.text };
        items = copy;
        snippetList.currentIndex = idx;
        isDirty = false;
        snippetsSaved(items);
    }
}
