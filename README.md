# Running single-node Kubernetes cluster on AWS

For tests that require a full version of Kubernetes with external access (hard to achieve with Kind or Microk8s) it is often easier to use a single instance of AWS with minikube.  
This Terraform module creates an instance on AWS and installs minikube on it.

## Features

* There's no need for AWS load balancer - minikube provides [metallb](https://metallb.universe.tf/) which is configured to use instance's public IP address (single `LoadBalancer` can be configured at the moment and it is used by nginx ingress controller).
* Storage is provisioned automatically using EBS volumes and `gp2` StorageClass is configured as default. You can use `standard` StorageClass which uses local volumes, but for some workloads it doesn't work (all directories have 777 perms).

## How to connect

You can connect to the instance with the ssh private key obtained with `terraform output ssh_private_key`. Save it somewhere and use `ubuntu` as a username:

```shell
PUBLIC_DNS=$(terraform output public_dns)
ssh ubuntu@PUBLIC_DNS -i $KEY 
```

To connect to Kubernetes API use `kubeconfig` output, for example:

```shell
terraform output kubeconfig > /tmp/aws-minikube-kubeconfig
export KUBECONFIG=/tmp/aws-minikube-kubeconfig
```

You can also merge it with your default kubeconfig using `konfig` plugin (install with [krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)):

```shell
kubectl konfig import --save /tmp/aws-minikube-kubeconfig
```

## Inputs## Inputs

| Name                 | Description                               | Type     | Default       | Required |
| -------------------- | ----------------------------------------- | -------- | ------------- | :------: |
| env\_name            | String used as a prefix for AWS resources | `string` | n/a           |   yes    |
| instance\_disk\_size | Instance disk size (in GB)                | `number` | `50`          |    no    |
| instance\_type       | Instance type                             | `string` | `"t3a.large"` |    no    |
| subnet\_id           | ID of the AWS subnet                      | `string` | n/a           |   yes    |
| vpc\_id              | ID of the AWS VPC                         | `string` | n/a           |   yes    |

## Outputs

| Name              | Description                                |
| ----------------- | ------------------------------------------ |
| kubeconfig        | Kubeconfig content                         |
| public\_dns       | Public DNS name of the instance            |
| public\_ip        | Public IP name of the instance             |
| ssh\_private\_key | SSH private key generated for the instance |