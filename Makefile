APP      = LML
TESTS    = LMLTestRunner
RELEASE  = .build/release/$(APP)

.PHONY: all build test run clean release

all: build

build:
	swift build -c release
	cp $(RELEASE) ./$(APP)
	codesign -fs - ./$(APP)

test:
	swift run $(TESTS)

run: build
	./$(APP)

release:
	@LAST=$$(git tag --sort=-v:refname | head -1 | sed 's/^v//'); \
	if [ -z "$$LAST" ]; then NEXT="0.1.0"; \
	else NEXT=$$(echo "$$LAST" | awk -F. '{print $$1"."$$2"."$$3+1}'); fi; \
	echo "Releasing v$$NEXT (last: $${LAST:-none})"; \
	git tag "v$$NEXT" && git push origin main "v$$NEXT"

clean:
	swift package clean
	rm -f ./$(APP)
