#!/usr/bin/env bash
# coolify-inventory.sh — REMOTE SERVER banner + YAML inventory of Coolify compose stacks.
# Usage: coolify-inventory.sh [output.yaml]   (or COOLIFY_INVENTORY_OUT=...; COOLIFY_ROOT=/data/coolify)
set -euo pipefail
OUT="${1:-${COOLIFY_INVENTORY_OUT:-$HOME/coolify-inventory.yaml}}"
ROOT="${COOLIFY_ROOT:-/data/coolify}"

banner() {
  printf '\033]0;REMOTE SERVER — %s\007' "$(hostname)"   # window title
  if [ -t 1 ]; then printf '\033[2J\033[H'; fi
  if command -v figlet >/dev/null 2>&1; then
    printf '\033[1;36m'; figlet -w 120 "REMOTE SERVER"; printf '\033[0m'
  else
    local l="████████████████████████████████████████████"
    printf '\033[1;36m%s\n██                                        ██\n██      R E M O T E   S E R V E R         ██\n██                                        ██\n%s\033[0m\n' "$l" "$l"
  fi
  printf '\033[1;33m  host: %s   user: %s\033[0m\n\n' "$(hostname)" "$(whoami)"
}
banner

for d in "$ROOT/services" "$ROOT/applications"; do
  [ -d "$d" ] || { echo "(missing: $d)"; continue; }
  if command -v tree >/dev/null 2>&1; then tree -L 2 "$d"; else find "$d" -maxdepth 2 | sort; fi
done

command -v python3 >/dev/null || { echo "python3 required" >&2; exit 1; }
python3 - "$ROOT" "$OUT" <<'PY'
import sys, os, re, glob, json, datetime, socket
root, out = sys.argv[1], sys.argv[2]
try:
    import yaml
except ImportError:
    yaml = None

def parse(path):
    if yaml:
        try:
            doc = yaml.safe_load(open(path)) or {}
            svcs = doc.get("services") or {}
            return [{"name": n, "image": (s or {}).get("image"), "container_name": (s or {}).get("container_name")} for n, s in svcs.items()]
        except Exception as e:
            return [{"error": str(e)}]
    # fallback: indentation-based scan
    res, ins, cur, ind = [], False, None, None
    for line in open(path, errors="replace"):
        if re.match(r"^services:\s*$", line): ins = True; continue
        if ins and re.match(r"^\S", line): ins = False
        if not ins: continue
        m = re.match(r"^( +)([A-Za-z0-9_.-]+):\s*$", line)
        if m and (ind is None or len(m.group(1)) == ind):
            ind = len(m.group(1)); cur = {"name": m.group(2), "image": None, "container_name": None}; res.append(cur); continue
        m = re.match(r"^\s+(image|container_name):\s*['\"]?([^'\"\s]+)", line)
        if m and cur and cur[m.group(1)] is None: cur[m.group(1)] = m.group(2)
    return res

inv = {"host": socket.gethostname(), "generated": datetime.datetime.now().isoformat(timespec="seconds"), "roots": {}}
for kind in ("services", "applications"):
    base = os.path.join(root, kind); stacks = []
    if os.path.isdir(base):
        for d in sorted(os.listdir(base)):
            p = os.path.join(base, d)
            if not os.path.isdir(p): continue
            files = sorted(glob.glob(os.path.join(p, "**", "docker-compose.y*ml"), recursive=True))
            stacks.append({"id": d, "path": p, "compose_files": [{"file": f, "services": parse(f)} for f in files]})
    inv["roots"][kind] = {"path": base, "exists": os.path.isdir(base), "stacks": stacks}

with open(out, "w") as fh:
    if yaml: yaml.safe_dump(inv, fh, sort_keys=False, default_flow_style=False)
    else:
        def dump(o, i=0):
            sp = "  " * i
            if isinstance(o, dict):
                for k, v in o.items():
                    if isinstance(v, (dict, list)) and v: fh.write(f"{sp}{k}:\n"); dump(v, i + 1)
                    else: fh.write(f"{sp}{k}: {json.dumps(v) if v not in ({}, []) else json.dumps(v)}\n")
            else:
                for v in o:
                    if isinstance(v, dict) and v:
                        ks = list(v.items()); k0, v0 = ks[0]
                        if isinstance(v0, (dict, list)) and v0: fh.write(f"{sp}- {k0}:\n"); dump(v0, i + 2)
                        else: fh.write(f"{sp}- {k0}: {json.dumps(v0)}\n")
                        dump(dict(ks[1:]), i + 1)
                    else: fh.write(f"{sp}- {json.dumps(v)}\n")
        dump(inv)
n = sum(len(cf["services"]) for r in inv["roots"].values() for s in r["stacks"] for cf in s["compose_files"])
print(f"\nWrote {out} ({n} compose services)")
PY
