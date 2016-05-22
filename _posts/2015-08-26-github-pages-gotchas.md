---
layout: post
title: Gotchas for using Github Pages with Jekyll
categories:
- post
---

* __How to use custom domain with github pages? something like, `blog.dynofu.me -> dyno.github.io`__

> you need to setup the CNAME file, https://help.github.com/articles/setting-up-a-custom-domain-with-github-pages/


* __Why isn't the page showing up after I commited to the github pages repository?__

> https://help.github.com/articles/troubleshooting-github-pages-build-failures/


* __I've installed `kramdown`, why do I still got `Missing dependency: kramdown`?__

> !! DEPRECATED !! https://github.com/blog/2100-github-pages-now-faster-and-simpler-with-jekyll-3-0

> I bet you are using `bundler` and running on Mac. check
> http://stackoverflow.com/questions/31417469/jekyll-ruby-kramdown-missing-dependency/32233986#32233986
> If you have the `kramdown` problem or donnot know what all these different markdown renders are,
> I would also suggest to switch to `redcarpet`.
> http://ajoz.github.io/2014/06/29/i-want-my-github-flavored-markdown/

