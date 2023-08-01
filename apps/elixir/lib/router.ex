defmodule Moos2.Router do
  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  @port 4000

  @response_body """
    <html><script>(() => window.close())();</script></html>
  """

  get("/success", do: conn |> send_resp(200, @response_body))
  get("/error", do: conn |> put_resp_content_type("text/html") |> send_resp(200, @response_body))

  get "/auth/callback" do
    case Moos2.Spotify.authenticate(conn, conn.params) do
      :ok -> redirect(conn, "/success")
      _ -> redirect(conn, Moos2.Error.error(1))
    end
  end

  match(_, do: send_resp(conn, 404, Jason.encode!(nil)))

  defp redirect(conn, url) do
    conn
    |> put_resp_header("location", url)
    |> send_resp(conn.status || 302, "Redirecting")
  end

  def port, do: @port
end
