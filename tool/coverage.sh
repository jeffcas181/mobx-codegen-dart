#!/bin/bash

# Fast fail the script on failures.
set -e

OBS_PORT=9292
echo "Collecting coverage on port $OBS_PORT..."

# Start tests in one VM.
echo "Starting tests..."
dart \
  --disable-service-auth-codes \
  --pause-isolates-on-exit \
  --enable_asserts \
  --enable-vm-service=$OBS_PORT \
  test/all_tests.dart &

# Run the coverage collector to generate the JSON coverage report.
echo "Collecting coverage..."
nohup dart run coverage:collect_coverage \
  --port=$OBS_PORT \
  --out=coverage/coverage.json \
  --wait-paused \
  --resume-isolates

echo "Generating LCOV report..."
dart run coverage:format_coverage \
  --lcov \
  --in=coverage/coverage.json \
  --out=coverage/lcov.info \
  --packages=.dart_tool/package_config.json \
  --report-on=lib
