.PHONY: all build clean run release debug

# Swift source files (from src/)
SWIFT_SOURCES := $(shell find src -name '*.swift')
CPUS := $(shell sysctl -n hw.logicalcpu)

# Default target
all: build

# ---- Development (fast) build ----
debug: uncapturable.app/Contents/MacOS/uncapturable-debug uncapturable.app/Contents/Info.plist uncapturable.app/Contents/Resources/App.icns

uncapturable.app/Contents/MacOS/uncapturable-debug:
	mkdir -p uncapturable.app/Contents/MacOS uncapturable.app/Contents/Resources
	swiftc -Onone -g -suppress-warnings -incremental \
		-j $(CPUS) \
		-o uncapturable.app/Contents/MacOS/uncapturable-debug \
		$(SWIFT_SOURCES)

# ---- Release (optimized) build ----
release: uncapturable.app/Contents/MacOS/uncapturable uncapturable.app/Contents/Info.plist uncapturable.app/Contents/Resources/App.icns

uncapturable.app/Contents/MacOS/uncapturable:
	mkdir -p uncapturable.app/Contents/MacOS uncapturable.app/Contents/Resources
	swiftc -O -whole-module-optimization -suppress-warnings \
		-j $(CPUS) \
		-o uncapturable.app/Contents/MacOS/uncapturable \
		$(SWIFT_SOURCES)

# Common files
uncapturable.app/Contents/Info.plist: src/Info.plist
	cp $< $@

uncapturable.app/Contents/Resources/App.icns: src/App.icns
	cp $< $@

# Cleanup
clean:
	rm -rf uncapturable.app

# Run (build if missing)
run:
	@if [ ! -d "uncapturable.app" ]; then \
		$(MAKE) release || exit $$?; \
	fi
	@open "uncapturable.app"
