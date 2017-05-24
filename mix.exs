defmodule NewRelic.Mixfile do
  use Mix.Project

  def project do
    [app: :new_relic,
     version: "0.1.2",
     elixir: "~> 1.4.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "Elixir library for sending metrics to New Relic.",
     # package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger],
     mod: {NewRelic, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:plug, "~> 1.3.5"},
     {:ecto, "~> 2.1.4"},
     {:httpoison, "~> 0.11.2"},
     {:phoenix, "~> 1.2.4"},
     {:poison, "~> 2.2"},
     {:decorator, "~> 1.2.0"},
     {:credo, "~> 0.7.4", only: [:dev, :test]},
     {:mix_test_watch, "~> 0.4.0", only: :dev, runtime: false},
     {:ex_doc, ">= 0.15.1", only: :dev}]
  end

  # not going to release this to hex just yet
  #
  # defp package do
  #   [maintainers: ["Andreas Eger"],
  #    licenses: ["MIT"],
  #    links: %{"Github" => "https://github.com/runtastic/newrelic-elixir"}]
  # end
end
