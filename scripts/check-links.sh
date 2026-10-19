#!/usr/bin/env bash
# Check relative Markdown links (and their #anchors) in this repo.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/check-links.sh

Checks every relative link in the repo's Markdown files:
the target file or directory exists, and a #anchor matches a heading in the
target Markdown file. http(s) and mailto links are not fetched.

Prints one line per broken link and exits 1 if any are found.
USAGE
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  "") ;;
  *) echo "error: unexpected argument: $1" >&2; usage >&2; exit 1 ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import os, re, sys

root = sys.argv[1]
link_re = re.compile(r'\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)')
heading_re = re.compile(r'^#{1,6}\s+(.*?)\s*#*\s*$')

def slugs(path):
    out, seen, fence = set(), {}, False
    for line in open(path, encoding='utf-8'):
        if line.lstrip().startswith('```'):
            fence = not fence
            continue
        m = None if fence else heading_re.match(line)
        if not m:
            continue
        text = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', m.group(1))
        slug = re.sub(r'[^\w\- ]', '', text.lower()).replace(' ', '-')
        n = seen.get(slug, 0)
        seen[slug] = n + 1
        out.add(slug if n == 0 else f'{slug}-{n}')
    return out

broken = 0
for dirpath, dirnames, files in os.walk(root):
    dirnames[:] = [d for d in dirnames if d not in ('.git', 'vendor', 'node_modules')]
    for name in files:
        if not name.endswith('.md'):
            continue
        src = os.path.join(dirpath, name)
        fence = False
        for lineno, line in enumerate(open(src, encoding='utf-8'), 1):
            if line.lstrip().startswith('```'):
                fence = not fence
                continue
            if fence:
                continue
            for target in link_re.findall(re.sub(r'`[^`]*`', '', line)):
                if re.match(r'^(https?:|mailto:)', target):
                    continue
                path, _, anchor = target.partition('#')
                dest = os.path.normpath(os.path.join(dirpath, path)) if path else src
                rel = os.path.relpath(src, root)
                if not os.path.exists(dest):
                    print(f'{rel}:{lineno}: missing {target}')
                    broken += 1
                elif anchor and dest.endswith('.md') and anchor.lower() not in slugs(dest):
                    print(f'{rel}:{lineno}: no heading for #{anchor} in {target}')
                    broken += 1

if broken:
    print(f'{broken} broken link(s)')
    sys.exit(1)
print('links ok')
PY
