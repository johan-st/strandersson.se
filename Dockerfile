# BUILD AND TEST
FROM debian:bullseye-slim as build

# install node and npm (apt has an old version of node, so we use the node source )
RUN apt update && apt-get install -y curl
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - 
RUN apt install -y nodejs
# No cleanup nessecary as we are using a multi-stage build

# create app directory
WORKDIR /usr/src/app

# copy package.json and package-lock.json (npm package file)
COPY package*.json ./

# install dependencies
RUN npm ci

# and elm.json (elm package file)
COPY elm.json ./

#copy source files
COPY src ./src

# test
RUN npm test

# assign build time to environment variable
ARG BUILD_TIME 
ENV BUILD_TIME=${BUILD_TIME:-unknown}
# build
RUN npm run build:noEnv

# PRODUCTION
FROM nginx:1.23.3-alpine-slim as webserver

# copy build files
COPY --from=build /usr/src/app/dist /usr/share/nginx/html

# letting nginx run with default config


