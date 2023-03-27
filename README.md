<h1 align="center">
Oj Serializers
<p align="center">
<a href="https://github.com/ElMassimo/oj_serializers/actions"><img alt="Build Status" src="https://github.com/ElMassimo/oj_serializers/workflows/build/badge.svg"/></a>
<a href="https://inch-ci.org/github/ElMassimo/oj_serializers"><img alt="Inline docs" src="https://inch-ci.org/github/ElMassimo/oj_serializers.svg"/></a>
<a href="https://codeclimate.com/github/ElMassimo/oj_serializers"><img alt="Maintainability" src="https://codeclimate.com/github/ElMassimo/oj_serializers/badges/gpa.svg"/></a>
<a href="https://codeclimate.com/github/ElMassimo/oj_serializers"><img alt="Test Coverage" src="https://codeclimate.com/github/ElMassimo/oj_serializers/badges/coverage.svg"/></a>
<a href="https://rubygems.org/gems/oj_serializers"><img alt="Gem Version" src="https://img.shields.io/gem/v/oj_serializers.svg?colorB=e9573f"/></a>
<a href="https://github.com/ElMassimo/oj_serializers/blob/main/LICENSE.txt"><img alt="License" src="https://img.shields.io/badge/license-MIT-428F7E.svg"/></a>
</p>
</h1>

Faster JSON serializers for Ruby, built on top of the powerful [`oj`][oj] library.

[oj]: https://github.com/ohler55/oj
[mongoid]: https://github.com/mongodb/mongoid
[ams]: https://github.com/rails-api/active_model_serializers
[jsonapi]: https://github.com/jsonapi-serializer/jsonapi-serializer
[panko]: https://github.com/panko-serializer/panko_serializer
[blueprinter]: https://github.com/procore/blueprinter
[benchmarks]: https://github.com/ElMassimo/oj_serializers/tree/master/benchmarks
[raw_benchmarks]: https://github.com/ElMassimo/oj_serializers/blob/main/benchmarks/document_benchmark.rb
[sugar]: https://github.com/ElMassimo/oj_serializers/blob/main/lib/oj_serializers/sugar.rb#L14
[migration guide]: https://github.com/ElMassimo/oj_serializers/blob/main/MIGRATION_GUIDE.md
[design]: https://github.com/ElMassimo/oj_serializers#design-
[raw_json]: https://github.com/ohler55/oj/issues/542
[trailing_commas]: https://maximomussini.com/posts/trailing-commas/
[render dsl]: https://github.com/ElMassimo/oj_serializers#render-dsl-
[sorbet]: https://sorbet.org/
[Discussion]: https://github.com/ElMassimo/oj_serializers/discussions

## Why? 🤔

[`ActiveModel::Serializer`][ams] has a nice DSL, but it allocates many objects
leading to memory bloat, time spent on GC, and lower performance.

`Oj::Serializer` provides a similar API, with [better performance][benchmarks].

Learn more about [how this library achieves its performance][design].

## Features ⚡️

- Declaration syntax [similar to Active Model Serializers][migration guide]
- Reduced [memory allocation][benchmarks] and [improved performance][benchmarks]
- Support for `has_one` and `has_many`, compose with `flat_one`
- Useful development checks to avoid typos and mistakes
- Integrates nicely with Rails controllers

## Installation 💿

Add this line to your application's Gemfile:

```ruby
gem 'oj_serializers'
```

And then run:

    $ bundle install

## Usage 🚀

You can define a serializer by subclassing `Oj::Serializer`, and specify which
attributes should be serialized.

```ruby
class AlbumSerializer < Oj::Serializer
  attributes :name, :genres

  attr
  def release
    album.release_date.strftime('%B %d, %Y')
  end

  has_many :songs, serializer: SongSerializer
end
```

<details>
  <summary>Example Output</summary>

```ruby
{
  name: "Abraxas",
  genres: [
    "Pyschodelic Rock",
    "Blues Rock",
    "Jazz Fusion",
    "Latin Rock",
  ],
  release: "September 23, 1970",
  songs: [
    {
      track: 1,
      name: "Sing Winds, Crying Beasts",
      composers: ["Michael Carabello"],
    },
    {
      track: 2,
      name: "Black Magic Woman / Gypsy Queen",
      composers: ["Peter Green", "Gábor Szabó"],
    },
    {
      track: 3,
      name: "Oye como va",
      composers: ["Tito Puente"],
    },
    {
      track: 4,
      name: "Incident at Neshabur",
      composers: ["Alberto Gianquinto", "Carlos Santana"],
    },
    {
      track: 5,
      name: "Se acabó",
      composers: ["José Areas"],
    },
    {
      track: 6,
      name: "Mother's Daughter",
      composers: ["Gregg Rolie"],
    },
    {
      track: 7,
      name: "Samba pa ti",
      composers: ["Santana"],
    },
    {
      track: 8,
      name: "Hope You're Feeling Better",
      composers: ["Rolie"],
    },
    {
      track: 9,
      name: "El Nicoya",
      composers: ["Areas"],
    },
  ],
}
```
</details>

You can then use your new serializer to render an object or collection:

```ruby
class AlbumsController < ApplicationController
  def show
    render json: AlbumSerializer.one(album)
  end

  def index
    render json: { albums: AlbumSerializer.many(albums) }
  end
end
```

## Rendering 🖨

Use `one` to serialize objects, and `many` to serialize enumerables:

```ruby
render json: {
  favorite_album: AlbumSerializer.one(album),
  purchased_albums: AlbumSerializer.many(albums),
}
```

Serializers can be rendered arrays, hashes, or even inside `ActiveModel::Serializer`
by using a method in the serializer, making it very easy to combine with other
libraries and migrate incrementally.

You can use `render` as a shortcut for `one` and `many`, but it might be less readable:

```ruby
render json: {
  favorite_album: AlbumSerializer.render(album),
  purchased_albums: AlbumSerializer.render(albums),
}
```

## Attributes DSL 🪄

Specify which attributes should be rendered by calling a method in the object to serialize.

```ruby
class PlayerSerializer < Oj::Serializer
  attributes :first_name, :last_name, :full_name
end
```

You can serialize custom values by specifying that a method is an `attribute`:

```ruby
class PlayerSerializer < Oj::Serializer
  attributes :first_name, :last_name, :full_name

  attribute
  def name
    "#{player.first_name} #{player.last_name}"
  end
end
```

> **Note**
>
> In this example, `player` was inferred from `PlayerSerializer`.
>
> You can customize this by using [`object_as`](#using-a-different-alias-for-the-internal-object).


### Associations 🔗

Use `has_one` to serialize individual objects, and `has_many` to serialize a collection.

You must specificy which serializer to use with the `serializer` option.

```ruby
class SongSerializer < Oj::Serializer
  has_one :album, serializer: AlbumSerializer
  has_many :composers, serializer: ComposerSerializer
end
```

Provide a different value for the association by providing a block:

```ruby
class SongSerializer < Oj::Serializer
  has_one :album, serializer: AlbumSerializer do
    Album.find_by(song_ids: song.id)
  end
end
```

In case you need to pass options, you can call the serializer manually:

```ruby
class SongSerializer < Oj::Serializer
  attribute
  def album
    AlbumSerializer.one(song.album, for_song: song)
  end
end
```

### Aliasing or renaming attributes ↔️

You can pass `as` when defining an attribute or association to serialize it
using a different key:

```ruby
class SongSerializer < Oj::Serializer
  has_one :album, as: :first_release, serializer: AlbumSerializer

  attributes title: {as: :name}

  # or as a shortcut
  attributes title: :name
end
```

### Conditional Attributes ❔

You can render attributes and associations conditionally by using `:if`.

```ruby
class PlayerSerializer < Oj::Serializer
  attributes :first_name, :last_name, if: -> { player.display_name? }

  has_one :album, serializer: AlbumSerializer, if: -> { player.album }
end
```

This is useful in cases where you don't want to `null` values to be in the response.

## Advanced Usage 🧙‍♂️

### Using a different alias for the internal object

In most cases, the default alias for the `object` will be convenient enough.

However, if you would like to specify it manually, use `object_as`:

```ruby
class DiscographySerializer < Oj::Serializer
  object_as :artist

  # Now we can use `artist` instead of `object` or `discography`.
  attribute
  def latest_albums
    artist.albums.desc(:year)
  end
end
```

### Identifier Attributes

The `identifier` method allows you to only include an identifier if the record
or document has been persisted.

```ruby
class AlbumSerializer < Oj::Serializer
  identifier

  # or if it's a different field
  identifier :uuid
end
```

Additionally, identifier fields are always rendered first, even when sorting
fields alphabetically.

### Transforming Attribute Keys 🗝

When serialized data will be consumed from a client language that has different
naming conventions, it can be convenient to transform keys accordingly.

For example, when rendering an API to be consumed from the browser via JavaScript,
where properties are traditionally named using camel case.

Use `transform_keys` to handle that conversion.

```ruby
class BaseSerializer < Oj::Serializer
  transform_keys :camelize

  # shortcut for
  transform_keys -> (key) { key.to_s.camelize(:lower) }
end
```

This has no performance impact, as keys will be transformed at load time.

### Sorting Attributes 📶

By default attributes are rendered in the order they are defined.

If you would like to sort attributes alphabetically, you can specify it at a
serializer level:

```ruby
class BaseSerializer < Oj::Serializer
  sort_attributes_by :name # or a Proc
end
```

This has no performance impact, as attributes will be sorted at load time.

### Path Helpers 🛣

In case you need to access path helpers in your serializers, you can use the
following:

```ruby
class BaseSerializer < Oj::Serializer
  include Rails.application.routes.url_helpers

  def default_url_options
    Rails.application.routes.default_url_options
  end
end
```

One slight variation that might make it easier to maintain in the long term is
to use a separate singleton service to provide the url helpers and options, and
make it available as `urls`.

### Memoization & Local State

Serializers are designed to be stateless so that an instanced can be reused, but
sometimes it's convenient to store intermediate calculations.

Use `memo` for memoization and storing temporary information.

```ruby
class DownloadSerializer < Oj::Serializer
  attributes :filename, :size

  attribute
  def progress
    "#{ last_event&.progress || 0 }%"
  end

private

  def last_event
    memo.fetch(:last_event) {
      download.events.desc(:created_at).first
    }
  end
end
```

### `hash_attributes` 🚀

Very convenient when serializing Hash-like structures, this strategy uses the `[]` operator.

```ruby
class PersonSerializer < Oj::Serializer
  hash_attributes 'first_name', :last_name
end

PersonSerializer.one('first_name' => 'Mary', :middle_name => 'Jane', :last_name => 'Watson')
# {"first_name":"Mary","last_name":"Watson"}
```

### `mongo_attributes` 🚀

Reads data directly from `attributes` in a [Mongoid] document.

By skipping type casting, coercion, and defaults, it [achieves the best performance][raw_benchmarks].

Although there are some downsides, depending on how consistent your schema is,
and which kind of consumer the API has, it can be really powerful.

```ruby
class AlbumSerializer < Oj::Serializer
  mongo_attributes :id, :name
end
```

### Caching 📦

Use `cached` to leverage key-based caching, which calls `cache_key` in the object.

You can also provide a lambda to `cached_with_key` to define a custom key:

```ruby
class CachedUserSerializer < UserSerializer
  cached_with_key ->(user) {
    "#{ user.id }/#{ user.current_sign_in_at }"
  }
end
```

It will leverage `fetch_multi` when serializing a collection with `many` or
`has_many`, to minimize the amount of round trips needed to read and write all
items to cache.

This works specially well if your cache store also supports `write_multi`.

Usually serialization happens so fast that __turning caching on can be slower__.
Always benchmark to make sure it's worth it, and use caching only for
time-consuming or deeply nested structures with unpredictable query patterns.

### Writing to JSON

In some corner cases it might be faster to serialize using a `Oj::StringWriter`,
which you can access by using `one_as_json` and `many_as_json`.

Alternatively, you can toggle this mode at a serializer level by using
`default_format :json`, or configure it globally from your base serializer:

```ruby
class BaseSerializer < Oj::Serializer
  default_format :json # :hash is the default
end
```

This will change the default shortcuts (`render`, `one`, `one_if`, and `many`),
so that the serializer writes directly to JSON instead of returning a Hash.

<details>
  <summary>Example Output</summary>

```json
{
  "name": "Abraxas",
  "genres": [
    "Pyschodelic Rock",
    "Blues Rock",
    "Jazz Fusion",
    "Latin Rock"
  ],
  "release": "September 23, 1970",
  "songs": [
    {
      "track": 1,
      "name": "Sing Winds, Crying Beasts",
      "composers": [
        "Michael Carabello"
      ]
    },
    {
      "track": 2,
      "name": "Black Magic Woman / Gypsy Queen",
      "composers": [
        "Peter Green",
        "Gábor Szabó"
      ]
    },
    {
      "track": 3,
      "name": "Oye como va",
      "composers": [
        "Tito Puente"
      ]
    },
    {
      "track": 4,
      "name": "Incident at Neshabur",
      "composers": [
        "Alberto Gianquinto",
        "Carlos Santana"
      ]
    },
    {
      "track": 5,
      "name": "Se acabó",
      "composers": [
        "José Areas"
      ]
    },
    {
      "track": 6,
      "name": "Mother's Daughter",
      "composers": [
        "Gregg Rolie"
      ]
    },
    {
      "track": 7,
      "name": "Samba pa ti",
      "composers": [
        "Santana"
      ]
    },
    {
      "track": 8,
      "name": "Hope You're Feeling Better",
      "composers": [
        "Rolie"
      ]
    },
    {
      "track": 9,
      "name": "El Nicoya",
      "composers": [
        "Areas"
      ]
    }
  ]
}
```
</details>


## Design 📐

Unlike `ActiveModel::Serializer`, which builds a Hash that then gets encoded to
JSON, this implementation can use `Oj::StringWriter` to write JSON directly,
greatly reducing the overhead of allocating and garbage collecting the hashes.

It also allocates a single instance per serializer class, which makes it easy
to use, while keeping memory usage under control.

The internal design is simple and extensible, and because the library is written
in Ruby, creating new serialization strategies requires very little code.
Please open a [Discussion] if you need help 😃

### Comparison with other libraries

`ActiveModel::Serializer` instantiates one serializer object per item to be serialized.

Other libraries such as [`blueprinter`][blueprinter] [`jsonapi-serializer`][jsonapi]
evaluate serializers in the context of a `class` instead of an `instance` of a class.
The downside is that you can't use instance methods or local memoization, and any
mixins must be applied to the class itself.

[`panko-serializer`][panko] also uses `Oj::StringWriter`, but it has the big downside of having to own the entire render tree. Putting a serializer inside a Hash or an Active Model Serializer and serializing that to JSON doesn't work, making a gradual migration harder to achieve. Also, it's optimized for Active Record but I needed good Mongoid support.

`Oj::Serializer` combines some of these ideas, by using instances, but reusing them to avoid object allocations. Serializing 10,000 items instantiates a single serializer. Unlike `panko-serializer`, it doesn't suffer from [double encoding problems](https://panko.dev/docs/response-bag) so it's easier to use.

Follow [this discussion][raw_json] to find out more about [the `raw_json` extensions][raw_json] that made this high level of interoperability possible.

As a result, migrating from `active_model_serializers` is relatively
straightforward because instance methods, inheritance, and mixins work as usual.

### Benchmarks 📊

This library includes some [benchmarks] to compare performance with similar libraries.

See [this pull request](https://github.com/ElMassimo/oj_serializers/pull/9) for a quick comparison,
or check the CI to see the latest results.

### Migrating from other libraries

This library provides a few different compatibility modes that make it
easier to migrate from `active_model_serializers` and similar libraries, please
refer to the [migration guide] for a full discussion.

## Formatting 📏

Even though most of the examples above use a single-line style to be succint, I highly recommend writing one attribute per line, sorting them alphabetically (most editors can do it for you), and [always using a trailing comma][trailing_commas].

```ruby
class AlbumSerializer < Oj::Serializer
  attributes(
    :genres,
    :name,
    :release_date,
  )
end
```

It will make things clearer, minimize the amount of git conflicts, and keep the history a lot cleaner and more meaningful when using `git blame`.

## Special Thanks 🙏

This library wouldn't be possible without the wonderful and performant [`oj`](https://github.com/ohler55/oj) library. Thanks [Peter](https://github.com/ohler55)! 😃

Also, thanks to the libraries that inspired this one:

- [`active_model_serializers`][ams]: For the DSL
- [`panko-serializer`][panko]: For validating that using `Oj::StringWriter` was indeed fast

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
