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