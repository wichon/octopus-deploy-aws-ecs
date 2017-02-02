ecrRepositoryName=$(get_octopusvariable "EcrRepositoryName")
ecrRepositoryUrl=$(get_octopusvariable "EcrRepositoryUrl")
dockerBuildTag=$(get_octopusvariable "DockerBuildTag")
region=$(get_octopusvariable "Region")

# Cd into artifacts folder
cd $(get_octopusvariable "Octopus.Action[Grab Package].Output.Package.InstallationDirectoryPath")

# ECR login
dockerLoginCommand=`aws ecr get-login --region $region`
eval $dockerLoginCommand

docker build --no-cache -t $ecrRepositoryName:$dockerBuildTag .

docker tag -f $ecrRepositoryName:$dockerBuildTag $ecrRepositoryUrl/$ecrRepositoryName:$dockerBuildTag
docker tag -f $ecrRepositoryName:$dockerBuildTag $ecrRepositoryUrl/$ecrRepositoryName:latest

docker push $ecrRepositoryUrl/$ecrRepositoryName:$dockerBuildTag
docker push $ecrRepositoryUrl/$ecrRepositoryName:latest