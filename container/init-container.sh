#!/bin/bash

source ~/.rvm/scripts/rvm

echo installing default gems ...
bundle install --gemfile ~/default_gems.txt

sudo service ssh start

exec "$@"
