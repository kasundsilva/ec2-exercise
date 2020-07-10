# Introduction

This is an exercise to satisfy the requirements from the file "SRE Team - Engineering Assignment.pdf".

# Pre-requisites and set up

- This automation uses the bash shell in its execution so, you need to either run it on a unix-based workstation (mac or linux) or,
if running on Windows, run it on a shell application such as "git bash" (https://www.stanleyulili.com/git/how-to-install-git-bash-on-windows/).
- You need an AWS account available. The one offered for free is more than enough. A t2.micro image is used so no charges will be made.
- Configure an AWS cli profile using the instructions from https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html.
- Set the value of "Profile" in the "input/stacks.json" file to the name of the AWS profile you set up in the previous step. 

# Usage

#### Execute the following command

```
./run.sh
```

#### Access the instance from the command line

```
ssh -i output/devops-compute-admin.pem ubuntu@ec2-54-79-119-217.ap-southeast-2.compute.amazonaws.com
```


#### Access the logs using a web browser

```
http://ec2-54-79-119-217.ap-southeast-2.compute.amazonaws.com/resource/resource.log
```

#### To find out which word is repeated the most in the default nginx page, type the following in the command line:


```
/home/ubuntu/scripts/nginx-word.sh
```



