defmodule TestHelpers.Assertions do
  import ExUnit.Assertions

  def assert_contains(collection, value) do
    assert Enum.member?(collection, value), "expected #{inspect(collection)} to contain #{inspect(value)}"
  end

  def get_metric_keys() do
    [_, _, metrics, _] = NewRelic.Collector.poll
    Map.keys(metrics)
  end
  def get_metric_by_key(key) do
    [_, _, metrics, _] = NewRelic.Collector.poll
    metrics[key]
  end
end
