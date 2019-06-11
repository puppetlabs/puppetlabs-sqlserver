# sqlserver testing

## Overview

The sqlserver module is tested at the unit and acceptance level. Those tests are found in the spec/unit and spec/acceptance directory respectively. Acceptance level tests are run using either a master and agent setup or just an aget. This is accomplished via use of testmode-switcher technology. The module's tests also utilize test-tiers.

## Running Module Tests
This section will instruct you on how to run the unit and acceptance tests.

### General Setup Steps:
Option 1 - using Bundler:
1. Install Bundler
```
gem install bundler
```
2. Install dependent gems
```
bundle install --path .bundle/gems
```
3. To see what tasks are available run
```
bundle exec rake -T
```

Option 2 - if not using Bundler, then install the dependent gems.

Puppet's default is to use Bundler, as such the rest of this document will assume use thereof.


### Unit Tests
To run the unit  tests simply type
```
bundle exec rake spec
```

### Acceptance Tests

#### System Under Test
The Acceptance tets run on either a master and agent system or just on a stand-alone agent machine depending on what test mode you have delcared. With BEAKER_TESTMODE=agent the tests run using a master and an agent. With BEAKER_TESTMODE=apply the tests will run on only the agent.

#### Generate Hosts File
First use beaker-hostgenerator to set up a hosts.yml to feed to the acceptance tests by running:

```
bundle exec beaker-hostgenerator windows2012r2-64sql_host%2Cdefault.a%7Bsql_version=2012%7D-redhat7-64mdca --hypervisor abs > spec/acceptance/nodesets/hosts.yml
```
This command assumes you're running it from the root of the sqlserver module repo.

#### Environment Variables
Several environment variables should be set in order to as closely mimic Puppet's Jenkins continuous test system as possible.

```
export ABS_RESOURCE_HOSTS="[{\"hostname\":\"<LOCATION OF WINDOWS HOST TO TEST>\",\"type\":\"win-2012r2-x86_64\",\"engine\":\"vmpooler\"},{\"hostname\":\"<LOCATION OF WINDOWS HOST TO TEST>\",\"type\":\"redhat-7-x86_64\",\"engine\":\"vmpooler\"}]"
```

e.g. replace "<LOCATION OF WINDOWS HOST TO TEST>\" with "fyzskxlt6edanll.delivery.puppetlabs.net\"

```
export ABS_RESOURCE_REQUESTS_beaker="[{\"windows2012r2-64sql_host.a%7Bsql_version=2012%7D-redhat7-64mdca\":{\"win-2012r2-x86_64\":1,\"redhat-7-x86_64\":1}, \"windows2012r2-64sql_host.a%7Bsql_version=2014%7D-redhat7-64mdca\":{\"win-2012r2-x86_64\":1,\"redhat-7-x86_64\":1}}]"

export BEAKER_setfile=spec/acceptance/nodesets/hosts.yml
export BEAKER_keyfile=/var/lib/jenkins/.ssh/id_rsa-acceptance
export BEAKER_destroy=always
export BEAKER_debug=true
export BEAKER_PE_DIR=http://enterprise.delivery.puppetlabs.net/2017.1/ci-ready
export BEAKER_PE_VER=2017.1.1
export PUPPET_INSTALL_TYPE=pe
export INSTALLATION_TYPE=pe
export BEAKER_TESTMODE=agent
export BUNDLE_PATH=.bundle/gems
export BUNDLE_BIN=.bundle/bin
export TEST_FRAMEWORK=beaker-rspec
export TEST_TIERS=low
```
Where "BEAKER_PE_DIR" should be set to whatever version of PE you're testing against.

#### Test Tiers
This module uses test-tiering a technology that allows only subsets of acceptance tests to run depending on how much risk they have been evaluated to carry among other factors such as run-time etc. The "TEST_TIERS" environment variable specifies what set of the acceptance tests to run. Since at the time of writing (7/16/17) all sqlserver module tests are tiered at the "low" level, the only way to run the acceptance tests is to specify "TEST_TIERS=low". Alternatively, if the environment variable TEST_TIERS is absent the module tests will default to runnin all the tests.

#### Executing the Acceptance Tests

bundle exec rake beaker:hosts --verbose