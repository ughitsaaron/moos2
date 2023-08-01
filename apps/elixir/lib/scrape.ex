defmodule Moos2.Scrape do
  @type playlist :: {title :: String.t(), href :: String.t()}
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
