defmodule NewRelic.Instrumentation.Decorators do
  use Decorator.Define, [transaction_event: 0, transaction_event: 1]

  @doc false
  def transaction_event(body, context) do
    decorate_event(:event, body, context)
  end
  def transaction_event(type, body, context) do
    decorate_event(type, body, context)
  end

  defp decorate_event(type, body, %{module: mod, name: name, args: [conn|_]}) do
    quote do
      NewRelic.Instrumentation.instrument(
        unquote(conn),
        unquote(type),
        unquote("#{mod}.#{name}"),
        fn -> unquote(body) end)
    end
  end
end
