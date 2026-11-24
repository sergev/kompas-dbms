# KOMPAS DBMS: command line tools in Free Pascal.
#   make        build build/bin (tools) and build/lib (units for programs)
#   make test   run tests/ (needs python3)
#   make clean

FPC     ?= fpc
B       := build
BIN     := $(B)/bin
LIB     := $(B)/lib
OBJ     := $(B)/obj
FFLAGS  := -O1 -v0e -l- -Fusrc -Fusrc/rt

UNITS   := kutf krt kio mpage mtree mars kdb kgenrt sevlib
NATIVE  := mad predt gen
CONVERT := servis ttc

SRC     := $(wildcard src/*.pas src/rt/*.pas)
STAMP   := $(LIB)/.units

all: $(addprefix $(BIN)/,$(NATIVE) $(CONVERT) kpc)

# units for programs (and for the tools)
$(STAMP): $(SRC) | $(LIB)
	@for u in $(UNITS); do \
	  f=src/$$u.pas; [ -f $$f ] || f=src/rt/$$u.pas; \
	  echo "$(FPC) $$f"; $(FPC) $(FFLAGS) -FU$(LIB) $$f || exit 1; \
	done
	@touch $@

$(BIN)/%: src/%.pas $(STAMP) | $(BIN) $(OBJ)
	$(FPC) $(FFLAGS) -Fu$(LIB) -FU$(OBJ)/$* -o$@ $<

# servis and ttc are KOMPAS Pascal: through predt like any program
$(BIN)/servis $(BIN)/ttc: $(BIN)/%: src/%.pas $(BIN)/predt $(STAMP) | $(OBJ)
	@mkdir -p $(OBJ)/$*
	$(BIN)/predt $< $(OBJ)/$*/$*.pas
	$(FPC) -O1 -v0e -l- -Fu$(LIB) -FU$(OBJ)/$* -o$@ $(OBJ)/$*/$*.pas

$(BIN)/kpc: src/kpc | $(BIN)
	cp $< $@
	chmod 755 $@

$(BIN) $(LIB):
	mkdir -p $@

$(OBJ):
	mkdir -p $(addprefix $(OBJ)/,$(NATIVE) $(CONVERT))

test: all
	python3 tests/run.py

clean:
	rm -rf $(B)

.PHONY: all test clean
