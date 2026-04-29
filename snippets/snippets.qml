// Text Snippets — insert reusable text snippets with placeholders into notes.
//
// Placeholders (date & time):
//   $CURRENT_YEAR             four-digit year          2026
//   $CURRENT_YEAR_SHORT       two-digit year           26
//   $CURRENT_MONTH            two-digit month          04
//   $CURRENT_MONTH_NAME       full month name          April  (system locale)
//   $CURRENT_MONTH_NAME_SHORT short month name         Apr    (system locale)
//   $CURRENT_DATE             two-digit day            29
//   $CURRENT_HOUR             hour 00–23               14
//   $CURRENT_MINUTE           two-digit minute         07
//   $CURRENT_SECOND           two-digit second         03
//   $CURRENT_SECONDS_UNIX     Unix timestamp           1745920023
//
// Placeholders (identifiers):
//   $UUID                     UUID v4                  550e8400-e29b-41d4-a716-446655440000
//
// Placeholders (note context):
//   $NOTE_TITLE               current note title       My note
//   $NOTE_FILENAME            current note filename    my-note.md
//
// Placeholders (system):
//   $OS_NAME                  operating system name    Linux

import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    property string scriptDirPath

    function init() {
        script.registerCustomAction("insertSnippet", "Insert snippet", "Snippet", "", false, false, false);
        script.registerCustomAction("manageSnippets", "Manage snippets", "", "", false, true, false);
    }

    function customActionInvoked(identifier) {
        if (identifier === "insertSnippet") {
            insertSnippet();
        } else if (identifier === "manageSnippets") {
            manageSnippets();
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    function pad(n) {
        return n < 10 ? "0" + n : String(n);
    }

    function generateUUID() {
        return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c) {
            var r = Math.random() * 16 | 0;
            return (c === "x" ? r : (r & 0x3 | 0x8)).toString(16);
        });
    }

    function processPlaceholders(text) {
        var now = new Date();
        var loc = Qt.locale();
        var note = script.currentNote();
        var osMap = { "linux": "Linux", "osx": "macOS", "windows": "Windows", "unix": "Unix" };
        return text
            .replace(/\$CURRENT_YEAR_SHORT/g,      String(now.getFullYear()).slice(-2))
            .replace(/\$CURRENT_YEAR/g,             String(now.getFullYear()))
            .replace(/\$CURRENT_MONTH_NAME_SHORT/g, loc.monthName(now.getMonth(), 1))
            .replace(/\$CURRENT_MONTH_NAME/g,       loc.monthName(now.getMonth(), 0))
            .replace(/\$CURRENT_MONTH/g,            pad(now.getMonth() + 1))
            .replace(/\$CURRENT_DATE/g,             pad(now.getDate()))
            .replace(/\$CURRENT_HOUR/g,             pad(now.getHours()))
            .replace(/\$CURRENT_MINUTE/g,           pad(now.getMinutes()))
            .replace(/\$CURRENT_SECOND/g,           pad(now.getSeconds()))
            .replace(/\$CURRENT_SECONDS_UNIX/g,     String(Math.floor(now.getTime() / 1000)))
            .replace(/\$UUID/g,                     generateUUID())
            .replace(/\$NOTE_TITLE/g,               note ? note.name     : "")
            .replace(/\$NOTE_FILENAME/g,            note ? note.fileName : "")
            .replace(/\$OS_NAME/g,                  osMap[Qt.platform.os] || Qt.platform.os);
    }

    function snippetsFilePath() {
        return scriptDirPath + "/snippets.json";
    }

    function loadSnippets() {
        var path = snippetsFilePath();
        if (!script.fileExists(path)) return [];
        try {
            return JSON.parse(script.readFromFile(path, "UTF-8"));
        } catch (e) {
            script.log("snippets: JSON read error — " + e);
            return [];
        }
    }

    function saveSnippets(snippets) {
        script.writeToFile(snippetsFilePath(), JSON.stringify(snippets, null, 2), false);
    }

    // ── Actions ───────────────────────────────────────────────────────────────

    function insertSnippet() {
        var snippets = loadSnippets();
        if (snippets.length === 0) {
            script.informationMessageBox(
                "No snippets defined yet.\nUse Scripting › Manage snippets to create one.",
                "Snippets"
            );
            return;
        }

        var names = [];
        for (var i = 0; i < snippets.length; i++) names.push(snippets[i].name);

        var selected = script.inputDialogGetItem("Insert snippet", "Snippet:", names, 0, false);
        if (!selected) return;

        for (var j = 0; j < snippets.length; j++) {
            if (snippets[j].name === selected) {
                script.noteTextEditWrite(processPlaceholders(snippets[j].content));
                return;
            }
        }
    }

    function manageSnippets() {
        var component = Qt.createComponent(Qt.resolvedUrl("ManageSnippetsDialog.qml"));
        if (component.status !== Component.Ready) {
            script.log("snippets: failed to load dialog — " + component.errorString());
            return;
        }
        var dialog = component.createObject(null, { snippets: loadSnippets() });
        if (!dialog) {
            script.log("snippets: failed to instantiate dialog");
            return;
        }
        dialog.snippetsSaved.connect(function(updated) {
            saveSnippets(updated);
        });
        dialog.show();
    }
}
