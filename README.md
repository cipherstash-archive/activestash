# ActiveStash

ActiveStash is the Rails specific gem for using [CipherStash](https://cipherstash.com).
It provides search functionality for ActiveRecord models
that are configured to use field level encryption (using [Lockbox](https://github.com/ankane/lockbox) or
[EncryptedRecord](https://guides.rubyonrails.org/active_record_encryption.html)).
When records are created or updated, they are indexed into a CipherStash collection
which can be queried via an ActiveStash::Relation.

## Getting a workspace

To use `ActiveStash` you need a CipherStash account and workspace.
See our [Getting Started Guide](https://docs.cipherstash.com/tutorials/getting-started/index.html) to get one set up.

## Installation

Add this line to your applications Gemfile:

    gem 'activestash'

And then execute:

    $ bundle install

To use, include ActiveStash::Search in a model:

```ruby
class User < ActiveRecord::Base
  include ActiveStash::Search

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
rails g migration AddStashIdToUser stash_id:string
rails db:migrate
```

## Create a CipherStash Collection

Before you can index your models, you need a CipherStash collection.
ActiveStash will determine the appropriate indexes and settings based on your model.

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

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/activestash`. To experiment with that code, run `bin/console` for an interactive prompt.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cipherstash/activestash. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cipherstash/activestash/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Activestash project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cipherstash/activestash/blob/master/CODE_OF_CONDUCT.md).
