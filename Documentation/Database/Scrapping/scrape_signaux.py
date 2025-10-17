#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Scraper des panneaux de signalisation depuis Wikibooks (FR).

Sources:
- Code de la route / Liste des panneaux
- Code de la route / Signalisation dynamique

Le script crée une base SQLite (panneaux.db) et télécharge les images.

Champs stockés:
- id (PK)
- name (nom du panneau)
- description (texte court si disponible)
- category (ex: Panneaux de danger, Panneaux d'interdiction, etc.)
- subcategory (ex: Panneaux de priorité, Limitation de vitesse, etc.)
- type ("liste_des_panneaux" ou "signalisation_dynamique")
- source_url (URL de la page d'origine)
- image_url (URL absolue de l'image)
- image_path (chemin local de l'image téléchargée)

Usage:
    python scrape_signaux.py

Dépendances (voir requirements.txt):
    requests, beautifulsoup4, tqdm
"""

import os
import re
import sqlite3
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple
import csv

import requests
from bs4 import BeautifulSoup, Tag
from tqdm import tqdm


BASE_DIR = Path(__file__).resolve().parent
# Si vous souhaitez aussi un fichier SQLite, mettez SAVE_SQLITE_FILE=True
SAVE_SQLITE_FILE = False
DB_PATH = BASE_DIR / "panneaux.db"
IMAGES_DIR = BASE_DIR / "images"

SOURCES = [
    {
        "url": "https://fr.wikibooks.org/wiki/Code_de_la_route/Liste_des_panneaux",
        "type": "liste_des_panneaux",
    },
    {
        "url": "https://fr.wikibooks.org/wiki/Code_de_la_route/Signalisation_dynamique",
        "type": "signalisation_dynamique",
    },
]

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0 Safari/537.36"
    )
}


@dataclass
class Entry:
    name: str
    description: Optional[str]
    type_: str
    source_url: str
    image_url: Optional[str]
    image_path: Optional[str]


def ensure_dirs() -> None:
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)


def connect_db(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(str(path) if SAVE_SQLITE_FILE else ":memory:")
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS PANNEAUX (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            type TEXT NOT NULL,
            source_url TEXT NOT NULL,
            image_url TEXT,
            image_path TEXT,
            UNIQUE(name, type) ON CONFLICT IGNORE
        );
        """
    )
    conn.execute("PRAGMA journal_mode=WAL;")
    return conn


def fetch_html(url: str) -> BeautifulSoup:
    resp = requests.get(url, headers=HEADERS, timeout=30)
    resp.raise_for_status()
    # Utiliser l'analyseur standard pour éviter la dépendance à lxml sur Windows
    return BeautifulSoup(resp.text, "html.parser")


def absolutize_url(url: str) -> str:
    if url.startswith("//"):
        return "https:" + url
    return url


def sanitize_filename(name: str) -> str:
    safe = re.sub(r"[^A-Za-z0-9_.\-]+", "_", name.strip())
    return safe[:200] if len(safe) > 200 else safe


def extract_category_from_header(tag: Tag) -> Optional[str]:
    text = tag.get_text(strip=True)
    return text or None


def iter_content_sections(mw_output: Tag) -> Iterable[Tuple[Optional[str], Optional[str], List[Tag]]]:
    """
    Itère sur les sections (h2/h3) et collecte les éléments jusqu'au prochain header.
    Retourne (category, subcategory, list_of_tags_in_section)
    """
    current_category: Optional[str] = None
    current_subcategory: Optional[str] = None
    buffer: List[Tag] = []

    for child in mw_output.children:
        if not isinstance(child, Tag):
            continue
        if child.name in ("h2", "h3"):
            if buffer:
                yield current_category, current_subcategory, buffer
                buffer = []
            if child.name == "h2":
                current_category = extract_category_from_header(child)
                current_subcategory = None
            else:
                current_subcategory = extract_category_from_header(child)
        else:
            buffer.append(child)

    if buffer:
        yield current_category, current_subcategory, buffer


def parse_list_items(section_nodes: List[Tag]) -> List[Tuple[str, Optional[str]]]:
    """
    Extrait des couples (name, description) à partir des <ul>/<ol>/<li>.
    """
    results: List[Tuple[str, Optional[str]]] = []
    for node in section_nodes:
        if node.name in ("ul", "ol"):
            # Récursif pour ne pas rater les sous-listes
            for li in node.find_all("li", recursive=True):
                text = li.get_text(" ", strip=True)
                if not text:
                    continue
                results.append((text, None))
    return results


def parse_gallery_and_thumbs(section_nodes: List[Tag]) -> List[Tuple[str, Optional[str], Optional[str]]]:
    """
    Extrait (name, description, image_url) depuis les galeries et vignettes.
    """
    out: List[Tuple[str, Optional[str], Optional[str]]] = []

    # Galleries
    for node in section_nodes:
        for gallery in node.find_all(class_=lambda c: c and "gallery" in c):
            for item in gallery.find_all("div", class_=lambda c: c and "gallerybox" in c):
                img = item.find("img")
                caption = item.find("div", class_=lambda c: c and "gallerytext" in c)
                name = None
                desc = None
                if caption:
                    cap_text = caption.get_text(" ", strip=True)
                    # Heuristique: première phrase = nom
                    # Sinon, tout en nom et desc=None
                    if "." in cap_text:
                        parts = cap_text.split(".", 1)
                        name = parts[0].strip()
                        desc = parts[1].strip() or None
                    else:
                        name = cap_text
                img_url = None
                if img and img.has_attr("src"):
                    img_url = absolutize_url(img["src"])  # miniatures wiki
                if name:
                    out.append((name, desc, img_url))

    # Thumbs (vignettes "thumb")
    for node in section_nodes:
        for thumb in node.find_all("div", class_=lambda c: c and "thumb" in c):
            img = thumb.find("img")
            caption = thumb.find("div", class_=lambda c: c and ("thumbcaption" in c or "thumbcaption") )
            name = None
            desc = None
            if caption:
                cap_text = caption.get_text(" ", strip=True)
                if "." in cap_text:
                    parts = cap_text.split(".", 1)
                    name = parts[0].strip()
                    desc = parts[1].strip() or None
                else:
                    name = cap_text
            img_url = None
            if img and img.has_attr("src"):
                img_url = absolutize_url(img["src"])  # miniatures wiki
            if name or img_url:
                out.append((name or "(Sans titre)", desc, img_url))

    return out


def parse_images_alt(section_nodes: List[Tag]) -> List[Tuple[str, Optional[str], Optional[str]]]:
    """
    Capture supplémentaire: récupère toute image présente avec son alt comme nom potentiel.
    Utile si la page n'utilise pas de galerie/thumbnail structurée.
    """
    out: List[Tuple[str, Optional[str], Optional[str]]] = []
    for node in section_nodes:
        for img in node.find_all("img"):
            img_url = img.get("src")
            if not img_url:
                continue
            name = img.get("alt") or None
            if name:
                out.append((name.strip(), None, absolutize_url(img_url)))
            else:
                out.append(("(Sans titre)", None, absolutize_url(img_url)))
    return out


def merge_entries(
    list_items: List[Tuple[str, Optional[str]]],
    gallery_items: List[Tuple[str, Optional[str], Optional[str]]],
    imgs_alt_items: List[Tuple[str, Optional[str], Optional[str]]],
) -> Dict[str, Dict[str, Optional[str]]]:
    """
    Fusionne les infos basées sur le nom (clé unique heuristique).
    Retourne dict name -> {description, image_url}
    """
    data: Dict[str, Dict[str, Optional[str]]] = {}
    for name, desc in list_items:
        data.setdefault(name, {})
        if desc:
            data[name]["description"] = desc
    for name, desc, img_url in gallery_items + imgs_alt_items:
        data.setdefault(name, {})
        if desc and not data[name].get("description"):
            data[name]["description"] = desc
        if img_url and not data[name].get("image_url"):
            data[name]["image_url"] = img_url
    return data


def best_image_url(thumbnail_url: str) -> str:
    """
    Convertit l'URL miniature en URL absolue (garde la miniature si taille inconnue).
    Sur Wikimedia, remplacer "/thumb/.../FILENAME/xxxpx-FILENAME" par "/.../FILENAME" donne l'original.
    """
    try:
        if "/thumb/" in thumbnail_url:
            parts = thumbnail_url.split("/thumb/")
            head = parts[0]
            tail = parts[1]
            # tail: path/to/file/FILENAME/xxxpx-FILENAME
            file_path, _, file_name = tail.rpartition("/")
            original = f"{head}/{file_path}"
            return original
    except Exception:
        pass
    return thumbnail_url


def download_image(url: str, dest_dir: Path) -> Optional[Path]:
    try:
        url = absolutize_url(url)
        original_url = best_image_url(url)
        filename = sanitize_filename(original_url.split("/")[-1] or "image")
        dest = dest_dir / filename
        if dest.exists():
            return dest
        with requests.get(original_url, headers=HEADERS, timeout=60, stream=True) as r:
            r.raise_for_status()
            with open(dest, "wb") as f:
                for chunk in r.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
        return dest
    except Exception:
        return None


def upsert_entry(conn: sqlite3.Connection, e: Entry) -> None:
    conn.execute(
        """
        INSERT OR IGNORE INTO PANNEAUX
            (name, description, type, source_url, image_url, image_path)
        VALUES
            (?, ?, ?, ?, ?, ?)
        """,
        (
            e.name,
            e.description,
            e.type_,
            e.source_url,
            e.image_url,
            e.image_path,
        ),
    )


def scrape_page(url: str, type_: str, conn: sqlite3.Connection) -> int:
    soup = fetch_html(url)
    mw_output = soup.find("div", class_="mw-parser-output")
    if not mw_output:
        return 0

    inserted = 0
    for category, subcategory, nodes in iter_content_sections(mw_output):
        list_items = parse_list_items(nodes)
        gallery_items = parse_gallery_and_thumbs(nodes)
        imgs_alt_items = parse_images_alt(nodes)
        merged = merge_entries(list_items, gallery_items, imgs_alt_items)

        for name, info in merged.items():
            desc = info.get("description")
            if not desc:
                base = (name or "Panneau").strip()
                type_label = (
                    "signalisation dynamique" if type_ == "signalisation_dynamique" else "liste des panneaux"
                )
                desc = f"{base} — panneau issu du Code de la route ({type_label})."
            img_url = info.get("image_url")
            img_path: Optional[str] = None
            if img_url:
                local = download_image(img_url, IMAGES_DIR)
                if local:
                    img_path = str(local.relative_to(BASE_DIR))
                    img_url = best_image_url(img_url)

            entry = Entry(
                name=name,
                description=desc,
                type_=type_,
                source_url=url,
                image_url=img_url,
                image_path=img_path,
            )
            upsert_entry(conn, entry)
            inserted += 1

    conn.commit()
    return inserted


def main() -> int:
    ensure_dirs()
    conn = connect_db(DB_PATH)
    total = 0
    for src in tqdm(SOURCES, desc="Scraping pages"):
        try:
            count = scrape_page(src["url"], src["type"], conn)
            total += count
        except Exception as exc:
            print(f"Erreur lors du scraping de {src['url']}: {exc}", file=sys.stderr)
    export_csv(conn, BASE_DIR / "panneaux.csv")
    export_sql(conn, BASE_DIR / "panneaux.sql")
    print(f"Terminé. {total} entrées considérées (doublons ignorés). DB: {DB_PATH}. Exports: panneaux.csv, panneaux.sql")
    return 0


def export_csv(conn: sqlite3.Connection, csv_path: Path) -> None:
    cols = [
        "id",
        "name",
        "description",
        "type",
        "source_url",
        "image_url",
        "image_path",
    ]
    cur = conn.execute(f"SELECT {', '.join(cols)} FROM PANNEAUX ORDER BY type, name")
    rows = cur.fetchall()
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(cols)
        for r in rows:
            writer.writerow(r)


def sql_escape(value: Optional[str]) -> str:
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def export_sql(conn: sqlite3.Connection, sql_path: Path) -> None:
    with open(sql_path, "w", encoding="utf-8") as f:
        f.write(
            """
-- Table d'export des PANNEAUX (compatible MySQL/phpMyAdmin)
DROP TABLE IF EXISTS `PANNEAUX`;
CREATE TABLE `PANNEAUX` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `type` VARCHAR(64) NOT NULL,
  `source_url` TEXT NOT NULL,
  `image_url` TEXT NULL,
  `image_path` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_name_type` (`name`, `type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
""".lstrip()
        )

        cur = conn.execute(
            "SELECT name, description, type, source_url, image_url, image_path FROM PANNEAUX ORDER BY type, name"
        )
        for (
            name,
            description,
            type_,
            source_url,
            image_url,
            image_path,
        ) in cur:
            f.write(
                "INSERT IGNORE INTO `PANNEAUX` (name, description, type, source_url, image_url, image_path) VALUES ("
                + ", ".join(
                    [
                        sql_escape(name),
                        sql_escape(description),
                        sql_escape(type_),
                        sql_escape(source_url),
                        sql_escape(image_url),
                        sql_escape(image_path),
                    ]
                )
                + ");\n"
            )



if __name__ == "__main__":
    raise SystemExit(main())

