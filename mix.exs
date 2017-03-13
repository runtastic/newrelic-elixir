defmodule NewRelic.Mixfile do
  use Mix.Project

  def project do
    [app: :new_relic,
     version: "0.1.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "Elixir library for sending metrics to New Relic.",
     # package: package(),
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger],
     mod: {NewRelic, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
    [{:plug, "~> 1.3"},
     {:lhttpc, "~> 1.4"},
     {:poison, "~> 3.0"},
     {:decorator, "~> 1.0"},
     {:credo, "~> 0.5", only: [:dev, :test]},
     {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  # not going to release this to hex just yet
  #
  # defp package do
  #   [maintainers: ["Andreas Eger"],
  #    licenses: ["MIT"],
  #    links: %{"Github" => "https://github.com/andreaseger/newrelic-elixir"}]
  # end
end
