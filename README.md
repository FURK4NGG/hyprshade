## 👀 hyprshade Overview  

**hyprshade** is a Bash utility for controlling a Hyprshade shader with
three modes: automatic scheduling, disabled, and always enabled. In
automatic mode, it enables the shader at night and disables it during
the day.
<br><br>

![hyprshade Demo GIF](https://github.com/FURK4NGG/hyprshade/blob/main/%7B%7D/hyprshade.gif)

<br><br>

✅ Works On  
- Linux distributions: Arch Linux, Debian, Fedora  
- Wayland compositors: Hyprland, Sway, and other wlroots-based compositors  

⚠️ Compatibility  
Other Wayland compositors and desktop environments have not been verified yet.
<br><br>

## 🚀 Features

- [x] Three-state toggle: automatic, disabled, and always enabled  
- [x] Automatically enables the shader from 19:00 to 06:59  
- [x] Disables the shader during daytime in automatic mode  
- [x] Uses a user-level systemd timer for scheduled updates  
- [x] Sends desktop notifications when the mode changes  
- [x] Stores the current mode in a state file  
- [x] Supports command-line usage and a help message  
- [x] Provides a time argument for refreshing the automatic mode  

## 📦 Setup


<br>

<details>
<summary>Arch</summary>
   
`Go to the`[`Hyprshade 4.0.1`](https://github.com/loqusion/hyprshade/releases?utm_source=chatgpt.com)`and download exact version`
```
git clone https://github.com/FURK4NGG/hyprshade.git
cd hyprshade
mkdir -p ~/.local/bin
sudo mkdir -p ~/.config/scripts/
sudo chmod +x ~/.config/scripts/*.sh
sudo cp -f ./hyprshade-auto.sh ~/.local/bin/hyprshade-auto.sh
sudo chmod +x ~/.local/bin/hyprshade-auto.sh
sudo chmod 600 ~/.config/scripts/hyprshade-toggle-state
sudo chown $USER:$USER ~/.config/scripts/hyprshade-toggle-state
systemctl --user daemon-reload
systemctl --user enable --now hyprshade-auto.timer
```

```
sudo pacman -S --needed python python-pip python-pipx
```
</details>
<br>

<details>
<summary>Debian / Ubuntu</summary>
   
```
sudo apt update
sudo apt install -y python3-gi gir1.2-gtk-3.0 python3-cairo libnotify-bin xcompmgr
```
```
mkdir -p ~/.local/bin ~/.config/scripts ~/.config/systemd/user

cp ./night-screen-overlay.py ~/.local/bin/
cp ./hyprshade-auto.sh ~/.local/bin/

cp ./hyprshade-auto.service ~/.config/systemd/user/
cp ./hyprshade-auto.timer ~/.config/systemd/user/

chmod +x ~/.local/bin/night-screen-overlay.py
chmod +x ~/.local/bin/hyprshade-auto.sh


cat > /tmp/install-hyprshade-debian.sh <<'INSTALLER'
#!/usr/bin/env bash
set -e

echo "=== Night Screen kurulumu başlıyor ==="

# Gerekli paketler
sudo apt update
sudo apt install -y \
    python3 \
    python3-gi \
    gir1.2-gtk-3.0 \
    python3-cairo \
    libnotify-bin \
    xcompmgr

# Dizinler
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/scripts"
mkdir -p "$HOME/.cache"
mkdir -p "$HOME/.config/systemd/user"

# --------------------------------------------------
# Python overlay
# --------------------------------------------------

cat > "$HOME/.local/bin/night-screen-overlay.py" <<'PYTHON'
#!/usr/bin/env python3

import os
import sys
import time
import signal
import subprocess
from pathlib import Path

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")

from gi.repository import Gtk, Gdk, GLib
import cairo

BASE = Path.home() / ".cache"

PID_FILE = BASE / "night-screen-overlay.pid"
LOG_FILE = BASE / "night-screen-overlay.log"

# Filtre ayarları
OPACITY = 0.12

# Açık turuncu: daha yumuşak bir gece filtresi
RED = 1.00
GREEN = 0.60
BLUE = 0.28


def is_running(pid):
    try:
        os.kill(int(pid), 0)
        return True
    except (ProcessLookupError, ValueError):
        return False
    except PermissionError:
        return True


def stop():
    if not PID_FILE.exists():
        print("Night Screen overlay stopped.")
        return

    try:
        pid = int(PID_FILE.read_text().strip())

        if pid != os.getpid() and is_running(pid):
            os.kill(pid, signal.SIGTERM)

    except (ValueError, OSError):
        pass

    try:
        PID_FILE.unlink(missing_ok=True)
    except OSError:
        pass

    print("Night Screen overlay stopped.")


def start():
    BASE.mkdir(parents=True, exist_ok=True)

    if PID_FILE.exists():
        try:
            old_pid = int(PID_FILE.read_text().strip())

            if is_running(old_pid):
                print("Night Screen overlay is already running.")
                return

        except (ValueError, OSError):
            pass

        PID_FILE.unlink(missing_ok=True)

    env = os.environ.copy()
    env.setdefault("DISPLAY", ":0")
    env.setdefault("XAUTHORITY", str(Path.home() / ".Xauthority"))

    with open(LOG_FILE, "a", encoding="utf-8") as log:
        log.write("Starting overlay process.\n")
        log.flush()

        process = subprocess.Popen(
            [sys.executable, str(Path(__file__).resolve()), "run"],
            stdin=subprocess.DEVNULL,
            stdout=log,
            stderr=subprocess.STDOUT,
            start_new_session=True,
            env=env,
        )

    PID_FILE.write_text(str(process.pid))
    print("Night Screen overlay start requested.")


def run():
    os.environ.setdefault("DISPLAY", ":0")
    os.environ.setdefault(
        "XAUTHORITY",
        str(Path.home() / ".Xauthority")
    )

    PID_FILE.write_text(str(os.getpid()))

    screen = Gdk.Screen.get_default()

    if screen is None:
        print("ERROR: No graphical display is available.")
        return 1

    # X11 oturumunda saydamlık için compositor gerekir.
    session_type = os.environ.get("XDG_SESSION_TYPE", "").lower()
    is_wayland = (
        session_type == "wayland"
        or bool(os.environ.get("WAYLAND_DISPLAY"))
    )

    if not is_wayland and not screen.is_composited():
        print("GTK compositor etkin değil; xcompmgr başlatılıyor.")

        # Eski xcompmgr yanlış parametrelerle çalışıyorsa
        # doğru parametrelerle yeniden başlat.
        subprocess.run(
            ["pkill", "-x", "xcompmgr"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        time.sleep(1)

        log = open(LOG_FILE, "a", encoding="utf-8")

        try:
            subprocess.Popen(
                [
                    "xcompmgr",
                    "-c", "-C",
                    "-t-5", "-l-5",
                    "-r4", "-o0.8"
                ],
                stdin=subprocess.DEVNULL,
                stdout=log,
                stderr=subprocess.STDOUT,
                start_new_session=True,
                env=os.environ.copy(),
            )
        except OSError as exc:
            print(f"ERROR: xcompmgr başlatılamadı: {exc}")
            log.close()
            return 1

        log.close()

    window = None
    started = time.monotonic()

    def draw_overlay(widget, cr):
        cr.set_operator(cairo.OPERATOR_SOURCE)
        cr.set_source_rgba(RED, GREEN, BLUE, OPACITY)
        cr.paint()
        return False

    def create_overlay():
        nonlocal window

        screen_now = Gdk.Screen.get_default()

        if screen_now is None:
            return False

        if not is_wayland and not screen_now.is_composited():
            if time.monotonic() - started >= 20:
                print(
                    "ERROR: X11 compositor did not become ready "
                    "within 20 seconds."
                )
                Gtk.main_quit()
                return False

            return True

        window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
        window.set_title("Night Screen Overlay")
        window.set_decorated(False)
        window.set_resizable(False)
        window.set_keep_above(True)
        window.set_accept_focus(False)
        window.set_focus_on_map(False)
        window.set_app_paintable(True)

        visual = screen_now.get_rgba_visual()

        if visual is not None:
            window.set_visual(visual)

        window.connect("draw", draw_overlay)

        # Tam ekran kaplama
        window.fullscreen()
        window.show_all()

        print(f"Overlay started. Opacity: {OPACITY}")
        return False

    # Compositor'ın hazır olmasını bekle.
    GLib.timeout_add(250, create_overlay)

    try:
        Gtk.main()
    finally:
        try:
            PID_FILE.unlink(missing_ok=True)
        except OSError:
            pass

    return 0


if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else "start"

    if command == "start":
        start()
    elif command == "stop":
        stop()
    elif command == "run":
        sys.exit(run())
    else:
        print("Kullanım: night-screen-overlay.py [start|stop|run]")
        sys.exit(1)
PYTHON

chmod +x "$HOME/.local/bin/night-screen-overlay.py"

# --------------------------------------------------
# Üç mod arasında geçiş yapan ana script
# --------------------------------------------------

cat > "$HOME/.local/bin/hyprshade-auto.sh" <<'SHELL'
#!/usr/bin/env bash

set -u

OVERLAY="$HOME/.local/bin/night-screen-overlay.py"
STATE_DIR="$HOME/.config/scripts"
STATE_FILE="$STATE_DIR/hyprshade-toggle-state"

mkdir -p "$STATE_DIR"

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

# Durum dosyası yoksa otomatik modla başla.
if [[ ! -f "$STATE_FILE" ]]; then
    printf '0\n' > "$STATE_FILE"
fi

notify_user() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Night Screen" "$1" 2>/dev/null || true
    fi
}

start_filter() {
    python3 "$OVERLAY" start
}

stop_filter() {
    python3 "$OVERLAY" stop
}

apply_mode() {
    local state
    state="$(cat "$STATE_FILE" 2>/dev/null || echo 0)"

    case "$state" in
        0)
            # Otomatik: 19.00-07.00
            local hour_min
            hour_min="$(date +%H%M)"

            if (( 10#$hour_min >= 1900 || 10#$hour_min < 700 )); then
                start_filter
            else
                stop_filter
            fi
            ;;

        1)
            # Sürekli kapalı
            stop_filter
            ;;

        2)
            # Sürekli açık
            start_filter
            ;;

        *)
            printf '0\n' > "$STATE_FILE"
            stop_filter
            ;;
    esac
}

# "time" parametresi zamanlayıcı içindir:
# Modu değiştirmez, yalnızca mevcut modu uygular.
if [[ "${1:-}" == "time" ]]; then
    apply_mode
    exit 0
fi

# Parametresiz her çalıştırmada sonraki moda geç.
state="$(cat "$STATE_FILE" 2>/dev/null || echo 0)"

case "$state" in
    0) state=1 ;;
    1) state=2 ;;
    *) state=0 ;;
esac

printf '%s\n' "$state" > "$STATE_FILE"

case "$state" in
    0)
        apply_mode
        notify_user "Mod: Otomatik (19:00–07:00)"
        echo "Night Screen mode: Automatic (19:00–07:00)"
        ;;
    1)
        stop_filter
        notify_user "Mod: Kapalı"
        echo "Night Screen mode: Off"
        ;;
    2)
        start_filter
        notify_user "Mod: Her zaman açık"
        echo "Night Screen mode: Always on"
        ;;
esac
SHELL

chmod +x "$HOME/.local/bin/hyprshade-auto.sh"

# --------------------------------------------------
# systemd kullanıcı servisi
# --------------------------------------------------

cat > "$HOME/.config/systemd/user/hyprshade-auto.service" <<'SERVICE'
[Unit]
Description=Night Screen automatic mode check

[Service]
Type=oneshot
Environment=DISPLAY=:0
Environment=XAUTHORITY=%h/.Xauthority
ExecStart=%h/.local/bin/hyprshade-auto.sh time
SERVICE

# --------------------------------------------------
# Her dakika kontrol eden timer
# --------------------------------------------------

cat > "$HOME/.config/systemd/user/hyprshade-auto.timer" <<'TIMER'
[Unit]
Description=Check Night Screen mode every minute

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s
AccuracySec=5s
Unit=hyprshade-auto.service

[Install]
WantedBy=timers.target
TIMER

# systemd'yi yenile ve timer'ı etkinleştir.
systemctl --user daemon-reload
systemctl --user enable --now hyprshade-auto.timer

echo
echo "=== Kurulum tamamlandı ==="
echo
echo "Mod değiştirmek için:"
echo "  ~/.local/bin/hyprshade-auto.sh"
echo
echo "Mevcut modu kontrol etmek için:"
echo "  cat ~/.config/scripts/hyprshade-toggle-state"
echo
echo "Timer durumunu kontrol etmek için:"
echo "  systemctl --user status hyprshade-auto.timer"
echo
echo "Overlay opaklığı: %12"
echo "Otomatik saatler: 19:00–07:00"
INSTALLER

bash /tmp/install-hyprshade-debian.sh
```
## Run
```
~/.local/bin/hyprshade-auto.sh
```
or  

Start filter

```
python3 ~/.local/bin/night-screen-overlay.py start
```
<br>
Stop filter  

```
python3 ~/.local/bin/night-screen-overlay.py stop
```
</details>
<br>

Fedora
```
sudo dnf install python3 python3-pip python3-pipx unzip
```
<br><br>

```
cd ~/Downloads
unzip hyprshade-4.0.1.zip
cd hyprshade-4.0.1
pipx install .
```

hyprshade --version
>hyprshade, version 4.0.1

<br><br>

## 🎉 Run

```
~/.local/bin/hyprshade-auto.sh
```
<br><br>
   

## ❓ HOW IT WORKS ❓  
```
Run hyprshade-auto.sh  
          │  
          ▼  
 Read the saved mode  
          │  
          ▼  
 ┌────────┼───────────┐  
 ▼        ▼           ▼  
Automatic Disabled    Always On  
 ▼        ▼           ▼  
19:00–06:59  Shader    Shader  
Shader ON    OFF       ON  
Daytime OFF  
```

## [`hyprshade-auto.sh`]

- Toggles between automatic, disabled, and always-on shader modes.  
  Otomatik, kapalı ve sürekli açık shader modları arasında geçiş yapar.

- Automatically enables the shader at night and disables it during the day.  
  Shader efektini gece otomatik olarak etkinleştirir, gündüz devre dışı bırakır.

- Manages the `hyprshade-auto.timer` and related user services.  
  `hyprshade-auto.timer` ve ilgili kullanıcı servislerini yönetir.

- Saves the current mode in a state file.  
  Mevcut modu bir durum dosyasına kaydeder.

- Sends desktop notifications when the shader mode changes.  
  Shader modu değiştiğinde masaüstü bildirimleri gönderir.

- Supports command-line arguments and a help message.  
  Komut satırı argümanlarını ve yardım mesajını destekler.

- Provides a `time` argument to refresh the automatic mode.  
  Otomatik modu yenilemek için `time` argümanını sunar.

- Uses `night_screen.frag` as the shader file.  
  Shader dosyası olarak `night_screen.frag` dosyasını kullanır.


# Fast Installation  

sudo pacman -Syu git  
git clone https://github.com/FURK4NGG/hyprshade.git  
cd hyprshade  
chmod +x install.sh  
./install.sh  

## 🔒 License  
<h1 align="center">📜 GPL-3.0 License</h1>
