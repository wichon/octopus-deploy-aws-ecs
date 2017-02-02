region=$(get_octopusvariable "Region")
cluster=$(get_octopusvariable "Cluster")
service=$(get_octopusvariable "Service")
taskDefinition=$(get_octopusvariable "TaskDefinition") 
dockerUser=$(get_octopusvariable "DockerRepoUser")
dockerPassword=$(get_octopusvariable "DockerRepoPassword")
dockerRepo=$(get_octopusvariable "DockerRepo")
dockerBuildTag=$(get_octopusvariable "DockerBuildTag")
maxRetries=15
sleepPeriod=30

i=0
echo "Checking if the Octopus Build image is registered in the Docker Hub repository ..."
while [ $i -lt $maxRetries ] && [ $(curl -s -m 2 --retry 3 --retry-delay 2 --retry-max-time 10 --user $dockerUser:$dockerPassword https://index.docker.io/v1/repositories/$dockerRepo/tags | jq ".[].name" | grep -c "$dockerBuildTag") -eq 0 ] ;
do
    echo "Octopus Build image is not registered yet, sleeping $sleepPeriod seconds and going to check back again (-_-)zzz"
    i=$[$i+1]
    sleep $sleepPeriod
done

if [ $i -eq $maxRetries ] ; then
    echo "Error!, Could not find the Octopus Build image ($dockerBuildTag) in the Docker Hub registry, deployment to AWS ECS will not continue :(."
    exit 1
fi

echo "Getting Active task defintion ..."
taskDefinitionBody=$(aws ecs describe-task-definition --region $region --task-definition $taskDefinition | jq '.taskDefinition.containerDefinitions' | jq ".[].image = \"$dockerRepo:$dockerBuildTag\"")

echo "Registering new task definition revision containing the generated image ..."
aws ecs register-task-definition --region $region --family $taskDefinition --container-definitions "$taskDefinitionBody"

echo "Updating ECS service ..."
aws ecs update-service --region $region --cluster $cluster --service $service --task-definition $taskDefinition

sleep 10
aws ecs wait services-stable --region $region --cluster $cluster --services $service

i=0
serviceDetails=$(aws ecs describe-services --region $region --cluster $cluster --services "$service" | jq '{elbName: .services[0].loadBalancers[0].loadBalancerName, desiredCount: .services[0].desiredCount }')
elbName=$(echo $serviceDetails | jq .elbName)
desiredTasks=$(echo $serviceDetails | jq .desiredCount)
echo "Checking that the load balancer has completely registered the new containers ..."
while [ $i -lt $maxRetries ] && [ ! $(aws elb describe-instance-health --load-balancer-name $(echo $elbName | sed s/\"//g) | grep InService | wc -l) -eq $desiredTasks ]
do
    echo "The load balancer has not completely registered the new container versions, sleeping $sleepPeriod seconds and going to check back again (-_-)zzz"
    i=$[$i+1]
    sleep $sleepPeriod
done

echo "Application successfully deployed"