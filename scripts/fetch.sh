#!/usr/bin/env bash
# Downloads public omics data for noggin scientists: only from known repositories, only into research/data/.
#   fetch.sh <url> <research/data/...>   download; skips a file that already exists
#   fetch.sh --size <url>                print the file's size in bytes, or "unknown"
# More hosts per project: fetch_hosts=host1,host2 in noggin.conf (see Skill(check)).
set -euo pipefail

hosts=(
  # sequencing: genomics, epigenomics, bulk and single-cell transcriptomics
  ftp.ncbi.nlm.nih.gov www.ncbi.nlm.nih.gov ftp.sra.ebi.ac.uk ftp.ebi.ac.uk www.ebi.ac.uk
  www.encodeproject.org datasets.cellxgene.cziscience.com cf.10xgenomics.com api.gdc.cancer.gov
  # proteomics
  ftp.pride.ebi.ac.uk massive-ftp.ucsd.edu massive.ucsd.edu rest.uniprot.org ftp.uniprot.org
  # references
  ftp.ensembl.org hgdownload.soe.ucsc.edu
)
extra=$(sed -n 's/^fetch_hosts=//p' noggin.conf 2>/dev/null | tail -1 || true)
[ -n "$extra" ] && IFS=, read -ra more <<< "$extra" && hosts+=("${more[@]}")

usage() { echo "usage: fetch.sh <url> <research/data/...> | fetch.sh --size <url>" >&2; exit 2; }
refuse() { echo "fetch: refused: $1" >&2; exit 1; }
host_ok() {  # https or ftp, no user@ part, host on the list
  local h a
  h=$(printf '%s' "$1" | sed -nE 's#^(https|ftp)://([^/:@?]+)(:[0-9]+)?(/[^@]*)?$#\2#p')
  [ -n "$h" ] || return 1
  for a in "${hosts[@]}"; do [ "$h" = "$a" ] && return 0; done
  return 1
}

if [ "${1:-}" = --size ]; then
  [ $# -eq 2 ] || usage
  host_ok "$2" || refuse "host not on the list: $2"
  n=$(curl -sIL --max-time 60 "$2" | tr -d '\r' | awk 'tolower($1) == "content-length:" { n = $2 } END { print n }')
  echo "${n:-unknown}"
  exit 0
fi

[ $# -eq 2 ] || usage
url=$1 dest=$2
host_ok "$url" || refuse "host not on the list: $url"
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
