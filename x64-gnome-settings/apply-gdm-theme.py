#!/usr/bin/env python3
import os
import sys
import glob
import shutil
import subprocess
import tempfile
from PIL import Image

STOCK_RESOURCE = "/usr/share/gnome-shell/gnome-shell-theme.gresource"
BACKUP_RESOURCE = "/usr/share/gnome-shell/gnome-shell-theme.gresource.stock"
WALLPAPER = "/usr/share/backgrounds/x64-lios/gdm-stealth-chassis.jpg"
STATE_FILE = "/var/lib/x64-lios/gdm-theme.state"

def get_connected_modes():
    """Detect all connected display modes from sysfs DRM."""
    modes = []
    for path in sorted(glob.glob('/sys/class/drm/*/status')):
        try:
            status = open(path).read().strip()
            if status == 'connected':
                modes_path = os.path.join(os.path.dirname(path), 'modes')
                if os.path.exists(modes_path):
                    lines = open(modes_path).read().splitlines()
                    if lines:
                        w, h = map(int, lines[0].split('x'))
                        modes.append((w, h))
        except Exception:
            pass
    return modes

def sync_monitors_xml():
    """Sync user's monitors.xml to GDM locations if available."""
    candidates = [
        os.path.expanduser("~qqqq/.config/monitors.xml"),
        os.path.expanduser("~/.config/monitors.xml"),
        "/etc/xdg/monitors.xml"
    ]
    src = None
    for c in candidates:
        if os.path.exists(c) and os.path.getsize(c) > 0:
            src = c
            break

    if src:
        destinations = [
            "/etc/xdg/monitors.xml",
            "/var/lib/gdm/.config/monitors.xml",
            "/var/lib/gdm/seat0/config/monitors.xml"
        ]
        for dst in destinations:
            try:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                if not os.path.exists(dst) or open(src, 'rb').read() != open(dst, 'rb').read():
                    shutil.copy2(src, dst)
                    os.chmod(dst, 0o644)
            except Exception:
                pass

def main():
    if not os.path.exists(STOCK_RESOURCE):
        return

    sync_monitors_xml()

    # Preserve stock theme backup if missing
    if not os.path.exists(BACKUP_RESOURCE):
        try:
            shutil.copy2(STOCK_RESOURCE, BACKUP_RESOURCE)
        except Exception as e:
            print(f"[X64 LIOS] Warning creating backup: {e}")

    source_res = BACKUP_RESOURCE if os.path.exists(BACKUP_RESOURCE) else STOCK_RESOURCE

    modes = get_connected_modes()
    state_sig = f"modes:{modes}:{os.path.getmtime(WALLPAPER) if os.path.exists(WALLPAPER) else 0}"

    force = "--force" in sys.argv
    if not force and os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f:
                if f.read().strip() == state_sig:
                    # Theme is already up to date with current displays
                    return
        except Exception:
            pass

    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            # 1. Extract all resources from source theme
            res_list = subprocess.check_output(["gresource", "list", source_res]).decode().splitlines()
            files = []
            for res in res_list:
                fname = os.path.basename(res)
                out_path = os.path.join(tmpdir, fname)
                with open(out_path, "wb") as f:
                    subprocess.run(["gresource", "extract", source_res, res], stdout=f, check=True)
                files.append(fname)

            # 2. Prepare optimized wallpaper canvas
            target_bg = os.path.join(tmpdir, "background")
            if os.path.exists(WALLPAPER):
                try:
                    base_img = Image.open(WALLPAPER)
                    if len(modes) >= 2:
                        # Multi-monitor stitched canvas
                        total_width = sum(m[0] for m in modes)
                        max_height = max(m[1] for m in modes)
                        canvas = Image.new("RGB", (total_width, max_height), (11, 12, 16))
                        cur_x = 0
                        for m_w, m_h in modes:
                            chassis_fit = base_img.resize((m_w, m_h), Image.Resampling.LANCZOS)
                            canvas.paste(chassis_fit, (cur_x, 0))
                            cur_x += m_w
                        canvas.save(target_bg, format="JPEG", quality=95)
                    elif len(modes) == 1:
                        # Single monitor native resolution
                        m_w, m_h = modes[0]
                        chassis_fit = base_img.resize((m_w, m_h), Image.Resampling.LANCZOS)
                        chassis_fit.save(target_bg, format="JPEG", quality=95)
                    else:
                        # Fallback copy
                        shutil.copy2(WALLPAPER, target_bg)
                except Exception as e:
                    print(f"[X64 LIOS] Image stitching exception, fallback to direct copy: {e}")
                    shutil.copy2(WALLPAPER, target_bg)

                if "background" not in files:
                    files.append("background")

            # 3. Custom CSS injection for GDM background and 160px logo
            custom_css = """
/* X64 LIOS GDM & Lock Screen Custom Styling */
#lockDialogGroup {
  background-color: #0b0c10;
  background-image: url('resource:///org/gnome/shell/theme/background');
  background-position: center;
  background-size: cover;
  background-repeat: no-repeat;
}

.login-dialog-logo-bin {
  margin: 1.5em 0;
}

.login-dialog-logo {
  max-width: 160px;
  max-height: 160px;
}
"""
            for css in ["gnome-shell-dark.css", "gnome-shell-light.css", "gnome-shell-high-contrast.css", "gnome-shell.css"]:
                p = os.path.join(tmpdir, css)
                if os.path.exists(p):
                    with open(p, "a") as f:
                        f.write(custom_css)

            # 4. XML manifest
            xml_path = os.path.join(tmpdir, "theme.gresource.xml")
            with open(xml_path, "w") as f:
                f.write('<?xml version="1.0" encoding="UTF-8"?>\n<gresources>\n  <gresource prefix="/org/gnome/shell/theme">\n')
                for fl in sorted(set(files)):
                    f.write(f'    <file>{fl}</file>\n')
                f.write('  </gresource>\n</gresources>\n')

            # 5. Compile directly to destination
            tmp_out = os.path.join(tmpdir, "gnome-shell-theme.gresource")
            subprocess.run(["glib-compile-resources", "--sourcedir", tmpdir, "--target", tmp_out, xml_path], check=True)
            shutil.copy2(tmp_out, STOCK_RESOURCE)
            os.chmod(STOCK_RESOURCE, 0o644)

            # Save state
            try:
                os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
                with open(STATE_FILE, "w") as f:
                    f.write(state_sig)
            except Exception:
                pass

            print("[X64 LIOS] GDM & Lock Screen theme successfully applied.")
    except Exception as e:
        print(f"[X64 LIOS] Error applying GDM theme: {e}")

if __name__ == "__main__":
    main()
