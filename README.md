# Mini test

To check for dependency updates:

    mvn versions:display-dependency-updates

## Docker

    sudo docker build --tag minitest .
    sudo docker run -p 12345:8080 --name derp minitest