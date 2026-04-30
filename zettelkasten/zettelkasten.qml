// Zettelkasten support for QOwnNotes.
//
// Two actions:
//   • Insert ZK ID   — inserts an ID built from a configurable format string
//   • Insert ZK link — filters notes by name, picks one, inserts [[filename|ID]]
//
// ID format tokens:  %Y year  %M month  %D day  %h hour  %m minute  %s second
// Example format:    id%Y%M%Dx%h%m%s  →  id20260430x143012
//
// IDs are detected via a configurable ECMAScript regex (default: \d{14}).
// The regex is tested first against the note filename, then full content —
// first match only.
//
// Link format:  [[nom_fichier_sur_disque.md|20260430143012]]
// QOwnNotes resolves the filename part as a wiki-link (Ctrl+click to open).

import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    property string idRegex
    property string idFormat

    property variant settingsVariables: [
        {
            "identifier": "idRegex",
            "name": "ID detection pattern (ECMAScript regex)",
            "description": "Pattern used to detect Zettelkasten IDs in note filenames and content.\nDefault matches 14-digit timestamps: \\d{14}",
            "type": "string",
            "default": "\\d{14}"
        },
        {
            "identifier": "idFormat",
            "name": "ID generation format",
            "description": "Format string for generating new IDs.\nTokens: %Y=year  %M=month  %D=day  %h=hour  %m=minute  %s=second\nLiteral characters are kept as-is.\n\nExamples:\n  %Y%M%D%h%m%s        →  20260430143012\n  id%Y%M%Dx%h%m%s     →  id20260430x143012\n  %Y-%M-%D            →  2026-04-30",
            "type": "string",
            "default": "%Y%M%D%h%m%s"
        }
    ]

    function init() {
        script.registerCustomAction("zkInsertId",   "Insert Zettelkasten ID",   "ZK-ID",   "", false, false, true);
        script.registerCustomAction("zkInsertLink", "Insert Zettelkasten link", "ZK-Link", "", false, false, true);
    }

    function customActionInvoked(identifier) {
        if (identifier === "zkInsertId") {
            insertZkId();
        } else if (identifier === "zkInsertLink") {
            insertZkLink();
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    function generateId() {
        var fmt = (idFormat || "").trim() || "%Y%M%D%h%m%s";
        var d = new Date();
        var p = function(n) { return n < 10 ? "0" + n : String(n); };
        return fmt
            .replace(/%Y/g, String(d.getFullYear()))
            .replace(/%M/g, p(d.getMonth() + 1))
            .replace(/%D/g, p(d.getDate()))
            .replace(/%h/g, p(d.getHours()))
            .replace(/%m/g, p(d.getMinutes()))
            .replace(/%s/g, p(d.getSeconds()));
    }

    function extractId(text) {
        try {
            var re = new RegExp(idRegex || "\\d{14}");
            var m  = text.match(re);
            return m ? m[0] : null;
        } catch (e) {
            script.log("zettelkasten: invalid ID regex — " + e);
            return null;
        }
    }

    // ── Actions ───────────────────────────────────────────────────────────────

    function insertZkId() {
        script.noteTextEditWrite(generateId());
    }

    function insertZkLink() {
        var noteIds = script.fetchNoteIdsByNoteTextPart("");
        var entries = [];

        for (var i = 0; i < noteIds.length; i++) {
            var note = script.fetchNoteById(noteIds[i]);
            if (!note || !note.fileName) continue;

            // Check filename first, then full content — first match only
            var zkId = extractId(note.fileName);
            if (!zkId) zkId = extractId(note.noteText);
            if (!zkId) continue;

            // Strip .txt extension — QOwnNotes wiki-links don't resolve it
            var linkTarget = /\.txt$/i.test(note.fileName)
                ? note.fileName.slice(0, note.fileName.length - 4)
                : note.fileName;

            entries.push({
                label:      zkId + "  —  " + note.name,
                linkTarget: linkTarget,
                zkId:       zkId
            });
        }

        if (entries.length === 0) {
            script.informationMessageBox(
                "No note with a Zettelkasten ID was found.\nPattern: " + (idRegex || "\\d{14}"),
                "Zettelkasten"
            );
            return;
        }

        // Most recent first
        entries.sort(function(a, b) {
            return b.zkId > a.zkId ? 1 : b.zkId < a.zkId ? -1 : 0;
        });

        var component = Qt.createComponent(Qt.resolvedUrl("ZkLinkDialog.qml"));
        if (component.status !== Component.Ready) {
            script.informationMessageBox(
                "Failed to load ZkLinkDialog:\n" + component.errorString(), "Zettelkasten");
            return;
        }
        var dialog = component.createObject(null, { entries: entries });
        if (!dialog) {
            script.informationMessageBox("Failed to instantiate ZkLinkDialog.", "Zettelkasten");
            return;
        }
        dialog.linkSelected.connect(function(linkTarget, zkId) {
            script.noteTextEditWrite("[[" + linkTarget + "|" + zkId + "]]");
        });
        dialog.show();
        dialog.raise();
        dialog.requestActivate();
    }
}
