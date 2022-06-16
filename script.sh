#!bin/sh


helm_status_1=$(helm status sonarqube -n sonarqube -o json | jq .status.phase -r)
helm_status_2=$(helm status sonatype-nexus -n nexus -o json | jq .status.phase -r)

kubernetes_status=$(kubectl get namespace jmeter -o json | jq .status.phase -r) 

## Checking if Kubernetes files are Present


if [[ $kubernetes_status == "Active" ]]

then

    echo "Kubernetes Namespace is already present. Hence removing..."
    
    kubectl delete namespace jmeter
    
    
else

    echo "Creating Kubernetes Files..."
    
    kubectl create namespace jmeter
    kubectl apply -f jmeter_master_deploy.yaml
    kubectl apply -f jmeter_slaves_deploy.yaml
    kubectl apply -f jmeter_master_configmap.yaml
    kubectl apply -f jmeter_slaves_svc.yaml

fi

## Checking if Helm files are Present

if [[ $helm_status_1 == "null" && $helm_status_2 == "null" ]]

then

    echo "Helm Files are already present. Hence removing..."
    
    kubectl delete namespace sonarqube
    kubectl delete namespace nexus
    helm repo remove oteemocharts
    helm repo update

else

    echo "Creating Helm Files..."
    
    helm repo add oteemocharts https://oteemo.github.io/charts
    helm repo update
    kubectl create namespace sonarqube
    kubectl create namespace nexus    
    helm install sonarqube oteemocharts/sonarqube -n sonarqube
    helm install sonatype-nexus oteemocharts/sonatype-nexus -n nexus

fi

