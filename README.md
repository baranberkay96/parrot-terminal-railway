# Deploy and Host Parrot OS Security Web Terminal with Railway

A Parrot OS 7 shell in your browser with a curated set of Parrot's command-line security tools: nmap, sqlmap, ffuf, gobuster, nuclei, subfinder, amass, hydra, john, hashcat, netexec, impacket and searchsploit. tmux keeps sessions and long scans running when you close the tab. A generated password protects the shell, and your home directory lives on a persistent volume. Need Metasploit or a whole Parrot tool group? Name it in one variable and Railway builds it into the image.

## About Hosting Parrot OS Security Web Terminal

A browser shell needs a long-running Linux container, a terminal server, a real login in front of it, TLS, and storage that survives rebuilds. This community template builds on the official `parrotsec/core` 7.4 image (pinned by digest) and installs the tools from the Parrot archive. The full `parrotsec/security` image is about 5 GB compressed, more than Railway's Trial and Free plans can build, so this template ships a smaller curated set (about 1 GB) that deploys on every plan. ttyd serves the shell on loopback only. nginx in front of it checks a password Railway generates at deploy, so the login never shows up in logs. You work as the user `parrot` with sudo, and `/home` is a Railway volume.

## Common Use Cases

- Security training, CTFs and HackTheBox / TryHackMe style labs from any browser, including Chromebooks and managed work laptops
- Recon and web testing of systems you own or are authorized to test, from a cloud IP instead of your home connection
- Long scans, fuzzing and password-cracking jobs in tmux that you check on later
- Trying Parrot's command-line tools without installing a VM

## Dependencies for Parrot OS Security Web Terminal Hosting

- A Railway volume mounted at `/home` (included in the template)
- Nothing else: no database, no API keys, no external accounts

### Deployment Dependencies

- Parrot OS documentation: https://parrotsec.org/docs/
- Parrot Docker images: https://parrotsec.org/docs/containers/parrot-on-docker/
- ttyd (web terminal, MIT): https://github.com/tsl0922/ttyd
- tmux: https://github.com/tmux/tmux/wiki
- Railway build variables: https://docs.railway.com/builds/dockerfiles#using-variables-at-build-time
- Railway Fair Use Policy: https://railway.com/legal/fair-use

### Implementation Details

| Service | Source | Purpose |
|---|---|---|
| Terminal | Dockerfile based on `parrotsec/core:7.4` | nginx basic-auth proxy on port 8080 (public HTTPS domain, `/healthz`), ttyd on loopback, tmux sessions, user `parrot` with sudo, volume at `/home` |

**Plan:** light enough for any plan, Free included. Measured on Railway: about 0.04 GB of RAM right after start and 0.1 GB with an open tmux session after an nmap scan. The default image is about 1.2 GB compressed (2.6 GB of packages), well under the 4 GB build limit of Trial and Free. Heavy tools such as Metasploit or long hashcat runs need more memory than the shell itself.

**First login**

1. Open the service's public URL.
2. Your browser asks for a user name and password. The user name is `parrot` (the `USERNAME` variable). The password is the generated `PASSWORD` value on the service's Variables tab.
3. You land in a tmux session named `main`. Close the tab at any time and reopen the URL to resume. For a second, independent session, open `https://{your-domain}/?arg=work`.
4. `sudo -i` gives you a root shell.

**Tools included**

| Area | Tools |
|---|---|
| Recon | nmap, dnsrecon, dnsenum, amass, subfinder, dnsx, naabu, httpx (`httpx-toolkit`), recon-ng, sherlock, whois, dig |
| Web | sqlmap, ffuf, gobuster, dirb, dirsearch, whatweb, wafw00f, wfuzz, nuclei, sslscan |
| Passwords | hydra, john, hashcat (CPU), hashid, hash-identifier, crunch, cewl, `/usr/share/wordlists` (rockyou and others) |
| Windows / AD | netexec, impacket scripts, evil-winrm, smbclient, smbmap, nbtscan, enum4linux-ng |
| Reference and post-exploitation | searchsploit (exploitdb), PEASS, linux-exploit-suggester, lynis |
| Reversing and files | gdb, radare2, binwalk, yara, exiftool |
| Everyday | git, curl, wget, python3, pip, pipx, build-essential, vim, nano, tmux, htop, jq, socat, proxychains4 |

**More tools**: set `PARROT_EXTRA_PACKAGES` to a space-separated list of Parrot packages, for example `metasploit-framework`, `theharvester` or `feroxbuster` (left out by default because they pull in Chromium or the 2 GB SecLists), or a whole group such as `parrot-tools-web` or `parrot-tools-password`. Railway passes the variable to the Docker build, so the next deploy builds an image with those packages and they survive every redeploy. Names apt cannot install are skipped with a warning in the build and deploy logs, so a typo never fails the deploy. Keep the image under 4 GB compressed if you are on Trial or Free (Metasploit adds about 0.5 GB compressed with its dependencies; a `parrot-tools-*` group installs every tool it lists, and `parrot-tools-full` is far too large). Packages installed with `sudo apt install` in the shell work at once but reset on the next redeploy.

**What persists**: everything under `/home/parrot`: files, notes, shell history, Python virtualenvs and pipx apps in `~/.local`, Go tools in `~/go/bin`. Running processes and apt packages reset on every redeploy or restart. tmux keeps sessions alive across browser reconnects, not across container restarts.

**Authorized use only**

These tools can scan, brute-force and exploit systems. Use them only against systems you own or have written permission to test. Railway's [Fair Use Policy](https://railway.com/legal/fair-use) and [Terms of Service](https://railway.com/legal/terms) apply to everything that runs in this shell, and scanning or attacking third-party networks from Railway can get your account suspended. Railway containers have no raw-socket access (`CAP_NET_RAW`), so SYN scans (`-sS`), UDP scans, OS detection (`-O`), masscan and packet capture do not work. nmap is set up for TCP connect scans, which work for every user and under sudo, including service and script detection (`nmap -sV -sC`). `ping` works with `sudo`. Parrot's AnonSurf and Tor routing are not set up: Railway does not allow operating proxies or anonymization services.

**Security**: the shell is never served without a password. With an empty, short (under 12 characters) or overlong `PASSWORD` the service still starts, but the login is locked with a random password nobody knows and the deploy log says how to fix it. Invalid `PORT`, `USERNAME` or `TERMINAL_FONT_SIZE` values fall back to the defaults with a warning. nginx checks the password, which the container keeps only as a SHA-512 crypt hash, rate-limits attempts and rejects WebSocket connections from other sites. ttyd listens on 127.0.0.1 only. The password does not appear in logs, process arguments or the shell environment. To change it, edit `PASSWORD` and redeploy. Browsers cache basic-auth logins until you close them, so use a private window on shared computers.

**Scaling**: a single-user machine on one volume, so keep one replica. Railway scales RAM and CPU vertically up to your plan limit. For a team, deploy one terminal per person.

**Pinning and upgrades**: the Parrot base image is pinned by digest on the `FROM` line of `services/terminal/Dockerfile`, and ttyd by version and SHA-256. Every fresh build runs `apt-get full-upgrade` within Parrot 7. Railway may reuse cached build layers, so change the digest (for example to a newer `parrotsec/core` 7.x tag) to force a fresh build.

### Why Deploy Parrot OS Security Web Terminal on Railway?

Railway gives the terminal an HTTPS URL, a persistent volume and automatic restarts, with no server to administer. You get a password-protected Parrot shell in one click and pay only for the CPU and memory it uses. This is a community template, not affiliated with or endorsed by Parrot Security CIC, the ttyd author or Railway. Parrot and Parrot OS are trademarks of Parrot Security CIC.
