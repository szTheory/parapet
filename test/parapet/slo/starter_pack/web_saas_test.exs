defmodule Parapet.SLO.StarterPack.WebSaaSTest do
  use ExUnit.Case, async: true

  alias Parapet.Internal.LabelPolicy
  alias Parapet.SLO.SliceSpec
  alias Parapet.SLO.StarterPack.WebSaaS

  test "slos/0 returns exactly 3 SliceSpec structs in the correct order" do
    slices = WebSaaS.slos()

    assert length(slices) == 3

    assert Enum.map(slices, & &1.name) == [
             :web_saas_http_availability,
             :web_saas_login_journey,
             :web_saas_oban_job_success
           ]

    Enum.each(slices, fn slice ->
      assert %SliceSpec{} = slice
    end)
  end

  test "HTTP availability slice has correct metric names, matchers, objective, and alert class" do
    slices = WebSaaS.slos()
    http = Enum.find(slices, &(&1.name == :web_saas_http_availability))

    assert http.good_source_metric == "parapet_http_request_count"
    assert http.good_matchers[:status_class] == ["2xx", "3xx"]
    assert http.total_source_metric == "parapet_http_request_count"
    assert http.total_matchers[:status_class] == ["2xx", "3xx", "4xx", "5xx"]
    assert http.objective == 99.5
    assert http.alert_class == :ticket
  end

  test "login journey slice has correct metric names, matchers, objective, and alert class" do
    slices = WebSaaS.slos()
    login = Enum.find(slices, &(&1.name == :web_saas_login_journey))

    assert login.good_source_metric == "parapet_journey_login_count"
    assert login.good_matchers[:outcome] == :success
    assert login.total_source_metric == "parapet_journey_login_count"
    assert login.total_matchers[:outcome] == [:success, :failure]
    assert login.objective == 99.9
    assert login.alert_class == :page
  end

  test "Oban job success slice has correct metric names, matchers, objective, and alert class" do
    slices = WebSaaS.slos()
    oban = Enum.find(slices, &(&1.name == :web_saas_oban_job_success))

    assert oban.good_source_metric == "parapet_oban_jobs_total"
    assert oban.good_matchers[:state] == "success"
    assert oban.total_source_metric == "parapet_oban_jobs_total"
    assert oban.total_matchers[:state] == ["success", "failure", "cancelled", "discarded"]
    assert oban.objective == 99.0
    assert oban.alert_class == :ticket
  end

  test "every slice has a non-zero min_total_rate" do
    slices = WebSaaS.slos()

    Enum.each(slices, fn slice ->
      assert is_number(slice.min_total_rate),
             "Expected min_total_rate to be a number for #{slice.name}"

      assert slice.min_total_rate > 0, "Expected min_total_rate to be > 0 for #{slice.name}"
    end)
  end

  test "all WebSaaS pack slice matcher keys pass LabelPolicy.assert_safe!" do
    slices = WebSaaS.slos()

    Enum.each(slices, fn slice ->
      matcher_keys = Keyword.keys(slice.good_matchers ++ slice.total_matchers)
      assert :ok = LabelPolicy.assert_safe!(matcher_keys)
      assert :ok = LabelPolicy.assert_safe!(slice.group_labels)
    end)
  end
end

defmodule Parapet.SLO.StarterPack.WebSaaSRegistrationTest do
  use ExUnit.Case, async: false

  alias Parapet.SLO.Generator
  alias Parapet.SLO.StarterPack.WebSaaS

  test "registering WebSaaS as provider generates alerts with denominator guard and recording rules" do
    Application.put_env(:parapet, :providers, [WebSaaS])

    on_exit(fn ->
      Application.put_env(:parapet, :slos, [])
      Application.put_env(:parapet, :providers, [])
    end)

    artifacts = Generator.provider_artifacts()

    assert artifacts.alerts =~ "> 0.01"
    assert artifacts.recording_rules =~ "web_saas_http_availability"
  end
end
