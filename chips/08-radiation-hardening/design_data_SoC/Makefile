WORK_DIR=$(shell pwd)
TOP=top
TAG=top-run

# IMPORTANT
# ------------
# Add here the pdk from PR 819 (https://github.com/IHP-GmbH/IHP-Open-PDK/pull/819)
PDK_ROOT ?= $(WORK_DIR)/mabrains-pdk
PDK = ihp-sg13g2

.PHONY: librelane
librelane:
	PDK_ROOT=$(PDK_ROOT) PDK=$(PDK) librelane --manual-pdk --run-tag $(TAG) --overwrite config.yaml
	cp -r runs/$(TAG)/final final

.PHONY: view-results
view-results:
	PDK_ROOT=$(PDK_ROOT) PDK=$(PDK) librelane --manual-pdk --last-run --flow OpenInOpenROAD config.yaml

.PHONY: view-results-klayout
view-results-klayout:
	PDK_ROOT=$(PDK_ROOT) PDK=$(PDK) librelane --manual-pdk --last-run --flow OpenInKLayout config.yaml

.PHONY: view-results-se
view-results-se:
	PDK_ROOT=$(PDK_ROOT) PDK=$(PDK) librelane --manual-pdk --last-run --flow SynthesisExploration config.yaml