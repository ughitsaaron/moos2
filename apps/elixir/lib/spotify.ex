defmodule Moos2.Spotify do
  use Agent

  alias Spotify

  defp open_browser(nil), do: {[], 0}

  defp open_browser(path) do
    case :os.type() do
      {:unix, :darwin} -> System.cmd("open", [path])
      _ -> open_browser(nil)
    end
  end

  @default_state %{status: :unauthenticated}

  def start_link(_ \\ []) do
    Agent.start_link(fn -> @default_state end, name: __MODULE__)
  end

  def put(:credentials, %Spotify.Credentials{} = credentials) do
    Agent.update(__MODULE__, &Map.put(&1, :credentials, credentials))
  end

  def get(key) do
    Agent.get(__MODULE__, fn state -> state[key] end)
  end

  def credentials, do: get(:credentials)

  def authenticate(%Plug.Conn{} = conn, params) do
    case Spotify.Authentication.authenticate(conn, params) do
      {:ok, credentials} -> put(:credentials, Spotify.Credentials.new(credentials))
      {:error, _} -> :error
    end
  end

  def authentication_loop do
    case get(:credentials) do
      %Spotify.Credentials{} = credentials ->
        {:ok, credentials}

      _ ->
        :timer.sleep(150)
        authentication_loop()
    end
  end

  def sign_in() do
    Spotify.Authorization.url()
    |> open_browser()

    authorize =
      Task.async(fn ->
        authentication_loop()
      end)

    Task.await(authorize, 30000)
  end

  def search_for_track({artist, track} = _song_info) do
    q = format_query(artist: artist, track: track)

    result =
      case Spotify.Search.query(credentials(), q: q, type: "track", limit: 1) do
        {:ok, result} -> result
      end

    Map.get(result, :items, []) |> List.first() |> get_track_uri()
  end

  def create_playlist(name) do
    body = Poison.encode!(%{name: name})
    Spotify.Playlist.create_playlist(credentials(), Spotify.current_user(), body)
  end

  def add_playlist_tracks(%Spotify.Playlist{id: id}, tracks) do
    uris = Poison.encode!(%{uris: tracks})
    Spotify.Playlist.add_tracks(credentials(), Spotify.current_user(), id, uris, [])
  end

  def get_track_uri(%Spotify.Track{uri: uri}), do: uri
  def get_track_uri(_track), do: nil

  defp format_query([artist: _artist, track: _track] = song_info) do
    Enum.map_join(song_info, fn {k, v} -> "#{k}:#{v} " end)
    |> String.trim()
  end
end
