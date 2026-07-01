# Upgrade Guide (1.x) — Schema Prefix Migration

This guide is the single source of truth for upgrading existing Parapet installations to the
`parapet` schema prefix introduced in Parapet 1.7. All other surfaces
([Migrating to Parapet 1.x](migration-v1.md), [Deploying Parapet](deployment.md)) route here.

## TL;DR

**Your data never moves automatically — nothing runs behind your back.**

Parapet 1.7 changed the default schema for evidence tables from `public` to `parapet`. New
installs work out of the box. Existing adopters must choose one of two tracks below, or the
first spine query fails with `relation "parapet.parapet_incidents" does not exist`.

## Action Required for Existing Adopters

**Action required for existing adopters: add `config :parapet, schema_prefix: nil` +
`mix deps.compile parapet --force` to stay on `public`, then run `mix parapet.doctor`.**

A do-nothing upgrader gets compiled `@prefix == "parapet"` pointed at `public` data — your
existing evidence tables — and sees a loud `relation "parapet.parapet_incidents" does not exist`
error on the first spine query. Nothing is corrupted; the `parapet` schema simply does not exist
in your database yet. But you must choose: stay on `public` (Track A) or move to `parapet`
(Track B).

Run `mix parapet.doctor` before and after whichever track you choose. The `schema` check catches
compile-time/runtime drift and will tell you exactly what to do.

## Track A: Stay on `public`

Add the following to `config/config.exs` to pin Parapet to the `public` schema:

```elixir
config :parapet, schema_prefix: nil
```

Then recompile the library so the compile-time default takes effect:

```bash
mix deps.compile parapet --force
```

Then run the doctor to confirm the prefix resolves correctly:

```bash
mix parapet.doctor
```

Your existing evidence tables stay exactly where they are. No migration is needed.

## Track B: Move to `parapet`

Run the move generator to produce a reversible migration:

```bash
mix parapet.gen.schema.move
mix ecto.migrate
```

The generated migration:

- Uses `SET LOCAL lock_timeout TO '5s'` (in `after_begin/0`) to bound the `ACCESS EXCLUSIVE`
  lock acquisition so a blocked move fails fast rather than queuing production traffic behind
  the FIFO lock queue.
- Runs `CREATE SCHEMA IF NOT EXISTS parapet` (this line is omitted if you pass
  `--no-create-schema`, for DBA-managed schemas).
- Executes six explicit, fully-qualified `ALTER TABLE` lines:
  ```sql
  ALTER TABLE public.parapet_action_items SET SCHEMA parapet;
  ALTER TABLE public.parapet_incidents SET SCHEMA parapet;
  ALTER TABLE public.parapet_timeline_entries SET SCHEMA parapet;
  ALTER TABLE public.parapet_tool_audits SET SCHEMA parapet;
  ALTER TABLE public.parapet_system_events SET SCHEMA parapet;
  ALTER TABLE public.parapet_action_claims SET SCHEMA parapet;
  ```
- `down` reverses the move with six `ALTER TABLE parapet.<t> SET SCHEMA public` lines in
  LIFO order.
- `down` **never** runs `DROP SCHEMA` — fail-closed safety. Roll back spine table migrations
  before rolling back this one.

The entire move runs in a single transaction. If any step fails, nothing moves.

After the migration runs, recompile to clear any cached compiled prefix:

```bash
mix deps.compile parapet --force
```

Then confirm the prefix resolves correctly:

```bash
mix parapet.doctor
```

## Least-Privilege GRANTs (DBA-Managed Schema)

If your deployment uses `--no-create-schema` because a DBA owns the schema, you must create
the schema and grant the correct privileges before running `mix ecto.migrate`:

```sql
-- Run once as a privileged role (DBA / schema owner):
CREATE SCHEMA IF NOT EXISTS parapet AUTHORIZATION your_app_role;

-- Split-role fallback (schema owned by a separate role):
GRANT USAGE  ON SCHEMA parapet TO your_app_role;
GRANT CREATE ON SCHEMA parapet TO your_app_role;
-- then: mix ecto.migrate
```

The `GRANT CREATE` is required because `ALTER TABLE … SET SCHEMA parapet` needs `CREATE`
privilege on the target schema.

## Recompile Order

When changing `schema_prefix` config or running the move migration, follow this order:

1. Update `config/config.exs` (Track A) **or** run `mix parapet.gen.schema.move && mix ecto.migrate` (Track B).
2. Run `mix deps.compile parapet --force` to bake the new prefix at compile time.
3. Run `mix parapet.doctor` to confirm drift is resolved and the schema exists.

If `mix parapet.doctor` reports a config drift warning, it means the runtime config and the
compiled prefix disagree — step 2 was not run, or the app restarted without a recompile.
The exact message is:

> "Config drift: runtime :schema_prefix is `<X>` but Parapet was compiled with `<Y>`. Spine
> reads/writes may target the wrong schema. Recompile the library:
> `mix deps.compile parapet --force`"

## Rollback

### Track A Rollback

Remove the `config :parapet, schema_prefix: nil` line from `config/config.exs`, then:

```bash
mix deps.compile parapet --force
```

```bash
mix parapet.doctor
```

### Track B Rollback

Roll back the move migration:

```bash
mix ecto.rollback
```

The `down` migration reverses all six `ALTER TABLE` lines in LIFO order, moving tables back to
`public`. It does not drop the `parapet` schema.

After rolling back, recompile:

```bash
mix deps.compile parapet --force
```

```bash
mix parapet.doctor
```

### Half-Migrated Recovery

If `mix ecto.migrate` was interrupted mid-run (e.g. the lock timed out on one table), the
migration runs inside a single transaction. A failure inside the transaction rolls back all
`SET SCHEMA` moves atomically — there is no partial state to recover from. The `lock_timeout`
set via `after_begin/0` ensures the migration fails fast rather than hanging.

If somehow the migration was marked applied in the schema_migrations table but the data was
not moved (an extremely rare edge case in non-transactional migration setups), run
`mix ecto.rollback` to force the `down` path, which will reverse whatever did move.

## FAQ

**Q: Does Parapet auto-detect which schema I was using before upgrading?**
No. There is no runtime install-detection. Parapet's default is a compile-time constant
(`Application.compile_env(:parapet, :schema_prefix, "parapet")`). Changing it requires
an explicit config change and recompile (Track A) or a migration (Track B).

**Q: If I do nothing and upgrade, what happens?**
The first spine query (e.g. listing incidents on the Operator UI) will fail with
`relation "parapet.parapet_incidents" does not exist`. Your data in `public` is safe and
untouched. You just need to choose Track A or Track B.

**Q: Can I run `mix parapet.doctor` to check before I decide?**
Yes. The `schema` check will report the compiled prefix and whether it exists in your database.
If your tables are in `public` and the compiled prefix is `parapet`, you will see a
schema-existence error — the signal to choose a track.

**Q: Will `mix parapet.doctor` catch a half-configured state?**
Yes. The `schema` check compares the runtime `:schema_prefix` config against the compiled
`@schema_prefix` module attribute. If they disagree (e.g. you updated config but forgot to
recompile), it reports:
> "Config drift: runtime :schema_prefix is `<X>` but Parapet was compiled with `<Y>`. Spine
> reads/writes may target the wrong schema. Recompile the library:
> `mix deps.compile parapet --force`"

**Q: Does Track B break existing FKs, indexes, or constraints?**
No. PostgreSQL moves indexes, constraints, and foreign keys atomically with the table when
using `ALTER TABLE … SET SCHEMA`. The move is byte-identical in terms of object names. The
generated migration includes an advisory check for views referencing spine tables by
unqualified name — those may need updating after the move.

**Q: What about contributors running the demo app on an existing database?**
Contributors with an existing demo database created before Phase 53 need to reset it:

```bash
cd examples/demo_app && mix ecto.drop && mix ecto.create && mix ecto.migrate && mix run priv/repo/seeds.exs
```

Or use the alias `mix demo.reset` if your project defines it. This is a contributor concern,
not an adopter concern — production adopters do not run the demo app.

**Q: I use a DBA-managed schema and cannot create schemas myself. What do I do?**
Use the `--no-create-schema` flag with the move generator:

```bash
mix parapet.gen.schema.move --no-create-schema
```

Then ask your DBA to run the GRANT block in the [Least-Privilege GRANTs](#least-privilege-grants-dba-managed-schema)
section before you run `mix ecto.migrate`.

**Q: The doctor says the schema does not exist. Is that an error?**
If you have not chosen a track yet, it is expected: your tables are in `public` and the default
compiled prefix (`parapet`) is pointing at a schema that does not exist in your database. Choose
Track A (stay on `public`) or Track B (move to `parapet`) to resolve it.
