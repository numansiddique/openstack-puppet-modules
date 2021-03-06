#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: neutron::agents:metering
#
# Setups Neutron metering agent.
#
# === Parameters
#
# [*package_ensure*]
#   (optional) Ensure state for package. Defaults to 'present'.
#
# [*enabled*]
#   (optional) Enable state for service. Defaults to 'true'.
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*debug*]
#   (optional) Show debugging output in log. Defaults to false.
#
# [*interface_driver*]
#   (optional) Defaults to 'neutron.agent.linux.interface.OVSInterfaceDriver'.
#
# [*driver*]
#   (optional) Defaults to 'neutron.services.metering.drivers.noop.noop_driver.NoopMeteringDriver'.
#
# [*measure_interval*]
#   (optional) Interval between two metering measures.
#   Defaults to 30.
#
# [*report_interval*]
#   (optional) Interval between two metering reports.
#   Defaults to 300.
#
# === Deprecated Parameters
#
# [*use_namespaces*]
#   (optional) Deprecated. 'True' value will be enforced in future releases.
#   Allow overlapping IP (Must have kernel build with
#   CONFIG_NET_NS=y and iproute2 package that supports namespaces).
#   Defaults to $::os_service_default.
#

class neutron::agents::metering (
  $package_ensure   = present,
  $enabled          = true,
  $manage_service   = true,
  $debug            = false,
  $interface_driver = 'neutron.agent.linux.interface.OVSInterfaceDriver',
  $driver           = 'neutron.services.metering.drivers.noop.noop_driver.NoopMeteringDriver',
  $measure_interval = $::os_service_default,
  $report_interval  = $::os_service_default,
  # DEPRECATED PARAMETERS
  $use_namespaces   = $::os_service_default,
) {

  include ::neutron::params

  Neutron_config<||>                ~> Service['neutron-metering-service']
  Neutron_metering_agent_config<||> ~> Service['neutron-metering-service']

  # The metering agent loads both neutron.ini and its own file.
  # This only lists config specific to the agent.  neutron.ini supplies
  # the rest.
  neutron_metering_agent_config {
    'DEFAULT/debug':              value => $debug;
    'DEFAULT/interface_driver':   value => $interface_driver;
    'DEFAULT/driver':             value => $driver;
    'DEFAULT/measure_interval':   value => $measure_interval;
    'DEFAULT/report_interval':    value => $report_interval;
  }

  if ! is_service_default ($use_namespaces) {
    warning('The use_namespaces parameter is deprecated and will be removed in future releases')
    neutron_metering_agent_config {
      'DEFAULT/use_namespaces':   value => $use_namespaces;
    }
  }

  if $::neutron::params::metering_agent_package {
    Package['neutron']            -> Package['neutron-metering-agent']
    package { 'neutron-metering-agent':
      ensure => $package_ensure,
      name   => $::neutron::params::metering_agent_package,
      tag    => ['openstack', 'neutron-package'],
    }
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
    Package['neutron'] ~> Service['neutron-metering-service']
    if $::neutron::params::metering_agent_package {
      Package['neutron-metering-agent'] ~> Service['neutron-metering-service']
    }
  }

  service { 'neutron-metering-service':
    ensure  => $service_ensure,
    name    => $::neutron::params::metering_agent_service,
    enable  => $enabled,
    require => Class['neutron'],
    tag     => 'neutron-service',
  }
}
