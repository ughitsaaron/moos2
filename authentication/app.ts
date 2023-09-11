import express from 'express';
import querystring from 'querystring';
import fetch from 'node-fetch';
import { exec } from 'node:child_process';

const app = express();

const PORT = 4000;
const CLIENT_ID = process.env.CLIENT_ID;
const SECRET_KEY = process.env.SECRET_KEY;
const BASE_URL = `http://localhost:${PORT}`;
const CALLBACK_URL = `${BASE_URL}/auth/callback`;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/auth/callback', async (req, res) => {
  const response = await fetch('https://accounts.spotify.com/api/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Accept: 'application/json',
    },
    body: querystring.encode({
      grant_type: 'authorization_code',
      code: req.query.code as string,
      redirect_uri: CALLBACK_URL,
      client_id: CLIENT_ID,
      client_secret: SECRET_KEY,
    }),
  }).then<any>((res) => res.json());

  const query = querystring.stringify(response);
  res.redirect(`/auth/complete?${query}`);
});

app.get('/auth/complete', (req, res) => {
  res.send('<script>window.close();</script>');
  process.on('exit', () => {
    process.stdout.write(JSON.stringify(req.query) + '\n');
  });
  process.exit();
});

app.get('/auth', (req, res) => {
  const url =
    'https://accounts.spotify.com/authorize?' +
    querystring.stringify({
      response_type: 'code',
      client_id: CLIENT_ID,
      scope: [
        'user-read-private',
        'user-read-email',
        'playlist-modify-private',
        'playlist-modify-public',
      ].join(','),
      redirect_uri: CALLBACK_URL,
    });

  res.redirect(url);
});

app.all('*', (req, res) => {
  res.status(404).send('oops');
});

app.listen(PORT, () => {
  if (['linux', 'darwin'].includes(process.platform)) {
    exec(`open http://localhost:${PORT}/auth`);
  }

  return console.log(`Express is listening at http://localhost:${PORT}`);
});
