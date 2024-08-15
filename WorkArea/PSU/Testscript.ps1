docker version

docker-compose version

docker run hello-world

docker pull ironmansoftware/universal
docker run --name 'DBA-PSU' -it -p 5000:5000 -v /Users/conrad.gauntlett/WorkArea/Repos:/root ironmansoftware/universal 

docker stop DBA-PSU
docker rm --force DBA-PSUCon 