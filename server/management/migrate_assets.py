#!/usr/bin/env python3
"""
Asset Migration Script for UnaMentis Curricula

This script downloads all remote visual assets for UMLCF curricula and
updates the files with local paths. Run this once to populate the asset cache.

Usage:
    python migrate_assets.py                    # Migrate all curricula
    python migrate_assets.py renaissance        # Migrate specific curriculum
    python migrate_assets.py --dry-run          # Preview without downloading
"""

import asyncio
import json
import sys
import time
from pathlib import Path
from typing import Optional

try:
    import aiohttp
except ImportError:
    print("Installing aiohttp...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "aiohttp"])
    import aiohttp

# Configuration
PROJECT_ROOT = Path(__file__).parent.parent.parent
CURRICULUM_DIR = PROJECT_ROOT / "curriculum" / "examples" / "realistic"
ASSETS_DIR = PROJECT_ROOT / "curriculum" / "assets"
RATE_LIMIT_SECONDS = 1.0  # Wikimedia rate limit

# Rate limiter state
_last_download_time = 0.0


async def download_asset(
    session: aiohttp.ClientSession,
    url: str,
    curriculum_id: str,
    topic_id: str,
    asset_id: str,
    dry_run: bool = False
) -> Optional[str]:
    """Download a single asset with rate limiting."""
    global _last_download_time

    # Enforce rate limiting
    now = time.time()
    elapsed = now - _last_download_time
    if elapsed < RATE_LIMIT_SECONDS:
        await asyncio.sleep(RATE_LIMIT_SECONDS - elapsed)
    _last_download_time = time.time()

    # Determine file extension
    url_path = url.split("?")[0]
    ext = Path(url_path).suffix.lower()
    if not ext or ext not in [".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg"]:
        ext = ".jpg"

    # Create target path
    assets_dir = ASSETS_DIR / curriculum_id / topic_id
    local_path = assets_dir / f"{asset_id}{ext}"
    relative_path = str(local_path.relative_to(PROJECT_ROOT))

    # Check if already downloaded
    if local_path.exists():
        print(f"  [SKIP] {asset_id}: Already cached")
        return relative_path

    if dry_run:
        print(f"  [DRY] {asset_id}: Would download from {url[:60]}...")
        return relative_path

    try:
        headers = {
            "User-Agent": "UnaMentis/1.0 (Educational App; https://unamentis.com; support@unamentis.com)"
        }

        async with session.get(url, headers=headers, timeout=aiohttp.ClientTimeout(total=30)) as response:
            if response.status == 200:
                content = await response.read()

                # Create directory and save
                assets_dir.mkdir(parents=True, exist_ok=True)
                with open(local_path, "wb") as f:
                    f.write(content)

                size_kb = len(content) / 1024
                print(f"  [OK] {asset_id}: {size_kb:.1f}KB -> {relative_path}")
                return relative_path

            elif response.status == 429:
                print(f"  [RATE] {asset_id}: Rate limited, skipping")
                return None
            else:
                print(f"  [ERR] {asset_id}: HTTP {response.status}")
                return None

    except asyncio.TimeoutError:
        print(f"  [TIMEOUT] {asset_id}: Download timed out")
        return None
    except Exception as e:
        print(f"  [ERR] {asset_id}: {e}")
        return None


async def migrate_curriculum(file_path: Path, dry_run: bool = False) -> dict:
    """Migrate a single curriculum file."""
    print(f"\n{'='*60}")
    print(f"Processing: {file_path.name}")
    print(f"{'='*60}")

    with open(file_path, 'r', encoding='utf-8') as f:
        umlcf = json.load(f)

    curriculum_id = umlcf.get("id", {}).get("value", file_path.stem)
    content = umlcf.get("content", [])

    if not content:
        print("  No content found")
        return {"downloaded": 0, "failed": 0, "skipped": 0}

    root = content[0]
    children = root.get("children", [])

    stats = {"downloaded": 0, "failed": 0, "skipped": 0, "updated": False}

    async with aiohttp.ClientSession() as session:
        for topic in children:
            topic_id = topic.get("id", {}).get("value", "")
            topic_title = topic.get("title", "Unknown")

            if not topic_id:
                continue

            media = topic.get("media", {})

            # Count assets in this topic
            embedded_count = len(media.get("embedded", []))
            reference_count = len(media.get("reference", []))

            if embedded_count + reference_count == 0:
                continue

            print(f"\n  Topic: {topic_title}")
            print(f"    ({embedded_count} embedded, {reference_count} reference)")

            for asset_list_key in ["embedded", "reference"]:
                assets = media.get(asset_list_key, [])

                for asset in assets:
                    asset_id = asset.get("id", "")
                    url = asset.get("url", "")
                    existing_local = asset.get("localPath", "")

                    if not url:
                        continue

                    if existing_local:
                        # Check if file actually exists
                        full_path = PROJECT_ROOT / existing_local
                        if full_path.exists():
                            stats["skipped"] += 1
                            continue
                        else:
                            print(f"    [MISSING] {asset_id}: Local path set but file missing")

                    result = await download_asset(
                        session=session,
                        url=url,
                        curriculum_id=curriculum_id,
                        topic_id=topic_id,
                        asset_id=asset_id,
                        dry_run=dry_run
                    )

                    if result:
                        if not dry_run:
                            asset["localPath"] = result
                            stats["updated"] = True
                        stats["downloaded"] += 1
                    else:
                        stats["failed"] += 1

    # Save updated file
    if stats["updated"] and not dry_run:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(umlcf, f, indent=2, ensure_ascii=False)
        print(f"\n  [SAVED] Updated {file_path.name}")

    return stats


async def main():
    """Main entry point."""
    args = sys.argv[1:]

    dry_run = "--dry-run" in args
    if dry_run:
        args.remove("--dry-run")
        print("DRY RUN MODE - No files will be downloaded or modified\n")

    # Find curriculum files to process
    if args:
        # Specific curriculum(s) requested
        files = []
        for name in args:
            # Try exact match first
            path = CURRICULUM_DIR / f"{name}.umlcf"
            if path.exists():
                files.append(path)
            else:
                # Try partial match
                matches = list(CURRICULUM_DIR.glob(f"*{name}*.umlcf"))
                files.extend(matches)

        if not files:
            print(f"No curriculum files found matching: {args}")
            sys.exit(1)
    else:
        # All curricula
        files = list(CURRICULUM_DIR.glob("*.umlcf"))

    if not files:
        print(f"No .umlcf files found in {CURRICULUM_DIR}")
        sys.exit(1)

    print(f"Found {len(files)} curriculum file(s) to process")

    total_stats = {"downloaded": 0, "failed": 0, "skipped": 0}

    for file_path in sorted(files):
        stats = await migrate_curriculum(file_path, dry_run=dry_run)
        total_stats["downloaded"] += stats["downloaded"]
        total_stats["failed"] += stats["failed"]
        total_stats["skipped"] += stats["skipped"]

    print(f"\n{'='*60}")
    print("MIGRATION COMPLETE")
    print(f"{'='*60}")
    print(f"  Downloaded: {total_stats['downloaded']}")
    print(f"  Failed:     {total_stats['failed']}")
    print(f"  Skipped:    {total_stats['skipped']}")

    if dry_run:
        print("\n  (Dry run - no changes made)")


if __name__ == "__main__":
    asyncio.run(main())
