#!/bin/bash

ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setUp() {
  local ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  export PATH="$ROOT_PATH:$PATH"
}

# Tests for arguments and errors

function test_when_nonexisting_data_file_provided_then_should_exit_with_error() {
  local actual="$(mycsv.sh --file=$ROOT_PATH/nonexisting.csv 2>&1)"
  local expected="ERROR: file=[$ROOT_PATH/nonexisting.csv] not found."
  assertEquals "$expected" "$actual"
}

function test_when_empty_file_passed_then_should_exit_with_too_less_columns_error() {
  local actual="$(mycsv.sh --file=$ROOT_PATH/empty.csv 2>&1)"
  local expected="ERROR: Columns amount less than one."
  assertEquals "$expected" "$actual"
}

function test_when_invalid_file_provided_and_validate_arg_used_then_should_exit_with_proper_error() {
  local actual="$(mycsv.sh --file=$ROOT_PATH/data-invalid.csv --validate 2>&1)"
  local expected="ERROR: Validation failed, not all records have same columns amount, record=[5,Tan,4000,IT,3] is invalid."
  assertEquals "$expected" "$actual"
}

function test_when_valid_file_provided_and_validate_arg_used_then_should_exit_with_zero_status() {
  mycsv.sh --file=$ROOT_PATH/data.csv --validate > /dev/null 2>&1
  local actual=$?
  local expected=0
  assertEquals "$expected" "$actual"
}

function test_when_invalid_file_provided_and_validate_arg_used_then_should_exit_with_nonzero_status() {
  mycsv.sh --file=$ROOT_PATH/invalid-data.csv --validate > /dev/null 2>&1
  local actual=$?
  local expected=1
  assertEquals "$expected" "$actual"
  assertNotEquals 0 "$actual" # This actually tests what case name describes
}

function test_when_named_cols_in_outcolorder_and_hasheaders_not_passed_then_should_exit_with_proper_error() {
  local actual="$(mycsv.sh --file=$ROOT_PATH/data.csv --outcolorder='id 2' 2>&1)"
  local expected="Cannot use named columns headers in order option when hasheaders != 1."
  assertEquals "$expected" "$actual"
}

# Tests for help

function test_when_no_args_passed_then_help_should_be_printed() {
  help_content="$(mycsv.sh)"
  expected="$(cat $ROOT_PATH/help.snapshot.txt)"
  assertEquals "$expected" "$help_content"
}

function test_when_help_arg_passed_then_help_should_be_printed() {
  help_content="$(mycsv.sh --help)"
  expected="$(cat $ROOT_PATH/help.snapshot.txt)"
  assertEquals "$expected" "$help_content"
}

function test_when_h_arg_passed_then_help_should_be_printed() {
  help_content="$(mycsv.sh -h)"
  expected="$(cat $ROOT_PATH/help.snapshot.txt)"
  assertEquals "$expected" "$help_content"
}

function test_when_version_arg_passed_then_help_should_be_printed() {
  version_content="$(mycsv.sh --version)"
  expected="mycsv.sh, version 0.2.0"
  assertEquals "$expected" "$version_content"
}

# Tests for output

function test_default_output() {
  output="$(mycsv.sh --file=$ROOT_PATH/data.csv)"
  expected="$(cat $ROOT_PATH/default.output)"
  assertEquals "$expected" "$output"
}

function test_id_salary_output_by_cols_numbers() {
  output="$(mycsv.sh --file=$ROOT_PATH/data.csv -outcolorder='1 3')"
  expected="$(cat $ROOT_PATH/id_salary.output)"
  assertEquals "$expected" "$output"
}

function test_id_salary_output_by_cols_names() {
  output="$(mycsv.sh --file=$ROOT_PATH/data.csv -H -o='id salary')"
  expected="$(cat $ROOT_PATH/id_salary.output)"
  assertEquals "$expected" "$output"
}

function test_when_separator_arg_passed_then_it_is_used_in_output() {
  output="$(mycsv.sh --file=$ROOT_PATH/data.csv -H -o='id salary' --separator='|')"
  expected="$(cat $ROOT_PATH/id_salary_sep_by_pipe.output)"
  assertEquals "$expected" "$output"
}

function test_custom_format() {
  output="$(mycsv.sh --file=$ROOT_PATH/data.csv -F='\2 from \3 earns \2')"
  expected="$(cat $ROOT_PATH/formatted.output)"
  assertEquals "$expected" "$output"
}

# Tests for 'malformed' files

function test_regex_for_columns_amount_should_recognise_empty_values() {
  for variant in $(seq 0 15 | \
    xargs -I{} bash -c 'bin=$(echo "obase=2;{}" | bc); printf "%04d\n" "$bin"' | \
    sed -E 's#(.)#,\1#g' | \
    cut -d',' -f2- | \
    sed 's#0##g; s#1#a#g'
  ); do
    actual="$(echo "$variant," | grep -oE '(".*?"|[^,]+),|,' | wc -l)"
    expected=4
    assertEquals $expected $actual
  done
}

function test_when_file_has_no_headers_and_has_empty_values_then_should_be_valid() {
  mycsv.sh --file=$ROOT_PATH/data_with_empty_values_no_header.csv --validate > /dev/null 2>&1
  actual_exit_status=$?
  expected=0
  assertEquals "$expected" "$actual_exit_status"
}

function test_when_file_has_empty_values_then_should_be_valid() {
  mycsv.sh --file=$ROOT_PATH/data_with_empty_values.csv --validate > /dev/null 2>&1
  actual_exit_status=$?
  expected=0
  assertEquals "$expected" "$actual_exit_status"
}

function test_when_file_has_empty_values_then_select_single_column_should_retrieve_proper_data() {
  for i in $(seq 1 4); do
    actual="$(mycsv.sh --file=$ROOT_PATH/data_with_empty_values.csv --o="$i")"
    expected=$(cat $ROOT_PATH/data_with_empty_values_outcol_$i.csv)
    assertEquals "$expected" "$actual"
  done
}

# function test_when

. $ROOT_PATH/../shunit2/shunit2
