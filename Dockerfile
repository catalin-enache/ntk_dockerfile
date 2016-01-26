
FROM ubuntu:14.04

ENV USER="app" \
    RUBY="2.2" \
    DEBIAN_FRONTEND="noninteractive"

# for using apt-get
RUN apt-get update -q
# for using apt-add-repository
RUN apt-get install -y software-properties-common
# in order to find rubyX.Y-dev
RUN apt-add-repository ppa:brightbox/ruby-ng
# update again after adding custom repos
RUN apt-get update -q
# now we should find everything
RUN apt-get install -y \
    nano \
    build-essential \
    libssl-dev \
    libpq-dev \
    python-dev \
    software-properties-common  \
    curl \
    gnupg2
# install NOW packages that will be reported later as missing by "rvm autolibs read-fail"
RUN apt-get install -y gawk libreadline6-dev libyaml-dev libsqlite3-dev sqlite3 autoconf libgdbm-dev libncurses5-dev automake libtool bison pkg-config libffi-dev


# ==================== create $USER ==================
RUN adduser --disabled-password --gecos "" $USER && \
    adduser $USER sudo
# ==================== END create $USER ==================


# ==================== set user passwd for ssh [DEV] ==================
RUN echo $USER:pass | chpasswd # let $USER have a password for allowing sudo
# ==================== END set user passwd for ssh ==================


# ==================== bashrc [DEV] ==================
#ADD container/bashrc.txt /tmp/bashrc.txt
#RUN cat /tmp/bashrc.txt >> /home/$USER/.bashrc
# ==================== END bashrc ==================


# ==================== openssh-server [DEV] ==================
# http://superuser.com/questions/844101/docker-login-via-ssh-always-asks-for-password/844112
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd
COPY container/authorized_keys /home/$USER/.ssh/authorized_keys
RUN chown $USER /home/$USER/.ssh/authorized_keys && \
    chown -R $USER:$USER /home/$USER/.ssh/authorized_keys && \
    chmod 700 /home/$USER/.ssh/authorized_keys
EXPOSE 22
# at init we have to run: service ssh start
# ==================== END openssh-server ==================




# ==================== rvm, ruby, bundler ==================
USER $USER
RUN gpg  --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    /bin/bash -l -c "source /home/$USER/.rvm/scripts/rvm" && \
    /bin/bash -l -c "rvm autolibs read-fail" && \
    /bin/bash -l -c "rvm install $RUBY" && \
    /bin/bash -l -c "rvm use $RUBY --default" && \
    /bin/bash -l -c "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc" && \
    /bin/bash -l -c "gem install bundler --no-ri --no-rdoc" && \
    /bin/bash -l -c "echo 'export PATH="\$HOME/.rvm/bin:\$PATH" && source ~/.rvm/scripts/rvm' >> ~/.bashrc"
# ==================== END rvm, ruby, bundler ==================


USER root
ADD container/init-container.sh /usr/bin/init-container
RUN chmod +x /usr/bin/init-container
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
CMD ["/bin/bash", "/usr/bin/init-container"]



