# Parrot OS 7 Security Web Terminal (Browser Shell): composer spec

Listing: **Parrot OS 7 Security Web Terminal (Browser Shell)**, "Parrot OS security shell in a browser tab: nmap, sqlmap, ffuf, hydra." Category Other. Icon: generic terminal (dashboard-icons `terminal.svg`), no Parrot logo (see NOTICE.md).

## Service: Terminal

- Source: repo `baranberkay96/parrot-terminal-railway`, root directory `/services/terminal` (Dockerfile).
- Base: `parrotsec/core:7.4@sha256:1c47caca1eb92568a67f9b994aeda842b2067e9025192d2c707ab6da332718d1` (2026-11-15). ttyd 1.7.7 release binary, SHA-256 pinned.
- Public domain, target port 8080, healthcheck `/healthz` (120 s), restart ON_FAILURE ×10, 1 replica.
- Volume `/home`.
- Variables: `PASSWORD` = `${{secret(32)}}`, `USERNAME` = `parrot`, `PORT` = `8080`, `TERMINAL_TMUX` = `true`, `TERMINAL_FONT_SIZE` = `15`, `PARROT_EXTRA_PACKAGES` = empty (build argument), `TZ` = `UTC`, `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` = `15`.

## Improvements over market templates

- The market leader builds `FROM parrotsec/security` (unpinned `latest`, about 5.1 GB compressed): above the 4 GB image limit of Trial and Free, so those deploys fail. This template pins `parrotsec/core:7.4` and installs a curated tool set (about 1 GB).
- No root shell over the web: user `parrot` with sudo; ttyd on loopback behind nginx basic auth instead of ttyd `-c user:pass` (which prints the credential to the logs) on a public port.
- Generated password; an empty, short or overlong password locks the login without failing the deploy (STANDARD 8.29).
- Origin check against cross-site WebSocket hijacking, rate limit, anti-framing headers.
- Healthcheck, tmux sessions that survive closed tabs, persistent `/home`, extra packages as a build variable, nmap set up for Railway's missing raw sockets.

## Resource estimate

| Service | Idle RAM | Typical | CPU |
|---|---|---|---|
| Terminal | ~0.1 GB | 0.2–1 GB (scans, cracking) | bursts |

About $1–3/month idle at Railway prices plus the volume ($0.15/GB-month). Runs on every plan, including Trial (1 GB) and Free (0.5 GB) for the shell itself.

## Verification checklist

- `/healthz` returns 200 without a login; `/` returns 401 without and 200 with the generated credential.
- The terminal opens, `sudo -i` works, `nmap -sT -sV scanme.nmap.org`-style scan of an authorized target works, `ping` works with sudo.
- A file in `~` survives a redeploy.
- `PASSWORD=short` → deploy succeeds, login locked, log explains.

## Open questions

- Parrot has no published trademark policy; the listing uses the name descriptively and a generic icon.
