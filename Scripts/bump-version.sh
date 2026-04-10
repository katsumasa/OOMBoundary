#!/bin/bash

# Version Bump Script for OOMBoundary
# Usage: ./bump-version.sh [major|minor|patch]

set -e

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
PLIST_PATH="${PROJECT_DIR}/OOMBoundary.xcodeproj/project.pbxproj"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔢 OOMBoundary Version Bump Tool${NC}"
echo ""

# Get current version using agvtool
cd "${PROJECT_DIR}"
CURRENT_VERSION=$(xcrun agvtool what-marketing-version -terse1 2>/dev/null || echo "1.0.0")

echo -e "Current Version: ${YELLOW}${CURRENT_VERSION}${NC}"

# Parse version
IFS='.' read -r MAJOR MINOR PATCH <<< "${CURRENT_VERSION}"

# Default to patch if not specified
BUMP_TYPE="${1:-patch}"

case "${BUMP_TYPE}" in
    major)
        NEW_MAJOR=$((MAJOR + 1))
        NEW_MINOR=0
        NEW_PATCH=0
        NEW_VERSION="${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}"
        echo -e "${GREEN}📈 Major version bump${NC}"
        ;;
    minor)
        NEW_MAJOR=${MAJOR}
        NEW_MINOR=$((MINOR + 1))
        NEW_PATCH=0
        NEW_VERSION="${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}"
        echo -e "${GREEN}📈 Minor version bump${NC}"
        ;;
    patch)
        NEW_MAJOR=${MAJOR}
        NEW_MINOR=${MINOR}
        NEW_PATCH=$((PATCH + 1))
        NEW_VERSION="${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}"
        echo -e "${GREEN}📈 Patch version bump${NC}"
        ;;
    *)
        echo -e "${RED}❌ Invalid bump type: ${BUMP_TYPE}${NC}"
        echo "Usage: $0 [major|minor|patch]"
        exit 1
        ;;
esac

echo -e "New Version:     ${GREEN}${NEW_VERSION}${NC}"
echo ""

# Confirmation
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠️  Cancelled${NC}"
    exit 0
fi

# Update version using agvtool
echo -e "${BLUE}📝 Updating version...${NC}"
xcrun agvtool new-marketing-version "${NEW_VERSION}"

# Also increment build number
CURRENT_BUILD=$(xcrun agvtool what-version -terse 2>/dev/null || echo "1")
NEW_BUILD=$((CURRENT_BUILD + 1))
echo -e "${BLUE}📝 Incrementing build number: ${CURRENT_BUILD} → ${NEW_BUILD}${NC}"
xcrun agvtool new-version -all "${NEW_BUILD}"

echo ""
echo -e "${GREEN}✅ Version updated successfully!${NC}"
echo -e "   Version: ${CURRENT_VERSION} → ${GREEN}${NEW_VERSION}${NC}"
echo -e "   Build:   ${CURRENT_BUILD} → ${GREEN}${NEW_BUILD}${NC}"
echo ""

# Git operations (optional)
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${BLUE}📌 Git operations:${NC}"

    # Check for uncommitted changes
    if [[ -n $(git status -s) ]]; then
        echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
        read -p "Commit version bump? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add .
            git commit -m "Bump version to ${NEW_VERSION} (Build ${NEW_BUILD})"
            echo -e "${GREEN}✅ Changes committed${NC}"

            read -p "Create git tag v${NEW_VERSION}? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git tag "v${NEW_VERSION}"
                echo -e "${GREEN}✅ Tag v${NEW_VERSION} created${NC}"
                echo -e "${YELLOW}💡 Don't forget to push: git push && git push --tags${NC}"
            fi
        fi
    else
        read -p "Create git tag v${NEW_VERSION}? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag "v${NEW_VERSION}"
            echo -e "${GREEN}✅ Tag v${NEW_VERSION} created${NC}"
            echo -e "${YELLOW}💡 Don't forget to push: git push --tags${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}✨ Done!${NC}"
