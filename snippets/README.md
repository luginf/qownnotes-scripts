# Text Snippets

Insert reusable text snippets into your notes via a selection dialog.

## Usage

- **Scripting › Insert snippet** — choose a snippet from the list and insert it at the cursor
- **Scripting › Manage snippets** — add, edit, delete, and reorder snippets

You can also link those actions to a custom shortcut.

## Actions

One toolbar button is registered:

| Button      | Action                                                     |
| ----------- | ---------------------------------------------------------- |
| **Snippet** | choose a snippet from the list and insert it at the cursor |

## Placeholders

Placeholders are replaced at insertion time. `$CURSOR` is the exception: it is
not replaced but positions the cursor after insertion.

### Date & time

| Placeholder                 | Example output                           |
| --------------------------- | ---------------------------------------- |
| `$CURRENT_YEAR`             | `2026`                                   |
| `$CURRENT_YEAR_SHORT`       | `26`                                     |
| `$CURRENT_MONTH`            | `04`                                     |
| `$CURRENT_MONTH_NAME`       | `April` (locale système)                 |
| `$CURRENT_MONTH_NAME_SHORT` | `Apr` (locale système)                   |
| `$CURRENT_DAY`              | `29`                                     |
| `$CURRENT_DATE`             | `29` _(deprecated — use `$CURRENT_DAY`)_ |
| `$CURRENT_HOUR`             | `14`                                     |
| `$CURRENT_MINUTE`           | `07`                                     |
| `$CURRENT_SECOND`           | `03`                                     |
| `$CURRENT_SECONDS_UNIX`     | `1745920023`                             |

### Identifiants

| Placeholder | Exemple                                |
| ----------- | -------------------------------------- |
| `$UUID`     | `550e8400-e29b-41d4-a716-446655440000` |
| `$ZK_ID`    | `20260430143012` (format configurable) |

### Note context

| Placeholder      | Example output |
| ---------------- | -------------- |
| `$NOTE_TITLE`    | `My note`      |
| `$NOTE_FILENAME` | `my-note.md`   |

### Editor context

| Placeholder  | Description                                                            |
| ------------ | ---------------------------------------------------------------------- |
| `$CLIPBOARD` | Current clipboard text                                                 |
| `$SELECTION` | Currently selected text in the editor                                  |
| `$CURSOR`    | Not replaced — positions the cursor here after the snippet is inserted |

## Manage snippets keyboard shortcuts

| Shortcut | Action                                         |
| -------- | ---------------------------------------------- |
| `Ctrl+S` | Save current snippet                           |
| `Ctrl+N` | Add new snippet                                |
| `Delete` | Remove selected snippet (list must have focus) |
| `Ctrl+↑` | Move snippet up                                |
| `Ctrl+↓` | Move snippet down                              |

## Unsaved changes protection

The Manage dialog warns before discarding unsaved changes:

| Action                             | Behaviour                                          |
| ---------------------------------- | -------------------------------------------------- |
| Click another snippet (with edits) | Prompts **Discard & switch / Stay** (no auto-save) |
| Add new snippet (with edits)       | Prompts **Save / Discard / Cancel**                |
| Switch tab (with unsaved changes)  | Prompts **Save / Discard / Cancel**                |
| Close (with unsaved changes)       | Prompts **Discard / Cancel** (default: Cancel)     |

> The save-to-disk prompt also appears if the other tab has unsaved structural changes (add / remove / reorder) that were not saved before switching.

## Settings

| Setting                    | Default        | Description                                                                                             |
| -------------------------- | -------------- | ------------------------------------------------------------------------------------------------------- |
| **Zettelkasten ID format** | `%Y%M%D%h%m%s` | Format string for `$ZK_ID` (see tokens below)                                                           |
| **Extra snippets file**    | _(empty)_      | Absolute path to a second `snippets.json` to merge with the primary one (see below)                     |
| **Extra snippets first**   | _(unchecked)_  | When checked, snippets from the extra file appear before those from the primary file in the insert list |

## Zettelkasten integration

`$ZK_ID` generates a Zettelkasten ID using the format string syntax documented
below. Configure **Zettelkasten ID format** in _Settings → Scripting → Text
Snippets_ to match the token format you use for your Zettelkasten IDs.

| Token | Value          |
| ----- | -------------- |
| `%Y`  | 4-digit year   |
| `%M`  | 2-digit month  |
| `%D`  | 2-digit day    |
| `%h`  | 2-digit hour   |
| `%m`  | 2-digit minute |
| `%s`  | 2-digit second |

## Two snippet files

Set **Extra snippets file** to the absolute path of a second `snippets.json`
(e.g., the one from the installed script). Both files are merged when inserting.
By default, primary snippets appear first; enable **Extra snippets first** to
reverse the order. Snippets from the extra file show a small green dot in the
insert list.

**Manage snippets** shows a **Primary / extra-filename** tab selector at the
top of the list panel when an extra file is configured. Each tab edits its own
file independently — changes are kept in memory when switching tabs, and the
**Save** button writes only the currently visible tab to disk. Clicking
**Manage…** from the insert dialog opens directly on the tab and row of the
selected snippet.

> **Note:** all settings changes (including **Extra snippets file**) require a
> script engine reload to take effect (_Settings → Scripting → Reload scripting
> engine_).

## Exemple

```
## $CURRENT_MONTH_NAME $CURRENT_DAY, $CURRENT_YEAR

$ZK_ID

$CURSOR

#tag
```
