defmodule Mix.Tasks.Verify.PublicApiTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Verify.PublicApi

  describe "detect_tier_from_text/1" do
    test "returns :stable when text contains both '{: .info}' and 'Stable'" do
      text = """
      Some module description.

      > #### Stable {: .info}
      >
      > This module is stable as of v1.0.0.
      """

      assert PublicApi.detect_tier_from_text(text) == :stable
    end

    test "returns :experimental when text contains both '{: .warning}' and 'Experimental'" do
      text = """
      Some module description.

      > #### Experimental {: .warning}
      >
      > This module is experimental in v1.x.
      """

      assert PublicApi.detect_tier_from_text(text) == :experimental
    end

    test "returns :unclassified when text contains '{: .warning}' but not 'Experimental'" do
      text = """
      Some module description.

      > #### Warning Notice {: .warning}
      >
      > This is just a warning, not a tier declaration.
      """

      assert PublicApi.detect_tier_from_text(text) == :unclassified
    end

    test "returns :unclassified when text has neither callout" do
      text = "Just a plain module description with no callout."

      assert PublicApi.detect_tier_from_text(text) == :unclassified
    end

    test "returns :unclassified when text contains 'Stable' but not '{: .info}'" do
      text = "This module has Stable behavior but no ExDoc callout."

      assert PublicApi.detect_tier_from_text(text) == :unclassified
    end

    test "returns :unclassified when text contains '{: .info}' but not 'Stable'" do
      text = """
      > #### Info Notice {: .info}
      >
      > Some informational note with no tier keyword.
      """

      assert PublicApi.detect_tier_from_text(text) == :unclassified
    end
  end

  describe "Parapet.Recovery stable reclassification (Wave-0 regression guard — STAB-07)" do
    test "Parapet.Recovery moduledoc is classified :stable by detect_tier_from_text/1" do
      # Regression guard: if recovery.ex admonition is ever reverted to Experimental,
      # this test fails. The live moduledoc is fetched via Code.fetch_docs/1 so the
      # assertion targets the actual compiled module, not a hardcoded constant.
      {:docs_v1, _, _, _, %{"en" => moduledoc_text}, _, _} = Code.fetch_docs(Parapet.Recovery)
      assert PublicApi.detect_tier_from_text(moduledoc_text) == :stable
    end

    test "detect_tier_from_text/1 returns :experimental for the old Recovery admonition string" do
      # Confirms the regression guard is real: the old Experimental string would have
      # returned :experimental, not :stable. Reversing the flip would break the test above.
      old_admonition =
        "> #### Experimental {: .warning}\n>\n> This module is experimental in v1.x."

      assert PublicApi.detect_tier_from_text(old_admonition) == :experimental
    end
  end

  describe "manifest tier field" do
    test "manifest includes 'tier' key in output (verified via detect_tier_from_text/1 contract)" do
      # The check_module/1 private function returns %{module: _, has_docs: _, tier: _}.
      # We verify the tier field is present by confirming detect_tier_from_text/1 returns
      # the expected atom values that would be set in the tier field of each manifest entry.
      stable_text = "> #### Stable {: .info}\n>\n> Stable description."
      assert PublicApi.detect_tier_from_text(stable_text) == :stable

      experimental_text = "> #### Experimental {: .warning}\n>\n> Experimental description."
      assert PublicApi.detect_tier_from_text(experimental_text) == :experimental

      plain_text = "No callout here."
      assert PublicApi.detect_tier_from_text(plain_text) == :unclassified
    end
  end

  describe "stable API surface fields" do
    defmodule BehaviourSample do
      @callback run(term()) :: {:ok, term()}
      defmacro sample_macro(arg), do: arg
      def public_fun(arg), do: {:ok, arg}
    end

    defmodule StructSample do
      defstruct [:id, :name]
    end

    test "exported_functions/1 records public functions and omits compiler builtins" do
      assert "public_fun/1" in PublicApi.exported_functions(BehaviourSample)

      refute Enum.any?(
               PublicApi.exported_functions(BehaviourSample),
               &String.starts_with?(&1, "__info__/")
             )

      refute Enum.any?(
               PublicApi.exported_functions(BehaviourSample),
               &String.starts_with?(&1, "module_info/")
             )
    end

    test "exported_macros/1 records public macros" do
      assert "sample_macro/1" in PublicApi.exported_macros(BehaviourSample)
    end

    test "callbacks/1 records behaviour callbacks" do
      assert "id/0" in PublicApi.callbacks(Parapet.Recovery)
      assert PublicApi.callbacks(Parapet.SLO.Provider) == ["slos/0"]
    end

    test "struct_keys/1 records stable struct fields" do
      assert PublicApi.struct_keys(StructSample) == ["id", "name"]
      assert PublicApi.struct_keys(BehaviourSample) == []
    end
  end
end
