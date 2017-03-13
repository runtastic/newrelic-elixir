defmodule NewRelic.TransactionError do
  @moduledoc """
  Records information about an error
  """

  defstruct [:name, :message, :stack_trace]

  @typedoc "A New Relixir transaction context."
  @opaque t :: %__MODULE__{name: String.t,
                           message: String.t,
                           stack_trace: list(String.t)}
end
