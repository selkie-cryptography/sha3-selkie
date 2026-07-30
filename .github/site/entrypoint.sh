#!/bin/sh
# Ensure the data directories exist on the persistent volume. The volume
# mount replaces /data at runtime, so these can't be created at image-build
# time. Keep in sync with ALL_KINDS in .github/scripts/ci-upload.rs and the
# location blocks in nginx.conf.
#
# Every backend that compiles a different kernel gets its own kind: no single
# build compiles all of them, so a per-backend report is the only kind there
# is.
mkdir -p \
    /data/coverage-portable /data/coverage-avx2 /data/coverage-avx512 \
    /data/coverage-neon /data/coverage-hybrid \
    /data/bench-neon /data/bench-neon-pairs /data/bench-avx2 \
    /data/bench-avx512 /data/bench-hybrid \
    /data/mutants-x86_64 /data/mutants-x86_64-avx512 \
    /data/mutants-aarch64-apple /data/mutants-aarch64-hybrid \
    /data/ctgrind-portable /data/ctgrind-avx2 \
    /data/deny /data/unsafe /data/platform /data/kat
exec nginx -g 'daemon off;'
