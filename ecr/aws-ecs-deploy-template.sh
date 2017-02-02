# default value for empty (blank) variables
blankValue=$(decode_servicemessagevalue "null")
region=$(get_octopusvariable "Region")
cluster=$(get_octopusvariable "Cluster")
service=$(get_octopusvariable "Service")
taskDefinition=$(get_octopusvariable "TaskDefinition") 
taskDefinitionContainer=$(get_octopusvariable "TaskDefinitionContainer")
ecrRepositoryName=$(get_octopusvariable "EcrRepositoryName")
ecrRepositoryUrl=$(get_octopusvariable "EcrRepositoryUrl")
dockerBuildTag=$(get_octopusvariable "DockerBuildTag")
maxRetries=15
sleepPeriod=30

# ECR login
dockerLoginCommand=`aws ecr get-login --region $region`
eval $dockerLoginCommand

i=0
echo "Checking if the Octopus Build image is registered in the ECR repository ..."
while [ $i -lt $maxRetries ] && [ $(aws ecr list-images --repository-name $ecrRepositoryName | grep -c "$dockerBuildTag") -eq 0 ] ;
do
    echo "Octopus Build image is not registered yet, sleeping $sleepPeriod seconds and going to check back again (-_-)zzz"
    i=$[$i+1]
    sleep $sleepPeriod
done

if [ $i -eq $maxRetries ] ; then
    echo "Error!, Could not find the Octopus Build image ($dockerBuildTag) in the ECR repository, deployment to AWS ECS will not continue :(."
    exit 1
fi

echo "Getting Active task defintion ..."
taskDefinitionBody=$(aws ecs describe-task-definition --region $region --task-definition $taskDefinition)
taskDefinitionContainerDefinitions=""
if [ "$taskDefinitionContainer" == "$blankValue" ] ; then
    echo "Changing all container definitions image to $ecrRepositoryUrl/$ecrRepositoryName:$dockerBuildTag"
    taskDefinitionContainerDefinitions=$(echo $taskDefinitionBody | jq '.taskDefinition.containerDefinitions' | jq ".[].image = \"$ecrRepositoryUrl/$ecrRepositoryName:$dockerBuildTag\"")
else
    echo "Changing $taskDefinitionContainer container definition image to $ecrRepositoryUrl/$ecrRepositoryName:$dockerBuildTag"
    taskDefinitionContainerDefinitions=$(echo $taskDefinitionBody | jq '.taskDefinition.containerDefinitions' | jq "(.[] | select(.name == \"$taskDefinitionContainer\") | .image) = \"$ecrRepositoryUrl/$ecrRepositoryName:$dockerBuildTag\"")
fi

echo "Registering new task definition revision containing the generated image ..."
if echo $taskDefinitionBody | jq -e '.taskDefinition.taskRoleArn' > /dev/null ; then
    taskRoleArn=$(echo $taskDefinitionBody | jq '.taskDefinition.taskRoleArn' | sed s/\"//g)
    echo "Adding task role set in the latest version of the task definition ($taskRoleArn) ..."
    aws ecs register-task-definition --region $region --family $taskDefinition --task-role-arn $taskRoleArn --container-definitions "$taskDefinitionContainerDefinitions"
else
    aws ecs register-task-definition --region $region --family $taskDefinition --container-definitions "$taskDefinitionContainerDefinitions"
fi

echo "Updating ECS service ..."
aws ecs update-service --region $region --cluster $cluster --service $service --task-definition $taskDefinition | jq '.service|del(.events,.deployments)'

sleep 10
echo "Waiting for ECS service to get stable ..."
aws ecs wait services-stable --region $region --cluster $cluster --services $service

serviceDetails=$(aws ecs describe-services --region $region --cluster $cluster --services "$service" | jq '.services[0]|del(.events,.deployments)')
if echo $serviceDetails | jq -e .loadBalancers[0] > /dev/null ; then
    echo "Checking that the load balancer has completely registered the new containers ..."
    elbInfo=$(echo $serviceDetails | jq .loadBalancers[0])
    desiredTasks=$(echo $serviceDetails | jq .desiredCount)
    i=0
    if echo $elbInfo | jq -e .targetGroupArn > /dev/null ; then
        targetGroupArn=$(echo $elbInfo | jq .targetGroupArn)
        while [ $i -lt $maxRetries ] && [ ! $(aws elbv2 describe-target-health --target-group-arn $(echo $targetGroupArn | sed s/\"//g) | grep -ci healthy) -eq $desiredTasks ]
        do
            echo "The load balancer target group ($targetGroupArn) has not completely registered the new container versions, sleeping $sleepPeriod seconds and going to check back again (-_-)zzz"
            i=$[$i+1]
            sleep $sleepPeriod
        done
    else
        if echo $elbInfo | jq -e .loadBalancerName > /dev/null ; then
            elbName=$(echo $elbInfo | jq .loadBalancerName)
            while [ $i -lt $maxRetries ] && [ ! $(aws elb describe-instance-health --load-balancer-name $(echo $elbName | sed s/\"//g) | grep -ci inservice) -eq $desiredTasks ]
            do
                echo "The load balancer ($elbName) has not completely registered the new container versions, sleeping $sleepPeriod seconds and going to check back again (-_-)zzz"
                i=$[$i+1]
                sleep $sleepPeriod
            done
        fi
    fi
else
    echo "There are no load balancers attached to the service, no need for waiting for a healthy load balancer."
fi
echo "Application successfully deployed"