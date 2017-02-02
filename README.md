# octopus-deploy-aws-ecs

Step Templates collection to deploy docker images to AWS ECS Cluster using [Octopus Deploy](https://octopus.com/)

## Limitations

Docker hub templates:

* Templates make the assumption that the task definition is composed of a single container image, for task definitions that are composed of multiple container images the step were the new task definition revision is created should be customized.
* The templates are still not integrated with AWS Application Load Balancers (to check for deployment status)

 Take a look to the [ecr templates](https://github.com/wichon/octopus-deploy-aws-ecs/tree/master/ecr) they support task definitions with multiple containers and application load balancers.

## Dependencies

### Octopus Server Depencies

* This templates depends on a Linux Agent .

### Linux Agent Dependencies

* bash
* [jq](https://stedolan.github.io/jq/)
* docker
* aws cli
  * An iam role (see below)

### Octopus Projects Dependencies

ECR

* aws-ecs-deploy-template.sh
  * Variables
    * Region (AWS Region)
    * Cluster (ECS Cluster Name)
    * Service (ECS Cluster Service)
    * TaskDefinition (Task Definition family)
    * TaskDefinitionContainer (The name of the container inside the task definition that will be deployed)
      * Can be empty for task definitions that only have one container.
    * EcrRepositoryUrl
    * EcrRepositoryName
    * DockerBuildTag (your custom Build tag text to identify the container)
* dockerize-artifacts.sh
  * Variables
    * Region (AWS Region)
    * EcrRepositoryUrl
    * EcrRepositoryName
    * DockerBuildTag (your custom Build tag text to identify the container)

Docker Hub

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

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ELBPermisions",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DescribeTargetHealth",
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
                "ecs:StopTask",
                "ecr:GetAuthorizationToken",
                "iam:PassRole"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```
