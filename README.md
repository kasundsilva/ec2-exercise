# Introduction

This is an exercise to satisfy the requirements from the file "SRE Team - Engineering Assignment.pdf".

The whole process has been automated using bash and cloudformation and is intended to be ran in a new/clean AWS account.

The automation creates the network and compute objects needed to perform the required tasks.

The parameters needed are set in the "input/stacks.json" file.

# Risks involved in this set up

It does not include a WAF firewall such as AWS WAF to protect the page against attacks such as SQL injection.

This instance has no protection (e.g.: AWS Shield) against DDOS attacks.

This instance does not scale automatically and does not have a load balancer, making it very hard to handle high amounts of requests caused by spikes.

# Pre-requisites and set up

- This automation uses the bash shell in its execution so, you need to either run it on a unix-based workstation (mac or linux) or,
if running on Windows, run it on a shell application such as "git bash" (https://www.stanleyulili.com/git/how-to-install-git-bash-on-windows/).
- You need an AWS account available. The one offered for free (https://aws.amazon.com/free) is more than enough for this exercise.
- Configure an AWS cli profile using the instructions from https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html and https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html.
- Set the value of "Profile" in the "input/stacks.json" file to the name of the AWS profile you set up in the previous step (this document assumes you're using a profile called "master"). Do the same for the "Region" parameter. 
- install the jq command line json processor (https://stedolan.github.io/jq/download/).

# Usage

- Access the AWS console from your web browser then go to the cloudformation service of the chosen region to follow the creation progress from there.
- Execute the following commands from your bash shell

    ```
    cd <project's folder>
    ./run.sh
    ```

- Get the logs' URL from the command line

    ```
    echo "http://$(aws ec2 describe-instances --filters Name=tag-key,Values=Name Name=tag-value,Values=Instance --profile master | jq -r .Reservations[].Instances[].PublicDnsName)/resource/resource.log"
    ```

- Access the logs' URL from the previous command using a web browser

#### To find out which word is repeated the most in the default nginx page

- Access the instance from the command line

    ```
    ssh -i output/devops-compute-admin.pem ubuntu@$(aws ec2 describe-instances --filters Name=tag-key,Values=Name Name=tag-value,Values=Instance --profile master | jq -r .Reservations[].Instances[].PublicDnsName)
    ```

- Type the following in the command line. The result will be under the "Execution" section

    ```
    /home/ubuntu/scripts/nginx-word.sh
    ```

- Get out of the ssh shell

    ```
    exit
    ```

#### Cleanup

- Access the AWS console from your web browser then go to the cloudformation service of the chosen region.
- Select the compute stack (e.g.: devops-compute) then click on "Delete". Confirm by clicking on "Delete Stack"
- Do the same to the network stack (e.g.: devops-network)

