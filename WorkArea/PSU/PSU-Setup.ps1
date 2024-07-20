docker pull ironmansoftware/universal

docker run --name 'PSU' -it -p 5000:5000 ironmansoftware/universal:latest

docker cp '/Users/conrad.gauntlett/WorkArea/aws' PSU:/root/.aws/
