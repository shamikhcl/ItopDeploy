#!/bin/bash
# This is a placeholder helper to pull DB info from terraform output.
set -euo pipefail
terraform output -json | jq '.rds_endpoint'
