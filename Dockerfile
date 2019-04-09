FROM maven:3.6.0-jdk-12-alpine as build
ADD . /
RUN \
apk add binutils && \
mvn package && \
cd target && \
jar xf *.jar && \
cd - && \
jdeps --multi-release 12 target/*.jar target/BOOT-INF/lib/*.jar | egrep -o 'java\.[a-z\.]+' | sort | uniq > deps.txt && \
java --list-modules | egrep -o 'java\.[a-z\.]+' | sort | uniq > modules.txt && \
comm -12 deps.txt modules.txt > common.txt && \
comm -13 deps.txt modules.txt > unused.txt && \
echo -e "\n[Found jdk modules]\n$(cat modules.txt)" && \
echo -e "\n[Found jdk dependecies]\n$(cat deps.txt)" && \
echo -e "\n[Found common jdk dependecies]\n$(cat common.txt)" && \
echo -e "\n[Found unused jdk dependecies]\n$(cat unused.txt)" && \
jlink --add-modules $(cat common.txt | tr '\n' ',') --output runtime --no-header-files --no-man-pages --compress=2 --strip-debug && \
cp target/*.jar runtime/bin/app.jar && \
find runtime -name '*.so' -exec strip -p --strip-unneeded {} \; && \
echo -e "\n[jlink diff]\n$(du -d1 -h runtime | tail -n1)\n$(du -d1 -h $JAVA_HOME | tail -n1)\n"

FROM alpine:latest
COPY --from=build runtime /runtime
ENTRYPOINT /runtime/bin/java -jar /runtime/bin/app.jar
