defmodule DemoAppWeb.Parapet.OperatorComponents do
  @moduledoc false
  use DemoAppWeb, :html

  def operator_theme_bootstrap(assigns) do
    ~H"""
    <style>
      @font-face {
        font-family: "IBM Plex Sans";
        font-style: normal;
        font-weight: 400;
        font-display: swap;
        src: url("/parapet/fonts/IBMPlexSans-Regular-latin.woff2") format("woff2");
      }
      @font-face {
        font-family: "IBM Plex Sans";
        font-style: normal;
        font-weight: 500;
        font-display: swap;
        src: url("/parapet/fonts/IBMPlexSans-Medium-latin.woff2") format("woff2");
      }
      @font-face {
        font-family: "IBM Plex Sans";
        font-style: normal;
        font-weight: 600;
        font-display: swap;
        src: url("/parapet/fonts/IBMPlexSans-SemiBold-latin.woff2") format("woff2");
      }
      @font-face {
        font-family: "IBM Plex Mono";
        font-style: normal;
        font-weight: 400;
        font-display: swap;
        src: url("/parapet/fonts/IBMPlexMono-Regular-latin.woff2") format("woff2");
      }
      @font-face {
        font-family: "IBM Plex Mono";
        font-style: normal;
        font-weight: 500;
        font-display: swap;
        src: url("/parapet/fonts/IBMPlexMono-Medium-latin.woff2") format("woff2");
      }
      .parapet-ui {
        color-scheme: light;
        --parapet-bg: #F8F4EC;
        --parapet-panel: #FFFFFF;
        --parapet-panel-muted: #EAE2D4;
        --parapet-text: #101820;
        --parapet-text-muted: #2E3A42;
        --parapet-border: rgba(16,24,32,0.12);
        --parapet-border-strong: rgba(16,24,32,0.14);
        --parapet-shadow: 0 1px 2px rgba(16,24,32,0.06), 0 0 0 1px rgba(16,24,32,0.04);
        --parapet-accent: #256C82;
        --parapet-accent-strong: #1A5066;
        --parapet-accent-soft: #EFF6E8;
        --parapet-accent-text: #256C82;
        --parapet-warning-bg: #F8EFD7;
        --parapet-warning-text: #B45309;
        --parapet-info-bg: #ECEBFF;
        --parapet-info-text: #4F46A5;
        --po-link: #256C82;
        --po-link-hover: #1A5066;
        --po-focus: #256C82;
        --po-focus-offset: #ffffff;
        --po-header-bg: #FFFFFF;
        --po-header-border: rgba(16,24,32,0.12);
        --po-header-title: #101820;
        --po-header-muted: #256C82;
        --po-nav-fg: #2E3A42;
        --po-nav-hover-bg: #EAE2D4;
        --po-nav-hover-fg: #101820;
        --po-nav-active-bg: #EFF6E8;
        --po-nav-active-fg: #3F5E28;
        --po-theme-control-bg: #F8F4EC;
        --po-theme-control-border: rgba(16,24,32,0.12);
        --po-theme-control-fg: #2E3A42;
        --po-chip-neutral-bg: #ECEFF1;
        --po-chip-neutral-fg: #2E3A42;
        --po-chip-neutral-border: #CBD2D8;
        --po-chip-success-bg: #EFF6E8;
        --po-chip-success-fg: #3F5E28;
        --po-chip-success-border: #B6C99A;
        --po-chip-warning-bg: #F8EFD7;
        --po-chip-warning-fg: #92400E;
        --po-chip-warning-border: #E3B66E;
        --po-chip-danger-bg: #FCE8E2;
        --po-chip-danger-fg: #9F2D2D;
        --po-chip-danger-border: #E3A19A;
        --po-chip-info-bg: #ECEBFF;
        --po-chip-info-fg: #4F46A5;
        --po-chip-info-border: #B9B5F6;
        --po-button-warning-bg: #B45309;
        --po-button-warning-fg: #ffffff;
        --po-button-warning-hover: #92400E;
        --po-button-primary-bg: var(--parapet-text);
        --po-button-primary-fg: var(--parapet-panel);
        --po-button-primary-hover: var(--parapet-text-muted);
        --po-button-recovery-bg: var(--parapet-accent);
        --po-button-recovery-fg: #FFFFFF;
        --po-button-recovery-hover: var(--parapet-accent-strong);
        --po-button-destructive-bg: #B13A32;
        --po-button-destructive-fg: #FFFFFF;
        --po-button-destructive-hover: #8C2E27;
        --po-button-success-bg: #567236;
        --po-button-success-fg: #FFFFFF;
        --po-button-success-hover: #3F5E28;
        --font-sans: "IBM Plex Sans", ui-sans-serif, system-ui, sans-serif;
        --font-mono: "IBM Plex Mono", ui-monospace, monospace;
        --motion-fast: 120ms;
        --motion-base: 200ms;
        --motion-ease: cubic-bezier(.2, 0, 0, 1);
        --fs-display: 56px; --lh-display: 1.00; --fw-display: 500;
        --fs-h1: 40px; --lh-h1: 1.08; --fw-h1: 500;
        --fs-h2: 30px; --lh-h2: 1.16; --fw-h2: 500;
        --fs-h3: 22px; --lh-h3: 1.25; --fw-h3: 500;
        --fs-body: 16px; --lh-body: 1.60; --fw-body: 400;
        --fs-body-sm: 14px; --lh-body-sm: 1.50; --fw-body-sm: 400;
        --fs-caption: 12px; --lh-caption: 1.40; --fw-caption: 500;
        --fs-code: 13px; --lh-code: 1.55; --fw-code: 400;
        --fs-metric-lg: 36px; --lh-metric-lg: 1.00; --fw-metric-lg: 500;
        --fs-metric-sm: 20px; --lh-metric-sm: 1.10; --fw-metric-sm: 500;
        --space-1: 4px; --space-2: 8px; --space-3: 12px; --space-4: 16px;
        --space-5: 24px; --space-6: 32px; --space-7: 48px; --space-8: 64px;
        --radius-xs: 4px; --radius-sm: 6px; --radius-md: 10px; --radius-lg: 14px; --radius-xl: 20px;
        --radius-pill: 999px;
        --border-light: 1px solid rgba(16, 24, 32, 0.12);
        --border-dark: 1px solid rgba(248, 244, 236, 0.16);
        --shadow-card: 0 1px 2px rgba(16, 24, 32, 0.06);
        --shadow-popover: 0 12px 32px rgba(16, 24, 32, 0.16);
      }

      html[data-parapet-theme="dark"] .parapet-ui,
      html[data-parapet-theme="system"] .parapet-ui:is(.force-system-dark) {
        color-scheme: dark;
        --parapet-bg: #18232B;
        --parapet-panel: #2E3A42;
        --parapet-panel-muted: #101820;
        --parapet-text: #F8F4EC;
        --parapet-text-muted: #D8D0C3;
        --parapet-border: rgba(248,244,236,0.16);
        --parapet-border-strong: rgba(248,244,236,0.20);
        --parapet-shadow: 0 1px 2px rgba(0,0,0,0.42), 0 0 0 1px rgba(248,244,236,0.08);
        --parapet-accent: #7FB4C6;
        --parapet-accent-strong: #A8D0DE;
        --parapet-accent-soft: rgba(37,108,130,0.16);
        --parapet-accent-text: #A8D0DE;
        --parapet-warning-bg: rgba(180,83,9,0.24);
        --parapet-warning-text: #D97706;
        --parapet-info-bg: rgba(109,91,208,0.24);
        --parapet-info-text: #B9B5F6;
        --po-link: #7FB4C6;
        --po-link-hover: #A8D0DE;
        --po-focus: #F8F4EC;
        --po-focus-offset: #18232B;
        --po-header-bg: #101820;
        --po-header-border: rgba(248,244,236,0.16);
        --po-header-title: #F8F4EC;
        --po-header-muted: #7FB4C6;
        --po-nav-fg: #D8D0C3;
        --po-nav-hover-bg: #2E3A42;
        --po-nav-hover-fg: #F8F4EC;
        --po-nav-active-bg: #3F5E28;
        --po-nav-active-fg: #F8F4EC;
        --po-theme-control-bg: #18232B;
        --po-theme-control-border: rgba(248,244,236,0.16);
        --po-theme-control-fg: #D8D0C3;
        --po-chip-neutral-bg: #2E3A42;
        --po-chip-neutral-fg: #ECEFF1;
        --po-chip-neutral-border: #556B77;
        --po-chip-success-bg: #3F5E28;
        --po-chip-success-fg: #EFF6E8;
        --po-chip-success-border: #567236;
        --po-chip-warning-bg: #92400E;
        --po-chip-warning-fg: #F8EFD7;
        --po-chip-warning-border: #B45309;
        --po-chip-danger-bg: #9F2D2D;
        --po-chip-danger-fg: #FCE8E2;
        --po-chip-danger-border: #B13A32;
        --po-chip-info-bg: #4F46A5;
        --po-chip-info-fg: #ECEBFF;
        --po-chip-info-border: #6D5BD0;
        --po-button-warning-bg: #D97706;
        --po-button-warning-fg: #101820;
        --po-button-warning-hover: #B45309;
        --po-button-success-bg: #3F5E28;
        --po-button-success-fg: #EFF6E8;
        --po-button-success-hover: #567236;
      }

      @media (prefers-color-scheme: dark) {
        html:not([data-parapet-theme]),
        html[data-parapet-theme="system"] {
          color-scheme: dark;
        }

        html:not([data-parapet-theme]) .parapet-ui,
        html[data-parapet-theme="system"] .parapet-ui {
          color-scheme: dark;
          --parapet-bg: #18232B;
          --parapet-panel: #2E3A42;
          --parapet-panel-muted: #101820;
          --parapet-text: #F8F4EC;
          --parapet-text-muted: #D8D0C3;
          --parapet-border: rgba(248,244,236,0.16);
          --parapet-border-strong: rgba(248,244,236,0.20);
          --parapet-shadow: 0 1px 2px rgba(0,0,0,0.42), 0 0 0 1px rgba(248,244,236,0.08);
          --parapet-accent: #7FB4C6;
          --parapet-accent-strong: #A8D0DE;
          --parapet-accent-soft: rgba(37,108,130,0.16);
          --parapet-accent-text: #A8D0DE;
          --parapet-warning-bg: rgba(180,83,9,0.24);
          --parapet-warning-text: #D97706;
          --parapet-info-bg: rgba(109,91,208,0.24);
          --parapet-info-text: #B9B5F6;
          --po-link: #7FB4C6;
          --po-link-hover: #A8D0DE;
          --po-focus: #F8F4EC;
          --po-focus-offset: #18232B;
          --po-header-bg: #101820;
          --po-header-border: rgba(248,244,236,0.16);
          --po-header-title: #F8F4EC;
          --po-header-muted: #7FB4C6;
          --po-nav-fg: #D8D0C3;
          --po-nav-hover-bg: #2E3A42;
          --po-nav-hover-fg: #F8F4EC;
          --po-nav-active-bg: #3F5E28;
          --po-nav-active-fg: #F8F4EC;
          --po-theme-control-bg: #18232B;
          --po-theme-control-border: rgba(248,244,236,0.16);
          --po-theme-control-fg: #D8D0C3;
          --po-chip-neutral-bg: #2E3A42;
          --po-chip-neutral-fg: #ECEFF1;
          --po-chip-neutral-border: #556B77;
          --po-chip-success-bg: #3F5E28;
          --po-chip-success-fg: #EFF6E8;
          --po-chip-success-border: #567236;
          --po-chip-warning-bg: #92400E;
          --po-chip-warning-fg: #F8EFD7;
          --po-chip-warning-border: #B45309;
          --po-chip-danger-bg: #9F2D2D;
          --po-chip-danger-fg: #FCE8E2;
          --po-chip-danger-border: #B13A32;
          --po-chip-info-bg: #4F46A5;
          --po-chip-info-fg: #ECEBFF;
          --po-chip-info-border: #6D5BD0;
          --po-button-warning-bg: #D97706;
          --po-button-warning-fg: #101820;
          --po-button-warning-hover: #B45309;
          --po-button-success-bg: #3F5E28;
          --po-button-success-fg: #EFF6E8;
          --po-button-success-hover: #567236;
        }
      }

      .parapet-ui.bg-stone-100,
      .parapet-ui .bg-stone-50,
      .parapet-ui .bg-stone-50\/40,
      .parapet-ui .bg-stone-100 { background-color: var(--parapet-bg); }
      .parapet-ui .bg-white,
      .parapet-ui .bg-white\/70 { background-color: var(--parapet-panel); }
      .parapet-ui .text-stone-950,
      .parapet-ui .text-stone-900,
      .parapet-ui .text-stone-800,
      .parapet-ui .text-stone-700 { color: var(--parapet-text); }
      .parapet-ui .text-stone-600,
      .parapet-ui .text-stone-500,
      .parapet-ui .text-stone-400 { color: var(--parapet-text-muted); }
      .parapet-ui .border-stone-200,
      .parapet-ui .border-stone-300 { border-color: var(--parapet-border); }
      .parapet-ui .divide-stone-200 > :not([hidden]) ~ :not([hidden]) { border-color: var(--parapet-border); }
      .parapet-ui .ring-stone-900\/5,
      .parapet-ui .ring-stone-300,
      .parapet-ui .ring-stone-200 { --tw-ring-color: var(--parapet-border-strong); }
      .parapet-ui .shadow-sm { box-shadow: var(--parapet-shadow); }
      .parapet-ui .bg-teal-50,
      .parapet-ui .bg-teal-50\/80 { background-color: var(--parapet-accent-soft); }
      .parapet-ui .text-teal-700,
      .parapet-ui .text-teal-800,
      .parapet-ui .text-teal-950 { color: var(--parapet-accent-text); }
      .parapet-ui .bg-indigo-50,
      .parapet-ui .bg-violet-50\/50 { background-color: var(--parapet-info-bg); }
      .parapet-ui .text-indigo-700,
      .parapet-ui .text-indigo-800,
      .parapet-ui .text-indigo-900,
      .parapet-ui .text-violet-800,
      .parapet-ui .text-violet-900 { color: var(--parapet-info-text); }
      .parapet-ui .bg-amber-50,
      .parapet-ui .bg-amber-50\/60 { background-color: var(--parapet-warning-bg); }
      .parapet-ui .text-amber-700,
      .parapet-ui .text-amber-800,
      .parapet-ui .text-amber-900,
      .parapet-ui .text-amber-950 { color: var(--parapet-warning-text); }

      .parapet-ui .po-link {
        color: var(--po-link);
      }

      .parapet-ui .po-link:hover {
        color: var(--po-link-hover);
      }

      .parapet-ui .po-focus {
        --tw-ring-color: var(--po-focus);
        --tw-ring-offset-color: var(--po-focus-offset);
      }

      .parapet-ui .po-operator-header {
        border-color: var(--po-header-border);
        background: var(--po-header-bg);
        color: var(--po-header-title);
      }

      .parapet-ui .po-operator-brand {
        color: var(--po-header-muted);
      }

      .parapet-ui .po-operator-title {
        color: var(--po-header-title);
      }

      .parapet-ui .po-nav-item {
        color: var(--po-nav-fg);
      }

      .parapet-ui .po-nav-item:hover {
        background: var(--po-nav-hover-bg);
        color: var(--po-nav-hover-fg);
      }

      .parapet-ui .po-nav-active {
        background: var(--po-nav-active-bg);
        color: var(--po-nav-active-fg);
        border-bottom: 2px solid var(--parapet-accent);
      }

      .parapet-ui .po-theme-control {
        background: var(--po-theme-control-bg);
        box-shadow: inset 0 0 0 1px var(--po-theme-control-border);
      }

      .parapet-ui .po-theme-option {
        color: var(--po-theme-control-fg);
      }

      .parapet-ui .po-chip {
        border: 1px solid var(--po-chip-neutral-border);
        background: var(--po-chip-neutral-bg);
        color: var(--po-chip-neutral-fg);
      }

      .parapet-ui .po-chip-success {
        border-color: var(--po-chip-success-border);
        background: var(--po-chip-success-bg);
        color: var(--po-chip-success-fg);
      }

      .parapet-ui .po-chip-warning {
        border-color: var(--po-chip-warning-border);
        background: var(--po-chip-warning-bg);
        color: var(--po-chip-warning-fg);
      }

      .parapet-ui .po-chip-danger {
        border-color: var(--po-chip-danger-border);
        background: var(--po-chip-danger-bg);
        color: var(--po-chip-danger-fg);
      }

      .parapet-ui .po-chip-info {
        border-color: var(--po-chip-info-border);
        background: var(--po-chip-info-bg);
        color: var(--po-chip-info-fg);
      }

      .parapet-ui .po-button-warning {
        background: var(--po-button-warning-bg);
        color: var(--po-button-warning-fg);
      }

      .parapet-ui .po-button-warning:hover {
        background: var(--po-button-warning-hover);
      }

      .parapet-ui .po-button-primary {
        background: var(--po-button-primary-bg);
        color: var(--po-button-primary-fg);
      }
      .parapet-ui .po-button-primary:hover {
        background: var(--po-button-primary-hover);
      }

      .parapet-ui .po-button-recovery {
        background: var(--po-button-recovery-bg);
        color: var(--po-button-recovery-fg);
      }
      .parapet-ui .po-button-recovery:hover {
        background: var(--po-button-recovery-hover);
      }

      .parapet-ui .po-button-destructive {
        background: var(--po-button-destructive-bg);
        color: var(--po-button-destructive-fg);
      }
      .parapet-ui .po-button-destructive:hover {
        background: var(--po-button-destructive-hover);
      }

      .parapet-ui .po-button-success {
        background: var(--po-button-success-bg);
        color: var(--po-button-success-fg);
      }
      .parapet-ui .po-button-success:hover {
        background: var(--po-button-success-hover);
      }

      .parapet-ui .po-guidance {
        background: var(--parapet-info-bg);
        color: var(--parapet-info-text);
        border: 1px solid var(--parapet-border);
      }

      .parapet-ui .po-timeline-badge-operator {
        background: var(--parapet-accent);
        color: #FFFFFF;
      }

      .parapet-ui .po-timeline-badge-copilot {
        background: var(--parapet-info-text);
        color: var(--parapet-bg);
      }

      .parapet-ui .po-timeline-badge-external {
        background: var(--parapet-text-muted);
        color: var(--parapet-panel);
      }

      .parapet-ui .po-queue-row-selected {
        border-left-color: var(--parapet-accent);
        background: var(--parapet-accent-soft);
      }
      .parapet-ui .po-queue-row-selected:hover {
        background: var(--parapet-accent-soft);
      }

      /* DATA-03: Suppress connector spine on the final timeline entry */
      .parapet-ui .po-timeline-list > li:last-child > div > span[aria-hidden="true"] {
        display: none;
      }

      .parapet-theme-option[aria-pressed="true"] {
        background: var(--po-nav-active-bg);
        color: var(--po-nav-active-fg);
      }

      html[data-parapet-theme="light"] .parapet-theme-option[data-parapet-theme-value="light"],
      html[data-parapet-theme="dark"] .parapet-theme-option[data-parapet-theme-value="dark"],
      html[data-parapet-theme="system"] .parapet-theme-option[data-parapet-theme-value="system"] {
        background: var(--po-nav-active-bg);
        color: var(--po-nav-active-fg);
      }

      html[data-parapet-theme="dark"] .parapet-theme-option[aria-pressed="true"] {
        color: var(--po-nav-active-fg);
      }

      @media (prefers-reduced-motion: reduce) {
        :root {
          --motion-fast: 0ms;
          --motion-base: 0ms;
        }
        /* DATA-06: animate-pulse skeleton is zeroed here — no new motion rule needed */
        .parapet-ui * {
          animation-duration: 0.01ms !important;
          animation-iteration-count: 1 !important;
          scroll-behavior: auto;
          transition-duration: 0.01ms !important;
        }
      }
    </style>
    <script>
      (() => {
        const key = "parapet.operator.theme";
        const root = document.documentElement;
        const requested = new URLSearchParams(window.location.search).get("parapet_theme");
        const syncButtons = (value) => {
          document.querySelectorAll("[data-parapet-theme-value]").forEach((button) => {
            button.setAttribute("aria-pressed", button.dataset.parapetThemeValue === value ? "true" : "false");
          });
        };
        const apply = (theme) => {
          const value = ["light", "dark", "system"].includes(theme) ? theme : "system";
          root.dataset.parapetTheme = value;
          syncButtons(value);
          window.requestAnimationFrame(() => syncButtons(value));
        };
        if (["light", "dark", "system"].includes(requested)) {
          localStorage.setItem(key, requested);
        }
        apply(requested || localStorage.getItem(key) || "system");
        window.parapetSetTheme = (theme) => {
          localStorage.setItem(key, theme);
          apply(theme);
        };
      })();
    </script>
    """
  end

  attr(:active, :atom, required: true)
  attr(:operator_base_path, :string, default: "/parapet")

  def operator_nav(assigns) do
    ~H"""
    <header class="po-operator-header border-b">
      <div class="flex flex-col gap-3 px-4 py-3 md:flex-row md:items-center md:justify-between md:px-6">
        <div>
          <p class="po-operator-brand text-xs font-semibold uppercase tracking-[0.18em]">Parapet Operator</p>
          <h1 class="po-operator-title mt-1 text-lg font-semibold">Active response workbench</h1>
        </div>
        <nav aria-label="Parapet operator sections" class="flex flex-wrap gap-2">
          <.nav_item href={operator_path(@operator_base_path)} active={@active == :response}>Respond</.nav_item>
          <.nav_item href={operator_path(@operator_base_path, :actions)} active={@active == :actions}>Actions</.nav_item>
          <.nav_item href={operator_path(@operator_base_path, :history)} active={@active == :history}>History</.nav_item>
        </nav>
        <.theme_control />
      </div>
    </header>
    """
  end

  def theme_control(assigns) do
    ~H"""
    <div class="po-theme-control flex min-h-[40px] items-center gap-1 rounded-lg px-1 py-1" role="group" aria-label="Operator color theme">
      <button type="button" data-parapet-theme-value="light" onclick="window.parapetSetTheme && window.parapetSetTheme('light')" aria-pressed="false" class="parapet-theme-option po-theme-option po-focus flex min-h-[32px] items-center rounded-md px-2 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2">
        Light
      </button>
      <button type="button" data-parapet-theme-value="dark" onclick="window.parapetSetTheme && window.parapetSetTheme('dark')" aria-pressed="false" class="parapet-theme-option po-theme-option po-focus flex min-h-[32px] items-center rounded-md px-2 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2">
        Dark
      </button>
      <button type="button" data-parapet-theme-value="system" onclick="window.parapetSetTheme && window.parapetSetTheme('system')" aria-pressed="false" class="parapet-theme-option po-theme-option po-focus flex min-h-[32px] items-center rounded-md px-2 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2">
        System
      </button>
    </div>
    """
  end

  attr(:detail, :map, default: nil)
  attr(:visible_incidents, :list, required: true)
  attr(:action_items, :list, required: true)
  attr(:journeys, :list, required: true)

  def response_cockpit(assigns) do
    ~H"""
    <section aria-label="Active response summary" class="rounded-2xl bg-white p-5 shadow-sm ring-1 ring-stone-900/5 md:p-7">
      <div class="grid gap-6 lg:grid-cols-[minmax(0,1fr)_22rem]">
        <div class="min-w-0">
          <p class="text-sm font-semibold uppercase tracking-[0.16em] text-teal-700">Active response</p>
          <%= if @detail do %>
            <div class="mt-3 flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
              <div class="min-w-0">
                <h2 class="text-3xl font-semibold text-stone-950 text-balance"><%= @detail.incident.title %></h2>
                <p class="mt-2 max-w-3xl text-base leading-7 text-stone-600">
                  <%= @detail.derived.impact || @detail.incident.description || "No impact summary is recorded yet." %>
                </p>
              </div>
              <span class={["self-start rounded-full px-3 py-1 text-sm font-semibold", state_color(@detail.incident.state)]}>
                <%= @detail.incident.state %>
              </span>
            </div>

            <div class="mt-6 grid gap-4 md:grid-cols-3">
              <div class="rounded-xl bg-stone-50 p-4 ring-1 ring-stone-900/5">
                <p class="text-sm font-semibold text-stone-700">Latest Evidence</p>
                <p class="mt-2 text-sm leading-6 text-stone-600"><%= latest_evidence_summary(@detail) %></p>
              </div>
              <div class="rounded-xl bg-stone-50 p-4 ring-1 ring-stone-900/5">
                <p class="text-sm font-semibold text-stone-700">Next Safe Action</p>
                <p class="mt-2 text-sm leading-6 text-stone-600"><%= next_safe_action_summary(@detail) %></p>
              </div>
              <div class="rounded-xl bg-stone-50 p-4 ring-1 ring-stone-900/5">
                <p class="text-sm font-semibold text-stone-700">Pending Work</p>
                <p class="mt-2 text-sm leading-6 text-stone-600">
                  <%= Enum.count(@action_items) %> open recovery or review <%= if Enum.count(@action_items) == 1, do: "item", else: "items" %>.
                </p>
              </div>
            </div>
          <% else %>
            <h2 class="mt-3 text-3xl font-semibold text-stone-950 text-balance">No active incidents need response.</h2>
            <p class="mt-2 max-w-2xl text-base leading-7 text-stone-600">
              The active queue is empty. Use History for resolved evidence or Actions for pending recovery work.
            </p>
          <% end %>
        </div>

        <div class="rounded-xl bg-stone-50 p-4 ring-1 ring-stone-900/5">
          <p class="text-sm font-semibold text-stone-700">Critical Journeys</p>
          <div class="mt-3 flex flex-wrap gap-2">
            <%= for journey <- @journeys do %>
              <span class={chip_class(:journey, journey.status)}>
                <%= journey.name %>: <%= journey.status %>
              </span>
            <% end %>
          </div>
          <div class="mt-5 grid grid-cols-2 gap-3 border-t border-stone-200 pt-4">
            <div>
              <p class="text-2xl font-semibold tabular-nums text-stone-950"><%= Enum.count(@visible_incidents) %></p>
              <p class="text-sm text-stone-600">active incidents</p>
            </div>
            <div>
              <p class="text-2xl font-semibold tabular-nums text-stone-950"><%= Enum.count(@action_items) %></p>
              <p class="text-sm text-stone-600">pending actions</p>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr(:href, :string, required: true)
  attr(:active, :boolean, default: false)
  slot(:inner_block, required: true)

  def nav_item(assigns) do
    ~H"""
    <.link
      navigate={@href}
      aria-current={if @active, do: "page", else: nil}
      class={[
        "po-focus flex min-h-[40px] items-center rounded-lg px-3 py-2 text-sm font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2",
        if(@active, do: "po-nav-active", else: "po-nav-item")
      ]}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  attr(:queue_page, :map, required: true)
  attr(:visible_incidents, :list, required: true)
  attr(:action_items, :list, required: true)
  attr(:journeys, :list, required: true)
  attr(:page_mode, :atom, required: true)

  def operator_overview(assigns) do
    ~H"""
    <section aria-label="Operational overview" class="grid gap-3 md:grid-cols-[1.2fr_1fr_1fr]">
      <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-stone-900/5">
        <p class="text-xs font-semibold uppercase tracking-[0.16em] text-stone-500"><%= overview_mode_label(@page_mode) %></p>
        <div class="mt-2 flex items-end justify-between gap-4">
          <div>
            <p class="text-2xl font-semibold tabular-nums text-stone-950"><%= Enum.count(@visible_incidents) %></p>
            <p class="mt-1 text-sm text-stone-600">incidents in the current queue window</p>
          </div>
          <span class="rounded-full bg-teal-50 px-3 py-1 text-xs font-semibold text-teal-800 ring-1 ring-teal-200">
            Evidence first
          </span>
        </div>
      </div>

      <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-stone-900/5">
        <p class="text-xs font-semibold uppercase tracking-[0.16em] text-stone-500">Pending actions</p>
        <p class="mt-2 text-2xl font-semibold tabular-nums text-stone-950"><%= Enum.count(@action_items) %></p>
        <p class="mt-1 text-sm text-stone-600">open recovery or review items</p>
      </div>

      <div class="rounded-xl bg-white p-4 shadow-sm ring-1 ring-stone-900/5">
        <p class="text-xs font-semibold uppercase tracking-[0.16em] text-stone-500">Critical journeys</p>
        <div class="mt-3 flex flex-wrap gap-2">
          <%= for journey <- @journeys do %>
            <span class={chip_class(:journey, journey.status)}>
              <%= journey.name %>: <%= journey.status %>
            </span>
          <% end %>
        </div>
      </div>
    </section>
    """
  end

  attr(:items, :list, required: true)
  attr(:operator_base_path, :string, default: "/parapet")

  def action_center(assigns) do
    ~H"""
    <section>
      <div class="mb-5 flex flex-col gap-2 md:flex-row md:items-end md:justify-between">
        <div>
          <p class="text-xs font-semibold uppercase tracking-[0.16em] text-stone-500">Recovery work</p>
          <h2 class="mt-1 text-2xl font-semibold text-stone-950 text-balance">Pending action items</h2>
          <p class="mt-2 max-w-2xl text-sm text-stone-600">
            Items here are the operator-facing work queue behind preview and recovery flows. Review the linked incident before executing a mutating action.
          </p>
        </div>
        <.link navigate={operator_path(@operator_base_path)} class={[control_class(:primary)]}>
          Return to response
        </.link>
      </div>
      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <%= for item <- @items do %>
          <.action_item_card item={item} />
        <% end %>
        <%= if Enum.empty?(@items) do %>
          <div class="rounded-xl border border-dashed border-stone-300 bg-white/70 p-6 text-center shadow-sm">
            <svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);"
                 fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-sm font-semibold text-stone-800">No pending action items</p>
            <p class="mt-2 text-sm text-stone-500">Recovery work appears here when an incident has a concrete item to inspect or resolve.</p>
          </div>
        <% end %>
      </div>
    </section>
    """
  end

  attr(:incidents, :list, required: true)
  attr(:selected, :any, default: nil)
  attr(:queue_params, :map, default: %{})
  attr(:page_mode, :atom, default: :response)
  attr(:operator_base_path, :string, default: "/parapet")

  def incident_list(assigns) do
    ~H"""
    <div class="divide-y divide-stone-200">
      <%= for incident <- @incidents do %>
        <%= if @page_mode == :history do %>
          <.link
            navigate={incident_detail_path(@operator_base_path, incident)}
            aria-current="false"
            data-incident-id={incident.id}
            class={[
              "block border-l-4 px-4 py-3 transition-colors",
              queue_row_class(nil, incident)
            ]}
          >
            <.incident_row incident={incident} />
          </.link>
        <% else %>
          <.link
            patch={queue_item_path(@operator_base_path, @queue_params, incident)}
            aria-current={if @selected && @selected.id == incident.id, do: "true", else: "false"}
            data-incident-id={incident.id}
            class={[
              "block border-l-4 px-4 py-3 transition-colors",
              queue_row_class(@selected, incident)
            ]}
          >
            <.incident_row incident={incident} />
          </.link>
        <% end %>
      <% end %>

      <%= if Enum.empty?(@incidents) do %>
        <div class="px-4 py-8 text-center">
          <svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);"
               fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M2.25 13.5h3.86a2.25 2.25 0 012.012 1.244l.256.512a2.25 2.25 0 002.013 1.244h3.218a2.25 2.25 0 002.013-1.244l.256-.512a2.25 2.25 0 012.013-1.244h3.859m-19.5.338V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18v-4.162c0-.224-.034-.447-.1-.661L19.24 5.338a2.25 2.25 0 00-2.15-1.588H6.911a2.25 2.25 0 00-2.15 1.588L2.35 13.177a2.25 2.25 0 00-.1.661z" />
          </svg>
          <p class="text-sm font-semibold text-stone-800">No active incidents</p>
          <p class="mt-2 text-sm text-stone-500">
            Open and investigating incidents will appear here. Use History to review resolved incidents without disrupting the active queue.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:incident, :map, required: true)

  def incident_row(assigns) do
    ~H"""
    <div class="flex items-start justify-between gap-3">
      <div class="min-w-0 flex-1">
        <div class="flex flex-wrap items-center gap-2">
          <span class={chip_class(:state, @incident.state)}>
            <%= @incident.state %>
          </span>
          <%= if @incident.severity do %>
            <span class={chip_class(:severity, @incident.severity)}>
              <%= @incident.severity %>
            </span>
          <% end %>
          <%= if @incident.attention_chip do %>
            <span class="po-chip po-chip-warning rounded-full px-2.5 py-1 text-xs font-semibold">
              <%= @incident.attention_chip %>
            </span>
          <% end %>
        </div>
        <p class="mt-2 truncate text-sm font-semibold text-stone-900"><%= @incident.title %></p>
        <%= if @incident.secondary_line do %>
          <p class="mt-1 truncate text-sm text-stone-600"><%= @incident.secondary_line %></p>
        <% end %>
      </div>
      <div class="shrink-0 text-right">
        <p class="text-xs font-medium uppercase tracking-wide text-stone-500">Updated</p>
        <p class="mt-1 text-sm text-stone-700"><%= @incident.updated_at_label %></p>
      </div>
    </div>
    """
  end

  attr(:detail, :map, required: true)
  attr(:operator_base_path, :string, default: "/parapet")

  def incident_summary(assigns) do
    ~H"""
    <div class="min-w-0 overflow-hidden">
      <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div class="min-w-0">
          <h1 class="max-w-xs whitespace-normal break-words text-2xl font-bold text-stone-900 sm:max-w-none sm:text-balance"><%= @detail.incident.title %></h1>
          <p class="text-sm text-stone-500 mt-1"><span class="break-all tabular-nums font-mono"><%= @detail.incident.id %></span></p>
        </div>
        <span class={["self-start px-3 py-1 text-sm font-medium rounded-full", state_color(@detail.incident.state)]}>
          <%= @detail.incident.state %>
        </span>
      </div>
      
      <div class="bg-violet-50/50 p-4 rounded-xl mb-6 shadow-sm ring-1 ring-violet-900/5">
        <h4 class="text-sm font-medium text-violet-900 mb-2">Impact Summary</h4>
        <p class="text-sm text-violet-800">
          <%= @detail.derived.impact || "No impact summary recorded." %>
        </p>
      </div>

      <div class="shadow-sm ring-1 ring-amber-900/5 bg-amber-50 rounded-xl p-4 mb-6">
        <div class="mb-3 flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div class="min-w-0">
            <h4 class="text-sm font-semibold text-amber-950">Escalation Status</h4>
            <p class="text-sm text-amber-900 mt-1">
              <%= escalation_status_copy(@detail.escalation_summary.status) %>
            </p>
          </div>
          <span class="self-start px-2.5 py-1 text-xs font-semibold rounded-full border border-[color:var(--po-chip-warning-border)] bg-white text-amber-900">
            <%= escalation_status_badge(@detail.escalation_summary.status) %>
          </span>
        </div>

        <dl class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
          <%= if @detail.escalation_summary.escalation_chain do %>
            <div class="rounded-lg ring-1 ring-stone-900/5 shadow-sm bg-white p-3 sm:col-span-2">
              <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">Escalation Chain</dt>
              <dd class="mt-2">
                <ol class="grid grid-cols-1 gap-2 md:grid-cols-2">
                  <%= for step <- @detail.escalation_summary.escalation_chain do %>
                    <li class="flex flex-col gap-2 rounded-md border border-[color:var(--po-chip-warning-border)] bg-amber-50/60 px-3 py-2 sm:flex-row sm:items-center sm:justify-between">
                      <div class="min-w-0">
                        <p class="text-sm font-medium text-amber-950"><%= step.label %></p>
                        <%= if step.delay do %>
                          <p class="text-xs text-amber-800 mt-0.5">After <%= step.delay %></p>
                        <% end %>
                      </div>
                      <span class={["self-start px-2 py-0.5 text-xs font-semibold uppercase tracking-wide rounded-full border", escalation_chain_status_class(step.status)]}>
                        <%= escalation_chain_status_copy(step.status) %>
                      </span>
                    </li>
                  <% end %>
                </ol>
              </dd>
            </div>
          <% end %>
          <%= if @detail.escalation_summary.time_until_next_escalation do %>
            <div class="rounded-lg ring-1 ring-stone-900/5 shadow-sm bg-white p-3 sm:col-span-2">
              <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">Time Until Next Escalation</dt>
              <dd class="mt-1 break-words text-amber-950"><span class="tabular-nums font-mono"><%= countdown_copy(@detail.escalation_summary.time_until_next_escalation) %></span></dd>
            </div>
          <% end %>
          <div class="rounded-lg ring-1 ring-stone-900/5 shadow-sm bg-white p-3">
            <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">Next Step</dt>
            <dd class="mt-1 break-words text-amber-950"><%= escalation_next_step_copy(@detail.escalation_summary.next_step) %></dd>
          </div>
          <div class="rounded-lg ring-1 ring-stone-900/5 shadow-sm bg-white p-3">
            <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">System Action</dt>
            <dd class="mt-1 break-words text-amber-950"><%= system_action_copy(@detail.escalation_summary.system_action) %></dd>
          </div>
          <div class="rounded-lg ring-1 ring-stone-900/5 shadow-sm bg-white p-3">
            <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">Suppression</dt>
            <dd class="mt-1 break-words text-amber-950"><%= suppression_copy(@detail.escalation_summary.suppression) %></dd>
          </div>
          <div class="rounded-lg ring-1 ring-stone-900/5 shadow-sm bg-white p-3">
            <dt class="text-xs font-semibold uppercase tracking-wide text-amber-700">Latest Evidence</dt>
            <dd class="mt-1 break-words text-amber-950"><%= latest_event_copy(@detail.escalation_summary.latest_event) %></dd>
          </div>
        </dl>
      </div>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <div class="shadow-sm ring-1 ring-stone-900/5 bg-white rounded-xl p-4">
          <h4 class="text-sm font-medium text-stone-700 mb-2">Top Facts</h4>
          <ul class="text-sm text-stone-600 list-disc pl-5">
            <li>Created <%= readable_datetime(@detail.incident.inserted_at) %></li>
            <%= if @detail.derived.fault_plane do %>
              <li>Likely fault plane: <%= @detail.derived.fault_plane %></li>
            <% end %>
            <%= if @detail.derived.next_safe_action do %>
              <li>Next safe action: <%= @detail.derived.next_safe_action %></li>
            <% end %>
          </ul>
        </div>
        <div class="shadow-sm ring-1 ring-stone-900/5 bg-white rounded-xl p-4">
          <h4 class="text-sm font-medium text-stone-700 mb-2">Observability</h4>
          <div class="flex flex-col gap-2">
            <%= if trace_id = Map.get(@detail.incident, :trace_id) do %>
              <% template = Application.get_env(:parapet, :trace_url_template) || "#" %>
              <% url = if is_binary(template), do: String.replace(template, "{trace_id}", trace_id), else: "#" %>
              <a href={url} class="po-link flex items-center gap-1 text-sm hover:underline" target="_blank" rel="noopener noreferrer">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
                <span>Trace: <span class="tabular-nums font-mono"><%= trace_id %></span></span> &nearr;
              </a>
            <% end %>
            <%= for link <- @detail.external_links do %>
              <a href={external_link_url(link)} class="po-link flex items-center gap-1 text-sm hover:underline" target="_blank" rel="noopener noreferrer">
                <span><%= external_link_label(link) %></span> &nearr;
              </a>
            <% end %>
            <%= if Enum.empty?(@detail.external_links) && is_nil(Map.get(@detail.incident, :trace_id)) do %>
              <span class="text-sm text-stone-500">No external links attached.</span>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:detail, :map, required: true)

  def incident_timeline(assigns) do
    ~H"""
    <div class="flow-root">
      <% timeline_entries = @detail.timeline_entries || Enum.map(@detail.entries, fn entry -> %{entry: entry, presentation: %{actor_class: :evidence, style_variant: :neutral_evidence, system_action?: false}} end) %>
      <%= if Enum.empty?(timeline_entries) do %>
        <div class="flex min-h-[12rem] items-center justify-center text-center px-4 py-8">
          <div>
            <svg aria-hidden="true" class="mx-auto mb-3 h-8 w-8" style="color: var(--parapet-text-muted);"
                 fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p class="text-sm font-semibold" style="color: var(--parapet-text);">No timeline entries yet</p>
            <p class="mt-1 text-sm" style="color: var(--parapet-text-muted);">
              Evidence and operator actions will appear here as they are recorded.
            </p>
          </div>
        </div>
      <% else %>
        <ul role="list" class="po-timeline-list -mb-8">
          <%= for item <- timeline_entries do %>
            <% entry = item.entry %>
            <% presentation = item.presentation %>
            <li>
              <div class="relative pb-8">
                <span class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-stone-200" aria-hidden="true"></span>
                <div class="relative flex space-x-3">
                  <div>
                    <span class={["h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white text-white text-[11px] font-semibold", timeline_entry_badge_class(presentation)]}>
                      <%= timeline_entry_badge_text(presentation) %>
                    </span>
                  </div>
                  <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                    <div>
                      <div class="flex items-center gap-2 flex-wrap">
                        <p class="text-sm font-medium text-stone-900"><%= timeline_entry_title(entry, presentation) %></p>
                        <span class={["px-2 py-0.5 text-xs font-semibold uppercase tracking-wide rounded-full border", timeline_entry_actor_class(presentation)]}>
                          <%= timeline_actor_copy(presentation.actor_class) %>
                        </span>
                      </div>
                      <p class="text-sm text-stone-600 mt-1">
                        <%= if external_link_entry?(entry) do %>
                          <a href={external_link_url(entry.payload)} class="po-link inline-flex items-center gap-1 break-all hover:underline" target="_blank" rel="noopener noreferrer">
                            <span><%= external_link_label(entry.payload) %></span> &nearr;
                          </a>
                        <% else %>
                          <%= timeline_entry_body(entry, presentation) %>
                        <% end %>
                      </p>
                    </div>
                    <div class="whitespace-nowrap text-right text-sm text-stone-500">
                      <time datetime={exact_datetime(entry.inserted_at)} title={exact_datetime(entry.inserted_at)} class="tabular-nums"><%= readable_datetime(entry.inserted_at) %></time>
                    </div>
                  </div>
                </div>
              </div>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  attr(:entries, :list, required: true)

  def suspect_changes_card(assigns) do
    ~H"""
    <%= if not Enum.empty?(@entries) do %>
      <div class="bg-violet-50/50 ring-1 ring-violet-900/5 shadow-sm rounded-xl p-4 mb-6">
        <h3 class="text-lg font-semibold text-stone-900 mb-3">Recent System Changes (&plusmn; 60 mins)</h3>
        <div class="flex flex-col gap-3">
          <%= for entry <- @entries do %>
            <% actor = Map.get(entry.payload, "actor") || Map.get(entry.payload, :actor) || "System" %>
            <% flag = Map.get(entry.payload, "flag") || Map.get(entry.payload, :flag) %>
            <% scope = Map.get(entry.payload, "scope") || Map.get(entry.payload, :scope) %>
            <div class="flex justify-between items-start bg-white ring-1 ring-stone-900/5 rounded-lg p-3 shadow-sm">
              <div class="flex items-start gap-3">
                <div class="mt-0.5">
                  <span class="h-6 w-6 rounded-full po-chip po-chip-info flex items-center justify-center text-xs font-bold ring-2 ring-white">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z" clip-rule="evenodd" />
                    </svg>
                  </span>
                </div>
                <div>
                  <p class="text-sm font-medium text-stone-900">
                    Flag <span class="font-mono text-xs bg-stone-100 px-1 rounded border border-stone-200"><span class="tabular-nums font-mono"><%= flag %></span></span> updated
                  </p>
                  <p class="text-xs text-stone-500 mt-0.5">
                    <%= actor %> published ruleset
                  </p>
                </div>
              </div>
              <div class="flex flex-col items-end gap-1">
                <span class="po-chip po-chip-info">
                  <%= inspect(scope) %>
                </span>
                <time datetime={exact_datetime(entry.inserted_at)} title={exact_datetime(entry.inserted_at)} class="text-sm text-stone-500"><%= readable_datetime(entry.inserted_at) %></time>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  attr(:detail, :map, required: true)

  def retrospective_card(assigns) do
    retrospective =
      if assigns.detail.incident.state == "resolved" &&
           is_map(assigns.detail.incident.runbook_data) do
        Map.get(assigns.detail.incident.runbook_data, "retrospective")
      end

    assigns = assign(assigns, :retrospective, retrospective)

    ~H"""
    <%= if is_binary(@retrospective) && String.trim(@retrospective) != "" do %>
      <section class={surface_class(:compact_card)} aria-label="Incident retrospective">
        <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div class="min-w-0">
            <p class="text-xs font-semibold uppercase tracking-[0.16em] text-stone-500">History artifact</p>
            <h3 class="mt-1 text-lg font-semibold text-stone-950">Incident retrospective</h3>
            <p class="mt-2 text-sm leading-6 text-stone-600">
              Copies the Markdown retrospective for Slack, docs, or an LLM review.
            </p>
          </div>
          <button
            type="button"
            data-content={@retrospective}
            onclick="navigator.clipboard && navigator.clipboard.writeText(this.dataset.content); const label = this.querySelector('[data-copy-label]'); if (label) { const previous = label.textContent; label.textContent = 'Copied'; setTimeout(() => label.textContent = previous, 1400); }"
            class={["shrink-0", control_class(:primary)]}
          >
            <span data-copy-label>Copy retrospective</span>
          </button>
        </div>

        <div class="space-y-3 rounded-lg bg-stone-50 p-4 ring-1 ring-stone-900/5">
          <%= for block <- retrospective_blocks(@retrospective) do %>
            <%= case block do %>
              <% {:heading, text} -> %>
                <h4 class="text-base font-semibold text-stone-950"><%= text %></h4>
              <% {:paragraph, text} -> %>
                <p class="text-sm leading-6 text-stone-700"><%= text %></p>
            <% end %>
          <% end %>
        </div>
      </section>
    <% end %>
    """
  end

  attr(:detail, :map, required: true)

  def runbook_card(assigns) do
    ~H"""
    <div class={surface_class(:runbook_card)}>
      <h3 class="text-lg font-semibold text-stone-900 mb-1">
        <%= @detail.derived.runbook_title || "Runbook" %>
      </h3>
      <p class="text-sm text-stone-600 mb-4">
        <%= @detail.derived.runbook_description || "No description provided." %>
      </p>

      <div class="flex flex-col gap-3">
        <%= for step <- @detail.derived.runbook_steps do %>
          <div class="ring-1 ring-stone-900/5 bg-stone-50 rounded-lg p-3">
            <div class="flex justify-between items-start">
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <h4 class="text-sm font-medium text-stone-900"><%= step.label %></h4>
                  <%= if step.state == :executed do %>
                    <span class={chip_class(:execution, :executed)}>Executed</span>
                  <% end %>
                </div>
                <p class="text-xs text-stone-500 mt-1"><%= step.description %></p>
                
                <%= if step.state == :guidance && step.guidance do %>
                  <div class="po-guidance mt-2 p-2 rounded text-xs italic">
                    <%= step.guidance %>
                  </div>
                <% end %>

                <%= if step.warning do %>
                  <div class="mt-2 p-2 bg-amber-50 border border-[color:var(--po-chip-warning-border)] rounded text-xs text-amber-800">
                    <%= step.warning %>
                  </div>
                <% end %>

                <%= if length(step.targeting_hints) > 0 do %>
                  <div class="mt-2 flex flex-wrap gap-1">
                    <%= for hint <- step.targeting_hints do %>
                      <span class="po-chip po-chip-info text-xs font-mono" title={hint.title}>
                        <%= hint.kind %>:<span class="tabular-nums font-mono"><%= String.slice(to_string(hint.external_id), 0..7) %></span>
                      </span>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <%= if @detail.incident.state != "resolved" do %>
                <div class="ml-4">
                  <%= case step.state do %>
                    <% :previewable -> %>
                      <p class="mb-2 max-w-48 text-sm text-stone-500">Preview scoped changes before execution. No recovery action runs until confirm.</p>
                      <button phx-click="preview_mitigation" phx-value-step={step.id} phx-value-incident_id={@detail.incident.id} class={control_class(:recovery)}>
                        Preview Recovery
                      </button>
                    <% :executable -> %>
                      <p class="mb-2 max-w-48 text-sm text-stone-500">Preview scoped changes before execution. No recovery action runs until confirm.</p>
                       <button phx-click="preview_mitigation" phx-value-step={step.id} phx-value-incident_id={@detail.incident.id} class={control_class(:recovery)}>
                        Preview Recovery
                      </button>
                    <% :executed -> %>
                      <div class="text-sm text-stone-400 text-right">
                      </div>
                    <% _ -> %>
                    
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr(:detail, :map, required: true)

  def preview_panel(assigns) do
    ~H"""
    <% preview = @detail.derived.active_preview %>
    <div class="fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6">
      <div class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden">
        <div class="px-4 py-2 flex justify-between items-center" style="background: var(--parapet-accent);">
          <h3 class="text-sm font-bold text-white uppercase tracking-wider">Recovery Preview</h3>
          <button type="button" phx-click="cancel_preview" aria-label="Close Recovery Preview" class="flex min-h-[40px] min-w-[40px] items-center justify-center rounded-lg text-white hover:opacity-80 focus:outline-none focus:ring-2 focus:ring-white/80">
            <svg aria-hidden="true" xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>
        
        <div class="p-4">
          <div class="grid grid-cols-2 gap-4 mb-4">
            <div>
              <p class="text-xs text-stone-500 uppercase font-bold">Target Kind</p>
              <p class="text-sm font-medium text-stone-900"><%= preview.data["target_kind"] %></p>
            </div>
            <div>
              <p class="text-xs text-stone-500 uppercase font-bold">Affected Count</p>
              <p class="text-sm font-medium text-stone-900"><%= preview.data["count"] %></p>
            </div>
          </div>

          <%= if (preview.data["warnings"] || []) != [] do %>
            <div class="mb-4 p-2 rounded border border-[color:var(--po-chip-danger-border)] bg-[color:var(--po-chip-danger-bg)]">
              <p class="text-xs uppercase font-bold mb-1 text-[color:var(--po-chip-danger-fg)]">Warnings</p>
              <ul class="text-xs list-disc pl-4 text-[color:var(--po-chip-danger-fg)]">
                <%= for w <- preview.data["warnings"] do %>
                  <li><%= w %></li>
                <% end %>
              </ul>
            </div>
          <% end %>

          <%= if preview.data["idempotency_caveats"] do %>
            <div class="mb-4">
              <p class="text-xs text-stone-500 uppercase font-bold mb-1">Idempotency</p>
              <p class="text-xs text-stone-600"><%= preview.data["idempotency_caveats"] %></p>
            </div>
          <% end %>

          <div class="flex gap-2">
            <p class="po-guidance mb-3 rounded-lg px-3 py-2 text-xs ring-1">
              Execute bounded recovery. Writes a durable audit record with actor, reason, correlation id, and outcome.
            </p>
            <button 
              phx-click="confirm_mitigation" 
              phx-value-step={preview.step_id} 
              phx-value-incident_id={@detail.incident.id}
              phx-value-token={preview.preview_token}
              class={["flex-1", control_class(:recovery)]}
            >
              Confirm Recovery
            </button>
          </div>
          <p class="text-xs text-center text-stone-400 mt-2 italic">
            Preview is active.
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr(:detail, :map, required: true)
  attr(:operator_base_path, :string, default: "/parapet")

  def action_rail(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <%= if @detail.incident.state == "resolved" do %>
        <section class={surface_class(:action_card)} aria-label="Resolved incident status">
          <p class="text-xs font-semibold uppercase tracking-[0.16em] text-stone-500">Review mode</p>
          <h3 class="mt-1 text-lg font-semibold text-stone-950">Resolved incident</h3>
          <p class="mt-2 text-sm leading-6 text-stone-600">
            This incident is closed. History keeps the final timeline, retrospective, and audit evidence together for review.
          </p>
          <a href={operator_path(@operator_base_path, :history)} class={["mt-4", control_class(:primary)]}>
            Back to history
          </a>
        </section>
      <% else %>
        <h3 class="text-lg font-semibold text-stone-950">Operator actions</h3>
        <%= if @detail.incident.state == "open" do %>
          <div class={surface_class(:action_card)}>
            <h4 class="text-sm font-medium text-stone-900 mb-2">Acknowledge</h4>
            <p class="text-sm text-stone-500 mb-3">Take ownership of this incident. Writes a durable audit record and timeline entry.</p>
            <button phx-click="acknowledge" phx-value-id={@detail.incident.id} class={control_class(:recovery, :full)}>
              Acknowledge Incident
            </button>
          </div>
        <% end %>

        <div class={surface_class(:action_card)}>
          <h4 class="text-sm font-medium text-stone-900 mb-2">Escalation Controls</h4>
          <%= if escalation_controls_enabled?(@detail.incident) do %>
            <p class="text-sm text-stone-500 mb-3">Request the next escalation only after reviewing current status and the canonical timeline. Every request is audited.</p>
            <button phx-click="trigger_next_escalation" phx-value-id={@detail.incident.id} class={["mb-2", control_class(:warning, :full)]}>
              Trigger Next Escalation
            </button>
            <p class="text-sm text-stone-500 mb-3">Suppress pending escalation for the displayed bounded window. Every request is audited.</p>
            <button phx-click="suppress_pending_escalation" phx-value-id={@detail.incident.id} phx-value-minutes="30" class={control_class(:warning_secondary, :full)}>
              Suppress Pending Escalation
            </button>
          <% else %>
            <p class="text-sm text-stone-600">Escalation controls are available only while the incident is open.</p>
          <% end %>
        </div>

        <div class={surface_class(:action_card)}>
          <h4 class="text-sm font-medium text-stone-900 mb-2">Resolve</h4>
          <p class="text-sm text-stone-500 mb-3">Mark incident as resolved only after user impact has stopped and evidence is complete. Writes audit record.</p>
          <button phx-click="resolve" phx-value-id={@detail.incident.id} class={control_class(:success, :full)}>
            Resolve Incident
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:items, :list, required: true)

  def action_item_list(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <%= for item <- @items do %>
        <.action_item_card item={item} />
      <% end %>
      <%= if Enum.empty?(@items) do %>
        <p class="text-sm text-stone-500 italic">No action items pending.</p>
      <% end %>
    </div>
    """
  end

  attr(:item, :map, required: true)

  def action_item_card(assigns) do
    resolver = Application.get_env(:parapet, :scoria)[:ui_url_resolver]

    url =
      case resolver do
        {mod, fun, args} -> apply(mod, fun, args ++ [assigns.item.external_id])
        _ -> nil
      end

    assigns = assign(assigns, :url, url)

    ~H"""
    <div class={surface_class(:action_card)}>
      <div class="flex justify-between items-start mb-2">
        <h4 class="text-sm font-medium text-stone-900"><%= @item.title || "Action Item" %></h4>
        <span class={["rounded-full px-2.5 py-1 text-xs font-semibold", state_color(@item.state)]}>
          <%= @item.state %>
        </span>
      </div>
      <p class="text-xs text-stone-500 mb-3"><%= @item.integration %>:<%= @item.external_id %></p>
      <p class="mb-3 rounded-lg bg-stone-50 px-3 py-2 text-xs text-stone-600 ring-1 ring-stone-900/5">
        Review the linked incident evidence before recovery. Capability confirms write audit records.
      </p>
      <%= if @url do %>
        <a href={@url} target="_blank" rel="noopener noreferrer" class={control_class(:recovery, :full)}>
          Review in UI &nearr;
        </a>
      <% else %>
        <div class="text-xs text-stone-500 text-center py-2 border border-dashed border-stone-300 rounded">No resolver configured</div>
      <% end %>
    </div>
    """
  end

  attr(:journeys, :list, required: true)

  def critical_journeys(assigns) do
    ~H"""
    <div class={surface_class(:compact_card)}>
      <h3 class="text-sm font-semibold text-stone-700 uppercase tracking-wider mb-3">Critical Journeys</h3>
      <div class="flex flex-col gap-2">
        <%= for journey <- @journeys do %>
          <div class="flex items-center justify-between p-2 rounded-lg bg-stone-50 ring-1 ring-stone-900/5">
            <span class="text-sm font-medium text-stone-800"><%= journey.name %></span>
            <span class={chip_class(:journey, journey.status)}>
              <%= journey.status %>
            </span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp surface_class(:action_card),
    do: "rounded-xl bg-white p-4 shadow-sm ring-1 ring-stone-900/5"

  defp surface_class(:runbook_card),
    do: "mb-6 rounded-xl bg-white p-4 shadow-sm ring-1 ring-stone-900/5"

  defp surface_class(:compact_card),
    do: "mb-4 rounded-xl bg-white p-4 shadow-sm ring-1 ring-stone-900/5"

  defp control_class(kind), do: control_class(kind, nil)

  defp control_class(:primary, width),
    do: control_width(width) <> " " <> control_base() <> " po-button-primary"

  defp control_class(:destructive, width),
    do: control_width(width) <> " " <> control_base() <> " po-button-destructive"

  defp control_class(:recovery, width),
    do: control_width(width) <> " " <> control_base() <> " po-button-recovery"

  defp control_class(:warning, width),
    do: control_width(width) <> " " <> control_base() <> " po-button-warning"

  defp control_class(:warning_secondary, width),
    do:
      control_width(width) <>
        " " <>
        control_base() <>
        " bg-white text-amber-900 ring-1 ring-[color:var(--po-chip-warning-border)] hover:bg-amber-50"

  defp control_class(:success, width),
    do: control_width(width) <> " " <> control_base() <> " po-button-success"

  defp control_base do
    "flex min-h-[40px] items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition-transform duration-[--motion-fast] ease-out active:scale-[0.96] focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none"
  end

  defp control_width(:full), do: "w-full"
  defp control_width(_), do: "inline-flex"

  defp chip_class(:state, state),
    do: ["rounded-full px-2 py-1 text-xs font-semibold", state_color(state)]

  defp chip_class(:severity, severity),
    do: ["rounded-full border px-2 py-1 text-xs font-semibold", severity_color(severity)]

  defp chip_class(:journey, status),
    do: ["rounded-full px-2.5 py-1 text-xs font-semibold ring-1", journey_color(status)]

  defp chip_class(:execution, :executed),
    do:
      "po-chip po-chip-success rounded px-1.5 py-0.5 text-xs font-semibold uppercase tracking-wide"

  defp journey_color(:healthy), do: "po-chip po-chip-success"
  defp journey_color(:degraded), do: "po-chip po-chip-warning"
  defp journey_color(:down), do: "po-chip po-chip-danger"
  defp journey_color(_), do: "po-chip"

  defp overview_mode_label(:history), do: "Resolved history"
  defp overview_mode_label(:actions), do: "Action center"
  defp overview_mode_label(_), do: "Active response"

  defp operator_path(operator_base_path), do: operator_base_path

  defp operator_path(operator_base_path, :actions), do: operator_base_path <> "/actions"
  defp operator_path(operator_base_path, :history), do: operator_base_path <> "/history"

  defp queue_item_path(operator_base_path, queue_params, incident) do
    params =
      queue_params
      |> Map.merge(%{"id" => incident.id})
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" or value == "active" end)

    case params do
      [] -> operator_path(operator_base_path)
      _ -> operator_path(operator_base_path) <> "?" <> URI.encode_query(params)
    end
  end

  defp incident_detail_path(operator_base_path, incident),
    do: operator_base_path <> "/incidents/#{incident.id}"

  defp queue_row_class(selected, incident) do
    if selected && selected.id == incident.id do
      "po-queue-row-selected"
    else
      "border-l-transparent bg-stone-50/40 hover:bg-stone-100"
    end
  end

  defp state_color("open"), do: "po-chip po-chip-danger"
  defp state_color("acknowledged"), do: "po-chip po-chip-warning"
  defp state_color("investigating"), do: "po-chip po-chip-info"
  defp state_color("resolved"), do: "po-chip po-chip-success"
  defp state_color(_), do: "po-chip"

  defp severity_color("critical"), do: "po-chip po-chip-danger"
  defp severity_color("high"), do: "po-chip po-chip-danger"
  defp severity_color("medium"), do: "po-chip po-chip-warning"
  defp severity_color("low"), do: "po-chip po-chip-success"
  defp severity_color(_), do: "po-chip"

  defp latest_evidence_summary(%{timeline_entries: entries}) when is_list(entries) do
    case List.last(entries) do
      %{entry: entry, presentation: presentation} -> timeline_entry_body(entry, presentation)
      %{entry: entry} -> timeline_entry_body(entry, %{actor_class: :evidence})
      _ -> "No timeline evidence has been recorded yet."
    end
  end

  defp latest_evidence_summary(%{entries: entries}) when is_list(entries) do
    case List.last(entries) do
      nil -> "No timeline evidence has been recorded yet."
      entry -> timeline_entry_body(entry, %{actor_class: :evidence})
    end
  end

  defp latest_evidence_summary(_detail), do: "No timeline evidence has been recorded yet."

  defp next_safe_action_summary(%{derived: %{next_safe_action: action}}) when is_binary(action),
    do: action

  defp next_safe_action_summary(%{derived: %{runbook_steps: steps}}) when is_list(steps) do
    case Enum.find(steps, &(&1.state in [:previewable, :executable])) do
      %{label: label} ->
        "Review evidence, then #{String.downcase(label)} with preview/audit controls."

      _ ->
        "Continue from the latest durable evidence before taking action."
    end
  end

  defp next_safe_action_summary(_detail),
    do: "Continue from the latest durable evidence before taking action."

  defp escalation_status_copy(:suppressed),
    do: "Pending escalation is durably suppressed until the recorded window expires."

  defp escalation_status_copy(:manual_trigger_requested),
    do:
      "An operator requested the next escalation and the worker has not written the outcome yet."

  defp escalation_status_copy(:recently_executed),
    do: "The system recently executed an escalation step and recorded the result in the timeline."

  defp escalation_status_copy(:recently_short_circuited),
    do: "The latest escalation attempt was safely short-circuited and logged."

  defp escalation_status_copy(_),
    do: "No active escalation override is recorded. Continue from the latest durable evidence."

  defp escalation_status_badge(:suppressed), do: "Suppressed"
  defp escalation_status_badge(:manual_trigger_requested), do: "Requested"
  defp escalation_status_badge(:recently_executed), do: "Executed"
  defp escalation_status_badge(:recently_short_circuited), do: "Short-Circuited"
  defp escalation_status_badge(_), do: "Idle"

  defp escalation_next_step_copy(%{kind: :await_suppression_expiry, at: %DateTime{} = at}),
    do: "Wait for suppression to expire #{readable_datetime(at)}."

  defp escalation_next_step_copy(%{kind: :await_worker_execution, at: %DateTime{} = at}),
    do:
      "Await worker execution for the pending escalation request recorded #{readable_datetime(at)}."

  defp escalation_next_step_copy(%{kind: :await_next_escalation, at: %DateTime{} = at}),
    do: "Await the next scheduled escalation step #{readable_datetime(at)}."

  defp escalation_next_step_copy(%{kind: :monitor_timeline, at: %DateTime{} = at}),
    do:
      "Monitor the canonical timeline. Latest escalation evidence landed #{readable_datetime(at)}."

  defp escalation_next_step_copy(_),
    do: "Monitor the canonical timeline for the next durable escalation event."

  defp system_action_copy(%{status: :executed, at: %DateTime{} = at, mode: mode}),
    do:
      "System action executed #{readable_datetime(at)}#{if(mode, do: " via #{mode}", else: "")}."

  defp system_action_copy(%{status: :short_circuited, at: %DateTime{} = at}),
    do: "System execution was short-circuited #{readable_datetime(at)}."

  defp system_action_copy(_), do: "No recent system action is recorded."

  defp suppression_copy(%{
         active?: true,
         until: %DateTime{} = until,
         actor: actor,
         reason: reason
       }) do
    "#{actor || "Operator"} suppressed pending escalation until #{readable_datetime(until)}. #{reason || "No reason recorded."}"
  end

  defp suppression_copy(_), do: "No active suppression window is recorded."

  defp latest_event_copy(%{type: type, at: %DateTime{} = at, actor_class: actor_class}),
    do: "#{humanize_type(type)} #{readable_datetime(at)} (#{timeline_actor_copy(actor_class)})."

  defp latest_event_copy(_), do: "No escalation event has been recorded yet."

  defp countdown_copy(%{seconds: seconds, at: %DateTime{} = at})
       when is_integer(seconds) and seconds > 0 do
    "Approximately #{humanize_seconds(seconds)} until the next escalation checkpoint (#{readable_datetime(at)})."
  end

  defp countdown_copy(_), do: "No countdown is currently available from durable evidence."

  defp external_link_label(%{"label" => label, "url" => url})
       when is_binary(label) and is_binary(url), do: label

  defp external_link_label(%{label: label, url: url}) when is_binary(label) and is_binary(url),
    do: label

  defp external_link_label(%{"url" => url}) when is_binary(url), do: url
  defp external_link_label(%{url: url}) when is_binary(url), do: url
  defp external_link_label(link) when is_binary(link), do: link
  defp external_link_label(link), do: inspect(link)

  defp external_link_url(%{"url" => url}) when is_binary(url), do: url
  defp external_link_url(%{url: url}) when is_binary(url), do: url
  defp external_link_url(link) when is_binary(link), do: link
  defp external_link_url(_), do: "#"

  defp external_link_entry?(%{type: "external_link", payload: payload}) when is_map(payload),
    do: true

  defp external_link_entry?(_entry), do: false

  defp timeline_entry_badge_class(%{actor_class: :system}), do: "po-button-warning"
  defp timeline_entry_badge_class(%{actor_class: :operator}), do: "po-timeline-badge-operator"
  defp timeline_entry_badge_class(%{actor_class: :copilot}), do: "po-timeline-badge-copilot"
  defp timeline_entry_badge_class(%{actor_class: :external}), do: "po-timeline-badge-external"
  defp timeline_entry_badge_class(_), do: "bg-stone-600"

  defp timeline_entry_badge_text(%{actor_class: :system}), do: "SYS"
  defp timeline_entry_badge_text(%{actor_class: :operator}), do: "OP"
  defp timeline_entry_badge_text(%{actor_class: :copilot}), do: "AI"
  defp timeline_entry_badge_text(%{actor_class: :external}), do: "EXT"
  defp timeline_entry_badge_text(_), do: "EV"

  defp timeline_entry_actor_class(%{actor_class: :system}),
    do: "po-chip po-chip-warning"

  defp timeline_entry_actor_class(%{actor_class: :operator}),
    do: "po-chip po-chip-info"

  defp timeline_entry_actor_class(%{actor_class: :copilot}),
    do: "po-chip po-chip-info"

  defp timeline_entry_actor_class(%{actor_class: :external}),
    do: "po-chip"

  defp timeline_entry_actor_class(_), do: "po-chip"

  defp timeline_actor_copy(:system), do: "System"
  defp timeline_actor_copy(:operator), do: "Operator"
  defp timeline_actor_copy(:copilot), do: "Copilot"
  defp timeline_actor_copy(:external), do: "External"
  defp timeline_actor_copy(_), do: "Evidence"

  defp escalation_chain_status_copy(:completed), do: "Complete"
  defp escalation_chain_status_copy(:current), do: "Current"
  defp escalation_chain_status_copy(_), do: "Pending"

  defp escalation_chain_status_class(:completed),
    do: "po-chip po-chip-success"

  defp escalation_chain_status_class(:current),
    do: "po-chip po-chip-warning"

  defp escalation_chain_status_class(_),
    do: "po-chip"

  defp escalation_controls_enabled?(%{state: "open"}), do: true
  defp escalation_controls_enabled?(_incident), do: false

  defp timeline_entry_title(%{type: "mitigation_executed"}, _presentation),
    do: "Runbook mitigation executed"

  defp timeline_entry_title(%{type: "escalation_trigger_requested"}, _presentation),
    do: "Escalation requested"

  defp timeline_entry_title(%{type: "escalation_suppressed"}, _presentation),
    do: "Escalation suppressed"

  defp timeline_entry_title(%{type: "escalation_executed"}, _presentation),
    do: "Escalation executed"

  defp timeline_entry_title(%{type: "escalation_short_circuited"}, _presentation),
    do: "Escalation short-circuited"

  defp timeline_entry_title(%{type: "rulestead_flag_change"}, _presentation),
    do: "Feature flag changed"

  defp timeline_entry_title(%{type: "note"}, _presentation), do: "Operator note"

  defp timeline_entry_title(%{type: "status_change"}, _presentation),
    do: "Incident status changed"

  defp timeline_entry_title(%{type: "external_link"}, _presentation),
    do: "External evidence attached"

  defp timeline_entry_title(%{type: type}, _presentation), do: humanize_type(type)

  defp timeline_entry_body(%{type: "mitigation_executed", payload: payload}, presentation) do
    actor = payload_value(payload, "actor") || timeline_actor_copy(presentation.actor_class)
    step_id = payload_value(payload, "step_id") || "unknown-step"
    "#{actor} executed mitigation step #{step_id}."
  end

  defp timeline_entry_body(
         %{type: "escalation_trigger_requested", payload: payload},
         _presentation
       ) do
    actor = payload_value(payload, "actor") || "Operator"
    reason = payload_value(payload, "reason") || "No reason recorded."
    "#{actor} requested the next escalation. #{reason}"
  end

  defp timeline_entry_body(%{type: "escalation_suppressed", payload: payload}, _presentation) do
    actor = payload_value(payload, "actor") || "Operator"
    reason = payload_value(payload, "reason") || "No reason recorded."
    suppressed_until = payload_value(payload, "suppressed_until")
    "#{actor} suppressed pending escalation until #{suppressed_until}. #{reason}"
  end

  defp timeline_entry_body(%{type: "escalation_executed", payload: payload}, _presentation) do
    mode = payload_value(payload, "mode") || "scheduled"
    policy = payload_value(payload, "policy")
    "Escalation executed via #{mode}#{if(policy, do: " using #{policy}", else: "")}."
  end

  defp timeline_entry_body(%{type: "escalation_short_circuited", payload: payload}, _presentation) do
    reason = payload_value(payload, "reason") || "no bounded reason recorded"
    "Escalation was short-circuited because #{reason}."
  end

  defp timeline_entry_body(%{type: "rulestead_flag_change", payload: payload}, _presentation) do
    actor = payload_value(payload, "actor") || "System"
    flag = payload_value(payload, "flag") || "unknown"
    scope = payload_value(payload, "scope")
    "#{actor} changed flag #{flag}#{if(scope, do: " in scope #{inspect(scope)}", else: "")}."
  end

  defp timeline_entry_body(%{type: "note", payload: payload}, _presentation),
    do: payload_value(payload, "text") || "No note text recorded."

  defp timeline_entry_body(%{type: "status_change", payload: payload}, _presentation) do
    "Incident moved to #{payload_value(payload, "new_state") || "an updated state"}."
  end

  defp timeline_entry_body(%{type: "external_link", payload: payload}, _presentation) do
    label = external_link_label(payload)
    url = external_link_url(payload)
    "#{label}: #{url}"
  end

  defp timeline_entry_body(%{type: type}, _presentation),
    do: "#{humanize_type(type)} was recorded as durable evidence."

  defp payload_value(payload, key) when is_map(payload),
    do: Map.get(payload, key) || Map.get(payload, String.to_atom(key))

  defp payload_value(_payload, _key), do: nil

  defp humanize_type(type) when is_binary(type) do
    type
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp retrospective_blocks(markdown) when is_binary(markdown) do
    markdown
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn
      "# " <> heading -> {:heading, heading}
      "## " <> heading -> {:heading, heading}
      paragraph -> {:paragraph, paragraph}
    end)
  end

  defp retrospective_blocks(_markdown), do: []

  defp readable_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %d, %Y, %H:%M UTC")
  end

  defp readable_datetime(nil), do: "Not recorded"
  defp readable_datetime(other), do: to_string(other)

  defp exact_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp exact_datetime(other), do: to_string(other)

  defp humanize_seconds(seconds) when seconds < 60, do: "#{seconds}s"
  defp humanize_seconds(seconds) when seconds < 3_600, do: "#{div(seconds, 60)}m"
  defp humanize_seconds(seconds), do: "#{div(seconds, 3_600)}h #{div(rem(seconds, 3_600), 60)}m"
end
