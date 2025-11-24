#!/bin/bash

ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION='0.1.0'

source "${ROOT_PATH}/help.sh"

if [[ $# -le 0 ]]; then
  print_help
  exit 1
fi

f=''
H=0
o=''
s=','
F=''

for a in "$@"; do
  charset=".*" # dangerous, but I handle it this way to be able to use any value as format arg and other
  if [[ -n "$(echo "$a" | grep -E "^\-{1,2}($charset)(=$charset)?$")" ]]; then
    eval "$(printf "%q" "$a" | sed -E 's#^\-{1,2}##' | sed -E 's#^([^=]+)$#\1=1#')"
  fi
done

file=${file:-$f}
hasheaders=${hasheaders:-$H}
outcolorder=${outcolorder:-$o}
separator=${separator:-$s}
format=${format:-$F}
# validate auto-assigned above as 1 if --validate passed
version=${version:-$v}
help=${help:-$h}


if [[ "$help" == '1' ]]; then
  print_help
  exit 0
fi

if [[ "$version" == '1' ]]; then
  echo "mycsv.sh, version $VERSION"
  exit 0
fi


# stdin should be handled better way
if [[ "$file" == '-' ]]; then
  file="$(mktemp)"
  { while read -r record; do echo "$record"; done } > "$file"
fi

if [[ ! -f "$file" ]]; then
  echo "ERROR: file=[$file] not found." >&2
  exit 1
fi


columns_amount=$(cat "$file" | sed -n '1p' | grep -oE '"[^"]+"|[^,]+' | wc -l)

if [[ $columns_amount -lt 1 ]]; then
  echo "ERROR: Columns amount less than one." >&2
  exit 1
fi


if [[ -n "$validate" ]]; then
  while read -r record; do
    curcols=$(echo "$record" | grep -oE '"[^"]+"|[^,]+' | wc -l)
    if [[ $columns_amount -ne $curcols ]]; then
      echo "ERROR: Validation failed, not all records have same columns amount, record=[$record] is invalid." >&2
      exit 1
    fi
  done < "$file"
  exit 0
fi


if [[ -z "$outcolorder" ]]; then
  outcolorder="$(seq 1 $columns_amount | xargs)"
fi

if [[ "$hasheaders" == '0' && -n "$(echo "$outcolorder" | grep -oE '[^0-9 ]')" ]]; then
  echo "Cannot use named columns headers in order option when hasheaders != 1." 2>&1
  exit 1
fi

if [[ "$hasheaders" == '1' ]]; then
  header_names=($(cat "$file" | head -n 1 | grep -oE '"[^"]+"|[^,]+'))
  header_index=1
  for header_name in "${header_names[@]}"; do
    outcolorder="$(echo "$outcolorder" | sed "s#$header_name#$header_index#g")"
    header_index=$((header_index + 1))
  done
fi

regex="$(seq 1 $columns_amount | \
  xargs | \
  sed -E 's#[0-9]+[ ]?#\,(\"[^\"]+\"|[^,]+\)#g' | \
  cut -c 2-)"

outcolorder="$(echo "$outcolorder" | sed -E 's#([0-9]+)#\\\1#g' | sed "s# #$separator#g")"

if [[ -z "$format" ]]; then
  format="$outcolorder"
fi

sed -E "s#$regex#$format#" "$file"
