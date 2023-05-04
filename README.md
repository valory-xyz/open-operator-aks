# Open Operator - Autonomous Keeper Service (AKS)
This repository contains tooling to deploy an agent instance for the Autonomous Keeper Service on AWS using Terraform.

## Deploy the service using Github actions

The repository is prepared to deploy the service automatically using Github actions. This is the easiest way to deploy your service.

### Steps

1. **Set up your AWS account.** Log in to the AWS console and configure the following parameters.

   1. In case you don't have one, you need to create an IAM user with an access key. Within the AWS console, create a new user (IAM/Users), and [create an access key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) for that user (Security credentials/Access keys). Note down the *AWS Access Key ID* and *AWS Secret Access Key*.
   2. You also need to [create an S3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html) to store the Terraform state for the service. You must follow the [AWS guidelines](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html) for naming your bucket. Note down the chosen bucket name.

2. **Clone this repository.**

3. **Set up the repository variables and secrets.** In the cloned Github repository, you must define the variables and secrets specified below.

   1. Secrets (Settings/Secrets and Variables/Actions/Secrets):
      * `AWS_ACCESS_KEY_ID`: Your AWS access key ID (20 characters).
      * `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key (40 characters).
      * `OPERATOR_SSH_PRIVATE_KEY`: SSH private key to access the deployed AWS EC2 instance where the service will be running. It must include the opening (`-----BEGIN ... -----`) and closing (`-----END ... -----`) lines.
      * `KEYS_JSON`: keys.json file for the service to be deployed.
      * `GH_TOKEN`: Github access token. This is required in case the service repository is private.

   2. Variables (Settings/Secrets and Variables/Actions/Variables):
      * `TFSTATE_S3_BUCKET`: AWS S3 bucket name to store the Terraform state.
      * `SERVICE_REPO_URL`: Service Github repository URL. Example: `https://github.com/valory-xyz/agent-academy-2`.
      * `SERVICE_REPO_TAG`: Repository tag corresponding to the release to be deployed. If this variable is left empty or blank, the deployment script will choose the latest release. Example: `v0.2.1`.
      * `SERVICE_ID`: Public ID of the service. The service must be located in the repository specified above. Example: `valory/keep3r_bot_goerli/0.1.0`.

4. **Set up the service variables and secrets.** You must define the variables and secrets particular to this service, which will be the values used within the AWS EC2 instance. These are defined in the files `./config/service_vars.env` and `./config/service_secrets.env`, respectively. You can specify the values for the variables and secrets directly in these files, or leave them blank and specify them as Github variables/secrets, using the same identifier names. If a Github variable/secret matches an identifier in the files `service_vars.env` or `service_secrets.env`, it will override its value.

   For example, you can leave `MY_SECRET=` blank in `service_secrets.env`, and define a Github secret `MY_SECRET` with the concrete value. This is convenient to avoid exposing secret values in a public repository.

   Note that variables/secrets to be exported in the AWS EC2 container **must be defined** in `service_vars.env` or `service_secrets.env`, even if they have assigned blank values.

5. **Execute a release of the repository.** The release will automatically create the necessary resources on AWS and deploy the agent service on the generated AWS EC2 instance. The service will be deployed for the specified `SERVICE_REPO_TAG`, or for the latest released tag, if it is not present. Once the release process has finished, the AWS EC2 instance will continue deploying the service.

   You can connect to the AWS EC2 instance via SSH using the `OPERATOR_SSH_PRIVATE_KEY` specified above:
   ```bash
   ssh -i /path/to/private_key ubuntu@<aws_ec2_public_ip>
   ```

   You can track the progress of the service deployment by checking the log file:
   ```bash
   cat ~/deploy_service.log
   ```

   Once the service agent is up and running, you can attach to its `screen` session:
   ```bash
   screen -r service_screen_session
   ```

## Deploy the service manually

You can clone the repository on your local machine and execute manually the deployment steps.
### Requirements

* [Terraform](https://developer.hashicorp.com/terraform)
* [AWS CLI](https://aws.amazon.com/cli/)

### Steps

1. **Configure AWS CLI.** You need to set up your AWS account as indicated in Step 1 above. Once you have your *AWS Access Key ID* and *AWS Secret Access Key*, configure your local machine to work with these credentials using the command:
    ```bash
    aws configure
    ```

    You can check if it has been properly configured by examining the files
    ```bash
    cat ~/.aws/config
    cat ~/.aws/credentials
    ```

2. **Configure deployment variables.** Navigate to the folder `./cloud_resources/aws/docker-compose/` and configure the variables within the file `variables.tf`. Specifically, ensure to populate the public key that you will be using to access the AWS EC2 instance. You can generate the keypair yorself, e.g.,
    ```bash
    ssh-keygen -t rsa -b 2048 -f id_rsa
    ```

    or use the AWS Management Console / EC2 service / Key Pairs / Create Key Pair to create a keypair.

3. **Deploy the infrastructure.** Within the folder `./cloud_resources/aws/docker-compose/` execute the necessary terraform commands to deploy the instance on AWS:
    ```bash
    terraform init -backend-config="bucket=<your_aws_s3_bucket_id>"
    terraform plan
    terraform apply
    ```

    After approving the deployment, you should see the logs of the command, and the following output once it finishes:
    ```
    (...)

    Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

    Outputs:

    instance_id = "i-05a058113bec25924"
    instance_public_ip = "35.177.208.255"
    ```

    Notice, the application automatically prints out the IP of the newly deployed EC2 instance, which can be used to access through SSH to the instance. After a couple of minutes, the EC2 instance will automatically install the [Open Autonomy](https://docs.autonolas.network/open-autonomy/) framework, together with a number of dependencies.

    **At this point, the EC2 instance will be installing the required dependencies. You should wait 2-3 minutes until it finishes before connecting to the instance.**

4. **Configure the service deployment script.** Define the service variables as indicated above. Once they have been set, you can execute the script `./scripts/generate_service_deployment_script.sh`. This script will generate the file `deploy_service.sh`, which must be executed inside the AWS EC2 instance.
The script is essentially following the [deployment process](https://docs.autonolas.network/open-autonomy/guides/deploy_service/) of the Open Autonomy framework for the service.

7. **Deploy the agent in the AWS EC2 instance.**
   1. Once properly configured, copy the `deploy_aks_service.sh` to the EC2 instance:
      ```bash
      scp ./deploy_service.sh ubuntu@35.177.208.255:~ 
      ```
   2. Connect to the EC2 instance via SSH and run the deployment script:
      ```bash
      ssh ubuntu@35.177.208.255
      ubuntu@ip-10-0-1-230:~$ ./deploy_aks_service.sh 
      ```

Upon executing all the steps, an agent instance for the AKS service should be running in a `screen` session. You can attach to the `screen` session to see the output of the agent:
  ```bash
  screen -r service_screen_session
  ```

  (Use `Ctrl+A D` to detach from the session). Alternatively, you can also follow the Docker logs:
  ```bash
  docker logs abci0 --follow  # For the agent
  docker logs node0 --follow  # For the Tendermint node
  ```

## Tearing down the infrastructure

Once you have finished using your service, you should tear down the infrastructure to free resources and avoid unnecessary billing on AWS. You can do so by removing the resources using the AWS frontend, or cloning the repository on your local machine and execute
```bash
cd ./cloud_resources/aws/docker-compose/
terraform destroy
```
