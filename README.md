# nginx ui 
## Updated with Simple authentication and Nginx service reload

![Docker Image CI](https://github.com/schenkd/nginx-ui/workflows/Docker%20Image%20CI/badge.svg)

![Image of Nginx UI](https://github.com/shyjuk/nginx-ui/blob/master/app/static/nginx_ui.png)

Table of Contents
- [Quick start](#quick-start)
- [nginx ui](#nginx-ui)
  - [Introduction](#introduction)
  - [Setup](#setup)
    - [Example](#example)
    - [Docker](#docker)
  - [UI](#ui)
  - [Authentication](#authentication)


## Quick start

First, prepare your Linux server[*](#quick-start-note) with a fresh install of Ubuntu LTS or Debian.

Use this one-liner to set up an NGINX UI:

```bash
wget https://raw.githubusercontent.com/shyjuk/nginx-ui/master/scripts/nguisetup.sh -O nguisetup.sh && sudo sh nguisetup.sh
```

## Introduction

We use nginx in our company lab environment. It often happens that my
colleagues have developed an application that is now deployed in our Stage
or Prod environment. To make this application accessible nginx has to be
adapted. Most of the time my colleagues don't have the permission to access
the server and change the configuration files and since I don't feel like
doing this for everyone anymore I thought a UI could help us all. If you
feel the same way I wish you a lot of fun with the application and I am
looking forward to your feedback, change requests or even a star.

## Setup

Containerization is now state of the art and therefore the application is
delivered in a container.

### Example

- `-d` run as deamon in background
- `--restart=always` restart on crash or server reboot
- `--name nginxui` give the container a name
- `-v /etc/nginx:/etc/nginx` map the hosts nginx directory into the container
- `-p 8080:8080` map host port 8080 to docker container port 8080

```bash
docker run -d --restart=always --name nginxui -v /etc/nginx:/etc/nginx -p 8080:8080 schenkd/nginx-ui:latest
```

### Docker

Repository @ [DockerHub](https://hub.docker.com/r/schenkd/nginx-ui)

Docker Compose excerpt

```yaml
# Docker Compose excerpt
services:
  nginx-ui:
    image: schenkd/nginx-ui:latest
    ports:
      - 8080:8080
    volumes:
      - nginx:/etc/nginx
```

## UI

![Image of Nginx UI](https://i.ibb.co/qNgBRrt/Bildschirmfoto-2020-06-21-um-10-01-46.png)

With the menu item Main Config the Nginx specific configuration files
can be extracted and updated. These are dynamically read from the Nginx
directory. If a file has been added manually, it is immediately integrated
into the Nginx UI Main Config menu item.

![Image of Nginx UI](https://i.ibb.co/j85XKM6/Bildschirmfoto-2020-06-21-um-10-01-58.png)

Adding a domain opens an exclusive editing window for the configuration
file. This can be applied, deleted and enabled/disabled.

## Authentication

A basic single admin based authentication is enabled. The username and password hash is saved in the config.py file. 
To change the password create a new password using the mk_passwd.py utility under script directory and replace the value of "PASS" variable in config.py.

```none
python3 mk_passwd.py <new password>
```

