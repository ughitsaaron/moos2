Mix.install([:poison, :floki, :httpoison])

defmodule Credentials do
  use Agent

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def set(value) do
    Agent.update(__MODULE__, fn _ -> value end)
  end

  def set_username(username) do
    Agent.update(__MODULE__, fn state -> Map.merge(state, %{"username" => username}) end)
  end

  def get do
    Agent.get(__MODULE__, & &1)
  end
end

defmodule Spotify do
  use HTTPoison.Base

  @endpoint "https://api.spotify.com/v1"

  def process_request_url(path), do: @endpoint <> path
  def process_request_body("" = body), do: body
  def process_request_body(%{} = body), do: Poison.encode!(body)
  def process_response_body(body), do: body |> Poison.decode!()

  def process_request_headers(_headers \\ []) do
    credentials = Credentials.get()
    ["Authorization": "Bearer " <> credentials["access_token"]]
  end

  defp search_for_track({artist, track} = _song_info) do
    q = format_query(artist: artist, track: track)
    params = %{ q: q, type: "track", limit: 1 } |> URI.encode_query()

    Spotify.get!("/search?#{params}").body
      |> get_in(["tracks", "items"])
      |> List.first()
      |> get_track_uri()
  end

  def search_for_tracks(playlist) do
    Enum.map(playlist, fn track -> search_for_track(track) end)
      |> Enum.reject(&is_nil/1)
  end

  def create_playlist(name, uris) do
    body = %{"name" => name}
    username = Credentials.get() |> Map.get("username")
    response = Spotify.post!("/users/#{username}/playlists", body).body
    Spotify.post("/playlists/#{response["id"]}/tracks", %{uris: uris})
  end

  defp get_track_uri(%{uri: uri}), do: uri
  defp get_track_uri(%{"uri" => uri}), do: uri
  defp get_track_uri(_track), do: nil

  defp format_query([artist: _artist, track: _track] = song_info) do
    Enum.map_join(song_info, fn {k, v} -> "#{k}:#{v} " end)
    |> String.trim()
  end
end

Credentials.start_link()
HTTPoison.start()
Spotify.start()

:ok = IO.read(:stdio, :all)
  |> String.split("\n")
  |> Enum.find(&(String.contains?(&1, "access_token")))
  |> Poison.decode!()
  |> Credentials.set

defmodule Formatter do
  def print(:green, text) do
    IO.ANSI.green() <> IO.ANSI.bright() <> text <> IO.ANSI.reset() |> IO.puts
  end

  def print(:red, text) do
    IO.ANSI.red() <> IO.ANSI.bright() <> text <> IO.ANSI.reset() |> IO.puts
  end

  def print_bold(:white, text) do
    IO.ANSI.white() <> IO.ANSI.bright() <> IO.ANSI.bright() <> text <> IO.ANSI.reset() |> IO.puts
  end
end

case Spotify.get("/me") do
  {:ok, %{status_code: 200, body: body}} ->
    :ok = Credentials.set_username(body["id"])
    Formatter.print(:green, "Okay!\n")

  _ -> IO.inspect("Uh oh")
end

defmodule Scrape do
  def get_playlist(path) do
    response = HTTPoison.get!(path)
    {:ok, document} = Floki.parse_document(response.body)

    Floki.find(document, "#songs table tr")
    |> Enum.map(&Floki.find(&1, "td.col_artist, td.col_song_title"))
    |> Enum.map(
      &Enum.map(&1, fn {_tag, _attrs, [node | _children]} ->
        Floki.text(node) |> String.replace("\n", "")
      end)
    )
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.reject(&Enum.all?(&1, fn str -> str == "" end))
    |> Enum.map(&List.to_tuple/1)
  end
end

[url, playlist_name | _] = System.argv()

tracks = Scrape.get_playlist(url)

Enum.each(tracks, fn {artist, title} ->
  Formatter.print_bold(:white, "#{artist} – #{title}")
end)

uris = Spotify.search_for_tracks(tracks)

{:ok, _} = Spotify.create_playlist(playlist_name, uris)

Formatter.print(:green, "\nSuccess!\n")
