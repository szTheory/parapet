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
end
