FROM bitnami/minideb:latest

RUN apt update
RUN apt upgrade -y curl apt-transport-https gpg vim
 
RUN echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/nul
RUN curl https://download.jitsi.org/jitsi-key.gpg.key | sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
RUN apt update

# https://serverless.industries/2020/05/07/debconf-unattended-package-install.en.html
RUN echo "jitsi-videobridge2 jitsi-videobridge/jvb-hostname string jitsi.nunimbus.com" | debconf-set-selections
RUN echo "jitsi-meet-web-config jitsi-meet/cert-choice select Generate a new self-signed certificate (You will later get a chance to obtain a Let's encrypt certificate)" | debconf-set-selections
RUN apt install -y jitsi-meet

RUN rm /etc/nginx/sites-enabled/*
COPY default /etc/nginx/sites-enabled/default

#RUN apt autoremove -y curl vim
RUN apt clean

RUN echo "#!/bin/bash" > /entrypoint.sh
RUN echo "nginx -g 'daemon off;'" >> /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT nginx -g 'daemon off;'
#ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["/usr/sbin/nginx", "-g", "'daemon off;'"]
