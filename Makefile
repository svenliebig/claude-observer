.PHONY: build install uninstall run stop clean

OBSERVER_DIR = $(HOME)/.claude-observer
BINARY = $(OBSERVER_DIR)/bin/claude-observer

build:
	@mkdir -p $(OBSERVER_DIR)/bin $(OBSERVER_DIR)/web
	swiftc -O -o $(BINARY) Sources/main.swift -framework Cocoa -framework Network
	@cp -f web/index.html $(OBSERVER_DIR)/web/index.html 2>/dev/null || true
	@echo "Built: $(BINARY)"

install:
	python3 scripts/install.py

uninstall:
	python3 scripts/uninstall.py

run: build
	@$(BINARY) &
	@echo "Claude Observer is running."

stop:
	@pkill -x claude-observer 2>/dev/null && echo "Stopped." || echo "Not running."

clean:
	@rm -f $(OBSERVER_DIR)/bin/claude-observer
	@rm -rf $(OBSERVER_DIR)/sessions/*.json
	@echo "Cleaned."
