FROM maven:3.6.0-jdk-12-alpine as build

ADD . /

RUN \
apk add binutils && \
mvn package && \
jlink --add-modules java.base,java.desktop,java.instrument,java.logging,java.management,java.management.rmi,java.naming,java.prefs,java.rmi,java.scripting,java.security.jgss,java.sql,java.xml \
        --output runtime --no-header-files --no-man-pages --compress=2 --strip-debug && \
cp target/mini-template-0.1.jar runtime/bin/app.jar && \
find runtime -name '*.so' -exec strip -p --strip-unneeded {} \; && \
echo -e "\n[JLINK DIFF]\n$(du -d1 -h runtime | tail -n1)\n$(du -d1 -h $JAVA_HOME | tail -n1)\n"

FROM alpine:latest
COPY --from=build runtime /runtime
ENTRYPOINT /runtime/bin/java -jar /runtime/bin/app.jar
