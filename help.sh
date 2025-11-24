#!/bin/bash

function print_help() {
  echo -e "mycsv.sh script usage
  \033[1m--file\033[0m, \033[1m-f\033[0m
    path to CSV file, mandatory

  \033[1m--hasheaders\033[0m, \033[1m-H\033[0m
    use this option to denote that input has CSV headers in first row

  \033[1m--outcolorder\033[0m, \033[1m-o\033[0m
    numberr or names e.g. 1 2 username price 4

  \033[1m--separator\033[0m, \033[1m-s\033[0m
    can be a single character, can be string

  \033[1m--format\033[0m, \033[1m-F\033[0m
    your own format, to render columns inside it use \\1, \\2 etc .

  \033[1m--validate\033[0m
    prints this help and exits

  \033[1m--version\033[0m, \033[1m-v\033[0m
    print version and exit

  \033[1m--help\033[0m, \033[1m-h\033[0m
    print this help and exit

    Examples:
    mycsv.sh --file=data.csv --has-headers -o='1 2 3' -s=','

    mycsv.sh -f='data.csv' --validate
    "
    return 0
}
