dockerRepo=$(get_octopusvariable "DockerRepo")
dockerBuildTag=$(get_octopusvariable "DockerBuildTag") 
dockerRepoUser=$(get_octopusvariable "DockerRepoUser")
dockerRepoPassword=$(get_octopusvariable "DockerRepoPassword")
dockerRepoEmail=$(get_octopusvariable "DockerRepoEmail")

# Cd into artifacts folder
cd $(get_octopusvariable "Octopus.Action[Grab package].Output.Package.InstallationDirectoryPath")

# Build image based in the docker file included in the root of the artifacts folder
docker build -t $dockerRepo:$dockerBuildTag .

# Tag generated container with the custom tag, and the latest tag
docker tag -f $dockerRepo:$dockerBuildTag $dockerRepo:latest 

# Authenticate into Docker hub repository 
docker login -u $dockerRepoUser -e $dockerRepoEmail -p $dockerRepoPassword

# Push image to private repository with the latest and build number tags
docker push $dockerRepo:$dockerBuildTag && docker push $dockerRepo:latest
