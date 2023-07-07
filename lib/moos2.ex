defmodule Moos2.Main do
  @base_url "https://wfmu.org/"

  def main(args) do
    children = [{Plug.Cowboy, scheme: :http, plug: Moos2.Router, options: [port: 4000]}]
    IO.inspect(args)
    [url] = args

    playlist =
      case String.starts_with?(url, @base_url) do
        true -> Moos2.Scrape.get_playlist(url)
        false -> {:error, "Error during auth"}
      end

    IO.inspect(playlist)

    Supervisor.start_link(children, strategy: :one_for_one, name: Moos2.Supervisor)
  end

  @dialyzer {:no_return, stop: 0}
  def stop, do: System.halt(:abort)
end
