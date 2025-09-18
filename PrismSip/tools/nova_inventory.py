import os, json, hashlib, datetime, re

ROOT = os.path.dirname(os.path.dirname(__file__)) or "."
SRC  = os.path.join(ROOT, "src")
OUT_JSON = os.path.join(ROOT, "scripts.manifest.json")
OUT_MD   = os.path.join(ROOT, "docs", "scripts.inventory.md")

def sha1_of_file(path):
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def parse_header(text):
    # reads @Name, @Version, @Provides, @DependsOn, @Scope
    meta = {}
    for line in text.splitlines()[:50]:
        m = re.match(r"\s*--\s*@([A-Za-z]+):\s*(.*)$", line)
        if m:
            key = m.group(1).strip()
            val = m.group(2).strip()
            meta[key] = val
    return meta

files = []
for base, _, names in os.walk(SRC):
    for name in names:
        if not name.endswith(".lua"): continue
        p = os.path.join(base, name)
        rel = os.path.relpath(p, ROOT).replace('\\','/')
        try:
            with open(p, "r", encoding="utf-8", errors="ignore") as f:
                txt = f.read()
        except Exception:
            txt = ""
        meta = parse_header(txt)
        files.append({
            "path": rel,
            "name": name,
            "bytes": os.path.getsize(p),
            "sha1": sha1_of_file(p),
            "version": meta.get("Version"),
            "provides": meta.get("Provides"),
            "depends_on": meta.get("DependsOn"),
            "scope": meta.get("Scope"),
        })

files.sort(key=lambda x: x["path"])
manifest = {
    "project": os.path.basename(ROOT),
    "generated_at": datetime.datetime.utcnow().isoformat() + "Z",
    "count": len(files),
    "files": files
}

os.makedirs(os.path.join(ROOT, "docs"), exist_ok=True)
with open(OUT_JSON, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)

# Also write a human-readable markdown report
lines = ["# Script Inventory", "", f"_Generated: {manifest['generated_at']}_", "", "Path | Bytes | SHA1 | Version", "---|---:|---|---"]
for it in files:
    lines.append(f"{it['path']} | {it['bytes']} | `{it['sha1'][:10]}...` | {it.get('version') or '-'}")
with open(OUT_MD, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"Wrote {OUT_JSON} and {OUT_MD} (files: {len(files)})")
