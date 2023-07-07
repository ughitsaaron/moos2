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

  @response_body """
    <html><script>(() => window.close())();</script></html>
  """

  get("/success", do: conn |> send_resp(200, @response_body))
  get("/error", do: conn |> put_resp_content_type("text/html") |> send_resp(200, @response_body))

  get "/auth/callback" do
    case Moos2.Spotify.authenticate(conn, conn.params) do
      :ok -> send(:ok, 200)
      _ -> Moos2.Error.error(1)
    end
  end
end
