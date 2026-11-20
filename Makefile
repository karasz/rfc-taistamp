DRAFT   := draft-mery-nagy-taistamp-01
SRC     := taistamp.mmark
XML     := $(DRAFT).xml
TXT     := $(DRAFT).txt
HTML    := $(DRAFT).html

XML2RFC := xml2rfc

MMARK_URL := github.com/mmarkdown/mmark/v2@v2.2.48
MMARK ?= $(call installed_or_run,mmark,go run $(MMARK_URL))

CSPELL_PKG := cspell@10.4.0
CSPELL ?= $(call installed_or_run,cspell,npx --yes $(CSPELL_PKG))

IDNITS_PKG := @ietf-tools/idnits@3.3.0
IDNITS ?= $(call installed_or_run,idnits,npx --yes --package=$(IDNITS_PKG) idnits)
IDNITS_FLAGS := --fail-on warnings

ACTIONLINT_URL := github.com/rhysd/actionlint/cmd/actionlint@v1.7.12
ACTIONLINT ?= $(call installed_or_run,actionlint,go run $(ACTIONLINT_URL))

# check_tool,<binary>,<install hint>
check_tool = command -v $(1) >/dev/null 2>&1 || \
	{ echo "$(1) not found. $(2)"; exit 1; }

# installed_or_run,<binary>,<command>: <binary> when installed, else <command>
installed_or_run = $(if $(shell command -v $(1) 2>/dev/null),$(1),$(2))

.PHONY: all build check lint spell whitespace idnits actionlint clean update-date

all: build check

build: $(TXT) $(HTML)

update-date:
	sed -i "s|^date = .*|date = $$(date -u +%Y-%m-%dT%H:%M:%SZ)|" $(SRC)

$(XML): $(SRC)
	@$(MAKE) update-date
	$(MMARK) $< > $@~ && mv $@~ $@

$(TXT): $(XML)
	@$(call check_tool,$(XML2RFC),Install: pip install xml2rfc==3.35.0)
	$(XML2RFC) --text -o $@ $<

$(HTML): $(XML)
	@$(call check_tool,$(XML2RFC),Install: pip install xml2rfc==3.35.0)
	$(XML2RFC) --html -o $@ $<

check: lint idnits

lint: spell whitespace

spell:
	$(CSPELL) --no-progress $(SRC)

whitespace:
	@grep -Pn '\s+$$' $(SRC) && { echo "trailing whitespace found"; exit 1; } || true
	@grep -Pn '\t' $(SRC) && { echo "tabs found"; exit 1; } || true
	@grep -Pn '\r' $(SRC) && { echo "CRLF line endings found"; exit 1; } || true

idnits: $(TXT)
	$(IDNITS) $(IDNITS_FLAGS) $<

actionlint:
	$(ACTIONLINT)

clean:
	rm -f $(XML) $(TXT) $(HTML)

