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

# Filter settings
OPACITY = 0.12

# Light orange
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

    BASE.mkdir(parents=True, exist_ok=True)
    PID_FILE.write_text(str(os.getpid()))

    screen = Gdk.Screen.get_default()

    if screen is None:
        print("ERROR: No graphical display available.")
        return 1

    session_type = os.environ.get("XDG_SESSION_TYPE", "").lower()
    is_wayland = (
        session_type == "wayland"
        or bool(os.environ.get("WAYLAND_DISPLAY"))
    )

    # Check the compositor on X11
    if not is_wayland and not screen.is_composited():
        print("Starting X11 compositor...")

        subprocess.run(
            ["pkill", "-x", "xcompmgr"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        time.sleep(1)

        with open(LOG_FILE, "a", encoding="utf-8") as log:
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

    started = time.monotonic()
    window = None

    # Fullscreen drawing
    def draw_overlay(widget, cr):
        allocation = widget.get_allocation()

        cr.set_operator(cairo.OPERATOR_SOURCE)
        cr.set_source_rgba(RED, GREEN, BLUE, OPACITY)

        # Cover the entire drawing area without leaving gaps at the edges.
        cr.rectangle(
            0,
            0,
            allocation.width,
            allocation.height
        )
        cr.fill()

        return False

    def enforce_fullscreen():
        if window is None:
            return False

        # Reapply fullscreen mode.
        window.fullscreen()

        gdk_window = window.get_window()
        if gdk_window is not None:
            gdk_window.raise_()

        return False

    def create_overlay():
        nonlocal window

        current_screen = Gdk.Screen.get_default()

        if current_screen is None:
            return False

        if not is_wayland and not current_screen.is_composited():
            if time.monotonic() - started >= 20:
                print("ERROR: X11 compositor did not become ready.")
                Gtk.main_quit()
                return False

            return True

        # Get the screen dimensions.
        monitor = current_screen.get_primary_monitor()

        if monitor < 0:
            monitor = 0

        geometry = current_screen.get_monitor_geometry(monitor)
        screen_width = geometry.width
        screen_height = geometry.height

        window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)

        window.set_title("Night Screen Overlay")
        window.set_decorated(False)
        window.set_resizable(False)
        window.set_keep_above(True)
        window.set_accept_focus(False)
        window.set_focus_on_map(False)
        window.set_app_paintable(True)

        # Create the window using the screen dimensions
        # to prevent size and edge issues.
        window.set_default_size(screen_width, screen_height)
        window.set_size_request(screen_width, screen_height)
        window.set_position(Gtk.WindowPosition.NONE)

        visual = current_screen.get_rgba_visual()

        if visual is not None:
            window.set_visual(visual)

        window.connect("draw", draw_overlay)

        # Position the window at the top-left corner of the screen.
        window.move(geometry.x, geometry.y)

        # Show the window first, then apply fullscreen mode.
        window.show_all()
        window.fullscreen()

        # Reapply fullscreen mode in case the window manager resizes the window.
        GLib.timeout_add(500, enforce_fullscreen)

        print(
            f"Overlay active: {screen_width}x{screen_height}, "
            f"opacity={OPACITY}"
        )

        return False

    GLib.timeout_add(250, create_overlay)

    try:
        Gtk.main()
    finally:
        try:
            if PID_FILE.exists():
                current_pid = int(PID_FILE.read_text().strip())

                if current_pid == os.getpid():
                    PID_FILE.unlink(missing_ok=True)
        except (ValueError, OSError):
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
        print("Usage: night-screen-overlay.py [start|stop|run]")
        sys.exit(1)
PYTHON

chmod +x ~/.local/bin/night-screen-overlay.py
