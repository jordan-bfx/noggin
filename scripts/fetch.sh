#!/usr/bin/env bash
# Downloads public data for noggin scientists: only from the sources listed in research/datasets.md, only into research/data/.
#   fetch.sh <url> <research/data/...>   download a file; skips one that already exists
#   fetch.sh --size <url>                print its size in bytes, or "unknown"
#   fetch.sh --print <url>               print a small response (API metadata, listings), at most 10 MB
# Run from the project root. A URL is allowed when it starts with a `prefix/` in the download column of research/datasets.md.
set -euo pipefail

list=research/datasets.md
usage() { echo "usage: fetch.sh <url> <research/data/...> | --size <url> | --print <url>" >&2; exit 2; }
refuse() { echo "fetch: refused: $1" >&2; exit 1; }

[ -f "$list" ] || refuse "no $list; run /noggin:init"
prefixes=$(grep '^|' "$list" | grep -oE '`(https|ftp)://[^` ]+/`' | tr -d '`' || true)

url_ok() {
  local p
  # No dot segments, encoded or not: curl would resolve them and step outside the prefix.
  case "$1" in *"/../"*|*"/./"*|*"%2e"*|*"%2E"*) return 1 ;; esac
  while read -r p; do
    [ -n "$p" ] && [ "${1#"$p"}" != "$1" ] && return 0
  done <<< "$prefixes"
  return 1
}

case "${1:-}" in
  --size)
    [ $# -eq 2 ] || usage
    url_ok "$2" || refuse "not under a prefix in $list: $2"
    # Ask for one byte: the total is in Content-Range, and servers that refuse HEAD still answer.
    h=$(curl -sL --max-time 60 --max-filesize 1048576 -r 0-0 -o /dev/null -D - "$2" 2>/dev/null | tr -d '\r' || true)
    n=$(awk 'tolower($1) == "content-range:" { split($3, a, "/"); n = a[2] } END { print n }' <<< "$h")
    [ -n "$n" ] && [ "$n" != "*" ] || n=$(awk 'tolower($1) == "content-length:" { n = $2 } END { print n }' <<< "$h")
    echo "${n:-unknown}"
    exit 0 ;;
  --print)
    [ $# -eq 2 ] || usage
    url_ok "$2" || refuse "not under a prefix in $list: $2"
    curl -fsL --max-time 120 --max-filesize 10485760 "$2"
    exit 0 ;;
esac

[ $# -eq 2 ] || usage
url=$1 dest=$2
url_ok "$url" || refuse "not under a prefix in $list: $url"
case "$dest" in research/data/?*) ;; *) refuse "destination must be under research/data/: $dest" ;; esac
case "/$dest/" in */../*) refuse "no .. in the destination: $dest" ;; esac
mkdir -p "$(dirname "$dest")"
real=$(cd "$(dirname "$dest")" && pwd -P)
case "$real/" in "$(pwd -P)/research/data/"*) ;; *) refuse "destination resolves outside research/data/: $real" ;; esac

if [ -e "$dest" ]; then echo "fetch: exists $dest"; exit 0; fi
# Download beside the target, then rename: an interrupted download never looks complete.
curl -fL --retry 3 -o "$dest.part" "$url"
mv "$dest.part" "$dest"
echo "fetch: saved $dest ($(wc -c < "$dest" | tr -d ' ') bytes)"
