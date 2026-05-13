defprotocol Parapet.SLO.Resolvable do
  @moduledoc """
  Protocol to transform provider structs to `Parapet.SLO.t()`.
  """
  
  @fallback_to_any true
  
  @spec to_slo(t) :: Parapet.SLO.t()
  def to_slo(struct)
end

defimpl Parapet.SLO.Resolvable, for: Parapet.SLO do
  def to_slo(slo), do: slo
end

defimpl Parapet.SLO.Resolvable, for: Any do
  def to_slo(struct) do
    raise Protocol.UndefinedError,
      protocol: @protocol,
      value: struct,
      description: "Parapet.SLO.Resolvable protocol must always be implemented for custom SLO structs"
  end
end