APP      = LML
TESTS    = LMLTests
SWIFTC   = swiftc
FRAMEWORKS = -framework Cocoa -framework Carbon

.PHONY: all build test run clean

all: build

build:
	$(SWIFTC) $(APP).swift $(FRAMEWORKS) -o $(APP)

test:
	$(SWIFTC) $(TESTS).swift -o $(TESTS) && ./$(TESTS)

run: build
	./$(APP)

clean:
	rm -f $(APP) $(TESTS)
