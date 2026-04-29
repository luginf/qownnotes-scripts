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

    SystemPalette { id: palette }

    Window {
        id: helpWindow
        title: "Snippets — Placeholders"
        width: 640
        height: 460
        minimumWidth: 500
        minimumHeight: 360
        flags: Qt.Dialog | Qt.WindowCloseButtonHint

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            TextArea {
                Layout.fillWidth: true
                readOnly: true
                selectByMouse: true
                background: null
                font.family: "monospace"
                font.pointSize: Qt.application.font.pointSize - 1
                text:
                    "Date & time\n" +
                    "  $CURRENT_YEAR             four-digit year          2026\n" +
                    "  $CURRENT_YEAR_SHORT        two-digit year           26\n" +
                    "  $CURRENT_MONTH             two-digit month          04\n" +
                    "  $CURRENT_MONTH_NAME        full month name          April\n" +
                    "  $CURRENT_MONTH_NAME_SHORT  short month name         Apr\n" +
                    "  $CURRENT_DATE              two-digit day            29\n" +
                    "  $CURRENT_HOUR              hour 00–23               14\n" +
                    "  $CURRENT_MINUTE            two-digit minute         07\n" +
                    "  $CURRENT_SECOND            two-digit second         03\n" +
                    "  $CURRENT_SECONDS_UNIX      Unix timestamp           1745920023\n\n" +
                    "Identifiers\n" +
                    "  $UUID                      UUID v4                  550e8400-e29b-41d4-a716-446655440000\n\n" +
                    "Note context\n" +
                    "  $NOTE_TITLE                current note title       My note\n" +
                    "  $NOTE_FILENAME             current note filename    my-note.md\n\n" +
                    "System\n" +
                    "  $OS_NAME                   operating system         Linux / macOS / Windows"
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "Close"
                    onClicked: helpWindow.close()
                }
            }
        }
    }

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
                    font.pointSize: Qt.application.font.pointSize - 1
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    border.color: contentArea.activeFocus ? palette.highlight : palette.mid
                    border.width: 1
                    radius: 3
                    color: palette.base
                    clip: true

                    Flickable {
                        id: contentFlick
                        anchors.fill: parent
                        anchors.margins: 1
                        contentWidth: width
                        contentHeight: contentArea.implicitHeight
                        flickableDirection: Flickable.VerticalFlick
                        clip: true

                        TextArea {
                            id: contentArea
                            width: contentFlick.width
                            height: Math.max(contentFlick.height, implicitHeight)
                            wrapMode: Text.Wrap
                            selectByMouse: true
                            placeholderText: "Snippet content…"
                            background: null
                            onTextChanged: if (!updating) isDirty = true
                        }

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
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
            Button {
                text: "Placeholders…"
                onClicked: helpWindow.show()
            }
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
