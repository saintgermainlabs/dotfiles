#!/usr/bin/env bash
# coolify-inventory.sh — YAML inventory of Coolify compose stacks.
# Usage: coolify-inventory.sh [raw|paths] [output.yaml]   (also --mode=raw|paths)
#   raw   (default) full inventory -> ~/data/inv/coolify-inventory.yaml
#   paths stack dirs, compose files, volumes/bind mounts, working_dir, build context -> ~/data/inv/coolify-paths.yaml
#   COOLIFY_INVENTORY_OUT=... overrides output; COOLIFY_ROOT=/data/coolify
set -euo pipefail
MODE=raw
case "${1:-}" in
  raw|paths) MODE="$1"; shift ;;
  --mode=*) MODE="${1#--mode=}"; shift ;;
  --mode) MODE="${2:?}"; shift 2 ;;
  -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
esac
case "$MODE" in raw|paths) ;; *) echo "unknown mode: $MODE (raw|paths)" >&2; exit 2 ;; esac
if [ "$MODE" = paths ]; then DEF="$HOME/data/inv/coolify-paths.yaml"; else DEF="$HOME/data/inv/coolify-inventory.yaml"; fi
OUT="${1:-${COOLIFY_INVENTORY_OUT:-$DEF}}"
mkdir -p "$(dirname "$OUT")"
ROOT="${COOLIFY_ROOT:-/data/coolify}"


[ "$MODE" = raw ] && for d in "$ROOT/services" "$ROOT/applications"; do
  [ -d "$d" ] || { echo "(missing: $d)"; continue; }
  if command -v tree >/dev/null 2>&1; then tree -L 2 "$d"; else find "$d" -maxdepth 2 | sort; fi
done

command -v python3 >/dev/null || { echo "python3 required" >&2; exit 1; }
python3 - "$ROOT" "$OUT" "$MODE" <<'PY'
import sys, os, re, glob, json, datetime, socket
root, out, mode = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    import yaml
except ImportError:
    yaml = None

def kv_list(v, keys_only=False):
    """compose list-or-map -> dict (values dropped when keys_only)."""
    d = {}
    if isinstance(v, dict):
        for k, x in v.items(): d[str(k)] = None if keys_only else (None if x is None else str(x))
    elif isinstance(v, list):
        for x in v:
            k, _, val = str(x).partition("=")
            d[k.strip()] = None if keys_only else val
    return d

def names(v):
    if isinstance(v, dict): return [str(k) for k in v]
    if isinstance(v, list): return [str(x) if not isinstance(x, dict) else next(iter(x), "") for x in v]
    return []

def ports(v):
    out = []
    for x in v or []:
        if isinstance(x, dict):
            pub, tgt, proto = x.get("published"), x.get("target"), x.get("protocol")
            out.append(f"{pub}:{tgt}" if pub else str(tgt) + (f"/{proto}" if proto and proto != "tcp" else ""))
        else: out.append(str(x))
    return out

def entry(n, s):
    s = s or {}
    e = {"name": n, "image": s.get("image"), "container_name": s.get("container_name")}
    labels = kv_list(s.get("labels"))
    for k in ("app.name", "app.component"):
        if labels.get(k): e[k] = labels[k]
    if s.get("hostname"): e["hostname"] = s["hostname"]
    if s.get("profiles"): e["profiles"] = list(s["profiles"])
    if names(s.get("networks")): e["networks"] = names(s.get("networks"))
    if ports(s.get("ports")): e["ports"] = ports(s.get("ports"))
    env = list(kv_list(s.get("environment"), keys_only=True))
    if env: e["environment_keys"] = env
    if names(s.get("depends_on")): e["depends_on"] = names(s.get("depends_on"))
    if labels: e["labels"] = labels
    return e

def absp(p, base):
    p = str(p)
    if p.startswith("~"): return os.path.expanduser(p)
    return p if p.startswith("/") or "$" in p else os.path.normpath(os.path.join(base, p))

def vol_entries(v, base, named):
    res = []
    for x in v or []:
        if isinstance(x, dict):
            src, tgt, typ = x.get("source"), x.get("target"), x.get("type")
            ro = bool(x.get("read_only"))
        else:
            parts = str(x).split(":")
            if len(parts) == 1: src, tgt = None, parts[0]
            else: src, tgt = parts[0], parts[1]
            ro = len(parts) > 2 and "ro" in parts[2].split(",")
            typ = None
        if typ is None:
            typ = "anonymous" if not src else ("bind" if re.match(r"^[./~$]", str(src)) else "volume")
        e = {"type": typ, "target": tgt}
        if typ == "bind": e["host_path"] = absp(src, base)
        elif typ == "volume" and src:
            e["volume"] = str(src)
            nv = named.get(str(src)) or {}
            if nv.get("name"): e["docker_volume_name"] = nv["name"]
            dev = (nv.get("driver_opts") or {}).get("device")
            if dev: e["host_path"] = absp(dev, base)
        elif src: e["source"] = str(src)
        if ro: e["read_only"] = True
        res.append(e)
    return res

def entry_paths(n, s, base, named):
    s = s or {}
    e = {"name": n}
    labels = kv_list(s.get("labels"))
    for k in ("app.name", "app.component"):
        if labels.get(k): e[k] = labels[k]
    if s.get("container_name"): e["container_name"] = s["container_name"]
    if s.get("image"): e["image"] = s["image"]
    if s.get("working_dir"): e["working_dir"] = s["working_dir"]
    b = s.get("build")
    if b:
        ctx = b if isinstance(b, str) else (b.get("context") or ".")
        e["build_context"] = absp(ctx, base)
        if isinstance(b, dict) and b.get("dockerfile"): e["dockerfile"] = b["dockerfile"]
    for k in ("env_file",):
        if s.get(k):
            v = s[k] if isinstance(s[k], list) else [s[k]]
            e[k] = [absp(x if isinstance(x, str) else x.get("path"), base) for x in v]
    vols = vol_entries(s.get("volumes"), base, named)
    if vols: e["volumes"] = vols
    return e

def parse(path):
    if yaml and mode == "paths":
        try:
            doc = yaml.safe_load(open(path)) or {}
            named = {str(k): (v or {}) for k, v in (doc.get("volumes") or {}).items()}
            base = os.path.dirname(path)
            return [entry_paths(n, s, base, named) for n, s in (doc.get("services") or {}).items()]
        except Exception as e:
            return [{"error": str(e)}]
    if yaml:
        try:
            doc = yaml.safe_load(open(path)) or {}
            return [entry(n, s) for n, s in (doc.get("services") or {}).items()]
        except Exception as e:
            return [{"error": str(e)}]
    # fallback: indentation-based scan (name/image/container_name/app labels only)
    res, ins, cur, ind = [], False, None, None
    for line in open(path, errors="replace"):
        if re.match(r"^services:\s*$", line): ins = True; continue
        if ins and re.match(r"^\S", line): ins = False
        if not ins: continue
        m = re.match(r"^( +)([A-Za-z0-9_.-]+):\s*$", line)
        if m and (ind is None or len(m.group(1)) == ind):
            ind = len(m.group(1)); cur = {"name": m.group(2), "image": None, "container_name": None}; res.append(cur); continue
        m = re.match(r"^\s+(image|container_name|hostname):\s*['\"]?([^'\"\s]+)", line)
        if m and cur and cur.get(m.group(1)) is None: cur[m.group(1)] = m.group(2)
        m = re.match(r"^\s+-?\s*['\"]?(app\.name|app\.component)\s*[:=]\s*['\"]?([^'\"\n]+?)['\"]?\s*$", line)
        if m and cur: cur[m.group(1)] = m.group(2)
    return res

def docker_enrich(inv):
    """Optional: fill app.name/app.component from running containers when compose lacks them."""
    import subprocess
    try:
        ids = subprocess.run(["docker", "ps", "-q"], capture_output=True, text=True, timeout=15).stdout.split()
        if not ids: return
        data = json.loads(subprocess.run(["docker", "inspect", *ids], capture_output=True, text=True, timeout=30).stdout or "[]")
    except Exception:
        return
    by_name, by_proj = {}, {}
    for c in data:
        lb = (c.get("Config") or {}).get("Labels") or {}
        by_name[c.get("Name", "").lstrip("/")] = lb
        p, sv = lb.get("com.docker.compose.project"), lb.get("com.docker.compose.service")
        if p and sv: by_proj[(p, sv)] = lb
    for r in inv["roots"].values():
        for st in r["stacks"]:
            for cf in st["compose_files"]:
                for e in cf["services"]:
                    if "name" not in e: continue
                    lb = by_name.get(e.get("container_name") or "") or by_proj.get((st["id"], e["name"])) \
                         or next((v for k, v in by_name.items() if k.startswith(f"{e['name']}-{st['id']}")), None)
                    if not lb: continue
                    e["running"] = True
                    for k in ("app.name", "app.component"):
                        if not e.get(k) and lb.get(k): e[k] = lb[k]; e.setdefault("live_labels_from", "docker")

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

def docker_mounts(inv):
    """paths mode: add live mounts (incl. resolved named-volume Mountpoint) from running containers."""
    import subprocess
    try:
        ids = subprocess.run(["docker", "ps", "-q"], capture_output=True, text=True, timeout=15).stdout.split()
        if not ids: return
        data = json.loads(subprocess.run(["docker", "inspect", *ids], capture_output=True, text=True, timeout=30).stdout or "[]")
    except Exception:
        return
    by = {}
    for c in data:
        lb = (c.get("Config") or {}).get("Labels") or {}
        m = [{"type": x.get("Type"), "source": x.get("Source"), "target": x.get("Destination"), **({"volume": x["Name"]} if x.get("Name") else {})} for x in c.get("Mounts") or []]
        by[c.get("Name", "").lstrip("/")] = (lb, m)
        p, sv = lb.get("com.docker.compose.project"), lb.get("com.docker.compose.service")
        if p and sv: by[(p, sv)] = (lb, m)
    for r in inv["roots"].values():
        for st in r["stacks"]:
            for cf in st["compose_files"]:
                for e in cf["services"]:
                    if "name" not in e: continue
                    hit = by.get(e.get("container_name") or "") or by.get((st["id"], e["name"])) \
                          or next((v for k, v in by.items() if isinstance(k, str) and k.startswith(f"{e['name']}-{st['id']}")), None)
                    if not hit: continue
                    lb, m = hit
                    e["running"] = True
                    for k in ("app.name", "app.component"):
                        if not e.get(k) and lb.get(k): e[k] = lb[k]
                    if m: e["live_mounts"] = m

if mode == "paths":
    for r in inv["roots"].values():
        r["stacks"] = [{"id": st["id"], "stack_dir": st["path"],
                        "compose_files": [{"compose_file": cf["file"], "services": cf["services"]} for cf in st["compose_files"]]}
                       for st in r["stacks"]]
    docker_mounts(inv)
else:
    docker_enrich(inv)
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
print(f"\nWrote {out} [{mode}] ({n} compose services)")
PY
