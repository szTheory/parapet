---
status: draft
---

# UI Specification: Phase 2 - Rulestead Flag Correlation

## 1. Design System
- **Framework:** Phoenix LiveView (HEEx templates)
- **Styling:** Tailwind CSS (Host application defaults)
- **shadcn:** None (N/A for Elixir host-injected UI)
- **Safety Gate:** N/A (No external JS dependencies or registries)

## 2. Spacing & Layout
- **Scale:** 8-point scale (4, 8, 16, 24, 32)
- **Tokens:** `p-4` (16px), `gap-4` (16px), `mb-6` (24px), `py-2` (8px), `px-4` (16px), `mb-2` (8px).
- **Layout:** Standard flexbox layouts consistent with existing operator components. Hero cards placed before or alongside the summary card.

## 3. Typography
- **Sizes:**
  - `text-xs` (12px) - Scopes, timestamps, labels.
  - `text-sm` (14px) - Body, descriptions, action items.
  - `text-lg` (18px) - Card Headings.
  - `text-2xl` (24px) - Page Titles.
- **Weights (Strictly 2):**
  - Regular (`font-normal`) - Body text, descriptions, labels.
  - Medium (`font-medium`) - Headings, buttons, emphasized elements.
- **Line Height:** Tailwind default (1.5 for body, 1.2 for headings).

## 4. Color Palette (60/30/10 Split)
- **60% (Base/Surface):** `bg-white`, `bg-gray-50`. Borders `border-gray-200`. Base text `text-gray-900`.
- **30% (Secondary/Accent):** `bg-blue-50`, `text-blue-900`, `border-blue-200` to indicate recent changes as informational but important. Secondary text `text-gray-500`.
- **10% (Focal Point/Highlight):** `bg-purple-100` / `text-purple-800` or `ring-purple-200 bg-purple-500` for the distinct timeline node points to differentiate feature flag changes from standard SRE events.

## 5. Copywriting & Content
- **Suspect Changes Card:**
  - **Title:** "Recent System Changes (± 60 mins)"
  - **Item Format:** "Flag `{flag_name}` updated ({scope})"
  - **Empty State:** If no changes are found within the window, the card is completely omitted to avoid noise.
  - **Error State:** If system events fail to load, display: "Unable to load recent system changes. [Retry loading]"
- **Inline Timeline Markers:**
  - **Action Copy:** "{Actor} published ruleset for {flag_name}"
  - **Scope Display:** Explicitly show the scope payload (e.g. `tenant:acme` or `10% rollout`).

## 6. Components & Interactions

**Visual Focal Point:** The primary visual focal point of the page is the **Suspect Changes Card**. It should draw the user's eye immediately upon page load by being placed prominently above the impact summary, using the 30% accent color background (`bg-blue-50`).

### Component 1: `suspect_changes_card`
- **Location:** Added to `Parapet.OperatorComponents` and rendered in `operator_detail_live.ex` above the impact summary or runbook card.
- **Visuals:** 
  - Container: `bg-white border border-gray-200 rounded-md p-4 mb-6`
  - Title: `text-lg font-semibold text-gray-900 mb-3`
  - List Items: Flex row with icon, text, and timestamp.
  - Badge: Scope badge (e.g., `px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800`).
- **Interaction:** Read-only list.

### Component 2: `incident_timeline` (Update)
- **Location:** Update existing `incident_timeline` function in `Parapet.OperatorComponents`.
- **Visuals:**
  - Provide a distinct icon or colored ring for the timeline node when `entry.type` is a system event / flag change (e.g., `<span class="h-8 w-8 rounded-full bg-purple-500 flex items-center justify-center ring-8 ring-white">`).
- **Interaction:** Chronological read-only integration.

## 7. Pre-Populated From
| Source | Decisions Used |
|--------|---------------|
| CONTEXT.md | 0 |
| RESEARCH.md | 3 (Hero Card wording, inline timeline markers, ignoring eval telemetry) |
| components.json | N/A |
| User input | 0 |
