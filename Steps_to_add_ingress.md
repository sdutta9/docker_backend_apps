## Pulling NGINX Ingress from private ECR registry
- To pull ingress image from private ECR, create a secret object using below command:
    ```bash
        MY_AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
        MY_REGION=us-east-1

        kubectl create secret docker-registry dockersecret \
        --docker-server=${MY_AWS_ACCOUNT_ID}.dkr.ecr.${MY_REGION}.amazonaws.com \
        --docker-username=AWS \
        --docker-password=$(aws ecr get-login-password --region ${MY_REGION}) \
        --namespace=nginx-ingress
    ```
- Once secret is created you can build the deployment running below command
    ```bash
        cd [ProjectRoot]
        kubectl apply -f k8s/NginxIngress/nginx-plus-ingress.yaml
    ```
## References:
- https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-by-providing-credentials-on-the-command-line
- https://skryvets.com/blog/2021/03/15/kubernetes-pull-image-from-private-ecr-registry/