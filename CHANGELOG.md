# DocumenterTools.jl changelog

## Version `v0.1.3`

* ![Experimental][badge-experimental] ![Feature][badge-feature] The new `Themes` submodule provides an experimental API to compile Documenter Sass themes. ([#27][github-27])

## Version `v0.1.2`

* ![Deprecation][badge-deprecation] The `Travis` submodule has been deprecated. Instead of `Travis.genkeys`, use `DocumenterTools.genkeys`. ([#30][github-30])

## Version `v0.1.1`

* ![Enhancement][badge-enhancement] The `generate(path::String)` method now defaults to `"docs"` as the default path, allowing it to be simply called as `generate()` in e.g. the root directory of a package. ([#22][github-22])

* ![Enhancement][badge-enhancement] The generated values for the `format` argument of `makedocs` are now consistent with the new API introduced in Documenter v0.21. ([#21][github-21])

## Version `v0.1.0`

* Initial release.


[github-21]: https://github.com/JuliaDocs/DocumenterTools.jl/pull/21
[github-22]: https://github.com/JuliaDocs/DocumenterTools.jl/pull/22
[github-27]: https://github.com/JuliaDocs/DocumenterTools.jl/pull/27
[github-30]: https://github.com/JuliaDocs/DocumenterTools.jl/pull/30


[badge-breaking]: https://img.shields.io/badge/BREAKING-red.svg
[badge-deprecation]: https://img.shields.io/badge/deprecation-orange.svg
[badge-feature]: https://img.shields.io/badge/feature-green.svg
[badge-enhancement]: https://img.shields.io/badge/enhancement-blue.svg
[badge-bugfix]: https://img.shields.io/badge/bugfix-purple.svg
[badge-experimental]: https://img.shields.io/badge/experimental-lightgrey.svg

<!--
# Badges

![BREAKING][badge-breaking]
![Deprecation][badge-deprecation]
![Feature][badge-feature]
![Enhancement][badge-enhancement]
![Bugfix][badge-bugfix]
![Experimental][badge-experimental]
-->
