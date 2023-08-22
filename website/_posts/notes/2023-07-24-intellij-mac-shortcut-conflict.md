---
layout: post
category: note
title: Intellij Mac Shortcut Conflict Resolution
note_type: Mac
---

In a recent macOS update a keyboard shortcut was introduced that conflicts with the intellij find command, `cmd` + `shift` + `f`.

To resolve this conflict you can disable the spotlight shortcut by doing the following:

1. Open `System Preferences` on your Mac.
2. Go to `Keyboard`.
3. Click on the `Keyboard Shortcuts` button.
4. Select `Services` on the left pane.
5. Expand the `Searching` section.
6. Uncheck `Spotlight`

Now, when searching for text in Intellij, you can use the `cmd` + `shift` + `f` shortcut without the spotlight search popping up.