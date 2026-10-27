#!/usr/bin/env bash
# coolify-inventory.sh — YAML inventory of Coolify compose stacks.
# Usage: coolify-inventory.sh [raw|paths|summary] [file.yaml]   (also --mode=...)
#   raw   (default) full inventory -> ~/data/inv/coolify-inventory.yaml
#   paths stack dirs, compose files, volumes/bind mounts, working_dir, build context -> ~/data/inv/coolify-paths.yaml
#   summary  human-readable tree of existing raw YAML (project/stack/service/component/image/container);
#            add --refresh (or -r) to regenerate raw first; --tsv for tab-separated rows;
#            --yaml (or --format yaml|tsv|text): YAML keyed project -> stack_name (app.name) -> service name, merged with
#            paths info (stack_dir, volumes, env_file...) from coolify-paths.yaml if present;
#            --by-name writes it to ~/data/inv/coolify-by-name.yaml (--out=FILE for another path)
#   get|lookup <stack_name> [component]   (or --name X [--component Y]) print the YAML block for a stack (app.name)
#            or one service (matched by app.component, else service key) from ~/data/inv/coolify-by-name.yaml;
#            -r/--refresh regenerates it first (also auto-generated if missing); --file=F other by-name file
#   COOLIFY_INVENTORY_OUT=... overrides output; COOLIFY_ROOT=/data/coolify
set -euo pipefail
MODE=raw
case "${1:-}" in
  raw|paths|summary|list|get|lookup) MODE="$1"; shift ;;
  --mode=*) MODE="${1#--mode=}"; shift ;;
  --mode) MODE="${2:?}"; shift 2 ;;
  -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
esac
[ "$MODE" = list ] && MODE=summary
[ "$MODE" = lookup ] && MODE=get
case "$MODE" in raw|paths|summary|get) ;; *) echo "unknown mode: $MODE (raw|paths|summary|get)" >&2; exit 2 ;; esac
if [ "$MODE" = get ]; then
  LN=""; LC=""; REFRESH=0; BYN="${COOLIFY_BYNAME_OUT:-$HOME/data/inv/coolify-by-name.yaml}"
  while [ $# -gt 0 ]; do case "$1" in
    -r|--refresh) REFRESH=1 ;;
    --name=*) LN="${1#--name=}" ;; --name|-n) LN="${2:?}"; shift ;;
    --component=*) LC="${1#--component=}" ;; --component|-c) LC="${2:?}"; shift ;;
    --file=*) BYN="${1#--file=}" ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) if [ -z "$LN" ]; then LN="$1"; elif [ -z "$LC" ]; then LC="$1"; else echo "extra arg: $1" >&2; exit 2; fi ;;
  esac; shift; done
  [ -n "$LN" ] || { echo "usage: $0 get <stack_name> [component]  |  lookup --name X [--component Y]" >&2; exit 2; }
  if [ "$REFRESH" = 1 ] || [ ! -f "$BYN" ]; then "$0" summary --refresh --out="$BYN" || exit 1; fi
  exec python3 - "$BYN" "$LN" "$LC" <<'PY'
import sys, yaml
f, name, comp = sys.argv[1:4]
Y = yaml.safe_load(open(f)) or {}
hits = [(p, k, S) for p, P in (Y.get("projects") or {}).items() for k, S in ((P or {}).get("stacks") or {}).items()
        if name in (k, S.get("stack_name"), S.get("id"))]
if not hits:
    names = sorted({S.get("stack_name") or k for P in (Y.get("projects") or {}).values() for k, S in ((P or {}).get("stacks") or {}).items()})
    sys.exit(f"no stack '{name}' in {f}\navailable: " + ", ".join(names))
out = {}
for p, k, S in hits:
    if comp:
        sv = {n: v for n, v in (S.get("services") or {}).items() if v.get("component") == comp} \
             or {n: v for n, v in (S.get("services") or {}).items() if n == comp}
        if not sv: continue
        out.setdefault(p, {}).setdefault(k, {"stack_name": S.get("stack_name"), "id": S.get("id"), "stack_dir": S.get("stack_dir"), "services": {}})["services"].update(sv)
    else:
        out.setdefault(p, {})[k] = S
if not out:
    avail = sorted({v.get("component") or n for _, _, S in hits for n, v in (S.get("services") or {}).items()})
    sys.exit(f"no component '{comp}' in stack '{name}'\navailable: " + ", ".join(avail))
print(f"# {f}  (generated {Y.get('generated')})")
sys.stdout.write(yaml.safe_dump({"projects": {p: {"stacks": st} for p, st in out.items()}}, sort_keys=False, allow_unicode=True))
PY
fi
if [ "$MODE" = summary ]; then
  REFRESH=0; TSV=0; IN=""; OUTF=""
  while [ $# -gt 0 ]; do case "$1" in -r|--refresh) REFRESH=1 ;; --tsv) TSV=1 ;; --yaml) TSV=yaml ;;
    --out=*) OUTF="${1#--out=}"; TSV=yaml ;;
    --by-name) OUTF="${COOLIFY_BYNAME_OUT:-$HOME/data/inv/coolify-by-name.yaml}"; TSV=yaml ;;
    --format=*|--format) if [ "$1" = --format ]; then F="${2:?}"; shift; else F="${1#--format=}"; fi
      case "$F" in yaml|yml) TSV=yaml ;; tsv) TSV=1 ;; text|human) TSV=0 ;; *) echo "bad format: $F (text|tsv|yaml)" >&2; exit 2 ;; esac ;;
    *) IN="$1" ;; esac; shift; done
  IN="${IN:-${COOLIFY_INVENTORY_OUT:-$HOME/data/inv/coolify-inventory.yaml}}"
  PATHS_IN="${COOLIFY_PATHS_IN:-$HOME/data/inv/coolify-paths.yaml}"
  [ "$REFRESH" = 1 ] && "$0" raw "$IN" >/dev/null && { [ "$TSV" = yaml ] && "$0" paths "$PATHS_IN" >/dev/null || true; }
  if [ -n "$OUTF" ]; then mkdir -p "$(dirname "$OUTF")"; "$0" summary --yaml "$IN" > "$OUTF"; echo "Wrote $OUTF" >&2; exit 0; fi
  export PATHS_IN
  [ -f "$IN" ] || { echo "no inventory: $IN (run: $0 raw, or summary --refresh)" >&2; exit 1; }
  exec python3 - "$IN" "$TSV" <<'PY'
import sys, yaml, signal; signal.signal(signal.SIGPIPE, signal.SIG_DFL)
inv = yaml.safe_load(open(sys.argv[1])) or {}; tsv = sys.argv[2] == "1"; ym = sys.argv[2] == "yaml"
if ym:
    tsv = True
    import os
    try: PI = yaml.safe_load(open(os.environ.get("PATHS_IN",""))) or {}
    except Exception: PI = {}
    PS = {(k, st["id"]): st for k, r in (PI.get("roots") or {}).items() for st in r.get("stacks") or []}
    PSV = {(k, st["id"], e.get("name")): e for (k, _), st in PS.items() for cf in st.get("compose_files") or [] for e in cf.get("services") or []}
    Y = {"paths_source": os.environ.get("PATHS_IN") if PI else None, "source": sys.argv[1], "host": inv.get("host"), "generated": inv.get("generated"), "projects": {}}
    print = lambda *a, **k: None
print(f"# {sys.argv[1]}  host={inv.get('host')}  generated={inv.get('generated')}") if not tsv else \
  print("root\tproject\tstack_name\tstack_id\tservice\tcomponent\timage\tcontainer_name\trunning")
tot = 0
for kind, r in (inv.get("roots") or {}).items():
    stacks = r.get("stacks") or []
    if not tsv: print(f"\n== {kind} ({len(stacks)} stacks) — {r.get('path')}")
    for st in stacks:
        svcs = [e for cf in st.get("compose_files") or [] for e in cf.get("services") or []]
        lb = lambda k: next((e.get("labels", {}).get(k) for e in svcs if (e.get("labels") or {}).get(k)), None)
        # stack_name: docker label app.name (names the whole stack) > coolify.resourceName > compose project > id
        name = next((e.get("app.name") or (e.get("labels") or {}).get("app.name") for e in svcs if e.get("app.name") or (e.get("labels") or {}).get("app.name")), None) \
               or (lb("coolify.resourceName") or "").removesuffix("-" + st["id"]) or lb("com.docker.compose.project") or st["id"]
        proj = lb("coolify.projectName") or "-"; env = lb("coolify.environmentName")
        if not tsv:
            print(f"  [{proj}{'/'+env if env and env!='production' else ''}] stack: {name}  (id {st['id']})" + ("  (no compose)" if not svcs else ""))
        for e in svcs:
            tot += 1
            row = [kind, proj, name, st["id"], e.get("name") or e.get("error", "?"), e.get("app.component") or "",
                   e.get("image") or "", e.get("container_name") or "", "yes" if e.get("running") else ""]
            if ym:
                P = Y["projects"].setdefault(proj, {"stacks": {}})
                key = name if name not in P["stacks"] or P["stacks"][name]["id"] == st["id"] else f"{name} ({st['id']})"
                ps = PS.get((kind, st["id"])) or {}
                S = P["stacks"].setdefault(key, {"stack_name": name, "id": st["id"], "root": kind, "environment": env,
                                                 "stack_dir": ps.get("stack_dir") or st.get("path"),
                                                 "compose_files": [cf.get("file") for cf in st.get("compose_files") or []], "services": {}})
                pe = PSV.get((kind, st["id"], row[4])) or {}
                sv = {k: v for k, v in {"stack_name": name, "stack_id": st["id"], "component": row[5] or None, "image": row[6] or None, "container_name": row[7] or None,
                      "running": bool(row[8]), "working_dir": pe.get("working_dir"), "build_context": pe.get("build_context"),
                      "env_file": pe.get("env_file"), "volumes": pe.get("volumes"), "live_mounts": pe.get("live_mounts")}.items() if v is not None}
                S["services"][row[4]] = sv
            if tsv: print("\t".join(map(str, row)))
            else:
                comp = f" <{row[5]}>" if row[5] else ""
                print(f"    - {row[4]}{comp}  {row[6] or '(build)'}" + (f"  ⟶ {row[7]}" if row[7] else "") + ("  ●" if row[8] else ""))
if not tsv: print(f"\n{tot} services total  (● = running)")
if ym:
    Y["total_services"] = tot
    sys.stdout.write(yaml.safe_dump(Y, sort_keys=False, allow_unicode=True))
PY
fi
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
