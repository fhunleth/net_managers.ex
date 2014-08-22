all: $(patsubst %.dot,%.pdf,$(wildcard *.dot))

%.pdf: %.dot
	dot -Tpdf -o $@ $<

clean:
	rm -f *.pdf
