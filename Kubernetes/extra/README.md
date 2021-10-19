## Miscellaneous yaml file examples

#### to test flagger you can follow the below

below instructions follow closely with this - https://docs.flagger.app/tutorials/contour-progressive-delivery, you should read this link as well

##### create namespace
```shell
kubectl create ns test
```

##### create load tester
```shell
kubectl apply -k https://github.com/fluxcd/flagger//kustomize/tester?ref=main
```

##### create deployment and hpa
```shell
kubectl apply -k https://github.com/fluxcd/flagger//kustomize/podinfo?ref=main
```

##### create canary config
```shell
kubectl apply -f ./files/flagger/example-podinfo-canary.yaml
```

##### add tls delegation for test namespace to pickup proper secret
```shell
kubectl apply -f ./files/flagger/example-tls-delegation.yaml
```

##### expose deployment via httpproxy
```shell
kubectl apply -f ./files/flagger/example-httpproxy.yaml
```

##### Eveything is setup now
##### to initiate a canary deployment you need to change the image in the podinfo deployment

```shell
kubectl -n test set image deployment/podinfo podinfod=stefanprodan/podinfo:3.1.1
```
##### you can switch the pod image tag between 3.1.2 and 3.1.1 to simulate a canary deployment

##### look at canary
```shell
kubectl -n test describe canary/podinfo
```

##### watch canary
```shell
kubectl get canaries --all-namespaces --watch
```
