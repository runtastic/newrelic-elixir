Application.put_env(:new_relic, :application_name, "Test")
Application.put_env(:new_relic, :license_key, "xyz")

ExUnit.configure(exclude: [pending: true], colors: [enabled: true])
ExUnit.start()
