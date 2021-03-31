KCLI = $(shell bash -c 'command -v kcli')

KUBE_NAME ?= mykube


.PHONY: kcli-prepare-sys
kcli-prepare-sys:
	sudo usermod -aG qemu,libvirt $(shell id -un)
	# newgrp libvirt
	sudo systemctl enable --now libvirtd
	# sudo groupadd docker
	# sudo usermod -aG docker $(shell id -un)
	# sudo systemctl restart docker
	# sudo usermod -aG qemu,libvirt $(shell id -un)

.PHONY: kcli-install
kcli-install:
ifeq (,$(KCLI))
	sudo dnf -y copr enable karmab/kcli
	sudo dnf -y install kcli
	[ -e "$(PWD)/.images" ] || mkdir -p $(PWD)/.images
	kcli create pool -p $(PWD)/.images kcli
	sudo setfacl -m u:$(shell id -un):rwx $(PWD)/.images
	kcli create network -c 192.168.122.0/24 default
endif


.PHONY: kcli
kcli:
ifeq (,$(KCLI))
	@bash -c 'command -v kcli' 2>/dev/null 1>/dev/null || { \
	$(MAKE) kcli-prepare-sys kcli-install \
	}
endif


.PHONY: kcli-create
kcli-create: kcli
	kcli create cluster openshift $(KUBE_NAME)
	@echo "To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=$(HOME)/.kcli/clusters/$(KUBE_NAME)/auth/kubeconfig'"


.PHONY: kcli-delete
kcli-delete: kcli
	kcli delete cluster -y $(KUBE_NAME)
