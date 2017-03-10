defmodule NewRelic.Transaction do
  @moduledoc """
  Records information about an instrumented web transaction.
  """

  defstruct [:name, :start_time]

  @typedoc "A New Relixir transaction context."
  @opaque t :: %__MODULE__{name: String.t, start_time: :erlang.timestamp}

  @typedoc "The name of a query."
  @type query :: String.t

  @typedoc "Elapsed time in microseconds."
  @type interval :: non_neg_integer

  @typedoc "Event types that can be recorded"
  @type event_type :: :event | :db | :error | :ext

  @doc """
  Creates a new web transaction.

  This method should be called just before processing a web transaction.
  """
  @spec start(String.t) :: t
  def start(name) when is_binary(name) do
    %__MODULE__{name: name, start_time: :os.timestamp}
  end

  @doc """
  Updates the name of an existing transaction

  This method allows you to specify the name of a transaction after start to
  facilitate the use case where the transaction name is not known at start time.
  """
  @spec update_name(t, String.t) :: t
  def update_name(transaction, new_name) do
    %{transaction | name: new_name}
  end

  @doc """
  Finishes a web transaction.

  This method should be called just after processing a web transaction. It will record the elapsed
  time of the transaction.
  """
  @spec finish(t) :: :ok
  def finish(%__MODULE__{name: name, start_time: start_time}) do
    end_time = :os.timestamp
    elapsed = :timer.now_diff(end_time, start_time)

    NewRelic.Collector.record_value(name, :total, elapsed)
  end

  @spec record(t, event_type, String.t, interval | String.t) :: any
  def record(%__MODULE__{name: name}, type, payload, elapsed) when type in [:event, :db, :ext] do
    NewRelic.Collector.record_value(name, {type, payload}, elapsed)
  end
  def record(%__MODULE__{name: name}, :error, type, error) do
    NewRelic.Collector.record_error(name, {type, error})
  end
end
