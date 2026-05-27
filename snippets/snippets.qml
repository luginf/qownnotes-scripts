// Text Snippets — insert reusable text snippets with placeholders into notes.
// Placeholders (date & time):
//   $CURRENT_YEAR             four-digit year          2026
//   $CURRENT_YEAR_SHORT       two-digit year           26
//   $CURRENT_MONTH            two-digit month          04
//   $CURRENT_MONTH_NAME       full month name          April  (system locale)
//   $CURRENT_MONTH_NAME_SHORT short month name         Apr    (system locale)
//   $CURRENT_DAY              two-digit day            29
//   $CURRENT_DATE             two-digit day            29     (deprecated: use $CURRENT_DAY)
//   $CURRENT_HOUR             hour 00–23               14
//   $CURRENT_MINUTE           two-digit minute         07
//   $CURRENT_SECOND           two-digit second         03
//   $CURRENT_SECONDS_UNIX     Unix timestamp           1745920023
// Placeholders (identifiers):
//   $UUID                     UUID v4                  550e8400-e29b-41d4-a716-446655440000
// Placeholders (note context):
//   $NOTE_TITLE               current note title       My note
//   $NOTE_FILENAME            current note filename    my-note.md
// Placeholders (editor context):
//   $CLIPBOARD                clipboard text           (current clipboard content)
//   $SELECTION                selected text            (currently selected text in the editor)
//   $CURSOR                   cursor position          (not replaced — positions the cursor here after insertion)
// Placeholders (system):
//   $OS_NAME                  operating system name    Linux
import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    property string scriptDirPath
    property string zkIdFormat
    property string extraSnippetsFile
    property bool extraFirst

    property variant settingsVariables: [
        {
            "identifier": "zkIdFormat",
            "name": "Zettelkasten ID format",
            "description": "Format string used by the $ZK_ID placeholder. Uses the same tokens as the Zettelkasten extension — set both to the same value to keep IDs consistent.\nTokens: %Y=year  %M=month  %D=day  %h=hour  %m=minute  %s=second\n\nExamples:\n  %Y%M%D%h%m%s      →  20260430143012\n  id%Y%M%Dx%h%m%s   →  id20260430x143012",
            "type": "string",
            "default": "%Y%M%D%h%m%s"
        },
        {
            "identifier": "extraSnippetsFile",
            "name": "Extra snippets file (optional)",
            "description": "Absolute path to a second snippets.json to merge with the primary one. Useful to combine a local development copy with the installed script's snippets.\n\nExample: /home/user/.local/share/PBE/QOwnNotes/scripts/snippets/snippets.json\n\nLeave empty to use only the primary file.",
            "type": "string",
            "default": ""
        },
        {
            "identifier": "extraFirst",
            "name": "Extra snippets first",
            "description": "When checked, snippets from the extra file appear before those from the primary file in the insert list.",
            "type": "boolean",
            "default": false
        }
    ]

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

    function generateZkId() {
        var fmt = (zkIdFormat || "").trim() || "%Y%M%D%h%m%s";
        var now = new Date();
        return fmt.replace(/%Y/g, String(now.getFullYear())).replace(/%M/g, pad(now.getMonth() + 1)).replace(/%D/g, pad(now.getDate())).replace(/%h/g, pad(now.getHours())).replace(/%m/g, pad(now.getMinutes())).replace(/%s/g, pad(now.getSeconds()));
    }

    function generateUUID() {
        return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
            var r = Math.random() * 16 | 0;
            return (c === "x" ? r : (r & 0x3 | 0x8)).toString(16);
        });
    }

    function processPlaceholders(text) {
        var now = new Date();
        var loc = Qt.locale();
        var note = script.currentNote();
        var osMap = {
            "linux": "Linux",
            "osx": "macOS",
            "windows": "Windows",
            "unix": "Unix"
        };
        var clipboard = "";
        try {
            clipboard = script.clipboard();
        } catch (e) {}
        var selection = "";
        try {
            selection = script.noteTextEditSelectedText();
        } catch (e) {}
        var placeholders = {
            "$CURRENT_SECONDS_UNIX": String(Math.floor(now.getTime() / 1000)),
            "$CURRENT_YEAR_SHORT": String(now.getFullYear()).slice(-2),
            "$CURRENT_YEAR": String(now.getFullYear()),
            "$CURRENT_MONTH_NAME_SHORT": loc.monthName(now.getMonth(), 1),
            "$CURRENT_MONTH_NAME": loc.monthName(now.getMonth(), 0),
            "$CURRENT_MONTH": pad(now.getMonth() + 1),
            "$CURRENT_DAY": pad(now.getDate()),
            "$CURRENT_DATE": pad(now.getDate()),
            "$CURRENT_HOUR": pad(now.getHours()),
            "$CURRENT_MINUTE": pad(now.getMinutes()),
            "$CURRENT_SECOND": pad(now.getSeconds()),
            "$UUID": generateUUID(),
            "$NOTE_TITLE": note ? note.name : "",
            "$NOTE_FILENAME": note ? note.fileName : "",
            "$CLIPBOARD": clipboard,
            "$SELECTION": selection,
            "$OS_NAME": osMap[Qt.platform.os] || Qt.platform.os,
            "$ZK_ID": generateZkId()
        };
        return text.replace(/\$(?:CURRENT_SECONDS_UNIX|CURRENT_YEAR_SHORT|CURRENT_YEAR|CURRENT_MONTH_NAME_SHORT|CURRENT_MONTH_NAME|CURRENT_MONTH|CURRENT_DAY|CURRENT_DATE|CURRENT_HOUR|CURRENT_MINUTE|CURRENT_SECOND|UUID|NOTE_TITLE|NOTE_FILENAME|CLIPBOARD|SELECTION|OS_NAME|ZK_ID)/g, function (match) {
            return placeholders[match];
        });
    }

    function snippetsFilePath() {
        return scriptDirPath + "/snippets.json";
    }

    function loadSnippetsFromFile(path) {
        if (!script.fileExists(path))
            return [];
        try {
            return JSON.parse(script.readFromFile(path, "UTF-8"));
        } catch (e) {
            script.log("snippets: JSON read error (" + path + ") — " + e);
            return [];
        }
    }

    function loadSnippets() {
        var primary = loadSnippetsFromFile(snippetsFilePath());
        var extra = (extraSnippetsFile || "").trim();
        if (!extra)
            return primary;
        return primary.concat(loadSnippetsFromFile(extra));
    }

    function saveSnippets(snippets) {
        var path = snippetsFilePath();
        if (!script.writeToFile(path, JSON.stringify(snippets, null, 2)))
            script.informationMessageBox("Could not write to:\n" + path + "\n\nCheck that the file is writable.", "Snippets — save failed");
    }

    // ── Actions ───────────────────────────────────────────────────────────────
    function insertSnippet() {
        var primary = loadSnippetsFromFile(snippetsFilePath());
        var extra = (extraSnippetsFile || "").trim();
        var extraItems = extra ? loadSnippetsFromFile(extra) : [];
        var snippets = extraFirst ? extraItems.concat(primary) : primary.concat(extraItems);
        if (snippets.length === 0) {
            script.informationMessageBox("No snippets defined yet.\nUse Scripting › Manage snippets to create one.", "Snippets");
            return;
        }

        // Build entries: preview resolved at dialog-open time, originalIndex for
        // re-resolution at insertion, fileIndex (0=primary/1=extra) and localIndex
        // (index within that file) so Manage can open on the right tab and row.
        var entries = [];
        for (var i = 0; i < snippets.length; i++) {
            var fi, localIdx;
            if (extraFirst) {
                fi = i < extraItems.length ? 1 : 0;
                localIdx = fi === 1 ? i : i - extraItems.length;
            } else {
                fi = i < primary.length ? 0 : 1;
                localIdx = fi === 0 ? i : i - primary.length;
            }
            entries.push({
                "name": snippets[i].name,
                "preview": processPlaceholders(snippets[i].content),
                "originalIndex": i,
                "fileIndex": fi,
                "localIndex": localIdx
            });
        }
        var component = Qt.createComponent(Qt.resolvedUrl("InsertSnippetDialog.qml"));
        if (component.status !== Component.Ready) {
            script.log("snippets: failed to load InsertSnippetDialog — " + component.errorString());
            return;
        }
        var dialog = component.createObject(null, {
            "entries": entries,
            "hasExtra": extraItems.length > 0
        });
        if (!dialog) {
            script.log("snippets: failed to instantiate InsertSnippetDialog");
            return;
        }
        // Re-process placeholders at insertion time so timestamps are fresh.
        // $CURSOR is handled here: the text is split at $CURSOR and the cursor
        // is repositioned after writing.
        dialog.snippetChosen.connect(function (originalIndex) {
            var text = processPlaceholders(snippets[originalIndex].content);
            var cursorIdx = text.indexOf("$CURSOR");
            if (cursorIdx >= 0) {
                var insertPos = script.noteTextEditCursorPosition();
                script.noteTextEditWrite(text.replace("$CURSOR", ""));
                script.noteTextEditSetCursorPosition(insertPos + cursorIdx);
            } else {
                script.noteTextEditWrite(text);
            }
            mainWindow.focusNoteTextEdit();
        });
        dialog.manageRequested.connect(function (fileIndex, localIndex) {
            var md = manageSnippets(fileIndex, localIndex);
            if (md) {
                var oldDialog = dialog;
                md.visibleChanged.connect(function () {
                    if (!md.visible) {
                        oldDialog.destroy();
                        insertSnippet();
                    }
                });
            }
        });
        dialog.show();
        dialog.raise();
        dialog.requestActivate();
    }

    function manageSnippets(initialTab, initialSnippet) {
        var component = Qt.createComponent(Qt.resolvedUrl("ManageSnippetsDialog.qml"));
        if (component.status !== Component.Ready) {
            script.log("snippets: failed to load dialog — " + component.errorString());
            return;
        }
        var extra = (extraSnippetsFile || "").trim();
        var dialog = component.createObject(null, {
            "primarySnippets": loadSnippetsFromFile(snippetsFilePath()),
            "extraSnippets": extra ? loadSnippetsFromFile(extra) : [],
            "extraLabel": extra ? extra.split("/").pop() : "",
            "initialTab": initialTab || 0,
            "initialSnippet": (initialSnippet !== undefined && initialSnippet >= 0) ? initialSnippet : -1
        });
        if (!dialog) {
            script.log("snippets: failed to instantiate dialog");
            return;
        }
        dialog.snippetsSaved.connect(function (updated, fileIndex) {
            if (fileIndex === 0) {
                saveSnippets(updated);
            } else {
                if (!script.writeToFile(extra, JSON.stringify(updated, null, 2)))
                    script.informationMessageBox("Could not write to:\n" + extra + "\n\nCheck that the file is writable.", "Snippets — save failed");
            }
        });
        dialog.show();
        return dialog;
    }
}
