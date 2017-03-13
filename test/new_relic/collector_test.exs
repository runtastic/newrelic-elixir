defmodule NewRelic.CollectorTest do
  use ExUnit.Case, async: false

  alias NewRelic.{Collector,TransactionError,TransactionEvent}

  setup do
    Collector.poll # to empty the current state
    [transaction_name: "meh"]
  end

  describe ".poll" do
    test "start_time and end_time" do
      interval = 20
      Collector.poll
      :timer.sleep(interval)
      [end_time, start_time, _, _] = Collector.poll
      assert_in_delta end_time - start_time, interval, 2
    end
  end

  describe ".record_error" do
    test "single error", c do
      error = %TransactionError{name: "Not Found", message: "route not found"}

      Collector.record_error(c[:transaction_name], error)

      [_end_time, _start_time, _metrics, collected_errors] = Collector.poll
      assert %{{c[:transaction_name], error} => 1} == collected_errors
    end

    test "single error multiple times", c do
      error = %TransactionError{name: "Not Found", message: "route not found"}

      Collector.record_error(c[:transaction_name], error)
      Collector.record_error(c[:transaction_name], error)
      Collector.record_error(c[:transaction_name], error)

      [_end_time, _start_time, _metrics, collected_errors] = Collector.poll
      assert %{{c[:transaction_name], error} => 3} == collected_errors
    end

    test "multiple errors", c do
      error1 = %TransactionError{name: "Not Found", message: "route not found", stack_trace: ["line1", "line2"]}
      error2 = %TransactionError{name: "Forbidden", message: "user authentication failed"}

      Collector.record_error(c[:transaction_name], error1)
      Collector.record_error(c[:transaction_name], error2)
      Collector.record_error(c[:transaction_name], error2)

      [_end_time, _start_time, _metrics, collected_errors] = Collector.poll
      assert %{
        {c[:transaction_name], error1} => 1,
        {c[:transaction_name], error2} => 2
      } == collected_errors
    end
  end

  describe ".record_value" do
    test "single event", c do
      event = %TransactionEvent{category: :event, segment: "Some.Module.function"}
      key = TransactionEvent.to_key(event)

      Collector.record_value(c[:transaction_name], event, 50)

      [_end_time, _start_time, collected_metrics, _errors] = Collector.poll
      assert %{{c[:transaction_name], key} => [50]} == collected_metrics
    end

    test "single event multiple times", c do
      event = %TransactionEvent{category: :event, segment: "Some.Module.function"}
      key = TransactionEvent.to_key(event)

      Collector.record_value(c[:transaction_name], event, 50)
      Collector.record_value(c[:transaction_name], event, 48)
      Collector.record_value(c[:transaction_name], event, 33)

      [_end_time, _start_time, collected_metrics, _errors] = Collector.poll
      assert %{{c[:transaction_name], key} => [33, 48, 50]} == collected_metrics
    end

    test "multiple events", c do
      event1 = %TransactionEvent{category: :event, segment: "Some.Module.function"}
      key1 = TransactionEvent.to_key(event1)
      event2 = %TransactionEvent{category: :db, segment: "SELECT * from users;"}
      key2 = TransactionEvent.to_key(event2)

      Collector.record_value(c[:transaction_name], event1, 50)
      Collector.record_value(c[:transaction_name], event2, 248)
      Collector.record_value(c[:transaction_name], event1, 33)
      Collector.record_value(c[:transaction_name], event2, 198)
      Collector.record_value(c[:transaction_name], event2, 253)

      [_end_time, _start_time, collected_metrics, _errors] = Collector.poll
      assert %{
        {c[:transaction_name], key1} => [33, 50],
        {c[:transaction_name], key2} => [253, 198, 248]
      } == collected_metrics
    end

    test "without segment", c do
      event1 = %TransactionEvent{category: :event, segment: "Some.Module.function"}
      key = TransactionEvent.to_key(event1)
      event2 = %TransactionEvent{category: :total}

      Collector.record_value(c[:transaction_name], event1, 50)
      Collector.record_value(c[:transaction_name], event2, 248)
      Collector.record_value(c[:transaction_name], event1, 33)
      Collector.record_value(c[:transaction_name], event2, 198)
      Collector.record_value(c[:transaction_name], event2, 253)

      [_end_time, _start_time, collected_metrics, _errors] = Collector.poll
      assert %{
        {c[:transaction_name], key} => [33, 50],
        {c[:transaction_name], :total} => [253, 198, 248]
      } == collected_metrics
    end
  end
end
