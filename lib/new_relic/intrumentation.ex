defmodule NewRelic.Instrumentation do
  import NewRelic.Instrumentation.Helper
  alias NewRelic.{TransactionEvent,TransactionError}

  @doc """
  Instruments the given function

  Records the time the provided function takes to execute with the given event
  category and segment.

  the time elapsed is associated to the transaction provided directly or
  extracted from the plug connection
  """
  @spec instrument(Plug.Conn.t | NewRelic.Transaction.t, atom(), String.t, fun()) :: any()
  def instrument(%Plug.Conn{} = conn, category, segment, function) do
    conn
    |> get_transaction_from_conn
    |> instrument(category, segment, function)
  end

  def instrument(%NewRelic.Transaction{} = transaction, category, segment, function) do
    {elapsed, result} = :timer.tc(function)

    NewRelic.Transaction.record(transaction, %TransactionEvent{category: category, segment: segment}, elapsed)
    result
  end
  def instrument(_,_,_,fun), do: fun.()


  @spec error(Plug.Conn.t | NewRelic.Transaction.t, String.t, String.t, list(String.t)) :: any()
  def error(conn_or_transaction, name, msg, stack_trace \\ [])
  def error(nil,_,_,_), do: nil
  def error(%Plug.Conn{}=conn, name, msg, stack_trace) do
    conn
    |> get_transaction_from_conn
    |> error(name, msg, stack_trace)
  end
  def error(%NewRelic.Transaction{} = transaction, name, msg, stack_trace) do
    NewRelic.Transaction.record(transaction, %TransactionError{name: name, message: msg, stack_trace: stack_trace} )
  end
end
