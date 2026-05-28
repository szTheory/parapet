defmodule Parapet.Operator.UI do
  @moduledoc """
  UI copy helpers for operator recovery-action result variants.

  Generated operator LiveViews (`mix parapet.gen.ui`) call these so the wording —
  and any *new* short-circuit reasons added in a later 1.x release — are owned by
  the library and inherited on upgrade. The host keeps the control flow; the
  library owns the copy.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @typedoc "A flash severity level paired with an operator-facing message."
  @type flash :: {:info | :warning | :error, String.t()}

  @doc since: "1.1.0"
  @doc """
  Maps a `t:Parapet.Operator.short_circuit_reason/0` to a `{level, message}` flash.

  Returns a safe default for any reason this version does not yet know about — so a
  host on an older generated template never crashes when a new reason ships. New
  reasons are additive within 1.x.

  ## Examples

      iex> Parapet.Operator.UI.short_circuit_flash(:preview_expired)
      {:warning, "Preview expired — please re-Preview before confirming"}

      iex> Parapet.Operator.UI.short_circuit_flash(:some_future_reason)
      {:warning, "Recovery could not proceed — refresh and review the timeline"}
  """
  @spec short_circuit_flash(atom()) :: flash()
  def short_circuit_flash(:preview_expired),
    do: {:warning, "Preview expired — please re-Preview before confirming"}

  def short_circuit_flash(:target_refs_drift),
    do: {:warning, "Target state changed since Preview — please re-Preview"}

  def short_circuit_flash(:incident_resolved),
    do: {:info, "Incident already resolved — no action needed"}

  def short_circuit_flash(:breaker_open),
    do: {:warning, "Circuit breaker open — recovery temporarily disabled"}

  def short_circuit_flash(:internal_error),
    do: {:error, "Recovery could not proceed due to an internal error — review the timeline"}

  # Forward-compatibility catch-all: a future additive reason degrades gracefully
  # instead of raising FunctionClauseError in a host's generated LiveView.
  def short_circuit_flash(_other),
    do: {:warning, "Recovery could not proceed — refresh and review the timeline"}
end
