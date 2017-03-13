defmodule NewRelic.Collector do
  use GenServer
  @name __MODULE__
  @default_state [%{}, %{}]
  @type state :: nonempty_improper_list(pos_integer, map())

  def start_link(_opts \\ []) do
    GenServer.start_link(@name, [current_time() | @default_state], name: @name)
  end

  alias NewRelic.{TransactionEvent,TransactionError}

  @spec record_value(String.t, TransactionEvent.t, non_neg_integer()) :: nil
  def record_value(transaction_name, %TransactionEvent{}=event, elapsed) do
    GenServer.cast(@name, {:record_value, {transaction_name, TransactionEvent.to_key(event)}, elapsed})
  end

  @spec record_error(String.t, TransactionError.t) :: nil
  def record_error(transaction_name, %TransactionError{}=error) do
    GenServer.cast(@name, {:record_error, {transaction_name, error}})
  end

  @spec poll() :: state
  def poll do
    GenServer.call(@name, :poll)
  end

  def handle_cast({:record_value, key, time}, [start_time, metrics, errors]) do
    metrics = Map.update(metrics, key, [time], &([time | &1]))
    {:noreply, [start_time, metrics, errors]}
  end

  def handle_cast({:record_error, key}, [start_time, metrics, errors]) do
    errors = Map.update(errors, key, 1, &(1 + &1))
    {:noreply, [start_time, metrics, errors]}
  end

  def handle_call(:poll, _from, state) do
    time = current_time()
    {:reply, [time | state], [time | @default_state]}
  end

  defp current_time do
    :os.system_time(:milli_seconds)
  end
end
