#!bin/sh

helm repo add oteemocharts https://oteemo.github.io/charts
helm repo update

helm install sonarqube oteemocharts/sonarqube
helm install sonatype-nexus oteemocharts/sonatype-nexus

kubectl apply -f jmeter_master_deploy.yaml
kubectl apply -f jmeter_slaves_deploy.yaml
kubectl apply -f jmeter_master_configmap.yaml
kubectl apply -f jmeter_slaves_svc.yaml

kubectl expose service sonarqube-sonarqube --type=NodePort --target-port=9000 --name=sonarqube

