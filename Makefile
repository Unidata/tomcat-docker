
build:
	docker build -t unidata/tomcat-docker:8 .

run:
	docker-compose up unidata-tomcat
