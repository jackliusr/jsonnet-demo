.PHONY: all clean

all: clean
	tk export yaml environments/default
	test -s kustomization.yaml || kustomize init
	kustomize edit add resource yaml/networking.istio.io-v1beta1.Gateway-gw-*.yaml

clean:
	rm -rf ./yaml
