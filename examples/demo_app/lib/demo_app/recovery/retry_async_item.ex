defmodule DemoApp.Recovery.RetryAsyncItem do
  use Parapet.Recovery

  @impl Parapet.Recovery
  def id, do: :retry_async_item

  @impl Parapet.Recovery
  def label, do: "Retry Async Item"

  @impl Parapet.Recovery
  def preview(incident, _step) do
    {:ok,
     %{
       count: 1,
       target_refs: [incident.id],
       preconditions: ["Item must be in 'executing' state"],
       warnings: ["Retrying without root cause analysis may reproduce the stall"],
       summary: "Force-retry the stalled async item linked to this incident"
     }}
  end

  @impl Parapet.Recovery
  def execute(incident, _target_refs) do
    import Ecto.Query

    # Find the first open item linked to this incident, then update it by id.
    # update_all does not support limit: so we do a select-then-update pattern.
    case DemoApp.Repo.one(
           from(a in Parapet.Spine.ActionItem,
             where: a.incident_id == ^incident.id and a.state == "open",
             limit: 1,
             select: a.id
           )
         ) do
      nil ->
        {:ok, %{retried_count: 0, note: "no open items found"}}

      item_id ->
        {n, _} =
          DemoApp.Repo.update_all(
            from(a in Parapet.Spine.ActionItem, where: a.id == ^item_id),
            set: [state: "retrying"]
          )

        {:ok, %{retried_count: n}}
    end
  end
end
