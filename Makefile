KCLI = $(shell bash -c 'command -v kcli')

KCLI_KUBE := $(shell yq -r .cluster kcli_parameters.yml)
KCLI_POOL := $(shell yq -r .pool kcli_parameters.yml)


.PHONY: help
help:
	@cat HELP

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
	kcli create network -c 192.168.122.0/24 default
endif


.PHONY: kcli
kcli:
ifeq (,$(KCLI))
	@bash -c 'command -v kcli' 2>/dev/null 1>/dev/null || { \
	make kcli-prepare-sys kcli-install \
	}
endif


.PHONY: kcli-create
kcli-create: kcli
	-mkdir -p $(PWD)/.images/$(KCLI_POOL)
	-kcli create pool -p $(PWD)/.images/$(KCLI_POOL) $(KCLI_POOL)
	sudo setfacl -m u:$(shell id -un):rwx $(PWD)/.images/$(KCLI_POOL)
	kcli create cluster openshift $(KCLI_KUBE)
	-@sudo mkdir -p /etc/dnsmasq.d/kcli
	-@sudo cp -f config/dnsmasq.d/kcli.conf /etc/dnsmasq.d/kcli.conf
	@ \
	KCLI_KUBE="$(KCLI_KUBE)" \
	KCLI_VM_NETWORK="$$( sudo virsh dumpxml $(KCLI_KUBE)-master-0 | xq | jq -r '.domain.devices.interface.source."@network"'))" \
	KCLI_VM_IP="$$( $(KCLI) info vm $(KCLI_KUBE)-master-0 -f ip | yq -r .ip )" \
	KCLI_VM_IP_INVERSE="$$( echo '$(KCLI_VM_IP)' | awk -F. '{ print $$4"."$$3"."$$2"."$$1 }')" \
	envsubst < config/dnsmasq.d/kube.conf.envsubst | sudo tee "/etc/dnsmasq.d/kcli/$(KCLI_KUBE).conf" > /dev/null
	@sudo systemctl reload NetworkManager.service
	@echo "To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=$(HOME)/.kcli/clusters/$(KCLI_KUBE)/auth/kubeconfig'"


.PHONY: demo
demo:
	@ \
	KCLI_VM_NETWORK="default" \
	KCLI_VM_IP="192.168.1.12" \
	KCLI_VM_IP_INVERSE="12.1.168.192" \
	envsubst < config/dnsmasq.d/kube.conf.envsubst



.PHONY: kcli-kubeadmin-password
kcli-kubeadmin-password:
	@cat ~/.kcli/clusters/$(KCLI_KUBE)/auth/kubeadmin-password; echo ""


.PHONY: kcli-delete
kcli-delete: kcli
	kcli delete cluster -y $(KCLI_KUBE)
	sudo rm -vf /etc/dnsmasq.d/kcli/$(KCLI_KUBE).conf
	@sudo systemctl reload NetworkManager.service
