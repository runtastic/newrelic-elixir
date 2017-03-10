defmodule NewRelic.TransactionTest do
  use ExUnit.Case, async: false
  import TestHelpers.Assertions

  alias NewRelic.Transaction

  setup do
    [name: "Test Transaction"]
  end

  # finish

  test "finish records elapsed time with correct key", context do
    transaction = Transaction.start(context[:name])
    Transaction.finish(transaction)

    assert_contains(get_metric_keys(), {context[:name], :total})
  end

  test "finish records accurate elapsed time", context do
    {_, elapsed_time} = :timer.tc(fn() ->
      transaction = Transaction.start(context[:name])
      :ok = :timer.sleep(42)
      Transaction.finish(transaction)
    end)

    [recorded_time] = get_metric_by_key({context[:name], :total})
    assert_between(recorded_time, 42000, elapsed_time)
  end

  describe "record :event" do
    setup context do
      Map.merge(context, %{elapsed: 242, event: "SomeModule.methodname"})
    end

    test "record_db records query time with correct key when given a string", context do
      transaction = Transaction.start(context[:name])
      Transaction.record(transaction, :event, context[:event], context[:elapsed])

      assert_contains(get_metric_keys(), {context[:name], {:event, context[:event]}})
    end

    test "record_db records accurate query time when given a string", context do
      transaction = Transaction.start(context[:name])
      Transaction.record(transaction, :event, context[:event], context[:elapsed])

      [recorded_time] = get_metric_by_key({context[:name], {:event, context[:event]}})

      assert recorded_time == context[:elapsed]
    end
  end
  describe "record :db" do
    setup context do
      Map.merge(context, %{elapsed: 42, query: "FooBar"})
    end

    test "record_db records query time with correct key when given a string", context do
      transaction = Transaction.start(context[:name])
      Transaction.record(transaction, :db, context[:query], context[:elapsed])

      assert_contains(get_metric_keys(), {context[:name], {:db, context[:query]}})
    end

    test "record_db records accurate query time when given a string", context do
      transaction = Transaction.start(context[:name])
      Transaction.record(transaction, :db, context[:query], context[:elapsed])

      [recorded_time] = get_metric_by_key({context[:name], {:db, context[:query]}})

      assert recorded_time == context[:elapsed]
    end
  end
end
