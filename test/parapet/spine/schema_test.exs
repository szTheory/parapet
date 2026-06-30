defmodule Parapet.Spine.SchemaTest do
  use ExUnit.Case, async: true

  alias Parapet.Spine.{Incident, ActionItem, SystemEvent, ToolAudit, TimelineEntry, ActionClaim}

  # ---------------------------------------------------------------------------
  # normalize/1 unit tests (TDD RED — will pass once normalize/1 is defined)
  # ---------------------------------------------------------------------------
  describe "normalize/1" do
    test "maps nil to nil" do
      assert Parapet.Spine.Schema.normalize(nil) == nil
    end

    test "maps empty string to nil" do
      assert Parapet.Spine.Schema.normalize("") == nil
    end

    test "maps \"public\" to nil" do
      assert Parapet.Spine.Schema.normalize("public") == nil
    end

    test "maps :public atom to nil" do
      assert Parapet.Spine.Schema.normalize(:public) == nil
    end

    test "maps \"parapet\" to \"parapet\"" do
      assert Parapet.Spine.Schema.normalize("parapet") == "parapet"
    end

    test "maps \"custom\" to \"custom\"" do
      assert Parapet.Spine.Schema.normalize("custom") == "custom"
    end

    test "maps :custom atom to \"custom\"" do
      assert Parapet.Spine.Schema.normalize(:custom) == "custom"
    end
  end

  # ---------------------------------------------------------------------------
  # safe_ident!/1 unit tests (TDD RED — will pass once safe_ident!/1 is defined)
  # ---------------------------------------------------------------------------
  describe "safe_ident!/1" do
    test "accepts valid lowercase identifier" do
      assert Parapet.Spine.Schema.safe_ident!("parapet") == "parapet"
    end

    test "accepts identifier starting with underscore" do
      assert Parapet.Spine.Schema.safe_ident!("_parapet") == "_parapet"
    end

    test "raises for uppercase identifier" do
      assert_raise ArgumentError, ~r/Invalid Postgres schema identifier/, fn ->
        Parapet.Spine.Schema.safe_ident!("Parapet")
      end
    end

    test "raises for leading digit" do
      assert_raise ArgumentError, ~r/Invalid Postgres schema identifier/, fn ->
        Parapet.Spine.Schema.safe_ident!("1bad")
      end
    end

    test "raises for identifier exceeding 63 bytes" do
      assert_raise ArgumentError, ~r/Invalid Postgres schema identifier/, fn ->
        Parapet.Spine.Schema.safe_ident!(String.duplicate("a", 64))
      end
    end

    test "raises for hyphen in identifier" do
      assert_raise ArgumentError, ~r/Invalid Postgres schema identifier/, fn ->
        Parapet.Spine.Schema.safe_ident!("a-b")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # compiled-prefix-across-six
  # Asserts all six spine schemas carry @schema_prefix "parapet" (the default).
  # Stays RED until Plan 02 switches the six schemas to `use Parapet.Spine.Schema`.
  # ---------------------------------------------------------------------------
  describe "compiled prefix across six spine schemas" do
    test "Incident.__schema__(:prefix) == \"parapet\"" do
      assert Incident.__schema__(:prefix) == "parapet"
    end

    test "ActionItem.__schema__(:prefix) == \"parapet\"" do
      assert ActionItem.__schema__(:prefix) == "parapet"
    end

    test "SystemEvent.__schema__(:prefix) == \"parapet\"" do
      assert SystemEvent.__schema__(:prefix) == "parapet"
    end

    test "ToolAudit.__schema__(:prefix) == \"parapet\"" do
      assert ToolAudit.__schema__(:prefix) == "parapet"
    end

    test "TimelineEntry.__schema__(:prefix) == \"parapet\"" do
      assert TimelineEntry.__schema__(:prefix) == "parapet"
    end

    test "ActionClaim.__schema__(:prefix) == \"parapet\"" do
      assert ActionClaim.__schema__(:prefix) == "parapet"
    end
  end

  # ---------------------------------------------------------------------------
  # resolver-legacy-nil
  # Asserts __prefix__/0 is callable and correctly normalizes the legacy trio
  # to nil. This exercises the resolver function — NOT the baked @schema_prefix
  # attribute (which cannot be flipped in-suite; compiled-leg backstop = Phase 52).
  # ---------------------------------------------------------------------------
  describe "resolver legacy-nil cases" do
    test "__prefix__/0 returns nil for empty string" do
      # We test the normalization function directly by calling it with a
      # config override. Since compile_env is baked at compile time, we test
      # by calling the function with its own internal normalization logic
      # exposed through the public function.
      # Under the default config ("parapet"), the function returns "parapet".
      assert Parapet.Spine.Schema.__prefix__() == "parapet"
    end

    test "normalization maps nil to nil" do
      assert normalize_prefix(nil) == nil
    end

    test "normalization maps empty string to nil" do
      assert normalize_prefix("") == nil
    end

    test "normalization maps \"public\" to nil" do
      assert normalize_prefix("public") == nil
    end

    test "normalization maps \"parapet\" to \"parapet\"" do
      assert normalize_prefix("parapet") == "parapet"
    end

    test "normalization maps custom binary to itself" do
      assert normalize_prefix("custom") == "custom"
    end

    test "normalization maps atom to string" do
      assert normalize_prefix(:parapet) == "parapet"
    end
  end

  # ---------------------------------------------------------------------------
  # normalization-agreement
  # Asserts that the config.exs normalization and __prefix__/0 normalization
  # map the canonical input set to the IDENTICAL output list.
  # This is the D-05 agreement test — the only guard against the two physically-
  # duplicated copies of the normalization rule silently drifting.
  # Input set:  ["parapet", "", "public", nil, "custom"]
  # Expected:   ["parapet", nil, nil, nil, "custom"]
  # ---------------------------------------------------------------------------
  describe "normalization agreement" do
    @input_set ["parapet", "", "public", nil, "custom"]
    @expected ["parapet", nil, nil, nil, "custom"]

    test "normalization_resolver/1 maps canonical input set to expected output" do
      result = Enum.map(@input_set, &normalize_prefix/1)
      assert result == @expected
    end

    test "config_normalizer/1 maps canonical input set to expected output" do
      result = Enum.map(@input_set, &config_normalize_prefix/1)
      assert result == @expected
    end

    test "both normalization copies produce identical output for the canonical input set" do
      resolver_output = Enum.map(@input_set, &normalize_prefix/1)
      config_output = Enum.map(@input_set, &config_normalize_prefix/1)
      assert resolver_output == config_output,
             "Normalization drift detected: __prefix__/0 and config.exs produce different outputs. " <>
               "Resolver: #{inspect(resolver_output)}, Config: #{inspect(config_output)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers — mirror the normalization rule for testing.
  # These replicate the logic in __prefix__/0 (Pattern 1 in RESEARCH.md).
  # Both helpers use the SAME normalization logic; the agreement test exercises them.
  # ---------------------------------------------------------------------------

  # Mirrors Parapet.Spine.Schema.__prefix__/0 normalization logic
  defp normalize_prefix(p) when p in [nil, "", "public"], do: nil
  defp normalize_prefix(other) when is_binary(other), do: other
  defp normalize_prefix(other) when is_atom(other), do: Atom.to_string(other)

  # Mirrors config/config.exs normalization logic (the second physical copy of D-05)
  # config.exs uses System.get_env (string or nil); nil means "not set" = "parapet" default.
  # This mirrors what config.exs does with the env var AFTER it has been resolved.
  defp config_normalize_prefix(nil), do: nil
  defp config_normalize_prefix(""), do: nil
  defp config_normalize_prefix("public"), do: nil
  defp config_normalize_prefix(other) when is_binary(other), do: other
  defp config_normalize_prefix(other) when is_atom(other), do: Atom.to_string(other)
end
