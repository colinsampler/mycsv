#!/bin/bash

ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION='0.2.0'
CSV_SPLIT_RE='(".*?"|[^,]+),|,'

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

# add comma at the end to properly get columns amount, see how $CSV_SPLIT_RE works
first_rec="$(cat "$file" | sed -n '1p'),"
columns_amount=$(echo "$first_rec" | grep -oE "$CSV_SPLIT_RE" | wc -l)

# -lt 2, because adding comma to empty record makes columns_amount min 1
if [[ $columns_amount -lt 2 ]]; then
  echo "ERROR: Columns amount less than one." >&2
  exit 1
fi


if [[ -n "$validate" ]]; then
  while read -r record; do
    # append comma to each record to get proper amount of columns for each record with $CSV_SPLIT_RE
    curcols=$(echo "$record," | grep -oE "$CSV_SPLIT_RE" | wc -l)
    if [[ $columns_amount -ne $curcols ]]; then
      echo "ERROR: Validation failed, not all records have same columns amount, record=[$record] is invalid." >&2
      exit 1
    fi
  done < "$file"
  exit 0
fi

# if not provided, generate them like 1 2 3 4 5 ... $columns_amount
if [[ -z "$outcolorder" ]]; then
  outcolorder="$(seq 1 $columns_amount | xargs)"
fi

if [[ "$hasheaders" == '0' && -n "$(echo "$outcolorder" | grep -oE '[^0-9 ]')" ]]; then
  echo "Cannot use named columns headers in order option when hasheaders != 1." 2>&1
  exit 1
fi

if [[ "$hasheaders" == '1' ]]; then
  first_rec="$(cat "$file" | sed -n '1p'),"
  # WARNING: on purpose array declared below
  header_names=($(echo "$first_rec" | grep -oE "$CSV_SPLIT_RE" | sed -E 's#,$##'))
  header_index=1
  for header_name in "${header_names[@]}"; do
    outcolorder="$(echo "$outcolorder" | sed "s#$header_name#$header_index#g")"
    header_index=$((header_index + 1))
  done
fi

# generate sed's capture regex
# $columns_amount times \,("[^"]+"|""|[^,]+|()) aka String.join by comma
# remove first comma that is actually not added by String.join
regex="$(seq 1 $columns_amount | \
  xargs | \
  sed -E 's#[0-9]+[ ]?#\,(".*"|[^,]+|())#g' | \
  cut -c2-)"

# Because above sed has two capturing groups I cannot have out order as 1 2 3 4 ... I need silently renumber it to 1 3 5 7 ... for user needs
# then I prepare references like from 1 3 5 7 ... to \1 \3 \5 \7 ...
# and I apply proper separator to the output
outcolorder="$(echo "$outcolorder" | \
  grep -oE '[0-9]+' | \
  awk '{ print 2*$1-1 }' | \
  paste -sd' ' - | \
  sed -E 's#([0-9]+)#\\\1#g' | \
  sed "s# #$separator#g")"

if [[ -z "$format" ]]; then
  format="$outcolorder"
else
  # fix columns numbers in $format if needed
  format="$(echo "$format" | \
    sed -E 's#(\\[0-9+])#\n\1\n#g' | \
    awk '
    /^\\/ {
      num=$0
      sub(/\\/, "", num)
      printf("\\\\%d\n", 2*num-1)
      next
    }
    {
      print
    }
    ' | \
    xargs)"
fi

sed -E "s#$regex#$format#" "$file"
