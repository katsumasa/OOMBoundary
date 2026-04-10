#!/bin/bash

# Build Script for OOMBoundary
# Usage: ./build.sh [soft|full] [device|simulator] [debug|release]

set -e

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
MODE="${1:-soft}"
PLATFORM="${2:-simulator}"
CONFIGURATION="${3:-debug}"

echo -e "${BLUE}🏗️  OOMBoundary Build Tool${NC}"
echo ""

# Validate mode
case "${MODE}" in
    soft|SOFT|Soft)
        MODE="soft"
        MODE_DISPLAY="Soft Mode"
        ;;
    full|FULL|Full|hard|HARD|Hard)
        MODE="full"
        MODE_DISPLAY="Full Mode"
        ;;
    *)
        echo -e "${RED}❌ Invalid mode: ${MODE}${NC}"
        echo "Usage: $0 [soft|full] [device|simulator] [debug|release]"
        exit 1
        ;;
esac

# Validate platform
case "${PLATFORM}" in
    device|DEVICE|Device)
        DESTINATION="generic/platform=iOS"
        PLATFORM_DISPLAY="iOS Device"
        ;;
    simulator|SIMULATOR|Simulator|sim)
        DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
        PLATFORM_DISPLAY="iOS Simulator"
        ;;
    *)
        echo -e "${RED}❌ Invalid platform: ${PLATFORM}${NC}"
        echo "Usage: $0 [soft|full] [device|simulator] [debug|release]"
        exit 1
        ;;
esac

# Validate configuration
case "${CONFIGURATION}" in
    debug|DEBUG|Debug)
        CONFIGURATION="Debug"
        ;;
    release|RELEASE|Release)
        CONFIGURATION="Release"
        ;;
    *)
        echo -e "${RED}❌ Invalid configuration: ${CONFIGURATION}${NC}"
        echo "Usage: $0 [soft|full] [device|simulator] [debug|release]"
        exit 1
        ;;
esac

echo -e "Mode:          ${GREEN}${MODE_DISPLAY}${NC}"
echo -e "Platform:      ${BLUE}${PLATFORM_DISPLAY}${NC}"
echo -e "Configuration: ${YELLOW}${CONFIGURATION}${NC}"
echo ""

# Switch memory enforcement mode
echo -e "${BLUE}🔧 Switching to ${MODE_DISPLAY}...${NC}"
export MEMORY_ENFORCEMENT_MODE="${MODE}"
"${PROJECT_DIR}/Scripts/switch-memory-enforcement.sh"

echo ""
echo -e "${BLUE}🔨 Building...${NC}"

cd "${PROJECT_DIR}"

# Get version info
VERSION=$(xcrun agvtool what-marketing-version -terse1 2>/dev/null || echo "Unknown")
BUILD=$(xcrun agvtool what-version -terse 2>/dev/null || echo "Unknown")

echo -e "Version: ${GREEN}${VERSION}${NC}"
echo -e "Build:   ${GREEN}${BUILD}${NC}"
echo ""

# Build
xcodebuild \
    -project OOMBoundary.xcodeproj \
    -scheme OOMBoundary \
    -configuration "${CONFIGURATION}" \
    -destination "${DESTINATION}" \
    clean build \
    | xcpretty || true

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Build succeeded!${NC}"
    echo -e "   Mode: ${MODE_DISPLAY}"
    echo -e "   Version: ${VERSION} (Build ${BUILD})"

    # Output location
    BUILD_DIR="${PROJECT_DIR}/build/${CONFIGURATION}-iphoneos"
    if [ "${PLATFORM}" = "simulator" ]; then
        BUILD_DIR="${PROJECT_DIR}/build/${CONFIGURATION}-iphonesimulator"
    fi

    if [ -d "${BUILD_DIR}" ]; then
        echo -e "   Output: ${BUILD_DIR}"
    fi
else
    echo ""
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi
