Mix.install([:floki, :jason, :plug_cowboy, :req, :spotify_ex])

defmodule Router do
  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  @response_body """
    <html><script>(() => window.close())();</script></html>
  """

  get("/success", do: conn |> send_resp(200, @response_body))
  get("/error", do: conn |> put_resp_content_type("text/html") |> send_resp(200, @response_body))

  # defp redirect(conn, url) do
  #   conn
  #   |> put_resp_header("location", url)
  #   |> send_resp(conn.status || 302, "redirecting")
  #   |> halt()
  # end

  # get "/" do
  # end

  get "/auth/callback" do
    case Spotify.authenticate(conn, conn.params) do
      :ok -> send(:ok, 200)
      _ -> Error.error(1)
    end
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: reason, stack: _stack}) do
    send_resp(conn, conn.status, Poison.encode!(%{reason: reason}))
  end
end

defmodule Spotify do
  use Agent

  alias Spotify, as: ExSpotify

  def start_link(_init) do
    Agent.start_link(fn -> %ExSpotify.Credentials{} end, name: __MODULE__)
  end

  defp get_creds, do: Agent.get(__MODULE__, & &1)

  defp auth_url do
    query_params =
      URI.encode_query(%{
        response_type: "code",
        client_id: "d5e3977ccb2a4f919c90b91932116a72",
        scope:
          Enum.join(
            [
              "user-read-private",
              "user-read-email",
              "playlist-modify-private",
              "playlist-modify-public"
            ],
            " "
          ),
        redirect_uri: "http://localhost:4000/auth/callback",
        state: "abcd1234"
      })

    "https://accounts.spotify.com/authorize"
    |> URI.parse()
    |> Map.put(:query, query_params)
    |> URI.to_string()
  end

  def authenticate(%Plug.Conn{} = conn, params) do
    case ExSpotify.Authentication.authenticate(conn, params) do
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
    System.cmd("open", [auth_url()])

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

defmodule Scrape do
  @type playlist :: {title :: String.t(), href :: String.t()}
  def get_playlist(path) do
    response = Req.get!(path)
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

defmodule Main do
  @base_url "https://wfmu.org/"

  def main(args \\ []) do
    [url] = args

    playlist =
      case String.starts_with?(url, @base_url) do
        true -> Scrape.get_playlist(url)
        false -> Error.error(0)
      end

    IO.inspect(playlist)
    IO.puts("Opening browser to http://localhost:4000/…")

    :ok = Spotify.sign_in()
  end
end

defmodule Error do
  def error(0), do: System.halt("Invalid input URL")
  def error(1), do: System.halt("Error during authentication")
end

System.argv() |> Main.main()
