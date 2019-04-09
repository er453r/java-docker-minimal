FROM adoptopenjdk/openjdk11:alpine as build
ADD . /
RUN \
apk add binutils maven && \
mvn package && \
cd target && \
jar xf *.jar && \
cd - && \
jdeps --multi-release 11 target/*.jar target/BOOT-INF/lib/*.jar | egrep -o 'java\.[a-z\.]+' | sort | uniq > deps.txt && \
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

RUN apk --update add --no-cache --virtual .build-deps curl binutils \
    && GLIBC_VER="2.29-r0" \
    && ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" \
    && GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-8.2.1%2B20180831-1-x86_64.pkg.tar.xz" \
    && GCC_LIBS_SHA256=e4b39fb1f5957c5aab5c2ce0c46e03d30426f3b94b9992b009d417ff2d56af4d \
    && ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.9-1-x86_64.pkg.tar.xz" \
    && ZLIB_SHA256=bb0959c08c1735de27abf01440a6f8a17c5c51e61c3b4c707e988c906d3b7f67 \
    && curl -Ls https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/${GLIBC_VER}.apk \
    && apk add /tmp/${GLIBC_VER}.apk \
    && curl -Ls ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz \
    && echo "${GCC_LIBS_SHA256}  /tmp/gcc-libs.tar.xz" | sha256sum -c - \
    && mkdir /tmp/gcc \
    && tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc \
    && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib \
    && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
    && curl -Ls ${ZLIB_URL} -o /tmp/libz.tar.xz \
    && echo "${ZLIB_SHA256}  /tmp/libz.tar.xz" | sha256sum -c - \
    && mkdir /tmp/libz \
    && tar -xf /tmp/libz.tar.xz -C /tmp/libz \
    && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib \
    && apk del --purge .build-deps \
    && rm -rf /tmp/${GLIBC_VER}.apk /tmp/gcc /tmp/gcc-libs.tar.xz /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*

ENTRYPOINT /runtime/bin/java -jar /runtime/bin/app.jar
