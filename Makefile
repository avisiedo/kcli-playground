KCLI = $(shell bash -c 'command -v kcli')

KCLI_KUBE ?= mykube
KCLI_POOL ?= kcli


.PHONY: help
help:
	@cat HELP

.PHONY: read-cluster-ip
read-cluster-ip:
	sudo virsh dumpxml $(KCLI_KUBE)-master-0 | xq |

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
	kcli create pool -p $(PWD)/.images $(KCLI_POOL)
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
	kcli create cluster openshift $(KCLI_KUBE)
	@[ -e /etc/dnsmasq.d/kcli ] || sudo mkdir -p /etc/dnsmasq.d/kcli
	@[ -e /etc/dnsmasq.d/kcli.conf ] || sudo cp -f config/dnsmasq.d/kcli.conf /etc/dnsmasq.d/kcli.conf
	$(eval KCLI_VM_NETWORK := $(shell sudo virsh dumpxml $(KCLI_KUBE)-master-0 | xq | jq -r '.domain.devices.interface.source."@network"'))
	$(eval KCLI_VM_IP := $(shell kcli info vm $(KCLI_KUBE)-master-0 -f ip | yq -r .ip ))
	$(eval KCLI_VM_IP_INVERSE := $(shell echo '$(KCLI_VM_IP)' | awk -F. '{ print $$4"."$$3"."$$2"."$$1 }'))
	@KCLI_KUBE="$(KCLI_KUBE)" KCLI_VM_IP="$(KCLI_VM_IP)" KCLI_VM_IP_INVERSE="$(KCLI_VM_IP_INVERSE)" \
	    envsubst < config/dnsmasq.d/kube.conf.envsubst | sudo tee "/etc/dnsmasq.d/kcli/$(KCLI_KUBE).conf" > /dev/null
	@sudo systemctl reload NetworkManager.service
	@echo "To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=$(HOME)/.kcli/clusters/$(KCLI_KUBE)/auth/kubeconfig'"


.PHONY: kcli-kubeadmin-password
kcli-kubeadmin-password:
	@cat ~/.kcli/clusters/$(KCLI_KUBE)/auth/kubeadmin-password; echo ""


.PHONY: kcli-delete
kcli-delete: kcli
	kcli delete cluster -y $(KCLI_KUBE)
	sudo rm -vf /etc/dnsmasq.d/kcli/$(KCLI_KUBE).conf
