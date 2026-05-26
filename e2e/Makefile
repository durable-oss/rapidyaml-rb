GEM_FILE := $(shell ls -t ../pkg/*-x86_64-linux.gem 2>/dev/null | head -1)
RUBY_VERSIONS := 3.1 3.2 3.3 3.4

.PHONY: all $(RUBY_VERSIONS)

all: $(RUBY_VERSIONS)

$(RUBY_VERSIONS):
	@echo "=== ruby:$@ ==="
	docker run --rm \
		-v "$(abspath $(GEM_FILE)):/tmp/rapidyaml.gem:ro" \
		-v "$(abspath smoke.rb):/tmp/smoke.rb:ro" \
		ruby:$@ \
		sh -c 'gem install /tmp/rapidyaml.gem --no-document && ruby /tmp/smoke.rb'
