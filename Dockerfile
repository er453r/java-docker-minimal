FROM openjdk:11-jdk

RUN apt-get update && apt-get install maven binutils -y

ADD . /

RUN mvn package

#RUN apt-get update && apt-get install maven

#ADD target/runtime runtime
#ADD target/mini-template-0.1.jar mini-template-0.1.jar
ENTRYPOINT /target/runtime/bin/java -jar /target/mini-template-0.1.jar
