FROM ubuntu:20.04 as ubuntu-base

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
        sudo \
        supervisor \
        xvfb x11vnc novnc websockify \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN cp /usr/share/novnc/vnc.html /usr/share/novnc/index.html

COPY scripts/* /opt/bin/

# Add Supervisor configuration file
COPY supervisord.conf /etc/supervisor/

# Relaxing permissions for other non-sudo environments
RUN  mkdir -p /var/run/supervisor /var/log/supervisor \
    && chmod -R 777 /opt/bin/ /var/run/supervisor /var/log/supervisor /etc/passwd \
    && chgrp -R 0 /opt/bin/ /var/run/supervisor /var/log/supervisor \
    && chmod -R g=u /opt/bin/ /var/run/supervisor /var/log/supervisor

# Creating base directory for Xvfb
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix
EXPOSE 25565

CMD ["/opt/bin/entry_point.sh"]

#============================
# Utilities
#============================
FROM ubuntu-base as ubuntu-utilities

RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
        firefox htop terminator gnupg2 software-properties-common \
    && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt install -qqy --no-install-recommends ./google-chrome-stable_current_amd64.deb \
    && apt-add-repository ppa:remmina-ppa-team/remmina-next \
    && apt update \
    && apt install -qqy --no-install-recommends remmina remmina-plugin-rdp remmina-plugin-secret \
    && apt-add-repository ppa:obsproject/obs-studio \
    && apt update \
    && apt install -qqy --no-install-recommends obs-studio \
    && apt install unzip \
    && apt-get autoclean \
    && apt-get autoremove \
    && apt install curl \
    && curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc |  tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" |  tee /etc/apt/sources.list.d/ngrok.list &&  apt update &&  apt install ngrok \
    && curl -s https://packagecloud.io/install/repositories/pufferpanel/pufferpanel/script.deb.sh | os=ubuntu dist=jammy bash \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# COPY conf.d/* /etc/supervisor/conf.d/


#============================
# GUI
#============================
FROM ubuntu-utilities as ubuntu-ui

ENV SCREEN_WIDTH=1280 \
    SCREEN_HEIGHT=720 \
    SCREEN_DEPTH=24 \
    SCREEN_DPI=96 \
    DISPLAY=:99 \
    DISPLAY_NUM=99 \
    UI_COMMAND=/usr/bin/startxfce4

# RUN apt-get update -qqy \
#     && apt-get -qqy install \
#         xserver-xorg xserver-xorg-video-fbdev xinit pciutils xinput xfonts-100dpi xfonts-75dpi xfonts-scalable kde-plasma-desktop

FROM ubuntu-utilities as ubuntu-ui

RUN apt-get update -qqy \
    && apt-get -qqy install --no-install-recommends \
        dbus-x11 xfce4 \
        openjdk-8-jre \
        wget \
    && wget https://dl.pufferpanel.com/pufferpanel-2.2.3.deb \
    && apt-get -qqy install --no-install-recommends ./pufferpanel-2.2.3.deb \
    && curl -s https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -o /tmp/ngrok.zip \
    && unzip /tmp/ngrok.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/ngrok \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*
