#!/bin/bash

setUp() {
  local ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  export PATH="$ROOT_PATH:$PATH"
}

# Tests for arguments and errors

function test_when_nonexisting_data_file_provided_then_should_exit_with_error() {
  local actual="$(mycsv.sh --file=nonexisting.csv 2>&1)"
  local expected="ERROR: file=[nonexisting.csv] not found."
  assertEquals "$expected" "$actual"
}

function test_when_empty_file_passed_then_shouled_exit_with_too_less_columns_error() {
  local actual="$(mycsv.sh --file=empty.csv 2>&1)"
  local expected="ERROR: Columns amount less than one."
  assertEquals "$expected" "$actual"
}

function test_when_invalid_file_provided_and_validate_arg_used_then_should_exit_with_proper_error() {
  local actual="$(mycsv.sh --file=data-invalid.csv --validate 2>&1)"
  local expected="ERROR: Validation failed, not all records have same columns amount, record=[5,Tan,4000,IT,3] is invalid."
  assertEquals "$expected" "$actual"
}

function test_when_valid_file_provided_and_validate_arg_used_then_should_exit_with_zero_status() {
  mycsv.sh --file=data.csv --validate > /dev/null 2>&1
  local actual=$?
  local expected=0
  assertEquals "$expected" "$actual"
}

function test_when_invalid_file_provided_and_validate_arg_used_then_should_exit_with_nonzero_status() {
  mycsv.sh --file=invalid-data.csv --validate > /dev/null 2>&1
  local actual=$?
  local expected=1
  assertEquals "$expected" "$actual"
  assertNotEquals 0 "$actual" # This actually tests what case name describes
}

function test_when_named_cols_in_outcolorder_and_hasheaders_not_passed_then_should_exit_with_proper_error() {
  local actual="$(mycsv.sh --file=data.csv --outcolorder='id 2' 2>&1)"
  local expected="Cannot use named columns headers in order option when hasheaders != 1."
  assertEquals "$expected" "$actual"
}

# Tests for help

function test_when_no_args_passed_then_help_should_be_printed() {
  help_content="$(mycsv.sh)"
  expected="$(cat help.snapshot.txt)"
  assertEquals "$expected" "$help_content"
}

function test_when_help_arg_passed_then_help_should_be_printed() {
  help_content="$(mycsv.sh --help)"
  expected="$(cat help.snapshot.txt)"
  assertEquals "$expected" "$help_content"
}

function test_when_h_arg_passed_then_help_should_be_printed() {
  help_content="$(mycsv.sh -h)"
  expected="$(cat help.snapshot.txt)"
  assertEquals "$expected" "$help_content"
}

function test_when_version_arg_passed_then_help_should_be_printed() {
  version_content="$(mycsv.sh --version)"
  expected="mycsv.sh, version 0.1.0"
  assertEquals "$expected" "$version_content"
}

# Tests for output

function test_default_output() {
  output="$(mycsv.sh --file=data.csv)"
  expected="$(cat default.output)"
  assertEquals "$expected" "$output"
}

function test_id_salary_output_by_cols_numbers() {
  output="$(mycsv.sh --file=data.csv -outcolorder='1 3')"
  expected="$(cat id_salary.output)"
  assertEquals "$expected" "$output"
}

function test_id_salary_output_by_cols_names() {
  output="$(mycsv.sh --file=data.csv -H -o='id salary')"
  expected="$(cat id_salary.output)"
  assertEquals "$expected" "$output"
}

function test_when_separator_arg_passed_then_it_is_used_in_output() {
  output="$(mycsv.sh --file=data.csv -H -o='id salary' --separator='|')"
  expected="$(cat id_salary_sep_by_pipe.output)"
  assertEquals "$expected" "$output"
}

function test_custom_format() {
  output="$(mycsv.sh --file=data.csv -F='\2 from \3 earns \2')"
  expected="$(cat formatted.output)"
  assertEquals "$expected" "$output"
}

tearDown() {
  :
  # assertEquals 1 0
  # TODO:
}

. ../shunit2/shunit2
