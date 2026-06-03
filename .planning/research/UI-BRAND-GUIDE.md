# Parapet Operator UI - Design System & Brand Guide

## Core Philosophy
The Operator UI is built for the Solo SaaS Operator. It must be brutally clear, instantly scannable, and extremely safe to use under pressure. The design aesthetic is "Industrial Zen": clean lines, unambiguous states, zero visual clutter, and highly tactile, satisfying interactions (juiciness).

## CSS Architecture
We exclusively use **Tailwind CSS**. We avoid custom CSS files to ensure the generated UI components drop seamlessly into any host application without requiring them to modify their build pipeline.

## 1. Typography
- **Font Family**: System default sans-serif (`font-sans`).
- **Smoothing**: Always apply `antialiased` to the top-level operator wrapper.
- **Data & IDs**: Always use `tabular-nums font-mono` for incident IDs, countdowns, trace IDs, and timestamps to prevent layout shifting.
- **Headings**: Use `text-balance` for all titles and runbook names.
- **Weight**: Rely heavily on `font-medium` (500) and `font-semibold` (600) for UI density. Use `font-bold` (700) sparingly, only for critical alerts.

## 2. Surfaces & Depth
- **Borders vs. Shadows**: Replace flat `border-gray-200` on main cards with layered shadows. Use `shadow-sm ring-1 ring-stone-900/5 bg-white` for base cards.
- **Concentric Radius**: 
  - Outer cards: `rounded-xl`
  - Inner nested blocks (if padding is `p-4`): `rounded-md` or `rounded-lg`
- **Empty States**: Must be visually distinct, using `bg-stone-50/50 border border-dashed border-stone-300 rounded-xl`.

## 3. Color Scale (The "Industrial Zen" Palette)
- **Base Neutral**: Shift from `gray` to `stone` for a slightly warmer, more industrial feel.
- **Primary Brand**: `indigo` for primary actions (Preview, Execute).
- **State Colors**:
  - `open` / Critical: `rose` (not generic red).
  - `acknowledged` / Warning: `amber` (softer than bright yellow).
  - `resolved` / Success: `emerald` (more readable than bright green).
  - Info / System: `blue` or `violet`.

## 4. Motion & Micro-interactions
- **Press State (Tactile Feedback)**: Every actionable button must use `active:scale-[0.96] transition-transform duration-100 ease-out`. This gives satisfying physical feedback.
- **Transitions**: Never use `transition-all`. Use `transition-colors`, `transition-opacity`, or `transition-transform`.

## 5. Hit Areas & Affordances
- Every button must have a minimum optical hit area of 40x40px (`min-h-[40px] px-4 py-2`).
- Links must have clear hover states (`hover:underline hover:text-indigo-800`).
