#!/bin/bash

# Multi-Platform Version Management Script
# For use with SPOTS Background Agent
# Handles Android, iOS, and Web versioning

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🤖 Multi-Platform Version Management${NC}"
echo "=========================================="

# Function to get current version
get_current_version() {
    local pubspec_file="pubspec.yaml"
    if [ -f "$pubspec_file" ]; then
        local version=$(grep "^version:" "$pubspec_file" | sed 's/version: //')
        echo "$version"
    else
        echo "1.0.0+1"
    fi
}

# Function to increment version
increment_version() {
    local version="$1"
    local increment_type="$2"  # patch, minor, major
    
    # Parse version (format: 1.0.0+1)
    local version_part=$(echo "$version" | cut -d'+' -f1)
    local build_number=$(echo "$version" | cut -d'+' -f2)
    
    # Split version into parts
    local major=$(echo "$version_part" | cut -d'.' -f1)
    local minor=$(echo "$version_part" | cut -d'.' -f2)
    local patch=$(echo "$version_part" | cut -d'.' -f3)
    
    case "$increment_type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            echo "Invalid increment type. Use: major, minor, or patch"
            exit 1
            ;;
    esac
    
    # Increment build number
    build_number=$((build_number + 1))
    
    echo "${major}.${minor}.${patch}+${build_number}"
}

# Function to update pubspec.yaml
update_pubspec_version() {
    local new_version="$1"
    local pubspec_file="pubspec.yaml"
    
    if [ -f "$pubspec_file" ]; then
        # Backup original
        cp "$pubspec_file" "${pubspec_file}.backup"
        
        # Update version
        sed -i.bak "s/^version: .*/version: $new_version/" "$pubspec_file"
        
        echo -e "${GREEN}✅ Updated pubspec.yaml version to $new_version${NC}"
    else
        echo -e "${RED}❌ pubspec.yaml not found${NC}"
        exit 1
    fi
}

# Function to update Android build.gradle
update_android_version() {
    local new_version="$1"
    local build_gradle_file="android/app/build.gradle"
    
    if [ -f "$build_gradle_file" ]; then
        # Parse version parts
        local version_part=$(echo "$new_version" | cut -d'+' -f1)
        local build_number=$(echo "$new_version" | cut -d'+' -f2)
        
        # Backup original
        cp "$build_gradle_file" "${build_gradle_file}.backup"
        
        # Update versionCode and versionName
        sed -i.bak "s/flutterVersionCode = '[0-9]*'/flutterVersionCode = '$build_number'/" "$build_gradle_file"
        sed -i.bak "s/flutterVersionName = '[0-9.]*'/flutterVersionName = '$version_part'/" "$build_gradle_file"
        
        echo -e "${GREEN}✅ Updated Android build.gradle version to $new_version${NC}"
    else
        echo -e "${RED}❌ Android build.gradle not found${NC}"
        exit 1
    fi
}

# Function to update iOS version
update_ios_version() {
    local new_version="$1"
    local xcconfig_file="ios/Flutter/Generated.xcconfig"
    
    if [ -f "$xcconfig_file" ]; then
        # Parse version parts
        local version_part=$(echo "$new_version" | cut -d'+' -f1)
        local build_number=$(echo "$new_version" | cut -d'+' -f2)
        
        # Backup original
        cp "$xcconfig_file" "${xcconfig_file}.backup"
        
        # Update FLUTTER_BUILD_NAME and FLUTTER_BUILD_NUMBER
        sed -i.bak "s/FLUTTER_BUILD_NAME=.*/FLUTTER_BUILD_NAME=$version_part/" "$xcconfig_file"
        sed -i.bak "s/FLUTTER_BUILD_NUMBER=.*/FLUTTER_BUILD_NUMBER=$build_number/" "$xcconfig_file"
        
        echo -e "${GREEN}✅ Updated iOS Generated.xcconfig version to $new_version${NC}"
    else
        echo -e "${YELLOW}⚠️ iOS Generated.xcconfig not found (will be regenerated on next build)${NC}"
    fi
}

# Function to update web manifest version
update_web_version() {
    local new_version="$1"
    local manifest_file="web/manifest.json"
    
    if [ -f "$manifest_file" ]; then
        # Parse version parts
        local version_part=$(echo "$new_version" | cut -d'+' -f1)
        
        # Backup original
        cp "$manifest_file" "${manifest_file}.backup"
        
        # Add version field if it doesn't exist, or update it
        if grep -q '"version"' "$manifest_file"; then
            sed -i.bak "s/\"version\": \"[0-9.]*\"/\"version\": \"$version_part\"/" "$manifest_file"
        else
            # Add version field after name
            sed -i.bak "s/\"name\": \"spots\"/\"name\": \"spots\",\n    \"version\": \"$version_part\"/" "$manifest_file"
        fi
        
        echo -e "${GREEN}✅ Updated web manifest.json version to $version_part${NC}"
    else
        echo -e "${RED}❌ Web manifest.json not found${NC}"
        exit 1
    fi
}

# Function to validate version format
validate_version() {
    local version="$1"
    
    # Check if version matches format X.Y.Z+N
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to create version commit
create_version_commit() {
    local new_version="$1"
    local commit_message="$2"
    
    # Add all version-related files
    git add pubspec.yaml android/app/build.gradle web/manifest.json
    
    # Add iOS file if it exists
    if [ -f "ios/Flutter/Generated.xcconfig" ]; then
        git add ios/Flutter/Generated.xcconfig
    fi
    
    if [ -n "$commit_message" ]; then
        git commit -m "Bump version to $new_version - $commit_message"
        echo -e "${GREEN}✅ Created version commit: $new_version${NC}"
    else
        git commit -m "Bump version to $new_version"
        echo -e "${GREEN}✅ Created version commit: $new_version${NC}"
    fi
}

# Function to update all platforms
update_all_platforms() {
    local new_version="$1"
    local commit_message="$2"
    
    echo -e "${BLUE}🔄 Updating all platform versions...${NC}"
    
    # Update pubspec.yaml (Flutter)
    update_pubspec_version "$new_version"
    
    # Update Android
    update_android_version "$new_version"
    
    # Update iOS
    update_ios_version "$new_version"
    
    # Update Web
    update_web_version "$new_version"
    
    echo -e "${GREEN}✅ All platform versions updated to $new_version${NC}"
}

# Function to check platform status
check_platform_status() {
    echo -e "${BLUE}📱 Platform Version Status:${NC}"
    
    # Get current version
    local current_version=$(get_current_version)
    echo -e "  Flutter (pubspec.yaml): $current_version"
    
    # Check Android
    if [ -f "android/app/build.gradle" ]; then
        local android_version=$(grep "flutterVersionName" android/app/build.gradle | sed "s/.*flutterVersionName = '//" | sed "s/'.*//")
        local android_build=$(grep "flutterVersionCode" android/app/build.gradle | sed "s/.*flutterVersionCode = '//" | sed "s/'.*//")
        echo -e "  Android: $android_version+$android_build"
    else
        echo -e "  Android: ❌ Not found"
    fi
    
    # Check iOS
    if [ -f "ios/Flutter/Generated.xcconfig" ]; then
        local ios_version=$(grep "FLUTTER_BUILD_NAME" ios/Flutter/Generated.xcconfig | sed "s/FLUTTER_BUILD_NAME=//")
        local ios_build=$(grep "FLUTTER_BUILD_NUMBER" ios/Flutter/Generated.xcconfig | sed "s/FLUTTER_BUILD_NUMBER=//")
        echo -e "  iOS: $ios_version+$ios_build"
    else
        echo -e "  iOS: ⚠️ Generated.xcconfig not found"
    fi
    
    # Check Web
    if [ -f "web/manifest.json" ]; then
        if grep -q '"version"' web/manifest.json; then
            local web_version=$(grep '"version"' web/manifest.json | sed 's/.*"version": "//' | sed 's/".*//')
            echo -e "  Web: $web_version"
        else
            echo -e "  Web: ⚠️ No version field found"
        fi
    else
        echo -e "  Web: ❌ Not found"
    fi
}

# Main execution
main() {
    local action="$1"
    local increment_type="$2"
    local commit_message="$3"
    
    case "$action" in
        "get")
            local current_version=$(get_current_version)
            echo -e "${BLUE}Current version: $current_version${NC}"
            ;;
        "status")
            check_platform_status
            ;;
        "increment")
            if [ -z "$increment_type" ]; then
                echo -e "${RED}❌ Please specify increment type: patch, minor, or major${NC}"
                exit 1
            fi
            
            local current_version=$(get_current_version)
            local new_version=$(increment_version "$current_version" "$increment_type")
            
            echo -e "${BLUE}Current version: $current_version${NC}"
            echo -e "${BLUE}New version: $new_version${NC}"
            
            # Validate new version
            if [ "$(validate_version "$new_version")" = "true" ]; then
                update_all_platforms "$new_version" "$commit_message"
                
                if [ "$4" = "--commit" ]; then
                    create_version_commit "$new_version" "$commit_message"
                fi
                
                echo -e "${GREEN}🎉 All platform versions updated successfully!${NC}"
            else
                echo -e "${RED}❌ Invalid version format: $new_version${NC}"
                exit 1
            fi
            ;;
        "validate")
            local version="$2"
            if [ "$(validate_version "$version")" = "true" ]; then
                echo -e "${GREEN}✅ Valid version format: $version${NC}"
            else
                echo -e "${RED}❌ Invalid version format: $version${NC}"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 {get|status|increment|validate} [increment_type] [commit_message] [--commit]"
            echo ""
            echo "Commands:"
            echo "  get                    - Get current version"
            echo "  status                 - Check all platform versions"
            echo "  increment <type>       - Increment version (patch|minor|major)"
            echo "  validate <version>     - Validate version format"
            echo ""
            echo "Examples:"
            echo "  $0 get"
            echo "  $0 status"
            echo "  $0 increment patch"
            echo "  $0 increment minor --commit 'Add new feature'"
            echo "  $0 validate 1.2.3+4"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 