# Design Fork: SLO-W1 (Wizard) and SLO-B1 (Bundles) for v1.0

**Researched:** 2026-05-25
**Question:** Should `mix parapet.gen.slo` (interactive wizard) and/or cross-integration SLO slice bundles ship in v1.0? If so, what is the idiomatic design? If not, why is deferral safe?
**Overall confidence:** HIGH (ecosystem patterns are well-established; Parapet's codebase is fully read)

---

## 1. Decision Question

v1.0 is Parapet's stability freeze: anything on the public surface after this release is subject to semver forever. The maintainer has parked two SLO-authoring features for consideration:

- **SLO-W1** — an interactive `mix parapet.gen.slo` wizard that guides adopters through defining a custom SLO slice without reading the authoring guide first.
- **SLO-B1** — cross-integration SLO slice bundles that compose multiple provider slices into a single named grouping (e.g., a "payment reliability bundle" combining HTTP + Oban + Mailglass slices).

The question is: which of these, if any, belongs in v1.0's frozen public surface — and if they ship, what is the idiomatic design?

---

## 2. Options Considered

### SLO-W1: Interactive `mix parapet.gen.slo` Wizard

#### Description
A Mix task that prompts the adopter step-by-step for: slice name, integration, kind (ratio/freshness/diagnostic), good metric + matchers, total metric + matchers, objective percentage, alert class, and runbook URL. The task then renders a host-owned provider module the adopter can commit and modify.

#### Concrete sketch

```
$ mix parapet.gen.slo

? Slice name (atom): checkout_completion
? Integration tag (atom): checkout
? Kind: ratio / freshness / diagnostic: ratio
? Good metric (Prometheus series name): parapet_checkout_completed_total
? Good matchers (key=val, comma-separated): status=ok
? Total metric: parapet_checkout_started_total
? Total matchers: (leave blank for none)
? Objective (e.g. 99.5): 99.5
? Alert class: page / ticket / warning: page
? Runbook URL: https://example.com/runbooks/checkout

Writing lib/my_app/slo/checkout_completion.ex ...
Done. Register: config :parapet, providers: [MyApp.SLO.CheckoutCompletion]
Then run: mix parapet.gen.prometheus
```

The generated file is a standard `Parapet.SLO.Provider` module with a `slos/0` returning a `SliceSpec`. The file is fully inspectable, host-owned, and modifiable.

#### Pros
- Lower barrier for adopters who have not internalized the SliceSpec API.
- Reinforces the "you never write raw PromQL" message at the task level.
- Consistent with Parapet's existing Igniter-based install story.

#### Cons — and they are significant

**Igniter does not support interactive prompts.** Igniter's `Igniter.Mix.Task` is a diff-accumulation and file-patching framework. It shows a unified diff of planned changes, asks "apply?", and writes. It does not provide select menus, text-input prompts, or step-by-step question flows. Building an interactive wizard requires falling outside the Igniter model entirely — using `Mix.Shell.IO.prompt/1` and `Mix.Shell.IO.yes?/1` in a plain `Mix.Task`, bypassing Igniter's idempotency and dry-run guarantees.

**Two-surface problem.** If the wizard runs as a plain `Mix.Task` (not Igniter), it cannot be composed into `mix parapet.install` safely, cannot be dry-run with `--dry-run`, and cannot be previewed before application. That breaks the consistency of Parapet's install DX, which is Igniter-first throughout (`parapet.install`, `parapet.gen.spine`, `parapet.gen.prometheus`, `parapet.gen.ui`).

**The generated file is not meaningfully shorter than reading the docs.** A `SliceSpec.new(...)` call with seven or eight fields is ~15 lines of Elixir. The authoring guide already provides copy-paste templates. An adopter who follows the wizard and then reads the generated file will spend roughly the same time as an adopter who reads the guide first. The wizard adds ceremony without adding clarity.

**Wizard divergence from the real SliceSpec surface is a freeze risk.** If the wizard asks "good metric?" and "total metric?" but the SliceSpec later gains `:freshness_window` or `:synthetic_probe`, the wizard is stale. Since v1.0 freezes the public surface, the wizard's question set becomes a second thing to version and maintain.

**Phoenix and Ash generators are instructive here.** `mix phx.gen.context` and `mix phx.gen.auth` use `Mix.shell().yes?()` only for conflict resolution, not for primary input. All primary choices go through CLI flags (`--live`, `--merge-with-existing-context`). Ash's generators (backed by Igniter) are fully flag-based. The Elixir ecosystem consensus is: interactive prompts for conflict resolution or dangerous-operation confirmation; flags for intent. A wizard that drives primary feature choices through interactive prompts is not idiomatic.

**Oban's installer lesson.** Oban's Igniter-backed `mix oban.install` deduces the database engine and notifier automatically from the project's existing deps — it does not ask. Where a choice cannot be deduced, it accepts a `--repo` flag. This is the right model: "smart defaults + flags for overrides" beats "ask the user".

**Non-idempotent edits.** Running the wizard twice with different inputs creates two provider modules with potentially conflicting slice names. Igniter-based tasks handle this via AST comparison and idempotent patching. A prompt-driven `Mix.Task` that creates new files on every run requires adopters to manually manage deduplication.

**Freeze cost.** The wizard's UX (prompt order, question wording, field set) becomes part of the frozen public surface if it ships in v1.0. Any change to which fields are asked — even adding a new SliceSpec field — is a public behavior change.

#### Tradeoffs summary
| Dimension | Cost |
|-----------|------|
| Igniter compatibility | Breaks out of Igniter's model |
| Dry-run / composability | Loses both |
| Freeze surface | Adds wizard UX to the frozen contract |
| Maintenance | Wizard question set must track SliceSpec evolution |
| Ecosystem idiom | Non-standard (prompts for primary input) |
| DX gain over docs | Marginal — adopters still read the generated file |

---

### SLO-B1: Cross-Integration SLO Slice Bundles

#### Description
A "bundle" is a named grouping that spans multiple integrations. For example, a `PaymentReliability` bundle might compose HTTP + Oban + Mailglass delivery slices, all scoped to payment flows, into a single provider registration. The bundle could add extra metadata (shared labels, a common dashboard tag) or simply be a convenience wrapper that returns multiple SliceSpecs from one provider.

#### Concrete sketch

```elixir
defmodule MyApp.SLO.PaymentReliability do
  use Parapet.SLO.Bundle,
    name: :payment_reliability,
    slices: [
      # HTTP: checkout route availability
      {Parapet.SLO.HTTP, matchers: [route: "/checkout"]},
      # Oban: payment processor jobs
      {Parapet.SLO.Oban, matchers: [queue: "payments"]},
      # Mailglass: invoice delivery
      {Parapet.SLO.MailglassDelivery, message_type: :invoice}
    ]
end
```

Or the simpler form, which is already possible without a Bundle abstraction:

```elixir
defmodule MyApp.SLO.PaymentReliability do
  @behaviour Parapet.SLO.Provider

  def slos do
    [
      SliceSpec.new(name: :checkout_http, ...),
      SliceSpec.new(name: :payment_oban_jobs, ...),
      SliceSpec.new(name: :invoice_delivery, ...)
    ]
  end
end
```

#### Is SLO-B1 meaningfully different from "more StarterPacks"?

No. The existing pattern — a `Parapet.SLO.Provider` module that returns multiple `SliceSpec` structs — already is the bundle abstraction. `Parapet.SLO.StarterPack.WebSaaS` is a bundle of three slices. `Parapet.SLO.StarterPack.DeliverySaaS` is a bundle of ten slices that conditionally composes based on loaded providers. Any adopter can write a host-owned provider module that combines slices from different integrations — and that module is immediately host-owned, inspectable, and version-controlled.

The value-add of a formal `Parapet.SLO.Bundle` behaviour or DSL would need to be:

1. **Cross-slice shared metadata** — a bundle-level label or tag propagated to all member slices. This adds real value only if Grafana dashboard generation can use it (e.g., a "payment" dashboard section that groups all payment-scoped slices). This is a dashboard-generation problem, not an SLO authoring problem.
2. **Compile-time validation across the bundle** — ensuring no slice name collisions within a bundle. But Parapet's registry already deduplicates at registration time; the Provider behaviour already validates at SliceSpec construction.
3. **Convention for adopter-authored packs** — giving adopters a `use Parapet.SLO.Bundle` shorthand that is lighter than writing a full provider module. The DX gain is marginal because the Provider behaviour is already three lines of boilerplate.

What SLO-B1 does NOT add:
- New alerting capabilities
- New generator output (Prometheus rules are already generated per-slice regardless of bundle grouping)
- New runtime behavior (the registry iterates providers; bundle vs. non-bundle is invisible at runtime)

#### Freeze cost analysis
A `Parapet.SLO.Bundle` behaviour or DSL, once frozen in v1.0, cannot have new options added to its DSL without a major version bump. If the dashboard generator later needs per-bundle configuration (a legitimate future need), it cannot be added to the frozen Bundle API without a breaking change. The current pattern — host-owned provider modules — has no such constraint because the module is outside Parapet's API surface.

#### Tradeoffs summary
| Dimension | Assessment |
|-----------|------------|
| Functional novelty | Low — existing Provider pattern already does this |
| Freeze surface | Adds Bundle behaviour/DSL to the frozen contract |
| Dashboard integration gap | Real gap, but a dashboard-layer problem, not SLO-authoring |
| Adopter DX gain | Marginal — saves ~5 lines of boilerplate |
| Risk of premature abstraction | High — the right Bundle shape depends on dashboard needs not yet decided |

---

## 3. What's Idiomatic in Elixir/Phoenix Codegen and SLO Authoring

### Elixir/Phoenix codegen idioms

**Confirmed patterns from ecosystem research:**

1. **Igniter-first for host-modifying generators.** `mix oban.install`, `mix ash.gen.resource`, `mix parapet.install` all use Igniter's diff/patch model. Interactive prompts are absent. Choices are expressed as CLI flags with sensible defaults derived from project introspection.

2. **`Mix.shell().yes?()` is a conflict gate, not a wizard driver.** `phx.gen.context` uses `Mix.shell().yes?()` only when an existing context with the same name is found — to confirm the adopter intends to merge. It does not use prompt-based input for primary feature selection. This is the standard Elixir pattern.

3. **Flag-based primary input, prompt-based exception handling.** The ecosystem consensus: if you need user choice for primary intent, use a CLI flag. If you need user confirmation because something dangerous or surprising is about to happen, use a shell prompt. A multi-step wizard that asks for metric names, matchers, and objectives through shell prompts is an outlier in Elixir tooling.

4. **Generated code must be host-owned and readable.** Parapet's own constraint ("generated files must remain inspectable and modifiable by the adopter") is also the Phoenix generator contract. `phx.gen.auth` generates readable Elixir files that the host app owns. A wizard that generates opaque or non-obvious code contradicts this.

5. **Provider behaviours are the right SLO authoring abstraction.** The existing `Parapet.SLO.Provider` callback (`slos/0 :: [struct()]`) is idiomatic Elixir: a module that implements a behaviour, returns a list of structs, is compile-time validated, and is registered via config. This is the same shape as Phoenix's `Plug` behaviour, Oban's `Worker` behaviour, and Ecto's `Changeset` pipeline. It is already correct.

### SLO authoring idioms

The prompts research file establishes: SLOs should be authored against "what does failure cost a user?" not "what can I measure?". The decision tree in the authoring guide already captures this as: user task blocked? → observable via metric? → synchronous or async? → define slice. A wizard that asks "which metric?" without that framing can produce SLOs on infrastructure metrics (the explicit anti-pattern documented in the authoring guide).

Sloth and Pyrra (the cross-ecosystem SLO tooling leaders) are config-file-driven or YAML-driven — not interactive wizard-driven. Google SLO Generator is config-file-driven. The ecosystem has converged on declarative SLO definitions, not interactive wizards.

---

## 4. Lessons From Comparable Libraries

### Phoenix generators

**Right:** `phx.gen.html`, `phx.gen.context`, `phx.gen.auth` all generate inspectable, host-owned Elixir code that the adopter controls. The adopter understands what was generated because it looks like normal Phoenix code.

**Wrong (historical):** Early Phoenix generators over-generated — boilerplate tests, views, and templates that many teams immediately deleted. The lesson was to generate less, not more, and to make generated code obviously purposeful.

**Footgun:** `phx.gen.auth` generates security-critical code into the host app. The advantage is host-ownership; the risk is that security patches to the generator don't reach apps that have already run it. For SLOs this is lower stakes, but the lesson applies: generated code that accumulates and diverges from library evolution is a maintenance burden.

### Igniter (Ash, Oban, LiveView)

**Right:** Igniter's composable, idempotent, AST-aware generators are the current best practice. `mix oban.install` infers the DB engine from deps — the adopter doesn't need to know the engine name. `mix ash.gen.resource` takes the resource name as a CLI argument, not a prompt.

**Wrong:** Igniter tasks that use `Mix.shell().prompt/1` for primary choices lose Igniter's dry-run and composability guarantees. The community consensus (confirmed from Elixir Forum discussions and Igniter docs) is that Igniter tasks should be flag-parameterized.

**Footgun:** Stepping outside Igniter's model to use `Mix.Shell.IO` prompts creates an inconsistency: the task cannot be previewed with `--dry-run`, cannot be composed into another Igniter task, and cannot be non-interactively automated in CI. Parapet's `mix parapet.install` already requires `--ci`-safe behavior (it is run in GitHub Actions contexts).

### Oban

**Right:** `mix oban.install` deduces everything it can, uses the `--repo` flag for the one thing it cannot deduce, and shows a summary notice of what it did. It does not ask questions.

**Wrong (historical, pre-Igniter):** Early Oban installation was fully manual — add config, create migration, wire supervisor. Igniter eliminated this. The improvement was not "add an interactive wizard" but "eliminate the choices the adopter shouldn't need to make."

### Sloth / Pyrra (SLO ecosystem)

**Right:** Sloth's spec format (`slo_name`, `sli`, `alerting`, `objectives`) is declarative YAML. You don't run a wizard — you write a file. Pyrra follows the same pattern. The reason: SLO definitions are configuration artifacts that should be in version control, diffable, and reviewable in PRs. An interactive wizard that generates a file produces the same artifact, but the generation step adds friction without adding information.

**Footgun of SLO wizards:** A wizard can guide an adopter to define a syntactically valid SLO that is semantically wrong — e.g., alerting on an infrastructure metric, setting a 90% objective on a login journey, using a denominator that includes only successful events. The authoring guide's decision tree guards against these mistakes. A wizard that asks "which metric?" without the user-harm framing actively bypasses the guard.

---

## 5. DX/UX Considerations

### Principle of least surprise

Parapet's install model is already established: `mix parapet.install` (Igniter-backed, flag-parameterized, composable, dry-runnable, shows diff before applying). An adopter who has used `mix parapet.install` expects `mix parapet.gen.slo` to behave the same way. A prompt-driven wizard that does not show a diff, cannot be dry-run, and blocks on stdin surprises that adopter.

### Host-owned and inspectable constraint

A wizard that generates a `Parapet.SLO.Provider` module is fine — the file is host-owned and inspectable. The constraint is about the output, not the input mechanism. However, the authoring guide's copy-paste template achieves the same output. If the wizard adds nothing to the adopter's understanding of the generated module, it adds complexity without value.

### The "one-liner + docs" alternative

The StarterPack pattern demonstrated in v0.10 is the right answer to "how do I get a first SLO without reading everything": `config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]`. That is a one-liner. A wizard to generate a custom slice is a second-tier need — it arises only when the starter packs do not cover the adopter's journey. An adopter at that point has already spent enough time with Parapet to read the authoring guide's SliceSpec template.

### When a wizard genuinely helps vs. when docs are better

A wizard helps when:
- The decision tree has many branches that are hard to navigate in prose
- The correct answer depends on project-specific context the wizard can introspect
- The output is complex enough that hand-authoring has a high error rate

None of these apply to SliceSpec authoring:
- The decision tree is simple (the authoring guide already renders it as a flowchart)
- The wizard cannot introspect which Prometheus metrics the adopter's app emits (it would ask the user for the metric name anyway)
- A `SliceSpec.new(...)` call has compile-time validation — errors surface immediately, not at runtime

A wizard helps least when the adopter learns more from reading the docs than from answering the wizard's questions. SliceSpec authoring is in that category.

---

## 6. Recommendation

### SLO-W1 (interactive `mix parapet.gen.slo` wizard): DEFER TO v1.1

**Do not ship in v1.0.**

Rationale:

1. **Freeze cost is high, value is marginal.** The wizard's question set and output contract would be frozen in v1.0, but the value it adds over the authoring guide + SliceSpec templates is small. An adopter who can write `config :parapet, providers: [...]` can also follow a 15-line SliceSpec template.

2. **Igniter incompatibility is a design problem, not a coding problem.** The wizard cannot be implemented idiomatically in Igniter without stepping outside Igniter's model. Shipping it as a non-Igniter `Mix.Task` breaks DX consistency with the rest of Parapet's tooling. The right solution is to wait until either Igniter adds interactive prompt support (which is on their roadmap per community discussion) or to redesign the wizard as a flag-based Igniter task.

3. **The "smart flag + docs" pattern is already idiomatic and working.** `mix parapet.install --with-sigra --with-mailglass` demonstrates the correct model: flags for choices, notices for follow-up. `mix parapet.gen.slo --name checkout_completion --integration checkout --objective 99.5 --alert-class page --metric parapet_checkout_completed_total` would be equally correct — and it would be Igniter-compatible, dry-runnable, and composable.

4. **Deferral is low-risk.** The Provider behaviour, SliceSpec, and authoring guide are already in v1.0. A v1.1 `mix parapet.gen.slo` flag-based Igniter task is purely additive — it generates the same file the adopter would otherwise write by hand. It adds no frozen API surface to the library itself (the generated file is host-owned).

**If v1.1 ships SLO-W1, the idiomatic design is:**

A flag-based Igniter task, not an interactive wizard. Example signature:

```elixir
# mix parapet.gen.slo \
#   --name checkout_completion \
#   --integration checkout \
#   --metric parapet_checkout_started_total \
#   --good-metric parapet_checkout_completed_total \
#   --good-matchers "status=ok" \
#   --objective 99.5 \
#   --alert-class page \
#   --runbook https://example.com/runbooks/checkout
```

The task uses `Igniter.create_new_file/3` to render the provider module from an EEx template. It shows a diff. It is composable. It is dry-runnable. It registers the new provider in `config.exs` using `Igniter.Project.Config.configure/5`. Then it composes `parapet.gen.prometheus` to immediately regenerate the alert rules.

This design is idiomatic, consistent, and adds zero frozen API surface beyond the task's flag schema.

---

### SLO-B1 (cross-integration slice bundles): DROP (or acknowledge as already done)

**Do not ship a formal Bundle abstraction in v1.0 or v1.1.**

Rationale:

1. **The existing Provider pattern is already the bundle abstraction.** Any `Parapet.SLO.Provider` module that returns multiple SliceSpecs is already a bundle. `DeliverySaaS` is a ten-slice bundle. Adopters can write host-owned provider modules that combine slices from HTTP, Oban, and Mailglass into a single registration. There is no capability gap.

2. **A formal `Parapet.SLO.Bundle` behaviour is premature.** The value-add of a Bundle over a Provider is shared metadata or labels that propagate to all member slices. This value only materializes when dashboard generation can use bundle-level grouping. Dashboard generation (Grafana) is not yet at the level of sophistication where bundle-level grouping would be consumed. Freezing a Bundle API surface before the dashboard layer can use it locks in an abstraction that may be wrong.

3. **Freeze cost is not justified by functional gain.** A `use Parapet.SLO.Bundle` macro that saves five lines of boilerplate is not worth adding to the frozen public surface. If the adoption evidence (post-v1.0) shows that adopters commonly write multi-integration provider modules and that a Bundle shorthand would help, adding it in v1.1 or v1.2 is purely additive.

4. **Correct framing for v1.0 docs:** The SLO authoring guide should explicitly note that a host-owned Provider module is already the bundle pattern — adopters do not need a new abstraction. This costs nothing and closes the conceptual gap.

**If a Bundle abstraction later becomes warranted (v1.2+)**, the right design is:
- A `Parapet.SLO.Bundle` behaviour with `slices/0` callback (alias for Provider, adds semantic clarity)
- Bundle-level `:dashboard_group` metadata field used by `mix parapet.gen.grafana` to group panels
- No new generator output beyond what Providers already produce

---

## 7. Coherence With Parapet's Vision and Other v1.0 Decisions

**"Compile out cleanly":** Both features, if shipped, would add no runtime deps and no Oban queues — they are pure codegen artifacts. This constraint is satisfied either way.

**"Generated files must remain inspectable and modifiable."** The flag-based SLO generator (v1.1) satisfies this fully. The wizard (if it had shipped) would also satisfy it — but the interactive mechanism would not.

**"Low-cardinality by default."** Neither SLO-W1 nor SLO-B1 touch the metric label policy. This constraint is downstream of SliceSpec design, which is already correct.

**Frozen API contract:** v1.0's freeze targets the Provider behaviour, SliceSpec struct, Generator, and starter packs. These are proven in adoption (v0.10 shipped them). SLO-W1 would add a Mix task's flag schema and output contract. SLO-B1 would add a Bundle behaviour. Both are better deferred until the adoption evidence from v1.0 reveals what adopters actually need.

**"Host-owned infrastructure, not a vendor product."** Both features are additive scaffolding generators — fully consistent with the DNA. No concern here.

**"Opinionated SLO starter packs over auto-generated targets."** This v0.10 key decision is an argument against the wizard. The insight was that opinionated, documented, named packs beat silent auto-targets. A wizard that walks through every SliceSpec field without the opinionated framing risks producing the "auto-target" anti-pattern through different means.

---

## 8. Milestone Fit, Effort, and GSD Phase Chunking

### v1.0 scope recommendation

Neither SLO-W1 nor SLO-B1 belongs in v1.0. The v1.0 milestone should focus on:
1. Finalizing the public API surface for Provider, SliceSpec, Generator, and StarterPacks (already stable)
2. Documenting the stability tiers and deprecation policy
3. Any proven-in-adoption surface that needs to graduate to stable

SLO-W1 and SLO-B1 are pre-adoption features — they address a problem (authoring friction) that may or may not be the real bottleneck once v1.0 ships. Let adoption data from v1.0 reveal whether adopters are struggling with SliceSpec authoring or with something else entirely.

### SLO-W1 as a v1.1 workitem (if adoption evidence supports it)

If post-v1.0 adopter feedback shows that custom slice authoring is a friction point, SLO-W1 as a flag-based Igniter task is a single focused milestone. Rough effort:

| Phase | Content | Effort |
|-------|---------|--------|
| Phase 1 | Design flag schema for `mix parapet.gen.slo`; define EEx template for provider module output | 0.5 day |
| Phase 2 | Implement Igniter task: parse flags, render template, create file, configure providers, compose `parapet.gen.prometheus` | 1 day |
| Phase 3 | Tests: Igniter.Test assertions for generated file, config registration, prometheus composition | 0.5 day |
| Phase 4 | Docs: add `gen.slo` to authoring guide as the "if you don't want to hand-write the template" path | 0.25 day |

Total: ~2.25 days. A clean single-phase milestone if scope is kept tight.

### SLO-B1 as a v1.2+ workitem (only if dashboard grouping is built)

Bundle abstraction is only worth building when `mix parapet.gen.grafana` can consume bundle-level metadata to group panels. That milestone comes after Grafana generation is mature enough to benefit from the grouping. Do not build the Bundle API speculatively.

---

## 9. Sources

**Ecosystem documentation (HIGH confidence):**
- Igniter API docs: https://hexdocs.pm/igniter/Igniter.html — confirmed no interactive prompt functions
- Igniter writing generators guide: https://ash-project.github.io/igniter/writing-generators.html — confirmed flag-based design
- Oban installation docs: https://hexdocs.pm/oban/installation.html — confirmed flag-based Igniter installer, no prompts
- Phoenix phx.gen.context source: https://github.com/phoenixframework/phoenix/blob/main/lib/mix/tasks/phx.gen.context.ex — confirmed `yes?()` used only for conflict resolution
- Ash generators overview: https://hexdocs.pm/ash/generators.html — confirmed Igniter-backed, flag-based
- Sloth SLO generator: https://sloth.dev — confirmed declarative YAML, no wizard
- Igniter design philosophy: https://alembic.com.au/blog/igniter-rethinking-code-generation-with-project-patching — confirmed "project patching over file generation"

**Parapet codebase (HIGH confidence — directly read):**
- `lib/parapet/slo/provider.ex` — one-callback behaviour, minimal surface
- `lib/parapet/slo/slice_spec.ex` — struct with compile-time validation
- `lib/parapet/slo/generator.ex` — no interactive components
- `lib/parapet/slo/starter_pack/web_saas.ex` — three-slice bundle, provider pattern already is the abstraction
- `lib/parapet/slo/starter_pack/delivery_saas.ex` — ten-slice conditional bundle
- `lib/mix/tasks/parapet.install.ex` — Igniter-backed, flag-parameterized, dry-runnable, composable
- `docs/slo-authoring-guide.md` — decision tree already encodes the wizard logic in prose form
- `docs/getting-started.md` — one-liner pack activation is the established pattern

**Project context (HIGH confidence — directly read):**
- `.planning/PROJECT.md` — "host-owned inspectable" constraint, "compile out cleanly", freeze rationale
- `prompts/sre-best-practices-solo-founder-deep-research.md` — SLO authoring should be journey-first, not metric-first
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — "generate the boring correct stuff"; opinionated defaults beat open-ended choices
