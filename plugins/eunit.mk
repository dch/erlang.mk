# Copyright (c) 2014, Dave Cottlehuber <dch@skunkwerks.at>
# This file is contributed to erlang.mk and subject to the terms of the ISC License.

.PHONY: tests-eunit distclean-eunit clean-eunit build-eunit

# Configuration

EUNIT_ERLC_OPTS ?= +debug_info +warn_export_vars +warn_shadow_vars +warn_obsolete_guard
EUNIT_ERLC_OPTS += -DTEST=1 -DEXTRA=1

EUNIT_OPTS ?= {dir, "test"}, [verbose, {report,{eunit_surefire,[{dir,"logs"}]}}]

# Core targets.

tests:: tests-eunit

distclean:: distclean-eunit

help::
	@printf "%s\n" "" \
		"All modules in ebin/ will be tested with eunit, results in logs/."

# Plugin-specific targets.

EUNIT_RUN = erl \
	-no_auto_compile \
	-noshell \
	-pa $(realpath test) $(DEPS_DIR)/*/ebin \
	-pz $(realpath ebin) \
	-eval 'ok = eunit:test($(EUNIT_OPTS)).' \
	-s init stop

build-eunit:
	$(gen_verbose) erlc -v $(EUNIT_ERLC_OPTS) -I include/ -o test/ \
		$(wildcard src/*.erl src/*/*.erl) -pa ebin/

tests-eunit: ERLC_OPTS = $(EUNIT_ERLC_OPTS)
tests-eunit: clean deps app build-eunit
	$(gen_verbose) mkdir -p logs
	$(gen_verbose) $(EUNIT_RUN)

clean-eunit:
	$(gen_verbose) rm -rf test/*.beam

distclean-eunit:
	$(gen_verbose) rm -rf $(EUNIT_REPORT_DIR)
