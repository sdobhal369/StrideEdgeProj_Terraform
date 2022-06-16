#!bin/sh


helm_status=$(helm status sonarqube -n sonarqube -o json | jq .status.phase -r)

kubernetes_status_1=$(kubectl get namespace jmeter -o json | jq .status.phase -r) 
kubernetes_status_2=$(kubectl get namespace nexus -o json | jq .status.phase -r)

## Checking if Helm files are Present

if [[ $helm_status_1 == "null" ]]

then

    echo "Helm Files are already present. Hence removing..."
    
    kubectl delete namespace sonarqube
    helm repo remove oteemocharts
    helm repo update

else

    echo "Creating Helm Files..."
    
    helm repo add oteemocharts https://oteemo.github.io/charts
    helm repo update
    kubectl create namespace sonarqube    
    helm install sonarqube oteemocharts/sonarqube -n sonarqube

fi

## Checking if Kubernetes files are Present


if [[ $kubernetes_status_1 == "Active" && $kubernetes_status_2 == "Active" ]]

then

    echo "Kubernetes Namespace is already present. Hence removing..."
    
    kubectl delete namespace nexus
    kubectl delete namespace jmeter
    
    
else

    echo "Creating Kubernetes Files..."
    
    kubectl create namespace jmeter
    kubectl apply -f jmeter_master_deploy.yaml
    kubectl apply -f jmeter_slaves_deploy.yaml
    kubectl apply -f jmeter_master_configmap.yaml
    kubectl apply -f jmeter_slaves_svc.yaml
    
    kubectl create namespace nexus
    kubectl apply -f nexus_deploy.yaml
    kubectl apply -f nexus_svc.yaml
    

fi


