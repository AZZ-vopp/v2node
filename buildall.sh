#!/bin/bash

# v2node Build Script for All Platforms
# This script builds v2node for all supported platforms and architectures

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get version
VERSION="${1:-$(git rev-parse --short HEAD)}"
echo -e "${GREEN}Building v2node version: ${VERSION}${NC}"

# Build output directory
BUILD_DIR="builds"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Function to build for a specific platform
build_platform() {
    local GOOS=$1
    local GOARCH=$2
    local GOARM=$3
    local GOMIPS=$4
    local NAME=$5
    
    echo -e "${YELLOW}Building for ${NAME}...${NC}"
    
    # Create temporary build directory
    TEMP_DIR="build_assets_${NAME}"
    mkdir -p "$TEMP_DIR"
    
    # Set environment variables
    export GOOS=$GOOS
    export GOARCH=$GOARCH
    export GOARM=$GOARM
    export GOMIPS=$GOMIPS
    export CGO_ENABLED=0
    
    # Build command
    local OUTPUT_NAME="v2node"
    if [ "$GOOS" = "windows" ]; then
        OUTPUT_NAME="v2node.exe"
    fi
    
    GOEXPERIMENT=jsonv2 go build -v -o "$TEMP_DIR/$OUTPUT_NAME" -trimpath -ldflags "-X 'github.com/AZZ-vopp/v2node/cmd.version=$VERSION' -s -w -buildid="
    
    if [ $? -eq 0 ]; then
        # Copy additional files
        cp README.md "$TEMP_DIR/" 2>/dev/null || true
        cp LICENSE "$TEMP_DIR/" 2>/dev/null || true
        
        # Create ZIP archive
        cd "$TEMP_DIR"
        zip -9qr "../$BUILD_DIR/v2node-${NAME}.zip" .
        cd ..
        
        # Generate checksums
        cd "$BUILD_DIR"
        DGST="v2node-${NAME}.zip.dgst"
        for METHOD in md5 sha1 sha256 sha512; do
            openssl dgst -$METHOD "v2node-${NAME}.zip" | sed 's/([^)]*)//g' >> "$DGST"
        done
        cd ..
        
        # Cleanup temp directory
        rm -rf "$TEMP_DIR"
        
        echo -e "${GREEN}✓ Built ${NAME}${NC}"
    else
        echo -e "${RED}✗ Failed to build ${NAME}${NC}"
        rm -rf "$TEMP_DIR"
    fi
}

# Build for softfloat MIPS
build_platform_mips_softfloat() {
    local GOARCH=$1
    local NAME=$2
    
    echo -e "${YELLOW}Building for ${NAME} (softfloat)...${NC}"
    
    TEMP_DIR="build_assets_${NAME}_softfloat"
    mkdir -p "$TEMP_DIR"
    
    export GOOS=linux
    export GOARCH=$GOARCH
    export GOMIPS=softfloat
    export CGO_ENABLED=0
    
    GOEXPERIMENT=jsonv2 go build -v -o "$TEMP_DIR/v2node" -trimpath -ldflags "-X 'github.com/AZZ-vopp/v2node/cmd.version=$VERSION' -s -w -buildid="
    
    if [ $? -eq 0 ]; then
        cp README.md "$TEMP_DIR/" 2>/dev/null || true
        cp LICENSE "$TEMP_DIR/" 2>/dev/null || true
        
        cd "$TEMP_DIR"
        zip -9qr "../$BUILD_DIR/v2node-${NAME}-softfloat.zip" .
        cd ..
        
        cd "$BUILD_DIR"
        DGST="v2node-${NAME}-softfloat.zip.dgst"
        for METHOD in md5 sha1 sha256 sha512; do
            openssl dgst -$METHOD "v2node-${NAME}-softfloat.zip" | sed 's/([^)]*)//g' >> "$DGST"
        done
        cd ..
        
        rm -rf "$TEMP_DIR"
        echo -e "${GREEN}✓ Built ${NAME} (softfloat)${NC}"
    else
        echo -e "${RED}✗ Failed to build ${NAME} (softfloat)${NC}"
        rm -rf "$TEMP_DIR"
    fi
}

echo -e "${GREEN}Starting builds...${NC}\n"

# Download dependencies
echo -e "${YELLOW}Downloading dependencies...${NC}"
go mod download

# Windows builds
build_platform "windows" "386" "" "" "windows-32"
build_platform "windows" "amd64" "" "" "windows-64"

# Linux AMD64/386 builds
build_platform "linux" "386" "" "" "linux-32"
build_platform "linux" "amd64" "" "" "linux-64"

# Linux ARM builds
build_platform "linux" "arm" "5" "" "linux-arm32-v5"
build_platform "linux" "arm" "6" "" "linux-arm32-v6"
build_platform "linux" "arm" "7" "" "linux-arm32-v7a"
build_platform "linux" "arm64" "" "" "linux-arm64-v8a"

# Linux MIPS builds
build_platform "linux" "mips" "" "" "linux-mips32"
build_platform "linux" "mipsle" "" "" "linux-mips32le"
build_platform "linux" "mips64" "" "" "linux-mips64"
build_platform "linux" "mips64le" "" "" "linux-mips64le"

# Linux MIPS softfloat builds
build_platform_mips_softfloat "mips" "linux-mips32"
build_platform_mips_softfloat "mipsle" "linux-mips32le"

# Linux other architectures
build_platform "linux" "ppc64" "" "" "linux-ppc64"
build_platform "linux" "ppc64le" "" "" "linux-ppc64le"
build_platform "linux" "riscv64" "" "" "linux-riscv64"
build_platform "linux" "s390x" "" "" "linux-s390x"

# FreeBSD builds
build_platform "freebsd" "386" "" "" "freebsd-32"
build_platform "freebsd" "amd64" "" "" "freebsd-64"
build_platform "freebsd" "arm" "7" "" "freebsd-arm32-v7a"
build_platform "freebsd" "arm64" "" "" "freebsd-arm64-v8a"

# macOS builds
build_platform "darwin" "amd64" "" "" "macos-64"
build_platform "darwin" "arm64" "" "" "macos-arm64-v8a"

# Android builds
build_platform "android" "arm64" "" "" "android-arm64-v8a"

echo -e "\n${GREEN}==================================${NC}"
echo -e "${GREEN}All builds completed!${NC}"
echo -e "${GREEN}Build artifacts are in: ${BUILD_DIR}/${NC}"
echo -e "${GREEN}==================================${NC}"

# List all created files
echo -e "\n${YELLOW}Created files:${NC}"
ls -lh "$BUILD_DIR"
