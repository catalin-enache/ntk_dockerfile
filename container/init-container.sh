#!/bin/bash

source ~/.rvm/scripts/rvm
source ~/python2/bin/activate

echo installing default gems ...
bundle install --gemfile ~/default_gems.txt

sudo service ssh start

exec "$@"
