<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v5.0.3](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v5.0.3) - 2025-02-18

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v5.0.2...v5.0.3)

### Fixed

- (CAT-2222) Update legacy facts [#485](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/485) ([amitkarsale](https://github.com/amitkarsale))

## [v5.0.2](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v5.0.2) - 2024-07-18

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v5.0.1...v5.0.2)

### Fixed

- (CAT-1939) Reverting deferred function changes [#477](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/477) ([Ramesh7](https://github.com/Ramesh7))

## [v5.0.1](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v5.0.1) - 2024-02-22

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v5.0.0...v5.0.1)

### Fixed

- (CAT-1728) - Unable to use password function as deferred function [#469](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/469) ([Ramesh7](https://github.com/Ramesh7))

## [v5.0.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v5.0.0) - 2024-02-16

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v4.1.0...v5.0.0)

### Changed

- [CAT-1065] : Removing support for SQL Server 2012 [#455](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/455) ([rajat-puppet](https://github.com/rajat-puppet))

### Added

- (CAT-1148) Conversion of ERB to EPP [#454](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/454) ([praj1001](https://github.com/praj1001))

### Fixed

- (Bug) - Remove default switch of UpdateEnabled=false when Action=Install [#466](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/466) ([jordanbreen28](https://github.com/jordanbreen28))
- (bugfix) Update Issues URL [#456](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/456) ([pmcmaw](https://github.com/pmcmaw))

## [v4.1.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v4.1.0) - 2023-06-27

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v4.0.0...v4.1.0)

### Added

- pdksync - (MAINT) - Allow Stdlib 9.x [#438](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/438) ([LukasAud](https://github.com/LukasAud))
- (CONT-567) allow deferred function for password [#436](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/436) ([Ramesh7](https://github.com/Ramesh7))

## [v4.0.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v4.0.0) - 2023-04-26

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v3.3.0...v4.0.0)

### Changed

- (CONT-800) - Add Puppet 8/Drop Puppet 6 [#430](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/430) ([jordanbreen28](https://github.com/jordanbreen28))

## [v3.3.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v3.3.0) - 2023-03-07

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v3.2.1...v3.3.0)

### Added

- (CONT-490) - Add support for SQL Server 2022 [#420](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/420) ([jordanbreen28](https://github.com/jordanbreen28))

### Fixed

- Fix puppet strings formatting [#414](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/414) ([GSPatton](https://github.com/GSPatton))

## [v3.2.1](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v3.2.1) - 2022-12-13

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v3.2.0...v3.2.1)

### Fixed

- (CONT-370) Reinstate lost sqlserver documentation on feature & tool deprecations [#412](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/412) ([GSPatton](https://github.com/GSPatton))

## [v3.2.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v3.2.0) - 2022-08-23

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v3.1.0...v3.2.0)

### Added

- (CAT-136) Update dependencies [#405](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/405) ([LukasAud](https://github.com/LukasAud))

## [v3.1.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v3.1.0) - 2022-05-30

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v3.0.0...v3.1.0)

### Added

- pdksync - (FM-8922) - Add Support for Windows 2022 [#397](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/397) ([david22swan](https://github.com/david22swan))
- (MODULES-5472) Login values can now be passed as sensitive strings [#393](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/393) ([david22swan](https://github.com/david22swan))

### Fixed

- (MODULES-10825) - Dotnet installation fix [#392](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/392) ([david22swan](https://github.com/david22swan))

## [v3.0.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v3.0.0) - 2021-03-03

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v2.6.2...v3.0.0)

### Changed

- pdksync - Remove Puppet 5 from testing and bump minimal version to 6.0.0 [#369](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/369) ([carabasdaniel](https://github.com/carabasdaniel))

### Added

- pdksync - (feat) - Add support for Puppet 7 [#363](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/363) ([daianamezdrea](https://github.com/daianamezdrea))

### Fixed

- (FM-8879) Handle T-SQL Errors Properly [#349](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/349) ([RandomNoun7](https://github.com/RandomNoun7))

## [v2.6.2](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v2.6.2) - 2020-01-21

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v2.6.1...v2.6.2)

### Fixed

- (MODULES-10384) - Registry value check tightened [#343](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/343) ([david22swan](https://github.com/david22swan))
- (MODULES-10335) - Update exec's title to be unique [#341](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/341) ([david22swan](https://github.com/david22swan))

## [v2.6.1](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v2.6.1) - 2020-01-20

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v2.6.0...v2.6.1)

### Fixed

- (MODULES-10388) fix missing gem [#339](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/339) ([sheenaajay](https://github.com/sheenaajay))

## [v2.6.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v2.6.0) - 2019-10-22

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/v2.5.1...v2.6.0)

### Added

- Add support for Server 2019 [#327](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/327) ([sanfrancrisko](https://github.com/sanfrancrisko))

## [v2.5.1](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/v2.5.1) - 2019-09-20

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.5.0...v2.5.1)

### Fixed

- (MODULES-9912) ERB Template Errors [#320](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/320) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-6904) Restart SQL Server Service with Dependent Services [#315](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/315) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-8439) Fix sqlserver_instances custom fact [#314](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/314) ([carabasdaniel](https://github.com/carabasdaniel))
- (MODULES-8600) add DQC to sqlserver_features [#313](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/313) ([tphoney](https://github.com/tphoney))

## [2.5.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/2.5.0) - 2019-03-26

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.4.0...2.5.0)

### Added

- (MODULES-8610) Add start agent job task [#301](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/301) ([RandomNoun7](https://github.com/RandomNoun7))

### Fixed

- (MODULES-8749) Make job_name param required. [#303](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/303) ([RandomNoun7](https://github.com/RandomNoun7))

### Other

- (MAINT) Increase timeout interval [#306](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/306) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-8761) Docs release review [#305](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/305) ([clairecadman](https://github.com/clairecadman))

## [2.4.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/2.4.0) - 2019-03-12

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.3.0...2.4.0)

### Other

- Release Prep 2.4.0 [#298](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/298) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-8721) README edit [#297](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/297) ([clairecadman](https://github.com/clairecadman))
- (MODULES-8677) Made resource title unique among many instances [#296](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/296) ([dylanratcliffe](https://github.com/dylanratcliffe))
- (MODULES-8685) Changed END to be in the same conditional as BEGIN [#295](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/295) ([dylanratcliffe](https://github.com/dylanratcliffe))
- (MODULES-8692) Get Agent Jobs Task [#294](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/294) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-8606) Add SQL Logins Tasks [#291](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/291) ([RandomNoun7](https://github.com/RandomNoun7))
- (MAINT) Migrate test resources to artifactory - Fix Pipelines. [#290](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/290) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-8489) Mergeback to master [#289](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/289) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))

## [2.3.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/2.3.0) - 2019-01-22

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.2.0...2.3.0)

### Other

- (MODULES-8485) Release Prep 2.3.0 [#288](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/288) ([RandomNoun7](https://github.com/RandomNoun7))
- (MAINT) Fix changelog. [#287](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/287) ([RandomNoun7](https://github.com/RandomNoun7))
- Updated license terms [#286](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/286) ([turbodog](https://github.com/turbodog))
- (MODULES-8438) Install 2019 [#285](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/285) ([RandomNoun7](https://github.com/RandomNoun7))
- (maint) Update pdk template [#284](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/284) ([jpogran](https://github.com/jpogran))
- (MODULES-8130) Merge-back of release to master [#283](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/283) ([glennsarti](https://github.com/glennsarti))
- MODULES-7734 Detect installed features with value greater than 1 [#274](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/274) ([GrammatonKlaric](https://github.com/GrammatonKlaric))

## [2.2.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/2.2.0) - 2018-12-04

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.1.1...2.2.0)

### Other

- Update Release Date In Changelog [#281](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/281) ([RandomNoun7](https://github.com/RandomNoun7))
- (MAINT) fix CHANGELOG compare link [#280](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/280) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- (MODULES-8126) release prep for 2.2.0 [#279](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/279) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- (L10n) Updating translations for readmes/README_ja_JP.md [#278](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/278) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- (MODULES-7833) Update metadata for Puppet 6 [#277](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/277) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- (maint) Spec fixes [#273](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/273) ([Iristyle](https://github.com/Iristyle))
- pdksync - (MODULES-7658) use beaker4 in puppet-module-gems [#272](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/272) ([tphoney](https://github.com/tphoney))
- pdksync - (MODULES-7705) - Bumping stdlib dependency from < 5.0.0 to < 6.0.0 [#271](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/271) ([pmcmaw](https://github.com/pmcmaw))
- pdksync - (MODULES-7658) use beaker3 in puppet-module-gems [#270](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/270) ([tphoney](https://github.com/tphoney))
- (MODULES-7406) PDK Convert the module [#269](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/269) ([glennsarti](https://github.com/glennsarti))
- Merge Release Back To Master [#268](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/268) ([RandomNoun7](https://github.com/RandomNoun7))

## [2.1.1](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/2.1.1) - 2018-03-14

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.1.0...2.1.1)

### Other

- (MAINT) Fix Release Date in Changelog [#267](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/267) ([RandomNoun7](https://github.com/RandomNoun7))
- (MAINT) Fix Changelog Link [#266](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/266) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-6760) prep for 2.1.1 release [#265](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/265) ([RandomNoun7](https://github.com/RandomNoun7))
- (DOCUMENT-824) Update Changelog Format [#264](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/264) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-6281) Return Errors from T-SQL [#263](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/263) ([RandomNoun7](https://github.com/RandomNoun7))
- (FM-6605) Add CONTRIBUTING.MD to repository [#262](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/262) ([glennsarti](https://github.com/glennsarti))
- (maint) modulesync 65530a4 Update Travis [#260](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/260) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MODULES-6356) Fixes a problem still remaining from MODULES-2904 [#259](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/259) ([kreeuwijk](https://github.com/kreeuwijk))
- (maint) modulesync cd884db Remove AppVeyor OpenSSL update on Ruby 2.4 [#258](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/258) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (maint) - modulesync 384f4c1 [#256](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/256) ([tphoney](https://github.com/tphoney))
- Merge Release back to master [#255](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/255) ([jpogran](https://github.com/jpogran))

## [2.1.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/2.1.0) - 2017-12-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.0.2...2.1.0)

### Other

- (MODULES-6239) prep for 2.1.0 release [#254](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/254) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-6244) Update 2017 Support [#253](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/253) ([RandomNoun7](https://github.com/RandomNoun7))
- Merge Release back to Master [#252](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/252) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MODULES-6168) Detect SQL 2017 [#251](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/251) ([RandomNoun7](https://github.com/RandomNoun7))

## [2.0.2](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/2.0.2) - 2017-12-04

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.0.1...2.0.2)

### Other

- (MODULES-6022) Make SQLServer Instance Idempotent Again [#250](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/250) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (maint) - modulesync 1d81b6a [#248](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/248) ([pmcmaw](https://github.com/pmcmaw))
- Merge release back into master [#247](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/247) ([glennsarti](https://github.com/glennsarti))
- (FM-6464) Update metadata for open sourcing [#245](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/245) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [2.0.1](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/2.0.1) - 2017-11-14

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/2.0.0...2.0.1)

### Other

- (MODULES-5961) Prep for release 2.0.1 [#246](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/246) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MAINT) Correct supported versions & platforms [#244](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/244) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MODULES-5693) Replace SQLOLEDB with SQLNCLI11 [#243](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/243) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (maint) Remove instance during acceptance tests [#242](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/242) ([glennsarti](https://github.com/glennsarti))
- (MODULES-5566) Rewrite Instance Discovery [#241](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/241) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (Maintenance) remove redundant rake task [#240](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/240) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- Added 2016 to supported versions [#239](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/239) ([davinhanlon](https://github.com/davinhanlon))
- (maint) modulesync 892c4cf [#238](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/238) ([HAIL9000](https://github.com/HAIL9000))
- release 2.0.0 mergeback [#237](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/237) ([eputnam](https://github.com/eputnam))

## [2.0.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/2.0.0) - 2017-08-10

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/1.2.0...2.0.0)

### Other

- (maint) Update changelog to comply with Puppet formatting  [#236](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/236) ([glennsarti](https://github.com/glennsarti))
- (maint) modulesync 915cde70e20 [#235](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/235) ([glennsarti](https://github.com/glennsarti))
- (MODULES-5209) Prepare for 2.0.0 release [#234](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/234) ([glennsarti](https://github.com/glennsarti))
- (FM-6141) Add test-tiering, and README to spec directory [#233](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/233) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- some edits for sqlserver changes [#232](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/232) ([jbondpdx](https://github.com/jbondpdx))
- (MODULES-5070) Add polybase parameters to sql_instance [#231](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/231) ([glennsarti](https://github.com/glennsarti))
- (MODULES-5126) Use integer in acceptance test [#230](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/230) ([glennsarti](https://github.com/glennsarti))
- (MODULES-5187)(MODULES-52080) mysnc puppet 5 and ruby 2.4 [#229](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/229) ([eputnam](https://github.com/eputnam))
- (MODULES-5144) Prep for puppet 5 [#228](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/228) ([hunner](https://github.com/hunner))
- (MODULES-5126) Puppet4ing SQL Server [#227](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/227) ([glennsarti](https://github.com/glennsarti))
- (maint) Add more advanced examples to documentation [#226](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/226) ([glennsarti](https://github.com/glennsarti))
- (MODULES-4842) Update puppet compatibility with 4.7 as lower bound [#225](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/225) ([glennsarti](https://github.com/glennsarti))
- (MODULES-4915) Remove forced TCP connection for SQL management [#224](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/224) ([glennsarti](https://github.com/glennsarti))
- (FM-5062) Add testmode switcher to sqlserver module [#223](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/223) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- (FM-5021) Escaping identifiers when creating a database [#222](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/222) ([glennsarti](https://github.com/glennsarti))
- (MODULES-2543) Purge members from SQL Server Role [#221](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/221) ([glennsarti](https://github.com/glennsarti))
- (MODULES-2386) Using as_sysadmin_accounts without AS feature should error [#220](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/220) ([glennsarti](https://github.com/glennsarti))
- (FM-5389) Fix sql_features when installing SNAC_SDK [#219](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/219) ([glennsarti](https://github.com/glennsarti))
- (FM-5389) Add missing shared feature SNAC_SDK [#218](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/218) ([glennsarti](https://github.com/glennsarti))
- (MODULES-5030) Remove service_ensure parameter [#217](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/217) ([glennsarti](https://github.com/glennsarti))
- (MODULES-5092) Failures during .Net 3 installation should be obvious [#216](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/216) ([glennsarti](https://github.com/glennsarti))
- (MODULES-4257) Modify instance and features for SQL Server 2016 [#215](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/215) ([glennsarti](https://github.com/glennsarti))
- (maint) Update test helper for SQL Server 2016 [#213](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/213) ([glennsarti](https://github.com/glennsarti))
- (MODULES-5031) Modify facts for SQL Server 2016 [#212](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/212) ([glennsarti](https://github.com/glennsarti))
- (MODULES-4257) Add SQL Server 2016 support in acceptance tests [#211](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/211) ([glennsarti](https://github.com/glennsarti))
- Release mergeback [#210](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/210) ([pmcmaw](https://github.com/pmcmaw))

## [1.2.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/1.2.0) - 2017-05-09

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/1.1.6...1.2.0)

### Other

- 1.2.0 Release Prep [#209](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/209) ([HelenCampbell](https://github.com/HelenCampbell))
- fixing a typo for jp translation [#208](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/208) ([jbondpdx](https://github.com/jbondpdx))
- Adding correct project url and newline to metadata [#207](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/207) ([HelenCampbell](https://github.com/HelenCampbell))
- (MODULES-4667) Update beaker tests for Jenkins CI [#206](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/206) ([glennsarti](https://github.com/glennsarti))
- [msync] 786266 Implement puppet-module-gems, a45803 Remove metadata.json from locales config [#205](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/205) ([wilson208](https://github.com/wilson208))
- (MODULES-4334) - Adding locales directory, POT file and config.yaml [#204](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/204) ([pmcmaw](https://github.com/pmcmaw))
- [MODULES-4528] Replace Puppet.version comparison with Puppet::Util::Package.versioncmp [#203](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/203) ([wilson208](https://github.com/wilson208))
- (maint) Release mergeback [#202](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/202) ([DavidS](https://github.com/DavidS))

## [1.1.6](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/1.1.6) - 2017-03-07

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/1.1.5...1.1.6)

### Other

- [FM-6077] Release 1.1.6 [#201](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/201) ([wilson208](https://github.com/wilson208))
- [PE-17491] Do not fail on install when a restart exit code is returned [#200](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/200) ([wilson208](https://github.com/wilson208))

## [1.1.5](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/1.1.5) - 2017-02-16

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/1.1.4...1.1.5)

### Other

- (FM-6026) Release 1.1.5 [#199](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/199) ([glennsarti](https://github.com/glennsarti))
- (MODULES-4321): edit sqlserver for loc [#198](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/198) ([jbondpdx](https://github.com/jbondpdx))
- (maint) Prime Feature and Instance installation with .Net 3.5 source [#197](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/197) ([wilson208](https://github.com/wilson208))
- (MODULES-4098) Sync the rest of the files [#196](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/196) ([hunner](https://github.com/hunner))
- [MODULES-4255] Obfuscate passwords in sqlserver_instance [#195](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/195) ([wilson208](https://github.com/wilson208))
- (MODULES-4263) add blacksmith rake tasks [#194](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/194) ([eputnam](https://github.com/eputnam))
- (MODULES-4097) Sync travis.yml [#193](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/193) ([hunner](https://github.com/hunner))
- (FM-5972) Update to next modulesync_configs [dedaf10] [#192](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/192) ([DavidS](https://github.com/DavidS))
- (MODULES-3632) Use json_pure always [#191](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/191) ([hunner](https://github.com/hunner))
- (MODULES-3704) Update gemfile template to be identical [#190](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/190) ([hunner](https://github.com/hunner))

## [1.1.4](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/1.1.4) - 2016-08-31

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/1.1.3...1.1.4)

### Other

- (FM-5476) (docs) Edits for docs signoff [#189](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/189) ([gguillotte](https://github.com/gguillotte))
- (MODULES-3775) (msync 8d0455c) update travis/appveyer w/Ruby 2.3 [#188](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/188) ([MosesMendoza](https://github.com/MosesMendoza))
- (maint) modulesync 70360747 [#187](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/187) ([glennsarti](https://github.com/glennsarti))
- (FM-5473) Release 1.1.4 [#186](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/186) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3752) Fix modifying server_roles for an existing WINDOWS_LOGIN [#185](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/185) ([glennsarti](https://github.com/glennsarti))
- (BKR-914) Add workaround for beaker bug BKR-914 [#184](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/184) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3202) Fix install dependencies with custom source [#183](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/183) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3256)(MODULES-2323)(MODULES-2554)(MODULES-3083) Fix sqlserver::login resource [#182](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/182) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3640) Update modulesync 30fc4ab [#181](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/181) ([MosesMendoza](https://github.com/MosesMendoza))
- (PA-285) Branding name change [#166](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/166) ([jpogran](https://github.com/jpogran))

## [1.1.3](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/1.1.3) - 2016-07-12

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/1.1.2...1.1.3)

### Other

- (MODULES-3493) Prepare for Release v1.1.3 [#179](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/179) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3536) modsync update [#177](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/177) ([glennsarti](https://github.com/glennsarti))
- (maint) Update rakefile for puppetlabs_spec_helper [#176](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/176) ([glennsarti](https://github.com/glennsarti))
- (FM-5387) Remove simplecov gem and update for modsync [#175](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/175) ([glennsarti](https://github.com/glennsarti))
- (PE-16132) Add Windows Based Authentication for sqlserver::config [#174](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/174) ([glennsarti](https://github.com/glennsarti))
- (FM-5324) Fix TSQL error propagation [#173](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/173) ([Iristyle](https://github.com/Iristyle))
- (maint) remove trailing README whitespace [#171](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/171) ([Iristyle](https://github.com/Iristyle))
- (MODULES-3355) Fix acceptance tests for Sqlserver role [#169](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/169) ([jpogran](https://github.com/jpogran))
- (MODULES-3356) Branding Name Change [#168](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/168) ([jpogran](https://github.com/jpogran))
- (MODULES-3355) Fix Role Name Collisions [#167](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/167) ([jpogran](https://github.com/jpogran))
- Merge up to master from stable after modsync changes [#165](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/165) ([ferventcoder](https://github.com/ferventcoder))
- (maint) modsync update - stable [#163](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/163) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3240) Fix rspec-puppet incompatibility [#162](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/162) ([glennsarti](https://github.com/glennsarti))

## [1.1.2](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/1.1.2) - 2016-04-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/1.1.1...1.1.2)

### Other

- (FM-5081) Supported Release 1.1.2 [#160](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/160) ([ferventcoder](https://github.com/ferventcoder))
- (FM-5080) add Puppet version ranges [#159](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/159) ([ferventcoder](https://github.com/ferventcoder))
- (FM-5041) Install PE License for Acceptance Testing [#158](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/158) ([cowofevil](https://github.com/cowofevil))
- (FM-4918) update modsync / Restrict Rake ~> 10.1 [#153](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/153) ([ferventcoder](https://github.com/ferventcoder))

## [1.1.1](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/1.1.1) - 2015-12-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/1.1.0...1.1.1)

### Other

- (FM-3940) Fix specs - Puppet 4.x validation errors [#155](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/155) ([ferventcoder](https://github.com/ferventcoder))
- (FM-3502) Release 1.1.1 [#154](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/154) ([ferventcoder](https://github.com/ferventcoder))
- (FM-3706)Create database with optional compatibility breaks CI [#152](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/152) ([phongdly](https://github.com/phongdly))
- (FM-3655) SQL Server CI acceptance issues [#151](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/151) ([phongdly](https://github.com/phongdly))
- (MODULES-2497) SQLSERVER - Create Automated Tests for sqlserver::login [#150](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/150) ([phongdly](https://github.com/phongdly))
- (MODULES-2496) Create Automated Tests for sqlserver::database [#149](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/149) ([phongdly](https://github.com/phongdly))
- (MODULES-3094) Release 1.1.0 [#148](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/148) ([cyberious](https://github.com/cyberious))
- (MODULES-2469) Create Automated Tests for sqlserver::role [#147](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/147) ([phongdly](https://github.com/phongdly))
- (MODULES-2454)/Automated_Test_For_Database_User [#142](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/142) ([phongdly](https://github.com/phongdly))
- Merge master to stable [#136](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/136) ([cyberious](https://github.com/cyberious))

## [1.1.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/1.1.0) - 2015-09-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/1.0.0...1.1.0)

### Other

- (MODULES-2498) Fix the check on removal [#146](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/146) ([cyberious](https://github.com/cyberious))
- (MODULES-2498) generate random instance name in each context [#145](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/145) ([phongdly](https://github.com/phongdly))
- (MODULES-2464) Simplify query for sp_configure check [#144](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/144) ([cyberious](https://github.com/cyberious))
- (MODULES-2453) Create Automated Tests for sqlserver_tsql [#141](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/141) ([phongdly](https://github.com/phongdly))
- (MODULES-2392) Automated Tests for sqlserver::config [#140](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/140) ([phongdly](https://github.com/phongdly))
- (MODULES-2451) Fix issue with integer interpretations [#139](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/139) ([cyberious](https://github.com/cyberious))
- (FM-3094) Prepare for release 1.1.0 [#137](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/137) ([cyberious](https://github.com/cyberious))
- (maint) Guarantee Facter version for old Puppets / (MODULES-2452) Update Beaker Version [#135](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/135) ([ferventcoder](https://github.com/ferventcoder))
- (MODULES-2391) Create Automated Tests For sqlserver_instance 2015-08-26 [#134](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/134) ([phongdly](https://github.com/phongdly))
- (MODULES-2430) Fix issue parsing facts with puppet 4 [#133](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/133) ([cyberious](https://github.com/cyberious))
- (FM-3252) CI Pipeline for sqlserver at step 7a [#132](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/132) ([phongdly](https://github.com/phongdly))
- (MODULES-2403) Improve error handling for sqlserver_tsql [#131](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/131) ([cyberious](https://github.com/cyberious))
- (MODULES-2377) Add validation for sp_configure bools [#130](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/130) ([cyberious](https://github.com/cyberious))
- (docs) Several docs updates [#129](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/129) ([cyberious](https://github.com/cyberious))
- (docs) MODULES-2325 update readme to reflect permissions [#128](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/128) ([cyberious](https://github.com/cyberious))
- (DO NOT MERGE)(MODULES-2312) Use sp_executesql to execute T-SQL [#127](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/127) ([Iristyle](https://github.com/Iristyle))
- (maint) puppetlabs_spec_helper ~>0.10.3 [#125](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/125) ([ferventcoder](https://github.com/ferventcoder))
- (maint) replaced debian6 by centos7 master in nodesets yml files [#124](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/124) ([phongdly](https://github.com/phongdly))
- (MODULES-2207) bin beaker-rspec to ~> 5.1 [#123](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/123) ([ferventcoder](https://github.com/ferventcoder))
- (MODULES-2245) Fixes issue with assumption of strings [#122](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/122) ([cyberious](https://github.com/cyberious))
- (MODULES-2207) Modulesync [#121](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/121) ([ferventcoder](https://github.com/ferventcoder))
- (maint) Move to use Beaker-puppet_install_helper  [#120](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/120) ([cyberious](https://github.com/cyberious))
- (maint) fix future parser acceptance failures [#119](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/119) ([Iristyle](https://github.com/Iristyle))
- (maint) remove unneeded pre-suite module installs [#118](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/118) ([Iristyle](https://github.com/Iristyle))
- Fix Jenkins acceptance failures [#117](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/117) ([Iristyle](https://github.com/Iristyle))
- (FM-2303, FM-2790, FM-2445) WMI / Registry impl of Discovery Report [#116](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/116) ([Iristyle](https://github.com/Iristyle))
- (maint) remove references to beaker method step [#115](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/115) ([zreichert](https://github.com/zreichert))
- (maint) Inject CommonProgramFiles env var [#113](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/113) ([Iristyle](https://github.com/Iristyle))
- (FM-2791) Add database param to sqlserver_tsql [#112](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/112) ([cyberious](https://github.com/cyberious))
- Update README per DOC-1595 [#110](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/110) ([psoloway](https://github.com/psoloway))
- (maint) Lint and strict variables [#109](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/109) ([cyberious](https://github.com/cyberious))
- (MAINT) remove forge host from nodesets [#108](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/108) ([zreichert](https://github.com/zreichert))
- (maint) fix module installation [#107](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/107) ([Iristyle](https://github.com/Iristyle))
- (FM-2713) Remove sqlserver::config file requirement [#106](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/106) ([cyberious](https://github.com/cyberious))
- (FM-2577) Minor SQL server connection building refactorings [#105](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/105) ([Iristyle](https://github.com/Iristyle))
- (fix) - upcase instance name so we always have a consistent pattern to how SQL Server reports back names [#104](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/104) ([cyberious](https://github.com/cyberious))
- (fix) - Autoload property sqlserver_tsql when running from master [#100](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/100) ([cyberious](https://github.com/cyberious))
- (FM-2577) - Change from sqlcmd.exe to win32ole connector [#99](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/99) ([cyberious](https://github.com/cyberious))
- (maint) - Add .geppetto-rc.json to configure excludes [#98](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/98) ([cyberious](https://github.com/cyberious))
- Fix spec tests raise_error check [#91](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/91) ([cyberious](https://github.com/cyberious))
- Setup acceptance tests [#87](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/87) ([zreichert](https://github.com/zreichert))
- (BKR-147) add Gemfile setting for BEAKER_VERSION for puppet... [#84](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/84) ([anodelman](https://github.com/anodelman))
- FM-2328: document install_switches param in sqlserver [#82](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/82) ([jbondpdx](https://github.com/jbondpdx))
- FM-2303 Add install switches needed by customer [#81](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/81) ([cyberious](https://github.com/cyberious))
- FM-2298 and FM-2299 update Login and User to take hash of permissions [#79](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/79) ([cyberious](https://github.com/cyberious))
- FM-2303 Add install switches to sqlserver_install and sqlserver_features [#78](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/78) ([cyberious](https://github.com/cyberious))
- FM-2288 Role members [#77](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/77) ([cyberious](https://github.com/cyberious))
- FM-2287 Add Role Permissions ability [#76](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/76) ([cyberious](https://github.com/cyberious))
- Update sqlserver_validate_range to take array [#74](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/74) ([cyberious](https://github.com/cyberious))
- (DO NOT MERGE) - Pending Readme changes for Review [#73](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/73) ([cyberious](https://github.com/cyberious))
- FM-1556 Add ability to manage login server level permissions [#72](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/72) ([cyberious](https://github.com/cyberious))
- FM-2236 Add with_grant_option for user permissions [#71](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/71) ([cyberious](https://github.com/cyberious))
- FM-1898 Add sqlserver::user::permssion with GRANT, REVOKE and DENY [#70](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/70) ([cyberious](https://github.com/cyberious))
- FM1901 Add delete user capabilities [#69](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/69) ([cyberious](https://github.com/cyberious))
- FM-1900 Add User defined type [#68](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/68) ([cyberious](https://github.com/cyberious))
- Fix bug with TSQL provider rework [#67](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/67) ([cyberious](https://github.com/cyberious))
- DOC-1510: edit tsql additions [#66](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/66) ([jbondpdx](https://github.com/jbondpdx))
- FM-2110 README Predocs for sqlserver_tsql provider [#65](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/65) ([cyberious](https://github.com/cyberious))
- FM-2110 Prep TSQL provider  ... [#64](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/64) ([cyberious](https://github.com/cyberious))
- FM-2102 fix examples/sp_configure.pp [#63](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/63) ([cyberious](https://github.com/cyberious))
- FM-2122: Deleted irrelevant contribution information [#62](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/62) ([jbondpdx](https://github.com/jbondpdx))
- add geppetto-rc file to ignore examples [#61](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/61) ([justinstoller](https://github.com/justinstoller))
- Fix metadata.json and capture back puppet module build metadata.json [#60](https://github.com/puppetlabs/puppetlabs-sqlserver/pull/60) ([cyberious](https://github.com/cyberious))

## [1.0.0](https://github.com/puppetlabs/puppetlabs-sqlserver/tree/1.0.0) - 2014-12-15

[Full Changelog](https://github.com/puppetlabs/puppetlabs-sqlserver/compare/ef5c2854b9d6167b9db932dfb40cf2260fd5bd5c...1.0.0)
