defmodule Moos2.Helpers do
  alias Plug.Cowboy
  alias Moos2.Router

  def start_router do
    port = Router.port()
    Cowboy.http(Moos2.Router, [], port: port)
  end

  def shutdown_router do
    Cowboy.shutdown(Moos2.Router.HTTP)
  end

  def restart_router do
    case shutdown_router() do
      _ -> start_router()
    end
  end
end
