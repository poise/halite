# coding: utf-8
raise 'Halite is not compatible with no_lazy_load false, please set no_lazy_load true in your Chef configuration file.' unless Chef::Config[:no_lazy_load]
$LOAD_PATH << File.expand_path('../../files/halite_gem', __FILE__)
require "test5/dsl"
