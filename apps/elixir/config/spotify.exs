import Config

config :spotify_ex,
  callback_url: "http://localhost:4000/auth/callback",
  scopes: [
    "user-read-private",
    "user-read-email",
    "playlist-modify-private",
    "playlist-modify-public"
  ]
