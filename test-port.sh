#!/bin/sh
# Test an OpenBSD port on a remote host.
# Usage: test-port.sh <port-path> [ssh-host]
#   port-path: relative path from repo root, e.g. productivity/csheet
#   ssh-host:  SSH host alias (default: puffy-risc)
#
# Requires doas to be configured on the remote host.

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PORT_PATH=${1:?Usage: $0 <port-path> [ssh-host]}
SSH_HOST=${2:-puffy-risc}
REMOTE_PORTS_DIR=/usr/ports
LOCAL_PORT_DIR="$SCRIPT_DIR/$PORT_PATH"

if [ ! -f "$LOCAL_PORT_DIR/Makefile" ]; then
    echo "ERROR: No Makefile found at $LOCAL_PORT_DIR" >&2
    exit 1
fi

# Expand Makefile variables: extract V, then substitute into PKGNAME
VERSION=$(grep '^V ' "$LOCAL_PORT_DIR/Makefile" | awk '{print $NF}')
PKGNAME=$(grep '^PKGNAME' "$LOCAL_PORT_DIR/Makefile" | awk '{print $NF}' | sed "s/\${V}/$VERSION/g")

cleanup() {
    echo "==> Cleaning up"
    ssh "$SSH_HOST" "cd $REMOTE_PORTS_DIR/$PORT_PATH && doas make deinstall 2>/dev/null; make clean" || true
}
trap cleanup EXIT

echo "==> Testing port: $PORT_PATH on $SSH_HOST"

# Step 1: Copy port files directly to /usr/ports
echo "==> Copying port files to $SSH_HOST"
ssh "$SSH_HOST" "mkdir -p $REMOTE_PORTS_DIR/$PORT_PATH/pkg"
scp "$LOCAL_PORT_DIR/Makefile" "$LOCAL_PORT_DIR/distinfo" \
    "$SSH_HOST:$REMOTE_PORTS_DIR/$PORT_PATH/"
scp "$LOCAL_PORT_DIR/pkg/PLIST" "$LOCAL_PORT_DIR/pkg/DESCR" \
    "$SSH_HOST:$REMOTE_PORTS_DIR/$PORT_PATH/pkg/"

# Step 2: Fetch, build and package
echo "==> Building package"
ssh "$SSH_HOST" "cd $REMOTE_PORTS_DIR/$PORT_PATH && make clean=packages && make package"

# Step 3: Verify PLIST while pobj is still user-owned
echo "==> Checking PLIST"
ssh "$SSH_HOST" "cd $REMOTE_PORTS_DIR/$PORT_PATH && make plist"
REMOTE_PLIST=$(ssh "$SSH_HOST" "cat $REMOTE_PORTS_DIR/$PORT_PATH/pkg/PLIST")
LOCAL_PLIST=$(cat "$LOCAL_PORT_DIR/pkg/PLIST")
if [ "$REMOTE_PLIST" = "$LOCAL_PLIST" ]; then
    echo "    PLIST unchanged - OK"
else
    echo "    PLIST changed - review and update:"
    echo "$REMOTE_PLIST"
fi

# Step 4: Install
echo "==> Installing"
ssh "$SSH_HOST" "cd $REMOTE_PORTS_DIR/$PORT_PATH && doas make install"

# Step 5: Verify installation and version
EXPECTED_VERSION=$VERSION
echo "==> Verifying installation ($PKGNAME)"
ssh "$SSH_HOST" "pkg_info $PKGNAME"

BINARY=$(grep '^@bin' "$LOCAL_PORT_DIR/pkg/PLIST" | awk '{print $2}' | head -1)
if [ -n "$BINARY" ] && [ -n "$EXPECTED_VERSION" ]; then
    echo "==> Checking version (expected: $EXPECTED_VERSION)"
    ACTUAL_VERSION=$(ssh "$SSH_HOST" "/usr/local/$BINARY -v 2>&1" | grep -o 'v[0-9][0-9.]*' | head -1 | tr -d 'v')
    if [ "$ACTUAL_VERSION" = "$EXPECTED_VERSION" ]; then
        echo "    Version OK: $ACTUAL_VERSION"
    else
        echo "    ERROR: version mismatch: got '$ACTUAL_VERSION', expected '$EXPECTED_VERSION'" >&2
        exit 1
    fi
fi

# Step 6: Functional smoke test
if [ -n "$BINARY" ]; then
    echo "==> Smoke test: /usr/local/$BINARY --help"
    ssh "$SSH_HOST" "/usr/local/$BINARY --help" || true
fi

echo "==> Done"
