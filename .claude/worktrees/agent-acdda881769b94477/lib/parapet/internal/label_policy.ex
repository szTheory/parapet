defmodule Parapet.Internal.LabelPolicy do
  @moduledoc false

  alias Parapet.Telemetry.AsyncDelivery

  def assert_safe!(labels) do
    Enum.each(labels, fn label ->
      label_str = to_string(label)

      if label_str =~ ~r/id$/ or label_str =~ ~r/^raw_/ or label_str =~ ~r/token/ or
           label_str =~ ~r/path/ do
        raise ArgumentError, "High cardinality label rejected by Parapet safety policy: #{label}"
      end
    end)

    :ok
  end

  def assert_family_keys!(family, labels) do
    allowed_keys = AsyncDelivery.allowed_public_keys(family)

    Enum.each(labels, fn label ->
      label
      |> normalize_key()
      |> validate_family_key!(family, allowed_keys)
    end)

    :ok
  end

  defp validate_family_key!(key, family, allowed_keys) do
    cond do
      high_cardinality_key?(key) ->
        raise ArgumentError,
              "High cardinality label rejected by Parapet safety policy: #{key}"

      key not in allowed_keys ->
        raise ArgumentError,
              "Unsupported public metadata key #{inspect(key)} for #{inspect(family)}"

      true ->
        :ok
    end
  end

  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key) when is_binary(key), do: String.to_atom(key)

  defp high_cardinality_key?(label) do
    label_str = to_string(label)

    label_str =~ ~r/id$/ or label_str =~ ~r/^raw_/ or label_str =~ ~r/token/ or
      label_str =~ ~r/path/
  end
end
