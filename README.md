# digipi64-setup

Installs the features of [DigiPi](https://github.com/craigerl/digipi) on a general-purpose,
64-bit Raspberry Pi OS (tested on a Raspberry Pi 5 with Bookworm; written for Bookworm and Trixie).

DigiPi's own disk image is a closed, 32-bit, read-only kiosk. This script instead takes the open
configuration and web files from the DigiPi GitHub repository and sets them up on a normal
read/write system, so the Pi stays usable for other things. DigiPi's built-in web pages are used
to start and stop the ham radio modes.

## What it will not change

- **Hostname.** Never changed (the original is saved in `/var/lib/digipi64/hostname.orig`).
- **User account.** The account you run `sudo` from is the DigiPi user. It is never created,
  renamed, or given a new password. It is only added to hardware groups (audio, dialout, plugdev,
  gpio, i2c, spi, video).
- **Your dotfiles.** Nothing in your `~/.*` files is overwritten.
- **Networking.** DigiPi's hotspot and resolv.conf units are skipped. Use your normal Pi networking.
- **Boot files.** `/boot/firmware/config.txt` is not edited (audio HAT overlays, display drivers).

The root filesystem is left read/write. If the Pi is running an overlay (read-only) root, the
script turns it off and asks you to reboot and run it again.

## Requirements

- Raspberry Pi, 64-bit (aarch64) Raspberry Pi OS, Bookworm or Trixie
- Internet access (GitHub and the Debian package repositories)
- Run from your normal account, which needs passwordless `sudo`
- Optional: you will need your callsign, grid square, and similar details for Initialize

## Quick start

```bash
chmod +x digipi64-setup.sh
sudo ./digipi64-setup.sh install 2>&1 | tail -n 80
sudo cat /var/lib/digipi64/REVIEW.txt
```

Then reboot, open `https://<hostname>.local/` (the landing page) from another device, follow the **DigiPi**
link (`http://<hostname>.local:8081/`), and click **Initialize**.

Run it with `sudo` from your own account (not as a root login). To set the user explicitly:
`sudo DIGIPI_USER=<name> ./digipi64-setup.sh install`.

## Commands

| Command | What it does |
| --- | --- |
| `sudo ./digipi64-setup.sh install` | Full install (the default). Safe to run again. |
| `sudo ./digipi64-setup.sh install --update` | Fetch the latest DigiPi repo files again, rebuild, and redeploy. |
| `sudo digipi64-setup reconfigure` | Restore only the files Initialize rewrites, then unlock Initialize. |
| `sudo digipi64-setup reconfigure --full` | Redeploy every DigiPi file. This also resets app settings. |
| `sudo digipi64-setup audit` | Re-run the dependency, symlink and unit checks. Changes nothing. |

After the first install, the script copies itself to `/usr/local/sbin/digipi64-setup`, so the
`digipi64-setup` command works from anywhere.

### Environment variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `DIGIPI_USER` | the `sudo` user | User account DigiPi files belong to |
| `DIGIPI_REF` | `main` | Branch or tag of the DigiPi repo |
| `DIREWOLF_REF` | `dev` | Direwolf branch or tag. If it fails to build, `1.7` is tried automatically. |
| `APRSD_VERSION` | `4.2.4` | APRSD version for the Python venv |
| `DIGIPI_WEB_PORT` | `8081` (`80` if `INSTALL_NGINX=0`) | Port of DigiPi's own web server. |
| `HAM_MENU` | `1` | Group all radio applications under one **Ham Radio** start-menu heading. Set `0` to skip. |
| `INSTALL_NGINX` | `1` | nginx on ports 80/443 with the landing page and HTTPS. Set `0` to keep DigiPi on port 80 with no landing page or HTTPS. |
| `DIGIPI_VNC` | `1` | Set `0` to skip DigiPi's VNC and noVNC session (GUI apps then will not show in the web UI) |
| `BUILD_ARDOP` | `1` | Build ardopcf (open-source ARDOP modem, used in place of DigiPi's 32-bit `piardopc`). Set `0` to skip. |
| `BUILD_MERCURY` | `1` | Build the Rhizomatica Mercury HF modem. Set `0` to skip. |
| `INSTALL_HTCOMMANDER` | `1` | Install HTCommander (Benshi/UV-Pro handheld control) from its GitHub release `.deb`. `HTCOMMANDER_DEB_URL` overrides the URL. |
| `INSTALL_HAMCLOCKSYNC` | `1` | Install [Ham Clock Sync](https://github.com/jaredBevis/ham-clock-sync) (set the clock from WWV/WWVH audio, GPS or NTP). `HAMCLOCKSYNC_REPO` / `HAMCLOCKSYNC_REF` choose another source. |
| `INSTALL_GRIDTRACKER` | `1` | Install GridTracker 2 from the official arm64 `.deb`. `GRIDTRACKER_DEB_URL` overrides the URL. |
| `INSTALL_RTW` | `1` | Install the "reboot the world" collection: FreeCAD, Scilab, KiCad. Set `0` to skip. |
| `RTW_KICAD_3D` | `0` | Set `1` to also install KiCad's 3D models (`kicad-packages3d`, about 6 GB). |
| `AUTOHOTSPOT` | `ask` | Fallback Wi-Fi hotspot. `ask` prompts during install, `1` requires `FALLBACK_SSID`/`FALLBACK_PSK` when not interactive, `0` skips. |
| `FALLBACK_SSID`, `FALLBACK_PSK` | none | Hotspot name (1-32 characters) and password (8-63) to use without prompting. |
| `INSTALL_OSOYOO_DSI_7INCH` | `0` | Install the OSOYOO 7" DSI touchscreen driver and its boot-time repair check. Off unless you ask for it. |
| `OSOYOO_DSI_PORT` | `dsi1` | Which DSI connector the screen is on (`dsi0` or `dsi1`; Pi 3/4 have one connector, use the default). |
| `OSOYOO_DSI_AUTOFIX` | `1` | Check at every boot and rebuild the driver if a kernel update broke it. `0` turns the check off. |
| `OSOYOO_DSI_AUTOREBOOT` | `1` | Let the boot check reboot once after a rebuild if the screen still did not come up. `0` = never reboot by itself. |
| `DESKTOP_VNC` | `1` | Enable the Raspberry Pi desktop VNC server (wayvnc, port 5900). Set `0` to leave it as it is. |
| `OSK_TOGGLE` | `1` | Add a taskbar button that turns the on-screen keyboard (squeekboard) on or off. Set `0` to skip. |
| `OSK_DEFAULT` | `off` | Keyboard state after install (`on` or `off`). The button changes it afterwards. |
| `INSTALL_KIWIX` | `1` | Set up the Kiwix offline-content server. Set `0` to skip. |
| `KIWIX_PORT` | `8090` | Port of the Kiwix server (plain HTTP): `http://<hostname>.local:8090/`. |
| `ADD_GROUPS` | `1` | Set `0` to skip adding the user to hardware groups |
| `FORCE_UNITS` | empty | Space-separated unit names to install even if they were skipped |

Example: `sudo DIGIPI_WEB_PORT=8081 DIGIPI_VNC=0 ./digipi64-setup.sh install`

## Using DigiPi afterwards

1. **Initialize.** Open `http://<hostname>.local:8081/` and click **Initialize**. Enter callsign, grid,
   and so on. This writes your values into `~/localize.env` and the config files. The Initialize
   link then disappears from the home page and the page says the Pi is already initialized.
2. **Start a mode.** Use the buttons on the home page (TNC, digipeater, tracker, node, WSJT-X,
   FLDigi, JS8Call, QSSTV, and so on). Starting a mode stops the others. The mode chosen as the
   default is started at boot by `digipi-boot.service`.
3. **GUI apps** (WSJT-X, FLDigi, JS8Call, QSSTV) run in a private TigerVNC session on display `:1`
   and appear in the browser through noVNC (port 6080). This is separate from the Raspberry Pi
   desktop VNC on port 5900 (wayvnc), which the installer turns on (`DESKTOP_VNC=0` to skip). Connect a VNC viewer to
   `<hostname>.local:5900` and sign in with your Pi account's username and password.

### Changing your callsign or other settings (Reconfigure)

Either use the **Reconfigure** link on the home page (it appears once the Pi is initialized), or
run `sudo digipi64-setup reconfigure`. The web page version is at `/setup.php` or `/reconfigure.php`.

Reconfigure restores only the template files Initialize rewrites (your current ones are backed up
first), removes `/var/cache/digipi/localized.txt`, and re-opens Initialize. Hostname, user account
and application data are left alone. Use `reconfigure --full` only if you also want every other
DigiPi file reset.

## What the install does

1. Checks the system (64-bit, release, internet, hostname saved, overlay filesystem, ports 80/443).
2. Installs packages (lighttpd, PHP, AX.25 tools, hamlib, gpsd, chrony, wsjtx, js8call, fldigi, flrig,
   qsstv, linpac, uronode, tigervnc, noVNC, and others). Optional packages missing from your release
   are skipped with a warning, and are listed at the end.
3. Builds Direwolf into `/usr/local`, installs Pat, and installs APRSD (plus its webchat extension) into `~/.aprsd-venv`, and installs the APRS map ([direwolf-dashboard](https://github.com/hemna/direwolf-dashboard)) into `~/direwolf-dashboard`.
4. Fetches the DigiPi repo and prepares a copy: removes the original image's dotfiles and 32-bit
   binaries, rewrites the user and home paths, stops scripts from changing the hostname or accounts,
   patches the web pages for PHP 8, and makes the Initialize page re-runnable.
5. Deploys the files (backing up anything it replaces), links 64-bit equivalents of removed binaries
   into `/usr/local/bin`, and sets up lighttpd and the narrow sudo rules the web pages need for
   `www-data`.
6. Enables only `digipi-boot.service` for boot. The mode services are started on demand.

## Extra software (not part of DigiPi)

The install also adds these, each switchable with the variables above:

- **HTCommander** and **GridTracker 2** are installed from their publishers' `.deb` files
  (not in the Raspberry Pi OS repositories). apt resolves their dependencies. GridTracker's
  download page is checked for the newest arm64 version, with a known version as fallback.
- **Ham Clock Sync** ([jaredBevis/ham-clock-sync](https://github.com/jaredBevis/ham-clock-sync), GPL-3.0+) sets the
  clock from WWV/WWVH time signals on the sound card, GPS (gpsd or serial) or NTP, which matters for FT8 and JS8Call. The
  installer adds its dependencies (numpy, tkinter, Pillow, sounddevice, PortAudio, pyserial), clones it to
  `/usr/local/src/ham-clock-sync` (updated on each re-run) and adds the `ham-clock-sync` command plus a
  **Ham Clock Sync** entry in the Ham Radio start menu. Run it as your normal user; it asks for root only when it sets the
  clock (`sudo -n`, then `pkexec`). On a small screen: `ham-clock-sync --wf-width 360 --wf-height 160`.
- **"Reboot the world" collection:** FreeCAD, Scilab, and KiCad (with its symbols, footprints and
  templates) from the Debian archive. These are large installs; make sure the SD card has room.
  KiCad's 3D models are optional (`RTW_KICAD_3D=1`).
- **Kiwix server:** serves offline Wikipedia and other [ZIM](https://library.kiwix.org/) content.
  Put `.zim` files in `~/kiwix_zim` (created for you) and open `http://<hostname>.local:8090/`.
  A watcher (`kiwix-zim-sync`) rebuilds the library whenever the folder changes, plus every 5 minutes,
  and the server reloads it by itself, so no restart is needed. Files still being copied, or that are
  not valid ZIM files, are skipped. Units: `kiwix-serve`, `kiwix-zim-sync.path`, `kiwix-zim-sync.timer`.

## Ham Radio start menu

Radio applications (WSJT-X, FLDigi and the other fl* programs, JS8Call, QSSTV, wfview, FreeDV, TrustedQSL,
GridTracker 2, HTCommander and anything else tagged as ham radio) are collected under one **Ham Radio**
heading instead of being spread over Internet, Sound & Video, Other and so on. wfview, FreeDV and TrustedQSL
are installed from the Debian archive (the version may be older than the project's latest).

How it works: for each radio application the tool `digipi64-hammenu` writes a copy of its launcher in
`/usr/local/share/applications` whose only category is `HamRadio`, and adds a Ham Radio submenu to the desktop's
application menu. The original files in `/usr/share/applications` are never edited. Log out and in (or reboot) to
see it.

- After installing more radio software, run `sudo digipi64-hammenu` (it also runs automatically after apt installs).
- To include a program it does not recognise, add its launcher name (for example `myradio.desktop`) to
  `/etc/digipi64/ham-apps.list` and run the tool again.
- To undo: `sudo digipi64-hammenu --remove`.
- If your desktop's menu file does not read its `-merged` folder, the tool adds `<DefaultMergeDirs/>` to it and keeps
  a backup next to it ending in `.digipi64.orig`.

## Landing page and HTTPS

With `INSTALL_NGINX=1` (the default), nginx owns the standard ports and DigiPi's own web server (lighttpd)
moves to **port 8081** (not 8080, which Pat's web interface uses), because DigiPi's pages only work from the root of their own site.

| Address | What it is |
| --- | --- |
| `https://<hostname>.local/` or `http://<hostname>.local/` | Landing page with a tile for each web app |
| `http://<hostname>.local:8081/` | DigiPi (Initialize, modes, logs, noVNC and other DigiPi ports unchanged) |
| `http://<hostname>.local:8090/` | Kiwix (plain HTTP, linked from the landing page) |
| `https://<hostname>.local/ca.crt` | The Pi's certificate authority, to install on your devices |

The e-ink/OLED banner texts in DigiPi's scripts still say `http://digipi/...`; they do not know about port 8081.

**Certificate.** HTTPS uses a small certificate authority created on the Pi (`/etc/digipi64/tls`). Browsers show a
warning until you trust it: download `/ca.crt` from the landing page and add it as a trusted authority on each
device or browser. The authority can only vouch for `.local` names, your hostname, `localhost` and private
(home-network) IP addresses, so it cannot be used to impersonate other websites. Keep `/etc/digipi64/tls/ca.key`
private (it is readable by root only). The server certificate is re-issued automatically when the Pi's IP
addresses change. To do it by hand: `sudo digipi64-tls`; to start over with a new authority:
`sudo digipi64-tls --new-ca` (and re-install `ca.crt` on your devices).

**Adding more web apps.** Tiles come from small files in `/etc/digipi64/apps.d`; the page rebuilds itself when
they change. The helper `digipi64-addapp` manages them:

```
sudo digipi64-addapp link   myapp "My App" "http://{host}:3000/" "Short description"
sudo digipi64-addapp proxy  myapp 3000 "My App" "Short description"     # https://<hostname>.local/myapp/ -> 127.0.0.1:3000
sudo digipi64-addapp remove myapp
sudo digipi64-addapp list
```

`{host}` becomes whatever name you browsed to. `proxy` only suits apps that work under a sub-path (`/myapp/`);
otherwise use `link` to the app's own port. nginx snippets live in `/etc/nginx/digipi-apps.d/`.

## OSOYOO 7" DSI touchscreen (optional)

Not part of a normal install. To include it: `sudo INSTALL_OSOYOO_DSI_7INCH=1 ./digipi64-setup.sh install`.

It downloads [osoyoo-dsi-panel](https://github.com/osoyoo/osoyoo-dsi-panel) to `/usr/local/src/osoyoo-dsi-panel` and runs its
`./install-direct.sh display7inch` (builds the kernel modules for the running kernel, builds the overlay, adds the
`dtoverlay=` line to `config.txt`). Reboot afterwards to load the driver.

Rotation and touch are **not** configured by the script. Set them yourself in the desktop (Screen Configuration), which
keeps them across updates and re-runs. Nothing is written to your labwc files.

**Reconfigure / repair (touches nothing else):**

```
sudo digipi64-setup osoyoo-dsi-panel-7inch
```

This pulls the driver source, rebuilds it for the current kernel, rewrites the overlay line and the boot check. None of the
DigiPi, Kiwix, web or radio software is changed.

**Automatic repair after kernel updates.** With the screen installed, `osoyoo-dsi-check.service` runs at every boot:

1. Is the screen's overlay active and the driver already working? Then it stops.
2. If the driver is not working, it asks the I2C bus whether the screen's control chip (address 0x45) answers. The chip is
   powered through the cable, unlike the touch controller, which only powers up after the driver loads. No answer means no
   screen is connected, and it does nothing.
3. If the screen is there, it tries to load the modules. If they are missing for this kernel, it rebuilds them (this needs the
   internet for kernel headers), loads them, and reboots once if the screen still did not come up. It tries once per kernel
   version, so it cannot loop. Set `OSOYOO_DSI_AUTOREBOOT=0` in `/etc/digipi64/osoyoo-dsi.conf` to disable the reboot.

Log: `journalctl -u osoyoo-dsi-check`.

Limits and notes:

- Not yet tested on a real screen.

## On-screen keyboard toggle

The squeekboard on-screen keyboard pops up over applications on a touchscreen. The installer adds a **keyboard button to the
taskbar** (also in the start menu as *On-screen keyboard*) that turns it off and on. Log out and in once after the install to see the
button.

- **Off** (the default after install): a small guard (`digipi64-osk guard`, started at login) stops squeekboard from running.
- **On**: squeekboard is allowed again and is started right away.
- The choice survives reboots (`~/.config/digipi64/osk`). From a terminal: `digipi64-osk toggle|on|off|status`.
- Start state after install: `OSK_DEFAULT=on` or `off`. No button at all: `OSK_TOGGLE=0`.
- Re-install just this: `sudo digipi64-setup osk`.
- The button is added to `~/.config/wf-panel-pi.ini` (the Pi taskbar's file). If your taskbar has no launcher area, the review list says so,
  and the menu entry still works.
