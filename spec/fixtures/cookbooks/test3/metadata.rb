# coding: utf-8
name "test3"
version "7.8.9"
maintainer "Noah Kantrowitz"
maintainer_email "noah@coderanger.net"
source_url "http://example.com/" if defined?(source_url)
license "Apache 2.0"
depends "test2", "~> 4.5.6"
chef_version ">= 3" if defined?(chef_version)
