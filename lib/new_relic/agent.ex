defmodule NewRelic.Agent do
  @base_url "https://~s/agent_listener/invoke_raw_method?"
  require Logger

  @doc """
  Connects to New Relic and sends the hopefully correctly
  formatted data and registers it under the given hostname.
  """
  def push(hostname, data, errors) do
    if NewRelic.configured? do
      collector = get_redirect_host()
      run_id = connect(collector, hostname)
      case push_metric_data(collector, run_id, data) do
        :ok ->
          push_error_data(collector, run_id, errors)
        error ->
          Logger.error("NewRelic.Agent: push_metric_data failed: #{inspect error}")
      end
    end
  end


  ## NewRelic protocol

  def get_redirect_host() do
    url = url(method: :get_redirect_host)
    case request(url) do
      {:ok, {{200, 'OK'}, _, body}} ->
        struct = Poison.decode!(body)
        struct["return_value"]
      {:ok, {{503, _}, _, _}} ->
        raise RuntimeError.message("newrelic_down")
      {:error, :timeout} ->
        raise RuntimeError.message("newrelic_down")
    end
  end


  def connect(collector, hostname, attempts_count \\ 1) do
    url = url(collector, [method: :connect])
    system_pid = System.get_pid |> Integer.parse |> elem(0)
    app_name = Application.get_env(:new_relic, :application_name)

    data = [%{
      :agent_version => "1.5.0.103",
      :app_name => [app_name],
      :host => hostname,
      :identifier => app_name,
      :pid => system_pid,
      :environment => [],
      :language => Application.get_env(:new_relic, :language, "python"),
      :settings => %{}
    }]

    case request(url, Poison.encode!(data)) do
      {:ok, {{200, 'OK'}, _, body}} ->
        struct = Poison.decode!(body)
        return = struct["return_value"]
        return["agent_run_id"]
      {:ok, {{503, _}, _, body}} ->
        raise RuntimeError.exception("newrelic - connect - #{inspect body}")
      {:error, :timeout} ->
        if attempts_count > 0 do
          connect(collector, hostname, attempts_count-1)
        else
          raise RuntimeError.exception("newrelic - connect - timeout")
        end
    end
  end

  def push_metric_data(collector, run_id, metric_data) do
    url = url(collector, [method: :metric_data, run_id: run_id])
    data = [run_id | metric_data]
    push_data(url, data)
  end

  def push_error_data(collector, run_id, error_data) do
    url = url(collector, [method: :error_data, run_id: run_id])
    data = [run_id, error_data]
  	push_data(url, data)
  end

  def push_data(url, data) do
    case request(url, Poison.encode!(data)) do
      {:ok, {{200, 'OK'}, _, response}} ->
        struct = Poison.decode!(response)
        case struct["exception"] do
          nil ->
            :ok
          exception ->
            {:error, exception}
        end;
      {:ok, {{503, _}, _, body}} ->
        raise RuntimeError.exception("newrelic - push_data - #{inspect body}")
      {:ok, resp} ->
        Logger.error("NewRelic.Agent: push_data failed: #{inspect resp}")
      {:error, :timeout} ->
        raise RuntimeError.exception("newrelic - push_data - timeout")
    end
  end

  ## Helpers
  def request(url, body \\ "[]") do
    :lhttpc.request(url, :post, [{"Content-Encoding", "identity"}], body, 5000)
  end

  def url(args) do
    url("collector.newrelic.com", args)
  end
  def url(host, args) do
    license_key = Application.get_env(:new_relic, :license_key)
    base_args = [
      protocol_version: 10,
      license_key: license_key,
      marshal_format: :json
    ]
    base_url = String.replace(@base_url, "~s", host)
    [base_url, urljoin(args ++ base_args)]
    |> List.flatten
    |> Enum.join
    |> String.to_char_list
  end

  defp urljoin([]), do: []
  defp urljoin([h | t]) do
    [url_var(h) | (for x <- t, do: ["&", url_var(x)])]
  end

  defp url_var({key, value}), do: [to_string(key), "=", to_string(value)]
end
