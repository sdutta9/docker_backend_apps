
To pull ingress image from private ECR, create a secret object using below command
```bash
    kubectl create secret docker-registry dockersecret \
    --docker-server=${MY_AWS_ACCOUNT_ID}.dkr.ecr.${MY_REGION}.amazonaws.com \
    --docker-username=AWS \
    --docker-password=$(aws ecr get-login-password --region ${MY_REGION}) \
    --namespace=nginx-ingress
```