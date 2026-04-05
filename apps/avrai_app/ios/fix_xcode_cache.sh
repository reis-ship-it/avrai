#!/bin/bash
# Workaround script for Xcode 16.2 module cache bug
# Run this before building iOS

echo "Fixing Xcode 16.2 module cache issues..."

# Create module cache directory
mkdir -p ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
chmod 755 ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# Create Session.modulevalidation file
touch ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation
chmod 644 ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/Session.modulevalidation

# Create SDK stat cache directory
mkdir -p ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex
chmod 755 ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex

# Create common SDK cache files
touch ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/iphonesimulator18.2-22C146-07b28473f605e47e75261259d3ef3b5a.sdkstatcache
chmod 644 ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/iphonesimulator18.2-22C146-07b28473f605e47e75261259d3ef3b5a.sdkstatcache

echo "Cache files created. You may need to run this before each build."

