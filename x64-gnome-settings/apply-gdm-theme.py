#!/usr/bin/env python3
import os
import shutil
import subprocess
import tempfile

STOCK_RESOURCE = "/usr/share/gnome-shell/gnome-shell-theme.gresource"
BACKUP_RESOURCE = "/usr/share/gnome-shell/gnome-shell-theme.gresource.stock"
WALLPAPER = "/usr/share/backgrounds/x64-lios/gdm-stealth-chassis.jpg"

def main():
    if not os.path.exists(STOCK_RESOURCE):
        # GNOME Shell theme resource not found, exit gracefully
        return

    # If backup doesn't exist, preserve original stock theme
    if not os.path.exists(BACKUP_RESOURCE):
        try:
            shutil.copy2(STOCK_RESOURCE, BACKUP_RESOURCE)
        except Exception as e:
            print(f"[X64 LIOS] Warning creating backup: {e}")

    source_res = BACKUP_RESOURCE if os.path.exists(BACKUP_RESOURCE) else STOCK_RESOURCE

    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            # 1. Extract all resources from source
            res_list = subprocess.check_output(["gresource", "list", source_res]).decode().splitlines()
            files = []
            for res in res_list:
                fname = os.path.basename(res)
                out_path = os.path.join(tmpdir, fname)
                with open(out_path, "wb") as f:
                    subprocess.run(["gresource", "extract", source_res, res], stdout=f, check=True)
                files.append(fname)

            # 2. Add wallpaper as resource
            if os.path.exists(WALLPAPER):
                shutil.copy2(WALLPAPER, os.path.join(tmpdir, "background"))
                if "background" not in files:
                    files.append("background")

            # 3. Custom CSS injection for GDM background and 160px logo
            custom_css = """
/* X64 LIOS GDM & Lock Screen Custom Styling */
#lockDialogGroup {
  background-color: #101214;
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
            print("[X64 LIOS] GDM & Lock Screen theme successfully applied.")
    except Exception as e:
        print(f"[X64 LIOS] Error applying GDM theme: {e}")

if __name__ == "__main__":
    main()
