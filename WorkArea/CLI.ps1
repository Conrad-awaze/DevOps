# aws configure sso

# aws ecr get-login-password --region eu-west-2 --profile devops-sandbox | docker login --username AWS --password-stdin 063778477900.dkr.ecr.eu-west-2.amazonaws.com
# docker push 063778477900.dkr.ecr.eu-west-2.amazonaws.com/devops-db-monitor:latest

docker image tag 8bae355d7342 063778477900.dkr.ecr.eu-west-2.amazonaws.com/devops-db-monitor
docker push 063778477900.dkr.ecr.eu-west-2.amazonaws.com/devops-db-monitor:latest

docker image ls

063778477900.dkr.ecr.eu-west-2.amazonaws.com/devops-db-monitor:latest

# docker run --name 'PSU' -it -p 5000:5000 ironmansoftware/universal
# docker run --name 'DB-Monitor' -it  ironmansoftware/universal