<p align="center">
   <img src="./docs/images/open-operator-logo.svg">
</p>

<div id="title"  align="center" >
  <ul>
    <summary><h1 style="display: inline-block;">Open Operator</h1></summary>
  </ul>
</div>

<h2 align="center">
    <b>Autonomous Keeper Service</b>
<p align="center">
  <a href="https://github.com/valory-xyz/open-autonomy/blob/main/LICENSE">
    <img alt="License" src="https://img.shields.io/pypi/l/open-autonomy">
  </a>
</p> 
</h2>

This repository contains tooling to deploy an agent instance for the Autonomous Keeper Service (AKS) on Amazon Web Services (AWS) using Terraform. After the deployment process finishes, the agent will be running in a [`screen`](https://www.gnu.org/software/screen/) session within an [AWS EC2](https://aws.amazon.com/ec2/) instance.

You can deploy the agent instance either using using GitHub actions or cloning the repository locally on your machine and executing the steps manually.

#### Table of contents

- [Prerequisites](#prerequisites)
- [Deploy the service using GitHub actions](#deploy-the-service-using-github-actions)
- [Deploy the service manually](#deploy-the-service-manually)
- [Tearing down the infrastructure](#tearing-down-the-infrastructure)

## Prerequisites

1. **Set up your AWS account.** Sign in to the AWS Management Console
 and configure the following parameters.

   1. In case you don't have one, you need to create an IAM user with an access key. Within the AWS Management Console, create a new user (IAM/Users), and [create an access key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) for that user (Security credentials/Access keys). Note down the *AWS Access Key ID* and *AWS Secret Access Key*.
   2. You also need to [create an *S3 bucket*](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html) to store the Terraform state for the service. You must follow the [AWS guidelines](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html) for naming your bucket. Note down the chosen bucket name.

2. **Prepare an SSH key pair.** This key pair will be used to access the deployed AWS EC2 instance where the service will be running.

   You can generate the key pair yourself, e.g.,
   ```bash
   ssh-keygen -t rsa -b 2048 -f id_rsa
   ```
   or use the [AWS Management Console to create a key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html). Store securely both the public and private key.

3. **Prepare the service repository data.**

   1. Note down the *service repository URL* (e.g., `https://github.com/valory-xyz/agent-academy-2`), the *public ID of the service* located in the `packages/packages.json` file of the repository (e.g., `valory/keep3r_bot_goerli/0.1.0`), and the *release tag* corresponding to the version of the service you want to deploy (e.g., `v.0.2.1`). If you don't define the release tag, the script will deploy the latest available release.
   2. Ensure that the GitHub repository of the service is publicly accessible. If it is a private repository, your GitHub user account has to be authorized to access it, and you have to [create a *GitHub personal access token*](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with `repo` permissions enabled. Note down the token.

4. **Prepare the service configuration parameters.**

   1. Prepare the `./config/keys.json` file containing the agent(s) address(es) and key(s). For example, if you are deploying a single agent, the file contents should look like this:

      ```json
      [
         {
            "address": "0x1c883D4D6a429ef5ea12Fa70a1d67D6f6013b279",
            "private_key": "0x0000000000000000000000000000000000000000000000000000000000000000"
         }
      ]   
      ```

   2. Prepare the `./config/service_vars.env` file containing the service-specific variables. You must check the service you are deploying to know which variables you need to define.

   > :bulb: **Tip:** If you are [deploying the service using GitHub actions](#deploy-the-service-using-github-actions), you can override the `keys.json` file or any confidential service variable as a GitHub secret. See below.


## Deploy the service using GitHub actions

The repository is prepared to deploy the service automatically using GitHub actions. This is the easiest way to deploy your service.

1. **Clone this repository.** The remaining actions are assumed to take place in the cloned repository.

2. **Set up the repository variables and secrets.** In the cloned GitHub repository, you must define the following action secrets and variables.

   1. [Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository):
      * `AWS_ACCESS_KEY_ID`: AWS Access Key ID.
      * `AWS_SECRET_ACCESS_KEY`: AWS Secret Access Key.
      * `OPERATOR_SSH_PRIVATE_KEY`: SSH private key to access the deployed AWS EC2 instance. It must include the opening (`-----BEGIN ... -----`) and closing (`-----END ... -----`) lines.
      * `GH_TOKEN`: GitHub access token. This is only required if the service repository is private.

   2. [Variables](https://docs.github.com/en/actions/learn-github-actions/variables#creating-configuration-variables-for-a-repository):
      * `TFSTATE_S3_BUCKET`: AWS S3 bucket name to store the Terraform state.
      * `SERVICE_REPO_URL`: Service repository URL.
      * `SERVICE_ID`: Public ID of the service.
      * `SERVICE_REPO_TAG`: Release tag corresponding to the version of the service you want to deploy. If you don't define the release tag, the script will deploy the latest available release.

3. **Set up the service configuration parameters.**

   1. Prepare and commit the file `./config/keys.json` as indicated above. Alternatively, you can [define the GitHub secret](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) `KEYS_JSON` with the contents of the file.

   2. Prepare and commit the file `./config/service_vars.env` as indicated above. You can assign blank/dummy values for confidential variables in this file, and override their values by [defining a GitHub secret](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) with the same identifier that you want to override.

      > :warning: **Important:** Even if you define a service variable as a GitHub secret, you must specify its identifier in the file `./config/service_vars.env`. Otherwise, it will not be exported to the AWS EC2 instance.

4. **Create a release of the repository.** By [creating a release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository#creating-a-release) the service deployment workflow will be executed. This workflow will create the necessary resources on AWS, and deploy the agent service on the AWS EC2 instance. Once the release process has finished, the AWS EC2 instance will take over with the process of deploying the service.

   You should see the following output in the *Summary* step of the workflow:
   ```
   Summary:
    - Service repository URL: <SERVICE_REPO_URL>
    - Service repository tag: <SERVICE_REPO_TAG>
    - Service ID: <SERVICE_ID>
    - AWS EC2 instance public IP: <AWS_EC2_PUBLIC_IP>
    - AWS EC2 instance ID: <AWS_EC2_ID>
   ```

   You can connect to the AWS EC2 instance via SSH using the SSH private key specified above:
   ```bash
   ssh -i /path/to/private_key ubuntu@<AWS_EC2_PUBLIC_IP>
   ```

   Track the progress of the service deployment by checking the log file:
   ```bash
   cat ~/deploy_service.log
   ```

   Once the service agent is up and running, you can attach to its `screen` session:
   ```bash
   screen -r service_screen_session
   ```

   Use `Ctrl+A D` to detach from the session. Alternatively, you can also follow the Docker logs:
   ```bash
   docker logs abci0 --follow  # For the agent
   docker logs node0 --follow  # For the Tendermint node
   ```

## Deploy the service manually

You can clone the repository on your local machine and execute the deployment steps manually.

1. **Install required software.**

   * [Terraform](https://developer.hashicorp.com/terraform)
   * [AWS CLI](https://aws.amazon.com/cli/)

2. **Set up the AWS CLI.** Configure your local machine to work with your AWS credentials (*AWS Access Key ID* and *AWS Secret Access Key*):
    ```bash
    aws configure
    ```

    You can check if it has been properly configured by examining the files
    ```bash
    cat ~/.aws/config
    cat ~/.aws/credentials
    ```

3. **Deploy the infrastructure.**
   1. Define the following environment variables as specified above:
      * `TFSTATE_S3_BUCKET`
      * `TF_VAR_operator_ssh_pub_key=$(cat path/to/your/ssh_public_key)`

   2. Within the folder `./cloud_resources/aws/docker-compose/` execute the necessary terraform commands to deploy the instance on AWS:
      ```bash
      terraform init -backend-config="bucket=$TFSTATE_S3_BUCKET"
      terraform plan
      terraform apply
      ```

      After approving the deployment, you should see the logs of the command, and the following output once it finishes:
      ```
      Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

      Outputs:

      instance_id = <AWS_EC2_ID>
      instance_public_ip = <AWS_EC2_PUBLIC_IP>
      ```

      The application prints out the IP of the deployed AWS EC2 instance, which can be used to access through SSH to the instance. The instance will automatically install the [Open Autonomy](https://docs.autonolas.network/open-autonomy/) framework, together with a number of dependencies.

   3. Wait until the AWS EC2 instance is ready:
      ```bash
      aws ec2 wait instance-status-ok --instance-ids <AWS_EC2_ID>
      ```

4. **Generate the service deployment script.**
   1. Ensure that the file `./config/keys.json` contains the agent keys.
   2. Ensure that the file `./config/service_vars.env` contains the correct values for all the required variables for the service.
   3. Define the following environment variables as specified above:
      * `SERVICE_REPO_URL`
      * `SERVICE_ID`
      * (Optional) `SERVICE_REPO_TAG`
      * (Optional) `GH_TOKEN`
   4. Execute the script `./scripts/generate_service_deployment_script.sh` in the root folder of the repository. The script will generate the file `deploy_service.sh`, which contains the commands to deploy the service agent in the AWS EC2 instance.

5. **Deploy the agent in the AWS EC2 instance.**
   1. Copy the file `deploy_service.sh` to the AWS EC2 instance:
      ```bash
      scp ./deploy_service.sh ubuntu@<AWS_EC2_PUBLIC_IP>:~ 
      ```
   2. Launch the deployment script on the AWS EC2 instance:
      ```bash
      ssh ubuntu@<AWS_EC2_PUBLIC_IP> 'nohup ~/deploy_service.sh > deploy_service.log 2>&1 &'
      ```

   You can connect to the AWS EC2 instance via SSH using the SSH private key specified above:
   ```bash
   ssh -i /path/to/private_key ubuntu@<AWS_EC2_PUBLIC_IP>
   ```

   Track the progress of the service deployment by checking the log file:
   ```bash
   cat ~/deploy_service.log
   ```

   Once the service agent is up and running, you can attach to its `screen` session:
   ```bash
   screen -r service_screen_session
   ```

   Use `Ctrl+A D` to detach from the session. Alternatively, you can also follow the Docker logs:
   ```bash
   docker logs abci0 --follow  # For the agent
   docker logs node0 --follow  # For the Tendermint node
   ```
## Tearing down the infrastructure

Once you have finished using your service, you should tear down the infrastructure to free resources and avoid unnecessary billing on AWS. You can do so by removing the resources using the AWS Management Console, or cloning the repository on your local machine and executing
```bash
cd ./cloud_resources/aws/docker-compose/
terraform destroy
```
