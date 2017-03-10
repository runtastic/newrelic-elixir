defmodule NewRelic.Instrumentation.Plug do
  @moduledoc """

  """

  @behaviour Plug
  import Plug.Conn
  import NewRelic.Instrumentation.Helper

  def init(opts) do
    Keyword.get(opts, :name, "plug")
  end

  def call(%Plug.Conn{}=conn, default_transaction_name) do
    default_transaction_name
    |> NewRelic.Transaction.start
    |> save_transaction_to_conn(conn)
    |> register_before_send(fn(conn) ->
      conn
      |> get_transaction_from_conn
      |> NewRelic.Transaction.finish
      conn
    end)
  end
end
