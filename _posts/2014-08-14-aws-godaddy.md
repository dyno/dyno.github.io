---
layout: post
title: AWS Dynamic IP with GoDaddy Domain Name
categories:
- post
---

I am trying to experiment the AWS with Free Usage Tiers. After I brought up an EC2 instance (Virtual Machine),
The immediate next question is how to access it? The instance comes with a dynamic but public accessible IP address.
ssh to it can be done with an access certificate with [__shellinabox__](https://github.com/shellinabox/shellinabox).
I got a nice web terminal to workaround the proxy problem.

But one thing is still quite annoying - the public domain name is too long, and the ip address is dynamic.
Certainly we want something like [Free Dynamic DNS noip](http://www.noip.com/free). And there are tools just for that like ```noip4aws```.

My problem however is a little bit different, I have purchased a domain name from `GoDaddy`,
But `GoDaddy` does not have API for me to update my ip address mapping - almost exactly the problem
this [stackoverflow thread](http://stackoverflow.com/questions/17568892/aws-ec2-godaddy-domain-how-to-point) trying to address.

---

## The Solution ##

Here comes in __freedns.afraid.org__ which provide DNS server that can be accessed through their API.
In a word, let my GoDaddy registered domain name resolve by `afraid.org`'s DNS server which I programmatically updated from my EC2 instance.

* Starts from here `http://freedns.afraid.org/domain/ => "Add a Domain to FreeDNS" => say my domain name, dynofu.me`
* Point GoDaddy to use afraid.org's DNS server to resolve your domain name. e.g.
    `DYNOFU.ME(change to your domain name) => Settings => NameSevers => add NS1.AFRAID.ORG, NS2.AFRAID.ORG,` ...
* Inside my Ubuntu VM Instance, add [`/etc/crons.hourly/afraid.aws.sh`](http://freedns.afraid.org/scripts/afraid.aws.sh.txt),
  only need to modify `DIRECT_URL`. (The script also shows me how to get the public ip address inside the instance...)

This method does have its own shortcoming - somebody else can create a subdomain under your domain name
if you are not a payed user of `afraid.org` but that is not my primary concern anyway.

Now I am satisfied to visit my domain name without bothering with the "what is my instance's current IP address" problem.

