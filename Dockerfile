FROM openjdk:11-jdk

RUN apt-get update && apt-get install maven binutils -y

ADD . /

RUN mvn package

RUN jlink --add-modules java.base,java.desktop,java.instrument,java.logging,java.management,java.management.rmi,java.naming,java.prefs,java.rmi,java.scripting,java.security.jgss,java.sql,java.xml \
        --output /runtime --no-header-files --no-man-pages --compress=2 --strip-debug

RUN find /runtime/ -name '*.so' -exec strip -p --strip-unneeded {} \;

ENTRYPOINT /runtime/bin/java -jar /target/mini-template-0.1.jar
