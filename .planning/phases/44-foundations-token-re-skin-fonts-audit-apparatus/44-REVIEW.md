---
phase: 44-foundations-token-re-skin-fonts-audit-apparatus
reviewed: 2026-06-24T18:30:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/mix/tasks/parapet.gen.ui.ex
  - examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex
  - examples/demo_app/lib/demo_app_web.ex
  - examples/demo_app/lib/demo_app_web/router.ex
  - mix.exs
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 44: Code Review Report

**Reviewed:** 2026-06-24T18:30:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the five real-code files changed in phase 44. The CSS tokens, font binaries, audit-matrix
markdown, and test re-pin values were excluded per scope. No critical/security issues were found.
Three warnings surface behavioral defects and one questionable invariant, and two info items flag
minor quality concerns.

---

## Warnings

### WR-01: `copy_fonts_to_host` runs unconditionally even on `--dry-run`

**File:** `lib/mix/tasks/parapet.gen.ui.ex:70-73`

**Issue:** `run/1` calls `super(argv)` then unconditionally calls `copy_fonts_to_host/0`. Igniter's
`do_or_dry_run` (called inside `super`) respects the `--dry-run` flag and halts file writes, but
`copy_fonts_to_host/0` executes regardless — it calls `File.mkdir_p!` and `File.cp!` outside
Igniter's transaction model. A user running `mix parapet.gen.ui --dry-run` to preview changes will
have fonts silently written to their working tree even though they asked for a no-op preview.

**Fix:** Guard the copy with the parsed `--dry-run` flag, or check `"--dry-run"` in `argv` before
calling `copy_fonts_to_host/0`:

```elixir
def run(argv) do
  super(argv)
  unless "--dry-run" in argv, do: copy_fonts_to_host()
end
```

A more robust approach uses `Igniter.Mix.Task.Info` option parsing, but the `in argv` guard is
sufficient and mirrors how Igniter itself detects the flag.

---

### WR-02: `copy_fonts_to_host` calls `File.ls!` twice — second call races with first

**File:** `lib/mix/tasks/parapet.gen.ui.ex:80,85`

**Issue:** The directory is listed twice: once to iterate filenames for copying (line 80), and again
to compute the count for the info message (line 85). Between the two calls the filesystem could
change (unlikely in practice, but a genuine TOCTOU on the count). More practically, this means
two syscalls when one suffices, and the count in the message could differ from the number of files
actually copied.

**Fix:** Capture the result of the first `File.ls!` and reuse it:

```elixir
defp copy_fonts_to_host do
  source_dir = Path.join(:code.priv_dir(:parapet), "static/parapet/fonts")
  dest_dir = Path.join(File.cwd!(), "priv/static/parapet/fonts")
  File.mkdir_p!(dest_dir)

  filenames = File.ls!(source_dir)

  for filename <- filenames do
    File.cp!(Path.join(source_dir, filename), Path.join(dest_dir, filename))
  end

  Mix.shell().info(
    "* copying #{length(filenames)} font files to priv/static/parapet/fonts/"
  )
end
```

---

### WR-03: `copy_fonts_to_host` will crash if a subdirectory appears in the fonts dir

**File:** `lib/mix/tasks/parapet.gen.ui.ex:80-82`

**Issue:** `File.ls!` returns all entries in the directory, including subdirectories. `File.cp!/2`
does not copy directories — it raises `{:error, :eisdir}` (which `File.cp!` converts to a
raised exception). The fonts directory currently contains only files, but if a `.DS_Store` directory
or any other directory entry were ever present (e.g. a future nested subset directory), the task
would crash mid-copy, leaving a partially copied destination.

**Fix:** Filter to regular files only before copying:

```elixir
filenames =
  source_dir
  |> File.ls!()
  |> Enum.filter(fn name ->
    File.regular?(Path.join(source_dir, name))
  end)
```

This also makes the "N font files" count accurate if non-file entries are present.

---

## Info

### IN-01: Redundant glob entries in `mix.exs` `package[:files]`

**File:** `mix.exs:43-44`

**Issue:** The `files` list includes both `"priv"` (which causes the entire `priv/` tree to be
packed) and the explicit globs `priv/static/parapet/fonts/*.woff2` and
`priv/static/parapet/fonts/LICENSE.txt`. The specific font entries are entirely subsumed by `"priv"`
and have no effect. This is harmless today, but it creates misleading signal — a reader might assume
`"priv"` alone is insufficient, or that removing the redundant entries would break packaging.

**Fix:** Remove the redundant specific entries and keep only `"priv"`, or replace `"priv"` with
precise globs if there are priv subdirectories you intentionally want to exclude from the package:

```elixir
files:
  ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* CONTRIBUTING* SECURITY* LICENSE* docs),
```

---

### IN-02: `gallery_components/0` return value is assigned to socket but never read in `render/1`

**File:** `examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex:13,574-596`

**Issue:** `mount/3` assigns `:components` (the list of 19 component name atoms from
`gallery_components/0`), but `render/1` never references `@components`. The list is dead data
carried in the socket for the lifetime of every gallery page visit. It carries no runtime cost
worth flagging, but it is genuinely unused state — removing the assignment would be cleaner and
would signal clearly that the gallery is rendered from static markup, not a dynamic component loop.

**Fix:** Remove the dead assignment from `mount/3`:

```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   # remove: |> assign(:components, gallery_components())
   |> assign(:fixture_detail, fixture_detail())
   # ...
  }
end
```

And remove `defp gallery_components/0` entirely, or retain it only if a future audit/test
assertion against the list is planned (document that intent with a comment if so).

---

_Reviewed: 2026-06-24T18:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
