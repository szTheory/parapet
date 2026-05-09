defmodule Parapet.Internal.LabelPolicy do
  @moduledoc false

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
end
