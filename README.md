# Oj Serializers

A faster JSON serializer for Ruby on Rails. Easily migrate away from Active Model Serializers.

## Why? 🤔

`ActiveModel::Serializer` has a nice API, but it can require too many object
allocations, leading to memory bloat, time spent on GC, and low performance.

`Oj::Serializer` intends to provide a similar API with better performance.

### Design 📐

Unlike `ActiveModel::Serializer`, which builds a Hash that then gets encoded to
JSON, this implementation uses `Oj::StringWriter` to write JSON directly,
greatly reducing the overhead of allocating and garbage collecting the hashes.

Other libraries such as `fast_jsonapi` evaluate serializers in the context of
a `class` instead of an `instance` of a class. As a result you can't use instance
methods, and any mixins must be applied to the class itself.

`Oj::Serializer` uses instances instead, but keeps object allocations down by reusing them.

As a result, migrating from `active_model_serializers` is relatively
straightforward because instance methods, inheritance, and mixins work as usual.

## Features ⚡️

- Declaration syntax similar to Active Model Serializer.
- Reduced memory allocation and improved performance.
- Support for `has_one` and `has_many`.
- Caching.

## Installation ⚙️

Add this line to your application's Gemfile:

```ruby
gem 'oj_serializers'
```

Execute:

    $ bundle install

## Usage 📖

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

It's recommended to create your own `BaseSerializer` class in order to easily
add custom extensions, specially when migrating from `active_model_serializers`.

## Migrating from `active_model_serializers` ⏩

You can use these serializers inside arrays, hashes, or even inside `ActiveModel::Serializer`.

Follow [this discussion](https://github.com/ohler55/oj/issues/542) to find out more about [the `raw_json` extensions](https://github.com/ohler55/oj/issues/542) that made this great level of interoperability possible.

As a result, you can gradually replace the serializers one by one if needed.

### Path Helpers 🛣

In case you need to access path helpers in the serializer, you can use the
following:

```ruby
class BaseJsonSerializer < Oj::Serializer
  include Rails.application.routes.url_helpers

  def default_url_options
    Rails.application.routes.default_url_options
  end
end
```

One slight variation that might make it easier to maintain in the long term is
to use a separate singleton service to provide the url helpers and options, and
make it available as `urls`.

### Controller & Params 🚧

This pattern is usually a bad practice, because it couples the serializer to the
controller, making it harder to reuse or test independently.

However, it can be handy if you were already relying on this with `ActiveModel::Serializer`:

```ruby
class ApplicationController < ActionController::Base
  before_action { RequestLocals[:current_controller] = self }
end

class BaseJsonSerializer < Oj::Serializer
  def scope
    @scope ||= RequestLocals[:current_controller]
  end

  def params
    @params ||= scope&.params || {}
  end
end
```

Using `request_store` or `request_store_rails` is advisable instead of using
`Thread.current`, since keeping a reference to a controller after the request is
done could cause problems and memory bloat.

## Special Thanks 🙏

This library wouldn't be possible without the wonderful and performant [`oj`](https://github.com/ohler55/oj) library.

Huge thanks to [Peter](https://github.com/ohler55)! :smiley:

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
