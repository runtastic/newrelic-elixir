# Yet another NewRelic elixir agent

[![Build Status](https://travis-ci.org/andreaseger/newrelic-elixir.svg?branch=master)](https://travis-ci.org/andreaseger/newrelic-elixir)

Instrument your Elixir applications with New Relic.

Based on [newrelic.ex](https://github.com/romul/newrelic.ex) which itself is
based on [newrelic-erlang](https://github.com/wooga/newrelic-erlang)
and [new-relixir](https://github.com/TheRealReal/new-relixir).

It's a mess, isn't it :(

## Why

Well the available solution in elixir are all bound to phoenix and add IMHO some
ugly workarounds to make ecto instrumentation work.

I wasn't comfortable enough with erlang to use `newrelic-erlang` directly with
confidence but after studying `newrelic.ex` which is for many parts a direct
translation of `newrelic-erlang` I discovered a couple issues which lead me to
strip the codebase down to its essentials and implement the basic needs for
instrumenting plugs, generic method calls and have them show up in the correct
categories at new relic.

Additionally to the tracking issues encountered I also wanted to have my agent
use ssl when communicating with new relic.

## It is working?

This library is in a very early stage but it appears to track the essentials to
new relic as can be seen in the screenshot below.

![newrelic-elixir-initial-test](https://cloud.githubusercontent.com/assets/172702/23795528/6cd875fc-0596-11e7-9b95-50205b728601.png)

The app in test was a simple locally hosted mix application using a plug
endpoint which basically only had some sleep timers over a few instrumented
functions and a http call to another locally hosted endpoint (also instrumented
via new_relic). This shows that both simple method tracer but also tracing from
one transaction to another seems to be working.

Even with the high load shown the memory consumption stays constant.

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
