# Parrot OS Security Web Terminal for Railway.
#
# Parrot OS 7 ("echo", based on Debian 13) with ttyd serving tmux sessions,
# behind an nginx basic-auth proxy. The shell runs as the non-root user
# "parrot" (passwordless sudo), and /home is a Railway volume.
#
# Base: the official parrotsec/core image, tag 7.4, pinned by its multi-arch
# index digest (2026-11-15). The parrotsec/security image is not used: it is
# about 5.1 GB compressed, above the 4 GB image limit of Railway's Trial and
# Free plans. A curated command-line tool set from the Parrot archive is
# installed instead (about 1 GB compressed). Change tag and digest together
# and redeploy to upgrade.
FROM parrotsec/core:7.4@sha256:1c47caca1eb92568a67f9b994aeda842b2067e9025192d2c707ab6da332718d1

# Extra Parrot packages to bake into the image, space separated, for example
# "metasploit-framework" or "parrot-tools-web". Railway passes the service
# variable of the same name as a build argument, so changing it rebuilds the
# image with those packages. They survive redeploys, unlike `apt install` in
# the shell.
ARG PARROT_EXTRA_PACKAGES=""

ARG DEBIAN_FRONTEND=noninteractive

# ttyd is not in the Parrot archive. The static release binary is pinned by
# version and SHA-256 (from the release's SHA256SUMS).
ARG TTYD_VERSION=1.7.7
ARG TTYD_SHA256=8a217c968aba172e0dbf3f34447218dc015bc4d5e59bf51db2f2cd12b7be4f55

# Railway containers have no CAP_NET_RAW, so nmap's raw-packet scans (-sS, -O,
# -sU) cannot work. NMAP_UNPRIVILEGED makes nmap fall back to TCP connect scans
# (-sT) even under sudo, instead of failing.
ENV LANG=C.UTF-8 \
    TZ=UTC \
    NMAP_UNPRIVILEGED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# apt retries: the Parrot mirror redirector occasionally drops a request.
RUN printf 'Acquire::Retries "5";\nAcquire::http::Timeout "60";\n' > /etc/apt/apt.conf.d/80-railway-retries

# System packages: the auth proxy (nginx), the init (tini), tmux and everyday
# shell tools. `apt-get full-upgrade` brings the 7.x base up to date.
RUN apt-get update \
 && apt-get full-upgrade -y \
 && apt-get install -y --no-install-recommends \
      bash-completion build-essential ca-certificates curl fastfetch file git \
      htop iproute2 iputils-ping jq less libcap2-bin lsof man-db nano ncurses-term \
      netcat-traditional nginx openssh-client openssl pipx procps python3-pip \
      python3-venv ripgrep socat sudo tini tmux tree tzdata unzip vim \
      wget zip \
 && rm -f /etc/nginx/sites-enabled/default \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL --retry 5 --retry-all-errors -o /usr/local/bin/ttyd \
      "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64" \
 && echo "${TTYD_SHA256}  /usr/local/bin/ttyd" | sha256sum -c - \
 && chmod 0755 /usr/local/bin/ttyd \
 && /usr/local/bin/ttyd --version

# Command-line security tools from the Parrot archive. Recon: nmap, masscan
# (needs raw sockets, so it cannot scan on Railway), dnsrecon, dnsenum, amass,
# subfinder, dnsx, naabu, httpx, recon-ng, sherlock, whois, dig. Web: sqlmap,
# gobuster, ffuf, dirb, dirsearch, whatweb, wafw00f, wfuzz, nuclei, sslscan.
# Passwords: hydra, john, hashcat (CPU only, through PoCL),
# hashid, hash-identifier, crunch, cewl, wordlists (rockyou). Windows/AD:
# smbclient, smbmap, nbtscan, enum4linux-ng, netexec, impacket, evil-winrm.
# Reference and post-exploitation: searchsploit (exploitdb), peass,
# linux-exploit-suggester, lynis. Reversing and forensics: gdb, radare2,
# binwalk, yara, exiftool. GUI tools are left out: this is a terminal. Left
# out for size (each can be added with PARROT_EXTRA_PACKAGES): commix (its
# package depends on metasploit-framework and PostgreSQL), theharvester
# (depends on Chromium and Node.js) and feroxbuster (depends on seclists,
# about 2 GB installed). Together they tripled the image.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      amass bind9-dnsutils binwalk cewl crunch dirb dirsearch dnsenum \
      dnsrecon dnsx enum4linux-ng evil-winrm exploitdb ffuf gdb \
      gobuster hash-identifier hashcat hashid httpx-toolkit hydra \
      impacket-scripts john libimage-exiftool-perl linux-exploit-suggester \
      lynis masscan naabu nbtscan netexec nmap nuclei parrot-core peass \
      proxychains4 radare2 recon-ng sherlock smbclient smbmap sqlmap sslscan \
      subfinder wafw00f whatweb wfuzz whois wordlists yara \
 && rm -rf /var/lib/apt/lists/*

# Optional extras from PARROT_EXTRA_PACKAGES, checked as package names first
# so the variable cannot inject shell or apt options. A value typed into the
# deploy form must not fail the build: invalid names and packages that apt
# cannot install are skipped with a warning (here and in the deploy log, from
# /etc/parrot-terminal/skipped-packages), and the rest is installed. Parrot's
# tool groups (parrot-tools-*) list their tools as Recommends, so they are
# installed with recommends; everything else without.
RUN set -eux; \
    install -d -m 0755 /etc/parrot-terminal; \
    : > /etc/parrot-terminal/skipped-packages; \
    read -r -a requested <<< "${PARROT_EXTRA_PACKAGES//,/ }"; \
    extra=(); \
    for pkg in "${requested[@]}"; do \
      if [[ "$pkg" =~ ^[a-z0-9][a-z0-9+.-]+$ ]]; then \
        extra+=("$pkg"); \
      else \
        echo "WARNING: PARROT_EXTRA_PACKAGES: skipping invalid package name '${pkg:0:64}'" >&2; \
        printf '%s\n' "${pkg:0:64}" >> /etc/parrot-terminal/skipped-packages; \
      fi; \
    done; \
    install_one() { \
      case "$1" in \
        parrot-tools-*) apt-get install -y --install-recommends "$1" ;; \
        *) apt-get install -y --no-install-recommends "$1" ;; \
      esac; \
    }; \
    if (( ${#extra[@]} > 0 )); then \
      apt-get update; \
      for pkg in "${extra[@]}"; do \
        if ! install_one "$pkg"; then \
          echo "WARNING: PARROT_EXTRA_PACKAGES: skipping '${pkg}', apt could not install it." >&2; \
          printf '%s\n' "$pkg" >> /etc/parrot-terminal/skipped-packages; \
        fi; \
      done; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*; \
    fi; \
    chmod 0644 /etc/parrot-terminal/skipped-packages

# Railway's container capability set lacks NET_RAW and NET_ADMIN, and the
# kernel refuses to exec a binary whose file capabilities exceed that set
# ("Operation not permitted" for every user, root included; ping is one of
# them). Stripping the file capabilities lets those tools run with whatever
# the container allows. Parrot's own login message is replaced by this
# template's banner.
RUN set -eux; \
    caps="$(getcap -r /usr /opt 2> /dev/null || true)"; \
    for bin in $(printf '%s\n' "$caps" | awk 'NF {print $1}'); do setcap -r "$bin"; done; \
    test -z "$(getcap -r /usr /opt 2> /dev/null || true)"; \
    : > /etc/motd

# The login user. It has a fixed uid 1000 so file ownership on the volume stays
# stable across image updates. New homes get Parrot's default dotfiles plus one
# line that loads this template's shell defaults.
RUN set -eux; \
    printf '\n# Parrot Web Terminal defaults (prompt, history, PATH). Delete these lines to opt out.\nif [ -r /etc/parrot-terminal/bashrc ]; then . /etc/parrot-terminal/bashrc; fi\n' \
      >> /etc/skel/.bashrc; \
    if getent passwd 1000 > /dev/null; then userdel --remove "$(getent passwd 1000 | cut -d: -f1)"; fi; \
    useradd --create-home --uid 1000 --user-group --groups sudo --shell /bin/bash parrot; \
    printf 'Defaults env_keep += "NMAP_UNPRIVILEGED"\nparrot ALL=(ALL:ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/90-parrot-terminal; \
    chmod 0440 /etc/sudoers.d/90-parrot-terminal; \
    visudo -cf /etc/sudoers.d/90-parrot-terminal

COPY entrypoint.sh /usr/local/bin/parrot-terminal-entrypoint
COPY terminal-session.sh /usr/local/bin/terminal-session
COPY bashrc.sh /etc/parrot-terminal/bashrc
COPY motd.txt /etc/parrot-terminal/motd
COPY nginx.conf.template /etc/parrot-terminal/nginx.conf.template
COPY tmux.conf /etc/tmux.conf
RUN chmod 0755 /usr/local/bin/parrot-terminal-entrypoint /usr/local/bin/terminal-session \
 && chmod 0644 /etc/parrot-terminal/bashrc /etc/parrot-terminal/motd \
      /etc/parrot-terminal/nginx.conf.template /etc/tmux.conf

EXPOSE 8080

# On Railway, podman-init is PID 1 and this runs under it. tini -s registers as
# a child subreaper, so orphaned processes (the tmux server, background jobs)
# are reaped whether or not tini is PID 1.
ENTRYPOINT ["/usr/bin/tini", "-s", "--", "/usr/local/bin/parrot-terminal-entrypoint"]
