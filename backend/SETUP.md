# Backend setup for the web app

The web app at https://pokemon-ip-tau.vercel.app runs in the browser over **https**.
Browsers refuse to call plain `http://` servers or private VPN addresses from an https
page, so the PHP APIs need a public https address before the website can log anyone in.

Do the steps in order. Each one ends with a way to check it worked.

---

## 1. Give the EC2 instance a fixed public IP

A normal EC2 public IP changes every time the instance is stopped and started (the app's
Instance screen does exactly that), which breaks every URL pointing at it.

1. AWS Console → **EC2** → **Elastic IPs** → **Allocate Elastic IP address** → Allocate.
2. Select the new IP → **Actions → Associate Elastic IP address** → choose your backend instance → Associate.

**Check:** the instance's "Public IPv4 address" now shows the Elastic IP, and stays the same after a stop/start.

> An Elastic IP is free while it is attached to a running instance. AWS charges for it while the instance is stopped.

## 2. Point a domain name at it

Certificates are issued for domain names, not bare IPs. If you don't own a domain, use a free one:

1. Go to https://www.duckdns.org, sign in, create a subdomain (e.g. `monstercc`).
2. Set its IP to your Elastic IP and click **update ip**.

You now have `monstercc.duckdns.org`. If you own a domain, add an **A record** pointing to the Elastic IP instead.

**Check:** `nslookup monstercc.duckdns.org` returns your Elastic IP.

## 3. Open ports 80 and 443

EC2 → your instance → **Security** tab → the security group → **Edit inbound rules** → add:

| Type  | Port | Source    |
|-------|------|-----------|
| HTTP  | 80   | 0.0.0.0/0 |
| HTTPS | 443  | 0.0.0.0/0 |

**Check:** `http://monstercc.duckdns.org/login_player_api.php` opens in a browser (an error message from PHP is fine; a timeout is not).

## 4. Install a free https certificate

SSH into the instance, then run the block for your OS and web server.

**Ubuntu + Apache**
```bash
sudo apt update && sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache -d monstercc.duckdns.org
```

**Amazon Linux 2023 + Apache (httpd)**
```bash
sudo dnf install -y certbot python3-certbot-apache mod_ssl
sudo certbot --apache -d monstercc.duckdns.org
```

(Using Nginx? Replace `apache` with `nginx` in the package and command.)

Answer the prompts and choose to redirect HTTP to HTTPS. Certbot renews the certificate automatically.

**Check:** `https://monstercc.duckdns.org/login_player_api.php` opens with a padlock.

## 5. Allow the website to call the APIs (CORS)

1. Copy [`cors.php`](cors.php) into the same folder as the `*_api.php` files (usually `/var/www/html`).
2. Add this as the **first line after `<?php`** in every `*_api.php` file:
   ```php
   require_once __DIR__ . '/cors.php';
   ```

**Check:**
```bash
curl -s -D - -o /dev/null -H "Origin: https://pokemon-ip-tau.vercel.app" https://monstercc.duckdns.org/login_player_api.php
```
The output must include `Access-Control-Allow-Origin: https://pokemon-ip-tau.vercel.app`.

## 6. Tell the web app the new address

1. Vercel → the project → **Settings → Environment Variables** → add
   `API_BASE` = `https://monstercc.duckdns.org` (no trailing slash).
2. **Deployments** → latest → **⋯ → Redeploy**.

**Check:** log in on https://pokemon-ip-tau.vercel.app.

For the Android app, build with the same address:
```bash
flutter build apk --dart-define=API_BASE=https://monstercc.duckdns.org
```

## 7. Recreate the instance start/stop API

The old address (`xfnttovxp5.execute-api.eu-west-3.amazonaws.com`) no longer exists.

1. AWS Console (region **eu-west-3 / Paris**) → **Lambda** → open the `STOP_AND_START` function.
   If it was deleted too, it needs to be rewritten first.
2. **Add trigger** → **API Gateway** → *Create a new API* → **HTTP API** → Security: **Open** → Add.
3. Open the new API in API Gateway → **CORS** → Allow origin `https://pokemon-ip-tau.vercel.app`,
   methods `GET, POST, OPTIONS`, headers `content-type` → Save.
4. Copy the trigger's **API endpoint** URL.
5. Vercel → Environment Variables → add `INSTANCE_API` = that URL → Redeploy.

**Check:** the app's Instance status screen shows Online/Offline instead of an error.

> ⚠️ An open start/stop URL lets anyone who finds it shut the server down. See step 8.

---

## 8. Security fixes (need the PHP source)

These have to be done in the PHP files; the app cannot enforce them.

- **Don't trust `player_id` from the request.** Right now anyone can send another player's ID
  to edit/delete their catches or change their password. On login, start a session
  (`session_start(); $_SESSION['player_id'] = ...`) or issue a token, and have every API read
  the player from that instead of from `$_POST`/`$_GET`.
- **Hash passwords.** Store `password_hash($password, PASSWORD_DEFAULT)` and check with
  `password_verify()`. Never store or return plain-text passwords.
- **Use prepared statements** (`$stmt = $pdo->prepare(...)`) for every query to block SQL injection.
- **Add a "get my profile" endpoint** so the My Account screen stops downloading the whole
  player list from `list_players_api.php`.
- **Protect the start/stop API**: only allow it for a logged-in admin, e.g. have the Lambda
  check a token that the PHP login issues to admins.
