# octopus-deploy-aws-ecs
Step Templates collection to deploy docker images to AWS ECS Cluster using [Octopus Deploy](https://octopus.com/)

## Limitations
This templates make the assumption that the task definition is composed of a single container image, for task definitions that are composed of multiple container images the step were the new task definition revision is created should be customized.

## Dependencies

### Octopus Server Depencies
* This templates depends on a Linux Agent .

### Linux Agent Dependencies
* bash
* [jq](https://stedolan.github.io/jq/)
* docker
* aws cli
  * An iam role (see below)

### Octopus Project Dependencies
* aws-ecs-deploy-template.sh
  * Variables
    * Region (AWS Region)
    * Cluster (ECS Cluster Name)
    * Service (ECS Cluster Service)
    * TaskDefinition (Task Definition family)
    * DockerRepoUser
    * DockerRepoPassword
    * DockerRepo
    * DockerBuildTag (your custom Build tag text to identify the container)
* dockerize-artifacts.sh
  * Variables
    * DockerRepoEmail
    * DockerRepoUser
    * DockerRepoPassword
    * DockerRepo
    * DockerBuildTag (your custom Build tag text to identify the container)

### AWS Dependencies
* IAM Role
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ELBPermisions",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DescribeInstanceHealth"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "ECSPermisions",
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeServices",
                "ecs:DescribeTaskDefinition",
                "ecs:RegisterTaskDefinition",
                "ecs:UpdateService",
                "ecs:ListTasks",
                "ecs:StopTask"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```
