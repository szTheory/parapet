defmodule DemoAppWeb.Parapet.GalleryLive do
  @moduledoc false
  use DemoAppWeb, :live_view

  import DemoAppWeb.Parapet.OperatorComponents

  # Hardcoded fixture data only — NO Repo/Ecto calls (T-44-07 mitigated).
  # This is a demo-only stress route for manual and screenshot audits.

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:components, gallery_components())
     |> assign(:fixture_detail, fixture_detail())
     |> assign(:fixture_detail_resolved, fixture_detail_resolved())
     |> assign(:fixture_action_items, fixture_action_items())
     |> assign(:fixture_journeys, fixture_journeys())
     |> assign(:fixture_entries, fixture_suspect_entries())
     |> assign(:fixture_queue_page, fixture_queue_page())
     |> assign(:fixture_incidents, fixture_incidents())}
  end

  def render(assigns) do
    ~H"""
    <.operator_theme_bootstrap />
    <div class="parapet-ui">
      <div style="padding: 1.5rem; max-width: 80rem; margin: 0 auto;">
        <h1 style="font-size: 1.5rem; font-weight: 700; margin-bottom: 0.5rem;">Parapet Operator UI Gallery</h1>
        <p style="font-size: 0.875rem; margin-bottom: 2rem; opacity: 0.7;">
          All 19 operator components across light/dark and default/empty/overflow/disabled/long-string states.
          Demo-only route — never shipped to host.
        </p>

        <%!-- ── 1. operator_theme_bootstrap ────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">1. operator_theme_bootstrap</h2>
          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light (default — active on this page). Dark wrapper below for visual diff.</p>
          <div data-parapet-theme="dark" style="padding: 1rem; border-radius: 0.5rem; border: 1px dashed #666;">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">dark variant context</p>
            <.operator_theme_bootstrap />
          </div>
        </section>

        <%!-- ── 2. operator_nav ──────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">2. operator_nav</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default (active=:response)</p>
          <.operator_nav active={:response} operator_base_path="/parapet/_gallery" />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1rem 0 0.5rem;">light-default (active=:actions)</p>
          <.operator_nav active={:actions} operator_base_path="/parapet/_gallery" />

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">dark-default (active=:history)</p>
            <.operator_nav active={:history} operator_base_path="/parapet/_gallery" />
          </div>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1rem 0 0.5rem;">light-overflow (very long base path)</p>
          <.operator_nav active={:response} operator_base_path="/parapet/a-very-long-operator-base-path-for-overflow-test" />
        </section>

        <%!-- ── 3. theme_control ───────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">3. theme_control</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default</p>
          <.theme_control />

          <div data-parapet-theme="dark" style="padding: 0.75rem; border-radius: 0.5rem; border: 1px dashed #666; margin-top: 1rem; display: inline-block;">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">dark-default</p>
            <.theme_control />
          </div>
        </section>

        <%!-- ── 4. response_cockpit ──────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">4. response_cockpit</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default (with active incident)</p>
          <.response_cockpit
            detail={@fixture_detail}
            visible_incidents={@fixture_incidents}
            action_items={@fixture_action_items}
            journeys={@fixture_journeys}
          />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty (no active incident)</p>
          <.response_cockpit
            visible_incidents={[]}
            action_items={[]}
            journeys={@fixture_journeys}
          />

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <.response_cockpit
              detail={@fixture_detail}
              visible_incidents={@fixture_incidents}
              action_items={@fixture_action_items}
              journeys={@fixture_journeys}
            />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-empty</p>
            <.response_cockpit
              visible_incidents={[]}
              action_items={[]}
              journeys={@fixture_journeys}
            />
          </div>
        </section>

        <%!-- ── 5. nav_item ────────────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">5. nav_item</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default (inactive)</p>
          <nav style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
            <.nav_item href="/parapet/_gallery">Inactive Nav Item</.nav_item>
            <.nav_item href="/parapet/_gallery" active={true}>Active Nav Item</.nav_item>
          </nav>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1rem 0 0.5rem;">light-overflow (long label)</p>
          <nav style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
            <.nav_item href="/parapet/_gallery">A Very Long Navigation Label That Tests Overflow</.nav_item>
          </nav>

          <div data-parapet-theme="dark" style="padding: 0.75rem; border-radius: 0.5rem; border: 1px dashed #666; margin-top: 1rem; display: inline-flex; gap: 0.5rem;">
            <.nav_item href="/parapet/_gallery">Dark Inactive</.nav_item>
            <.nav_item href="/parapet/_gallery" active={true}>Dark Active</.nav_item>
          </div>
        </section>

        <%!-- ── 6. operator_overview ───────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">6. operator_overview</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default</p>
          <.operator_overview
            queue_page={@fixture_queue_page}
            visible_incidents={@fixture_incidents}
            action_items={@fixture_action_items}
            journeys={@fixture_journeys}
            page_mode={:response}
          />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty</p>
          <.operator_overview
            queue_page={empty_queue_page()}
            visible_incidents={[]}
            action_items={[]}
            journeys={[]}
            page_mode={:response}
          />

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <.operator_overview
              queue_page={@fixture_queue_page}
              visible_incidents={@fixture_incidents}
              action_items={@fixture_action_items}
              journeys={@fixture_journeys}
              page_mode={:response}
            />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-empty</p>
            <.operator_overview
              queue_page={empty_queue_page()}
              visible_incidents={[]}
              action_items={[]}
              journeys={[]}
              page_mode={:history}
            />
          </div>
        </section>

        <%!-- ── 7. action_center ───────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">7. action_center</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default</p>
          <.action_center items={@fixture_action_items} operator_base_path="/parapet/_gallery" />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty</p>
          <.action_center items={[]} operator_base_path="/parapet/_gallery" />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-disabled (completed items)</p>
          <.action_center items={fixture_completed_action_items()} operator_base_path="/parapet/_gallery" />

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <.action_center items={@fixture_action_items} operator_base_path="/parapet/_gallery" />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-empty</p>
            <.action_center items={[]} operator_base_path="/parapet/_gallery" />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-disabled</p>
            <.action_center items={fixture_completed_action_items()} operator_base_path="/parapet/_gallery" />
          </div>
        </section>

        <%!-- ── 8. incident_list ───────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">8. incident_list</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default</p>
          <div class="rounded-xl bg-white ring-1 ring-stone-900/5 shadow-sm overflow-hidden">
            <.incident_list
              incidents={@fixture_incidents}
              selected={hd(@fixture_incidents)}
              queue_params={%{"status" => "active"}}
              page_mode={:response}
              operator_base_path="/parapet/_gallery"
            />
          </div>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty</p>
          <div class="rounded-xl bg-white ring-1 ring-stone-900/5 shadow-sm overflow-hidden">
            <.incident_list
              incidents={[]}
              selected={nil}
              queue_params={%{}}
              page_mode={:response}
              operator_base_path="/parapet/_gallery"
            />
          </div>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-overflow (many incidents)</p>
          <div class="rounded-xl bg-white ring-1 ring-stone-900/5 shadow-sm overflow-hidden" style="max-height: 14rem; overflow-y: auto;">
            <.incident_list
              incidents={overflow_incidents()}
              selected={nil}
              queue_params={%{}}
              page_mode={:history}
              operator_base_path="/parapet/_gallery"
            />
          </div>

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <div class="rounded-xl ring-1 ring-stone-900/5 shadow-sm overflow-hidden">
              <.incident_list
                incidents={@fixture_incidents}
                selected={hd(@fixture_incidents)}
                queue_params={%{"status" => "active"}}
                page_mode={:response}
                operator_base_path="/parapet/_gallery"
              />
            </div>

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-empty</p>
            <div class="rounded-xl ring-1 ring-stone-900/5 shadow-sm overflow-hidden">
              <.incident_list
                incidents={[]}
                selected={nil}
                queue_params={%{}}
                page_mode={:response}
                operator_base_path="/parapet/_gallery"
              />
            </div>

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-overflow</p>
            <div class="rounded-xl ring-1 ring-stone-900/5 shadow-sm overflow-hidden" style="max-height: 14rem; overflow-y: auto;">
              <.incident_list
                incidents={overflow_incidents()}
                selected={nil}
                queue_params={%{}}
                page_mode={:history}
                operator_base_path="/parapet/_gallery"
              />
            </div>
          </div>
        </section>

        <%!-- ── 9. incident_row ────────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">9. incident_row</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default (open, severity + attention chip)</p>
          <div class="divide-y divide-stone-200 rounded-xl bg-white ring-1 ring-stone-900/5 shadow-sm">
            <div class="px-4 py-3"><.incident_row incident={hd(@fixture_incidents)} /></div>
          </div>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-overflow (very long title)</p>
          <div class="divide-y divide-stone-200 rounded-xl bg-white ring-1 ring-stone-900/5 shadow-sm">
            <div class="px-4 py-3"><.incident_row incident={long_string_incident()} /></div>
          </div>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-disabled (resolved, no chips)</p>
          <div class="divide-y divide-stone-200 rounded-xl bg-white ring-1 ring-stone-900/5 shadow-sm">
            <div class="px-4 py-3"><.incident_row incident={resolved_incident()} /></div>
          </div>

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <div class="divide-y rounded-xl ring-1 ring-stone-900/5 shadow-sm">
              <div class="px-4 py-3"><.incident_row incident={hd(@fixture_incidents)} /></div>
            </div>

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-overflow</p>
            <div class="divide-y rounded-xl ring-1 ring-stone-900/5 shadow-sm">
              <div class="px-4 py-3"><.incident_row incident={long_string_incident()} /></div>
            </div>

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-disabled</p>
            <div class="divide-y rounded-xl ring-1 ring-stone-900/5 shadow-sm">
              <div class="px-4 py-3"><.incident_row incident={resolved_incident()} /></div>
            </div>
          </div>
        </section>

        <%!-- ── 10. incident_summary ──────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">10. incident_summary</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default</p>
          <.incident_summary detail={@fixture_detail} operator_base_path="/parapet/_gallery" />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty (no escalation chain)</p>
          <.incident_summary detail={fixture_detail_no_chain()} operator_base_path="/parapet/_gallery" />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-overflow (long strings)</p>
          <.incident_summary detail={fixture_detail_long_strings()} operator_base_path="/parapet/_gallery" />

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <.incident_summary detail={@fixture_detail} operator_base_path="/parapet/_gallery" />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-empty</p>
            <.incident_summary detail={fixture_detail_no_chain()} operator_base_path="/parapet/_gallery" />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-overflow</p>
            <.incident_summary detail={fixture_detail_long_strings()} operator_base_path="/parapet/_gallery" />
          </div>
        </section>

        <%!-- ── 11. incident_timeline ─────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">11. incident_timeline</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default</p>
          <.incident_timeline detail={@fixture_detail} />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty</p>
          <.incident_timeline detail={fixture_detail_put(:timeline_entries, [])} />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-overflow (many entries)</p>
          <.incident_timeline detail={fixture_detail_put(:timeline_entries, overflow_timeline_entries())} />

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <.incident_timeline detail={@fixture_detail} />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-empty</p>
            <.incident_timeline detail={fixture_detail_put(:timeline_entries, [])} />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-overflow</p>
            <.incident_timeline detail={fixture_detail_put(:timeline_entries, overflow_timeline_entries())} />
          </div>
        </section>

        <%!-- ── 12. suspect_changes_card ──────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">12. suspect_changes_card</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default</p>
          <.suspect_changes_card entries={@fixture_entries} />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty (component suppresses empty state)</p>
          <.suspect_changes_card entries={[]} />
          <p style="font-size: 0.75rem; opacity: 0.6;">(renders nothing — by design)</p>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-overflow (many entries)</p>
          <.suspect_changes_card entries={overflow_suspect_entries()} />

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <.suspect_changes_card entries={@fixture_entries} />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-overflow</p>
            <.suspect_changes_card entries={overflow_suspect_entries()} />
          </div>
        </section>

        <%!-- ── 13. retrospective_card ─────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">13. retrospective_card</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default (resolved with retrospective)</p>
          <.retrospective_card detail={@fixture_detail_resolved} />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty (open incident — no retrospective)</p>
          <.retrospective_card detail={@fixture_detail} />
          <p style="font-size: 0.75rem; opacity: 0.6;">(renders nothing — by design)</p>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-overflow (long retrospective)</p>
          <.retrospective_card detail={fixture_detail_long_retro()} />

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <.retrospective_card detail={@fixture_detail_resolved} />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-overflow</p>
            <.retrospective_card detail={fixture_detail_long_retro()} />
          </div>
        </section>

        <%!-- ── 14. runbook_card ────────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">14. runbook_card</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default (open incident with runbook steps)</p>
          <.runbook_card detail={@fixture_detail} />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty (no runbook steps)</p>
          <.runbook_card detail={fixture_detail_no_runbook_steps()} />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-overflow (many runbook steps)</p>
          <.runbook_card detail={fixture_detail_overflow_runbook()} />

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <.runbook_card detail={@fixture_detail} />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-empty</p>
            <.runbook_card detail={fixture_detail_no_runbook_steps()} />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-overflow</p>
            <.runbook_card detail={fixture_detail_overflow_runbook()} />
          </div>
        </section>

        <%!-- ── 15. preview_panel ────────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">15. preview_panel</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default (with active preview)</p>
          <div style="position: relative; min-height: 12rem;">
            <.preview_panel detail={fixture_detail_with_preview()} />
          </div>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-disabled (preview with warnings)</p>
          <div style="position: relative; min-height: 12rem;">
            <.preview_panel detail={fixture_detail_with_preview_warnings()} />
          </div>

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <div style="position: relative; min-height: 12rem;">
              <.preview_panel detail={fixture_detail_with_preview()} />
            </div>

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-disabled</p>
            <div style="position: relative; min-height: 12rem;">
              <.preview_panel detail={fixture_detail_with_preview_warnings()} />
            </div>
          </div>
        </section>

        <%!-- ── 16. action_rail ──────────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">16. action_rail</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default (open incident)</p>
          <div style="max-width: 20rem;">
            <.action_rail detail={@fixture_detail} operator_base_path="/parapet/_gallery" />
          </div>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-disabled (resolved — review mode)</p>
          <div style="max-width: 20rem;">
            <.action_rail detail={@fixture_detail_resolved} operator_base_path="/parapet/_gallery" />
          </div>

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <div style="max-width: 20rem;">
              <.action_rail detail={@fixture_detail} operator_base_path="/parapet/_gallery" />
            </div>

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-disabled</p>
            <div style="max-width: 20rem;">
              <.action_rail detail={@fixture_detail_resolved} operator_base_path="/parapet/_gallery" />
            </div>
          </div>
        </section>

        <%!-- ── 17. action_item_list ─────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">17. action_item_list</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default</p>
          <.action_item_list items={@fixture_action_items} />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty</p>
          <.action_item_list items={[]} />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-overflow (many items)</p>
          <.action_item_list items={overflow_action_items()} />

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <.action_item_list items={@fixture_action_items} />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-empty</p>
            <.action_item_list items={[]} />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-overflow</p>
            <.action_item_list items={overflow_action_items()} />
          </div>
        </section>

        <%!-- ── 18. action_item_card ──────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">18. action_item_card</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default</p>
          <div style="max-width: 24rem;"><.action_item_card item={hd(@fixture_action_items)} /></div>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty (nil title)</p>
          <div style="max-width: 24rem;"><.action_item_card item={action_item_no_title()} /></div>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-overflow (long title + external id)</p>
          <div style="max-width: 24rem;"><.action_item_card item={action_item_long_string()} /></div>

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-disabled (state=completed)</p>
          <div style="max-width: 24rem;"><.action_item_card item={hd(fixture_completed_action_items())} /></div>

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <div style="max-width: 24rem;"><.action_item_card item={hd(@fixture_action_items)} /></div>

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-empty</p>
            <div style="max-width: 24rem;"><.action_item_card item={action_item_no_title()} /></div>

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-overflow</p>
            <div style="max-width: 24rem;"><.action_item_card item={action_item_long_string()} /></div>

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-disabled</p>
            <div style="max-width: 24rem;"><.action_item_card item={hd(fixture_completed_action_items())} /></div>
          </div>
        </section>

        <%!-- ── 19. critical_journeys ─────────────────────────────────────────────── --%>
        <section style="margin-bottom: 3rem;">
          <h2 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 1rem; border-bottom: 1px solid #ccc;">19. critical_journeys</h2>

          <p style="font-size: 0.75rem; opacity: 0.6; margin-bottom: 0.5rem;">light-default (mixed statuses)</p>
          <.critical_journeys journeys={@fixture_journeys} />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-empty (no journeys)</p>
          <.critical_journeys journeys={[]} />

          <p style="font-size: 0.75rem; opacity: 0.6; margin: 1.5rem 0 0.5rem;">light-overflow (many journeys with long names)</p>
          <.critical_journeys journeys={overflow_journeys()} />

          <div data-parapet-theme="dark">
            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-default</p>
            <.critical_journeys journeys={@fixture_journeys} />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-empty</p>
            <.critical_journeys journeys={[]} />

            <p style="font-size: 0.75rem; opacity: 0.6; margin-top: 1.5rem; margin-bottom: 0.5rem;">dark-overflow</p>
            <.critical_journeys journeys={overflow_journeys()} />
          </div>
        </section>
      </div>
    </div>
    """
  end

  # ── Explicit static component list (not dynamic introspection) ──────────────

  defp gallery_components do
    [
      :operator_theme_bootstrap,
      :operator_nav,
      :theme_control,
      :response_cockpit,
      :nav_item,
      :operator_overview,
      :action_center,
      :incident_list,
      :incident_row,
      :incident_summary,
      :incident_timeline,
      :suspect_changes_card,
      :retrospective_card,
      :runbook_card,
      :preview_panel,
      :action_rail,
      :action_item_list,
      :action_item_card,
      :critical_journeys
    ]
  end

  # ── Fixture helpers — hardcoded, no Repo/Ecto (T-44-07) ─────────────────────

  # Incident row maps — match queue_row/1 shape from WorkbenchContract
  defp fixture_incidents do
    [
      %{
        id: "inc-001",
        title: "Login service spike — elevated error rate on /auth/token",
        state: "open",
        severity: "high",
        attention_chip: "Escalation pending",
        secondary_line: "Affecting ~23% of login attempts since 14:42 UTC",
        updated_at_label: "2 min ago"
      },
      %{
        id: "inc-002",
        title: "Checkout webhook delivery failures",
        state: "investigating",
        severity: "medium",
        attention_chip: nil,
        secondary_line: "Stripe callbacks timing out",
        updated_at_label: "8 min ago"
      },
      %{
        id: "inc-003",
        title: "Background job retry storm",
        state: "open",
        severity: "low",
        attention_chip: nil,
        secondary_line: nil,
        updated_at_label: "22 min ago"
      }
    ]
  end

  defp resolved_incident do
    %{
      id: "inc-resolved-01",
      title: "Signup email delivery resolved",
      state: "resolved",
      severity: nil,
      attention_chip: nil,
      secondary_line: "Postmark outage cleared at 15:10 UTC",
      updated_at_label: "1 hr ago"
    }
  end

  defp long_string_incident do
    %{
      id: "inc-long-01",
      title:
        "A Very Long Incident Title That Tests The Overflow And Text Truncation Behavior Of The Incident Row Component When The Title Exceeds The Available Width In Both Light And Dark Themes",
      state: "investigating",
      severity: "critical",
      attention_chip: "Immediate action required — SLO breach imminent within 15 minutes, multiple services affected",
      secondary_line:
        "Secondary information line that is also quite long: affecting us-east-1, eu-west-2, and ap-southeast-1 simultaneously",
      updated_at_label: "just now"
    }
  end

  # Action item maps — match action_item_card shape
  defp fixture_action_items do
    [
      %{
        id: "ai-001",
        title: "Review auth service deployment log",
        state: "pending",
        integration: "linear",
        external_id: "ENG-4421"
      },
      %{
        id: "ai-002",
        title: "Validate token endpoint metrics after rollback",
        state: "pending",
        integration: "github",
        external_id: "parapet#887"
      }
    ]
  end

  defp fixture_completed_action_items do
    [
      %{
        id: "ai-done-001",
        title: "Rollback auth service to v2.14.1",
        state: "completed",
        integration: "linear",
        external_id: "ENG-4422"
      }
    ]
  end

  defp action_item_no_title do
    %{id: "ai-notitle-01", title: nil, state: "pending", integration: "jira", external_id: "OPS-0042"}
  end

  defp action_item_long_string do
    %{
      id: "ai-long-01",
      title: "A very long action item title that tests text wrapping in the action item card component when it greatly exceeds the normal width",
      state: "pending",
      integration: "linear",
      external_id: "ENG-99999-long-external-id-overflow-test"
    }
  end

  defp fixture_journeys do
    [
      %{name: "Login", status: :healthy},
      %{name: "Signup", status: :healthy},
      %{name: "Checkout", status: :degraded},
      %{name: "Webhooks", status: :down},
      %{name: "API", status: :healthy}
    ]
  end

  defp fixture_suspect_entries do
    [
      %{
        payload: %{"flag" => "auth.rate_limit_threshold", "actor" => "deploy@ci", "scope" => :global},
        inserted_at: ~N[2026-06-24 14:30:00]
      },
      %{
        payload: %{"flag" => "auth.token_expiry_seconds", "actor" => "admin@example.com", "scope" => :production},
        inserted_at: ~N[2026-06-24 14:35:00]
      }
    ]
  end

  defp fixture_queue_page do
    %{items: fixture_incidents(), total: 3, page: 1, page_size: 30}
  end

  defp empty_queue_page do
    %{items: [], total: 0, page: 1, page_size: 30}
  end

  # Fixture detail — matches incident_detail/1 return shape from Parapet.Operator
  # Keys: incident, entries, derived, action_items, external_links, escalation_summary, timeline_entries
  defp fixture_detail do
    %{
      incident: %{
        id: "inc-001",
        title: "Login service spike — elevated error rate on /auth/token",
        state: "open",
        severity: "high",
        description: "Elevated error rates on the auth token endpoint affecting login flows.",
        inserted_at: ~N[2026-06-24 14:42:00],
        updated_at: ~N[2026-06-24 14:55:00],
        trace_id: "trace-abc123def456",
        runbook_data: %{
          "title" => "Auth Token Endpoint Recovery",
          "description" => "Steps to diagnose and recover from elevated error rates on /auth/token.",
          "steps" => fixture_runbook_raw_steps()
        }
      },
      entries: [],
      derived: %{
        impact: "Login success rate dropped to ~77% (baseline 99.8%). Existing sessions unaffected.",
        fault_plane: "auth-service",
        next_safe_action: "Review recent deployments to auth service before executing rollback.",
        runbook_title: "Auth Token Endpoint Recovery",
        runbook_description: "Steps to diagnose and recover from elevated error rates on /auth/token.",
        runbook_steps: fixture_derived_runbook_steps(),
        active_preview: nil
      },
      action_items: fixture_action_items(),
      external_links: [],
      escalation_summary: %{
        status: :pending,
        escalation_chain: [
          %{label: "On-call engineer", delay: nil, status: :notified},
          %{label: "Engineering manager", delay: "15 min", status: :pending},
          %{label: "Director of Engineering", delay: "30 min", status: :pending}
        ],
        time_until_next_escalation: 720,
        next_step: :trigger,
        system_action: :none,
        suppression: :none,
        latest_event: %{kind: "evidence", summary: "Error rate 23%", occurred_at: ~N[2026-06-24 14:52:00]}
      },
      timeline_entries: fixture_timeline_entries()
    }
  end

  defp fixture_detail_resolved do
    %{
      incident: %{
        id: "inc-resolved-01",
        title: "Signup email delivery resolved",
        state: "resolved",
        severity: nil,
        description: "Signup email delivery was delayed for ~40 minutes.",
        inserted_at: ~N[2026-06-24 14:28:00],
        updated_at: ~N[2026-06-24 15:10:00],
        trace_id: nil,
        runbook_data: %{
          "retrospective" =>
            "## Incident Retrospective\n\n### What happened\nPostmark experienced a regional outage from 14:28-15:10 UTC.\n\n### Impact\nSignup confirmation emails were delayed for ~40 minutes. All emails eventually delivered.\n\n### Resolution\nNo action required from our side — Postmark restored service."
        }
      },
      entries: [],
      derived: %{
        impact: "Signup email delivery was delayed for ~40 minutes. No data loss.",
        fault_plane: nil,
        next_safe_action: nil,
        runbook_title: nil,
        runbook_description: nil,
        runbook_steps: [],
        active_preview: nil
      },
      action_items: [],
      external_links: [],
      escalation_summary: %{
        status: :resolved,
        escalation_chain: nil,
        time_until_next_escalation: nil,
        next_step: :none,
        system_action: :none,
        suppression: :none,
        latest_event: nil
      },
      timeline_entries: fixture_timeline_entries()
    }
  end

  defp fixture_detail_no_chain do
    detail = fixture_detail()

    %{detail | escalation_summary: %{
      status: :none,
      escalation_chain: nil,
      time_until_next_escalation: nil,
      next_step: :none,
      system_action: :none,
      suppression: :none,
      latest_event: nil
    }, timeline_entries: []}
  end

  defp fixture_detail_long_strings do
    detail = fixture_detail()

    %{detail |
      incident: %{detail.incident |
        title: "A Very Long Incident Title That Tests Text Wrapping And Overflow Behavior Across All Detail Components In Both Light And Dark Themes On The Gallery Page",
        description: "A very long description field."
      },
      derived: %{detail.derived |
        impact: "A very long impact summary that describes in great detail all of the cascading effects across multiple systems. This text should wrap correctly and not cause layout overflow."
      }
    }
  end

  defp fixture_detail_put(key, value) do
    Map.put(fixture_detail(), key, value)
  end

  defp fixture_detail_no_runbook_steps do
    detail = fixture_detail()
    %{detail | derived: %{detail.derived | runbook_steps: [], runbook_title: nil, runbook_description: nil}}
  end

  defp fixture_detail_overflow_runbook do
    detail = fixture_detail()

    steps =
      for i <- 1..12 do
        %{
          id: "step-#{i}",
          label: "Step #{i}: #{Enum.at(["Verify service health", "Check error logs", "Review metrics", "Notify stakeholders", "Execute rollback", "Validate recovery"], rem(i, 6))}",
          description: "Detailed instructions for step #{i}.",
          kind: "check",
          state: Enum.at([:executable, :previewable, :executed, :guidance], rem(i, 4)),
          guidance: if(rem(i, 4) == 3, do: "Guidance text for this read-only step."),
          warning: if(rem(i, 5) == 0, do: "Warning: this action is irreversible."),
          targeting_hints: []
        }
      end

    %{detail | derived: %{detail.derived | runbook_steps: steps}}
  end

  defp fixture_detail_with_preview do
    detail = fixture_detail()

    %{detail | derived: %{detail.derived |
      active_preview: %{
        step_id: "step-rollback-01",
        preview_token: "prev_tok_abc123",
        data: %{
          "target_kind" => "FeatureFlag",
          "count" => 1,
          "warnings" => [],
          "idempotency_caveats" => "Safe to re-run. Idempotent rollback."
        }
      }
    }}
  end

  defp fixture_detail_with_preview_warnings do
    detail = fixture_detail()

    %{detail | derived: %{detail.derived |
      active_preview: %{
        step_id: "step-drain-01",
        preview_token: "prev_tok_xyz789",
        data: %{
          "target_kind" => "ServiceInstance",
          "count" => 3,
          "warnings" => [
            "This action will drain 3 service instances simultaneously.",
            "Ensure at least 2 healthy instances remain before proceeding."
          ],
          "idempotency_caveats" => nil
        }
      }
    }}
  end

  defp fixture_detail_long_retro do
    detail = fixture_detail_resolved()
    long_retro = """
    ## Incident Retrospective

    ### What happened
    An extended description of the incident root cause spanning multiple paragraphs.

    ### Timeline
    - 14:28 UTC — Postmark begins returning 503s
    - 14:30 UTC — First alert fires
    - 14:35 UTC — On-call acknowledges
    - 15:10 UTC — Postmark restored, queue drains

    ### Impact
    Approximately 847 users received signup emails with a ~42 minute delay. No emails lost.

    ### Root Cause
    Third-party dependency (Postmark) experienced a regional infrastructure incident.

    ### Prevention
    Added secondary email provider as fallback. Updated runbook with manual queue-drain steps.
    """

    incident = %{detail.incident | runbook_data: Map.put(detail.incident.runbook_data, "retrospective", long_retro)}
    %{detail | incident: incident}
  end

  defp fixture_timeline_entries do
    [
      %{
        entry: %{
          id: "te-001",
          type: "evidence",
          payload: %{"summary" => "Error rate on /auth/token reached 23% — SLO threshold breached"},
          inserted_at: ~N[2026-06-24 14:42:00]
        },
        presentation: %{
          actor_class: :system,
          style_variant: :neutral_evidence,
          system_action?: true
        }
      },
      %{
        entry: %{
          id: "te-002",
          type: "operator_action",
          payload: %{"summary" => "Acknowledged by on-call engineer"},
          inserted_at: ~N[2026-06-24 14:45:00]
        },
        presentation: %{
          actor_class: :operator,
          style_variant: :operator_action,
          system_action?: false
        }
      },
      %{
        entry: %{
          id: "te-003",
          type: "escalation",
          payload: %{"summary" => "Escalation to engineering manager triggered"},
          inserted_at: ~N[2026-06-24 15:00:00]
        },
        presentation: %{
          actor_class: :system,
          style_variant: :escalation,
          system_action?: true
        }
      }
    ]
  end

  defp fixture_runbook_raw_steps do
    [
      %{
        "id" => "step-1",
        "action" => "Verify current error rate in Grafana",
        "description" => "Check the parapet_http_request_duration_ms_bucket metric.",
        "kind" => "check"
      },
      %{
        "id" => "step-2",
        "action" => "Review recent deployments",
        "description" => "Check deployment logs for changes in the past 2 hours.",
        "kind" => "check",
        "requires_preview" => true
      },
      %{
        "id" => "step-3",
        "action" => "Roll back to previous version",
        "description" => "Execute rollback only if a recent deployment is the root cause.",
        "kind" => "mutating",
        "requires_preview" => true
      }
    ]
  end

  defp fixture_derived_runbook_steps do
    [
      %{
        id: "step-1",
        label: "Verify current error rate in Grafana",
        description: "Check the parapet_http_request_duration_ms_bucket metric.",
        kind: "check",
        state: :executed,
        guidance: nil,
        warning: nil,
        targeting_hints: []
      },
      %{
        id: "step-2",
        label: "Review recent deployments",
        description: "Check deployment logs for changes in the past 2 hours.",
        kind: "check",
        state: :previewable,
        guidance: nil,
        warning: nil,
        targeting_hints: []
      },
      %{
        id: "step-3",
        label: "Roll back to previous version",
        description: "Execute rollback only if a recent deployment is the root cause.",
        kind: "mutating",
        state: :executable,
        guidance: nil,
        warning: "This action will restart the auth service. Confirm SLO impact is acceptable.",
        targeting_hints: []
      }
    ]
  end

  # ── Overflow / stress fixtures ───────────────────────────────────────────────

  defp overflow_incidents do
    for i <- 1..15 do
      %{
        id: "inc-overflow-#{i}",
        title: "Incident #{i} — #{Enum.at(["Auth spike", "Queue backlog", "DB connection exhausted", "Cache miss storm", "Webhook timeout"], rem(i, 5))}",
        state: Enum.at(["open", "investigating", "open", "investigating"], rem(i, 4)),
        severity: Enum.at(["high", "medium", "low", nil], rem(i, 4)),
        attention_chip: if(rem(i, 5) == 0, do: "SLO breach imminent"),
        secondary_line: if(rem(i, 3) == 0, do: "Secondary detail line #{i}"),
        updated_at_label: "#{i} min ago"
      }
    end
  end

  defp overflow_suspect_entries do
    for i <- 1..8 do
      %{
        payload: %{"flag" => "feature.flag_#{i}", "actor" => "deploy@ci", "scope" => :production},
        inserted_at: ~N[2026-06-24 14:30:00]
      }
    end
  end

  defp overflow_action_items do
    for i <- 1..8 do
      %{
        id: "ai-overflow-#{i}",
        title: "Action item #{i} — review and resolve",
        state: Enum.at(["pending", "executing", "pending"], rem(i, 3)),
        integration: Enum.at(["linear", "github", "jira"], rem(i, 3)),
        external_id: "TICKET-#{1000 + i}"
      }
    end
  end

  defp overflow_journeys do
    [
      %{name: "User Authentication & Login Flow", status: :healthy},
      %{name: "New User Registration & Email Verification", status: :healthy},
      %{name: "Shopping Cart & Checkout Process", status: :degraded},
      %{name: "Payment Processing & Confirmation", status: :degraded},
      %{name: "Order Fulfillment & Shipping Notification", status: :down},
      %{name: "Customer Support Ticket Creation", status: :healthy},
      %{name: "API Rate Limiting & Authentication", status: :healthy},
      %{name: "Background Job Processing Pipeline", status: :down},
      %{name: "Real-time Event Streaming", status: :healthy},
      %{name: "Database Backup & Recovery", status: :healthy}
    ]
  end

  defp overflow_timeline_entries do
    for i <- 1..20 do
      %{
        entry: %{
          id: "te-overflow-#{i}",
          type: Enum.at(["evidence", "operator_action", "system_action", "escalation"], rem(i, 4)),
          payload: %{"summary" => "Timeline event #{i}"},
          inserted_at: ~N[2026-06-24 14:42:00]
        },
        presentation: %{
          actor_class: if(rem(i, 2) == 0, do: :system, else: :operator),
          style_variant: :neutral_evidence,
          system_action?: rem(i, 2) == 0
        }
      }
    end
  end
end
