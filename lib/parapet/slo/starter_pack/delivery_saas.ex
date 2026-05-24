defmodule Parapet.SLO.StarterPack.DeliverySaaS do
  @moduledoc """
  Extends `Parapet.SLO.StarterPack.WebSaaS` with Mailglass and Chimeway delivery SLO slices.

  Register in one line:

      config :parapet, providers: [Parapet.SLO.StarterPack.DeliverySaaS]

  This pack composes the three WebSaaS slices (HTTP availability, login journey, Oban job
  success) with the full Mailglass and Chimeway delivery catalogs, giving delivery-sending
  teams a coherent first set of SLOs without any hand-written PromQL.

  ## Conditional Registration

  Delivery slices are registered **only when the corresponding host library is loaded**.
  If Mailglass is not installed in the host application, Mailglass slices are omitted
  cleanly — no error, no dead alert rules. Same for Chimeway. Each guard is independent:
  a team using only Mailglass (without Chimeway) gets WebSaaS + Mailglass slices only.

  The module itself is always loadable and fully documented regardless of which host
  libraries are present, so `mix verify.public_api` always passes.

  ## Slices (when all host libs present)

  - 3 slices from `Parapet.SLO.StarterPack.WebSaaS` (HTTP availability, login journey,
    Oban job success)
  - 4 slices from `Parapet.SLO.MailglassDelivery` (submit acceptance, confirmed delivery,
    webhook freshness, suppression drift)
  - 3 slices from `Parapet.SLO.ChimewayDelivery` (provider acceptance, callback
    confirmation, callback freshness)

  Total: 10 slices when both Mailglass and Chimeway host libraries are loaded.
  """

  @behaviour Parapet.SLO.Provider

  alias Parapet.SLO.ChimewayDelivery
  alias Parapet.SLO.MailglassDelivery
  alias Parapet.SLO.StarterPack.WebSaaS

  @doc """
  Returns the composite SLO slice list: WebSaaS slices plus any loaded delivery slices.

  In production, delivery slices are included only when the corresponding host library
  (`Mailglass` or `Chimeway`) is loaded. When a host library is absent, its slices are
  omitted cleanly with no error. Register this provider via
  `config :parapet, providers: [Parapet.SLO.StarterPack.DeliverySaaS]`.
  """
  @impl true
  def slos do
    WebSaaS.slos() ++ delivery_slices(Mailglass, Chimeway)
  end

  @doc false
  def delivery_slices(mailglass_mod, chimeway_mod) do
    mailglass_slices =
      if Code.ensure_loaded?(mailglass_mod) do
        MailglassDelivery.slos()
      else
        []
      end

    chimeway_slices =
      if Code.ensure_loaded?(chimeway_mod) do
        ChimewayDelivery.slos()
      else
        []
      end

    mailglass_slices ++ chimeway_slices
  end
end
