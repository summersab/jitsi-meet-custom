FROM bitnami/minideb:latest

RUN apt update
RUN apt-get upgrade -y software-properties-common apt-transport-https gpg ca-certificates curl gcc

RUN add-apt-repository 'deb http://security.debian.org/debian-security stretch/updates main'

RUN echo deb http://packages.prosody.im/debian $(lsb_release -sc) main | tee -a /etc/apt/sources.list
RUN curl https://prosody.im/files/prosody-debian-packages.key | apt-key add

RUN echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/nul
RUN curl https://download.jitsi.org/jitsi-key.gpg.key | sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'

RUN apt-get update
RUN apt-get install -y lua5.2 liblua5.2 luarocks libssl1.0-dev

RUN luarocks install basexx
RUN luarocks install luacrypto

RUN luarocks download lua-cjson
RUN luarocks unpack lua-cjson-2.1.0.6-1.src.rock
RUN sed -i 's/len = lua_objlen(l, -1);/len = lua_rawlen(l, -1);/g' /lua-cjson-2.1.0.6-1/lua-cjson/lua_cjson.c
RUN sed -i 's%\(Build defaults #\+\)%\1\nLUA_INCLUDE_DIR =   /usr/include/lua5.2%g' /lua-cjson-2.1.0.6-1/lua-cjson/Makefile

RUN luarocks make
RUN luarocks install luajwtjitsi

RUN rm -r lua-cjson-2.1.0.6-1 lua-cjson-2.1.0.6-1.src.rock

RUN echo "jitsi-videobridge2 jitsi-videobridge/jvb-hostname string meet.jitsi.local" | debconf-set-selections
RUN echo "jitsi-meet-web-config jitsi-meet/cert-choice select Generate a new self-signed certificate (You will later get a chance to obtain a Let's encrypt certificate)" | debconf-set-selections
RUN echo "jitsi-meet-tokens jitsi-meet-tokens/appsecret password JWT_APP_SECRET" | debconf-set-selections
RUN echo "jitsi-meet-tokens jitsi-meet-tokens/appid string JWT_APP_ID" | debconf-set-selections

RUN apt-get install -y prosody
RUN apt-get install -y jitsi-meet
RUN luarocks install luasec
RUN apt-get install -y jitsi-meet-tokens

RUN sed -i 's/meet.jitsi.local"/{{ .Env.JITSI_DOMAIN }}"/g' /etc/prosody/conf.avail/meet.jitsi.local.cfg.lua
RUN sed -i 's/JWT_APP_SECRET/{{ .Env.JWT_APP_SECRET }}/g' /etc/prosody/conf.avail/meet.jitsi.local.cfg.lua
RUN sed -i 's/JWT_APP_ID/{{ .Env.JWT_APP_ID }}/g' /etc/prosody/conf.avail/meet.jitsi.local.cfg.lua
RUN sed -i 's/authentication = "token"/authentication = "{{ .Env.JWT_AUTH_TYPE }}"/g' /etc/prosody/conf.avail/meet.jitsi.local.cfg.lua
RUN sed -i 's/443 ssl;/8080;/g' /etc/nginx/sites-available/meet.jitsi.local.conf

RUN apt-get autoremove gcc curl software-properties-common apt-transport-https
RUN apt-get clean

EXPOSE 8080
ENTRYPOINT nginx -g 'daemon off;'
