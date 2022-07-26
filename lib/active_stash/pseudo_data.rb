module ActiveStash # :nodoc:
  # = (Experimental) Pseudo Data generator
  #
  # Including this module in a model that uses ActiveRecord encryption
  # will production data to be used safely in development.
  #
  # For this to work, you must set:
  #
  # ```
  # config.active_record.encryption.support_unencrypted_data = true
  # ```
  #
  # Encrypted values are used as seeds to fake values so that generated
  # values are deterministic.
  #
  # This means:
  #
  # * Developers can take a copy of production data for local dev
  # * Pseudo data is faked but loosely coupled to production data
  # * Pseudo data is the same each time a record is loaded
  # * Pseudo data is the same for all developers
  # * Adding new records locally works as normal
  #
  # ## Fake
  #
  # To fake a value, you must use Faker (only Faker is supported right now).
  # Using the `fake` class method, pass an attribute you want to fake and either a class name
  # or a proc.
  #
  # Note, that if you try to fake a field that is not encrypted nothing happens!
  #
  # Faking with a class name, will call a method on that class with the same name as the attribute.
  # Faking with a proc will pass the record instance to the proc and you can call Faker
  # methods you like.
  #
  # ## Example
  #
  # class User < ActiveRecord::Base
  #   encrypts :first_name
  #   encrypts :last_name
  #   encrypts :email
  #
  #   fake :first_name, Faker::Name
  #   fake :email, -> (user) { Faker::Internet.email(name: user.first_name) }
  #
  # ## Production
  #
  # In production (or any time that a record is successfully decrypted with a valid key)
  # faking will be skipped. This means you can leave your faking code in place and it will
  # only get run in dev (or any time that a key is not available).
  #
  module PseudoData
    def self.included(base)
      base.extend ClassMethods

      base.class_eval do
        after_initialize :fake_from_ciphertext
      end

      def fake_from_ciphertext
        self.class.encrypted_attributes.each do |attr|
          value = self[attr]
          # TODO: We must make sure that any fakes that use a proc happen after those that don't!
          attr_faker = self.class.faked_attributes[attr]
          if is_encrypted?(value) && attr_faker
            seed = OpenSSL::Digest::SHA256.digest(value).unpack("Q<").first
            self[attr] = attr_faker.fake_for(seed, self, attr)
          end
        end
      end

      def is_encrypted?(value)
        json = JSON.parse(value)
        json["p"] && json["h"]
      rescue
        false
      end
    end

    class AttributeFaker
      def initialize(faker)
        @faker = faker
      end

      def with_deterministic_seed(seed, &block)
        ::Faker::Config.random = Random.new(seed)
        yield block
      ensure
        ::Faker::Config.random = nil
      end

      def fake_for(seed, record, attr_name)
        with_deterministic_seed(seed) do
          case @faker
          when Proc
            @faker.call(record)
          when Class
            @faker.send(attr_name)

          else
            raise "Unknown faker config for '#{attr_name}'"
          end
        end
      end
    end

    module ClassMethods
      attr_reader :faked_attributes

      def fake(attr, faker)
        @faked_attributes ||= {}
        @faked_attributes[attr.to_sym] = AttributeFaker.new(faker)
      end
    end
  end
end
