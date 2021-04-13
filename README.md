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

- Create a symbolic link to the profile:

  ```shell
  ln -svf profiles/openshift-47-latest.yml kcli_parameters.yml
  make kcli-create
  ```

- If you lost the chance to set up dnsmasq (sudo actions are required),
  you can repeat them by:

  ```shell
  make kcli-setup-dnsmasq
  ```

## Delete the cluster

Using the same profile, it only needs to execute:

```shell
make kcli-delete
```
