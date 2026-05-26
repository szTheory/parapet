defmodule Parapet.EvidenceTest do
  use ExUnit.Case, async: false

  defmodule DummyRepo do
    def insert(changeset, _opts \\ []) do
      if changeset.valid? do
        struct = Ecto.Changeset.apply_changes(changeset)
        # ensure it has an ID
        struct = Map.put(struct, :id, Ecto.UUID.generate())
        send(self(), {:dummy_repo_insert, struct.__struct__})
        {:ok, struct}
      else
        {:error, changeset}
      end
    end

    def update(changeset, _opts \\ []) do
      if changeset.valid? do
        struct = Ecto.Changeset.apply_changes(changeset)
        send(self(), {:dummy_repo_update, struct.__struct__})
        {:ok, struct}
      else
        {:error, changeset}
      end
    end

    def transaction(%Ecto.Multi{} = multi) do
      ops = Ecto.Multi.to_list(multi)

      try do
        results =
          Enum.reduce(ops, %{}, fn op, acc ->
            case op do
              {name, {:insert, changeset, _opts}} when not is_function(changeset) ->
                if changeset.valid? do
                  struct = Ecto.Changeset.apply_changes(changeset)
                  struct = Map.put(struct, :id, Ecto.UUID.generate())
                  send(self(), {:dummy_repo_insert, struct.__struct__})
                  Map.put(acc, name, struct)
                else
                  throw({:rollback, name, changeset, acc})
                end

              {name, {:insert, fun, _opts}} when is_function(fun) ->
                changeset = fun.(acc)

                is_valid =
                  case changeset do
                    %Ecto.Changeset{valid?: valid} -> valid
                    _ -> true
                  end

                if is_valid do
                  struct =
                    case changeset do
                      %Ecto.Changeset{} -> Ecto.Changeset.apply_changes(changeset)
                      other -> other
                    end

                  struct = Map.put(struct, :id, Ecto.UUID.generate())
                  send(self(), {:dummy_repo_insert, struct.__struct__})
                  Map.put(acc, name, struct)
                else
                  throw({:rollback, name, changeset, acc})
                end

              {name, {:update, changeset, _opts}} when not is_function(changeset) ->
                if changeset.valid? do
                  struct = Ecto.Changeset.apply_changes(changeset)
                  send(self(), {:dummy_repo_update, struct.__struct__})
                  Map.put(acc, name, struct)
                else
                  throw({:rollback, name, changeset, acc})
                end

              {name, {:run, fun}} ->
                case fun.(__MODULE__, acc) do
                  {:ok, result} -> Map.put(acc, name, result)
                  {:error, reason} -> throw({:rollback, name, reason, acc})
                end
            end
          end)

        {:ok, results}
      catch
        {:rollback, name, error_val, results} ->
          {:error, name, error_val, results}
      end
    end
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    on_exit(fn -> Application.delete_env(:parapet, :repo) end)
    :ok
  end

  describe "repo/0" do
    test "fetches repo from application env" do
      assert Parapet.Evidence.repo() == DummyRepo
    end

    test "raises a clear error when repo is not configured" do
      Application.delete_env(:parapet, :repo)

      assert_raise ArgumentError, ~r/requires a :repo to be configured/, fn ->
        Parapet.Evidence.repo()
      end
    end
  end

  describe "create_incident/1" do
    test "creates an incident with valid attrs" do
      attrs = %{title: "API Outage", description: "Database is slow"}
      assert {:ok, incident} = Parapet.Evidence.create_incident(attrs)
      assert incident.title == "API Outage"
      assert incident.state == "open"
    end

    test "enqueues escalation job if policy is configured" do
      Application.put_env(
        :parapet,
        :escalation_policy,
        Parapet.Escalation.WorkerTest.SuccessPolicy
      )

      on_exit(fn -> Application.delete_env(:parapet, :escalation_policy) end)

      attrs = %{title: "API Outage 2", description: "Database is down"}
      assert {:ok, incident} = Parapet.Evidence.create_incident(attrs)
      assert incident.title == "API Outage 2"

      # Verify Oban job is inserted via multi
      assert_receive {:dummy_repo_insert, Oban.Job}
    end

    test "returns error changeset for invalid attrs" do
      attrs = %{title: nil}
      assert {:error, changeset} = Parapet.Evidence.create_incident(attrs)
      refute changeset.valid?
    end
  end

  describe "append_timeline/2" do
    test "appends a timeline entry" do
      incident_id = Ecto.UUID.generate()
      attrs = %{type: "note", payload: %{"text" => "Looked into it"}}
      assert {:ok, entry} = Parapet.Evidence.append_timeline(incident_id, attrs)
      assert entry.incident_id == incident_id
      assert entry.type == "note"
    end
  end

  describe "log_tool_audit/1" do
    setup do
      # Attach a telemetry handler to track events
      handler_id = "test-log-tool-audit-#{System.unique_integer()}"

      :telemetry.attach(
        handler_id,
        [:parapet, :audit, :created],
        fn _name, _measurements, metadata, _config ->
          send(self(), {:telemetry_event, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)
      :ok
    end

    test "logs a tool audit to DB and emits telemetry in :dual_write mode (default)" do
      Application.put_env(:parapet, :audit_mode, :dual_write)

      attrs = %{tool_name: "test_tool", input: %{"a" => 1}, success: true}
      assert {:ok, audit} = Parapet.Evidence.log_tool_audit(attrs)
      assert audit.tool_name == "test_tool"

      # Verify DB insert
      assert_receive {:dummy_repo_insert, Parapet.Spine.ToolAudit}

      # Verify telemetry
      assert_receive {:telemetry_event, metadata}
      assert metadata.audit_attrs == attrs
    end

    test "bypasses DB insert and only emits telemetry in :threadline_deferred mode" do
      Application.put_env(:parapet, :audit_mode, :threadline_deferred)
      on_exit(fn -> Application.delete_env(:parapet, :audit_mode) end)

      attrs = %{tool_name: "test_tool", input: %{"a" => 1}, success: true}
      assert {:ok, :deferred} = Parapet.Evidence.log_tool_audit(attrs)

      # Verify NO DB insert
      refute_receive {:dummy_repo_insert, Parapet.Spine.ToolAudit}

      # Verify telemetry
      assert_receive {:telemetry_event, metadata}
      assert metadata.audit_attrs == attrs
    end
  end

  describe "run_operator_command/1" do
    setup do
      # Attach a telemetry handler to track events
      handler_id = "test-run-operator-#{System.unique_integer()}"

      :telemetry.attach(
        handler_id,
        [:parapet, :audit, :created],
        fn _name, _measurements, metadata, _config ->
          send(self(), {:telemetry_event, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)
      :ok
    end

    test "inserts TimelineEntry and ToolAudit, and emits telemetry in :dual_write mode" do
      Application.put_env(:parapet, :audit_mode, :dual_write)

      incident = %Parapet.Spine.Incident{id: Ecto.UUID.generate(), state: "open"}
      incident_changeset = Ecto.Changeset.change(incident, %{state: "resolved"})

      opts = [
        incident_changeset: incident_changeset,
        timeline_attrs: %{type: "note", payload: %{"text" => "Fixed"}},
        audit_attrs: %{tool_name: "fixer", input: %{}, success: true}
      ]

      assert {:ok, results} = Parapet.Evidence.run_operator_command(opts)

      assert results.incident.state == "resolved"
      assert results.timeline_entry.type == "note"
      assert results.tool_audit.tool_name == "fixer"
      assert results.broadcast_audit == :broadcasted

      # Verify DB inserts
      assert_receive {:dummy_repo_insert, Parapet.Spine.TimelineEntry}
      assert_receive {:dummy_repo_insert, Parapet.Spine.ToolAudit}

      # Verify telemetry
      assert_receive {:telemetry_event, metadata}
      assert metadata.audit_attrs.tool_name == "fixer"
    end

    test "inserts TimelineEntry but BYPASSES ToolAudit DB insert in :threadline_deferred mode" do
      Application.put_env(:parapet, :audit_mode, :threadline_deferred)
      on_exit(fn -> Application.delete_env(:parapet, :audit_mode) end)

      incident = %Parapet.Spine.Incident{id: Ecto.UUID.generate(), state: "open"}
      incident_changeset = Ecto.Changeset.change(incident, %{state: "resolved"})

      opts = [
        incident_changeset: incident_changeset,
        timeline_attrs: %{type: "note", payload: %{"text" => "Fixed"}},
        audit_attrs: %{tool_name: "fixer", input: %{}, success: true}
      ]

      assert {:ok, results} = Parapet.Evidence.run_operator_command(opts)

      assert results.incident.state == "resolved"
      assert results.timeline_entry.type == "note"
      assert results.tool_audit == :deferred

      # Verify DB inserts
      assert_receive {:dummy_repo_insert, Parapet.Spine.TimelineEntry}
      refute_receive {:dummy_repo_insert, Parapet.Spine.ToolAudit}

      # Verify telemetry
      assert_receive {:telemetry_event, metadata}
      assert metadata.audit_attrs.tool_name == "fixer"
    end
  end
end
