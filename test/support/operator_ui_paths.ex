defmodule Parapet.TestSupport.OperatorUIPaths do
  @moduledoc false

  def component_paths do
    [
      "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex",
      "priv/templates/parapet.gen.ui/operator_components.ex.eex"
    ]
  end

  def live_template_paths do
    [
      "priv/templates/parapet.gen.ui/operator_live.ex.eex",
      "examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex"
    ]
  end

  def detail_template_paths do
    [
      "priv/templates/parapet.gen.ui/operator_detail_live.ex.eex",
      "examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex"
    ]
  end
end
