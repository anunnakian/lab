# DECISIONS

1. Create spring project

2. Add docker file with three steps (Build, Prep and runtime)

3. create specific namespace

kubectl create restricted namespace backend to force all pods to respect security configuration

kubectl label --overwrite ns backend pod-security.kubernetes.io/enforce=restricted

4. create helm chart for my application



5. build the image and use it in minikube



