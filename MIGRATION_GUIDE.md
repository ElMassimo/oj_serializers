# Migration Guide

[request_store]: https://github.com/steveklabnik/request_store
[request_store_rails]: https://github.com/ElMassimo/request_store_rails
[readme]: https://github.com/ElMassimo/oj_serializers/blob/master/README.md

[oj]: https://github.com/ohler55/oj
[ams]: https://github.com/rails-api/active_model_serializers
[jsonapi]: https://github.com/jsonapi-serializer/jsonapi-serializer
[panko]: https://github.com/panko-serializer/panko_serializer
[benchmarks]: https://github.com/ElMassimo/oj_serializers/tree/master/benchmarks
[raw_benchmarks]: https://github.com/ElMassimo/oj_serializers/blob/master/benchmarks/document_benchmark.rb
[migration guide]: https://github.com/ElMassimo/oj_serializers/blob/master/MIGRATION_GUIDE.md
[raw_json]: https://github.com/ohler55/oj/issues/542
[trailing_commas]: https://maximomussini.com/posts/trailing-commas/

The DSL of `oj_serializers` is meant to be similar to the one provided by `active_model_serializers` to make the migration process simple,
though the goal is not to be a drop-in replacement.

## Rendering 🛠

To use the same format in controllers, using the `root`, `serializer`, `each_serializer` options, you should require the compatibility layer:

```ruby
# config/initializers/json.rb
require 'oj_serializers/compat'
```

Otherwise, use `one` and `many` to serialize objects or enumerables:

```ruby
render json: {
  favorite: LegacyAlbumSerializer.new(album),
  purchases: albums.map { |album| LegacyAlbumSerializer.new(album) },
}

# becomes

render json: {
  favorite: AlbumSerializer.one(album),
  purchases: AlbumSerializer.many(albums),
}
```

### Attributes

Have in mind that unlike in Active Model Serializers, `attributes` in `Oj::Serializer` will _not_ take into account methods defined in the serializer.

Specially in the beginning, you can replace `attributes` with `ams_attributes` to preserve the same behavior.

```ruby
class AlbumSerializer < ActiveModel::Serializer
  attributes :name, :release

  has_many :songs

  def album
    object
  end

  def release
    album.release_date.strftime('%B %d, %Y')
  end

  def include_release?
    album.released?
  end
end

# becomes

class AlbumSerializer < Oj::Serializer
  ams_attributes :name, :release

  # The serializer class must be explicitly provided.
  has_many :songs, serializer: SongSerializer

  def release
    album.release_date.strftime('%B %d, %Y')
  end

  # This AMS magic still works.
  def include_release?
    album.released?
  end
end
```

Once your serializer is working as expected, you can further refactor it to be more performant by using `attributes` and `serializer_attributes`.

Being explicit about where the attributes are coming from makes the serializers easier to understand and more maintainable.

```ruby
class AlbumSerializer < Oj::Serializer
  attributes :name

  has_many :songs, serializer: SongSerializer

  attr if: -> { album.released? }
  def release
    album.release_date.strftime('%B %d, %Y')
  end
end
```

The shorthand syntax for serializer attributes might seem odd at first, but it
makes it a lot easier to differentiate helper methods from attributes,
especially in large serializers.

## Migrate gradually, one at a time

You can use these serializers inside arrays, hashes, or even inside `ActiveModel::Serializer`.

```ruby
class LegacyAlbumSerializer < ActiveModel::Serializer
  attributes :songs

  def songs
    SongSerializer.many(object.songs)
  end
end
```

As a result, you can gradually replace the serializers one by one as needed.

## Path Helpers 🛣

In case you need to access path helpers in your serializers, you can use the
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

## Controller & Params 🚧

This pattern is usually a bad practice, because it couples the serializer to the
controller, making it harder to reuse or test independently.

However, it can be handy if you were already relying on this with `ActiveModel::Serializer`:

```ruby
class ApplicationController < ActionController::Base
  before_action { Thread.current[:current_controller] = self }
end

class BaseJsonSerializer < Oj::Serializer
  def scope
    @scope ||= Thread.current[:current_controller]
  end

  def params
    @params ||= scope&.params || {}
  end
end
```

Using [`request_store`][request_store] or [`request_store_rails`][request_store_rails] is advisable instead of using
`Thread.current`, since keeping a reference to a controller after the request is
done could cause memory bloat and additional problems.
