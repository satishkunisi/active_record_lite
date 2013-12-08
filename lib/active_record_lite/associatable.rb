require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
  end

  def other_table
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    name = name.to_s.capitalize

    defaults = {
      :other_class_name => name,
      :primary_key => "id",
      :foreign_key => "#{name}_id"
    }

    params = defaults.merge(params)

    params.each do |method, value|
      self.class.define_method(method) do
        value
      end
    end

    self.class.define_method(:other_class) do
      name.constantize
    end

    self.class.define_method(:other_table_name) do
      name.constantize.table_name
    end

  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
  end

  def type
  end
end

module Associatable
  def assoc_params
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    self.class.parse_all

  end

  def has_many(name, params = {})
  end

  def has_one_through(name, assoc1, assoc2)
  end

end
