package test

import (
	"io/ioutil"
	"os"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/terraform"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func TestTerraformAwsMinikubeWithDefaultVpc(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/default-vpc",
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApplyAndIdempotent(t, terraformOptions)

	kubeconfig_file, _ := ioutil.TempFile("/tmp", "terraform_aws_minikube_test")
	defer os.Remove(kubeconfig_file.Name())

	kubeconfig := terraform.Output(t, terraformOptions, "kubeconfig")
	kubeconfig_file.Write([]byte(kubeconfig))
	kubeconfig_file.Close()

	t.Logf("Wrote kubeconfig to %v", kubeconfig_file.Name())

	// metallb
	options_metallb := k8s.NewKubectlOptions("", kubeconfig_file.Name(), "metallb-system")
	k8s.WaitUntilNumPodsCreated(t, options_metallb, metav1.ListOptions{LabelSelector: "app=metallb"}, 2, 20, time.Second*10)

	// nginx ingress
	options_default := k8s.NewKubectlOptions("", kubeconfig_file.Name(), "default")
	k8s.WaitUntilServiceAvailable(t, options_default, "ingress-ingress-nginx-controller", 20, time.Second*10)

	// metrics-server
	options_kubesystem := k8s.NewKubectlOptions("", kubeconfig_file.Name(), "kube-system")
	k8s.WaitUntilServiceAvailable(t, options_kubesystem, "metrics-server", 20, time.Second*10)

}
