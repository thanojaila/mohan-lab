# Hosting the Mohan Lab website on AWS

Step-by-step runbook: from a blank AWS account to **https://mohanlab.bme.uh.edu** with automatic updates.
Written so it can be repeated by someone else (or by you in a year).

**Time:** about 1 hour of work, plus waiting for UH IT to change the DNS.
**Cost:** about $20/month (t3.small ~$15, public IP ~$3.65, disk ~$1.60). Prices change; check the AWS pricing calculator.

---

## How it fits together

```
 Visitor ──► mohanlab.bme.uh.edu ──(DNS, managed by UH IT)──► Elastic IP
                                                                 │
                                          ┌──────────────────────▼──────────────────────┐
                                          │ AWS EC2 server (Ubuntu, t3.small)           │
                                          │   nginx (ports 80/443, HTTPS)               │
                                          │     └─► website app (Node, port 3000)       │
                                          └──────────────────────▲──────────────────────┘
                                                                 │ SSH + scripts/deploy.sh
 Editor ──► GitHub (main branch) ──► GitHub Actions (checks) ────┘
```

- **Code lives in GitHub.** The server only holds a copy. If the server is lost, build a new one with `server-setup.sh` (~15 min).
- **Saving a change on GitHub publishes it.** GitHub Actions checks the code, then runs `scripts/deploy.sh` on the server.
- **A broken change cannot take the site down.** If the new version fails to build or start, `deploy.sh` restores the previous version automatically.

## Files added by this setup

| File | Purpose |
|---|---|
| `scripts/server-setup.sh` | One-time server setup (Node, nginx, service, swap, auto-updates) |
| `scripts/deploy.sh` | Publishes the latest code (runs on the server). Auto-restores on failure |
| `scripts/enable-https.sh` | Free HTTPS certificate, run once after DNS works |
| `.github/workflows/deploy.yml` | Checks + auto-deploy when `main` changes |
| `docs/aws-hosting.md` | This runbook |
| `docs/updating-the-website.md` | Guide for non-technical editors |

---

## Before you start

- [ ] An AWS account you can log into, with billing set up.
- [ ] **Write access to the GitHub repo, and admin access to add Actions secrets** (Settings → Secrets). The site is hosted from the `thanojaila` GitHub account's fork of the original `Tankthesigma/mohan-lab` repo (write access to the original was unavailable at setup time). For handover, consider moving it to a lab-owned GitHub organization (Settings → Danger zone → Transfer) so it does not depend on one person's account.
- [ ] Node 22.13+ on your Mac (`node -v`).

---

## Step 1 - Test the production build on your Mac

This confirms the app runs the way the server will run it, and shows which port it uses.

```bash
cd ~/path/to/mohan-lab
npm ci
npm run build
npm start
```

Open the address it prints (expected: http://localhost:3000). If it uses a **different port**, note it: you will need to set `APP_PORT` in step 4. Stop it with `Ctrl+C`.

## Step 2 - Add the hosting files to the repo and push

1. Copy the downloaded `scripts/`, `.github/` and `docs/` files into the repo (merge with the existing `docs/` folder).
2. In Terminal:

```bash
cd ~/path/to/mohan-lab
git pull
chmod +x scripts/*.sh
git add scripts .github docs
git commit -m "Add AWS hosting scripts, auto-deploy workflow, and handover docs"
git push origin main
```

The workflow will run once and show a yellow warning ("secrets are not set yet - skipping the deploy"). That is expected until step 6.

## Step 3 - Launch the server (AWS console)

Region: **US East (N. Virginia) us-east-1** (any region works; use the same one throughout).

1. AWS console → **EC2** → **Launch instance**.
2. **Name:** `mohan-lab-website`
3. **AMI:** Ubuntu Server **24.04 LTS** (64-bit x86).
4. **Instance type:** `t3.small`.
5. **Key pair:** *Create new key pair* → name `mohan-lab-key`, type **ED25519**, format `.pem`. It downloads once. **Store it in a password manager**; AWS cannot give it back.
6. **Network settings → Create security group** with these inbound rules:

   | Type | Port | Source | Why |
   |---|---|---|---|
   | SSH | 22 | Anywhere (0.0.0.0/0) | You and GitHub Actions log in here (key-only; fail2ban is installed) |
   | HTTP | 80 | Anywhere | Website |
   | HTTPS | 443 | Anywhere | Website |

7. **Storage:** 20 GiB **gp3**.
8. Under **Advanced details**, set **Termination protection** to *Enable* (prevents accidental deletion).
9. **Launch instance.**

### Give it a permanent IP address

1. EC2 → **Elastic IPs** → **Allocate Elastic IP address** → Allocate.
2. Select it → **Actions → Associate Elastic IP address** → choose `mohan-lab-website` → Associate.
3. Write the address down. This is the **ELASTIC_IP** used below, and the address UH IT will point the domain to.

> An Elastic IP that is *not* attached to a running instance still costs money. Release it if you ever delete the server.

## Step 4 - Run the setup on the server

On your Mac:

```bash
chmod 400 ~/Downloads/mohan-lab-key.pem
ssh -i ~/Downloads/mohan-lab-key.pem ubuntu@ELASTIC_IP
```

(Type `yes` the first time.) You are now on the server. Run:

```bash
curl -fsSLo setup.sh https://raw.githubusercontent.com/thanojaila/mohan-lab/main/scripts/server-setup.sh
bash setup.sh
```

If the app used a different port in step 1: `APP_PORT=XXXX bash setup.sh`.

It takes about 5-10 minutes and prints a **"Setup complete"** box at the end. Then open **http://ELASTIC_IP** in a browser. You should see the website.

## Step 5 - Create a deploy key for GitHub

This is a separate key so that GitHub never gets your personal `.pem`.

On your **Mac**:

```bash
ssh-keygen -t ed25519 -f ~/mohan-lab-deploy-key -N "" -C "github-actions-deploy"
ssh -i ~/Downloads/mohan-lab-key.pem ubuntu@ELASTIC_IP \
  "cat >> ~/.ssh/authorized_keys" < ~/mohan-lab-deploy-key.pub
```

## Step 6 - Add the GitHub secrets (turns on automatic updates)

GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**. Add two:

| Name | Value |
|---|---|
| `EC2_HOST` | the Elastic IP (just the numbers, e.g. `3.91.10.20`) |
| `EC2_SSH_KEY` | the **entire contents** of `~/mohan-lab-deploy-key` (run `cat ~/mohan-lab-deploy-key` and copy everything, including the BEGIN/END lines) |

Then delete the private key file from the Mac or move it into the password manager: `rm ~/mohan-lab-deploy-key` after saving.

### Test the automatic update

1. On GitHub, edit any small piece of text (see `docs/updating-the-website.md`) and commit it.
2. Open the repo's **Actions** tab. You should see "Check the code", then "Publish to AWS", ending in a **green check** after a few minutes.
3. Refresh http://ELASTIC_IP and confirm the change is there. Undo the test edit the same way.

## Step 7 - Point the domain at the server (UH IT)

Send UH IT / Dr. Vivek Kumar:

> Please create an **A record** for `mohanlab.bme.uh.edu` pointing to **ELASTIC_IP**. A TTL of 300 seconds (5 min) would be ideal during the switch.

Check progress from your Mac:

```bash
dig +short mohanlab.bme.uh.edu       # should print ELASTIC_IP once the change is live
```

Keep the old WordPress site running until the new one is confirmed working. Changing the A record is the switch; changing it back is the rollback.

## Step 8 - Turn on HTTPS

Only after `dig` shows your Elastic IP. On the server:

```bash
~/mohan-lab/scripts/enable-https.sh your.name@uh.edu
```

Then open **https://mohanlab.bme.uh.edu**. The certificate renews itself automatically.

## Step 9 - Go-live checklist

- [ ] https://mohanlab.bme.uh.edu loads and `http://` redirects to `https://`
- [ ] Click through: home, people, research, publications, news, internships, contact
- [ ] Open the site on a phone
- [ ] Images, videos and downloads load
- [ ] A few **old WordPress URLs** (from Google or old links) redirect to the right new pages
- [ ] Search engines are allowed in: `curl -sI https://mohanlab.bme.uh.edu | grep -i x-robots` prints nothing, and `https://mohanlab.bme.uh.edu/robots.txt` does not block everything
- [ ] Any security headers the Cloudflare version set (see `cloudflare/origin/`) have been reviewed. nginx adds only basic ones (`scripts/server-setup.sh`, step 8)
- [ ] **AWS billing alert:** Billing → Budgets → monthly cost budget of $30 with an email alert
- [ ] **Uptime monitor:** free account at uptimerobot.com, HTTPS check on the site, alert to a shared lab email
- [ ] Credentials stored in the lab password manager (AWS login, `mohan-lab-key.pem`, GitHub owner account)
- [ ] The "Who owns what" table in `docs/updating-the-website.md` is filled in

---

## Everyday commands (on the server)

Connect: `ssh -i mohan-lab-key.pem ubuntu@ELASTIC_IP`

| Task | Command |
|---|---|
| Is the site running? | `sudo systemctl status mohanlab` |
| Restart the site | `sudo systemctl restart mohanlab` |
| Live app logs | `sudo journalctl -u mohanlab -f` |
| Web server errors | `sudo tail -n 50 /var/log/nginx/error.log` |
| Deploy history | `cat ~/mohanlab-deploys.log` |
| Publish latest `main` by hand | `~/mohan-lab/scripts/deploy.sh` |
| Go back to an older version | `~/mohan-lab/scripts/deploy.sh <commit-id>` |
| Disk space | `df -h /` |

**Going back to an older version** (until the next change is saved to `main`): GitHub → **Actions → Deploy website → Run workflow**, paste the old commit ID (from the repo's **Commits** page), run. To make it permanent, undo the bad change in `main` too, or the next save will publish it again.

## Maintenance

- **Security updates** install automatically. Reboot occasionally (`sudo reboot`) when AWS or Ubuntu asks for it; the site comes back by itself in about a minute.
- **HTTPS certificate** renews automatically. If it ever fails: `sudo certbot renew`.
- **Node.js / dependencies:** update through normal code changes (`npm update`, test, commit); the deploy pipeline rebuilds them.
- **Disaster recovery:** all content is in GitHub. To rebuild: launch a new instance (step 3), run `server-setup.sh` (step 4), move the Elastic IP to the new instance (EC2 → Elastic IPs → Associate). The domain needs no change.

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| Browser cannot reach `http://ELASTIC_IP` | Security group missing port 80, or Elastic IP not associated with the instance |
| nginx shows **502 Bad Gateway** | The app is not running or is on another port: `sudo systemctl status mohanlab`, `sudo journalctl -u mohanlab -n 50` |
| `setup.sh` says the site did not respond | Wrong port (set `APP_PORT`), or the build failed. Read the log it prints |
| Build killed / "out of memory" | Check swap: `swapon --show`. Re-run setup to add it, or use a `t3.medium` |
| GitHub Action fails at **Check the code** | A real code problem (lint/type/test). Open the failed step for the message. The live site is unchanged |
| GitHub Action fails at **Publish to AWS** with `Permission denied (publickey)` | `EC2_SSH_KEY` secret is wrong or the public key is not in `~/.ssh/authorized_keys` (step 5) |
| Action fails with connection timed out | Security group port 22, or the server is stopped. Start it in the EC2 console |
| Deploy log says `FAILED ... (restoring ...)` | The new version did not build or start. The old version was restored. See the Action log for why |
| `enable-https.sh` says DNS does not point here | The A record is not live yet; wait and retry. Check with `dig +short mohanlab.bme.uh.edu` |
| Certificate error after months | `sudo certbot renew`, then `sudo systemctl reload nginx` |
| Server unreachable entirely | EC2 console → instance state / status checks → **Reboot** |
