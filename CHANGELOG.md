## Oj Serializers 2.0.3 (2023-04-19)

### Features ✨

- [Allow `key` and `unless` in AMS-compat mode](https://github.com/ElMassimo/oj_serializers/commit/5050710e199651cc2c0e9d9d6395f2c2ac9b1875)

### Fixes 🐞

- [Allow using `active_model_serializers` in associations](https://github.com/ElMassimo/oj_serializers/commit/501ed4014b564e6f103d2f52d15832fe6706d6a8)

## Oj Serializers 2.0.2 (2023-04-02)

### Features ✨

- [Automatically remove `?` when using `transform_keys :camelize`](https://github.com/ElMassimo/oj_serializers/commit/79758a0)

### Fixes 🐞

- [Error when defining attributes with options](https://github.com/ElMassimo/oj_serializers/commit/680ab47)

## Oj Serializers 2.0.1 (2023-04-02)

### Features ✨

- [Automatically mark `id` as an identifier (rendered first)](https://github.com/ElMassimo/oj_serializers/commit/c4c6de7)
- [Fail on typos in attribute and association options](https://github.com/ElMassimo/oj_serializers/commit/afd80ac)

### Fixes 🐞

- [Aliased attributes should be sorted by the output key](https://github.com/ElMassimo/oj_serializers/commit/fc6f4c1)

## [Oj Serializers 2.0.0 (2023-03-27)](https://github.com/ElMassimo/oj_serializers/pull/9)

### Features ✨

- Improved performance (20% to 40% faster than v1)
- Added `render_as_hash` to efficiently build a Hash from the serializer
- `transform_keys :camelize`: a built-in setting to convert keys, in a way that does not affect runtime performance
- `sort_keys_by :name`: allows to sort the response alphabetically, without affecting runtime performance
- `render` shortcut, unifying `one` and `many`
- `attribute` as an easier approach to define serializer attributes

### Breaking Changes

Since returning a `Hash` is more convenient than returning a `Oj::StringWriter`, and performance is comparable, `default_format :hash` is now the default.

The previous APIs will still be available as `one_as_json` and `many_as_json`, as well as `default_format :json` to make the library work like in version 1.

## Oj Serializers 1.0.2 (2023-03-01) ##

*   [fix: avoid freezing `ALLOWED_INSTANCE_VARIABLES`](https://github.com/ElMassimo/oj_serializers/commit/ade0302)


## Oj Serializers 1.0.1 (2023-03-01) ##

*   [fix: avoid caching instances of reloaded classes in development](https://github.com/ElMassimo/oj_serializers/commit/0bd928d64d159926acf6b4d57e3f08b12f6931ce)


## Oj Serializers 1.0.0 (2020-11-05) ##

*   Initial Release.
