SHELL = /bin/bash


docker-run:
	# https://github.com/jekyll/docker/wiki/Usage:-Running
	docker run -ti -v $(PWD):/srv/jekyll -p 4000:4000 jekyll/jekyll:pages jekyll serve
