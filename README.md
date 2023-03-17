<h1 align="center">
Oj Serializers
<p align="center">
<a href="https://github.com/ElMassimo/oj_serializers/actions"><img alt="Build Status" src="https://github.com/ElMassimo/oj_serializers/workflows/build/badge.svg"/></a>
<a href="https://inch-ci.org/github/ElMassimo/oj_serializers"><img alt="Inline docs" src="https://inch-ci.org/github/ElMassimo/oj_serializers.svg"/></a>
<a href="https://codeclimate.com/github/ElMassimo/oj_serializers"><img alt="Maintainability" src="https://codeclimate.com/github/ElMassimo/oj_serializers/badges/gpa.svg"/></a>
<a href="https://codeclimate.com/github/ElMassimo/oj_serializers"><img alt="Test Coverage" src="https://codeclimate.com/github/ElMassimo/oj_serializers/badges/coverage.svg"/></a>
<a href="https://rubygems.org/gems/oj_serializers"><img alt="Gem Version" src="https://img.shields.io/gem/v/oj_serializers.svg?colorB=e9573f"/></a>
<a href="https://github.com/ElMassimo/oj_serializers/blob/master/LICENSE.txt"><img alt="License" src="https://img.shields.io/badge/license-MIT-428F7E.svg"/></a>
</p>
</h1>

JSON serializers for Ruby, built on top of the powerful [`oj`][oj] library.

[oj]: https://github.com/ohler55/oj
[mongoid]: https://github.com/mongodb/mongoid
[ams]: https://github.com/rails-api/active_model_serializers
[jsonapi]: https://github.com/jsonapi-serializer/jsonapi-serializer
[panko]: https://github.com/panko-serializer/panko_serializer
[benchmarks]: https://github.com/ElMassimo/oj_serializers/tree/master/benchmarks
[raw_benchmarks]: https://github.com/ElMassimo/oj_serializers/blob/master/benchmarks/document_benchmark.rb
[sugar]: https://github.com/ElMassimo/oj_serializers/blob/master/lib/oj_serializers/sugar.rb#L14
[migration guide]: https://github.com/ElMassimo/oj_serializers/blob/master/MIGRATION_GUIDE.md
[design]: https://github.com/ElMassimo/oj_serializers#design-
[raw_json]: https://github.com/ohler55/oj/issues/542
[trailing_commas]: https://maximomussini.com/posts/trailing-commas/
[render dsl]: https://github.com/ElMassimo/oj_serializers#render-dsl-

## Why? 🤔

[`ActiveModel::Serializer`][ams] has a nice DSL, but it allocates many objects leading
to memory bloat, time spent on GC, and lower performance.

`Oj::Serializer` provides a similar API, with [better performance][benchmarks].

Learn more about [how this library achieves its performance][design].

## Features ⚡️

- Declaration syntax similar to Active Model Serializers
- Reduced memory allocation and [improved performance][benchmarks]
- Support for `has_one` and `has_many`; compose with `flat_one`
- Useful development checks to avoid typos and mistakes
- Integrates nicely with Rails controllers
- Caching

## Installation 💿

Add this line to your application's Gemfile:

```ruby
gem 'oj_serializers'
```

And then run:

    $ bundle install

## Usage 🚀

You can define a serializer by subclassing `Oj::Serializer`, and specify which
attributes should be serialized to JSON.

```ruby
class AlbumSerializer < Oj::Serializer
  attributes :name, :genres

  attribute \
  def release
    album.release_date.strftime('%B %d, %Y')
  end

  has_many :songs, serializer: SongSerializer
end
```

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

<br/>

To use the serializer, the recommended approach is:

```ruby
class AlbumsController < ApplicationController
  def show
    album = Album.find(params[:id])
    render json: AlbumSerializer.one(album)
  end

  def index
    albums = Album.all
    render json: { albums: AlbumSerializer.many(albums) }
  end
end
```

If you are using Rails you can also use something closer to Active Model Serializers by adding [`sugar`][sugar]:

```ruby
require 'oj_serializers/sugar'

class AlbumsController < ApplicationController
  def show
    album = Album.find(params[:id])
    render json: album, serializer: AlbumSerializer
  end

  def index
    albums = Album.all
    render json: albums, each_serializer: AlbumSerializer, root: :albums
  end
end
```

It's recommended to create your own `BaseSerializer` class in order to easily
add custom extensions, specially when migrating from `active_model_serializers`.

## Render DSL 🛠

In order to efficiently reuse the instances, serializers can't be instantiated directly. Use `one` and `many` to serialize objects or enumerables:

```ruby
render json: {
  favorite_album: AlbumSerializer.one(album),
  purchased_albums: AlbumSerializer.many(albums),
}
```

You can use these serializers inside arrays, hashes, or even inside `ActiveModel::Serializer` by using a method in the serializer.

Follow [this discussion][raw_json] to find out more about [the `raw_json` extensions][raw_json] that made this high level of interoperability possible.

## Attributes DSL 🛠

Attributes methods can be used to define which model attributes should be serialized
to JSON. Each method provides a different strategy to obtain the values to serialize.

The internal design is simple and extensible, so creating new strategies requires very little code.
Please open an issue if you need help 😃

### `attributes`

Obtains the attribute value by calling a method in the object being serialized.

```ruby
class PlayerSerializer < Oj::Serializer
  attributes :full_name
end
```

Have in mind that unlike Active Model Serializers, it will _not_ take into
account methods defined in the serializer. Being explicit about where the
attribute is coming from makes the serializers easier to understand and more
maintainable.

### `serializer_attributes`

Obtains the attribute value by calling a method defined in the serializer.


You may call [`serializer_attributes`](https://github.com/ElMassimo/oj_serializers/blob/master/spec/support/serializers/song_serializer.rb#L13-L15) or use the `attribute` inline syntax:

```ruby
class PlayerSerializer < Oj::Serializer
  attribute \
  def full_name
    "#{player.first_name} #{player.last_name}"
  end
end
```

Instance methods can access the object by the serializer name without the
`Serializer` suffix, `player` in the example above, or directly as `@object`.

You can customize this by using [`object_as`](https://github.com/ElMassimo/oj_serializers#using-a-different-alias-for-the-internal-object).

### `ams_attributes` 🐌

Works like `attributes` in Active Model Serializers, by calling a method in the serializer if defined, or calling `read_attribute_for_serialization` in the model.

```ruby
class AlbumSerializer < Oj::Serializer
  ams_attributes :name, :release

  def release
    album.release_date.strftime('%B %d, %Y')
  end
end
```

Should only be used when migrating from Active Model Serializers, as it's slower and can create confusion.

Instead, use `attributes` for model methods, and the inline `attribute` for serializer attributes. Being explicit makes serializers easier to understand, and to maintain.

Please refer to the [migration guide] for more information.

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

## Associations DSL 🛠

Use `has_one` to serialize individual objects, and `has_many` to serialize a collection.

The value for the association is obtained from a serializer method if defined, or by calling the method in the object being serialized.

You must specificy which serializer to use with the `serializer` option.

```ruby
class SongSerializer < Oj::Serializer
  has_one :album, serializer: AlbumSerializer
  has_many :composers, serializer: ComposerSerializer

  # You can also compose serializers using `flat_one`.
  flat_one :song, serializer: SongMetadataSerializer
end
```

The associations DSL is more concise and achieves better performance, so prefer to use it instead of manually definining attributes:

```ruby
class SongSerializer < SongMetadataSerializer
  attribute \
  def album
    AlbumSerializer.one(song.album)
  end

  attribute \
  def composers
    ComposerSerializer.many(song.composers)
  end
end
```

## Other DSL 🛠

### Using a different alias for the internal object

You can use `object_as` to create an alias for the serialized object to access it from instance methods:

```ruby
class DiscographySerializer < Oj::Serializer
  object_as :artist

  # Now we can use `artist` instead of `object` or `discography`.
  def latest_albums
    artist.albums.desc(:year)
  end
end
```

### Rendering an attribute conditionally

All the attributes and association methods can take an `if` option to render conditionally.

```ruby
class AlbumSerializer < Oj::Serializer
  mongo_attributes :release_date, if: -> { album.released? }

  has_many :songs, serializer: SongSerializer, if: -> { album.songs.any? }

  # You can achieve the same by manually defining a method:
  def include_songs?
    album.songs.any?
  end
end
```

### Memoization & Local State

Serializers are designed to be stateless so that an instanced can be reused, but sometimes it's convenient to store intermediate calculations.

Use `memo` for memoization and storing temporary information.

```ruby
class DownloadSerializer < Oj::Serializer
  attributes :filename, :size

  attribute \
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

### Render to Hash

In cases where you need objects instead of a JSON string, you can use `render_as_hash`:

```ruby
album = Album.find(params[:id])
AlbumSerializer.render_as_hash(album)
# {name: "Abraxas", genres: ["Pyschodelic Rock", "Blues Rock", ...

albums = Album.all
PersonSerializer.render_as_hash(albums)
# [{name: "Abraxas", genres: ["Pyschodelic Rock", "Blues Rock", ...
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

Have in mind that building a hash is typically less performant than writing to a
string directly, as more objects are allocated, so prefer using the [Render DSL]
whenever possible.

### Caching 📦

Use `cached` to leverage key-based caching, which calls `cache_key` in the object. You can also provide a lambda to `cached_with_key` to define a custom key:

```ruby
class CachedUserSerializer < UserSerializer
  cached_with_key ->(user) {
    "#{ user.id }/#{ user.current_sign_in_at }"
  }
end
```

It will leverage `fetch_multi` when serializing a collection with `many` or `has_many`, to minimize the amount of round trips needed to read and write all items to cache. This works specially well if your cache store also supports `write_multi`.

Usually serialization happens so fast that __turning caching on can be slower__. Always benchmark to make sure it's worth it, and use caching only for time-consuming or deeply nested structures.

## Design 📐

Unlike `ActiveModel::Serializer`, which builds a Hash that then gets encoded to
JSON, this implementation can use `Oj::StringWriter` to write JSON directly,
greatly reducing the overhead of allocating and garbage collecting the hashes.

It also allocates a single instance per serializer class, which makes it easy
to use, while keeping memory usage under control.

### Comparison with other libraries

`ActiveModel::Serializer` instantiates one serializer object per item to be serialized.

Other libraries such as [`jsonapi-serializer`][jsonapi] evaluate serializers in the context of
a `class` instead of an `instance` of a class. Although it is efficient in terms
of memory usage, the downside is that you can't use instance methods or local
memoization, and any mixins must be applied to the class itself.

[`panko-serializer`][panko] also uses `Oj::StringWriter`, but it has the big downside of having to own the entire render tree. Putting a serializer inside a Hash or an Active Model Serializer and serializing that to JSON doesn't work, making a gradual migration harder to achieve. Also, it's optimized for Active Record but I needed good Mongoid support.

`Oj::Serializer` combines some of these ideas, by using instances, but reusing them to avoid object allocations. Serializing 10,000 items instantiates a single serializer. Unlike `panko-serializer`, it doesn't suffer from [double encoding problems](https://panko.dev/docs/response-bag) so it's easier to use.

As a result, migrating from `active_model_serializers` is relatively straightforward because instance methods, inheritance, and mixins work as usual.

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
