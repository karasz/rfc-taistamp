DRAFT   := draft-mery-nagy-taistamp-00
SRC     := taistamp.mmark
XML     := $(DRAFT).xml
TXT     := $(DRAFT).txt
HTML    := $(DRAFT).html

MMARK   := mmark
XML2RFC := xml2rfc
CSPELL  := cspell
IDNITS  := idnits

# check_tool,<binary>,<install hint>
check_tool = command -v $(1) >/dev/null 2>&1 || \
	{ echo "$(1) not found. $(2)"; exit 1; }

.PHONY: all build check lint spell whitespace idnits clean update-date

all: build check

build: $(TXT) $(HTML)

update-date:
	sed -i "s|^date = .*|date = $$(date -u +%Y-%m-%dT%H:%M:%SZ)|" $(SRC)

$(XML): $(SRC)
	@$(MAKE) update-date
	@$(call check_tool,$(MMARK),Install: go install github.com/mmarkdown/mmark/v2@latest)
	$(MMARK) $< > $@~ && mv $@~ $@

$(TXT): $(XML)
	@$(call check_tool,$(XML2RFC),Install: pip install xml2rfc)
	$(XML2RFC) --text -o $@ $<

$(HTML): $(XML)
	@$(call check_tool,$(XML2RFC),Install: pip install xml2rfc)
	$(XML2RFC) --html -o $@ $<

check: lint idnits

lint: spell whitespace

spell:
	@$(call check_tool,$(CSPELL),Install: npm install -g cspell)
	$(CSPELL) --no-progress $(SRC)

whitespace:
	@grep -Pn '\s+$$' $(SRC) && { echo "trailing whitespace found"; exit 1; } || true
	@grep -Pn '\t' $(SRC) && { echo "tabs found"; exit 1; } || true
	@grep -Pn '\r' $(SRC) && { echo "CRLF line endings found"; exit 1; } || true

idnits: $(TXT)
	@$(call check_tool,$(IDNITS),Install: https://author-tools.ietf.org/idnits)
	$(IDNITS) $<

clean:
	rm -f $(XML) $(TXT) $(HTML)

