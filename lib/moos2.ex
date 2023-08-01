defmodule Moos2.Main do
  def main(_args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Moos2.Router, options: [port: 4000]},
      {Moos2.Spotify, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Moos2.Supervisor)

    [path, name] = System.argv()
    {:ok, _credentials} = Moos2.Spotify.sign_in()

    track_info = Moos2.Scrape.get_playlist(path)

    IO.inspect(track_info)

    tracks = Enum.map(track_info, &Moos2.Spotify.search_for_track/1) |> Enum.reject(&is_nil/1)

    IO.inspect(tracks)

    {:ok, playlist} = Moos2.Spotify.create_playlist(name)
    {:ok, _result} = Moos2.Spotify.add_playlist_tracks(playlist, tracks)

    IO.inspect("okay uplaoded yay!")
  end

  @dialyzer {:no_return, stop: 0}
  def stop, do: System.halt(:abort)
end
