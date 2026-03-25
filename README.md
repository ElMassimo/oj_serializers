<h1 align="center">
JSON Serializers
<p align="center">
<a href="https://github.com/ElMassimo/oj_serializers/actions"><img alt="Build Status" src="https://github.com/ElMassimo/oj_serializers/workflows/build/badge.svg"/></a>
<a href="https://codeclimate.com/github/ElMassimo/oj_serializers"><img alt="Maintainability" src="https://codeclimate.com/github/ElMassimo/oj_serializers/badges/gpa.svg"/></a>
<a href="https://codeclimate.com/github/ElMassimo/oj_serializers"><img alt="Test Coverage" src="https://codeclimate.com/github/ElMassimo/oj_serializers/badges/coverage.svg"/></a>
<a href="https://rubygems.org/gems/json_serializers"><img alt="Gem Version" src="https://img.shields.io/gem/v/json_serializers.svg?colorB=e9573f"/></a>
<a href="https://github.com/ElMassimo/oj_serializers/blob/main/LICENSE.txt"><img alt="License" src="https://img.shields.io/badge/license-MIT-428F7E.svg"/></a>
</p>
</h1>

Fast, memory-efficient JSON serializers for Ruby and Rails.

[mongoid]: https://github.com/mongodb/mongoid
[ams]: https://github.com/rails-api/active_model_serializers
[jsonapi]: https://github.com/jsonapi-serializer/jsonapi-serializer
[panko]: https://github.com/panko-serializer/panko_serializer
[blueprinter]: https://github.com/procore/blueprinter
[benchmarks]: https://github.com/ElMassimo/oj_serializers/tree/master/benchmarks
[raw_benchmarks]: https://github.com/ElMassimo/oj_serializers/blob/main/benchmarks/document_benchmark.rb
[sugar]: https://github.com/ElMassimo/oj_serializers/blob/main/lib/json_serializers/sugar.rb#L14
[migration guide]: https://github.com/ElMassimo/oj_serializers/blob/main/MIGRATION_GUIDE.md
[design]: https://github.com/ElMassimo/oj_serializers#design-
[associations]: https://github.com/ElMassimo/oj_serializers#associations-
[compose]: https://github.com/ElMassimo/oj_serializers#composing-serializers-
[trailing_commas]: https://maximomussini.com/posts/trailing-commas/
[render dsl]: https://github.com/ElMassimo/oj_serializers#render-dsl-
[sorbet]: https://sorbet.org/
[Discussion]: https://github.com/ElMassimo/oj_serializers/discussions
[TypeScript]: https://www.typescriptlang.org/
[types_from_serializers]: https://github.com/ElMassimo/types_from_serializers
[inheritance]: https://github.com/ElMassimo/types_from_serializers/blob/main/playground/vanilla/app/serializers/song_with_videos_serializer.rb#L1

## Why?

[`ActiveModel::Serializer`][ams] has a nice DSL, but it allocates many objects
leading to memory bloat, time spent on GC, and lower performance.

`JsonSerializer` provides a similar API, with [better performance][benchmarks].

Learn more about [how this library achieves its performance][design].

## Features

- Intuitive declaration syntax, supporting mixins and inheritance
- Reduced [memory allocation][benchmarks] and [improved performance][benchmarks]
- Generate [TypeScript interfaces automatically][types_from_serializers]
- Support for [`has_one`][associations] and [`has_many`][associations], compose with [`flat_one`][compose]
- Useful development checks to avoid typos and mistakes
- [Migrate easily from Active Model Serializers][migration guide]

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json_serializers'
```

And then run:

    $ bundle install

## Usage

You can define a serializer by subclassing `JsonSerializer`, and specify which
attributes should be serialized.

```ruby
class AlbumSerializer < JsonSerializer
  attributes :name, :genres

  attribute :release do
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

<details>
  <summary>Active Model Serializers style</summary>

```ruby
require "json_serializers/sugar" # In an initializer

class AlbumsController < ApplicationController
  def show
    render json: album, serializer: AlbumSerializer
  end

  def index
    render json: albums, root: :albums, each_serializer: AlbumSerializer
  end
end
```
</details>

## Rendering

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

`render` is a shortcut for `one` and `many`:

```ruby
render json: {
  favorite_album: AlbumSerializer.render(album),
  purchased_albums: AlbumSerializer.render(albums),
}
```

## Attributes DSL

Specify which attributes should be rendered by calling a method in the object to serialize.

```ruby
class PlayerSerializer < JsonSerializer
  attributes :first_name, :last_name, :full_name
end
```

You can serialize custom values by specifying that a method is an `attribute`:

```ruby
class PlayerSerializer < JsonSerializer
  attribute :name do
    "#{player.first_name} #{player.last_name}"
  end

  # or

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


### Associations

Use `has_one` to serialize individual objects, and `has_many` to serialize a collection.

You must specificy which serializer to use with the `serializer` option.

```ruby
class SongSerializer < JsonSerializer
  has_one :album, serializer: AlbumSerializer
  has_many :composers, serializer: ComposerSerializer
end
```

Specify a different value for the association by providing a block:

```ruby
class SongSerializer < JsonSerializer
  has_one :album, serializer: AlbumSerializer do
    Album.find_by(song_ids: song.id)
  end
end
```

In case you need to pass options, you can call the serializer manually:

```ruby
class SongSerializer < JsonSerializer
  attribute :album do
    AlbumSerializer.one(song.album, for_song: song)
  end
end
```

### Aliasing or renaming attributes

You can pass `as` when defining an attribute or association to serialize it
using a different key:

```ruby
class SongSerializer < JsonSerializer
  has_one :album, as: :first_release, serializer: AlbumSerializer

  attributes title: {as: :name}

  # or as a shortcut
  attributes title: :name
end
```

### Conditional attributes

You can render attributes and associations conditionally by using `:if`.

```ruby
class PlayerSerializer < JsonSerializer
  attributes :first_name, :last_name, if: -> { player.display_name? }

  has_one :album, serializer: AlbumSerializer, if: -> { player.album }
end
```

This is useful in cases where you don't want to `null` values to be in the response.

## Advanced Usage

### Using a different alias for the internal object

In most cases, the default alias for the `object` will be convenient enough.

However, if you would like to specify it manually, use `object_as`:

```ruby
class DiscographySerializer < JsonSerializer
  object_as :artist

  # Now we can use `artist` instead of `object` or `discography`.
  attribute
  def latest_albums
    artist.albums.desc(:year)
  end
end
```

### Identifier attributes

The `identifier` method allows you to only include an identifier if the record
or document has been persisted.

```ruby
class AlbumSerializer < JsonSerializer
  identifier

  # or if it's a different field
  identifier :uuid
end
```

Additionally, identifier fields are always rendered first, even when sorting
fields alphabetically.

### Transforming attribute keys

When serialized data will be consumed from a client language that has different
naming conventions, it can be convenient to transform keys accordingly.

For example, when rendering an API to be consumed from the browser via JavaScript,
where properties are traditionally named using camel case.

Use `transform_keys` to handle that conversion.

```ruby
class BaseSerializer < JsonSerializer
  transform_keys :camelize

  # shortcut for
  transform_keys -> (key) { key.to_s.camelize(:lower) }
end
```

This has no performance impact, as keys will be transformed at load time.

### Sorting attributes

By default attributes are rendered in the order they are defined.

If you would like to sort attributes alphabetically, you can specify it at a
serializer level:

```ruby
class BaseSerializer < JsonSerializer
  sort_attributes_by :name # or a Proc
end
```

This has no performance impact, as attributes will be sorted at load time.

### Path helpers

In case you need to access path helpers in your serializers, you can use the
following:

```ruby
class BaseSerializer < JsonSerializer
  include Rails.application.routes.url_helpers

  def default_url_options
    Rails.application.routes.default_url_options
  end
end
```

One slight variation that might make it easier to maintain in the long term is
to use a separate singleton service to provide the url helpers and options, and
make it available as `urls`.

### Generating TypeScript automatically

It's easy for the backend and the frontend to become out of sync. Traditionally, preventing bugs requires writing extensive integration tests.

[TypeScript] is a great tool to catch this kind of bugs and mistakes, as it can detect incorrect usages and missing fields, but writing types manually is cumbersome, and they can become stale over time, giving a false sense of confidence.

[`types_from_serializers`][types_from_serializers] extends this library to allow embedding type information, as well as inferring types from the SQL schema when available, and uses this information to automatically generate TypeScript interfaces from your serializers.

As a result, it's posible to easily detect mismatches between the backend and the frontend, as well as make the fields more discoverable and provide great autocompletion in the frontend, without having to manually write the types.

### Composing serializers

There are three options to [compose serializers](https://github.com/ElMassimo/oj_serializers/discussions/10#discussioncomment-5523921): [inheritance], mixins, and `flat_one`.

Use `flat_one` to include all attributes from a different serializer:

```ruby
class AttachmentSerializer < BaseSerializer
  identifier

  class BlobSerializer < BaseSerializer
    attributes :filename, :byte_size, :content_type, :created_at
  end

  flat_one :blob, serializer: BlobSerializer
end
```

Think of it as `has_one` without a "root", all the attributes are added directly.

<details>
  <summary>Example Output</summary>

```ruby
{
  id: 5,
  filename: "image.jpg,
  byte_size: 256074,
  content_type: "image/jpeg",
  created_at: "2022-08-04T17:25:12.637-07:00",
}
```
</details>

This is especially convenient when using [`types_from_serializers`][types_from_serializers],
as it enables automatic type inference for the included attributes.

### Memoization & local state

Serializers are designed to be stateless so that an instanced can be reused, but
sometimes it's convenient to store intermediate calculations.

Use `memo` for memoization and storing temporary information.

```ruby
class DownloadSerializer < JsonSerializer
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

### `hash_attributes`

Very convenient when serializing Hash-like structures, this strategy uses the `[]` operator.

```ruby
class PersonSerializer < JsonSerializer
  hash_attributes 'first_name', :last_name
end

PersonSerializer.one('first_name' => 'Mary', :middle_name => 'Jane', :last_name => 'Watson')
# {first_name: "Mary", last_name: "Watson"}
```

### `mongo_attributes`

Reads data directly from `attributes` in a [Mongoid] document.

By skipping type casting, coercion, and defaults, it [achieves the best performance][raw_benchmarks].

Although there are some downsides, depending on how consistent your schema is,
and which kind of consumer the API has, it can be really powerful.

```ruby
class AlbumSerializer < JsonSerializer
  mongo_attributes :id, :name
end
```

### Caching

Usually rendering is so fast that __turning caching on can be slower__.

However, in cases of deeply nested structures, unpredictable query patterns, or
methods that take a long time to run, caching can improve performance.

To enable caching, use `cached`, which calls `cache_key` in the object:

```ruby
class CachedUserSerializer < UserSerializer
  cached
end
```

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

## Design

Unlike `ActiveModel::Serializer`, which allocates a new serializer instance for
every object being serialized, this library reuses a single instance per
serializer class, greatly reducing memory allocation and GC pressure.

Serialization builds a plain Ruby Hash via code generation, which is then encoded
to JSON using Ruby's built-in `JSON.generate`. This approach keeps the
implementation simple and portable — no C extensions are required.

The internal design is simple and extensible, and because the library is written
in Ruby, creating new serialization strategies requires very little code.
Please open a [Discussion] if you need help.

### Comparison with other libraries

`ActiveModel::Serializer` instantiates one serializer object per item to be serialized.

Other libraries such as [`blueprinter`][blueprinter] [`jsonapi-serializer`][jsonapi]
evaluate serializers in the context of a `class` instead of an `instance` of a class.
The downside is that you can't use instance methods or local memoization, and any
mixins must be applied to the class itself.

[`panko-serializer`][panko] uses C extensions for performance, but it has the big downside of having to own the entire render tree. Putting a serializer inside a Hash or an Active Model Serializer and serializing that to JSON doesn't work, making a gradual migration harder to achieve. Also, it's optimized for Active Record but doesn't support Mongoid.

`JsonSerializer` combines some of these ideas, by using instances, but reusing them to avoid object allocations. Serializing 10,000 items instantiates a single serializer. Unlike `panko-serializer`, it doesn't suffer from [double encoding problems](https://panko.dev/docs/response-bag) so it's easier to use.

As a result, migrating from `active_model_serializers` is relatively
straightforward because instance methods, inheritance, and mixins work as usual.

### Benchmarks

This library includes some [benchmarks] to compare performance with similar libraries.

See [this pull request](https://github.com/ElMassimo/oj_serializers/pull/9) for a quick comparison,
or check the CI to see the latest results.

### Migrating from other libraries

Please refer to the [migration guide] for a full discussion of the compatibility
modes available to make it easier to migrate from `active_model_serializers` and
similar libraries.

## Formatting

Even though most of the examples above use a single-line style to be succint, I highly recommend writing one attribute per line, sorting them alphabetically (most editors can do it for you), and [always using a trailing comma][trailing_commas].

```ruby
class AlbumSerializer < JsonSerializer
  attributes(
    :genres,
    :name,
    :release_date,
  )
end
```

It will make things clearer, minimize the amount of git conflicts, and keep the history a lot cleaner and more meaningful when using `git blame`.

## Special Thanks

This library was originally built on top of the [`oj`](https://github.com/ohler55/oj) gem. Thanks [Peter](https://github.com/ohler55)!

Also, thanks to the libraries that inspired this one:

- [`active_model_serializers`][ams]: For the DSL
- [`panko-serializer`][panko]: For early performance validation

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
