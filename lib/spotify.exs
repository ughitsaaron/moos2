import Config

config :spotify_ex,
  user_id: "ughitsaaron",
  scopes: [
    "user-read-private",
    "user-read-email",
    "playlist-modify-private",
    "playlist-modify-public"
  ],
  callback_url: "http://localhost:4000/auth/callback"
