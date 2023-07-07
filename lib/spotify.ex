defmodule Moos2.Spotify do
  use GenServer

  alias Spotify

  def init(args \\ %{}) do
    {:ok, args}
  end

  def start_link(options) do
    GenServer.start_link(__MODULE__, %Spotify.Credentials{}, options)
  end

  defp get_creds, do: Agent.get(__MODULE__, & &1)

  def authenticate(%Plug.Conn{} = conn, params) do
    case Spotify.Authentication.authenticate(conn, params) do
      {:ok, creds} ->
        Agent.update(__MODULE__, fn _ -> creds end)

      {:error, _} ->
        :error
    end
  end

  def authenticated? do
    if get_creds(), do: true, else: false
  end

  def sign_in do
    System.cmd("open", [Spotify.Authorization.url()])
    :ok
  end

  def search_for_track([artist: _artist, track: _track] = song_info) do
    creds = get_creds()
    q = format_query(song_info)

    result =
      case Spotify.Search.query(creds, q: q, type: "track", limit: 1) do
        {:ok, result} -> result
      end

    Map.get(result, :items, []) |> List.first()
  end

  def get_track_id(%Spotify.Track{id: id}), do: id
  def get_track_id(_track), do: nil

  defp format_query([artist: _artist, track: _track] = song_info) do
    Enum.map_join(song_info, fn {k, v} -> "#{k}:#{v} " end)
    |> String.trim()
  end
end
