defmodule NewRelic.Instrumentation do
  import NewRelic.Instrumentation.Helper

  @doc """
  Instruments the given function

  Records the time the provided function takes to execute with the given event
  type and name.

  the time elapsed is associated to the transaction provided directly or
  extracted from the plug connection
  """
  @spec instrument(Plug.Conn.t | NewRelic.Transaction.t, NewRelic.Transaction.event_type, String.t, fun()) :: any()
  def instrument(%Plug.Conn{} = conn, type, name, function) do
    conn
    |> get_transaction_from_conn
    |> instrument(type, name, function)
  end

  def instrument(%NewRelic.Transaction{} = transaction, type, name, function) do
    {elapsed, result} = :timer.tc(function)

    NewRelic.Transaction.record(transaction, type, name, elapsed)
    result
  end
  def instrument(_,_,_,fun), do: fun.()
end
