# kcli-playground

This repository try to be a proof of concept which leverage kcli tool for
deploying a cluster into the workstation, defining the profiles that are
helpful.

## Install kcli

From Fedora just run:

```shell
make kcli-prepare-sys
```

You could need to reboot or login again.

Now install kcli by:

```shell
make kcli-install
```

## Create OpenShift 4.7 cluster

Create a symbolic link to the profile:

```shell
ln -svf profiles/openshift-47-latest.yml kcli_parameters.yml
KUBE_NAME=mykube make kcli-create
```
