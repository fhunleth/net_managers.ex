
all:
	mix deps.get
	mix compile

test:
	mix test
.PHONY: test
