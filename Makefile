.PHONY: all clean

all: clean
	tk export vs environments/default

clean:
	rm -rf ./vs
