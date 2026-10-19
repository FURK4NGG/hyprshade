#!/usr/bin/env python3

import os
import sys
import signal
import subprocess
from pathlib import Path

import gi
import cairo

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")

from gi.repository import Gtk, Gdk, GLib

BASE = Path.home() / ".config" / "scripts"
PID_FILE = BASE / "night-screen-overlay.pid"
OPACITY = 0.20


def start():
    BASE.mkdir(parents=True, exist_ok=True)

    if PID_FILE.exists():
        try:
            pid = int(PID_FILE.read_text().strip())
            os.kill(pid, 0)
            print("Night Screen overlay is already running.")
            return
        except (ValueError, OSError):
            PID_FILE.unlink(missing_ok=True)

    env = os.environ.copy()
    env.setdefault("DISPLAY", ":0")
    env.setdefault("XAUTHORITY", str(Path.home() / ".Xauthority"))

    subprocess.Popen(
        [sys.executable, str(Path(__file__).resolve()), "run"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
        env=env,
    )

    print("Night Screen overlay started.")


def stop():
    if PID_FILE.exists():
        try:
            pid = int(PID_FILE.read_text().strip())
            os.kill(pid, signal.SIGTERM)
        except (ValueError, OSError):
            pass

        PID_FILE.unlink(missing_ok=True)

    print("Night Screen overlay stopped.")


def run():
    BASE.mkdir(parents=True, exist_ok=True)

    screen = Gdk.Screen.get_default()
    if screen is None:
        raise SystemExit("Cannot access X11 screen.")

    visual = screen.get_rgba_visual()
    if visual is None:
        raise SystemExit("RGBA visual is unavailable.")

    # Wait until the X11 compositor is ready.
    def wait_for_compositor():
        screen = Gdk.Screen.get_default()

        if screen is not None and screen.is_composited():
            create_overlay()
            return GLib.SOURCE_REMOVE

        return GLib.timeout_add(500, wait_for_compositor)

    def create_overlay():
        build_overlay(screen, visual)

    def build_overlay(screen, visual):
        # The overlay window is created only after compositing is active.
        create_window(screen, visual)

    def create_window(screen, visual):
        pass

    window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
    window.set_title("Night Screen Overlay")
    window.set_visual(visual)
    window.set_app_paintable(True)
    window.set_decorated(False)
    window.set_resizable(False)
    window.set_accept_focus(False)
    window.set_focus_on_map(False)
    window.set_keep_above(True)
    window.set_skip_taskbar_hint(True)
    window.set_skip_pager_hint(True)
    window.stick()

    def draw(widget, cr):
        allocation = widget.get_allocation()
        cr.set_operator(cairo.OPERATOR_SOURCE)
        cr.set_source_rgba(1.0, 0.48, 0.12, OPACITY)
        cr.rectangle(0, 0, allocation.width, allocation.height)
        cr.fill()
        return True

    window.connect("draw", draw)

    def click_through(widget, *args):
        gdk_window = widget.get_window()
        if gdk_window is not None:
            region = cairo.Region()
            gdk_window.input_shape_combine_region(region, 0, 0)

    window.connect("realize", click_through)
    window.connect("map-event", click_through)

    def cleanup(*args):
        try:
            PID_FILE.unlink(missing_ok=True)
        except OSError:
            pass

        Gtk.main_quit()
        return GLib.SOURCE_REMOVE

    window.connect("destroy", cleanup)

    GLib.unix_signal_add(
        GLib.PRIORITY_DEFAULT, signal.SIGTERM, cleanup
    )
    GLib.unix_signal_add(
        GLib.PRIORITY_DEFAULT, signal.SIGINT, cleanup
    )

    window.show_all()

    # Use the complete screen geometry and fullscreen the overlay.
    window.set_resizable(True)
    window.set_default_size(screen.get_width(), screen.get_height())
    window.fullscreen_on_monitor(screen, 0)
    window.show()
    window.present()

    # Reapply fullscreen after the window is mapped.
    def enforce_fullscreen():
        window.fullscreen()
        window.queue_draw()
        return GLib.SOURCE_REMOVE

    GLib.timeout_add(1000, enforce_fullscreen)

    PID_FILE.write_text(str(os.getpid()))
    Gtk.main()

    try:
        PID_FILE.unlink(missing_ok=True)
    except OSError:
        pass


if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else "start"

    if command == "start":
        start()
    elif command == "stop":
        stop()
    elif command == "run":
        run()
    else:
        raise SystemExit(
            "Usage: night-screen-overlay.py [start|stop|run]"
        )
