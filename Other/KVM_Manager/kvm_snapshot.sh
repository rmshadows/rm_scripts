#!/bin/bash
# 快照管理 — 请使用 5-kvm_snapshot.sh
exec "$(dirname "$0")/5-kvm_snapshot.sh" "$@"
