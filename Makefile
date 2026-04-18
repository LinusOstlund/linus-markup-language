APP      = LML
TESTS    = LMLTestRunner
RELEASE  = .build/release/$(APP)

.PHONY: all build test run clean release

all: build

build:
	swift build -c release
	mkdir -p $(APP).app/Contents/MacOS
	mkdir -p $(APP).app/Contents/Resources
	cp $(RELEASE) $(APP).app/Contents/MacOS/$(APP)
	cp Sources/LML/Resources/Info.plist $(APP).app/Contents/
	cp Sources/LML/Resources/AppIcon.icns $(APP).app/Contents/Resources/ 2>/dev/null || true
	codesign -fs - $(APP).app

test:
	swift run $(TESTS)

run: build
	open $(APP).app

release:
	@LAST=$$(git tag --sort=-v:refname | head -1 | sed 's/^v//'); \
	if [ -z "$$LAST" ]; then NEXT="0.1.0"; \
	else NEXT=$$(echo "$$LAST" | awk -F. '{print $$1"."$$2"."$$3+1}'); fi; \
	echo "Releasing v$$NEXT (last: $${LAST:-none})"; \
	git tag -a "v$$NEXT" -m "v$$NEXT" --no-sign && git push origin main "v$$NEXT"

clean:
	swift package clean
	rm -rf ./$(APP).app
	rm -f ./$(APP)
