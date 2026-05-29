defmodule Mix.Tasks.Parapet.Gen.Recovery do
  @moduledoc """
  Generates a host-owned recovery action module for Parapet.

  The generated module implements the `Parapet.Recovery` behaviour with the four frozen
  callbacks (`id/0`, `label/0`, `preview/2`, `execute/2`) and a docstring template for the
  adopter to fill in.

  A companion unit-test stub is also scaffolded alongside the module.
  """
  use Igniter.Mix.Task

  @example "mix parapet.gen.recovery <NAME>"
  @shortdoc "Generates a host-owned recovery action module"

  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :parapet,
      example: @example,
      positional: [:name]
    }
  end

  def igniter(igniter) do
    name = igniter.args.positional.name

    web_module = Igniter.Libs.Phoenix.web_module(igniter)
    app_name = Igniter.Project.Application.app_name(igniter)

    base_name = web_module |> inspect() |> String.trim_trailing("Web")
    module_prefix = Module.concat([base_name, "Parapet", "Recovery"])

    lib_dir = Path.join(["lib", "#{app_name}", "parapet", "recovery"])

    name_camelized = Macro.camelize(name)
    name_underscored = Macro.underscore(name)

    assigns = %{
      module_prefix: module_prefix,
      app_name: app_name,
      name_camelized: name_camelized,
      name_underscored: name_underscored
    }

    test_stub_content = """
    defmodule #{inspect(module_prefix)}.#{name_camelized}Test do
      use ExUnit.Case, async: true

      alias #{inspect(module_prefix)}.#{name_camelized}

      describe "#{inspect(module_prefix)}.#{name_camelized}" do
        test "id/0 returns an atom" do
          assert is_atom(#{name_camelized}.id())
        end

        test "label/0 returns a string" do
          assert is_binary(#{name_camelized}.label())
        end

        test "preview/2 returns {:ok, _}" do
          assert {:ok, _} = #{name_camelized}.preview(%{}, %{})
        end

        test "execute/2 returns {:ok, _}" do
          assert {:ok, _} = #{name_camelized}.execute(%{}, [])
        end
      end
    end
    """

    igniter
    |> Igniter.copy_template(
      Path.join([
        :code.priv_dir(:parapet),
        "templates",
        "parapet.gen.recovery",
        "recovery.ex.eex"
      ]),
      Path.join([lib_dir, "#{name_underscored}.ex"]),
      assigns,
      on_exists: :skip
    )
    |> Igniter.create_new_file(
      Path.join(["test", "#{app_name}", "parapet", "recovery", "#{name_underscored}_test.exs"]),
      test_stub_content,
      on_exists: :skip
    )
    |> Igniter.add_notice("""
    Parapet recovery module generated at `#{lib_dir}/#{name_underscored}.ex`.
    Fill in the capability atom in `id/0` (must be one of the 5 allowlisted atoms),
    customize `preview/2` to return the preview map, and `execute/2` to perform the mutation.
    Register via `Parapet.Recovery.attach/1` in your application start.
    """)
  end
end
