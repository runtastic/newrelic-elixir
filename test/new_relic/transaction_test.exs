defmodule NewRelic.TransactionTest do
  use ExUnit.Case, async: false
  import TestHelpers.Assertions

  alias NewRelic.{Transaction,TransactionEvent,TransactionError}

  setup do
    [name: "Test Transaction"]
  end

  describe ".start" do
    test "creates a transaction struct with start_time set to now" do
      transaction = Transaction.start("some_name")
      assert "some_name" = transaction.name
      assert_in_delta(:os.system_time(:micro_seconds), transaction.start_time, 50) # within 50 microsecond
    end
  end

  describe ".finish" do
    test "records elapsed time with correct key", context do
      transaction = Transaction.start(context[:name])
      Transaction.finish(transaction)

      assert_contains(get_metric_keys(), {context[:name], :total})
    end

    test "records accurate elapsed time", context do
      {elapsed_time, _} = :timer.tc(fn() ->
        transaction = Transaction.start(context[:name])
        :ok = :timer.sleep(42)
        Transaction.finish(transaction)
      end)

      [recorded_time] = get_metric_by_key({context[:name], :total})
      assert_in_delta(recorded_time, elapsed_time, 50) # within 50 microseconds
    end
  end

  describe ".record :event" do
    setup context do
      Map.merge(context, %{elapsed: 242, event: "SomeModule.methodname"})
    end

    test "elapsed time with correct key", context do
      transaction = Transaction.start(context[:name])
      Transaction.record(transaction,
        %TransactionEvent{category: :event, segment: context[:event]},
        context[:elapsed]
      )

      assert_contains(get_metric_keys(), {context[:name], {:event, context[:event]}})
    end

    test "with accurate elapsed time", context do
      transaction = Transaction.start(context[:name])
      Transaction.record(transaction,
        %TransactionEvent{category: :event, segment: context[:event]},
        context[:elapsed]
      )

      [recorded_time] = get_metric_by_key({context[:name], {:event, context[:event]}})

      assert recorded_time == context[:elapsed]
    end
  end

  describe ".record :db" do
    setup context do
      Map.merge(context, %{elapsed: 42, query: "FooBar"})
    end

    test "query time with correct key when given a string", context do
      transaction = Transaction.start(context[:name])
      Transaction.record(transaction,
        %TransactionEvent{category: :db, segment: context[:query]},
        context[:elapsed]
      )

      assert_contains(get_metric_keys(), {context[:name], {:db, context[:query]}})
    end

    test "accurate query time when given a string", context do
      transaction = Transaction.start(context[:name])
      Transaction.record(transaction,
        %TransactionEvent{category: :db, segment: context[:query]},
        context[:elapsed]
      )

      [recorded_time] = get_metric_by_key({context[:name], {:db, context[:query]}})

      assert recorded_time == context[:elapsed]
    end
  end
end
