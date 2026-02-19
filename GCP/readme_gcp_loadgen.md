# Steps to create a load generation VM using wrk tool within GCP

## Create a new ubuntu/debian linux VM on GCP

## Install wrk inside the vm

1. Ensure your local package index is up to date
    
    ```bash
    sudo apt update && sudo apt upgrade -y
    ```

1. Install dependency packages

    ```bash
    sudo apt install build-essential libssl-dev git unzip -y
    ```

1. Clone `wrk` repository

    ```bash
    git clone https://github.com/wg/wrk.git wrk
    cd wrk
    ```

1. Build the tool

    ```bash
    make
    ```

1. Once the build finishes, you'll have an executable named wrk in the current directory. To run it from anywhere, move it to `/usr/local/bin`

    ```bash
    sudo cp wrk /usr/local/bin
    ```

1. Check the version to confirm everything is working correctly:

    ```bash
    wrk --version
    ```

## Copy the load generation scripts to the vm

1. Create a new directory

    ```bash
    mkdir scripts
    ```

1. Copy below files from this repo to the vm

    1. waf_paths.lua : This file contains the list of paths that needs to be traversed
    2. waf_test_wrk.sh : This file is the main script that takes in a domain and duration for which you would like to run the load generation.
    3. waf_run_all.sh : This file is wrapper file which essentially runs the main script 3 times for 3 different domains.

1. Make all the script files executable

    ```bash
    sudo chmod +x /home/shouvik/script/*.sh
    ```

1. Create a directory where the logs would be captured for each run of the script

    ```bash
        # Create the directory
        sudo mkdir -p /var/log/wrk

        # Change ownership to your user
        sudo chown -R shouvik:shouvik /var/log/wrk
    ```

## Setup a Systemd service so that the script runs continuously from the moment your VM starts until it is shut down

1. Create the service file

    ```bash
    sudo vi /etc/systemd/system/waf_load_gen.service
    ```

1. Define the service configuration. Copy the contents of`waf_load_gen.service` file from this repository and paste it in the new file that you created in previous step.

1. Enable and start the service

    ```bash
        # Reload the systemd manager to see the new file
        sudo systemctl daemon-reload

        # Enable it to run at startup
        sudo systemctl enable waf_load_gen.service

        # Start it right now
        sudo systemctl start waf_load_gen.service
    ```

1. Verify service is enabled

    ```bash
    sudo systemctl is-enabled waf_load_gen.service
    ```

1. View systemd service logs:

    ```bash
    sudo systemctl status waf_load_gen.service
    ```

    ```bash
    journalctl -u waf_load_gen.service -f
    ```

