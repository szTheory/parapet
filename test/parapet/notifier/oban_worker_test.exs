defmodule Parapet.Notifier.ObanWorkerTest do
  use ExUnit.Case, async: false

  defmodule DummyRepo do
    def insert(changeset, _opts \\ []) do
      send(self(), {:insert, changeset})
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def get(Parapet.Spine.Incident, id) do
      %Parapet.Spine.Incident{id: id, state: "open"}
    end

    def all(_query) do
      []
    end
  end

  defmodule SuccessAdapter do
    @behaviour Parapet.Notifier
    def deliver(_incident, _opts), do: {:ok, "delivered fine"}
  end

  defmodule ErrorAdapter do
    @behaviour Parapet.Notifier
    def deliver(_incident, _opts), do: {:error, "failed horribly"}
  end

  defmodule ExceptionAdapter do
    @behaviour Parapet.Notifier
    def deliver(_incident, _opts), do: raise("boom")
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    Application.put_env(:parapet, :use_oban_for_notifications, false)

    on_exit(fn ->
      Application.delete_env(:parapet, :repo)
    end)

    incident_id = Ecto.UUID.generate()
    {:ok, incident_id: incident_id}
  end

  test "ObanWorker perform/1 handles success and writes timeline entry", %{
    incident_id: incident_id
  } do
    args = %{
      "incident_id" => incident_id,
      "adapter" => to_string(SuccessAdapter),
      "opts" => "[]"
    }

    assert :ok = Parapet.Notifier.ObanWorker.perform(%Oban.Job{args: args})

    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == incident_id
    assert entry.type == "notification_dispatched"
    assert entry.payload.adapter == inspect(SuccessAdapter)
    assert entry.payload.status == "success"
    assert entry.payload.details == inspect("delivered fine")
  end

  test "ObanWorker perform/1 handles error and writes timeline entry", %{incident_id: incident_id} do
    args = %{
      "incident_id" => incident_id,
      "adapter" => to_string(ErrorAdapter),
      "opts" => "[]"
    }

    assert {:error, _} = Parapet.Notifier.ObanWorker.perform(%Oban.Job{args: args})

    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.payload.status == "error"
    assert entry.payload.details == inspect("failed horribly")
  end

  test "ObanWorker perform/1 handles exceptions and still writes timeline entry", %{
    incident_id: incident_id
  } do
    args = %{
      "incident_id" => incident_id,
      "adapter" => to_string(ExceptionAdapter),
      "opts" => "[]"
    }

    assert {:error, _} = Parapet.Notifier.ObanWorker.perform(%Oban.Job{args: args})

    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.payload.status == "error"
    assert entry.payload.details =~ "boom"
  end
end
