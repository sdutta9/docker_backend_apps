# [Doc is in WIP] Steps to create a backend App VM within GCP

1. Select an azure location from the list listed below as per your choice

    ```bash
    az account list-locations -otable
    ```

1. Set your environment variables

    ```bash
    export MY_RG=sd-cflare
    export MY_LOC=northcentralus 
    export MY_PUBLICIP=$(curl ipinfo.io/ip)
    ```

1. Create resource group

    ```bash
    az group create --name $MY_RG --location $MY_LOC
    ```

1. Make sure your new resource group is in the list below

    ```bash
    az group list -otable | grep $MY_RG
    ```

1. Create a virtual network named `my-vnet` as below

    ```bash
    az network vnet create \
    --resource-group $MY_RG \
    --name my-vnet \
    --address-prefixes 10.0.0.0/16
    ```

1. Create a subnet named `vm-subnet` for virtual machine instances as below

    ```bash
    az network vnet subnet create \
    --resource-group $MY_RG \
    --name vm-subnet \
    --vnet-name my-vnet \
    --address-prefixes 10.0.1.0/24
    ```

1. Create a network security group (NSG) named `vm-nsg` using below command.

    ```bash
    az network nsg create \
    --resource-group $MY_RG \
    --name vm-nsg
    ```

1. Add two NSG rules to allow any traffic on port 80 and 443 from your system's public IP. Run below command to create the two rules. This rule you will modify to grant access to cloudflare IP

    ```bash
    ## Rule 1 for HTTP traffic

    az network nsg rule create \
    --resource-group $MY_RG \
    --nsg-name vm-nsg \
    --name HTTP \
    --priority 320 \
    --source-address-prefix $MY_PUBLICIP \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range 80 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --description "Allow HTTP traffic"
    ```

    ```bash
    ## Rule 2 for HTTPS traffic

    az network nsg rule create \
    --resource-group $MY_RG \
    --nsg-name vm-nsg \
    --name HTTPS \
    --priority 300 \
    --source-address-prefix $MY_PUBLICIP \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range 443 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --description "Allow HTTPS traffic"
    ```

1. Export your subscription details into an environment variable

    ```bash
    export MY_ID=`az group show -n $MY_RG --query "id" -otsv`
    export MY_JWT=$(cat Azure/nginx/ssl/nginx-plus.jwt)
    ```

1. Make sure all environment variables are set properly

    ```bash
    set | grep MY_
    ```

1. Create VM referencing the `init.sh` script present in the Azure directory within this repo.

    ```bash
    az vm create \
    --resource-group $MY_RG \
    --name my-ubuntuvm \
    --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest \
    --size Standard_B2s \
    --admin-username azureuser \
    --vnet-name my-vnet \
    --subnet vm-subnet \
    --assign-identity \
    --generate-ssh-keys \
    --public-ip-sku Standard \
    --custom-data Azure/init.sh 
    ```

1. Lock down your Network Security Group by allowing SSH/port22 access only to your publicIP

    ```bash
    az network nsg rule update \
    --resource-group $MY_RG \
    --nsg-name my-ubuntuvmNSG \
    --name default-allow-ssh \
    --source-address-prefix $MY_PUBLICIP
    ```

    ```bash
    ## Rule 1 for HTTP traffic (Allow any IP to access port 80)

    az network nsg rule create \
    --resource-group $MY_RG \
    --nsg-name my-ubuntuvmNSG \
    --name HTTP \
    --priority 320 \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range 80 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --description "Allow HTTP traffic"
    ```

1. To login to the vm type below command

    ```bash
    ssh azureuser@<UBUNTU_VM_PUBLICIP>

    #eg
    ssh azureuser@11.22.33.44
    ```

1. Run docker compose to create the containers

    ```bash
    cd /backend
    sudo docker-compose up -d
    ```

1. Test out from within the vm if the urls are all working

    ```bash
    curl http://localhost -H 'HOST:insecure-api.shouvik.dev'
    curl http://localhost -H 'HOST:secure-api.shouvik.dev'
    curl http://localhost -H 'HOST:insecure-web.shouvik.dev'
    curl http://localhost -H 'HOST:secure-web.shouvik.dev'
    ```