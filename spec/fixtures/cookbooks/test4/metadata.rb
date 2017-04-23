# coding: utf-8
name "test4"
version "2.3.1"
maintainer "Noah Kantrowitz"
maintainer_email "noah@coderanger.net"
source_url "http://example.com/" if defined?(source_url)
issues_url "http://issues" if defined?(issues_url)
license "Apache 2.0"
chef_version "< 99", ">= 1" if defined?(chef_version)
supports "ubuntu"
supports "debian"
supports "centos"
supports "redhat"
supports "fedora"
