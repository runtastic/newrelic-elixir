# Yet another NewRelic elixir agent

[![Build Status](https://travis-ci.org/runtastic/newrelic-elixir.svg?branch=master)](https://travis-ci.org/runtastic/newrelic-elixir)

Instrument your Elixir applications with New Relic.

This started of as a disconnected fork
of [newrelic.ex](https://github.com/romul/newrelic.ex) which itself is based
on [newrelic-erlang](https://github.com/wooga/newrelic-erlang) which somehow
reverse engineered the newrelic python agent.

## Why

Well the available solution in elixir are all bound to specific versions of
phoenix without any clear benefit also we were not happy with the way ecto was
instrumented.

While diving into [newrelic.ex][] and looking at some use-cases we also
discovered some issues with the translated code based on [newrelic-erlang][]. So
after a bit of studying we decided to only take the core of these libraries and
build the instrumentation logic and interface on top of it.

## Goals

- tracking of generic plug transactions
- tracking of functions called during a transaction (only instrumented function
  which have access to the current transaction)
- tracking of errors
- tracking of calls to other services
- use ssl/tls
- stable and usable in production for one of our upcoming elixir services

### nice to have

- support for custom attributes

## It is working?

This library is in a very early stage but it appears to be able track the
essentials of a transaction to new relic as can be seen in the screenshot below.

![newrelic-elixir-initial-test](https://cloud.githubusercontent.com/assets/172702/23795528/6cd875fc-0596-11e7-9b95-50205b728601.png)

> The app in test was a simple locally hosted mix application using a plug
> endpoint which basically only had some sleep timers over a few instrumented
> functions and a http call to another locally hosted endpoint (also instrumented
> via new_relic). This shows that both simple method tracer but also tracing from
> one transaction to another seems to be working.

Even with the relative high load shown the memory consumption stays constant.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `router` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:newrelic-elixir, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/newrelic-elixir](https://hexdocs.pm/newrelic-elixir).

## Usage

The following instructions show how to add instrumentation with New Relic to a hypothetical
Phoenix application named `MyApp`.

1.  Just add `new_relic` to your list of dependencies.

    ```elixir
    # mix.exs

    defmodule MyApp.Mixfile do
      use Mix.Project

      # ...

      def application do
        [mod: {MyApp, []}]
      end

      defp deps do
        [{:new_relic, git: "https://github.com/andreaseger/newrelic-elixir", branch: "master"}]
      end
    end
    ```

2.  Add your New Relic application name and license key to `config/config.exs`. You may wish to use
    environment variables to keep production, staging, and development environments separate:

    ```elixir
    # config/config.exs

    config :new_relic,
      application_name: System.get_env("NEWRELIC_APP_NAME"),
      license_key: System.get_env("NEWRELIC_LICENSE_KEY"),
      poll_interval: 60_000 # push data to NewRelic once per 1 minute
    ```


3. TODO

## Contributing
Bug reports and pull requests are welcome on GitHub at
https://github.com/runtastic/newrelic-elixir. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of
the [MIT License](http://opensource.org/licenses/MIT).
