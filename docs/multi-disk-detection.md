# Multi-Disk Steam Game Detection

OptiScaler Universal scans all your Steam libraries—internal SSDs, HDDs, NVMe enclosures, even Steam Deck microSD—so games are detected and configured automatically.

## How It Works

1) **Library discovery**  
   - Parses every `libraryfolders.vdf` it can find in `~/.steam/steam/steamapps/`, `~/.local/share/Steam/steamapps/`, and any `steamapps` under `/mnt`, `/media`, `/run/media/$USER`.  
   - Extracts each `"path"` entry, normalizes to `<library>/steamapps`.

2) **Manifest parsing (primary / 100% reliable)**  
   - Reads each `appmanifest_*.acf` in every library.  
   - Extracts `appid`, `name`, `installdir`, `StateFlags`; only `StateFlags == "4"` is treated as installed.  
   - AppID is mapped to the corresponding game profile (YAML in `config/games/`).

3) **Fallback methods** (run after manifests):
   - **Folder fuzzy match**: compares folder names under `steamapps/common/` against `folder_patterns` in the profile.  
   - **Executable probe**: searches known executables (`executables`) up to depth 4 and matches to a profile even if the folder was renamed.  
   - **AppID compatdata lookup**: checks `steamapps/compatdata/<appid>/pfx` to recover Proton installs where the manifest is missing.

4) **Validation**  
   - Confirms install path exists and required files (if any) are present.  
   - Locates the first existing DLL target dir from `dll_targets`.  
   - Checks Proton prefix (`compatdata/<appid>/pfx`) and writability of the install dir.

5) **Caching**  
   - Results are cached at `/tmp/optiscaler_scan_cache.json` for 5 minutes to speed up repeated scans; `--force-rescan` bypasses cache.

## Files We Parse

- `steamapps/libraryfolders.vdf` – library roots.  
- `steamapps/appmanifest_*.acf` – authoritative AppID + install dir + state flags.  
- `steamapps/compatdata/<appid>/pfx` – Proton prefix presence and path.

## Detection Methods (in order)

1. **AppManifest (primary)** — AppID → profile (exact).  
2. **Folder fuzzy** — `steamapps/common/<folder>` vs `folder_patterns`.  
3. **Executable probe** — presence of known binaries (`executables`).  
4. **AppID in compatdata** — Proton prefix when manifest is missing.

## Supported Layouts

- Default Linux Steam (`~/.steam/steam/steamapps`, `~/.local/share/Steam/steamapps`)  
- Extra libraries on `/mnt/*`, `/media/*`, `/run/media/$USER/*`  
- Steam Deck (`/home/deck/.local/share/Steam/steamapps`)  
- NTFS/Windows Steam libraries mounted in Linux  
- External USB/NVMe enclosures with Steam libraries

## CLI Usage Examples

```bash
# Quick scan (cached)
bash scripts/install.sh --scan-only

# Verbose (DEBUG) with cache
LOG_LEVEL=DEBUG bash scripts/install.sh --scan-only --verbose

# Force fresh scan across all disks
bash scripts/install.sh --scan-only --force-rescan

# List supported games (profiles)
bash scripts/install.sh --list-games
```

## Troubleshooting

- **No games found**: run with `--force-rescan --debug` to bypass cache and print library/manifest details. Ensure disks are mounted.  
- **Game on external drive not detected**: confirm the drive is mounted under `/mnt` or `/media`; re-run with `--force-rescan`.  
- **Permissions issue**: if `writable=false`, adjust ownership (`chown $USER:$USER <path>`) or mount with write access.  
- **Partial installs**: manifests with `StateFlags != 4` are ignored; finish the Steam install, then rescan.  
- **Renamed folders**: executable probe should catch it; otherwise add a new `folder_patterns` entry in the relevant `config/games/<id>.yaml`.

## Profile YAML Reference (excerpt)

```yaml
game_id: cyberpunk2077
name: "Cyberpunk 2077"
app_id: 1091500

detection:
  folder_patterns:
    - "Cyberpunk 2077"
    - "Cyberpunk2077"
  executables:
    - "bin/x64/Cyberpunk2077.exe"
  required_files: []
  dll_targets:
    - "bin/x64"
```

Add or adjust patterns/executables to improve detection for custom installs or mods.
