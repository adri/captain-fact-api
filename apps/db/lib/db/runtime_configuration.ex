defmodule DB.RuntimeConfiguration do
  use Weave

  def setup() do
    secrets_path =
      if File.exists?("/run/secrets"),
        do: "/run/secrets",
        else: Path.join(:code.priv_dir(:db), "secrets")

    Application.put_env(:weave, :file_directory, secrets_path)

    Application.put_env(:weave, :only, [
      "db_hostname",
      "db_username",
      "db_password",
      "db_name",
      "db_pool_size",
      "s3_access_key_id",
      "s3_secret_access_key",
      "s3_bucket"
    ])
  end

  # ----- Configuration handlers -----

  # Database
  weave("db_hostname", handler: fn v -> put_in_repo([:hostname], v) end)
  weave("db_username", handler: fn v -> put_in_repo([:username], v) end)
  weave("db_password", handler: fn v -> put_in_repo([:password], v) end)
  weave("db_name", handler: fn v -> put_in_repo([:database], v) end)
  weave("db_pool_size", handler: fn v -> put_in_repo([:pool_size], String.to_integer(v)) end)

  # Arc storage - AWS
  weave(
    "s3_access_key_id",
    handler: fn v -> put_in_env(:ex_aws, [:access_key_id], [v, :instance_role]) end
  )

  weave(
    "s3_secret_access_key",
    handler: fn v -> put_in_env(:ex_aws, [:secret_access_key], [v, :instance_role]) end
  )

  weave("s3_bucket", handler: {:arc, :bucket})

  # ----- Configuration utils -----

  defp put_in_env(app, [head | keys], value) do
    base = Application.get_env(app, head, [])

    modified =
      case keys do
        [] -> value
        _ -> put_in(base, keys, value)
      end

    Application.put_env(app, head, modified)
  end

  defp put_in_repo(keys, value), do: put_in_env(:db, [DB.Repo] ++ keys, value)
end
