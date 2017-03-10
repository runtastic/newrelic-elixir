defmodule NewRelic.Instrumentation.Helper do
  @transaction_key :new_relic_transaction

  def update_transaction_name(%Plug.Conn{}=conn, name) do
    conn
    |> get_transaction_from_conn
    |> NewRelic.Transaction.update_name(name)
    |> save_transaction_to_conn(conn)
  end

  def get_transaction_from_conn(conn) do
    Map.get(conn.private, @transaction_key)
  end

  def save_transaction_to_conn(transaction, conn) do
    conn
    |> Plug.Conn.put_private(@transaction_key, transaction)
  end
end
