defmodule NewRelic.TransactionEvent do
  @moduledoc """
  Records information about an event
  """

  @typedoc "Elapsed time in microseconds."
  @type interval :: non_neg_integer

  defstruct [:category, :segment]

  @typedoc "A New Relixir transaction context."
  @opaque t :: %__MODULE__{category: atom(),
                           segment: String.t}

  def to_key(%__MODULE__{category: category, segment: nil}), do: category
  def to_key(%__MODULE__{category: category, segment: segment}), do: {category, segment}

  def from_key({category, segment}) do
    %__MODULE__{category: category, segment: segment}
  end
end
