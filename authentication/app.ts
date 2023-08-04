import express from 'express';
import querystring from 'querystring';
import fetch from 'node-fetch';

const encodeFormData = (data: any) => {
  return Object.keys(data)
    .map((key) => encodeURIComponent(key) + '=' + encodeURIComponent(data[key]))
    .join('&');
};

const app = express();

// const USER_ID = 'ughitsaaron';
const PORT = 4000;
const CLIENT_ID = process.env.CLIENT_ID;
const SECRET_KEY = process.env.SECRET_KEY;
// const REQUEST_TOKEN = Buffer.from(
//   `${CLIENT_ID}:${SECRET_KEY}`,
//   'base64'
// ).toString('base64');
const BASE_URL = `http://localhost:${PORT}`;
const CALLBACK_URL = `${BASE_URL}/auth/callback`;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/auth/callback', async (req, res) => {
  const body = {
    grant_type: 'authorization_code',
    code: req.query.code,
    redirect_uri: CALLBACK_URL,
    client_id: CLIENT_ID,
    client_secret: SECRET_KEY,
  };

  const response = await fetch('https://accounts.spotify.com/api/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Accept: 'application/json',
    },
    body: encodeFormData(body),
  }).then<any>((res) => res.json());

  const query = querystring.stringify(response);
  res.redirect(`/auth/success?${query}`);
});

app.get('/auth/success', (req, res) => {
  process.stdout.write(JSON.stringify(req.query));
  res.end();
  process.exit();
});

app.get('/auth', (req, res) => {
  const scopes = [
    'user-read-private',
    'user-read-email',
    'playlist-modify-private',
    'playlist-modify-public',
  ];

  const url =
    'https://accounts.spotify.com/authorize?' +
    querystring.stringify({
      response_type: 'code',
      client_id: CLIENT_ID,
      scope: scopes,
      redirect_uri: CALLBACK_URL,
    });

  res.redirect(url);
});

app.all('*', (req, res) => {
  res.status(404).send('oops');
});

app.listen(PORT, () => {
  return console.log(`Express is listening at http://localhost:${PORT}`);
});
