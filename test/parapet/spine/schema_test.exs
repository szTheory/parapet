defmodule Parapet.Spine.SchemaTest do
  use ExUnit.Case, async: true

  alias Parapet.Spine.{Incident, ActionItem, SystemEvent, ToolAudit, TimelineEntry, ActionClaim}

  @compiled_prefix Parapet.Spine.Schema.__prefix__()

  # ---------------------------------------------------------------------------
  # normalize/1 unit tests
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
  # safe_ident!/1 unit tests
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
  # Asserts all six spine schemas carry identical __schema__(:prefix) equal to
  # Schema.__prefix__(). Runs unconditionally on both parapet and public legs.
  # ---------------------------------------------------------------------------
  describe "compiled prefix across six spine schemas" do
    test "Incident.__schema__(:prefix) matches compiled prefix" do
      assert Incident.__schema__(:prefix) == @compiled_prefix
    end

    test "ActionItem.__schema__(:prefix) matches compiled prefix" do
      assert ActionItem.__schema__(:prefix) == @compiled_prefix
    end

    test "SystemEvent.__schema__(:prefix) matches compiled prefix" do
      assert SystemEvent.__schema__(:prefix) == @compiled_prefix
    end

    test "ToolAudit.__schema__(:prefix) matches compiled prefix" do
      assert ToolAudit.__schema__(:prefix) == @compiled_prefix
    end

    test "TimelineEntry.__schema__(:prefix) matches compiled prefix" do
      assert TimelineEntry.__schema__(:prefix) == @compiled_prefix
    end

    test "ActionClaim.__schema__(:prefix) matches compiled prefix" do
      assert ActionClaim.__schema__(:prefix) == @compiled_prefix
    end

    # Cross-leg equality: all six schemas must carry the same prefix as Schema.__prefix__()
    # Runs unconditionally on both parapet and public CI legs (all "parapet" or all nil).
    test "all six schemas carry the same __schema__(:prefix) (cross-leg equality)" do
      prefix = Parapet.Spine.Schema.__prefix__()

      for mod <- [Incident, ActionItem, SystemEvent, ToolAudit, TimelineEntry, ActionClaim] do
        assert mod.__schema__(:prefix) == prefix,
               "#{mod}.__schema__(:prefix) #{inspect(mod.__schema__(:prefix))} " <>
                 "!= Schema.__prefix__() #{inspect(prefix)}"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # resolver-legacy-nil
  # Asserts __prefix__/0 is callable and normalizes correctly.
  # Guard: these tests pin the "absence = default" contract and only apply
  # when the compiled prefix IS "parapet" (i.e. the parapet CI leg).
  # ---------------------------------------------------------------------------
  describe "resolver legacy-nil cases" do
    if @compiled_prefix == "parapet" do
      test "__prefix__/0 returns \"parapet\" under the default config" do
        # Under the default config ("parapet"), the function returns "parapet".
        assert Parapet.Spine.Schema.__prefix__() == "parapet"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # normalization-agreement (WR-01)
  # Drives production code (Schema.normalize/1) — no test-local mirror functions.
  # Input set includes :public to cover atom normalization (IN-01 fix).
  # ---------------------------------------------------------------------------
  describe "normalization agreement" do
    @input_set ["parapet", "", "public", nil, "custom", :public]
    @expected ["parapet", nil, nil, nil, "custom", nil]

    test "Schema.normalize/1 maps canonical input set to expected output" do
      result = Enum.map(@input_set, &Parapet.Spine.Schema.normalize/1)
      assert result == @expected
    end

    test "Evidence.schema_prefix/0 returns the same value as Schema.__prefix__()" do
      assert Parapet.Evidence.schema_prefix() == Parapet.Spine.Schema.__prefix__()
    end
  end

  # ---------------------------------------------------------------------------
  # WR-02: Asymmetry pinned with explicit tests
  # "absence = default" (unset env → "parapet") vs "explicit nil = off" (nil → nil)
  # The "absence = default" pinned test is only meaningful when compiled with the
  # default "parapet" prefix — guard it so it does not fail on the public leg.
  # ---------------------------------------------------------------------------
  describe "WR-02 normalization asymmetry" do
    if @compiled_prefix == "parapet" do
      test "unset env normalizes toward \"parapet\" default (Schema.__prefix__() under default config)" do
        # Under the default compile_env configuration ("parapet"), __prefix__() returns "parapet".
        # This pinned test documents the "absence = default" contract.
        assert Parapet.Spine.Schema.__prefix__() == "parapet"
      end
    end

    test "normalize(nil) returns nil — explicit nil means unprefixed" do
      # This pinned test documents the "explicit nil = off" contract.
      assert Parapet.Spine.Schema.normalize(nil) == nil
    end
  end

  # ---------------------------------------------------------------------------
  # resolve_prefix/2 (pure core) — GEN-05 one shared resolver, GEN-03 conflict contract
  #
  # Tests call the pure core (flag, config) → {:ok, normalized} | {:conflict, nf, nc}
  # directly. No Igniter scaffolding, no Application.put_env — per D-05 and Pitfall 5.
  # ---------------------------------------------------------------------------
  describe "resolve_prefix/2 (pure core)" do
    alias Parapet.Spine.Schema

    # ── Precedence: default (both absent) ──────────────────────────────────
    test "nil flag + nil config → {:ok, \"parapet\"} (default)" do
      assert Schema.resolve_prefix(nil, nil) == {:ok, "parapet"}
    end

    # ── Precedence: flag wins over absent config ────────────────────────────
    test "flag only → {:ok, normalized_flag}" do
      assert Schema.resolve_prefix("custom", nil) == {:ok, "custom"}
    end

    # ── Precedence: config fallback when flag absent ────────────────────────
    test "nil flag + existing config → {:ok, config}" do
      assert Schema.resolve_prefix(nil, "custom") == {:ok, "custom"}
    end

    # ── Precedence: agreement → {:ok, value} ───────────────────────────────
    test "flag == config → {:ok, flag} (agreement, no conflict)" do
      assert Schema.resolve_prefix("parapet", "parapet") == {:ok, "parapet"}
    end

    # ── Nil/legacy leg: normalize maps \"public\"/\"\"/nil → nil ──────────────
    test "\"public\" flag normalizes to nil → {:ok, nil} (treats as absent)" do
      # normalize("public") == nil, treated as absent flag; config is also nil
      assert Schema.resolve_prefix("public", nil) == {:ok, "parapet"}
    end

    test "\"\" (empty string) flag normalizes to nil → default when config absent" do
      assert Schema.resolve_prefix("", nil) == {:ok, "parapet"}
    end

    test "nil flag + \"public\" config normalizes config to nil → default" do
      assert Schema.resolve_prefix(nil, "public") == {:ok, "parapet"}
    end

    test "nil flag + \"\" config normalizes config to nil → default" do
      assert Schema.resolve_prefix(nil, "") == {:ok, "parapet"}
    end

    test "\"public\" in flag position normalizes to nil, treated as absent" do
      # Both normalize to nil → default
      assert Schema.resolve_prefix("public", "public") == {:ok, "parapet"}
    end

    # ── Conflict path: flag ≠ config, both non-nil ─────────────────────────
    test "non-nil flag ≠ non-nil config → {:conflict, flag, config} (GEN-03: warns, does not crash)" do
      result = Schema.resolve_prefix("alpha", "beta")
      # Must return a conflict tuple, not raise
      assert result == {:conflict, "alpha", "beta"}
    end

    test "conflict path does not raise — explicit non-raising assertion" do
      result =
        try do
          Schema.resolve_prefix("alpha", "beta")
        rescue
          e -> {:raised, e}
        end

      assert match?({:conflict, _, _}, result),
             "Expected {:conflict, _, _}, got #{inspect(result)}"
    end

    test "conflict returns flag as first element (flag wins)" do
      {:conflict, normalized_flag, _normalized_config} = Schema.resolve_prefix("alpha", "beta")
      assert normalized_flag == "alpha"
    end

    test "conflict returns config as second element" do
      {:conflict, _normalized_flag, normalized_config} = Schema.resolve_prefix("alpha", "beta")
      assert normalized_config == "beta"
    end

    # ── safe_ident!/1 rejection: malformed identifiers raise ArgumentError ──
    test "malformed flag \"Bad-Name\" (hyphen + uppercase) raises ArgumentError" do
      assert_raise ArgumentError, ~r/Invalid Postgres schema identifier/, fn ->
        Schema.resolve_prefix("Bad-Name", nil)
      end
    end

    test "leading-digit flag \"1abc\" raises ArgumentError" do
      assert_raise ArgumentError, ~r/Invalid Postgres schema identifier/, fn ->
        Schema.resolve_prefix("1abc", nil)
      end
    end

    test "64-byte flag raises ArgumentError (exceeds 63 byte limit)" do
      assert_raise ArgumentError, ~r/Invalid Postgres schema identifier/, fn ->
        Schema.resolve_prefix(String.duplicate("a", 64), nil)
      end
    end

    test "malformed config raises ArgumentError before returning any result" do
      assert_raise ArgumentError, ~r/Invalid Postgres schema identifier/, fn ->
        Schema.resolve_prefix(nil, "Bad-Name")
      end
    end

    # ── Full precedence matrix scan ─────────────────────────────────────────
    # Covers the D-06 precedence table: flag > existing config > default "parapet"
    # "public", "", nil all normalize to nil (absent); "parapet", "custom" stay.
    test "precedence matrix: flag wins when both non-nil and disagree" do
      assert Schema.resolve_prefix("parapet", "custom") == {:conflict, "parapet", "custom"}
      assert Schema.resolve_prefix("custom", "parapet") == {:conflict, "custom", "parapet"}
    end

    test "precedence matrix: flag \"parapet\" with nil config → {:ok, \"parapet\"}" do
      assert Schema.resolve_prefix("parapet", nil) == {:ok, "parapet"}
    end

    test "precedence matrix: nil flag + \"parapet\" config → {:ok, \"parapet\"}" do
      assert Schema.resolve_prefix(nil, "parapet") == {:ok, "parapet"}
    end
  end
end
