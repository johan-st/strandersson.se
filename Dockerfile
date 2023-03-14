# -------------- #
# BUILD AND TEST #
# -------------- #
FROM debian:bullseye-slim as build

# install node and npm (apt has an old version of node, so we use the node source )
RUN apt update && apt-get install -y curl
RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash -
RUN apt install -y nodejs
# No cleanup nessecary as we are using a multi-stage build

# create app directory
WORKDIR /usr/src/app

# npm package file and lock file
COPY package*.json ./

# install dependencies
RUN npm ci

# typescript config file
COPY tsconfig.json ./

# elm package file
COPY elm.json ./

# copy static files
COPY static ./static

# copy source files
COPY src ./src

# test, typecheck and build
RUN npm test && npm run type && npm run build

# Workaround for issue where static files where not moved on build
RUN mv ./static/* ./dist/

# ---------- #
# PRODUCTION #
# ---------- #
FROM nginx:1.23.3-alpine-slim as webserver

# copy nginx main config
COPY nginx/nginx.conf /etc/nginx/

# Remove default configuration.
RUN rm -r /etc/nginx/conf.d

# add our own conf.d with specifics for strandersson.se
COPY nginx/conf.d/ /etc/nginx/conf.d/

# last layer because it's most likely to change.
# copy build files
COPY --from=build /usr/src/app/dist /usr/share/nginx/strandersson.se
