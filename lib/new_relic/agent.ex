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
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        struct = Poison.decode!(body)
        struct["return_value"]
      {:ok, %HTTPoison.Response{status_code: 503}} ->
        raise RuntimeError.message("newrelic_down")
      _error ->
        raise RuntimeError.message("newrelic_down")
    end
  end


  def connect(collector, hostname, attempts_count \\ 1) do
    url = url(collector, [method: :connect])

    data = [%{
      :agent_version => "1.5.0.103",
      :app_name => [app_name()],
      :host => l2b(hostname),
      :identifier => app_name(),
      :pid => l2i(:os.getpid()),
      :environment => [],
      :language => Application.get_env(:new_relic, :language, "python"),
      :settings => %{}
    }]
    Logger.info "Connect Url: #{url}, data: #{inspect data}"
    case request(url, Poison.encode!(data)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        struct = Poison.decode!(body)
        return = struct["return_value"]
        return["agent_run_id"]
      {:ok, %HTTPoison.Response{status_code: 503, body: body}} ->
        raise RuntimeError.exception("newrelic - connect - #{inspect body}")
      _error ->
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
    Logger.info "push Url: #{url}, data: #{inspect data}"
    case request(url, Poison.encode!(data)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response}} ->
        struct = Poison.decode!(response)
        case struct["exception"] do
          nil ->
            :ok
          exception ->
            {:error, exception}
        end;
      {:ok, %HTTPoison.Response{status_code: 503, body: body}} ->
        raise RuntimeError.exception("newrelic - push_data - #{inspect body}")
      {:ok, resp} ->
        Logger.error("NewRelic.Agent: push_data failed: #{inspect resp}")
      _error ->
        raise RuntimeError.exception("newrelic - push_data - timeout")
    end
  end

  ## Helpers

  defp l2b(char_list) do
    to_string(char_list)
  end
  defp l2i(char_list) do
    :erlang.list_to_integer(char_list)
  end

  defp app_name() do
    Application.get_env(:new_relic, :application_name)
  end

  defp license_key() do
    Application.get_env(:new_relic, :license_key)
  end

  def request(url, body \\ "[]") do
    Logger.info("[HTTPoison_request] [#{url}] [#{body}]")
    response = HTTPoison.post(url, body, [{"Content-Encoding", "identity"}], hackney: [timeout: 5000, max_connections: 1000])
    Logger.info("[HTTPoison_request_response] [#{inspect response}]")
    response
  end

  def url(args) do
    url("collector.newrelic.com", args)
  end
  def url(host, args) do
    base_args = [
      protocol_version: 10,
      license_key: license_key(),
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
