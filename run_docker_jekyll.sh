#!/bin/bash

set -x

docker run -ti -v $PWD:/srv/jekyll -p 4000:4000 jekyll/jekyll \
  bash -c "bundler exec jekyll serve --watch"
