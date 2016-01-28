
FROM ubuntu:14.04


RUN apt-get update -q \
    && apt-get install -y software-properties-common \
    && apt-add-repository -y ppa:brightbox/ruby-ng \
    && add-apt-repository -y ppa:fkrull/deadsnakes \
    && add-apt-repository -y ppa:fkrull/deadsnakes-python2.7 \
    && apt-get update -q \
    && apt-get install -y \
    nano \
    locate \
    whois \
    build-essential \
    libssl-dev \
    libpq-dev \
    python-dev \
    software-properties-common  \
    curl \
    gnupg2 \
    git \
    ruby2.3-dev
# ruby2.3-dev is not required  by "rmv requirements" or "rvm autolibs read-fail" but actually we will need it.
# Install NOW packages that will be reported later as missing by "rvm autolibs read-fail"
RUN apt-get install -y gawk libreadline6-dev libyaml-dev libsqlite3-dev sqlite3 autoconf libgdbm-dev libncurses5-dev automake libtool bison pkg-config libffi-dev



ENV USER="app" \
    RUBY="2.3.0" \
    NODEJS="5.5.0" \
    PYTHON2="2.7" \
    PYTHON3="3.5" \
    DEBIAN_FRONTEND="noninteractive"


# ==================== create $USER ==================
# create user $USER and make it sudo. Also make sudo passwordless.
RUN adduser --disabled-password --gecos "" $USER \
    && adduser $USER sudo \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
# ==================== END create $USER ==================


# ==================== set user passwd for ssh [DEV] ==================
# RUN echo $USER:pass | chpasswd # let $USER have a password ... ?
# ==================== END set user passwd for ssh ==================


# ==================== bashrc [DEV] ==================
COPY container/bashrc.txt /tmp/bashrc.txt
RUN cat /tmp/bashrc.txt >> /home/$USER/.bashrc
# ==================== END bashrc ==================


# ==================== openssh-server [DEV] ==================
# http://superuser.com/questions/844101/docker-login-via-ssh-always-asks-for-password/844112
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd
COPY container/authorized_keys /home/$USER/.ssh/authorized_keys
RUN chown $USER /home/$USER/.ssh/authorized_keys \
    && chown -R $USER:$USER /home/$USER/.ssh/authorized_keys \
    && chmod 700 /home/$USER/.ssh/authorized_keys
EXPOSE 22
# at init we have to run: service ssh start
# ==================== END openssh-server ==================


# ==================== rvm, ruby, bundler ==================
USER $USER
RUN gpg  --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 \
    && curl -sSL https://get.rvm.io | bash -s stable \
    && /bin/bash -l -c "source /home/$USER/.rvm/scripts/rvm" \
    && /bin/bash -l -c "rvm autolibs read-fail" \
    && /bin/bash -l -c "rvm install $RUBY" \
    && /bin/bash -l -c "rvm use $RUBY --default" \
    && echo 'gem: --no-ri --no-rdoc' > ~/.gemrc \
    && /bin/bash -l -c "gem install bundler --no-ri --no-rdoc" \
    && echo 'source ~/.rvm/scripts/rvm' >> ~/.bashrc
COPY container/default_gems.txt /home/$USER/default_gems.txt
# ==================== END rvm, ruby, bundler ==================


# ==================== nvm, nodejs ======================
RUN /bin/bash -l -c "git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags`" \
    && echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm' >> ~/.bashrc \
    && /bin/bash -l -c ". $HOME/.nvm/nvm.sh \
                            && nvm install $NODEJS \
                            && nvm alias default $NODEJS \
                            && nvm use default \
                            && npm install -g node-gyp"
# ==================== END nvm, nodejs ==================


# ==================== python ==========================
USER root
RUN apt-get install -y python$PYTHON2 python$PYTHON3 python$PYTHON2-dev python$PYTHON3-dev \
    && curl -sSL https://bootstrap.pypa.io/get-pip.py | python \
    && pip install --upgrade ndg-httpsclient \
    && pip install -U distribute \
    && pip install virtualenv
USER $USER
RUN mkdir /home/$USER/python$PYTHON2 /home/$USER/python$PYTHON3 \
    && virtualenv -p /usr/bin/python$PYTHON2 /home/$USER/python2 \
    && virtualenv -p /usr/bin/python$PYTHON3 /home/$USER/python3 \
    && echo "alias 'py2=source ~/python2/bin/activate'" >> ~/.bashrc \
    && echo "alias 'py3=source ~/python3/bin/activate'" >> ~/.bashrc \
    && echo "source ~/python3/bin/activate" >> ~/.bashrc
# ==================== END python ======================

USER root
EXPOSE 80 443 3000 8080 8000
COPY container/init-container.sh /usr/bin/init-container
RUN chmod +x /usr/bin/init-container
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENTRYPOINT ["/usr/bin/init-container"]
CMD ["/bin/bash"]

USER $USER



