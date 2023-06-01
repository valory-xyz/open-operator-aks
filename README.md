<p align="center">
   <img src="./docs/images/open-operator-logo.svg" width=300>
</p>

<h1 align="center" style="margin-bottom: 0;">
    Open Operator
    <br><sub>Autonomous Keeper Service</sub>
    <br><a href="https://github.com/valory-xyz/open-operator-aks/blob/main/LICENSE"><img alt="License: Apache-2.0" src="https://img.shields.io/github/license/valory-xyz/open-operator-aks"></a>
    <a href="https://aws.amazon.com/"><img alt="Cloud: AWS" src="https://img.shields.io/badge/cloud-AWS-orange"></a>
    <a href="https://docs.docker.com/compose/"><img alt="Deployment: Docker Compose" src="https://img.shields.io/badge/deployment-Docker%20Compose-blue"></a>
    <a href="https://pypi.org/project/open-autonomy/0.10.4/"><img alt="Framework: Open Autonomy 0.10.4" src="https://img.shields.io/badge/framework-Open%20Autonomy%200.10.4-blueviolet"></a>
    <!-- <a href="https://github.com/valory-xyz/open-operator-aks/releases/latest">
    <img alt="Latest release" src="https://img.shields.io/github/v/release/valory-xyz/open-operator-aks"> -->
    </a>
</h1>

This repository contains tooling to deploy autonomous service agent(s) on Amazon Web Services (AWS) using Terraform. The repository is designed to facilitate the deployment process by [using GitHub actions](#deploy-the-service-using-github-actions). You can also clone the repository locally on your machine and [execute the deployment commands manually]((#deploy-the-service-using-the-cli)).

<p align="center">
   <img src="./docs/images/deploy-steps.svg">
</p>

After the deployment process finishes, the agent will be running in a [`screen`](https://www.gnu.org/software/screen/) session within an [AWS EC2](https://aws.amazon.com/ec2/) instance in the default AWS Region `us-east-2`.[^1]

> **Note** <br />
> **This repository contains default configuration parameters in the `./config/service_vars.env` file that you will need to override with the information you will have been provided by the service owner.**

[^1]: If you wish to deploy on another AWS Region, you need to modify the Terraform variable `deployment_region` in the file `./infra/aws/docker_compose/variables.tf`. You also need to provide a valid Amazon Machine Image (AMI) ID for that region (resource `aws_instance` in the file `./infra/aws/docker_compose/main.tf`), otherwise the deployment process will fail on `terraform apply`.

## Prerequisites

1. **Set up your AWS account.** Sign in to the AWS Management Console and configure the following parameters.

   1. In case you don't have one, you need to create an IAM user with an access key. Within the AWS Management Console, create a new user (IAM/Users), and [create an access key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) for that user (Security credentials/Access keys). The IAM user needs have the permissions `AmazonEC2FullAccess` and `AmazonS3FullAccess`. Note down the *AWS Access Key ID* and *AWS Secret Access Key*.
  
   2. You also need to [create an *S3 bucket*](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html) to store the Terraform state for the service.[^2] Create the bucket in region `us-east-2`.  You must follow the [AWS guidelines](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html) for naming your bucket. Note down the bucket name.

   [^2]: For simplicity, the Terraform scripts in this repository do not implement [state locking](https://developer.hashicorp.com/terraform/language/state/locking). Therefore, it is important to ensure that the script is not executed concurrently by different users in order to prevent potential issues. You might consider implementing state locking in the AWS S3 bucket using [DyanomDB](https://aws.amazon.com/dynamodb/). See for example [this](https://terraformguru.com/terraform-real-world-on-aws-ec2/20-Remote-State-Storage-with-AWS-S3-and-DynamoDB/) or [this](https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa) tutorial.

2. **Prepare an SSH key pair.** This key pair will be used to access the deployed AWS EC2 instance where the service will be running.

   You can generate the key pair with the following command. **Do not enter a passphrase if prompted to do so:**

   ```bash
   ssh-keygen -t rsa -b 2048 -N "" -f id_rsa
   ```

   Store securely both the public and private key.[^3]
   
[^3]: Make sure to use one of the [supported AWS EC2 key pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html). You can also use the [AWS Management Console to create a key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html).

3. **Prepare the service repository data.**

   - Ensure that the GitHub repository of the service is publicly accessible. If it is a private repository, your GitHub user has to be authorized to access it, and you need to [create a *GitHub personal access token*](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with `repo` permissions enabled.

## Deploy the service using GitHub actions

The repository is prepared to deploy the service using GitHub actions. This is the easiest way to deploy your service.

1. **Fork this repository.**
2. **Configure cloud credentials and service parameters.**
   First, [define the following secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) and [variables](https://docs.github.com/en/actions/learn-github-actions/variables#creating-configuration-variables-for-a-repository) in the forked repository. We recommend defining them through the GitHub's website UI:

   > **Warning** <br />
   > **Please make sure to avoid any leading or trailing white spaces or newlines when defining secrets and variables.**

   <table>
   <thead>
   <tr>
   <th>Name</th>
   <th>Type</th>
   <th>Description</th>
   </tr>
   </thead>
   <tbody>
   <tr>
   <td>

   `AWS_ACCESS_KEY_ID`

   </td>
   <td>Secret</td>
   <td>AWS Access Key ID (20-character alphanumeric string).</td>
   </tr>
   <tr>
   <td>

   `AWS_SECRET_ACCESS_KEY`

   </td>
   <td>Secret</td>
   <td>AWS Secret Access Key (40-character alphanumeric string).</td>
   </tr>
   <tr>
   <td>

   `OPERATOR_SSH_PRIVATE_KEY`

   </td>
   <td>Secret</td>
   <td>SSH private key to access the deployed AWS EC2 instance. It must include the opening and closing lines. Example:

   ```text
   -----BEGIN OPENSSH PRIVATE KEY-----
   <ssh_private_key>
   -----END OPENSSH PRIVATE KEY-----
   ```

   </tr>
   <tr>
   <td>

   `GH_TOKEN`

   </td>
   <td>Secret</td>
   <td>GitHub access token. This is only required if the service repository is private. Example:

   `ghp_000000000000000000000000000000000000`

   </td>
   </tr>
   <tr>
   <td>

   `TFSTATE_S3_BUCKET`

   </td>
   <td>Variable</td>
   <td>AWS S3 bucket name to store the Terraform state.</td>
   </tr>
   <tr>
   <td>

   `SERVICE_REPO_URL`

   </td>
   <td>Variable</td>
   <td>Service repository URL.

   `https://github.com/valory-xyz/agent-academy-2`

   </td>
   </tr>
   <tr>
   <td>

   `SERVICE_ID`

   </td>
   <td>Variable</td>
   <td>Public ID of the service. 
      
    `valory/keep3r_bot_goerli:0.1.0` **for Görli testnet** 
      
`valory/keep3r_bot:0.1.0`   **for Ethereum mainnet**

   </td>
   </tr>
   <tr>
   <td>

   `SERVICE_REPO_TAG`
   <b>(Optional)</b>

   </td>
   <td>Variable</td>
   <td>Release tag corresponding to the version of the service you want to deploy. If not defined, the script will deploy the latest release. Currently:

   `v.0.3.0`

   </td>
   </tr>
   </tbody>
   </table><br />

   Next, Populate, commit and push the files with the service configuration parameters:

   <table>
   <thead>
   <tr>
   <th>File</th>
   <th>Description</th>
   </tr>
   </thead>
   <tbody>
   <tr>
   <td valign="top">

   `./config/keys.json`

   </td>
   <td>
   It must contain the address(es) and key(s) for the agents to be deployed. Example (for a single agent):

   ```json
   [
    {
     "address": "0x1c883D4D6a429ef5ea12Fa70a1d67D6f6013b279",
     "private_key": "0x0123456789abcdef0123456789abcdef...0"
    }
   ]
   ```

   > **Warning** <br />
   > **Typically, it is not advisable to expose the `keys.json` file in the repository. As an alternative, we provide a mechanism where you can [define the GitHub secret](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) `KEYS_JSON` with the contents of the file.**
   </td>
   </tr>
   <tr>
   <td valign="top">

   `./config/service_vars.env`

   </td>
   <td>

   It must contain the service-specific variables. You must check the service you are deploying to know which variables you need to define. Example:

   ```text
   SERVICE_VAR1=value1
   SERVICE_VAR2=value2
   SERVICE_SECRET1=secret_value1
   SERVICE_SECRET2=secret_value2
   ```

   > **Warning** <br />
   > **If you don't want to expose secret/confidential variables in the repository, you can assign them a blank value (or a placeholder value)[^3] in the file `service_vars.env`, and override their values by [defining GitHub secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) matching the corresponding variables' names. For the present case (`keep3r_bot` and `keep3r_bot_goerli` services), we recommend this practice with the variables <code>ARBITRUM_RPC_0</code> and <code>SERVICE_RPC_0</code>.**

   [^3]: The deployment process will override any service-specific variable defined in the `./config/service_vars.env` with any **secret** or **variable** defined in the GitHub repository that matches the variable name. It is important to note that a variable (overridden or not) will be exported to the AWS EC2 instance running the service agent **only** if it is declared in the `./config/service_vars.env` file.

   > **Warning** <br />
   > **For security reasons, even if present in the file `service_vars.env`, the following variables will not be overridden with GitHub secrets or variables: <code>AWS_ACCESS_KEY_ID</code>, <code>AWS_SECRET_ACCESS_KEY</code>, <code>OPERATOR_SSH_PRIVATE_KEY</code>, <code>GH_TOKEN</code>, <code>KEYS_JSON</code>, <code>TFSTATE_S3_BUCKET</code>.**

   </td>
   </tr>
   </tbody>
   </table>

3. **Deploy the infrastructure and the service to AWS.** Run the "Deploy service" workflow using the GitHub interface. This workflow will create the necessary resources on AWS. Once the workflow has finished, the generated AWS EC2 instance will take over with the process of deploying the agent for the service.

   <p align="center"><img src="docs/images/deploy-service-workflow.png" alt="Deploy service workflow" width=80%></p>
   
Please wait until the AWS EC2 instance finishes completing the service deployment. The IP of the created AWS EC2 instance can be retrieved for the "Summary" step in the "Deploy service" workflow.


4. **Interact with the AWS EC2 instance.** You can connect to the AWS EC2 instance as the user `ubuntu` using the SSH private key specified:

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

5. **Destroy the infrastructure.**  Run the "Destroy infrastructure" workflow using the GitHub interface. This will destroy the resources created on AWS. Alternatively, you can also remove the resources using the AWS Management Console.

   <p align="center"><img src="docs/images/destroy-infrastructure-workflow.png" alt="Deploy service workflow" width=80%></p>

## Deploy the service using the CLI

You can also execute the deployment steps manually on your local machine. You must ensure that you have the required software:

- [AWS CLI](https://aws.amazon.com/cli/)
- [Terraform](https://developer.hashicorp.com/terraform)

Follow these steps:

1. **Clone this repository to your local machine.**
2. **Configure cloud credentials and service parameters.**

   1. Set up the AWS CLI. Configure your local machine to work with your AWS credentials (*AWS Access Key ID* and *AWS Secret Access Key*):

      ```bash
      aws configure
      ```

      You can check if it has been properly configured by examining the files

      ```bash
      cat ~/.aws/config
      cat ~/.aws/credentials
      ```

   2. Define the following environment variables. See the description of the variables in Step 2 in the [section above](#deploy-the-service-using-github-actions).

      ```bash
      export TF_VAR_operator_ssh_pub_key_path=<path/to/your/ssh_public_key>

      export TFSTATE_S3_BUCKET=<tfstate_s3_bucket>
      export SERVICE_REPO_URL=https://github.com/<owner>/<repo>
      export SERVICE_ID=<author>/<service_name>:<version>

      # Optional variables
      export SERVICE_REPO_TAG=<version_tag>
      export GH_TOKEN=ghp_000000000000000000000000000000000000
      ```

   3. Populate the files with the service configuration parameters. See the description of the files in Step 2 in the [section above](#deploy-the-service-using-github-actions):

      - `./config/keys.json`
      - `./config/service_vars.env`

3. **Deploy the infrastructure and the service to AWS.**
   1. Deploy the infrastructure:

      ```bash
      cd ./infra/aws/docker-compose/
      terraform init -backend-config="bucket=$TFSTATE_S3_BUCKET"
      terraform plan
      terraform apply
      ```

      You should see the the following output once the command finishes:

      ```text
      Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

      Outputs:

      instance_id = <AWS_EC2_ID>
      instance_public_ip = <AWS_EC2_PUBLIC_IP>
      ```

      The instance will automatically install the [Open Autonomy](https://docs.autonolas.network/open-autonomy/) framework, together with a number of dependencies. You should wait until the AWS EC2 instance is ready (typically, less than 5 minutes). The command below will wait until it is ready:

      ```bash
      aws ec2 wait instance-status-ok --instance-ids <AWS_EC2_ID>

      ```

   2. Generate the service deployment script:

      ```bash
      # Position on the root of the repository
      cd ../../..
      ./scripts/generate_service_deployment_script.sh
      ```

      The script will generate the file `deploy_service.sh`, which contains the necessary commands to deploy the service in the AWS EC2 instance.
   3. Deploy the agent to the AWS EC2 instance:

      ```bash
      scp ./deploy_service.sh ubuntu@<AWS_EC2_PUBLIC_IP>:~ 
      ssh ubuntu@<AWS_EC2_PUBLIC_IP> 'nohup ~/deploy_service.sh > deploy_service.log 2>&1 &'
      ```

      You might need to indicate the SSH private key path using the `-i` option on the `scp` and `ssh` commands.

4. **Interact with the AWS EC2 instance.** See Step 5 in the [section above](#deploy-the-service-using-github-actions).

5. **Destroy the infrastructure.**

   ```bash
   cd ./infra/aws/docker-compose/
   terraform destroy
   ```

   This will destroy the resources created on AWS. Alternatively, you can also remove the resources using the AWS Management Console.
