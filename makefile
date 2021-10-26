# Copyright 2021 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

path ?= kubernetes

all: 0-fetch-k8s 1-build-binaries 2-vagrant-up 3-smoke-test

0: 0-fetch-k8s
1: 1-build-binaries
2: 2-vagrant-up
3: 3-smoke-test

0-fetch-k8s:
	chmod +x fetch.sh
	./fetch.sh

1-build-binaries:
	chmod +x build.sh
	./build.sh $(path)

2-vagrant-up:
	echo "cleaning up semaphores..."
	rm -f up joined cni

	echo "installing vagrant vbguest plugin..."
	#vagrant plugin install vagrant-vbguest

	echo "######################################"
	echo "Retry vagrant up if the first time the windows node failed"
	echo "Starting the control plane"
	echo "######################################"
	vagrant up controlplane
	
	echo "*********** vagrant up first run done ~~~~ ENTERING WINDOWS BRINGUP LOOP ***"
	until `vagrant status | grep winw1 | grep -q "running"` ; do vagrant up winw1 || echo failed_win_up ; done
	touch up
	until `vagrant ssh controlplane -c "kubectl get nodes" | grep -q winw1` ; do vagrant provision winw1 || echo failed_win_join; done
	touch joined
	vagrant provision winw1
	touch cni

3-smoke-test:
	vagrant ssh controlplane -c "kubectl scale deployment whoami-windows --replicas 0"
	vagrant ssh controlplane -c "kubectl scale deployment whoami-windows --replicas 3"
	vagrant ssh controlplane -c "kubectl get pods; sleep 5"
	vagrant ssh controlplane -c "kubectl exec -it netshoot -- curl http://whoami-windows:80/"

# TODO
#4-e2e-test:
#	sonobuoy run --e2e-focus=...
