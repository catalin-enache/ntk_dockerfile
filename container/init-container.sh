#!/bin/bash

sudo service ssh start

source ~/.rvm/scripts/rvm

exec "$@"
