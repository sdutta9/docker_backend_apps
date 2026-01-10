# [Doc is in WIP] Steps to create a backend App VM within GCP

Here is the Google Cloud Platform (GCP) equivalent of your Azure workflow.

### Key Concept Mappings

Before running the commands, note these structural differences:

* **Resource Group**  **Project:** GCP uses Projects to group resources. You usually select the project once at the start rather than passing a group flag to every command.
* **VNet/Subnet**  **VPC Network/Subnet:** Concepts are very similar.
* **NSG (Network Security Group)**  **Firewall Rules:** In GCP, firewall rules are global to the VPC network, not attached to a specific network interface or subnet object (though you can target them using "Network Tags").
* **Init Script:** In Azure, you use `--custom-data`. In GCP, you use `--metadata-from-file startup-script=...`.

---

### Step-by-Step GCP Conversion

#### 1. Select a GCP Zone

Instead of listing all regions, we pick a zone (a specific datacenter within a region).

```bash
gcloud compute zones list

```

#### 2. Set your environment variables

Note: GCP requires a Project ID.

```bash
export MY_PROJECT_ID=[YOUR_PROJECT_ID] # Replace with your actual project ID
export MY_ZONE=us-central1-a
export MY_NETWORK=my-vpc
export MY_SUBNET=vm-subnet
export MY_PUBLICIP=$(curl -s ipinfo.io/ip)

# Set the project and zone as default for this session
gcloud config set project $MY_PROJECT_ID
gcloud config set compute/zone $MY_ZONE

```

#### 3. Create Resource Group (Project)

*In GCP, you usually don't create projects via CLI script as part of a standard deployment (it requires organization-level permissions). We assume you are already inside a project.*

```bash
# Verify current project
gcloud config get-value project

```

#### 4. Make sure your project is active

```bash
gcloud projects list --filter="projectId:$MY_PROJECT_ID"

```

#### 5. Create a VPC Network (`my-vnet`)

GCP VPCs are global, but we use `--subnet-mode=custom` to define subnets manually like in your Azure script.

```bash
gcloud compute networks create $MY_NETWORK \
    --subnet-mode=custom \
    --bgp-routing-mode=regional

```

#### 6. Create a subnet (`vm-subnet`)

```bash
gcloud compute networks subnets create $MY_SUBNET \
    --network=$MY_NETWORK \
    --range=10.0.1.0/24 \
    --region=us-central1

```

#### 7 & 8. Create Firewall Rules (Equivalent to NSG)

In GCP, we create firewall rules attached to the VPC. We use **target tags** (`http-server`, `https-server`) so these rules only apply to VMs we specifically tag later.

```bash
# Allow HTTP (80) from your IP
gcloud compute firewall-rules create allow-http-my-ip \
    --network=$MY_NETWORK \
    --allow=tcp:80 \
    --source-ranges="$MY_PUBLICIP/32" \
    --target-tags=http-server \
    --description="Allow HTTP traffic from my IP"

# Allow HTTPS (443) from your IP
gcloud compute firewall-rules create allow-https-my-ip \
    --network=$MY_NETWORK \
    --allow=tcp:443 \
    --source-ranges="$MY_PUBLICIP/32" \
    --target-tags=https-server \
    --description="Allow HTTPS traffic from my IP"

```

#### 9. Export subscription details (Project info)

```bash
export MY_ID=$(gcloud projects list --filter="projectId:$MY_PROJECT_ID" --format="value(projectNumber)")
# Assuming the file exists locally
export MY_JWT=$(cat Azure/nginx/ssl/nginx-plus.jwt)

```

#### 10. Check variables

```bash
printenv | grep MY_

```

#### 11. Create VM (`my-ubuntuvm`)

This command creates the VM, attaches it to the network, and assigns the startup script.

* **Tags:** We add `http-server` and `https-server` tags so the firewall rules we created earlier apply to this VM.
* **Service Account:** `--scopes=cloud-platform` is roughly equivalent to Azure's generic Managed Identity with broad access.

```bash
gcloud compute instances create my-ubuntuvm \
    --zone=$MY_ZONE \
    --machine-type=e2-standard-2 \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --network=$MY_NETWORK \
    --subnet=$MY_SUBNET \
    --tags=http-server,https-server \
    --metadata-from-file startup-script=Azure/init.sh \
    --scopes=https://www.googleapis.com/auth/cloud-platform

```

*(Note: `Standard_B2s` in Azure is roughly `e2-standard-2` in GCP).*

#### 12. Lock down SSH and Open HTTP globally

In GCP, SSH is usually blocked by default unless you have the `default-allow-ssh` rule. We will create a specific rule for SSH restricted to your IP.

```bash
# 1. Allow SSH only from your IP
gcloud compute firewall-rules create allow-ssh-my-ip \
    --network=$MY_NETWORK \
    --allow=tcp:22 \
    --source-ranges="$MY_PUBLICIP/32" \
    --target-tags=http-server

# 2. Update the HTTP rule to allow traffic from ANYWHERE (0.0.0.0/0)
# (In GCP we overwrite the previous rule or create a new one. Here we update.)
gcloud compute firewall-rules update allow-http-my-ip \
    --source-ranges="0.0.0.0/0" \
    --description="Allow HTTP traffic from Anywhere"

```

#### 13. Login to the VM

GCP handles keys automatically. You don't need to manually find the IP or username.

```bash
gcloud compute ssh my-ubuntuvm --zone=$MY_ZONE

```

#### 14. Run Docker Compose

Once logged in (inside the SSH session):

```bash
cd /backend
sudo docker-compose up -d

```

*(Note: Ensure your `init.sh` script actually cloned the repo or created the `/backend` folder, otherwise this `cd` will fail).*

#### 15. Test URLs

Inside the VM:

```bash
curl http://localhost -H 'HOST:insecure-api.shouvik.dev'
curl http://localhost -H 'HOST:secure-api.shouvik.dev'
curl http://localhost -H 'HOST:insecure-web.shouvik.dev'
curl http://localhost -H 'HOST:secure-web.shouvik.dev'

```

---

### Key Troubleshooting Tip for GCP

In Azure, `custom-data` scripts run on the first boot. In GCP, `startup-script` also runs on boot, but you can view the logs easily to debug failures without logging into the machine:

```bash
# View the output of your init.sh script from your local machine
gcloud compute instances get-serial-port-output my-ubuntuvm --zone=$MY_ZONE

```