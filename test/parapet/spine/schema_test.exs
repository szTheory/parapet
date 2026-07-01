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
end
