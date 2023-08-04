# Moos2 Elixir

## Building & Usage

You will need to [register a developer application](https://developer.spotify.com/documentation/web-api) with Spotify in order to obtain an API access token.

You can run this as an Elixir script by piping API credentials in from the `/authentication` application like so,

```sh
$ yarn -s --cwd ../../authentication ts-node --esm app.ts | elixir moos2.exs [URL] [PLAYLIST_NAME]
```
