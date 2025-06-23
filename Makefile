.PHONY: all build test clean run install

# Default target
all: build

# Build the project
build:
	@echo "Building Memory Defragmenter..."
	@xcodebuild -project "Memory Defragmenter.xcodeproj" \
		-scheme "Memory Defragmenter" \
		-configuration Release \
		build

# Run tests
test:
	@echo "Running tests..."
	@xcodebuild -project "Memory Defragmenter.xcodeproj" \
		-scheme "Memory Defragmenter" \
		-destination 'platform=macOS' \
		test

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@xcodebuild -project "Memory Defragmenter.xcodeproj" \
		-scheme "Memory Defragmenter" \
		clean
	@rm -rf build/
	@rm -rf DerivedData/

# Run the application
run: build
	@echo "Running Memory Defragmenter..."
	@open "build/Release/Memory Defragmenter.app"

# Install to Applications folder
install: build
	@echo "Installing to /Applications..."
	@cp -R "build/Release/Memory Defragmenter.app" /Applications/
	@echo "Memory Defragmenter installed successfully!"

# Create a DMG for distribution
dmg: build
	@echo "Creating DMG..."
	@mkdir -p dist
	@create-dmg \
		--volname "Memory Defragmenter" \
		--window-pos 200 120 \
		--window-size 600 400 \
		--icon-size 100 \
		--icon "Memory Defragmenter.app" 175 120 \
		--hide-extension "Memory Defragmenter.app" \
		--app-drop-link 425 120 \
		"dist/Memory Defragmenter.dmg" \
		"build/Release/Memory Defragmenter.app"

# Check code formatting
lint:
	@echo "Checking code formatting..."
	@swift-format lint --recursive Memory\ Defragmenter/

# Format code
format:
	@echo "Formatting code..."
	@swift-format format --recursive --in-place Memory\ Defragmenter/

# Show help
help:
	@echo "Memory Defragmenter Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build    - Build the application"
	@echo "  make test     - Run tests"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make run      - Build and run the application"
	@echo "  make install  - Install to /Applications"
	@echo "  make dmg      - Create a DMG for distribution"
	@echo "  make lint     - Check code formatting"
	@echo "  make format   - Format code"
	@echo "  make help     - Show this help message"
