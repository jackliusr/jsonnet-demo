.PHONY: all clean

all: clean
	tk export yaml environments/default

clean:
	rm -rf ./yaml
