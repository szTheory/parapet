defmodule Parapet.Spine.PrefixPropagationTest do
  @moduledoc false

  use Parapet.TestSupport.ConcurrencyCase, async: false

  alias Parapet.Automation.CircuitBreaker
  alias Parapet.Automation.ClaimService
  alias Parapet.Evidence
  alias Parapet.MCP.Server
  alias Parapet.Spine.{ActionClaim, ActionItem, Incident, SystemEvent, TimelineEntry, ToolAudit}
  alias Parapet.TestSupport.ConcurrencyRepo

  # Bind at module top — baked at compile time, matches what @schema_prefix saw (D-09).
  @prefix Parapet.Spine.Schema.__prefix__()

  # ----------------------------------------------------------------
  # PROP-01/PROP-03 Part 1: to_sql FROM + JOIN proof (D-08, D-10)
  # Two spine↔spine joins: mcp/server.ex builder + circuit_breaker.ex query
  # ----------------------------------------------------------------

  describe "to_sql qualified prefix on spine↔spine joins" do
    test "timeline_for_correlation_query carries qualified prefix on FROM and JOIN" do
      query = Server.timeline_for_correlation_query("key-123")
      {sql, _params} = Ecto.Adapters.SQL.to_sql(:all, ConcurrencyRepo, query)

      if @prefix do
        assert sql =~ ~s("#{@prefix}"."parapet_timeline_entries"),
               "Expected qualified FROM token in: #{sql}"

        assert sql =~ ~s("#{@prefix}"."parapet_incidents"),
               "Expected qualified JOIN token in: #{sql}"

        # Negative: qualified FROM/JOIN means no stray bare `parapet_incidents` unqualified
        # (i.e. the table is only referenced in the form "schema"."table", not naked)
        if @prefix do
          refute sql =~ ~r/(?<!"parapet")\.parapet_incidents/,
                 "Bare parapet_incidents found in SQL — prefix not applied to JOIN: #{sql}"
        end
      else
        refute sql =~ ~s("parapet"."parapet_),
               "Public leg must not carry parapet. prefix: #{sql}"
      end
    end

    test "execution_count_query carries qualified prefix on FROM and JOIN" do
      query = CircuitBreaker.execution_count_query(Ecto.UUID.generate(), "step-1")
      {sql, _params} = Ecto.Adapters.SQL.to_sql(:all, ConcurrencyRepo, query)

      if @prefix do
        assert sql =~ ~s("#{@prefix}"."parapet_tool_audits"),
               "Expected qualified FROM token in: #{sql}"

        assert sql =~ ~s("#{@prefix}"."parapet_timeline_entries"),
               "Expected qualified JOIN token in: #{sql}"
      else
        refute sql =~ ~s("parapet"."parapet_),
               "Public leg must not carry parapet. prefix in circuit_breaker query: #{sql}"
      end
    end
  end

  # ----------------------------------------------------------------
  # PROP-01/PROP-03 Part 2: get_meta prefix proof (D-08)
  # insert_all + Ecto.Multi paths — to_sql cannot reach :insert_all
  # ----------------------------------------------------------------

  describe "Ecto.get_meta prefix on insert_all and Multi write paths" do
    test "Evidence.create_incident Ecto.Multi materializes correct prefix on returned struct" do
      {:ok, incident} =
        Evidence.create_incident(%{
          title: "Prefix propagation test incident",
          state: "open"
        })

      assert Ecto.get_meta(incident, :prefix) == @prefix,
             "Evidence.create_incident Ecto.Multi: expected prefix #{inspect(@prefix)}, " <>
               "got #{inspect(Ecto.get_meta(incident, :prefix))}"
    end

    test "ClaimService insert_all via claim_action materializes correct prefix on returned struct" do
      # Seed an incident so claim_action has a foreign key to reference
      {:ok, incident} =
        ConcurrencyRepo.insert(
          Incident.changeset(%Incident{}, %{title: "Claim prefix test", state: "open"})
        )

      result =
        ClaimService.claim_action(
          repo: ConcurrencyRepo,
          incident_id: incident.id,
          action_kind: "prefix_proof",
          action_key: "step-prefix-1",
          idempotency_key: "auto_exec_#{incident.id}_step-prefix-1"
        )

      assert {:won, claim} = result,
             "Expected {:won, claim} but got #{inspect(result)}"

      assert Ecto.get_meta(claim, :prefix) == @prefix,
             "ClaimService insert_all: expected prefix #{inspect(@prefix)}, " <>
               "got #{inspect(Ecto.get_meta(claim, :prefix))}"
    end
  end

  # ----------------------------------------------------------------
  # PROP-03 Part 3: six-schema __schema__(:prefix) equality (D-09)
  # Runs unconditionally — passes on both parapet and public legs
  # ----------------------------------------------------------------

  describe "six spine schemas carry consistent __schema__(:prefix)" do
    @spine_schemas [Incident, ActionItem, SystemEvent, ToolAudit, TimelineEntry, ActionClaim]

    test "all six schemas have __schema__(:prefix) == Schema.__prefix__()" do
      prefix = Parapet.Spine.Schema.__prefix__()

      for mod <- @spine_schemas do
        assert mod.__schema__(:prefix) == prefix,
               "#{mod}.__schema__(:prefix) is #{inspect(mod.__schema__(:prefix))} " <>
                 "but Parapet.Spine.Schema.__prefix__() is #{inspect(prefix)}"
      end
    end
  end
end
