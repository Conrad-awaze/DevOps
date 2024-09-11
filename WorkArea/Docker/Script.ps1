docker pull ironmansoftware/universal
docker pull ironmansoftware/universal:4.4.0-ubuntu-20.04


docker pull conradg69/database-monitor:1.0.0
docker pull conradg69/database-monitor-v5:1.0.0

docker run --name 'database-monitor' -it -p 5000:5000 conradg69/database-monitor:1.0.0
docker run --name 'database-monitor-v5' -it -p 5000:5000 conradg69/database-monitor-v5:1.0.0


docker commit 'database-monitor-v5' conradg69/database-monitor-v5
docker push conradg69/database-monitor-v5:latest

docker commit 'database-monitor' conradg69/database-monitor
docker push conradg69/database-monitor:latest

docker commit 'database-monitor' database-monitor
docker commit 'database-monitor-v5' database-monitor-v5



docker commit 'database-monitor' 063778477900.dkr.ecr.eu-west-2.amazonaws.com/devops-db-monitor:latest

docker image ls

aws ecr get-login-password --region eu-west-2 --profile Power_user-063778477900 | docker login --username AWS --password-stdin 063778477900.dkr.ecr.eu-west-2.amazonaws.com

aws sso login --profile Power_user-063778477900

docker push 063778477900.dkr.ecr.eu-west-2.amazonaws.com/devops-db-monitor:latest


# -------------------------------------------------------------------------------------------------------------------------------------------------- #
#                                                                    SSIO SANDPIT                                                                    #
# -------------------------------------------------------------------------------------------------------------------------------------------------- #

docker commit 'database-monitor' 587525780573.dkr.ecr.eu-west-2.amazonaws.com/dev-dba-dashboard

docker image ls

docker push 587525780573.dkr.ecr.eu-west-2.amazonaws.com/dev-dba-dashboard

aws ecr get-login-password --region eu-west-2 --profile DBA-Sandpit | docker login --username AWS --password-stdin 587525780573.dkr.ecr.eu-west-2.amazonaws.com

# multiple tags on a single image
docker tag 587525780573.dkr.ecr.eu-west-2.amazonaws.com/dev-dba-dashboard:latest 587525780573.dkr.ecr.eu-west-2.amazonaws.com/dev-dba-dashboard:1.0
docker push 587525780573.dkr.ecr.eu-west-2.amazonaws.com/dev-dba-dashboard:latest && docker push 587525780573.dkr.ecr.eu-west-2.amazonaws.com/dev-dba-dashboard:1.0

# aws ecr get-login-password --region eu-west-2 --profile DBA-Sandpit | docker login --username AWS --password-stdin 587525780573.dkr.ecr.eu-west-2.amazonaws.com
# docker push 587525780573.dkr.ecr.eu-west-2.amazonaws.com/db-dashboard:latest

# -------------------------------------------------------------------------------------------------------------------------------------------------- #

docker commit 'database-monitor-v5' 587525780573.dkr.ecr.eu-west-2.amazonaws.com/database-monitor-v5

docker image ls

docker push 587525780573.dkr.ecr.eu-west-2.amazonaws.com/database-monitor-v5

aws ecr get-login-password --region eu-west-2 --profile DBA-Sandpit | docker login --username AWS --password-stdin 587525780573.dkr.ecr.eu-west-2.amazonaws.com



docker run --name 'database-monitor' -it -p 5000:5000 database-monitor
docker run --name 'database-monitor-v5' -it -p 5000:5000 database-monitor-v5

docker run --name 'dba-dashboard-test' -it -p 5000:5000  conradg69/database-dashboard



docker login
docker images
docker ps -a

docker commit dba-dashboard-test conradg69/database-dashboard
docker push conradg69/database-dashboard



docker version

docker-compose version

docker run hello-world

docker pull ironmansoftware/universal
docker run --name 'dba-dashboard-test' -it -p 5000:5000  conradg69/database-dashboard

docker stop PSUTest
docker rm PSUTest
docker rm --force PSUTest


docker compose up -d

docker compose down


docker build . --tag=universal-persistent