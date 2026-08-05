#!/usr/bin/env python3

from __future__ import annotations

import os
import re
import shutil
import stat
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlparse

from gi.repository import GObject, Nautilus


APPIMAGE_DIR = Path.home() / ".local" / "opt" / "appimages"
APPLICATIONS_DIR = Path.home() / ".local" / "share" / "applications"
ICON_DIR = Path.home() / ".local" / "share" / "icons" / "appimages"


class AppImageInstallerExtension(GObject.GObject, Nautilus.MenuProvider):
    """Nautilus context-menu extension for installing AppImages."""

    def get_file_items(self, files):
        if len(files) != 1:
            return []

        file_info = files[0]

        if file_info.is_directory():
            return []

        path = self._get_local_path(file_info)
        if path is None or not self._is_appimage(path):
            return []

        item = Nautilus.MenuItem(
            name="AppImageInstaller::install",
            label="Install AppImage",
            tip="Install this AppImage and create an application launcher",
        )

        item.connect("activate", self._install_appimage, path)

        return [item]

    @staticmethod
    def _get_local_path(file_info) -> Path | None:
        uri = file_info.get_uri()
        parsed = urlparse(uri)

        if parsed.scheme != "file":
            return None

        return Path(unquote(parsed.path))

    @staticmethod
    def _is_appimage(path: Path) -> bool:
        """
        Detect whether a file appears to be an AppImage.

        Checks:
        1. .AppImage filename
        2. ELF magic
        3. AppImage magic bytes where available
        """

        if not path.is_file():
            return False

        # Filename is the cheapest/common check.
        if path.name.lower().endswith(".appimage"):
            return True

        try:
            with path.open("rb") as handle:
                header = handle.read(16)
        except OSError:
            return False

        # AppImages are ELF executables.
        if not header.startswith(b"\x7fELF"):
            return False

        # AppImage type 1/type 2 marker is normally found at bytes 8-10.
        if len(header) >= 11:
            marker = header[8:11]

            if marker in (b"AI\x01", b"AI\x02"):
                return True

        return False

    def _install_appimage(self, menu, source_path: Path):
        try:
            APPIMAGE_DIR.mkdir(parents=True, exist_ok=True)
            APPLICATIONS_DIR.mkdir(parents=True, exist_ok=True)
            ICON_DIR.mkdir(parents=True, exist_ok=True)

            app_name = self._clean_app_name(source_path.stem)

            destination = APPIMAGE_DIR / source_path.name

            shutil.copy2(source_path, destination)

            # Ensure executable bit.
            mode = destination.stat().st_mode
            destination.chmod(
                mode
                | stat.S_IXUSR
                | stat.S_IXGRP
                | stat.S_IXOTH
            )

            icon = self._extract_icon(destination, app_name)

            desktop_filename = (
                self._slugify(app_name) + ".desktop"
            )

            desktop_path = APPLICATIONS_DIR / desktop_filename

            self._create_desktop_file(
                desktop_path=desktop_path,
                app_name=app_name,
                executable=destination,
                icon=icon,
            )

            subprocess.run(
                ["update-desktop-database", str(APPLICATIONS_DIR)],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

            self._notify(
                "AppImage installed",
                f"{app_name} has been added to your applications.",
            )

        except Exception as exc:
            self._notify(
                "AppImage installation failed",
                str(exc),
            )

    @staticmethod
    def _clean_app_name(name: str) -> str:
        """
        Turn filenames such as:

            Obsidian-1.8.10-x86_64
            cursor-0.47.0-linux-x86_64

        into friendlier names.
        """

        name = re.sub(
            r"[-_.]?(x86_64|amd64|aarch64|arm64|linux)$",
            "",
            name,
            flags=re.IGNORECASE,
        )

        name = re.sub(
            r"[-_.]?\d+(?:\.\d+)+(?:[-_.].*)?$",
            "",
            name,
        )

        name = name.replace("_", " ").replace("-", " ")

        return name.strip().title()

    @staticmethod
    def _slugify(name: str) -> str:
        slug = name.lower()
        slug = re.sub(r"[^a-z0-9]+", "-", slug)
        return slug.strip("-") or "appimage"

    def _extract_icon(
        self,
        appimage: Path,
        app_name: str,
    ) -> Path | None:

        workdir = APPIMAGE_DIR / ".extract"

        if workdir.exists():
            shutil.rmtree(workdir, ignore_errors=True)

        workdir.mkdir(parents=True, exist_ok=True)

        try:
            result = subprocess.run(
                [
                    str(appimage),
                    "--appimage-extract",
                ],
                cwd=workdir,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=30,
            )

            if result.returncode != 0:
                return None

            root = workdir / "squashfs-root"

            if not root.exists():
                return None

            icon_candidates = []

            # Prefer common scalable/application icons.
            icon_candidates.extend(
                root.glob("*.png")
            )

            icon_candidates.extend(
                root.glob("*.svg")
            )

            icon_candidates.extend(
                root.glob("usr/share/icons/**/*.png")
            )

            icon_candidates.extend(
                root.glob("usr/share/icons/**/*.svg")
            )

            if not icon_candidates:
                return None

            # Prefer larger PNGs where possible.
            icon_candidates.sort(
                key=lambda p: p.stat().st_size,
                reverse=True,
            )

            source_icon = icon_candidates[0]

            extension = source_icon.suffix.lower() or ".png"

            destination = (
                ICON_DIR
                / f"{self._slugify(app_name)}{extension}"
            )

            shutil.copy2(source_icon, destination)

            return destination

        except (
            subprocess.TimeoutExpired,
            OSError,
        ):
            return None

        finally:
            shutil.rmtree(workdir, ignore_errors=True)

    @staticmethod
    def _create_desktop_file(
        desktop_path: Path,
        app_name: str,
        executable: Path,
        icon: Path | None,
    ):
        exec_value = str(executable).replace("\\", "\\\\")
        exec_value = exec_value.replace('"', '\\"')

        lines = [
            "[Desktop Entry]",
            "Type=Application",
            f"Name={app_name}",
            f'Exec="{exec_value}" %U',
            "Terminal=false",
            "Categories=Utility;",
            "StartupNotify=true",
        ]

        if icon is not None:
            lines.append(f"Icon={icon}")

        lines.extend(
            [
                "X-AppImage-Managed=true",
                "",
            ]
        )

        desktop_path.write_text(
            "\n".join(lines),
            encoding="utf-8",
        )

        desktop_path.chmod(0o755)

    @staticmethod
    def _notify(title: str, message: str):
        try:
            subprocess.run(
                ["notify-send", title, message],
                check=False,
            )
        except OSError:
            pass