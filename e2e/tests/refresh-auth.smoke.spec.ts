import { test } from '@playwright/test';
import * as fs from 'fs';

/**
 * Refresh the cached auth state WITHOUT an interactive login.
 *
 * Repeated interactive logins trip Azure AD B2C smart-lockout, so when the
 * access token in tests/.auth/user.json has expired we instead redeem the
 * stored refresh_token at the CIAM token endpoint and rewrite user.json.
 *
 *   npx playwright test tests/refresh-auth.smoke.spec.ts --project=smoke
 */

const AUTH_FILE = 'tests/.auth/user.json';
const TOKEN_URL =
  'https://wabiclinicsaas.ciamlogin.com/27ec5190-a36b-4d61-87c0-09925f039516/oauth2/v2.0/token';
const CLIENT_ID = '9ed8eb80-c00d-41c5-915f-fd8efa894b9a';
const SCOPE = 'openid profile email offline_access';

test('refresh cached auth token via refresh_token', async () => {
  const state = JSON.parse(fs.readFileSync(AUTH_FILE, 'utf-8'));
  const origin = (state.origins || []).find((o: any) => o.origin.includes('dev.wabicare.com'));
  if (!origin) throw new Error('No dev.wabicare.com origin in user.json');
  const ls: Array<{ name: string; value: string }> = origin.localStorage;
  const get = (n: string) => ls.find(kv => kv.name === n)?.value?.replace(/^"|"$/g, '');
  const refreshToken = get('flutter.refresh_token');
  if (!refreshToken) throw new Error('No flutter.refresh_token in user.json');

  const body = new URLSearchParams({
    client_id: CLIENT_ID,
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
    scope: SCOPE,
  });

  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Origin: 'https://dev.wabicare.com',
    },
    body: body.toString(),
  });
  const text = await res.text();
  console.log('  [refresh] status', res.status);
  if (!res.ok) {
    console.log('  [refresh] body', text.slice(0, 500));
    throw new Error(`Token refresh failed (${res.status})`);
  }
  const tok = JSON.parse(text);

  const setLs = (name: string, value: string) => {
    const existing = ls.find(kv => kv.name === name);
    const quoted = JSON.stringify(value); // app stores values JSON-quoted
    if (existing) existing.value = quoted;
    else ls.push({ name, value: quoted });
  };

  if (tok.access_token) setLs('flutter.access_token', tok.access_token);
  if (tok.id_token) setLs('flutter.id_token', tok.id_token);
  if (tok.refresh_token) setLs('flutter.refresh_token', tok.refresh_token);
  const expiresIn = Number(tok.expires_in || 3600);
  // Match the app's stored format: LOCAL time, no timezone suffix.
  const exp = new Date(Date.now() + expiresIn * 1000);
  const pad = (n: number) => String(n).padStart(2, '0');
  const expiresAt =
    `${exp.getFullYear()}-${pad(exp.getMonth() + 1)}-${pad(exp.getDate())}` +
    `T${pad(exp.getHours())}:${pad(exp.getMinutes())}:${pad(exp.getSeconds())}.000`;
  setLs('flutter.expires_at', expiresAt);

  fs.writeFileSync(AUTH_FILE, JSON.stringify(state, null, 2));
  console.log(`  [refresh] OK — new token expires ~${expiresAt} (in ${expiresIn}s)`);
});
