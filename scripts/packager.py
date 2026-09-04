#!/usr/bin/env python3
import os
import zipfile
import tarfile
import shutil

dist_dir = "export/dist"
os.makedirs(dist_dir, exist_ok=True)

# 1. Package Web
if os.path.exists("export/web"):
    web_zip = os.path.join(dist_dir, "VoltArena-Web.zip")
    with zipfile.ZipFile(web_zip, "w", zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk("export/web"):
            for f in files:
                fp = os.path.join(root, f)
                arcname = os.path.relpath(fp, "export/web")
                z.write(fp, arcname)
    size_mb = os.path.getsize(web_zip) / (1024 * 1024)
    print(f"Packaged Web:     {web_zip} ({size_mb:.2f} MB)")

# 2. Package Linux
if os.path.exists("export/linux"):
    linux_tar = os.path.join(dist_dir, "VoltArena-Linux-x86_64.tar.gz")
    with tarfile.open(linux_tar, "w:gz") as t:
        for root, _, files in os.walk("export/linux"):
            for f in files:
                fp = os.path.join(root, f)
                arcname = os.path.relpath(fp, "export/linux")
                t.add(fp, arcname)
    size_mb = os.path.getsize(linux_tar) / (1024 * 1024)
    print(f"Packaged Linux:   {linux_tar} ({size_mb:.2f} MB)")

# 3. Package Windows
if os.path.exists("export/windows"):
    win_zip = os.path.join(dist_dir, "VoltArena-Windows-x86_64.zip")
    with zipfile.ZipFile(win_zip, "w", zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk("export/windows"):
            for f in files:
                fp = os.path.join(root, f)
                arcname = os.path.relpath(fp, "export/windows")
                z.write(fp, arcname)
    size_mb = os.path.getsize(win_zip) / (1024 * 1024)
    print(f"Packaged Windows: {win_zip} ({size_mb:.2f} MB)")

# 4. Package Android
if os.path.exists("export/android/VoltArena.apk"):
    apk_target = os.path.join(dist_dir, "VoltArena-Android.apk")
    shutil.copyfile("export/android/VoltArena.apk", apk_target)
    size_mb = os.path.getsize(apk_target) / (1024 * 1024)
    print(f"Packaged Android: {apk_target} ({size_mb:.2f} MB)")

print("All distribution packages created in export/dist/.")
