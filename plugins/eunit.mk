# Copyright (c) 2014, Enrique Fernandez <enrique.fernandez@erlang-solutions.com>
# This file is contributed to erlang.mk and subject to the terms of the ISC License.

.PHONY: help-eunit build-eunit eunit distclean-eunit

# Configuration

EUNIT_ERLC_OPTS ?= +debug_info +warn_export_vars +warn_shadow_vars +warn_obsolete_guard -DTEST=1 -DEXTRA=1

EUNIT_DIR ?=
EUNIT_DIRS = $(sort $(EUNIT_DIR) ebin)

# All modules in EUNIT_DIR
EUNIT_DIR_MODS = $(notdir $(basename $(shell find $(EUNIT_DIR) -name *.beam)))
# All modules in 'ebin'
EUNIT_EBIN_MODS = $(notdir $(basename $(shell find ebin -name *.beam)))
# Only those modules in EUNIT_DIR with no matching module in 'ebin'.
# This is done to avoid some tests being executed twice.
EUNIT_MODS = $(filter-out $(patsubst %,%_tests,$(EUNIT_EBIN_MODS)),$(EUNIT_DIR_MODS))
TAGGED_EUNIT_TESTS = {dir,"ebin"} $(foreach mod,$(EUNIT_MODS),$(shell echo $(mod) | sed -e 's/\(.*\)/{module,\1}/g'))

EUNIT_OPTS ?= verbose, {report,{eunit_surefire,[{dir,"logs"}]}}

# Utility functions

define str-join
	$(shell echo '$(strip $(1))' | sed -e "s/ /,/g")
endef

# Core targets.

help:: help-eunit

tests:: eunit

clean:: clean-eunit

distclean:: distclean-eunit

# Plugin-specific targets.

EUNIT_RUN = erl \
	-no_auto_compile \
	-noshell \
	-pa $(realpath $(EUNIT_DIR)) $(DEPS_DIR)/*/ebin \
	-pz $(realpath ebin) \
	-eval 'eunit:test([$(call str-join,$(TAGGED_EUNIT_TESTS))], [$(EUNIT_OPTS)]).' \
	-s erlang halt

help-eunit:
	@printf "%s\n" "" \
		"EUnit targets:" \
		"  eunit       Run all the EUnit tests for this project"

ifeq ($(strip $(EUNIT_DIR)),)
build-eunit:
else ifeq ($(strip $(EUNIT_DIR)),ebin)
build-eunit:
else
build-eunit:
	$(gen_verbose) erlc -v $(EUNIT_ERLC_OPTS) -I include/ -o $(EUNIT_DIR) \
		$(wildcard $(EUNIT_DIR)/*.erl $(EUNIT_DIR)/*/*.erl) -pa ebin/
endif

eunit: ERLC_OPTS = $(EUNIT_ERLC_OPTS)
eunit: clean deps app build-eunit
	@echo '$(EUNIT_OPTS)' | perl -ne \
		'mkdir $$1 if /{\s*report\s*,\s*{\s*eunit_surefire\s*,\s*\[.*{\s*dir\s*,\s*"(.*)"\s*}.*\]\s*}\s*}/'
	@echo "EUNIT_DIR = " $(EUNIT_DIR)
	@echo "EUNIT_DIR_MODS = " $(EUNIT_DIR_MODS)
	@echo "EUNIT_MODS = " $(EUNIT_MODS)
	@echo "TAGGED_EUNIT_TESTS = " '$(TAGGED_EUNIT_TESTS)'
	$(gen_verbose) $(EUNIT_RUN)

clean-eunit:
	$(gen_verbose) $(foreach dir,$(EUNIT_DIRS),rm -rf $(dir)/*.beam)

distclean-eunit:
	@echo '$(EUNIT_OPTS)' | perl -ne \
		'use File::Path rmtree; rmtree $$1 if /{\s*report\s*,\s*{\s*eunit_surefire\s*,\s*\[.*{\s*dir\s*,\s*"(.*)"\s*}.*\]\s*}\s*}/'
