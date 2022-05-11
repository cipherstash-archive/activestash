# ActiveStash

ActiveStash is the Rails specific gem for using [CipherStash](https://cipherstash.com).
It provides search functionality for ActiveRecord models
that are configured to use field level encryption (using [Lockbox](https://github.com/ankane/lockbox) or
[EncryptedRecord](https://guides.rubyonrails.org/active_record_encryption.html)).
When records are created or updated, they are indexed into a CipherStash collection
which can be queried via an ActiveStash::Relation.

## What is CipherStash?

Field-level encryption is a powerful tool to protect sensitive data in your Active Record models.
However, when a field is encrypted, it can't be queried!
Simple lookups are impossible let alone free-text search or range queries.

This is where CipherStash comes in.
CipherStash is an Encrypted Search Index and using ActiveStash allows you to perform exact, free-text and
range queries on your Encrypted ActiveRecord models.
Queries use `ActiveStash::Relation` which wraps `ActiveRecord::Relation` so _most_ of the queries you can do in
ActiveRecord can be done using ActiveStash.

## How does it work?

ActiveStash uses the "look-aside" pattern to create an external, fully encrypted index for your ActiveRecord models.
Every time you create or update a record, the data is indexed to CipherStash via ActiveRecord callbacks.
Queries are delegated to CipherStash but return ActiveRecord models so things just work.

If you've used Elasticsearch with gems like [Searchkick](https://github.com/ankane/searchkick), this pattern will be familiar to you.


## Getting a workspace

To use `ActiveStash` you need a CipherStash account and workspace.
See our [Getting Started Guide](https://docs.cipherstash.com/tutorials/getting-started/index.html) to get one set up.

## Installation

Add this line to your applications Gemfile:

    gem 'activestash'

And then execute:

    $ bundle install

To use, include ActiveStash::Search in a model and define which fields you want to make searchable:

```ruby
class User < ActiveRecord::Base
  include ActiveStash::Search

  stash_index :name, :email, :dob

  # fields encrypted with EncryptedRecord
  encrypts :name
  encrypts :email
  encrypts :dob

  # ...the rest of your code
end
```

Any model in which you include ActiveStash::Search, will need to have a `stash_id` column added of type `string`.
For example, to add this to the table underlying your `User` model:

```sh
rails g migration AddStashIdToUser stash_id:string:index
rails db:migrate
```

The above command also ensures that an index is created on `stash_id`.

## Index Types

CipherStash supports 3 main types of indexes: `exact`, `range` (allows queries like `<` and `>`)
and `match` which supports free-text search.

ActiveStash will automatically determine what kinds of indexes to create based on the underlying data-type.
These are as follows:

### String and Text

`:string` and `:text` types automatically create the following indexes.
Range indexes on strings typically only work for ordering.

| Indexes Created | Allowed Operators | Example |
|-----------------|-------------------|---------------------|
| `match`         | `=~`              | `User.query { |q| q.name =~ "foo" }` |
| `exact`         | `==`              | `User.query(email: "foo@example.com)` |
| `range`         | `<`, `<=`, `==`, `>=`, `>` | `User.query.order(:email)` |

### Numeric Types

`:timestamp`, `:date`, `:datetime`, `:float`, `:decimal`, and `:integer` types all have `range` indexes created.

| Indexes Created | Allowed Operators | Example |
|-----------------|-------------------|---------------------|
| `range`         | `<`, `<=`, `==`, `>=`, `>`, `between` | `User.query { \|q\| q.dob > 20.years.ago }` |

### Overriding Automatically Created Indexes

If you need finer grained control over what types of indexes are created for a field, you can pass the `:except` or
`:only` options to `stash_index` (can be a symbol or array).

For example, to on create an `:exact` index for an integer field, you could do:

```ruby
stash_index :my_integer, only: :exact
```

To exclude the `:range` from a string type (say if you don't need to order by string), you can do:

```ruby
stash_index :my_string, except: :range
```

## Match All Indexes

ActiveStash can also create an index across multiple string fields so that you can perform free-text queries across all
specified fields at once.

To do so, you can use the `stash_match_all` DSL method and specify the fields that you want to have indexed:

```ruby
stash_match_all :first_name, :last_name, :email
```

Match all indexes are queryable by passing the query term directly to the `query` method.
So to search for the term "ruby" across `:first_name`, `:last_name` and `:email` you would do:

```ruby
User.query("ruby")
```

For more information on index types and their options, see the [CipherStash
docs](https://docs.cipherstash.com/reference/index-types/index.html).

## Create a CipherStash Collection

Before you can index your models, you need a CipherStash collection.
ActiveStash will create indexes as defined in your models.

All you need to do is create the collection by running:

    rails active_stash:collections:create

This command will create collections for all the models you have set up to use ActiveStash.

## (Re)indexing

To index your encrypted data into CipherStash, use the reindex task:

```sh
rails active_stash:reindexall
```

If you want to just reindex one model, for example `User`, run:

```sh
active_stash:reindex[User]
```

You can also reindex in code:

```ruby
User.reindex
```

Depending on how much data you have, reindexing may take a while but you only need to do it once.
*ActiveStash will automatically index (and delete) data as it records are created, updated and deleted.*

## Running Queries

To perform queries over your encrypted records, you can use the `query` method
For example, to find a user by email address:

```ruby
User.query(email: "person@example.com")
```

This will return an ActiveStash::Relation which extends `ActiveRecord::Relation` so you can chain *most* methods
as you normally would!

To constrain by multiple fields, include them in the hash:

```ruby
User.query(email: "person@example.com", verified: true)
```

To order by `dob`, do:

```ruby
User.query(email: "person@example.com).order(:dob)
```

Or to use limit and offset:

```ruby
User.query(verified: true).limit(10).offset(20)
```

This means that `ActiveStash` should work with pagination libraries like Kaminari.

You also, don't have to provide any constraints at all and just use the encrypted indexes for ordering!
To order all records by `dob` descending and then `created_at`, do (note the call to query with no args first):

```ruby
User.query.order(dob: :desc, :created_at)
```

### Advanced Queries

More advanced queries can be performed by passing a block to `query`.
For example, to find all users born in or after 1998:

```ruby
User.query { |q| q.dob > "1998-01-01".to_date }
```

Or, to perform a free-text search on name:

```ruby
User.query { |q| q.name =~ "Dan" }
```

To combine multiple constraints, make multiple calls in the block:

```ruby
User.query do |q|
  q.dob > "1998-01-01".to_date
  q.name =~ "Dan"
end
```

## Overriding the Collection Name

To set a different collection name, you can set one in your model:

```ruby
class User < ActiveRecord::Base
  include ActiveStash::Search
  self.collection_name = "mycollection"
end
```

## Setting a Default Scope

If you plan to use encrypted queries for all the data in your model, you can set a default scope:

```ruby
class User < ActiveRecord::Base
  include ActiveStash::Search

  def self.default_scope
    ActiveStash::Relation.new(self)
  end
end
```

Now, all queries will use the CipherStash collection, even if you don't call `query`.
For example, this will use encrypted indexes to order:

```ruby
User.order(:dob)

# Without a default scope you'd need to call
User.query.order(:dob)
```

## Managing Access Keys

Access keys are secret credentials that allow your application to authentication to CipherStash when it is running in a non-interactive environment (such as production or CI).
ActiveStash provides rake tasks to manage the access keys for your workspace.

To create a new access key:

```sh
rake active_stash:access_key:create[keyname]
```

To list all the access keys currently associated with your workspace:

```sh
rake active_stash:access_key:list
```

Finally, to delete an access key:

```sh
rake active_stash:access_key:delete[keyname]
```

Every access key must have a unique name, so you know what it is used for (and so you don't accidentally delete the wrong one).
You can have as many access keys as you like.

## Collection Management

### Drop a Collection

You can drop a collection directly in Ruby:

```ruby
User.collection.drop!
```

Or via the included Rake task.
This command takes the name of the _model_ that is attached to the collection.

```sh
rake active_stash:collections:drop[User]
```

### List Stash Enabled Models

A rake task is provided to list all of the models in your application that have been configured to use CipherStash.

```sh
rake active_stash:collections:list
```

### Create a Collection

You can also create a collection for a specific model in Ruby:

```ruby
User.collection.create!
```

Or via a Rake task:

```sh
rake active_stash:collections:create[User]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cipherstash/activestash. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cipherstash/activestash/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Activestash project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cipherstash/activestash/blob/master/CODE_OF_CONDUCT.md).
