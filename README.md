# platform-engineering-guardian
a




# TASKS
## 1. Kubernetes Deployment
####    - VPC, Public and Private Subnets, Internet Gateway, Nat Gateway, Security Groups etc. is deployed by using modules in Teraform "0-vpc.tf"
####    - Kubernetes Cluster is again deployed by eks module in Terraform "1-eks.tf" and its created in private subnet
####    - Application is a backend application and it is written in Python and has 2 simple, not complicated microservices. One servie is responsible for POST requests which inserts into a table inside the RDS(Person Table, PersonID, FullName). Other one is responsible for GET requests and retrieves every item inside the Person Table.
####    - I used AWS ALB Controller to achieve path based routing. Created an Ingress Object to forward the request to backend services. LoadBalancer is serving with HTTP port since my Domain is expired. But for SSL we just need to add and edit some annotations such as modifying listen-ports and providing certificate ARN. Backend services are exposed to the cluster by using ClusterIP.
####    - Also to mention microservices are being stored inside a private repository in ECR. 
#####       - URL's:
#####            - /add_person
#####            - /get_people
## 2. GitOps Workflow
####       - ArgoCD is implemented. Login to ArgoCD and authenticate to git repository. I used CodeCommit Repo here to keep my manifests. And authenticated by using HTTPS on IAM Console. Once its done create the application and sync it.
####         Since CodeCommit Repo and ArgoCD are connected whenever a new commit comes to repo ArgoCD is notified. There are 2 options to sync also manual and automatic. Automatic checks repo with 3 minutes interval.
## 3. AWS Integration
####     - RDS is created inside the VPC with Terraform module again. I've used MySQL. Since it's a best practice to create RDS inside private subnets I also created a bastion host inside the public subnet to access to RDS by SSH Tunnel. Bastion host only accepts SSH requests from my public IP address. 
####     - I implemented Secrets Manager first by generating the RDS password in RDS module by setting "manage_master_user_password = true" option which generates and stores the password in Secrets Manager.
####     - From that point I followed AWS documentation to create neccessary drivers inside my cluster. I created IAM Policy to read from Secrets Manager. I created ServiceAccount and SecretProviderClass inside the namespace. After that I mounted the secrets as volume with path "/mnt/secrets-store" so that my applications can read it.
## 4. Scaling and Auto-Healing
####     - Implemented Horizontal Pod Autoscaling for my GET service as I mentioned which retrieves the every row from RDS Person Table. First I found that my cluster is missing "metrics-server". After installing the metrics-server inside the cluster I was able to see how pods are autoscaling depending on the limits that I provided. It can also be seen with the screenshot. Here autoscaler is created by CLI but this was before I implemented ArgoCD. There is also hpa.yml file in my ArgoCD manifests.






#   Installation
####      - Terraform init to initalize Terraform in the directory and to install modules. Terraform apply to create infra once its done get the ARN output that is written in rds module file to use it in secrets-access-policy.json for IAM Policy and  SecretProviderClass manifest to read dbusername and dbpassword.
####      - Create IAM Policy to read from SecretsManager and get the ARN number from the output to use it in Role. Update policy with ARN if policy exists.
####      - Create service account that is bounded with the policy
````
aws iam create-policy --policy-name EKSSecretsAccessPolicy --policy-document file://secrets-access-policy.json

eksctl create iamserviceaccount \
                --region=eu-west-1 --namespace guardian-ns --name eks-secrets-sa \
                --cluster guardian-cluster \
                --attach-policy-arn  arn:aws:iam::721699489018:policy/EKSSecretsAccessPolicy --approve \
                --override-existing-serviceaccounts
````
####      - Install secrets store csi driver by following these pods will be able to read the RDS master user password from SecretsManager
````
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install -n kube-system csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver
helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
helm install -n kube-system secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws
````
     
####      - Install AWS LoadBalancer Controller. Create IAM Policy and ServiceAccount for LoadBalancer Controller
    
````
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

eksctl create iamserviceaccount \
    --cluster=guardian-cluster \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --role-name AmazonEKSLoadBalancerControllerRole \
    --attach-policy-arn=arn:aws:iam::721699489018:policy/AWSLoadBalancerControllerIAMPolicy \
    --approve
````


    
####         Add helm repo and install the Controller
````
helm repo add eks https://aws.github.io/eks-charts

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=guardian-cluster \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller
````
        
####     - Now ingress can be applied. It is not needed to annotate subnet id's since we've done it by using tags in VPC module. Once its installed it will route the traffic based on path.
####     - HorizontalPodAutoScale. Install metric-server first. And check if its working
````
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl get deployment metrics-server -n kube-system
````
         
####     - Create load and monitor the autoscaler as I mentioned above it can be also achieved with manifest file(hpa.yml)
````
kubectl autoscale -n guardian-ns deployment get-deployment --min=1 --max=5 --cpu-percent=30
kubectl get hpa -n guardian-ns --watch
````
     
####         Also created the HorizontalPodAutoscaler with manifest file as it can be seen on ArgoCD
````
kubectl run -i \
    --tty load-generator \
    --rm --image=busybox \
    --restart=Never \
    -- /bin/sh -c "while sleep 0.01; do wget -q -O- k8s-guardian-servicea-e6bf9574ec-1961346563.eu-west-1.elb.amazonaws.com/get_people; done"
````
    
####     - Install ArgoCD
####         Create namespace and install the ArgoCD
````
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
````
            
####         Update argocd server service to LoadBalancer from ClusterIP so that it can be accessed by Internet
````
kubectl edit svc argocd-server -n argocd
````             
####         Get the admin password for the UI
````
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
````         
####     - Monitoring and Logging
####         Monitoring, CloudWatch agent is installed and can be monitored through CloudWatch Container Insights. And also "amazon-cloudwatch-observability" addon is enabled and bounded with ServiceAccount inside eks.tf file. Based on Container Insights metrics alarms can be setup
````
eksctl create iamserviceaccount \
    --name cloudwatch-agent \
    --namespace amazon-cloudwatch --cluster guardian-cluster \
    --role-name guardian-monitoring \
    --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
    --role-only \
    --approve
````
     
####         SNS Topic, Subscription to topic, and Custom Metric alarm by giving the dimensions is created in sns.tf file. And received the email successfully. 

# Screenshots
## Secret retrieved from SecretsManager inside the container
![Ekran Resmi 2024-09-09 10 45 37](https://github.com/user-attachments/assets/048e3fe9-95d3-4766-87c0-1f10869f5566)

## Post Microservice Result
<img width="1313" alt="Ekran Resmi 2024-09-08 22 13 46" src="https://github.com/user-attachments/assets/2a2ae298-ce90-41e5-836e-4d82fd1291e4">

# Get Microservice Result
<img width="1666" alt="Ekran Resmi 2024-09-08 22 15 44" src="https://github.com/user-attachments/assets/1a3c0834-5598-474c-9deb-e330e74e8f40">

# Horizontal Pod Autoscaler
<img width="1470" alt="Ekran Resmi 2024-09-08 21 52 37" src="https://github.com/user-attachments/assets/06bba943-67cc-4f6e-8277-d5cdff4bef86">

# ArgoCD UI
![Ekran Resmi 2024-09-09 17 28 43](https://github.com/user-attachments/assets/a4b58baf-920b-438a-ba1d-0847d6abf5ef)


# ArgoCD Application installed with manifests inside CodeCommit Repo. Horizontal Pod Autoscaler with hpa manifest file
![Ekran Resmi 2024-09-09 17 30 23](https://github.com/user-attachments/assets/60bf4960-13da-4712-9af8-71f1c489568d)



# Container Insights
![Ekran Resmi 2024-09-09 14 40 51](https://github.com/user-attachments/assets/1db015ea-138e-4749-ac4a-2fa0d8e780dd)
![Ekran Resmi 2024-09-09 14 41 13](https://github.com/user-attachments/assets/bbf06e78-372d-4e24-8f76-cdd43a96acf8)

# Cloudwatch Alarm with given Dimensions and its also appearing in cluster overview
![Ekran Resmi 2024-09-09 15 26 48](https://github.com/user-attachments/assets/fcca61e4-6b9d-4e05-9abe-34da8538ab02)
![Ekran Resmi 2024-09-09 15 27 41](https://github.com/user-attachments/assets/986ba592-c844-4df1-979a-7c21fc9fb144)






























