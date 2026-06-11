#!/bin/sh
# Tiny convenience wrapper: `./fence.sh check` == `kujo run fence.kujo -- check`.
# The real implementation lives entirely in fence.kujo and src/*.kujo.
exec kujo run fence.kujo -- "$@"
