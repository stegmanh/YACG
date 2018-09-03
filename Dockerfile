ARG VERSION=8u151

FROM openjdk:11-jdk as BUILD

COPY . /src

WORKDIR /src
RUN ./gradlew build

FROM openjdk:11-jre


COPY --from=BUILD /src/client /bin/runner/client
COPY --from=BUILD /src/build/libs/set.jar /bin/runner/run.jar
WORKDIR /bin/runner

CMD ["java","-jar","run.jar"]
