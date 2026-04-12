APP      = LML
TESTS    = LMLTestRunner
RELEASE  = .build/release/$(APP)

.PHONY: all build test run clean

all: build

build:
	swift build -c release
	cp $(RELEASE) ./$(APP)

test:
	swift run $(TESTS)

run: build
	./$(APP)

clean:
	swift package clean
	rm -f ./$(APP)
