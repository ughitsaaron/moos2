# Moos2 Elixir

## Building & Usage

You will need to [register a developer application](https://developer.spotify.com/documentation/web-api) with Spotify in order to obtain an API access token.

1. Copy `config/spotify.secret.sample.exs` and rename it to `config/spotify.sample.exs`
2. Update `config/spotify.sample.exs` with your `client_id`, `secret_key`, and `user_id` (i.e., your account user name).
3. Run `mix deps.get` and `mix build` to [generate the application with `escript`](https://hexdocs.pm/mix/main/Mix.Tasks.Escript.Build.html).
4. Now you can use the generated executable, e.g.,

```sh
$ ./moos2 [URL] [playlist name]
```
