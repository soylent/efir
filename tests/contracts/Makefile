sources := $(wildcard *.sol)
contracts := $(sources:.sol=.json)

all: $(contracts)

clean:
	rm -f $(contracts)

%.json: %.sol
	solc --combined-json=bin,abi $^ > $@

.PHONY: all clean
