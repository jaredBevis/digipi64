#!/usr/bin/env bash
# =============================================================================
# digipi64-setup.sh  -  DigiPi features on a general-purpose 64-bit Raspberry Pi OS
#                       (Trixie, Pi 5).  Read/write filesystem, hostname and
#                       user account left exactly as they are.
#
#   sudo ./digipi64-setup.sh                 # install (default)
#   sudo ./digipi64-setup.sh install --update   # re-clone repo, rebuild, redeploy
#   sudo digipi64-setup reconfigure          # restore the files Initialize rewrites + re-open Initialize
#   sudo digipi64-setup reconfigure --full   # ...or redeploy every repo file (resets app settings too)
#   sudo digipi64-setup osoyoo-dsi-panel-7inch   # (re)build only the OSOYOO 7" DSI screen driver + its desktop settings
#   sudo digipi64-setup osk                  # (re)install just the on-screen keyboard taskbar toggle
#   sudo digipi64-setup audit                # re-run dependency / symlink checks
#
# Source of DigiPi files: https://github.com/craigerl/digipi (cloned at run time)
# Env overrides: DIGIPI_USER DIGIPI_REF DIREWOLF_REF APRSD_VERSION DIGIPI_WEB_PORT
#                DIGIPI_VNC=0 (skip DigiPi's VNC/noVNC session; GUI apps then won't show in the web UI)
#                ADD_GROUPS=0  FORCE_UNITS="a.service b.service"
#                BUILD_ARDOP=0 / BUILD_MERCURY=0 (skip building those 64-bit modems)
#                INSTALL_HTCOMMANDER=0  INSTALL_GRIDTRACKER=0  (external .deb apps)
#                INSTALL_RTW=0 (skip FreeCAD/Scilab/KiCad)  RTW_KICAD_3D=1 (also KiCad 3D models, ~6 GB)
#                HAM_MENU=0 (leave radio applications scattered in the start menu)
#                INSTALL_NGINX=0 (no landing page/HTTPS; DigiPi stays on port 80)
#                AUTOHOTSPOT=ask|1|0  FALLBACK_SSID FALLBACK_PSK  (fallback Wi-Fi hotspot; asks at install by default)
#                INSTALL_OSOYOO_DSI_7INCH=1 (OSOYOO 7" DSI screen; default 0)  OSOYOO_DSI_PORT=dsi1|dsi0
#                OSOYOO_DSI_AUTOFIX=0 (no boot check)  OSOYOO_DSI_AUTOREBOOT=0   (no rotation/touch settings: set those in the desktop yourself)
#                DESKTOP_VNC=0 (do not enable the Raspberry Pi desktop VNC server, wayvnc on port 5900)
#                OSK_TOGGLE=0 (no taskbar button for the on-screen keyboard)  OSK_DEFAULT=off|on (state after install; default off)
#                INSTALL_HAMCLOCKSYNC=0 (skip Ham Clock Sync, the WWV/GPS/NTP clock-setting tool)  HAMCLOCKSYNC_REPO / HAMCLOCKSYNC_REF
#                INSTALL_KIWIX=0  KIWIX_PORT=8090  (offline ZIM server, ZIM files go in ~/kiwix_zim)
#
# Copyright (C) 2026 the digipi64-setup authors
# SPDX-License-Identifier: GPL-3.0-or-later
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
# version. It is distributed WITHOUT ANY WARRANTY; see the GNU General Public License (LICENSE) for details.
# It is an independent port that downloads and adapts files from DigiPi (https://github.com/craigerl/digipi, by craigerl).
# This file was written as a new script; it changes the downloaded DigiPi files on the machine where it runs.
# =============================================================================
set -Eeuo pipefail

# ----------------------------- settings --------------------------------------
DIGIPI_REPO="${DIGIPI_REPO:-https://github.com/craigerl/digipi.git}"
DIGIPI_REF="${DIGIPI_REF:-main}"
DIREWOLF_REPO="${DIREWOLF_REPO:-https://github.com/wb2osz/direwolf.git}"
DIREWOLF_REF="${DIREWOLF_REF:-dev}"          # DigiPi 2.x uses Direwolf 1.8 (dev branch)
APRSD_VERSION="${APRSD_VERSION:-4.2.4}"
HAM_MENU="${HAM_MENU:-1}"                # one "Ham Radio" start-menu heading for all radio applications
INSTALL_NGINX="${INSTALL_NGINX:-1}"      # nginx on 80/443: landing page + HTTPS; DigiPi's own web server then moves to 8081
WEB_PORT="${DIGIPI_WEB_PORT:-$([[ $INSTALL_NGINX == 1 ]] && echo 8081 || echo 80)}"   # not 8080: Pat's web UI listens there
ADD_GROUPS="${ADD_GROUPS:-1}"
DIGIPI_VNC="${DIGIPI_VNC:-1}"
DASHBOARD_REPO="${DASHBOARD_REPO:-https://github.com/hemna/direwolf-dashboard.git}"; DASHBOARD_REF="${DASHBOARD_REF:-}"
INSTALL_HTCOMMANDER="${INSTALL_HTCOMMANDER:-1}"; INSTALL_GRIDTRACKER="${INSTALL_GRIDTRACKER:-1}"
INSTALL_RTW="${INSTALL_RTW:-1}"; RTW_KICAD_3D="${RTW_KICAD_3D:-0}"   # "reboot the world" engineering/design collection
INSTALL_OSOYOO_DSI_7INCH="${INSTALL_OSOYOO_DSI_7INCH:-0}"      # OSOYOO 7" DSI touchscreen driver; off unless requested
OSOYOO_DSI_REPO="${OSOYOO_DSI_REPO:-https://github.com/osoyoo/osoyoo-dsi-panel.git}"; OSOYOO_DSI_REF="${OSOYOO_DSI_REF:-}"
OSOYOO_DSI_PORT="${OSOYOO_DSI_PORT:-dsi1}"
DESKTOP_VNC="${DESKTOP_VNC:-1}"          # Raspberry Pi desktop VNC server (wayvnc, port 5900)
OSK_TOGGLE="${OSK_TOGGLE:-1}"; OSK_DEFAULT="${OSK_DEFAULT:-off}"   # taskbar button that turns the squeekboard on-screen keyboard on/off
OSOYOO_DSI_AUTOFIX="${OSOYOO_DSI_AUTOFIX:-1}"; OSOYOO_DSI_AUTOREBOOT="${OSOYOO_DSI_AUTOREBOOT:-1}"
INSTALL_HAMCLOCKSYNC="${INSTALL_HAMCLOCKSYNC:-1}"   # https://github.com/jaredBevis/ham-clock-sync (GPL-3.0+), shown under Ham Radio in the start menu
HAMCLOCKSYNC_REPO="${HAMCLOCKSYNC_REPO:-https://github.com/jaredBevis/ham-clock-sync.git}"; HAMCLOCKSYNC_REF="${HAMCLOCKSYNC_REF:-}"
INSTALL_KIWIX="${INSTALL_KIWIX:-1}"; KIWIX_PORT="${KIWIX_PORT:-8090}"; KIWIX_DIR_NAME="${KIWIX_DIR_NAME:-kiwix_zim}"
HTCOMMANDER_DEB_URL="${HTCOMMANDER_DEB_URL:-}"; GRIDTRACKER_DEB_URL="${GRIDTRACKER_DEB_URL:-}"
BUILD_ARDOP="${BUILD_ARDOP:-1}"          # ardopcf (open-source ARDOP modem, replaces DigiPi's 32-bit piardopc)
BUILD_MERCURY="${BUILD_MERCURY:-1}"      # Rhizomatica Mercury HF modem
ARDOP_REPO="${ARDOP_REPO:-https://github.com/pflarue/ardop.git}"; ARDOP_REF="${ARDOP_REF:-master}"
MERCURY_REPO="${MERCURY_REPO:-https://github.com/Rhizomatica/mercury.git}"; MERCURY_REF="${MERCURY_REF:-}"
FORCE_UNITS="${FORCE_UNITS:-}"

# Never overwritten in the user's home (keeps the account as you set it up)
# (the repo's home/pi is a snapshot of the author's image: every top-level dotfile is skipped)
HOME_EXCLUDES=('.*' '__pycache__')

STATE=/var/lib/digipi64
SRC=/opt/digipi-src
STAGE=$STATE/stage
VENV=""            # set in resolve_user: ~/.aprsd-venv (webchat.sh activates that path)
REVIEW=$STATE/REVIEW.txt
LOG=/var/log/digipi64-setup.log
SELF_INSTALLED=/usr/local/sbin/digipi64-setup

MODE=install; UPDATE=0; FULL=0
for a in "$@"; do
  case $a in
    install|reconfigure|audit|osoyoo-dsi-panel-7inch|osk) MODE=$a ;;
    --update) UPDATE=1 ;;
    --full) FULL=1 ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "unknown argument: $a" >&2; exit 2 ;;
  esac
done

log()  { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }
review(){ echo "$*" >> "$REVIEW"; }
trap 'die "line $LINENO: command failed: $BASH_COMMAND"' ERR

[[ $EUID -eq 0 ]] || die "Run with sudo."
mkdir -p "$STATE"; touch "$REVIEW"
exec > >(tee -a "$LOG") 2>&1
export DEBIAN_FRONTEND=noninteractive

# ----------------------------- user / host -----------------------------------
resolve_user() {
  if [[ $MODE == reconfigure && -f $STATE/user ]]; then
    TARGET_USER=$(<"$STATE/user")                 # web page runs us as www-data via sudo
  else
    TARGET_USER="${DIGIPI_USER:-${SUDO_USER:-}}"
  fi
  [[ -n $TARGET_USER && $TARGET_USER != root ]] || die "Run via 'sudo' from your normal account (or set DIGIPI_USER=<name>)."
  id "$TARGET_USER" &>/dev/null || die "User '$TARGET_USER' does not exist."
  TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
  VENV="$TARGET_HOME/.aprsd-venv"
  echo "$TARGET_USER" > "$STATE/user"
}

preflight() {
  log "Preflight"
  [[ $(uname -m) == aarch64 ]] || die "This script targets 64-bit (aarch64) Raspberry Pi OS."
  . /etc/os-release
  [[ ${VERSION_CODENAME:-} == trixie || ${VERSION_CODENAME:-} == bookworm ]] || warn "Expected Debian Trixie or Bookworm, found '${VERSION_CODENAME:-?}'. Continuing."
  curl -fsI --max-time 15 https://github.com >/dev/null || die "No internet access to github.com."
  [[ -f $STATE/hostname.orig ]] || hostname > "$STATE/hostname.orig"
  echo "User: $TARGET_USER ($TARGET_HOME)   Hostname (untouched): $(cat "$STATE/hostname.orig")"
  runuser -u "$TARGET_USER" -- sudo -n true 2>/dev/null \
    || warn "$TARGET_USER has no passwordless sudo. DigiPi scripts call sudo non-interactively (killall, systemctl, ...) and will fail."
  if [[ $(findmnt -no FSTYPE /) == overlay ]]; then
    command -v raspi-config >/dev/null && raspi-config nonint disable_overlayfs || true
    die "Root is an overlay (read-only) filesystem. Overlay disabled; REBOOT, then run this script again."
  fi
  local p; p=$(ss -ltnpH "sport = :$WEB_PORT" 2>/dev/null || true)
  if [[ -n $p && $p != *lighttpd* ]]; then
    die "Port $WEB_PORT is in use by something other than lighttpd:\n$p\nStop it, or rerun with DIGIPI_WEB_PORT=8081 (DigiPi links may assume port 80)."
  fi
  if [[ $INSTALL_NGINX == 1 ]]; then
    for p in 80 443; do
      local q; q=$(ss -ltnpH "sport = :$p" 2>/dev/null | grep -vE 'lighttpd|nginx' || true)
      [[ -z $q ]] || die "Port $p is in use by something other than lighttpd/nginx:\n$q\nStop it, or rerun with INSTALL_NGINX=0."
    done
  fi
}

# ----------------------------- read/write root -------------------------------
make_rw() {
  log "Making filesystem read/write"
  local bk="$STATE/backups/boot-$(date +%s)"; mkdir -p "$bk"
  cp -a /etc/fstab "$bk/fstab"
  awk 'BEGIN{OFS="\t"} /^[[:space:]]*#/||NF<4{print;next}
       ($2=="/"||$2=="/boot"||$2=="/boot/firmware"){
         n=split($4,o,","); s=""; ch=0
         for(i=1;i<=n;i++){ if(o[i]=="ro"){ch=1;continue} s=s (s?",":"") o[i] }
         if(ch){ if(s=="")s="defaults"; $4=s; print; next } }
       {print}' "$bk/fstab" > /etc/fstab.new && cat /etc/fstab.new > /etc/fstab && rm -f /etc/fstab.new
  local f
  for f in /boot/firmware/cmdline.txt /boot/cmdline.txt; do
    [[ -f $f ]] || continue
    cp -a "$f" "$bk/$(basename "$f")"
    for _ in 1 2 3; do
      sed -i -E 's/(^|[[:space:]])(ro|boot=overlay|overlayroot=[^[:space:]]*)([[:space:]]|$)/ /g' "$f"
    done
    sed -i -E 's/[[:space:]]+/ /g; s/^ //; s/ $//' "$f"
  done
  if command -v raspi-config >/dev/null; then
    raspi-config nonint disable_overlayfs 2>/dev/null || true
    raspi-config nonint disable_bootro   2>/dev/null || true
  fi
  mount -o remount,rw / || warn "remount,rw / failed"
  findmnt -no OPTIONS / | grep -qw rw || warn "Root does not look read/write yet; a reboot may be required."
}

# ----------------------------- packages --------------------------------------
CORE_PKGS=(git build-essential cmake pkg-config rsync curl jq ca-certificates sudo
  python3 python3-venv python3-pip python3-dev
  libasound2-dev libudev-dev libgps-dev libhamlib-dev libhamlib-utils libavahi-client-dev
  libgpiod-dev gpiod alsa-utils avahi-daemon lighttpd php-cgi php-cli ax25-tools ax25-apps
  rsyslog expect acl net-tools xterm)   # net-tools (ifconfig) and xterm (resize) are used by DigiPi's linpac.sh
OPT_PKGS=(gpsd gpsd-clients chrony uronode linpac wsjtx js8call fldigi flrig qsstv
  tmux sox ttyd python3-gpiod wmctrl xdotool fim bluez
  wfview freedv trustedqsl)
# DigiPi runs GUI apps in its own VNC display :1 (port 5901) and shows them in the web UI through noVNC (6080).
# Your Raspberry Pi desktop VNC (wayvnc, port 5900) is a different server; setup_desktop_vnc enables it (DESKTOP_VNC=0 to skip).
VNC_PKGS=(tigervnc-standalone-server tigervnc-tools novnc websockify x11-xserver-utils emwm openbox xterm)
MISSING_PKGS=()

install_packages() {
  log "Installing packages"
  apt-get update
  apt-get install -y "${CORE_PKGS[@]}"
  local p
  local opt=("${OPT_PKGS[@]}"); [[ $DIGIPI_VNC == 1 ]] && opt+=("${VNC_PKGS[@]}")
  for p in "${opt[@]}"; do
    if apt-cache show "$p" >/dev/null 2>&1; then
      apt-get install -y "$p" || { warn "install failed: $p"; MISSING_PKGS+=("$p"); }
    else
      warn "not in this release's arm64 repos: $p"; MISSING_PKGS+=("$p")
    fi
  done
  # Bookworm: no ttyd package / python3-gpiod is called python3-libgpiod
  if command -v ttyd >/dev/null; then MISSING_PKGS=("${MISSING_PKGS[@]/ttyd}")
  else
    local arch=$(uname -m) t=/usr/local/bin/ttyd
    if curl -fsSL --max-time 120 -o "$t.tmp" "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.$arch" && chmod +x "$t.tmp" && "$t.tmp" --version >/dev/null 2>&1; then
      mv -f "$t.tmp" "$t"; [[ -e /usr/bin/ttyd ]] || ln -s "$t" /usr/bin/ttyd; echo "  ttyd 1.7.7 installed from upstream release (web terminals)"
      MISSING_PKGS=("${MISSING_PKGS[@]/ttyd}")
    else rm -f "$t.tmp"; warn "ttyd unavailable: web terminal pages will not work"; fi
  fi
  python3 -c 'import gpiod' 2>/dev/null || apt-get install -y python3-libgpiod 2>/dev/null && MISSING_PKGS=("${MISSING_PKGS[@]/python3-gpiod}") || true
  local _m=(); for p in "${MISSING_PKGS[@]}"; do [[ -n $p ]] && _m+=("$p"); done; MISSING_PKGS=("${_m[@]}")
  printf 'ax25\nmkiss\n' > /etc/modules-load.d/digipi64.conf
  modprobe ax25 2>/dev/null || warn "ax25 kernel module not loadable on this kernel (AX.25 features will not work)."
  if [[ $ADD_GROUPS == 1 ]]; then
    local g
    for g in audio dialout plugdev gpio i2c spi video; do
      getent group "$g" >/dev/null && usermod -aG "$g" "$TARGET_USER"   # additive only
    done
  fi
}

build_direwolf() {
  log "Building Direwolf ($DIREWOLF_REF) -> /usr/local"
  local d=/opt/src/direwolf ref
  mkdir -p /opt/src
  for ref in "$DIREWOLF_REF" 1.7; do    # fall back to the 1.7 release if the dev branch will not build here
    rm -rf "$d"
    if git clone -q --branch "$ref" "$DIREWOLF_REPO" "$d" \
       && mkdir "$d/build" \
       && ( cd "$d/build" && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. && make -j"$(nproc)" && make install ); then
      break
    fi
    warn "Direwolf '$ref' failed to build"; [[ $ref == 1.7 ]] && die "Direwolf would not build; see output above."
  done
/usr/local/bin/direwolf -h 2>&1 | head -n1 || true
}

install_dashboard() {   # APRS map page (port 8088): hemna/direwolf-dashboard, which DigiPi's image carries in ~/direwolf-dashboard/.venv
  log "Installing direwolf-dashboard (APRS map) -> $TARGET_HOME/direwolf-dashboard"
  local d="$TARGET_HOME/direwolf-dashboard"
  if [[ ! -d $d ]]; then
    runuser -u "$TARGET_USER" -- git clone -q --depth 1 ${DASHBOARD_REF:+--branch "$DASHBOARD_REF"} "$DASHBOARD_REPO" "$d" || { warn "direwolf-dashboard clone failed: APRS Map page will not work"; review "direwolf-dashboard not installed"; return 0; }
  fi
  runuser -u "$TARGET_USER" -- bash -c "cd '$d' && python3 -m venv .venv && .venv/bin/pip install -q -e ." \
    || { warn "direwolf-dashboard install failed: APRS Map page will not work"; review "direwolf-dashboard not installed"; }
  return 0
}

build_modems() {   # 64-bit ARDOP and Mercury; failures are not fatal (the modes just stay unavailable)
  mkdir -p /opt/src
  if [[ $BUILD_ARDOP == 1 ]]; then
    log "Building ardopcf (ARDOP modem) -> /usr/local/bin"
    rm -rf /opt/src/ardop
    if git clone -q --depth 1 --branch "$ARDOP_REF" "$ARDOP_REPO" /opt/src/ardop && make -C /opt/src/ardop -j"$(nproc)" \
       && install -m 0755 /opt/src/ardop/ardopcf /usr/local/bin/ardopcf; then
      echo "  ardopcf installed"
    else warn "ardopcf failed to build: ARDOP mode will not work"; review "ardopcf not built (ARDOP unavailable)"; fi
  fi
  if [[ $BUILD_MERCURY == 1 ]]; then
    log "Building Mercury HF modem -> /usr/local/bin"
    rm -rf /opt/src/mercury
    apt-get install -y libpulse-dev libasound2-dev libhamlib-dev || true
    if git clone -q --depth 1 ${MERCURY_REF:+--branch "$MERCURY_REF"} "$MERCURY_REPO" /opt/src/mercury && make -C /opt/src/mercury -j"$(nproc)" \
       && make -C /opt/src/mercury install prefix=/usr/local; then
      echo "  mercury installed"
    else warn "Mercury failed to build: Mercury mode will not work"; review "mercury not built (Mercury unavailable)"; fi
  fi
}

fix_map_page() {   # map.php starts the dashboard with 'sudo su -c ... USER', which the sudo rules (rightly) refuse; use the narrow run-as form
  local f="$STAGE/var/www/html/map.php"
  [[ -f $f ]] || return 0
  TU="$TARGET_USER" perl -pi -e 's{exec\("sudo su -c \\"(/\S+/direwolf-dashboard\.sh) > /dev/null 2> /dev/null &\\" (\w+) " \);}{exec("sudo -u $ENV{TU} $1 > /dev/null 2> /dev/null &");}' "$f"
  # sudo's -i wraps the command in 'bash -c', which a path-based sudo rule can never match, so no '-i' anywhere
  perl -pi -e 's{sudo -i -u (\w+) (/\S+)}{sudo -u $1 $2}g' "$STAGE"/var/www/html/*.php
  local ds="$STAGE$TARGET_HOME/direwolf-dashboard.sh"   # without -i sudo may leave HOME alone; the dashboard reads ~/.config
  [[ -f $ds ]] && ! grep -q '^export HOME=' "$ds" && sed -i "1a export HOME=$TARGET_HOME" "$ds"
  # axcall.php starts the LinPac web terminal the same way ('sudo su -c ttyd ... linpac.sh USER'); give it a small wrapper
  local ax="$STAGE/var/www/html/axcall.php"
  if [[ -f $ax ]]; then
    cat > /usr/local/bin/digipi64-linpac-web <<LPEOF
#!/bin/bash
# started by the AX.25 page ("Run linpac"): LinPac in a browser terminal on port 7687, as $TARGET_USER
export HOME=$TARGET_HOME
pkill -u "\$(id -u)" -f 'ttyd.* -p 7687' 2>/dev/null
exec /usr/bin/ttyd -P 19 -t titleFixed=Linpac -W -p 7687 -t fontSize=18 -o -s SIGTERM $TARGET_HOME/linpac.sh
LPEOF
    chmod 0755 /usr/local/bin/digipi64-linpac-web
    TU="$TARGET_USER" perl -pi -e 's{exec\("export HOME=\S+; sudo su -c \\"/usr/bin/ttyd[^"]*?linpac\.sh\s+> /dev/null 2> /dev/null &\\" \w+\s+" \);}{exec("sudo -u $ENV{TU} /usr/local/bin/digipi64-linpac-web > /dev/null 2>&1 &");}' "$ax"
    grep -q 'digipi64-linpac-web' "$ax" && echo "  axcall.php: LinPac uses a narrow sudo rule" || { warn "could not patch axcall.php"; review "axcall.php LinPac launcher not patched"; }
  fi
  grep -q 'sudo -u' "$f" && echo "  map.php: uses a narrow sudo rule" || { warn "could not patch map.php"; review "map.php not patched (APRS Map may fail)"; }
}

patch_modems() {   # point DigiPi's ardop.sh / mercury.sh at the 64-bit programs and the right sound card
  local f="$STAGE$TARGET_HOME/ardop.sh"
  if [[ -x /usr/local/bin/ardopcf && -f $f ]]; then
    python3 - "$f" <<'PY'
import sys,re
f=sys.argv[1]; s=open(f).read()
s=s.replace('killall piardopc','killall ardopcf')
s=re.sub(r'^cd /tmp && /usr/local/bin/piardopc.*$',
 '# digipi64: ardopcf on the first USB sound card (override: ARDOP_AUDIO=plughw:1,0 in this script or ~/localize.env)\n'
 'ACARD=$(grep -i usb /proc/asound/cards | head -1 | cut -c 2-2)\n'
 'ADEV=${ARDOP_AUDIO:-${ACARD:+plughw:$ACARD,0}}; ADEV=${ADEV:-default}\n'
 'cd /tmp && /usr/local/bin/ardopcf -m -G 8514 8515 "$ADEV" "$ADEV"', s, flags=re.M)
open(f,'w').write(s)
PY
    echo "  ardop.sh now runs ardopcf"
  fi
  f="$STAGE$TARGET_HOME/mercury.sh"
  # neutralize() mistook the template copy for a dot-dir copy; it is a harmless file copy that mercury.sh needs
  [[ -f $f ]] && sed -i -E 's|^: # digipi64 disabled \(dot-dirs are symlinked\): (cp .*mercury\.ini\.template.*)$|\1|' "$f"
  if [[ -x /usr/local/bin/mercury && -f $f ]]; then
    python3 - "$f" <<'PY'
import sys
f=sys.argv[1]; s=open(f).read()
marker='/usr/bin/'  # no-op guard
add=('\n# digipi64: use the first USB sound card instead of the fixed card 0\n'
     'ACARD=$(grep -i usb /proc/asound/cards | head -1 | cut -c 2-2)\n'
     '[ -n "$ACARD" ] && sed -i "s/plughw:0,0/plughw:$ACARD,0/g" ' + '"$HOME/.config/mercury/mercury.ini"\n')
key='sed -i "s/BAUDRATE/$NEWBAUDRATE/gi"'
i=s.find(key)
if i>=0:
    j=s.find('\n',i)+1
    s=s[:j]+add+s[j:]
open(f,'w').write(s)
PY
    echo "  mercury.sh uses the first USB sound card"
  fi
}

install_pat() {
  log "Installing Pat (Winlink)"
  if ! command -v pat >/dev/null; then
    local url
    url=$(curl -fsSL https://api.github.com/repos/la5nta/pat/releases/latest \
          | jq -r '.assets[].browser_download_url | select(test("linux_arm64\\.deb$"))' | head -n1 || true)
    if [[ -n $url ]]; then
      curl -fsSL "$url" -o /tmp/pat.deb && apt-get install -y /tmp/pat.deb && rm -f /tmp/pat.deb
    else
      apt-get install -y pat || warn "Pat could not be installed."
    fi
  fi
  if ! command -v pat >/dev/null && command -v pat-winlink >/dev/null; then
    ln -sf "$(command -v pat-winlink)" /usr/local/bin/pat
  fi
}

install_aprsd() {
  log "Installing APRSD (venv: $VENV, as $TARGET_USER)"
  runuser -u "$TARGET_USER" -- python3 -m venv "$VENV"
  runuser -u "$TARGET_USER" -- "$VENV/bin/pip" install -q -U pip wheel
  runuser -u "$TARGET_USER" -- "$VENV/bin/pip" install -q "aprsd==$APRSD_VERSION" \
    || { warn "aprsd==$APRSD_VERSION failed; trying latest"; runuser -u "$TARGET_USER" -- "$VENV/bin/pip" install -q aprsd; }
  # APRSD 4.x moved the 'webchat' command into a separate extension package
  runuser -u "$TARGET_USER" -- "$VENV/bin/pip" install -q aprsd-webchat-extension \
    || { warn "aprsd-webchat-extension failed to install: the Webchat page will not work"; review "aprsd-webchat-extension not installed"; }
  [[ -x $VENV/bin/aprsd ]] && ln -sf "$VENV/bin/aprsd" /usr/local/bin/aprsd
  return 0
}

setup_vnc() {   # DigiPi's GUI apps run in 'vncserver' display :1 + noVNC
  [[ $DIGIPI_VNC == 1 ]] || { review "DIGIPI_VNC=0: WSJT-X/FLDigi/JS8Call/QSSTV will not appear in the DigiPi web UI"; return 0; }
  command -v tigervncserver >/dev/null || { warn "tigervncserver not installed; DigiPi GUI apps will not display"; review "tigervncserver missing"; return 0; }
  # Raspberry Pi OS ships RealVNC's 'vncserver' (a different program); DigiPi's scripts need TigerVNC's, always on display :1 (noVNC uses 5901)
  cat > /usr/local/bin/vncserver <<'EOF2'
#!/bin/bash
# digipi64: DigiPi scripts call 'vncserver -depth 16' / 'vncserver -kill :1'; use TigerVNC on display :1
real=/usr/bin/tigervncserver
for a in "$@"; do case $a in :[0-9]*|-kill|-list|-version|-h|--help) exec "$real" "$@" ;; esac; done
exec "$real" :1 -localhost yes "$@"
EOF2
  chmod 0755 /usr/local/bin/vncserver
  install -d /etc/tigervnc
  grep -qs "^:1=$TARGET_USER\$" /etc/tigervnc/vncserver.users || echo ":1=$TARGET_USER" >> /etc/tigervnc/vncserver.users
  [[ -x /usr/share/novnc/utils/novnc_proxy ]] || review "novnc_proxy not at /usr/share/novnc/utils/novnc_proxy; GUI apps will not show in the web UI"
  return 0
}

# ----------------------------- repo -> stage ---------------------------------
ensure_area() { grep -qxF "$1" "$STATE/areas.list" 2>/dev/null || echo "$1" >> "$STATE/areas.list"; }

map_dir() {   # <repo subdir> <destination on target>
  [[ -d $SRC/$1 ]] || { warn "repo has no '$1' - skipped"; return 0; }
  mkdir -p "$STAGE$2"; cp -a "$SRC/$1/." "$STAGE$2/"; ensure_area "$2"
  echo "  $1  ->  $2"
}

stage_repo() {
  log "Fetching DigiPi files ($DIGIPI_REPO @ $DIGIPI_REF)"
  rm -rf "$SRC" "$STAGE"; mkdir -p "$STAGE"; : > "$STATE/areas.list"; : > "$REVIEW"
  git clone -q --depth 1 --branch "$DIGIPI_REF" "$DIGIPI_REPO" "$SRC"
  map_dir etc/ax25          /etc/ax25
  map_dir etc/systemd       /etc/systemd/system     # units are directly in etc/systemd (no 'system' subdir)
  map_dir home/pi           "$TARGET_HOME"
  map_dir local             /usr/local              # the repo's 'local' IS /usr/local
  map_dir var/www/html      /var/www/html
  local d n
  for d in "$SRC"/*/; do n=$(basename "$d")
    case $n in etc|home|local|var|.git) ;; *) warn "unmapped top-level repo dir '$n' (review)"; review "unmapped repo dir: $n" ;; esac
  done
  clean_stage
}

clean_stage() {   # the repo is a snapshot of a running 32-bit image: drop everything that must not reach this system
  log "Removing image-snapshot artifacts from the staged files"
  local H="$STAGE$TARGET_HOME" W="$STAGE/var/www/html" L="$STAGE/usr/local" n; local dots=()
  if [[ -d $H ]]; then   # author's dotfiles, caches, history; .config/.local/.fldigi/.flrig/.vnc are symlinks into /run
    for n in "$H"/.[!.]*; do [[ -e $n || -L $n ]] || continue; dots+=("$(basename "$n")"); rm -rf "$n"; done
    review "image dotfiles NOT deployed (your own ~/.* are never touched): ${dots[*]:-none}"
  fi
  find "$STAGE" -type l -lname '/tmp/*' -delete 2>/dev/null || true   # pulse runtime sockets recorded in the image snapshot
  if [[ -f $STAGE/etc/ax25/axspawn.conf ]]; then   # axspawn must not create system accounts for AX.25 logins
    sed -i -E 's/^([[:space:]]*create_with_useradd[[:space:]]+)yes/\1no/' "$STAGE/etc/ax25/axspawn.conf"
    review "axspawn.conf: create_with_useradd set to 'no' (keeps your user accounts as they are)"
  fi
  find "$STAGE" -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null || true
  find "$STAGE" -type f \( -name '*.213' -o -name '*.201' -o -name '*.screen' -o -name '*.pyc' \) -delete
  rm -f "$H/direwolf.log" "$H/localize.env.orig" "$H/temp.py" "$H/config/aprsd/statsstore.json"
  find "$H/local/share" -type f \( -name ALL.TXT -o -name DIRECTED.TXT -o -name '*.db3' -o -name FoxQSO.txt \
       -o -name db.sqlite -o -name timer.out -o -name '*wisdom.dat' \) -delete 2>/dev/null || true   # author's operating logs
  rm -rf "$W/bak"; find "$W" -type f \( -name '*.bak' -o -name '*.orig' \) -delete 2>/dev/null || true   # bak/ = unpatched setup.php
  rm -rf "$L/lib" "$L/include"                                                                          # 32-bit libs + python3.13 dist-packages
  find "$L" -type f \( -name '*.a' -o -name '*.la' -o -name '*.so' -o -name '*.so.*' \) -delete 2>/dev/null || true
  # 32-bit ARM executables can't run on 64-bit Trixie (and would shadow your 64-bit builds): remove, remember names.
  python3 - "$STAGE" "$STATE/elf-removed.txt" <<'PY'
import os, sys
root, out = sys.argv[1:3]
with open(out, 'w') as o:
    for d, _, fs in os.walk(root):
        for f in fs:
            p = os.path.join(d, f)
            if os.path.islink(p): continue
            try:
                with open(p, 'rb') as fh: magic = fh.read(4)
            except OSError: continue
            if magic == b'\x7fELF':
                os.remove(p); o.write(os.path.relpath(p, root) + "\n")
            elif magic[:2] == b'#!':
                os.chmod(p, os.stat(p).st_mode | 0o111)       # scripts must be executable
PY
  echo "  removed $(wc -l < "$STATE/elf-removed.txt") 32-bit ARM binaries (list: $STATE/elf-removed.txt)"
}

fix_units() {   # repair unit files for this system (runs after sub_user)
  log "Repairing unit files"
  local U="$STAGE/etc/systemd/system"
  [[ -d $U ]] || return 0
  if [[ ! -f $U/conversd.service ]] && ! command -v conversd >/dev/null && [[ ! -e $STAGE/usr/local/sbin/conversd ]] \
     && grep -q '^Requires=conversd.service' "$U/node.service" 2>/dev/null; then
    sed -i '/^Requires=conversd\.service/d' "$U/node.service"
    review "node.service: removed Requires=conversd.service (the repo has no conversd unit/binary; Convers chat bridge unavailable)"
  fi
  if [[ ! -f $U/tracker.service && -f $U/tnc.service && -f $STAGE$TARGET_HOME/direwolf.tracker.sh ]]; then
    sed -e 's/^Description=tnc/Description=tracker/' -e 's#direwolf\.tnc\.sh#direwolf.tracker.sh#' \
        -e '/^ExecStartPre=+systemctl stop/ s/ tracker$/ tnc/' "$U/tnc.service" > "$U/tracker.service"
    review "generated tracker.service from tnc.service (every page references it, the repo doesn't ship it)"
  fi
  return 0
}

# ---- everything below edits ONLY the staged copy (never the live system) ----
sub_user() {
  [[ $TARGET_USER == pi && $TARGET_HOME == /home/pi ]] && return 0
  log "Rewriting 'pi' -> '$TARGET_USER' in staged files"
  grep -rIlE 'home/pi|(^|[^[:alnum:]_])pi:pi|^(User|Group)=pi$|(-u|su|chown) +pi\b' "$STAGE" 2>/dev/null |
  while IFS= read -r f; do
    sed -i -E "s#/home/pi#${TARGET_HOME}#g; s#(^|[[:space:]\"'=:])home/pi\\b#\\1${TARGET_HOME#/}#g; s#^User=pi\$#User=${TARGET_USER}#; s#^Group=pi\$#Group=${TARGET_USER}#;
               s#(^|[^[:alnum:]_])pi:pi#\1${TARGET_USER}:${TARGET_USER}#g;
               s#((-u|su|chown) +)pi\b#\1${TARGET_USER}#g" "$f"
  done || true
  # symlinks shipped in the repo that point into /home/pi
  find "$STAGE" -type l | while IFS= read -r l; do
    t=$(readlink "$l"); [[ $t == /home/pi* ]] && ln -sfn "${TARGET_HOME}${t#/home/pi}" "$l"
  done || true
}

neutralize() {   # stop the Initialize scripts from touching hostname / accounts
  log "Protecting hostname and user account from Initialize"
  local RE_HOST='^[[:space:]]*(sudo[[:space:]]+)?(hostnamectl[[:space:]]+set-hostname|raspi-config[[:space:]]+nonint[[:space:]]+do_hostname|echo[^|;&]*>[[:space:]]*/etc/hostname)[^;&|\\]*$'
  local RE_ACCT='^[[:space:]]*(sudo[[:space:]]+)?(usermod|useradd|userdel|adduser|chpasswd|passwd|echo[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?chpasswd)\b[^;&|\\]*$'
  local RE_COPY='^[[:space:]]*(sudo[[:space:]]+)?(cp|rsync)\b[^;&|\\]*[[:space:]/~]\.(config|local|wl2k|fldigi|flrig)\b[^;&|\\]*$'
  local f
  while IFS= read -r f; do
    head -c2 "$f" | grep -q '^#!' || continue
    head -n1 "$f" | grep -qE 'ba?sh|/sh' || continue
    grep -qE "$RE_HOST|$RE_ACCT|$RE_COPY" "$f" || continue
    cp -a "$f" "$f.orig"
    sed -i -E "\\#${RE_COPY}# s|^([[:space:]]*)(.*)\$|\\1: # digipi64 disabled (dot-dirs are symlinked): \\2|" "$f"
    sed -i -E "\\#${RE_HOST}# s|^([[:space:]]*)(.*)\$|\\1: # digipi64 disabled: \\2|" "$f"
    sed -i -E "\\#${RE_ACCT}# s|^([[:space:]]*)(.*)\$|\\1: # digipi64 disabled: \\2|" "$f"
    if bash -n "$f" 2>/dev/null; then rm -f "$f.orig"; review "neutralized hostname/account/dot-dir-copy command in ${f#$STAGE}"
    else mv -f "$f.orig" "$f"; review "COULD NOT auto-disable hostname/account change in ${f#$STAGE} - edit by hand"; fi
  done < <(find "$STAGE" -type f ! -name '*.orig')
  # anything left (PHP, multi-line shell, ...) is reported, not guessed at
  grep -rnIE 'set-hostname|/etc/hostname|do_hostname|chpasswd|usermod|useradd|adduser|[^/a-z]passwd[[:space:]]' "$STAGE" 2>/dev/null \
    | grep -v 'digipi64 disabled' | sed "s#$STAGE##" | sed 's/^/REVIEW remaining: /' >> "$REVIEW" || true
  grep -rnIE 'config\.txt|cmdline\.txt|dtoverlay|raspi-config' "$STAGE" 2>/dev/null \
    | grep -v 'digipi64 disabled' | sed "s#$STAGE##" | sed 's|^|REVIEW boot or system config touched: |' >> "$REVIEW" || true
}

triage_units() {   # keep read-only-kiosk plumbing from being installed
  log "Triaging systemd units"
  local U="$STAGE/etc/systemd/system" Q="$STATE/skipped-units" f n why
  local KIOSK_RE='tmpfs|overlay|remount|ramdisk|ramfs|umount|resolv\.conf|^Exec[A-Za-z]*=.*(rsync|[[:space:]]cp[[:space:]]+-[a-zA-Z]*[[:space:]].*\.(config|local|wl2k|fldigi|flrig))'
  local NET_RE='10\.0\.0\.5|hostapd|dnsmasq|wpa_supplicant|dhcpcd|nmcli|wlan0|hotspot'
  local VNC_RE='^Exec[A-Za-z]*=.*(vncserver|Xvnc|x11vnc|websockify|novnc)'
  rm -rf "$Q"; mkdir -p "$Q"; SKIPPED_UNITS=()
  [[ -d $U ]] || return 0
  for f in "$U"/*; do
    [[ -f $f ]] || continue; n=$(basename "$f")
    [[ " $FORCE_UNITS " == *" $n "* ]] && continue
    why=$(grep -inE "$KIOSK_RE" "$f" | head -n2 || true)
    [[ -z $why ]] && why=$(grep -inE "$NET_RE" "$f" | head -n2 | sed 's/^/network takeover: /' || true)
    if [[ -z $why && $DIGIPI_VNC != 1 ]]; then
      why=$(grep -inE "$VNC_RE" "$f" | head -n2 | sed 's/^/DigiPi VNC session (DIGIPI_VNC=0): /' || true)
      [[ -z $why && $n =~ vnc ]] && why="DigiPi VNC session (DIGIPI_VNC=0): unit name"
    fi
    if [[ -n $why ]]; then
      mv "$f" "$Q/"; SKIPPED_UNITS+=("$n")
      review "SKIPPED unit $n (looks like read-only/kiosk plumbing): ${why//$'\n'/ | }"
    fi
  done
  grep -nE 'DISPLAY=|[Vv][Nn][Cc]' "$U"/* 2>/dev/null | sed "s#$STAGE#REVIEW unit mentions DISPLAY/VNC (GUI apps may expect DigiPi's :1 session): #" >> "$REVIEW" || true
  grep -rlE 'tmpfs|overlay|remount|ramdisk' "$STAGE/usr/local" "$STAGE$TARGET_HOME" 2>/dev/null \
    | sed "s#$STAGE#REVIEW script touches mounts/tmpfs: #" >> "$REVIEW" || true
}

inject_reconfigure() {   # "Initialize" can be run again
  log "Adding Reconfigure support to the web UI"
  local W="$STAGE/var/www/html" f
  mkdir -p "$W"; ensure_area /var/www/html
  cat > "$W/reconfigure.php" <<'PHPEOF'
<?php
// Added by digipi64-setup: restores clean DigiPi config and re-opens Initialize.
$msg = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    exec('sudo -n /usr/local/sbin/digipi64-setup reconfigure 2>&1', $out, $rc);
    $msg = ($rc === 0)
        ? 'Defaults restored (your previous files were backed up). <a href="/setup.php">Continue to Initialize</a>.'
        : 'Reconfigure failed (exit ' . intval($rc) . '):<pre>' . htmlspecialchars(implode("\n", array_slice($out, -20))) . '</pre>';
}
?><!doctype html><html><head><meta charset="utf-8"><title>DigiPi Reconfigure</title></head><body>
<h2>Reconfigure DigiPi</h2>
<p>Restores the default DigiPi config files (current ones are backed up) and unlocks Initialize
so you can change callsign, etc. Hostname and user account are never changed.</p>
<?php if ($msg !== '') echo "<p>$msg</p>"; ?>
<form method="post"><button type="submit">Reset to defaults and re-run Initialize</button></form>
<p><a href="/">Back</a></p></body></html>
PHPEOF
  patch_setup_php
  install_helpers
}

patch_setup_php() {   # make Initialize safe and re-runnable (setup.php v2.2-1 layout)
  local f="$STAGE/var/www/html/setup.php" pl; pl=$(mktemp)
  [[ -f $f ]] || { warn "setup.php not found in repo; only /reconfigure.php is available"; return 0; }
  cat > "$pl" <<'PERL'
# 1) shell-injectable "sudo sed -i" writes -> validated root helper
s{shell_exec\("sudo sed -i 's/(NEW[A-Z0-9]+)=\.\*/\1=\$(\w+)/gi'\s+\S*localize\.env\s*"\)}{digipi_set('$1', \$$2)}g;
s{shell_exec\("sudo sed -i 's/(NEW[A-Z0-9]+)=\.\*/\1=(\d+)/gi'\s+\S*localize\.env\s*"\)}{digipi_set('$1', '$2')}g;
s{shell_exec\("sudo sed -i 's/\^ExecStart=\.\*/ExecStart=systemctl start \$defaultservice/gi' /etc/systemd/system/digipi-boot\.service"\)}{digipi_set('BOOTSERVICE', \$defaultservice)}g;
# 2) Reconfigure button shown in the "already initialized" branch
s{(the Initialize button here again\.';)}{$1\n    echo '<br/><br/><input type="submit" name="digipi64_reconfigure" value="Reconfigure (restore defaults, then Initialize)">';};
# 3) helper + reconfigure handler, before any output
$_ = <<'HDR' . $_;
<?php
function digipi_set($k, $v) {
    return shell_exec('sudo -n /usr/local/sbin/digipi64-setenv ' . escapeshellarg($k) . ' ' . escapeshellarg((string)$v) . ' 2>&1');
}
if (isset($_POST['digipi64_reconfigure'])) {
    exec('sudo -n /usr/local/sbin/digipi64-setup reconfigure 2>&1', $digipi64_out, $digipi64_rc);
}
?>
HDR
PERL
  perl -0pi "$pl" "$f"; rm -f "$pl"
  local left; left=$(grep -c 'sudo sed' "$f" || true)
  if [[ $left -gt 0 ]] || ! grep -q digipi64_reconfigure "$f"; then
    warn "setup.php did not match the expected layout (unpatched sudo sed: $left)."
    review "setup.php only partly patched - upstream layout changed; web Initialize may need manual work"
  else
    echo "  setup.php patched: safe setter + Reconfigure button"
  fi
  if command -v php >/dev/null && ! php -l "$f" >/dev/null 2>&1; then
    warn "patched setup.php has a PHP syntax error"; review "patched setup.php fails php -l"
  fi
}

install_helpers() {   # root-owned helpers the patched web UI calls through sudo
  local B="$STAGE/usr/local" ; mkdir -p "$B/sbin" "$B/bin"; ensure_area /usr/local
  cat > "$B/sbin/digipi64-setenv" <<'EOF'
#!/usr/bin/env bash
# Validated setter for localize.env / boot service. Called by setup.php via sudo.
set -euo pipefail
ENVF="__ENVF__"; UNIT=/etc/systemd/system/digipi-boot.service
key=${1:-}; val=${2:-}
case $key in
  NEWCALL|NEWWLPASS|NEWAPRSPASS|NEWGRID|NEWLAT|NEWLON|NEWGPS|NEWNODEPASS|NEWDISPLAYTYPE|\
  NEWRIGNUMBER|NEWDEVICEFILE|NEWBAUDRATE|NEWI2CAUDIO|NEWFLRIG|NEWBIGVNC)
    [[ $val =~ ^[[:alnum:]._@+:,#%^*!?~=-]{1,64}$ ]] || { echo "rejected value for $key" >&2; exit 3; }
    [[ -f $ENVF ]] || { echo "missing $ENVF" >&2; exit 4; }
    sed -i -E "s|${key}=.*|${key}=${val}|" "$ENVF" ;;
  BOOTSERVICE)
    case $val in tnc|tnc300b|tracker|digipeater|webchat|node|winlinkrms|wsjtx|js8call|sstv|fldigi) ;; *) exit 3 ;; esac
    [[ -f $UNIT ]] || { echo "missing $UNIT" >&2; exit 4; }
    sed -i -E "s|^ExecStart=.*|ExecStart=systemctl start ${val}|" "$UNIT"; systemctl daemon-reload ;;
  *) echo "unknown key" >&2; exit 2 ;;
esac
EOF
  sed -i "s#__ENVF__#${TARGET_HOME}/localize.env#" "$B/sbin/digipi64-setenv"
  chmod 0755 "$B/sbin/digipi64-setenv"
  if [[ ! -e $B/bin/remount ]]; then   # setup.php runs 'sudo /usr/local/bin/remount' on every load
    printf '#!/bin/sh\nmount -o remount,rw / 2>/dev/null\nexit 0\n' > "$B/bin/remount"; chmod 0755 "$B/bin/remount"
    review "repo had no usr/local/bin/remount; installed a harmless rw-remount shim"
  else
    head -c2 "$B/bin/remount" | grep -q '^#!' || sed -i '1i #!/bin/sh' "$B/bin/remount"   # repo copy has no shebang
  fi
  chmod 0755 "$B/bin/remount"
  fix_localize
}

fix_localize() {   # localize.sh: stray prose lines would run as commands; make sure it is executable
  local f="$STAGE$TARGET_HOME/localize.sh"
  [[ -f $f ]] || return 0
  sed -i -E 's/^(Initialization values move to .*)$/# \1/; s/^([[:space:]]+sudo (remount|nano localize\.env))[[:space:]]*$/# \1/' "$f"
  chmod 0755 "$f"; bash -n "$f" || review "localize.sh has a syntax problem after staging"
  # Save Configuration (index.php -> saveconfigs.sh) rsyncs ~/.config etc. into ~/config with --delete. With our
  # symlinks that would replace real files with links to themselves, so keep only the harmless part.
  local s="$STAGE$TARGET_HOME/saveconfigs.sh"
  if [[ -f $s ]]; then
    cat > "$s" <<'EOF'
#!/bin/sh
# digipi64: ~/.config, ~/.local, ~/.fldigi and ~/.flrig point into the DigiPi config folders on this
# read/write system, so settings are already saved. Only the ALSA mixer state still needs storing.
echo "Writing runtime app configs to SD card."
sudo alsactl store
echo "Settings are saved as you change them; no reboot needed."
EOF
    chmod 0755 "$s"
  fi
  local x="$STAGE$TARGET_HOME/vnc/xstartup"
  if [[ -f $x ]]; then
    chmod 0755 "$x"; chmod 0600 "$STAGE$TARGET_HOME/vnc/passwd" 2>/dev/null || true
    if ! command -v emwm >/dev/null; then
      sed -i -E 's/^emwm[[:space:]]*$/openbox/' "$x"
      review "emwm is not available; DigiPi's VNC session uses openbox instead (needed for wmctrl maximize)"
    fi
  fi
  return 0
}

fix_php8() {   # DigiPi's pages were written for PHP 7: putenv("") (grep found nothing) is a fatal error on PHP 8
  log "Making DigiPi web pages PHP 8 safe"
  local f n=0
  while IFS= read -r f; do
    if grep -q 'putenv(shell_exec(' "$f"; then
      perl -pi -e 's{putenv\(shell_exec\(("[^"]*")\)\);}{putenv(trim((string)shell_exec($1)) ?: "DIGIPI_UNSET=");}g' "$f"; n=$((n+1))
    fi
  done < <(find "$STAGE/var/www/html" -maxdepth 2 -type f -name '*.php' ! -path '*/bak/*')
  echo "  patched putenv() calls in $n page(s)"
}
reconfigure_link() {   # the home page hides its Initialize link once localized.txt exists; show a Reconfigure link instead
  local f="$STAGE/var/www/html/index.php"
  [[ -f $f ]] || return 0
  perl -0pi -e 's{(Initialize</strong></font></a> </td></tr>\x27;\n\s*\})}{$1 else {\n    echo \x27<tr><td colspan=3><a href="/setup.php" title="Change callsign and other local information (restores default config files, then re-runs Initialize)"><strong>Reconfigure</strong></a> </td></tr>\x27;\n  }}' "$f"
  grep -q '>Reconfigure<' "$f" && echo "  home page: Reconfigure link added" || { warn "could not add Reconfigure link to index.php (use /setup.php directly)"; review "no Reconfigure link on the home page; open /setup.php"; }
}
build_stage() { stage_repo; sub_user; fix_units; neutralize; triage_units; inject_reconfigure; fix_php8; reconfigure_link; patch_modems; fix_map_page; }


# ----------------------------- Initialize / reconfigure support --------------
init_targets() {   # files Initialize edits, read from localize.sh itself (only those that ship in the repo)
  local ls="$STAGE$TARGET_HOME/localize.sh" p
  [[ -f $ls ]] || return 0
  { grep -E '^[[:space:]]*sed -i' "$ls" | grep -oE '(^|[[:space:]])(etc|usr|home|var)/[A-Za-z0-9_./-]+' \
      | sed -E 's/^[[:space:]]+//; s#^#/#'
    echo "$TARGET_HOME/localize.env"
    for p in "$STAGE$TARGET_HOME"/direwolf*.conf; do [[ -f $p ]] && echo "${p#$STAGE}"; done
  } | sort -u | while IFS= read -r p; do [[ -f $STAGE$p ]] && echo "$p"; done
}

restore_templates() {   # reconfigure: put back ONLY the files Initialize rewrites (placeholders), not your app data
  log "Restoring Initialize templates (backup first)"
  local bk="$STATE/backups/reconf-$(date +%Y%m%d-%H%M%S)" f n=0
  while IFS= read -r f; do
    mkdir -p "$bk$(dirname "$f")"; [[ -e $f ]] && cp -a "$f" "$bk$f"
    if [[ -e $f ]]; then cat "$STAGE$f" > "$f"
    else mkdir -p "$(dirname "$f")"; cp --no-preserve=ownership "$STAGE$f" "$f"
         [[ $f == "$TARGET_HOME"/* ]] && chown "$TARGET_USER:$TARGET_USER" "$f"; fi
    n=$((n+1))
  done < <(init_targets)
  echo "  restored $n file(s); backups in $bk"
  ensure_gpsd_default reset
  systemctl daemon-reload
}

ensure_gpsd_default() {   # localize.sh edits the first 'ttyACM1' in /etc/default/gpsd, so that placeholder must exist
  local f=/etc/default/gpsd
  [[ -f $f ]] || return 0
  if [[ ${1:-} == reset ]]; then
    [[ -f $STATE/gpsd.managed ]] && sed -i -E 's|^DEVICES=.*|DEVICES="/dev/ttyACM1"|' "$f"
    return 0
  fi
  if ! grep -qE '^DEVICES="?[^" ]' "$f"; then            # only if you had no GPS device configured
    cp -a "$f" "$STATE/backups/gpsd.default.orig" 2>/dev/null || true
    sed -i -E 's|^DEVICES=.*|DEVICES="/dev/ttyACM1"|' "$f"
    grep -qE '^GPSD_OPTIONS="?-' "$f" || sed -i -E 's|^GPSD_OPTIONS=.*|GPSD_OPTIONS="-n"|' "$f"
    touch "$STATE/gpsd.managed"; echo "  /etc/default/gpsd: set DigiPi placeholder device ttyACM1 (Initialize replaces it)"
  else
    review "/etc/default/gpsd already has your GPS device; Initialize's GPS field will not change it"
  fi
}

link_dotdirs() {   # DigiPi's image copies ~/config -> /run/.config at boot; on a RW system link instead (never overwrite)
  log "Linking DigiPi config dirs to the dot-directories the apps read"
  local H=$TARGET_HOME d n a b f
  local SKIP_CONFIG=" pulse fish uv systemd "   # your desktop/audio stack, not DigiPi apps
  local SKIP_LOCAL=" bin wireplumber "
  link1() {   # <target> <linkname>
    if [[ -L $2 ]]; then [[ $(readlink "$2") == "$1" ]] || review "kept existing symlink $2 -> $(readlink "$2") (DigiPi expects $1)"; return 0; fi
    if [[ -e $2 ]]; then review "CONFLICT: $2 already exists and was NOT replaced; DigiPi settings in $1 won't reach that app"; return 0; fi
    runuser -u "$TARGET_USER" -- mkdir -p "$(dirname "$2")"
    runuser -u "$TARGET_USER" -- ln -s "$1" "$2"; echo "  $2 -> $1"
  }
  for d in wl2k:.wl2k fldigi:.fldigi flrig:.flrig; do
    [[ -d $H/${d%%:*} ]] && link1 "$H/${d%%:*}" "$H/${d##*:}"
  done
  if [[ -d $H/config ]]; then
    for n in "$H"/config/*; do
      [[ -e $n ]] || continue; [[ $SKIP_CONFIG == *" $(basename "$n") "* ]] && continue
      link1 "$n" "$H/.config/$(basename "$n")"
    done
  fi
  if [[ -d $H/local ]]; then
    for a in "$H"/local/*; do
      [[ -e $a ]] || continue; [[ $SKIP_LOCAL == *" $(basename "$a") "* ]] && continue
      if [[ -d $a && ! -L $a ]]; then   # link one level down so your ~/.local/share etc. stay yours
        for b in "$a"/*; do
          [[ -e $b ]] || continue; [[ $SKIP_LOCAL == *" $(basename "$b") "* ]] && continue
          link1 "$b" "$H/.local/$(basename "$a")/$(basename "$b")"
        done
      else link1 "$a" "$H/.local/$(basename "$a")"; fi
    done
  fi
  if [[ $DIGIPI_VNC == 1 && -d $H/vnc ]]; then   # ~/.vnc -> /run/.vnc on the image; vncserver reads ~/.vnc/{xstartup,passwd}
    if [[ ! -e $H/.vnc && ! -L $H/.vnc ]]; then link1 "$H/vnc" "$H/.vnc"
    else for f in xstartup passwd; do [[ -e $H/vnc/$f ]] && link1 "$H/vnc/$f" "$H/.vnc/$f"; done; fi
  fi
  return 0
}

link_replacements() {   # 32-bit DigiPi binaries were removed from the stage: point /usr/local names at 64-bit system ones
  log "Mapping removed 32-bit binaries to 64-bit equivalents"
  [[ -f $STATE/elf-removed.txt ]] || return 0
  local f n real; local -a none=()
  while IFS= read -r f; do
    [[ $f == usr/local/bin/* || $f == usr/local/sbin/* ]] || continue
    n=$(basename "$f"); [[ -e /$f ]] && continue
    case $n in ttyd.static) real=$(command -v ttyd || true) ;; direwolf-*) real=$(command -v direwolf || true) ;; piardopc*) real=$(command -v ardopcf || true) ;; *) real=$(PATH=/usr/sbin:/usr/bin:/sbin:/bin command -v "$n" || true) ;; esac
    if [[ -n $real ]]; then ln -s "$real" "/$f"; echo "  /$f -> $real"; else none+=("$n"); fi
  done < "$STATE/elf-removed.txt"
  (( ${#none[@]} )) && review "no 64-bit replacement for these DigiPi binaries (features that need them won't work): ${none[*]}"
  # LinPac helper programs: Debian's linpac package ships them elsewhere; ~/config/LinPac/bin links expect /usr/local/libexec/linpac
  if [[ ! -e /usr/local/libexec/linpac ]]; then
    local lp; lp=$(dpkg -L linpac 2>/dev/null | grep -E '/(mheard|autotx|logbook)$' | head -n1 || true)
    if [[ -n $lp ]]; then mkdir -p /usr/local/libexec; ln -sfn "$(dirname "$lp")" /usr/local/libexec/linpac; echo "  /usr/local/libexec/linpac -> $(dirname "$lp")"
    else review "linpac helper programs not found (LinPac plugins that call them will not work)"; fi
  fi
  # leftovers that point nowhere on this system
  local l; for l in "$TARGET_HOME"/local/bin/uv "$TARGET_HOME"/local/bin/uvx /usr/local/bin/wconvers /usr/local/bin/lconvers /usr/local/bin/ppconvers; do
    if [[ -L $l && ! -e $l ]]; then rm -f "$l"
    elif [[ $l == "$TARGET_HOME"/local/bin/uv* && -f $l && ! -s $l ]]; then rm -f "$l"; fi   # empty files an earlier run created
  done
  find "$TARGET_HOME/config/LinPac/bin" -xtype l -delete 2>/dev/null || true   # LinPac helpers Debian's package does not ship
  # DigiPi scripts write these in /run as the normal user (on the image /run is writable); recreate them at every boot
  printf 'f /run/direwolf.log 0664 %s %s -\nf /run/direwatch.png 0664 %s %s -\nf /run/direwatch1.png 0664 %s %s -\nf /run/direwatch2.png 0664 %s %s -\n' \
    "$TARGET_USER" "$TARGET_USER" "$TARGET_USER" "$TARGET_USER" "$TARGET_USER" "$TARGET_USER" "$TARGET_USER" "$TARGET_USER" > /etc/tmpfiles.d/digipi64.conf
  systemd-tmpfiles --create /etc/tmpfiles.d/digipi64.conf 2>/dev/null || true
  # localize.sh seds this file; it does not exist on a normal Pi
  [[ -e /etc/tightvncserver.conf ]] || echo '# digipi64 placeholder (Initialize edits the geometry here; DigiPi VNC uses tigervnc)' > /etc/tightvncserver.conf
  return 0
}

audit_script_paths() {   # absolute tool paths that DigiPi scripts call must exist on this system
  local x
  grep -rhoE '/usr/(local/)?(s?bin|share/novnc/utils)/[A-Za-z0-9_.+-]+' "$STAGE$TARGET_HOME"/*.sh "$STAGE/usr/local/bin"/*.sh 2>/dev/null \
    | sort -u | while IFS= read -r x; do
      [[ -e $x || -e $STAGE$x ]] || { echo "  scripts reference missing $x"; review "scripts call $x but it does not exist on this system"; }
    done || true
  return 0
}

audit_localize_targets() {   # every file Initialize will sed must exist on THIS system
  local ls="$TARGET_HOME/localize.sh" p
  [[ -f $ls ]] || return 0
  grep -E '^[[:space:]]*sed -i' "$ls" | grep -oE '(^|[[:space:]])(etc|usr|home|var|boot)/[A-Za-z0-9_./-]+' \
    | sed -E 's/^[[:space:]]+//; s#^#/#' | sort -u |
  while IFS= read -r p; do
    [[ -e $p ]] || { echo "  Initialize edits a file that does not exist: $p"; review "localize.sh edits $p but it doesn't exist here - that setting will not apply"; }
  done
  return 0
}

python_deps() {   # DigiPi's display/GPIO scripts (digibanner.py, direwatch...) import modules; find and install what Debian offers
  log "Checking Python modules used by DigiPi scripts"
  local -A PYAPT=([PIL]=python3-pil [numpy]=python3-numpy [pygame]=python3-pygame [spidev]=python3-spidev
    [gpiod]=python3-gpiod [lgpio]=python3-lgpio [RPi]=python3-rpi-lgpio [serial]=python3-serial [yaml]=python3-yaml
    [requests]=python3-requests [gps]=python3-gps [smbus2]=python3-smbus2 [smbus]=python3-smbus [psutil]=python3-psutil
    [cairo]=python3-cairo [flask]=python3-flask [paho]=python3-paho-mqtt [bs4]=python3-bs4 [dateutil]=python3-dateutil)
  local m f pkg
  while IFS=$'\t' read -r m f; do
    [[ -n $m ]] || continue
    if [[ -x $VENV/bin/python ]] && "$VENV/bin/python" -c "import importlib.util,sys;sys.exit(0 if importlib.util.find_spec('$m') else 1)" 2>/dev/null; then continue; fi
    pkg=${PYAPT[$m]:-}
    if [[ -n $pkg ]] && apt-cache show "$pkg" >/dev/null 2>&1; then
      apt-get install -y "$pkg" >/dev/null && echo "  installed $pkg (for '$m')" || review "python module '$m': apt install $pkg failed"
    else
      review "python module '$m' (used by ${f#$STAGE}) is not in Debian under a known name; install it yourself (pip in a venv) if that feature matters"
    fi
  done < <(python3 - "$STAGE" <<'PY'
import sys, os, ast, importlib.util
root = sys.argv[1]; local = set(); srcs = []
for d, dirs, files in os.walk(root):
    local.update(dirs)
    for f in files:
        p = os.path.join(d, f)
        if os.path.islink(p): continue
        if f.endswith('.py'):
            srcs.append(p); local.add(f[:-3])
        else:
            try:
                with open(p, 'rb') as fh: first = fh.readline(120)
                if first.startswith(b'#!') and b'python' in first: srcs.append(p)
            except OSError: pass
seen = {}
for p in srcs:
    try: tree = ast.parse(open(p, encoding='utf-8', errors='replace').read())
    except SyntaxError: continue
    for n in ast.walk(tree):
        names = [a.name.split('.')[0] for a in n.names] if isinstance(n, ast.Import) else \
                [n.module.split('.')[0]] if isinstance(n, ast.ImportFrom) and n.level == 0 and n.module else []
        for m in names:
            if m in sys.stdlib_module_names or m in local or m in seen: continue
            try: ok = importlib.util.find_spec(m) is not None
            except Exception: ok = False
            if not ok: seen[m] = p
for m, p in sorted(seen.items()): print(f"{m}\t{p}")
PY
)
  return 0
}

# ----------------------------- stage -> live ---------------------------------
deploy_stage() {
  log "Deploying files (existing files backed up)"
  local bk="$STATE/backups/deploy-$(date +%Y%m%d-%H%M%S)" d own e; local ex=()
  while IFS= read -r d; do
    [[ -d $STAGE$d ]] || continue
    ex=()
    case $d in
      "$TARGET_HOME") own="$TARGET_USER:$TARGET_USER"; for e in "${HOME_EXCLUDES[@]}"; do ex+=(--exclude="/$e"); done ;;
      /var/www/html)  own="www-data:www-data" ;;
      *)              own="root:root" ;;
    esac
    mkdir -p "$d" "$bk$d"
    chmod --reference="$d" "$STAGE$d"; chown --reference="$d" "$STAGE$d"   # don't alter live dir attributes
    rsync -a --omit-dir-times --chown="$own" --backup --backup-dir="$bk$d" "${ex[@]}" "$STAGE$d/" "$d/"
    echo "  $d"
  done < "$STATE/areas.list"
  install -d -o www-data -g www-data /var/cache/digipi
  rm -f /var/cache/digipi/localized.txt        # marker: "Initialize already done"
  systemctl daemon-reload
  link_dotdirs
}

enable_units() {
  log "Enabling DigiPi boot service"
  # DigiPi starts exactly ONE mode at boot (digipi-boot.service -> 'systemctl start <mode>'). The mode units also carry
  # [Install] sections, but they stop each other, so they must stay disabled or everything would start at boot.
  if [[ -f /etc/systemd/system/digipi-boot.service ]]; then systemctl enable digipi-boot.service 2>&1 | tail -n1
  else warn "digipi-boot.service was not installed; no DigiPi mode will start at boot"; fi
  return 0
}

# ----------------------------- web server ------------------------------------
setup_web() {
  log "Configuring lighttpd + PHP"
  local en=/etc/lighttpd/conf-enabled av=/etc/lighttpd/conf-available
  if command -v lighty-enable-mod >/dev/null; then lighty-enable-mod fastcgi fastcgi-php >/dev/null || true
  else ln -sf ../conf-available/10-fastcgi.conf "$en/"; ln -sf ../conf-available/15-fastcgi-php.conf "$en/"; fi
  if [[ $WEB_PORT != 80 ]]; then
    echo "server.port := $WEB_PORT" > "$av/99-digipi-port.conf"; ln -sf ../conf-available/99-digipi-port.conf "$en/"
  else rm -f "$av/99-digipi-port.conf" "$en/99-digipi-port.conf"; fi
  if [[ -d $STAGE/var/www/html/cgi-bin ]]; then
    cat > "$av/98-digipi-cgi.conf" <<'EOF'
server.modules += ("mod_cgi", "mod_alias")
alias.url += ("/cgi-bin/" => "/var/www/html/cgi-bin/")
$HTTP["url"] =~ "^/cgi-bin/" { cgi.assign = ( "" => "" ) }
EOF
    ln -sf ../conf-available/98-digipi-cgi.conf "$en/"
  fi
  # DigiPi's pages (running as www-data) read files under the user's home, e.g. ~/localize.env; Debian homes are often 0700
  if command -v setfacl >/dev/null; then setfacl -m u:www-data:--x "$TARGET_HOME"; else chmod o+x "$TARGET_HOME"; fi
  if [[ -f $TARGET_HOME/localize.env ]]; then chgrp www-data "$TARGET_HOME/localize.env"; chmod 660 "$TARGET_HOME/localize.env"; fi
  lighttpd -tt -f /etc/lighttpd/lighttpd.conf >/dev/null || die "lighttpd config test failed"
  systemctl enable lighttpd; systemctl restart lighttpd
}

gen_sudoers() {   # let the web UI run exactly the sudo commands its own pages use
  log "Generating narrow sudoers rules for the web UI (www-data)"
  local out=/etc/sudoers.d/digipi-web tmp line cmd args entry r; local -A seen=(); local list=() runas=()
  tmp=$(mktemp)
  while IFS= read -r line; do
    line=${line#sudo }; line=$(sed -E 's/[[:space:]]+$//' <<<"$line")
    [[ -z $line ]] && continue
    [[ $line == *digipi64-setenv* || $line == *"digipi64-setup reconfigure"* ]] && continue   # added below with their own rules
    if [[ $line =~ ^(-i[[:space:]]+)?-u[[:space:]]+([a-z_][a-z0-9_-]*)[[:space:]]+(/[^[:space:]]+)$ ]]; then
      runas+=("${BASH_REMATCH[2]}|${BASH_REMATCH[3]}"); continue      # e.g. Save Configuration: sudo -i -u USER ~/saveconfigs.sh
    fi
    [[ $line == -* ]] && { review "sudoers: skipped web sudo call with options: $line"; continue; }
    cmd=${line%% *}; args=""; [[ $line == *" "* ]] && args=${line#* }
    [[ $cmd == /* ]] || cmd=$(command -v "$cmd" 2>/dev/null || true)
    [[ -n $cmd ]] || continue
    case $(basename "$cmd") in
      bash|sh|dash|su|visudo|passwd|chpasswd|usermod|useradd|hostnamectl|vi|vim|nano|env|python*|perl|php|tee|dd|chmod|chown|cp|mv|rm|sed)
        review "sudoers: excluded risky web sudo call (that web button will not work): $line"; continue ;;
    esac
    args=$(sed -E 's/([,:=\\])/\\\1/g' <<<"$args")
    if [[ -n $args ]]; then entry="$cmd $args"; else entry="$cmd \"\""; fi   # "" = no arguments allowed (blocks e.g. 'login -f root')
    [[ -n ${seen[$entry]:-} ]] && continue; seen[$entry]=1; list+=("$entry")
  done < <(find "$STAGE/var/www/html" -type f \( -name '*.php' -o -name '*.sh' -o -name '*.html' -o -name '*.js' \) -print0 2>/dev/null | xargs -0 cat 2>/dev/null \
           | sed -E 's/[[:space:]][0-9]>/ >/g' \
           | grep -aoE "sudo[[:space:]]+[^\"'<>;|&\$\`)(]+" | sort -u)
  list+=("$SELF_INSTALLED reconfigure" "/usr/local/sbin/digipi64-setenv")
  { echo "# generated by digipi64-setup - commands found in /var/www/html"
    printf 'www-data ALL=(root) NOPASSWD: %s\n' "$(IFS=,; echo "${list[*]}" | sed 's/,/, /g')"
    for r in "${runas[@]}"; do printf 'www-data ALL=(%s) NOPASSWD: %s ""\n' "${r%%|*}" "${r#*|}"; done; } > "$tmp"
  if visudo -cf "$tmp" >/dev/null; then install -m 0440 "$tmp" "$out"; echo "  ${#list[@]} root command(s) + ${#runas[@]} run-as rule(s) (see $out)"
  else warn "generated sudoers failed validation; not installed. Web buttons needing sudo will not work."; review "sudoers generation failed"; fi
  rm -f "$tmp"
}

# ----------------------------- extras (not part of DigiPi) -------------------
deb_install() {   # <label> <url>: download a .deb and let apt resolve its dependencies
  local label=$1 url=$2 f; f=$(mktemp --suffix=.deb); chmod 644 "$f"
  if [[ -n $url ]] && curl -fL --retry 3 --max-time 1200 -o "$f" "$url" && dpkg-deb -I "$f" >/dev/null 2>&1 && apt-get install -y "$f"; then
    echo "  $label installed"; rm -f "$f"; return 0
  fi
  rm -f "$f"; warn "$label could not be installed (${url:-no URL})"; review "$label not installed - see the log; override with ${label^^}_DEB_URL"; return 1
}

install_htcommander() {   # Ylianst/HTCommander: control Benshi/UV-Pro Bluetooth handhelds
  log "Installing HTCommander"
  local a; a=$(dpkg --print-architecture); case $a in arm64) a=arm64 ;; amd64) a=x64 ;; *) warn "HTCommander has no .deb for $a"; return 0 ;; esac
  deb_install htcommander "${HTCOMMANDER_DEB_URL:-https://github.com/Ylianst/HTCommander/releases/latest/download/htcommander-linux-$a.deb}" || true
}

install_gridtracker() {   # GridTracker 2 (official .deb from download2.gridtracker.org)
  log "Installing GridTracker 2"
  local a n url="$GRIDTRACKER_DEB_URL"; a=$(dpkg --print-architecture)
  [[ $a == arm64 || $a == amd64 ]] || { warn "GridTracker has no .deb for $a"; return 0; }
  if [[ -z $url ]]; then
    n=$(curl -fsSL --max-time 30 https://gridtracker.org/index.php/downloads/gridtracker-downloads 2>/dev/null | grep -oE "GridTracker2-[0-9.]+-$a\.deb" | sort -uV | tail -n1 || true)
    [[ -n $n ]] || n="GridTracker2-2.261019.5-$a.deb"       # known-good version if the download page cannot be read
    url="https://download2.gridtracker.org/$n"
  fi
  deb_install gridtracker "$url" || true
}

install_hamclocksync() {   # jaredBevis/ham-clock-sync: set the clock from WWV/WWVH audio, GPS or NTP (Tk GUI; sets the clock through sudo/pkexec on demand)
  log "Ham Clock Sync (WWV/GPS/NTP clock setting)"
  local src=/usr/local/src/ham-clock-sync
  apt-get install -y python3-numpy python3-tk python3-pil python3-pil.imagetk libportaudio2 python3-serial python3-sounddevice \
    || { apt-get install -y python3-numpy python3-tk python3-pil python3-pil.imagetk libportaudio2 python3-serial python3-pip \
         && pip install --break-system-packages sounddevice; } || warn "some Ham Clock Sync dependencies were not installed"
  python3 -c 'import sounddevice' 2>/dev/null || pip install --break-system-packages sounddevice || warn "python sounddevice not installed; Ham Clock Sync cannot read audio"
  if [[ -d $src/.git ]]; then git -C "$src" pull --ff-only || warn "could not update Ham Clock Sync; using the copy that is there"
  else rm -rf "$src"; git clone --depth 1 ${HAMCLOCKSYNC_REF:+--branch "$HAMCLOCKSYNC_REF"} "$HAMCLOCKSYNC_REPO" "$src" \
    || { warn "could not clone $HAMCLOCKSYNC_REPO"; review "Ham Clock Sync not installed (download failed). Re-run the installer when online."; return 0; }; fi
  [[ -f $src/ham-clock-sync.py ]] || { warn "ham-clock-sync.py missing in $src"; review "Ham Clock Sync: ham-clock-sync.py not found in the download"; return 0; }
  cat > /usr/local/bin/ham-clock-sync <<'HCSEOF'
#!/bin/bash
# Starts Ham Clock Sync as the normal user (it asks for root itself only when it sets the clock). Extra options are passed on:
#   ham-clock-sync --simulate | --selftest | --wf-width 360 --wf-height 160 (small screens)
exec python3 /usr/local/src/ham-clock-sync/ham-clock-sync.py --no-auto-install "$@"
HCSEOF
  chmod 0755 /usr/local/bin/ham-clock-sync
  cat > /usr/share/applications/ham-clock-sync.desktop <<'HCSDESK'
[Desktop Entry]
Type=Application
Name=Ham Clock Sync
Comment=Set the clock from WWV/WWVH time signals, GPS or NTP (FT8, JS8Call timing)
Exec=/usr/local/bin/ham-clock-sync
Icon=preferences-system-time
Terminal=false
Categories=HamRadio;
HCSDESK
  echo "  installed: menu entry 'Ham Clock Sync' (Ham Radio), command ham-clock-sync, source $src"
  review "Ham Clock Sync is under Ham Radio in the start menu (or run: ham-clock-sync). Small screen: ham-clock-sync --wf-width 360 --wf-height 160. It sets the clock with sudo, so keep passwordless sudo for your user."
}
install_rtw() {   # "reboot the world": engineering and design utilities from the Debian archive
  log "Installing the 'reboot the world' collection (FreeCAD, Scilab, KiCad)"
  local p list=(freecad scilab kicad kicad-symbols kicad-footprints kicad-templates)
  [[ $RTW_KICAD_3D == 1 ]] && list+=(kicad-packages3d)
  for p in "${list[@]}"; do
    if apt-cache show "$p" >/dev/null 2>&1; then apt-get install -y "$p" || { warn "install failed: $p"; MISSING_PKGS+=("$p"); }
    else warn "not in this release's arm64 repos: $p"; MISSING_PKGS+=("$p"); fi
  done
  [[ $RTW_KICAD_3D == 1 ]] || review "KiCad 3D models (kicad-packages3d, ~6 GB) not installed; re-run with RTW_KICAD_3D=1 if you want them"
}

install_kiwix() {   # kiwix-serve on KIWIX_PORT; ZIM files dropped into ~/kiwix_zim are picked up automatically
  log "Setting up the Kiwix server (ZIM folder: $TARGET_HOME/$KIWIX_DIR_NAME, port $KIWIX_PORT)"
  apt-get install -y kiwix-tools || { warn "kiwix-tools not available: Kiwix server skipped"; MISSING_PKGS+=(kiwix-tools); return 0; }
  local zd="$TARGET_HOME/$KIWIX_DIR_NAME" lib="$TARGET_HOME/.kiwix/library.xml" sync=/usr/local/sbin/kiwix-zim-sync
  local kiwix_args=""     # plain HTTP, straight on KIWIX_PORT, all interfaces (no HTTPS proxy)
  install -d -o "$TARGET_USER" -g "$TARGET_USER" "$zd" "$TARGET_HOME/.kiwix"
  [[ -e $zd/README.txt ]] || { cat > "$zd/README.txt" <<EOF2
Put Kiwix ZIM files (offline Wikipedia, etc.) in this folder. They appear in the Kiwix server within a few minutes:
  http://$(hostname).local:$KIWIX_PORT/
Get ZIM files from https://library.kiwix.org/ or https://download.kiwix.org/zim/
Files still downloading (.part) are ignored until finished.
EOF2
    chown "$TARGET_USER:$TARGET_USER" "$zd/README.txt"; }
  cat > "$sync" <<'EOF2'
#!/bin/bash
# kiwix-zim-sync <zim-dir> <library.xml>: rebuild the Kiwix library from every valid *.zim file; kiwix-serve reloads it by itself
dir=$1; lib=$2
[[ -d $dir ]] || exit 0
tmp=$(mktemp "$lib.XXXXXX") || exit 1
echo '<?xml version="1.0" encoding="UTF-8"?><library version="20110515"></library>' > "$tmp"
now=$(date +%s)
while IFS= read -r -d '' z; do
  (( now - $(stat -c %Y "$z") < 30 )) && continue          # still being copied; the timer picks it up on the next run
  kiwix-manage "$tmp" add "$z" >/dev/null 2>&1 || echo "kiwix-zim-sync: skipping unreadable ZIM: $z" >&2
done < <(find -L "$dir" -maxdepth 2 -type f -name '*.zim' -print0 | sort -z)
chmod 644 "$tmp"
if cmp -s "$tmp" "$lib"; then rm -f "$tmp"; else mv -f "$tmp" "$lib"; fi
EOF2
  chmod 0755 "$sync"
  runuser -u "$TARGET_USER" -- "$sync" "$zd" "$lib"
  cat > /etc/systemd/system/kiwix-zim-sync.service <<EOF2
[Unit]
Description=Update the Kiwix library from $zd
StartLimitIntervalSec=0
[Service]
Type=oneshot
User=$TARGET_USER
ExecStart=$sync $zd $lib
EOF2
  cat > /etc/systemd/system/kiwix-zim-sync.path <<EOF2
[Unit]
Description=Watch $zd for ZIM files
[Path]
PathChanged=$zd
Unit=kiwix-zim-sync.service
[Install]
WantedBy=multi-user.target
EOF2
  cat > /etc/systemd/system/kiwix-zim-sync.timer <<'EOF2'
[Unit]
Description=Re-check the Kiwix ZIM folder (catches files that finished copying later)
[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
[Install]
WantedBy=timers.target
EOF2
  cat > /etc/systemd/system/kiwix-serve.service <<EOF2
[Unit]
Description=Kiwix server (offline ZIM content)
After=network.target
[Service]
User=$TARGET_USER
ExecStartPre=$sync $zd $lib
ExecStart=/usr/bin/kiwix-serve --library --monitorLibrary --port $KIWIX_PORT $kiwix_args $lib
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF2
  systemctl daemon-reload
  systemctl enable kiwix-zim-sync.path kiwix-zim-sync.timer >/dev/null 2>&1 || true
  systemctl enable kiwix-serve.service >/dev/null 2>&1 || true
  systemctl restart kiwix-serve.service kiwix-zim-sync.path kiwix-zim-sync.timer ||   # restart: a re-run changes the unit (port/address/URL root), and "enable --now" would leave the old process running
    true; systemctl is-active --quiet kiwix-serve.service || { warn "could not start the Kiwix units"; review "kiwix units failed to start"; }
  if [[ -e /etc/nginx/digipi-apps.d/kiwix.conf ]]; then   # earlier versions proxied Kiwix through nginx HTTPS at /kiwix/
    rm -f /etc/nginx/digipi-apps.d/kiwix.conf; systemctl is-active --quiet nginx && systemctl reload nginx || true
  fi
  if [[ $INSTALL_NGINX == 1 ]]; then
    install -d /etc/digipi64/apps.d
    printf 'TITLE=Kiwix\nDESC=Offline Wikipedia and other ZIM content\nURL=http://{host}:%s/\nORDER=20\n' "$KIWIX_PORT" > /etc/digipi64/apps.d/kiwix.app
    [[ -x /usr/local/sbin/digipi64-landing ]] && /usr/local/sbin/digipi64-landing || true
  fi
  echo "  Kiwix: http://$(hostname).local:$KIWIX_PORT/  (ZIM files go in $zd)"
}

install_extras() {
  [[ $INSTALL_HTCOMMANDER == 1 ]] && install_htcommander
  [[ $INSTALL_GRIDTRACKER == 1 ]] && install_gridtracker
  [[ $INSTALL_RTW == 1 ]] && install_rtw
  [[ $INSTALL_HAMCLOCKSYNC == 1 ]] && install_hamclocksync
  [[ $INSTALL_KIWIX == 1 ]] && install_kiwix
  return 0
}

# ----------------------------- front end: nginx, HTTPS, landing page ----------
install_frontend_helpers() {   # small root tools: digipi64-tls, digipi64-landing, digipi64-addapp
  cat > /usr/local/sbin/digipi64-tls <<'EOF2'
#!/bin/bash
# digipi64-tls [--new-ca]: local certificate authority + HTTPS certificate for this Pi.
# Idempotent: re-issues the server certificate only when the IP addresses change or it nears expiry.
set -euo pipefail
D=/etc/digipi64/tls; host=$(hostname)
install -d -m 755 "$D"; cd "$D"
[[ ${1:-} == --new-ca ]] && rm -f ca.key ca.crt server.key server.crt server.san
if [[ ! -f ca.key || ! -f ca.crt ]]; then
  openssl ecparam -name prime256v1 -genkey -noout -out ca.key; chmod 600 ca.key
  cat > ca.cnf <<EOF3
[req]
distinguished_name=dn
prompt=no
x509_extensions=v3_ca
[dn]
O=DigiPi local
CN=DigiPi Local CA ($host)
[v3_ca]
basicConstraints=critical,CA:TRUE,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
nameConstraints=critical,permitted;DNS:.local,permitted;DNS:localhost,permitted;DNS:$host,permitted;IP:127.0.0.0/255.0.0.0,permitted;IP:10.0.0.0/255.0.0.0,permitted;IP:172.16.0.0/255.240.0.0,permitted;IP:192.168.0.0/255.255.0.0,permitted;IP:169.254.0.0/255.255.0.0,permitted;IP:100.64.0.0/255.192.0.0
EOF3
  openssl req -x509 -new -key ca.key -sha256 -days 3650 -config ca.cnf -out ca.crt
  chmod 644 ca.crt; rm -f ca.cnf; rm -f server.san
fi
ips=$(python3 - <<'PY'
import ipaddress, subprocess
nets=[ipaddress.ip_network(n) for n in ("10.0.0.0/8","172.16.0.0/12","192.168.0.0/16","169.254.0.0/16","100.64.0.0/10")]
r=set()
for a in subprocess.run(["hostname","-I"],capture_output=True,text=True).stdout.split():
    try: ip=ipaddress.ip_address(a)
    except ValueError: continue
    if ip.version==4 and any(ip in n for n in nets): r.add(a)
print(" ".join(sorted(r)))
PY
)
san="DNS:$host.local,DNS:$host,DNS:localhost,IP:127.0.0.1"
for i in $ips; do san+=",IP:$i"; done
if [[ -f server.crt && -f server.key && -f server.san && "$(cat server.san)" == "$san" ]] && openssl x509 -in server.crt -noout -checkend $((60*86400)) >/dev/null 2>&1; then exit 0; fi
printf 'basicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=serverAuth\nsubjectAltName=%s\n' "$san" > ext.cnf
openssl ecparam -name prime256v1 -genkey -noout -out server.key.new
openssl req -new -key server.key.new -subj "/CN=$host.local" -out server.csr
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 825 -sha256 -extfile ext.cnf -out server.crt.new 2>/dev/null
chmod 600 server.key.new; mv -f server.key.new server.key; mv -f server.crt.new server.crt; echo "$san" > server.san
rm -f server.csr ext.cnf
echo "digipi64-tls: issued certificate for $san"
if systemctl is-active --quiet nginx; then nginx -t 2>/dev/null && systemctl reload nginx; fi
exit 0
EOF2
  cat > /usr/local/sbin/digipi64-landing <<'EOF2'
#!/usr/bin/env python3
# digipi64-landing: build /var/www/landing/index.html from /etc/digipi64/apps.d/*.app (KEY=value files: TITLE, DESC, URL, ORDER)
import glob, html, os, re, socket
APPS = "/etc/digipi64/apps.d"; OUT = "/var/www/landing/index.html"
apps = []
for f in sorted(glob.glob(APPS + "/*.app")):
    d = {}
    for line in open(f, encoding="utf-8", errors="replace"):
        m = re.match(r'^([A-Z_]+)=(.*)$', line.rstrip("\n"))
        if m: d[m.group(1)] = m.group(2).strip().strip('"')
    if not re.match(r'^https?://[^\s<>"\']+$', d.get("URL", "")): continue
    try: order = int(d.get("ORDER", "50"))
    except ValueError: order = 50
    apps.append((order, d.get("TITLE", os.path.basename(f)[:-4]), d.get("DESC", ""), d["URL"]))
apps.sort(key=lambda a: (a[0], a[1].lower()))
host = html.escape(socket.gethostname())
cards = "\n".join(
    '    <a class="card" data-url="%s"><h2>%s</h2><p>%s</p></a>' % (html.escape(u, quote=True), html.escape(t), html.escape(dsc))
    for _, t, dsc, u in apps) or '    <p>No apps registered yet.</p>'
page = """<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>%(host)s</title>
<style>
:root{--bg:#f4f5f7;--fg:#1c1f24;--muted:#5b6370;--card:#fff;--line:#d9dde3;--accent:#0b66c3}
@media (prefers-color-scheme:dark){:root{--bg:#14171b;--fg:#e8eaed;--muted:#9aa3ad;--card:#1d2127;--line:#2f353d;--accent:#6aaeff}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.5 system-ui,sans-serif}
main{max-width:860px;margin:0 auto;padding:32px 16px}
h1{margin:0 0 4px;font-size:1.7rem}.sub{color:var(--muted);margin:0 0 24px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:14px}
.card{display:block;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:16px;color:inherit;text-decoration:none;cursor:pointer}
.card:hover,.card:focus{border-color:var(--accent);outline:none}
.card h2{margin:0 0 4px;font-size:1.1rem;color:var(--accent)}.card p{margin:0;color:var(--muted);font-size:.92rem}
footer{margin-top:28px;color:var(--muted);font-size:.88rem}footer a{color:var(--accent)}
</style></head><body><main>
<h1>%(host)s</h1><p class="sub">Web apps on this Raspberry Pi</p>
<div class="grid">
%(cards)s
</div>
<footer id="tls"></footer>
</main>
<script>
document.querySelectorAll('a.card').forEach(function(a){a.href=a.dataset.url.replace('{host}',location.hostname);});
var f=document.getElementById('tls');
f.innerHTML=location.protocol==='https:'
 ? 'Browser warning on this page? <a href="/ca.crt">Download the Pi certificate</a> and add it to your device or browser as a trusted authority.'
 : 'Some content needs a secure connection: <a id="s">open this page over HTTPS</a>.';
var s=document.getElementById('s'); if(s) s.href='https://'+location.host+'/';
</script></body></html>
""" % {"host": host, "cards": cards}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
tmp = OUT + ".tmp"
open(tmp, "w", encoding="utf-8").write(page); os.chmod(tmp, 0o644); os.replace(tmp, OUT)
EOF2
  cat > /usr/local/sbin/digipi64-addapp <<'EOF2'
#!/bin/bash
# digipi64-addapp: add, list or remove a tile on the landing page (and optionally an nginx reverse proxy for it)
#   digipi64-addapp link   NAME "Title" URL ["Description"]     tile that links to URL ({host} = the name you browsed to)
#   digipi64-addapp proxy  NAME PORT "Title" ["Description"]    proxies https://<host>/NAME/ to 127.0.0.1:PORT (app must work under a sub-path)
#   digipi64-addapp remove NAME      |      digipi64-addapp list
set -euo pipefail
APPS=/etc/digipi64/apps.d; NG=/etc/nginx/digipi-apps.d
die(){ echo "digipi64-addapp: $*" >&2; exit 1; }
clean(){ printf '%s' "$1" | tr -d '\r\n"\\' | cut -c1-120; }
okname(){ [[ ${1:-} =~ ^[a-z0-9][a-z0-9-]{0,29}$ ]] || die "NAME must be lowercase letters, digits or '-'"; }
refresh(){ if [[ -d $NG ]] && ! nginx -t >/dev/null 2>&1; then nginx -t; die "nginx rejected the change; reverted"; fi
           systemctl reload nginx 2>/dev/null || true; /usr/local/sbin/digipi64-landing; }
install -d "$APPS" "$NG"
case ${1:-} in
  link)  okname "${2:-}"; [[ ${4:-} =~ ^https?://[^[:space:]\<\>\"\']+$ ]] || die "URL must start with http:// or https://"
         printf 'TITLE=%s\nDESC=%s\nURL=%s\nORDER=50\n' "$(clean "${3:-$2}")" "$(clean "${5:-}")" "$4" > "$APPS/$2.app"; refresh ;;
  proxy) okname "${2:-}"; [[ ${3:-} =~ ^[0-9]{1,5}$ ]] && (( $3 >= 1 && $3 <= 65535 )) || die "PORT must be 1-65535"
         [[ $2 == kiwix ]] && die "'kiwix' is managed by the installer"
         cat > "$NG/$2.conf" <<EOF3
location /$2/ {
    proxy_pass http://127.0.0.1:$3/;
    proxy_http_version 1.1;
    proxy_set_header Host \$http_host;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_read_timeout 600s;
}
EOF3
         printf 'TITLE=%s\nDESC=%s\nURL=https://{host}/%s/\nORDER=50\n' "$(clean "${4:-$2}")" "$(clean "${5:-}")" "$2" > "$APPS/$2.app"
         if ! nginx -t >/dev/null 2>&1; then rm -f "$NG/$2.conf" "$APPS/$2.app"; nginx -t; die "nginx rejected the change; reverted"; fi
         refresh ;;
  remove) okname "${2:-}"; rm -f "$APPS/$2.app" "$NG/$2.conf"; refresh ;;
  list)  grep -H '^TITLE=\|^URL=' "$APPS"/*.app 2>/dev/null | sed "s#$APPS/##" || true ;;
  *)     sed -n '2,6p' "$0"; exit 2 ;;
esac
EOF2
  chmod 0755 /usr/local/sbin/digipi64-tls /usr/local/sbin/digipi64-landing /usr/local/sbin/digipi64-addapp
}

setup_frontend() {   # nginx on 80/443: landing page, HTTPS (own CA), reverse proxies; DigiPi's lighttpd lives on $WEB_PORT
  [[ $INSTALL_NGINX == 1 ]] || return 0
  log "Setting up nginx: landing page and HTTPS on ports 80/443"
  apt-get install -y nginx openssl python3 || { warn "nginx failed to install: no landing page or HTTPS. DigiPi is on port $WEB_PORT."; review "nginx not installed"; return 0; }
  install -d /etc/digipi64/apps.d /etc/nginx/digipi-apps.d /var/www/landing
  install_frontend_helpers
  printf 'TITLE=DigiPi\nDESC=Ham radio modes, APRS, Winlink, GUI apps\nURL=http://{host}:%s/\nORDER=10\n' "$WEB_PORT" > /etc/digipi64/apps.d/digipi.app
  /usr/local/sbin/digipi64-tls
  [[ -L /etc/nginx/sites-enabled/default ]] && rm -f /etc/nginx/sites-enabled/default      # the stock 'welcome to nginx' site
  local v80="" v443=""   # IPv6 listeners only where the kernel has IPv6 (nginx refuses to start otherwise)
  if [[ -s /proc/net/if_inet6 ]]; then v80="listen [::]:80 default_server;"; v443="listen [::]:443 ssl default_server;"; fi
  cat > /etc/nginx/sites-available/digipi64 <<EOF2
server {
    listen 80 default_server;
    $v80
    listen 443 ssl default_server;
    $v443
    server_name _;
    ssl_certificate     /etc/digipi64/tls/server.crt;
    ssl_certificate_key /etc/digipi64/tls/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    root /var/www/landing;
    index index.html;
    location = /ca.crt { alias /etc/digipi64/tls/ca.crt; default_type application/x-x509-ca-cert; }
    include /etc/nginx/digipi-apps.d/*.conf;
    location / { try_files \$uri \$uri/ =404; }
}
EOF2
  ln -sf ../sites-available/digipi64 /etc/nginx/sites-enabled/digipi64
  nginx -t || { warn "nginx config test failed; landing page and HTTPS are not active"; review "nginx config test failed"; return 0; }
  cat > /etc/systemd/system/digipi64-tls.service <<'EOF2'
[Unit]
Description=Re-issue the DigiPi HTTPS certificate if the IP addresses changed
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/digipi64-tls
EOF2
  cat > /etc/systemd/system/digipi64-tls.timer <<'EOF2'
[Unit]
Description=Check the DigiPi HTTPS certificate
[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
[Install]
WantedBy=timers.target
EOF2
  cat > /etc/systemd/system/digipi64-landing.service <<'EOF2'
[Unit]
Description=Rebuild the landing page
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/digipi64-landing
EOF2
  cat > /etc/systemd/system/digipi64-landing.path <<'EOF2'
[Unit]
Description=Watch the landing page app list
[Path]
PathChanged=/etc/digipi64/apps.d
[Install]
WantedBy=multi-user.target
EOF2
  /usr/local/sbin/digipi64-landing
  systemctl daemon-reload
  systemctl enable --now nginx digipi64-tls.timer digipi64-landing.path || true
  systemctl reload nginx 2>/dev/null || systemctl restart nginx || { warn "nginx did not start"; review "nginx failed to start"; }
  echo "  Landing page: https://$(hostname).local/   (DigiPi: http://$(hostname).local:$WEB_PORT/)"
  review "HTTPS uses a local CA: download https://$(hostname).local/ca.crt and trust it on each device to remove browser warnings. Keep /etc/digipi64/tls/ca.key private."
}

# ----------------------------- start menu: one "Ham Radio" heading ----------
install_ardop_launcher() {   # start-menu entry that starts ARDOP and opens its WebGui (constellation, spectrum, waterfall)
  [[ -x /usr/local/bin/ardopcf ]] || return 0
  log "ARDOP launcher (WebGui on port 8514)"
  cat > /usr/local/bin/digipi64-ardop-gui <<'ARDOPGUI'
#!/bin/bash
# Starts DigiPi's ARDOP mode (ardopcf with its WebGui on port 8514) if it is not running, then opens the WebGui.
# Starting it stops other DigiPi modes that use the sound card, exactly as the DigiPi web page does.
URL=http://localhost:8514/
if ! pgrep -x ardopcf >/dev/null; then
  sudo -n systemctl start ardop.service || { notify-send "ARDOP" "Could not start ardop.service (needs passwordless sudo)" 2>/dev/null; exit 1; }
fi
for i in $(seq 1 20); do ss -ltn 2>/dev/null | grep -q ':8514 ' && break; sleep 1; done
exec xdg-open "$URL"
ARDOPGUI
  chmod 0755 /usr/local/bin/digipi64-ardop-gui
  cat > /usr/share/applications/digipi64-ardop.desktop <<'ARDOPDESK'
[Desktop Entry]
Type=Application
Name=ARDOP (ardopcf WebGui)
Comment=Start the ARDOP modem and open its web interface: constellation, spectrum, waterfall
Exec=/usr/local/bin/digipi64-ardop-gui
Icon=network-wireless
Terminal=false
Categories=HamRadio;
ARDOPDESK
  [[ -d /etc/digipi64/apps.d ]] && printf 'TITLE=ARDOP WebGui\nDESC=Constellation, spectrum and waterfall (works while ARDOP is running)\nURL=http://{host}:8514/\nORDER=30\n' > /etc/digipi64/apps.d/ardop.app
  [[ -x /usr/local/sbin/digipi64-landing ]] && /usr/local/sbin/digipi64-landing || true
}

setup_ham_menu() {
  [[ $HAM_MENU == 1 ]] || return 0
  log "Grouping radio applications under 'Ham Radio' in the start menu"
  cat > /usr/local/sbin/digipi64-hammenu <<'HAMMENU_PY'
#!/usr/bin/env python3
"""digipi64-hammenu: put every ham-radio application under one "Ham Radio" start-menu heading.

For each radio application it writes a copy of the .desktop file into /usr/local/share/applications (which
takes precedence over /usr/share/applications) whose only category is HamRadio, then adds a "Ham Radio"
submenu (all HamRadio entries) to the desktop's application menu through a menu merge file.
Run it again after installing more radio software:  sudo digipi64-hammenu
Add application file names (one per line, e.g. myradio.desktop) to /etc/digipi64/ham-apps.list to include them.
Undo:  sudo digipi64-hammenu --remove
"""
import glob, os, re, sys

ROOT = os.environ.get("HAM_ROOT", "")
def P(p): return ROOT + p
APPS = P("/usr/share/applications")
OVER = P("/usr/local/share/applications")
DIRS = P("/usr/local/share/desktop-directories")
MENUS = P("/etc/xdg/menus")
EXTRA = P("/etc/digipi64/ham-apps.list")
MARK = "# digipi64-hammenu override of "
DIRFILE = "digipi64-ham-radio.directory"
KNOWN = set("""wsjtx message_aggregator js8call fldigi flrig flmsg flamp flnet flwrap flarq flcluster fllog qsstv
gridtracker gridtracker2 htcommander wfview freedv xastir gpredict chirp cqrlog klog gqrx cubicsdr sdrangel
linpac qtel svxlink tqsl trustedqsl""".split())
quiet = "--quiet" in sys.argv
def say(*a):
    if not quiet: print(*a)

def read(path):
    with open(path, encoding="utf-8", errors="replace") as f: return f.read().splitlines()

def entry_value(lines, key):
    grp = False
    for l in lines:
        if l.startswith("["): grp = (l.strip() == "[Desktop Entry]")
        elif grp and l.startswith(key + "="): return l.split("=", 1)[1].strip()
    return None

def ours(path):
    try: return read(path)[0].startswith(MARK)
    except (OSError, IndexError): return False

def rewrite(lines, src):
    out, grp, done = [MARK + src], False, False
    for l in lines:
        if l.startswith("["):
            if grp and not done: out.append("Categories=HamRadio;"); done = True
            grp = (l.strip() == "[Desktop Entry]")
            out.append(l); continue
        if grp and l.startswith("Categories="):
            if not done: out.append("Categories=HamRadio;"); done = True
            continue
        out.append(l)
    if grp and not done: out.append("Categories=HamRadio;")
    return "\n".join(out) + "\n"

def remove_all():
    n = 0
    for f in glob.glob(OVER + "/*.desktop"):
        if ours(f): os.remove(f); n += 1
    for f in glob.glob(MENUS + "/*-merged/digipi64-ham.menu") + [DIRS + "/" + DIRFILE]:
        if os.path.exists(f): os.remove(f)
    say("removed %d override(s) and the Ham Radio menu" % n)

def main():
    if "--remove" in sys.argv: return remove_all()
    wanted = set(KNOWN)
    if os.path.exists(EXTRA):
        for l in read(EXTRA):
            l = l.strip()
            if l and not l.startswith("#"): wanted.add(l[:-8].lower() if l.lower().endswith(".desktop") else l.lower())
    os.makedirs(OVER, exist_ok=True); os.makedirs(DIRS, exist_ok=True)
    done = []
    for src in sorted(glob.glob(APPS + "/*.desktop")):
        name = os.path.basename(src)
        lines = read(src)
        if entry_value(lines, "Type") not in (None, "Application"): continue
        if (entry_value(lines, "NoDisplay") or "").lower() == "true" or (entry_value(lines, "Hidden") or "").lower() == "true": continue
        cats = [c for c in (entry_value(lines, "Categories") or "").split(";") if c]
        if "HamRadio" not in cats and name[:-8].lower() not in wanted: continue
        dst = OVER + "/" + name
        if os.path.exists(dst) and not ours(dst): say("skipped (you have your own copy): " + dst); continue
        text = rewrite(lines, "/usr/share/applications/" + name)
        if not os.path.exists(dst) or open(dst, encoding="utf-8", errors="replace").read() != text:
            with open(dst, "w", encoding="utf-8") as f: f.write(text)
            os.chmod(dst, 0o644)
        done.append(name)
    for f in glob.glob(OVER + "/*.desktop"):               # radio software that has been uninstalled
        if ours(f) and not os.path.exists(APPS + "/" + os.path.basename(f)): os.remove(f)
    with open(DIRS + "/" + DIRFILE, "w") as f:
        f.write("[Desktop Entry]\nType=Directory\nName=Ham Radio\nComment=Amateur radio applications\nIcon=network-wireless\n")
    merge = ('<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"\n "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">\n'
             "<Menu>\n  <Name>Applications</Name>\n  <Menu>\n    <Name>Ham Radio</Name>\n    <Directory>%s</Directory>\n"
             "    <Include><Category>HamRadio</Category></Include>\n  </Menu>\n</Menu>\n" % DIRFILE)
    menus = sorted(glob.glob(MENUS + "/*applications.menu"))
    for m in menus:
        d = m[:-5] + "-merged"
        os.makedirs(d, exist_ok=True)
        with open(d + "/digipi64-ham.menu", "w") as f: f.write(merge)
        txt = open(m, encoding="utf-8", errors="replace").read()
        if "<DefaultMergeDirs" not in txt and "<MergeDir" not in txt:    # the menu must read its -merged folder
            if not os.path.exists(m + ".digipi64.orig"): open(m + ".digipi64.orig", "w").write(txt)
            txt = re.sub(r"(<Name>Applications</Name>)", r"\1\n  <DefaultMergeDirs/>", txt, count=1)
            open(m, "w").write(txt); say("enabled menu merging in " + m)
    if not menus: say("no application menu found in %s (headless system?); entries were still re-categorised" % MENUS)
    say("Ham Radio menu: %d application(s): %s" % (len(done), ", ".join(n[:-8] for n in done) or "none"))
    if os.geteuid() == 0 and not ROOT and os.path.exists("/usr/bin/update-desktop-database"):
        os.system("update-desktop-database %s >/dev/null 2>&1" % OVER)

main()
HAMMENU_PY
  chmod 0755 /usr/local/sbin/digipi64-hammenu
  install -d /etc/digipi64
  [[ -e /etc/digipi64/ham-apps.list ]] || printf '# extra application files to show under Ham Radio, one per line (e.g. myradio.desktop)\n' > /etc/digipi64/ham-apps.list
  # keep it right after apt installs or upgrades radio software
  printf 'DPkg::Post-Invoke { "if [ -x /usr/local/sbin/digipi64-hammenu ]; then /usr/local/sbin/digipi64-hammenu --quiet || true; fi"; };\n' > /etc/apt/apt.conf.d/99digipi64-hammenu
  /usr/local/sbin/digipi64-hammenu || { warn "Ham Radio menu setup failed"; review "Ham Radio menu not set up"; }
  review "Ham Radio start menu: log out and back in (or reboot) to see it. After installing more radio software run: sudo digipi64-hammenu"
}

# ----------------------------- Wi-Fi fallback hotspot ------------------------
# Optional. Asks for a fallback network name/password, then a service checks every few minutes: connected -> nothing;
# hotspot with clients -> leave it; hotspot idle -> drop it, scan, join a known network or bring the hotspot back.
FB_SSID="${FALLBACK_SSID:-}"; FB_PSK="${FALLBACK_PSK:-}"
fallback_possible() {
  systemctl is-active --quiet NetworkManager 2>/dev/null || return 1
  command -v nmcli >/dev/null && nmcli -t -f TYPE device 2>/dev/null | grep -qx wifi
}
ask_fallback() {
  [[ ${AUTOHOTSPOT:-ask} == 0 ]] && return 0
  if ! fallback_possible; then
    echo "Wi-Fi fallback hotspot: skipped (needs NetworkManager and a wifi interface)."; FB_SSID=""; return 0
  fi
  if [[ -z $FB_SSID ]]; then
    if [[ ${AUTOHOTSPOT:-ask} == 1 && ! -t 0 ]]; then warn "AUTOHOTSPOT=1 needs FALLBACK_SSID and FALLBACK_PSK when not interactive; skipping hotspot."; return 0; fi
    [[ -t 0 ]] || { echo "Wi-Fi fallback hotspot: not configured (non-interactive). Later: sudo digipi64-setup install with FALLBACK_SSID/FALLBACK_PSK."; return 0; }
    echo
    echo "Optional fallback Wi-Fi hotspot: when no known wifi network is in range, this Pi hosts its own network so you can still connect."
    local s p p2
    while :; do
      read -r -p "Fallback hotspot name (SSID, 1-32 characters; blank to skip): " s
      [[ -z $s ]] && { FB_SSID=""; echo "  skipped (add it later: sudo digipi64-wifi-fallback configure)"; return 0; }
      [[ ${#s} -le 32 && $s != *\\* && $s =~ ^[[:print:]]+$ ]] && break; echo "  Use 1-32 printable characters, no backslash."
    done
    while :; do
      read -r -s -p "Hotspot password (8-63 characters): " p; echo; read -r -s -p "Repeat password: " p2; echo
      [[ $p == "$p2" ]] || { echo "  They do not match."; continue; }
      [[ ${#p} -ge 8 && ${#p} -le 63 && $p != *\\* && $p =~ ^[[:print:]]+$ ]] && break; echo "  Use 8-63 printable characters, no backslash."
    done
    FB_SSID=$s; FB_PSK=$p
  fi
  if [[ ${#FB_SSID} -gt 32 || ${#FB_PSK} -lt 8 || ${#FB_PSK} -gt 63 || $FB_SSID == *\\* || $FB_PSK == *\\* ]]; then
    warn "Fallback SSID/password invalid (SSID 1-32, password 8-63 characters, no backslash); skipping hotspot."; FB_SSID=""; FB_PSK=""
  fi
}
setup_wifi_fallback() {
  [[ ${AUTOHOTSPOT:-ask} == 0 ]] && return 0
  fallback_possible || return 0
  log "Wi-Fi fallback hotspot"
  apt-get install -y iw dnsmasq-base || { warn "iw/dnsmasq-base not installed; hotspot skipped"; review "Wi-Fi fallback skipped: iw/dnsmasq-base install failed"; return 0; }
  install -d /etc/digipi64
  [[ -e /etc/digipi64/hotspot.conf ]] || cat > /etc/digipi64/hotspot.conf <<'HSCONF'
# digipi64-wifi-fallback settings (restart the service after editing: sudo systemctl restart digipi64-wifi-fallback)
IFACE=""                     # wifi interface; blank = first one found
PROFILE="digipi-hotspot"     # NetworkManager profile name of the fallback network
INTERVAL=180                 # seconds between checks
BOOT_DELAY=45                # seconds to let normal wifi connect after boot before the first check
CONNECT_TIMEOUT=30
HOTSPOT_WITH_ETHERNET=1      # 0 = do not start the hotspot while a cable connection is up
HSCONF
  cat > /usr/local/sbin/digipi64-wifi-fallback <<'WIFIFB_EOF'
#!/bin/bash
# digipi64-wifi-fallback: keep the Pi reachable. If no known wifi network can be joined, host a fallback access point.
#   run        daemon loop (what the systemd service runs)
#   once       do a single check now
#   status     show what it sees
#   configure  change the fallback network name / password
# Every INTERVAL seconds: wifi connected -> do nothing; hotspot up with clients -> leave it; hotspot up with
# no clients -> drop it, scan, join a known network if one is in range, otherwise bring the hotspot back.
CONF=/etc/digipi64/hotspot.conf
IFACE=""; PROFILE="digipi-hotspot"; INTERVAL=180; BOOT_DELAY=45; CONNECT_TIMEOUT=30; HOTSPOT_WITH_ETHERNET=1
[[ -r $CONF ]] && . "$CONF"
export LC_ALL=C
log() { echo "$*"; }

wifi_dev()    { if [[ -n $IFACE ]]; then echo "$IFACE"; else nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}'; fi; }
dev_state()   { nmcli -t -g GENERAL.STATE device show "$1" 2>/dev/null | cut -d' ' -f1; }      # 100 = connected
active_conn() { local c; c=$(nmcli -t -g GENERAL.CONNECTION device show "$1" 2>/dev/null); [[ $c == "--" ]] && c=""; echo "$c"; }
client_count(){ iw dev "$1" station dump 2>/dev/null | grep -c '^Station' || true; }
wired_up()    { nmcli -t -f TYPE,STATE device 2>/dev/null | grep -q '^ethernet:connected'; }

known_visible() {   # prints the UUID of a saved, auto-connecting wifi client profile whose SSID is in range
  local dev=$1 seen u type ssid mode auto
  seen=$(nmcli -t -f SSID device wifi list ifname "$dev" 2>/dev/null | sed 's/\\:/:/g' | sort -u)
  while IFS=: read -r u type; do
    [[ $type == 802-11-wireless ]] || continue
    [[ $(nmcli -g connection.id connection show uuid "$u" 2>/dev/null) == "$PROFILE" ]] && continue
    mode=$(nmcli -g 802-11-wireless.mode connection show uuid "$u" 2>/dev/null); [[ $mode == ap || $mode == adhoc ]] && continue
    auto=$(nmcli -g connection.autoconnect connection show uuid "$u" 2>/dev/null); [[ $auto == no ]] && continue
    ssid=$(nmcli -g 802-11-wireless.ssid connection show uuid "$u" 2>/dev/null)
    [[ -n $ssid ]] && grep -qxF -- "$ssid" <<<"$seen" && { echo "$u"; return 0; }
  done < <(nmcli -t -f UUID,TYPE connection show 2>/dev/null)
  return 1
}

joined_client() {   # true when the wifi device is connected to something other than our hotspot
  local dev=$1 a; [[ $(dev_state "$dev") == 100 ]] || return 1
  a=$(active_conn "$dev"); [[ -n $a && $a != "$PROFILE" ]]
}

try_known() {
  local dev=$1 u
  u=$(known_visible "$dev") || return 1
  log "known network in range ($(nmcli -g connection.id connection show uuid "$u" 2>/dev/null)); connecting"
  nmcli -w "$CONNECT_TIMEOUT" connection up uuid "$u" ifname "$dev" >/dev/null 2>&1 && joined_client "$dev"
}

start_hotspot() {
  local dev=$1
  if [[ $HOTSPOT_WITH_ETHERNET != 1 ]] && wired_up; then log "wired network is up; not starting the hotspot"; return 0; fi
  log "starting fallback hotspot"
  nmcli -w "$CONNECT_TIMEOUT" connection up id "$PROFILE" ifname "$dev" >/dev/null 2>&1 \
    && log "hotspot is up" || log "could not start the hotspot (is profile '$PROFILE' present? country code set?)"
}

cycle() {
  local dev st act n
  [[ $(nmcli radio wifi 2>/dev/null) == enabled ]] || { log "wifi radio is off; leaving it alone"; return 0; }
  dev=$(wifi_dev); [[ -n $dev ]] || { log "no wifi device"; return 0; }
  nmcli -t -f NAME connection show 2>/dev/null | grep -qxF "$PROFILE" || { log "profile '$PROFILE' missing; run: digipi64-wifi-fallback configure"; return 0; }
  st=$(dev_state "$dev"); act=$(active_conn "$dev")
  if joined_client "$dev"; then return 0; fi                              # on a normal network: nothing to do
  if [[ $act == "$PROFILE" ]]; then                                       # hosting the fallback network
    n=$(client_count "$dev")
    if (( n > 0 )); then log "hotspot has $n client(s); leaving it up"; return 0; fi
    log "hotspot has no clients; checking for a known network"
    nmcli connection down id "$PROFILE" >/dev/null 2>&1; sleep 3
    joined_client "$dev" && { log "joined a network on its own"; return 0; }
    nmcli device wifi rescan ifname "$dev" >/dev/null 2>&1; sleep 8
    try_known "$dev" && { log "joined known network"; return 0; }
    log "no known network available"; start_hotspot "$dev"; return 0
  fi
  if [[ -n $st && $st -ge 40 && $st -lt 100 ]]; then log "wifi is connecting; waiting"; return 0; fi
  log "wifi is not connected"                                              # nothing active: join a known network or host
  nmcli device wifi rescan ifname "$dev" >/dev/null 2>&1; sleep 6
  try_known "$dev" && return 0
  start_hotspot "$dev"
}

status() {
  local dev; dev=$(wifi_dev)
  echo "wifi device : ${dev:-none}"
  echo "state       : $(nmcli -t -g GENERAL.STATE device show "$dev" 2>/dev/null)"
  echo "connection  : $(active_conn "$dev")"
  echo "hotspot     : $PROFILE   clients now: $(client_count "$dev")"
  echo "interval    : ${INTERVAL}s"
  iw reg get 2>/dev/null | grep -m1 country | sed 's/^/regulatory  : /'
}

valid_ssid() { [[ ${#1} -ge 1 && ${#1} -le 32 && $1 != *\\* && $1 =~ ^[[:print:]]+$ ]]; }
valid_psk()  { [[ ${#1} -ge 8 && ${#1} -le 63 && $1 != *\\* && $1 =~ ^[[:print:]]+$ ]]; }

configure() {
  local ssid psk psk2
  while :; do read -r -p "Fallback hotspot name (SSID, 1-32 characters): " ssid
    valid_ssid "$ssid" && break
    echo "Use 1-32 printable characters, no backslash."; done
  while :; do read -r -s -p "Hotspot password (8-63 characters): " psk; echo; read -r -s -p "Repeat password: " psk2; echo
    [[ $psk == "$psk2" ]] || { echo "They do not match."; continue; }
    valid_psk "$psk" && break
    echo "Use 8-63 printable characters, no backslash."; done
  write_profile "$ssid" "$psk" && echo "Saved. It takes effect the next time the hotspot starts."
}

write_profile() {   # <ssid> <psk>: NetworkManager keyfile (the password never appears on a command line)
  local ssid=$1 psk=$2 f=/etc/NetworkManager/system-connections/$PROFILE.nmconnection dev uuid
  dev=$(wifi_dev); uuid=$(cat /proc/sys/kernel/random/uuid)
  [[ -f $f ]] && uuid=$(sed -n 's/^uuid=//p' "$f" | head -n1)
  (umask 077; cat > "$f" <<EOF
[connection]
id=$PROFILE
uuid=$uuid
type=wifi
autoconnect=false
${dev:+interface-name=$dev}

[wifi]
mode=ap
ssid=$ssid
band=bg

[wifi-security]
key-mgmt=wpa-psk
psk=$psk

[ipv4]
method=shared

[ipv6]
method=ignore
EOF
  )
  chmod 600 "$f"; chown root:root "$f"
  nmcli connection reload
}

case ${1:-} in
  run)       sleep "$BOOT_DELAY"
             trap 'kill $(jobs -p) 2>/dev/null; exit 0' TERM INT
             while :; do cycle || true; sleep "$INTERVAL" & wait $!; done ;;
  once)      cycle ;;
  status)    status ;;
  configure) [[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }; configure ;;
  write-profile) [[ $EUID -eq 0 ]] || exit 1; write_profile "${FB_SSID:?}" "${FB_PSK:?}" ;;   # values come from the environment, never argv
  write-profile-stdin)   # used by the web page: line 1 = SSID, line 2 = password
             [[ $EUID -eq 0 ]] || exit 1; IFS= read -r s; IFS= read -r p
             valid_ssid "$s" && valid_psk "$p" || { echo "invalid name or password" >&2; exit 3; }
             write_profile "$s" "$p" && systemctl enable --now digipi64-wifi-fallback.service >/dev/null 2>&1; exit 0 ;;
  show)      [[ $EUID -eq 0 ]] || exit 1; f=/etc/NetworkManager/system-connections/$PROFILE.nmconnection
             [[ -r $f ]] && sed -n 's/^ssid=//p' "$f" | head -n1 ;;       # SSID only, never the password
  apply)     [[ $EUID -eq 0 ]] || exit 1                                     # restart the hotspot with the new settings (only if it is up now)
             d=$(wifi_dev); [[ -n $d && $(active_conn "$d") == "$PROFILE" ]] || exit 0
             setsid bash -c "sleep 2; nmcli connection down id '$PROFILE'; sleep 2; nmcli connection up id '$PROFILE'" >/dev/null 2>&1 </dev/null & ;;
  *)         sed -n '2,8p' "$0"; exit 2 ;;
esac
WIFIFB_EOF
  chmod 0755 /usr/local/sbin/digipi64-wifi-fallback
  if [[ -n $FB_SSID ]]; then
    FB_SSID="$FB_SSID" FB_PSK="$FB_PSK" /usr/local/sbin/digipi64-wifi-fallback write-profile \
      || { warn "Could not write the hotspot profile"; review "Wi-Fi fallback: profile not written"; FB_SSID=""; }
    FB_PSK=""
  fi
  cat > /etc/systemd/system/digipi64-wifi-fallback.service <<'FBUNIT'
[Unit]
Description=Fallback Wi-Fi hotspot when no known network is available
After=NetworkManager.service
Wants=NetworkManager.service

[Service]
ExecStart=/usr/local/sbin/digipi64-wifi-fallback run
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
FBUNIT
  systemctl daemon-reload
  if [[ -n $FB_SSID ]]; then systemctl enable --now digipi64-wifi-fallback.service || warn "Could not start digipi64-wifi-fallback.service"; fi
  # web page (served by DigiPi's own web server) to change the hotspot name/password without the old password
  cat > /var/www/html/hotspot.php <<'HSPHP'
<?php
// Change the fallback Wi-Fi hotspot name/password. No old password is asked: this is the recovery page.
$tool = '/usr/local/sbin/digipi64-wifi-fallback';
function run_tool($args, $stdin = null) {
  global $tool;
  $p = proc_open(array_merge(['/usr/bin/sudo', '-n', $tool], $args), [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']], $pipes);
  if (!is_resource($p)) return [1, ''];
  if ($stdin !== null) fwrite($pipes[0], $stdin);
  fclose($pipes[0]);
  $out = stream_get_contents($pipes[1]); fclose($pipes[1]); fclose($pipes[2]);
  return [proc_close($p), trim($out)];
}
$msg = ''; $ok = false;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $ssid = $_POST['ssid'] ?? ''; $psk = $_POST['psk'] ?? ''; $psk2 = $_POST['psk2'] ?? '';
  $bad = fn($v) => !preg_match('/^[\x20-\x7e]+$/', $v) || strpos($v, '\\') !== false;
  if ($ssid === '' || strlen($ssid) > 32 || $bad($ssid)) $msg = 'Name must be 1-32 printable characters, no backslash.';
  elseif (strlen($psk) < 8 || strlen($psk) > 63 || $bad($psk)) $msg = 'Password must be 8-63 printable characters, no backslash.';
  elseif ($psk !== $psk2) $msg = 'The two passwords do not match.';
  else {
    [$rc, ] = run_tool(['write-profile-stdin'], $ssid . "\n" . $psk . "\n");
    if ($rc !== 0) $msg = 'Could not save the hotspot settings.';
    else {
      $ok = true; $msg = 'Saved. The new name and password are used the next time the hotspot starts.';
      if (!empty($_POST['apply'])) { run_tool(['apply']); $msg .= ' If the hotspot is up right now it restarts in a few seconds and anything connected to it drops off.'; }
    }
  }
}
[, $cur] = run_tool(['show']);
$h = fn($s) => htmlspecialchars($s, ENT_QUOTES);
?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Fallback hotspot</title>
<style>
:root{--bg:#fff;--fg:#1c1f23;--mut:#5b6470;--card:#f4f6f8;--bd:#d5dae0;--ac:#0b6bcb;--ok:#14733c;--er:#b42318}
@media (prefers-color-scheme:dark){:root{--bg:#14171a;--fg:#e8ebee;--mut:#9aa4af;--card:#1e2328;--bd:#333b43;--ac:#5aa9ff;--ok:#4cc582;--er:#ff7b6e}}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.5 system-ui,sans-serif}
main{max-width:520px;margin:0 auto;padding:32px 16px}
.card{background:var(--card);border:1px solid var(--bd);border-radius:10px;padding:20px}
label{display:block;margin:14px 0 4px;font-weight:600}
input[type=text],input[type=password]{width:100%;box-sizing:border-box;padding:10px;border:1px solid var(--bd);border-radius:6px;background:var(--bg);color:var(--fg);font:inherit}
button{margin-top:18px;padding:10px 18px;border:0;border-radius:6px;background:var(--ac);color:#fff;font:inherit;font-weight:600;cursor:pointer}
.m{color:var(--mut);font-size:14px}.ok{color:var(--ok)}.er{color:var(--er)}a{color:var(--ac)}
</style></head><body><main>
<p><a href="/">&larr; Home</a></p>
<h1>Fallback hotspot</h1>
<p class="m">Wi-Fi network this Pi hosts when no known network is in range. Current name: <strong><?= $cur !== '' ? $h($cur) : 'not set' ?></strong>. The old password is not needed.</p>
<?php if ($msg): ?><p class="<?= $ok ? 'ok' : 'er' ?>" role="status"><?= $h($msg) ?></p><?php endif; ?>
<form class="card" method="post" autocomplete="off">
<label for="ssid">Hotspot name (SSID)</label><input id="ssid" name="ssid" type="text" maxlength="32" required value="<?= $h($ok ? '' : ($_POST['ssid'] ?? $cur)) ?>">
<label for="psk">New password (8-63 characters)</label><input id="psk" name="psk" type="password" minlength="8" maxlength="63" required>
<label for="psk2">Repeat password</label><input id="psk2" name="psk2" type="password" minlength="8" maxlength="63" required>
<label><input type="checkbox" name="apply" value="1"> Restart the hotspot now if it is up (disconnects anyone using it)</label>
<button type="submit">Save</button>
</form>
<p class="m">Anyone who can reach this page can change the hotspot, like the other DigiPi pages. Use it on a network you trust.</p>
</main></body></html>
HSPHP
  chown root:root /var/www/html/hotspot.php; chmod 0644 /var/www/html/hotspot.php
  cat > /etc/sudoers.d/digipi64-hotspot <<'HSSUDO'
www-data ALL=(root) NOPASSWD: /usr/local/sbin/digipi64-wifi-fallback show, /usr/local/sbin/digipi64-wifi-fallback write-profile-stdin, /usr/local/sbin/digipi64-wifi-fallback apply
HSSUDO
  chmod 0440 /etc/sudoers.d/digipi64-hotspot
  visudo -cf /etc/sudoers.d/digipi64-hotspot >/dev/null || { warn "hotspot sudoers rule invalid; removed"; rm -f /etc/sudoers.d/digipi64-hotspot; }
  if [[ -d /etc/digipi64/apps.d ]]; then
    printf 'TITLE=Fallback hotspot\nDESC=Change the fallback Wi-Fi name and password\nURL=http://{host}:%s/hotspot.php\nORDER=90\n' "$WEB_PORT" > /etc/digipi64/apps.d/hotspot.app
    [[ -x /usr/local/sbin/digipi64-landing ]] && /usr/local/sbin/digipi64-landing || true
  fi
  local c; c=$(iw reg get 2>/dev/null | awk '/country/{print $2; exit}')
  if [[ -z $c || $c == 00:* || $c == 00 ]]; then
    warn "Wi-Fi country is not set; the hotspot may not start. Set it: sudo raspi-config nonint do_wifi_country US (use your country code)"
    review "Wi-Fi regulatory country unset: sudo raspi-config nonint do_wifi_country <CC>"
  fi
  [[ -n $FB_SSID ]] || { review "Wi-Fi fallback hotspot not configured yet: open the Fallback hotspot page on the landing page (http://$(hostname).local:$WEB_PORT/hotspot.php) or run: sudo digipi64-wifi-fallback configure"; return 0; }
  review "Wi-Fi fallback hotspot '$FB_SSID': checks every 3 min. Status: sudo digipi64-wifi-fallback status. Change name/password: sudo digipi64-wifi-fallback configure. A single radio cannot be a client and a hotspot at once, so the hotspot is offline for ~15 s per check when no one is connected to it."
}

# ----------------------------- OSOYOO DSI screen (optional) --------------------
# Off by default: INSTALL_OSOYOO_DSI_7INCH=1 on install, or later:  sudo digipi64-setup osoyoo-dsi-panel-7inch
# That command only (re)builds the screen driver and installs the boot check; it changes nothing else on the Pi.
# Rotation and touch mapping are NOT set here: configure those in the desktop (Screen Configuration) yourself.
# Driver: https://github.com/osoyoo/osoyoo-dsi-panel
setup_osoyoo_dsi() {
  log "OSOYOO 7-inch DSI screen"
  case $OSOYOO_DSI_PORT in dsi0|dsi1) ;; *) die "OSOYOO_DSI_PORT must be dsi0 or dsi1";; esac
  apt-get install -y git build-essential device-tree-compiler i2c-tools \
    || warn "some packages were not installed"
  local src=/usr/local/src/osoyoo-dsi-panel
  if [[ -d $src/.git ]]; then git -C "$src" pull --ff-only || warn "could not update the driver source; building what is there"
  else rm -rf "$src"; git clone --depth 1 ${OSOYOO_DSI_REF:+--branch "$OSOYOO_DSI_REF"} "$OSOYOO_DSI_REPO" "$src" || { warn "could not clone $OSOYOO_DSI_REPO"; review "OSOYOO screen: driver source not downloaded"; return 0; }; fi
  # the driver's own installer builds against the running kernel, builds the overlay and edits config.txt (never reboots here)
  if ( cd "$src" && ./install-direct.sh display7inch "$OSOYOO_DSI_PORT" </dev/null ); then echo "  driver built and installed"
  else warn "OSOYOO driver build failed (see output above)"; review "OSOYOO screen: driver build failed; re-run: sudo digipi64-setup osoyoo-dsi-panel-7inch"; return 0; fi
  install -d /etc/digipi64
  printf '# written by digipi64-setup (osoyoo-dsi-panel-7inch)\nPANEL=display7inch\nPORT=%s\nAUTOREBOOT=%s\n' \
    "$OSOYOO_DSI_PORT" "$OSOYOO_DSI_AUTOREBOOT" > /etc/digipi64/osoyoo-dsi.conf
  cat > /usr/local/sbin/digipi64-osoyoo-dsi-check <<'DSICHK'
#!/bin/bash
# digipi64-osoyoo-dsi-check: run at boot. If the OSOYOO DSI screen's control chip answers on the I2C bus but its
# kernel driver is not active (typically after a kernel update), rebuild and load the driver.
# No screen on the bus = nothing to do.
CONF=${DSI_CONF:-/etc/digipi64/osoyoo-dsi.conf}
I2C=${DSI_I2C_SYSFS:-/sys/bus/i2c/devices}
STATE=${DSI_STATE:-/var/lib/digipi64}
SRC=/usr/local/src/osoyoo-dsi-panel
PANEL=display7inch; PORT=dsi1; AUTOREBOOT=1
[[ -r $CONF ]] && . "$CONF"
log() { echo "osoyoo-dsi-check: $*"; logger -t osoyoo-dsi-check -- "$*" 2>/dev/null || true; }

find_mcu() {   # the screen's microcontroller (i2c 0x45) as declared by the device-tree overlay
  local d
  for d in "$I2C"/*-0045; do
    [[ -e $d ]] || continue
    tr -d '\0' < "$d/of_node/compatible" 2>/dev/null | grep -q 'osoyoo,touchscreen-panel-regulator' && { echo "$d"; return 0; }
  done
  return 1
}
bound() { [[ -e $1/driver ]]; }

dev=$(find_mcu) || { log "no OSOYOO screen device on the I2C bus (overlay not active); nothing to do"; exit 0; }
bound "$dev" && { log "screen driver is active"; exit 0; }

bus=$(basename "$dev"); bus=${bus%%-*}
modprobe i2c-dev 2>/dev/null || true
# The screen's microcontroller is powered from the DSI cable even without the driver; the touch chip only after it loads.
if ! i2cdetect -y -r "$bus" 0x45 0x45 2>/dev/null | grep -qE '(^| )(45|UU)( |$)'; then
  log "driver not active, but nothing answers at i2c $bus:0x45 (screen not connected); skipping"; exit 0
fi
log "screen found on i2c-$bus but its driver is not active; trying to load it"

wait_bound() { local i; for i in 1 2 3 4 5 6 7 8 9 10; do bound "$dev" && return 0; sleep 1; done; return 1; }
modprobe osoyoo-panel-regulator 2>/dev/null; modprobe osoyoo-dsi-panel 2>/dev/null
wait_bound && { log "driver loaded"; exit 0; }

k=$(uname -r); mkdir -p "$STATE"; stamp=$STATE/osoyoo-dsi-attempt-$k
if [[ -e $stamp ]]; then log "already tried to rebuild for kernel $k; not trying again (run: sudo digipi64-setup osoyoo-dsi-panel-7inch)"; exit 0; fi
date > "$stamp"
[[ -d $SRC ]] || { log "driver source $SRC missing"; exit 1; }
log "rebuilding the driver for kernel $k"
for i in 1 2 3 4 5 6; do getent hosts deb.debian.org >/dev/null 2>&1 && break; sleep 10; done   # headers come from apt
if ! ( cd "$SRC" && ./install-direct.sh "$PANEL" "$PORT" </dev/null ); then log "rebuild failed"; exit 1; fi
modprobe osoyoo-panel-regulator 2>/dev/null; modprobe osoyoo-dsi-panel 2>/dev/null
if wait_bound; then log "driver rebuilt and loaded"; exit 0; fi
if [[ $AUTOREBOOT == 1 ]]; then log "driver rebuilt; rebooting once to bring the screen up"; systemctl reboot; else log "driver rebuilt; reboot to bring the screen up"; fi
exit 0
DSICHK
  chmod 0755 /usr/local/sbin/digipi64-osoyoo-dsi-check
  # earlier versions of this script also rotated the screen and mapped touch; remove what they left behind
  rm -f /usr/local/bin/digipi64-osoyoo-rotate
  local lc=$TARGET_HOME/.config/labwc
  if [[ -f $lc/autostart ]] && grep -q 'digipi64 osoyoo-dsi begin' "$lc/autostart"; then
    sed -i '/# digipi64 osoyoo-dsi begin/,/# digipi64 osoyoo-dsi end/d' "$lc/autostart"
    # a user autostart file REPLACES the system one, so an emptied file must go
    grep -qE '^[[:space:]]*[^[:space:]#]' "$lc/autostart" || rm -f "$lc/autostart"
  fi
  [[ -f $lc/rc.xml ]] && sed -i '/<!-- digipi64 osoyoo-dsi begin -->/,/<!-- digipi64 osoyoo-dsi end -->/d' "$lc/rc.xml"
  if [[ $OSOYOO_DSI_AUTOFIX == 1 ]]; then
    cat > /etc/systemd/system/osoyoo-dsi-check.service <<'DSIUNIT'
[Unit]
Description=Rebuild the OSOYOO DSI screen driver if a kernel update broke it
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/digipi64-osoyoo-dsi-check
TimeoutStartSec=1200

[Install]
WantedBy=multi-user.target
DSIUNIT
    systemctl daemon-reload; systemctl enable osoyoo-dsi-check.service >/dev/null 2>&1 && echo "  boot check enabled (osoyoo-dsi-check.service)"
  else systemctl disable osoyoo-dsi-check.service >/dev/null 2>&1 || true; fi
  rm -f "$STATE"/osoyoo-dsi-attempt-*        # a manual run clears the boot check's one-try-per-kernel guard
  review "OSOYOO 7-inch DSI screen installed on $OSOYOO_DSI_PORT (rotation/touch are left to the desktop settings). REBOOT to bring it up. After a kernel update: sudo digipi64-setup osoyoo-dsi-panel-7inch (the boot check does this by itself when the screen is connected)."
  echo "  reboot to bring the screen up"
}

# ----------------------------- desktop VNC server -----------------------------
# Raspberry Pi OS's own desktop VNC (wayvnc, port 5900; the same switch as raspi-config > Interface Options > VNC).
# Not related to DigiPi's private TigerVNC session on :1 / noVNC 6080. Login uses the Pi account's own password.
setup_desktop_vnc() {
  [[ $DESKTOP_VNC == 1 ]] || { echo "  DESKTOP_VNC=0: desktop VNC left as it is"; return 0; }
  log "Raspberry Pi desktop VNC (wayvnc, port 5900)"
  if command -v raspi-config >/dev/null 2>&1 && raspi-config nonint do_vnc 0; then { echo "  VNC enabled with raspi-config"; review "Desktop VNC (port 5900) is on: it needs the desktop session running (auto-login) and uses your Pi account's password."; }
  else
    command -v wayvnc >/dev/null 2>&1 || apt-get install -y wayvnc || warn "wayvnc not installed"
    if systemctl enable --now wayvnc.service >/dev/null 2>&1; then { echo "  wayvnc.service enabled"; review "Desktop VNC (port 5900) is on: it needs the desktop session running (auto-login) and uses your Pi account's password."; }
    else warn "could not enable the desktop VNC server"; review "Desktop VNC not enabled: run  sudo raspi-config nonint do_vnc 0  (or Interface Options > VNC in raspi-config)"; fi
  fi
}

# ----------------------------- on-screen keyboard toggle ----------------------
# A taskbar button (and menu entry "On-screen keyboard") that turns the squeekboard keyboard on or off. When it is off, a
# small login-time guard keeps squeekboard from running, so it cannot pop up over the apps; when on, squeekboard is allowed again.
setup_osk_toggle() {
  [[ $OSK_TOGGLE == 1 ]] || { echo "  OSK_TOGGLE=0: no keyboard button"; return 0; }
  log "On-screen keyboard toggle (taskbar button)"
  case $OSK_DEFAULT in on|off) ;; *) die "OSK_DEFAULT must be on or off";; esac
  cat > /usr/local/bin/digipi64-osk <<'OSKEOF'
#!/bin/bash
# digipi64-osk: switch the squeekboard on-screen keyboard on or off for the current user.
#   digipi64-osk toggle | on | off | status | guard
# The choice is kept in ~/.config/digipi64/osk and survives reboots. 'guard' runs at login and enforces it.
STATE_FILE=${XDG_CONFIG_HOME:-$HOME/.config}/digipi64/osk
DEFAULT=off; [[ -r /etc/digipi64/osk.conf ]] && . /etc/digipi64/osk.conf
get() { local v; v=$(cat "$STATE_FILE" 2>/dev/null); [[ $v == on || $v == off ]] && echo "$v" || echo "$DEFAULT"; }
put() { mkdir -p "$(dirname "$STATE_FILE")"; echo "$1" > "$STATE_FILE"; }
note() { command -v notify-send >/dev/null && notify-send -t 2500 -i input-keyboard "On-screen keyboard" "$1" 2>/dev/null; return 0; }
apply() {
  if [[ $1 == off ]]; then
    pkill -x squeekboard 2>/dev/null
  else
    pgrep -x squeekboard >/dev/null || { command -v squeekboard >/dev/null && setsid squeekboard >/dev/null 2>&1 9>&- < /dev/null & }   # 9>&-: do not hand the guard lock to squeekboard
  fi
  return 0
}
case ${1:-toggle} in
  status) get ;;
  on|off) put "$1"; apply "$1"; note "$1" ;;
  toggle) if [[ $(get) == on ]]; then n=off; else n=on; fi; put "$n"; apply "$n"; note "now $n" ;;
  guard)
    exec 9>"${XDG_RUNTIME_DIR:-/tmp}/digipi64-osk.lock"; flock -n 9 || exit 0   # one guard per login
    last=
    while :; do
      st=$(get)
      if [[ $st == off ]]; then pgrep -x squeekboard >/dev/null && pkill -x squeekboard
      elif [[ $last == off ]]; then apply on; fi
      last=$st; sleep 1
    done ;;
  *) echo "usage: digipi64-osk toggle|on|off|status" >&2; exit 2 ;;
esac
exit 0
OSKEOF
  chmod 0755 /usr/local/bin/digipi64-osk
  install -d /etc/digipi64
  # first run only: keep a later change of the setting
  [[ -e /etc/digipi64/osk.conf ]] || echo "DEFAULT=$OSK_DEFAULT" > /etc/digipi64/osk.conf
  cat > /usr/share/applications/digipi64-osk.desktop <<'EOF2'
[Desktop Entry]
Type=Application
Name=On-screen keyboard
Comment=Turn the on-screen keyboard (squeekboard) on or off
Exec=/usr/local/bin/digipi64-osk toggle
Icon=input-keyboard
Terminal=false
Categories=Utility;Accessibility;
EOF2
  cat > /etc/xdg/autostart/digipi64-osk.desktop <<'EOF2'
[Desktop Entry]
Type=Application
Name=On-screen keyboard guard
Exec=/usr/local/bin/digipi64-osk guard
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF2
  # put the button on the taskbar (wf-panel-pi); it reads ~/.config/wf-panel-pi.ini
  local ini=$TARGET_HOME/.config/wf-panel-pi.ini c
  if [[ ! -f $ini ]]; then
    for c in /etc/xdg/wf-panel-pi/wf-panel-pi.ini /etc/xdg/wf-panel-pi.ini /usr/share/wf-panel-pi/wf-panel-pi.ini; do
      [[ -f $c ]] && { install -d -o "$TARGET_USER" "$TARGET_HOME/.config"; cp "$c" "$ini"; break; }
    done
  fi
  if [[ -f $ini ]]; then
    python3 - "$ini" <<'PYEOF2' && echo "  taskbar button added to $ini" || { warn "could not edit $ini"; review "On-screen keyboard button: add 'On-screen keyboard' to the taskbar by hand (command: digipi64-osk toggle)"; }
import re, sys
p = sys.argv[1]; s = open(p).read()
if "digipi64-osk.desktop" in s: sys.exit(0)
nums = [int(n) for n in re.findall(r"^launcher_(\d+)\s*=", s, re.M)]
line = "launcher_%06d=digipi64-osk.desktop\n" % (max(nums) + 1 if nums else 1)
if nums:
    last = list(re.finditer(r"^launcher_\d+\s*=.*\n", s, re.M))[-1]
    s = s[:last.end()] + line + s[last.end():]
elif re.search(r"^\[panel\]\s*$", s, re.M):
    m = re.search(r"^\[panel\]\s*\n", s, re.M); s = s[:m.end()] + line + s[m.end():]
else:
    s += ("\n" if s and not s.endswith("\n") else "") + "[panel]\n" + line
open(p, "w").write(s)
PYEOF2
    chown "$TARGET_USER:$(id -gn "$TARGET_USER")" "$ini"
    grep -qE '^widgets_(left|right)=.*launchers' "$ini" || review "On-screen keyboard button: ~/.config/wf-panel-pi.ini has no 'launchers' widget on the taskbar; add the 'On-screen keyboard' launcher in the taskbar settings (or use: digipi64-osk toggle)"
  else
    warn "wf-panel-pi.ini not found; the taskbar button was not added"
    review "On-screen keyboard button: no taskbar config found. It is in the start menu (Accessories > On-screen keyboard); add it to the taskbar by hand, or use: digipi64-osk toggle"
  fi
  echo "  keyboard is '$(cat /etc/digipi64/osk.conf | sed -n 's/^DEFAULT=//p')' after login; click the taskbar keyboard button to switch (log out and in once to see the button)"
}

# ----------------------------- checks ----------------------------------------
audit() {
  log "Audit: symlinks and unit dependencies"
  local l t b
  # 1) symlinks that DigiPi shipped
  while IFS= read -r l; do
    [[ -L ${l#$STAGE} ]] || continue          # not deployed (removed on purpose): nothing to check
    t=$(readlink -m "${l#$STAGE}") ; [[ -e $t ]] && continue
    case $t in
      "$TARGET_HOME"/*|/var/cache/digipi/*|/var/lib/digipi/*|/var/log/digipi/*)
        b=$(basename "$t")
        if [[ $b == *.* ]]; then install -D -o "$TARGET_USER" -g "$TARGET_USER" /dev/null "$t" 2>/dev/null || true
        else install -d -o "$TARGET_USER" -g "$TARGET_USER" "$t" 2>/dev/null || true; fi
        echo "  created missing symlink target: $t" ;;
      *) echo "  DANGLING: ${l#$STAGE} -> $t"; review "dangling symlink: ${l#$STAGE} -> $t" ;;
    esac
  done < <(find "$STAGE" -type l 2>/dev/null)
  # 2) executables referenced by installed units
  local f x
  for f in "$STAGE"/etc/systemd/system/*; do
    [[ -f $f ]] || continue
    grep -hE '^Exec(Start|StartPre|StartPost|Stop)=' "$f" | sed -E 's/^[^=]*=//; s/^[-@+!:]+//' | awk '{print $1}' |
    while IFS= read -r x; do
      [[ -x $x ]] || command -v "$x" >/dev/null 2>&1 || { echo "  MISSING executable for $(basename "$f"): $x"; review "missing executable for $(basename "$f"): $x"; }
    done
  done
  audit_localize_targets
  audit_script_paths
  if [[ -s $REVIEW ]]; then warn "Items needing your eyes are in $REVIEW"; else echo "  nothing to review"; fi
}

summary() {
  log "Done"
  cat <<EOF
Hostname (unchanged): $(hostname)     User (unchanged): $TARGET_USER
$([[ $INSTALL_NGINX == 1 ]] && echo "Landing:  https://$(hostname).local/   (links to DigiPi, Kiwix and any apps you add: digipi64-addapp)")
Web UI:   http://$(hostname).local$([[ $WEB_PORT != 80 ]] && echo ":$WEB_PORT")/   -> click Initialize (setup.php)
Re-run Initialize any time: use the Reconfigure button on setup.php, or sudo digipi64-setup reconfigure
Review list:    $REVIEW
Skipped units:  ${SKIPPED_UNITS[*]:-none}   (stored in $STATE/skipped-units; use FORCE_UNITS to install)
32-bit binaries not deployed: $(wc -l < "$STATE/elf-removed.txt" 2>/dev/null || echo 0)  (names: $STATE/elf-removed.txt; 64-bit system equivalents are linked in /usr/local/bin)
Packages missing from repos: ${MISSING_PKGS[*]:-none}
Log: $LOG
Group changes take effect after logging out/in. Reboot to start the DigiPi services.
EOF
}

# ----------------------------- main ------------------------------------------
resolve_user
case $MODE in
  install)
    preflight; ask_fallback; make_rw; install_packages; build_direwolf; build_modems; install_pat; install_aprsd; install_dashboard; setup_vnc
    build_stage; deploy_stage; link_replacements; ensure_gpsd_default; python_deps; setup_web; gen_sudoers; enable_units; install_extras; setup_frontend; install_ardop_launcher; setup_ham_menu; setup_wifi_fallback; setup_desktop_vnc; setup_osk_toggle; (( INSTALL_OSOYOO_DSI_7INCH )) && setup_osoyoo_dsi; audit
    [[ -r ${BASH_SOURCE[0]} ]] && install -m 0755 "${BASH_SOURCE[0]}" "$SELF_INSTALLED"
    summary ;;
  reconfigure)
    [[ -d $STAGE ]] || die "Nothing staged; run the install first."
    (( UPDATE )) && { build_stage; gen_sudoers; FULL=1; }
    if (( FULL )); then deploy_stage; fi        # --full / --update: redeploy every repo file
    restore_templates                           # default: only the files Initialize rewrites
    rm -f /var/cache/digipi/localized.txt
    [[ $(hostname) == "$(cat "$STATE/hostname.orig")" ]] || warn "Hostname differs from install-time value ($(cat "$STATE/hostname.orig")); restore it if unintended."
    echo "Initialize templates restored. Open /setup.php (Initialize) to configure again." ;;
  osoyoo-dsi-panel-7inch)      # screen only: nothing else on the system is touched
    [[ $EUID -eq 0 ]] || die "Run as root (sudo)."
    setup_osoyoo_dsi; echo "Done. Reboot to load the new driver." ;;
  osk)                         # keyboard toggle only
    [[ $EUID -eq 0 ]] || die "Run as root (sudo)."
    setup_osk_toggle ;;
  audit)
    [[ -d $STAGE ]] || die "Nothing staged; run the install first."
    : > "$REVIEW"; audit ;;
esac
