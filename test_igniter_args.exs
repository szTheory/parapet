defmodule TestIgniter do
  use Igniter.Mix.Task
  def info(_argv, _) do
    %Igniter.Mix.Task.Info{schema: [with_sigra: :boolean], defaults: [with_sigra: false]}
  end
  def igniter(igniter) do
    IO.inspect(igniter.args.options)
    igniter
  end
end
