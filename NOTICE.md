# NOTICE: Parrot OS Security Web Terminal template

## Software installed in the image

| Component | Source | License | How it is used |
|---|---|---|---|
| Parrot OS 7 ("echo") | `parrotsec/core:7.4` (official image), https://hub.docker.com/r/parrotsec/core, pinned by multi-arch index digest `sha256:1c47caca…` (2026-11-15) | Various free licenses (Parrot's own projects GPL; see `/usr/share/doc/*/copyright` in the image) | Base image (`FROM`) and apt packages from the Parrot archive |
| ttyd 1.7.7 | GitHub release `ttyd.x86_64` of tsl0922/ttyd, SHA-256 `8a217c96…` (from the release's SHA256SUMS) | MIT, Copyright (c) 2016-2022 Shuanglei Tao | Web terminal on loopback, installed unmodified |
| nginx 1.26 | Parrot/Debian package `nginx` | BSD-2-Clause | Basic-auth reverse proxy. The config was written for this template |
| tmux 3.5a | Parrot/Debian package `tmux` | ISC | Persistent sessions |
| tini 0.19.0 | Parrot/Debian package `tini` | MIT | Init and child subreaper |
| nmap, masscan, sqlmap, ffuf, gobuster, feroxbuster, dirb, dirsearch, whatweb, wafw00f, wfuzz, nuclei, subfinder, dnsx, naabu, amass, httpx-toolkit, dnsrecon, dnsenum, theHarvester, recon-ng, sherlock, sslscan, commix, hydra, john, hashcat, hashid, hash-identifier, crunch, cewl, wordlists, netexec, impacket-scripts, evil-winrm, smbclient, smbmap, nbtscan, enum4linux-ng, exploitdb, peass, linux-exploit-suggester, lynis, gdb, radare2, binwalk, yara, exiftool, proxychains4, parrot-core and the everyday CLI tools | Parrot archive (`deb.parrot.sh`, suite `echo`) | Each package's own license (nmap: Nmap Public Source License; others GPL, MIT, BSD, Apache and similar) | Installed unmodified |

Changes to installed files: file capabilities are removed from all binaries (Railway's containers cannot exec binaries whose capabilities exceed their bounding set), `/etc/motd` is emptied (the template prints its own banner), and an apt retry setting is added. No package files are otherwise edited.

Optional packages named in `PARROT_EXTRA_PACKAGES` are installed from the Parrot archive at build time under their own licenses.

Trademarks: "Parrot" and the Parrot logo are trademarks of Parrot Security CIC (US filings, 2024). Parrot publishes no trademark usage policy that we could find (checked 2026-11-20), so this template uses the name only to describe the software it installs and does not use the Parrot logo (the listing icon is a generic terminal icon). This is a community template, not affiliated with or endorsed by Parrot Security CIC, the ttyd author or Railway.

## Upstream files and data checked (2026-11-20)

- Docker Hub tags of `parrotsec/core` (`7.4` = `latest`, multi-arch index `sha256:1c47caca1eb9…`, 0.19 GB compressed for amd64) and `parrotsec/security` (`latest` 5.14 GB compressed for amd64, too large for the 4 GB Trial/Free image limit).
- Parrot documentation "Docker Images" (https://parrotsec.org/docs/containers/parrot-on-docker/): image list and the `parrot-tools-*` metapackages `parrotsec/security` is built from.
- Parrot archive `dists/echo/Release` (Parrot 7 Echo Parakeet, 2026-11-19) and `main/binary-amd64/Packages`: every package name above exists; `ttyd`, `nikto` and `wpscan` are not in the archive (ttyd comes from its GitHub release instead; nikto and wpscan are left out).
- ttyd release 1.7.7 `SHA256SUMS`.

## Market templates and repositories reviewed

| Template / repo | License | Use |
|---|---|---|
| `parrotos-security-edition-web-terminal` / `decoge/parrotos-security-edition-webterminal-railway` | none stated | Template config and Dockerfile read for feature expectations (ttyd with `-c user:pass`, root shell, `parrotsec/security` base, `/work` volume). Nothing copied |
| `parrotos-core-edition-web-terminal`, `parrotos-core-web-terminal` / `decoge/parrotos-core-edition-webterminal-railway` | none stated | Listing text read. Nothing copied |

All files in this package were written for this template, adapted from the same author's Kali Linux Web Terminal template (`entrypoint.sh`, `terminal-session.sh`, `bashrc.sh`, `tmux.conf`, `nginx.conf.template`, `motd.txt`, the Dockerfile and the docs).
