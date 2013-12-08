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
      :foreign_key => "#{name.downcase}_id"
    }

    @params = defaults.merge(params)
  end

  def other_class_name
    @params[:other_class_name]
  end

  def primary_key
    @params[:primary_key]
  end

  def foreign_key
    @params[:foreign_key]
  end

  def other_class
    other_class_name.constantize
  end

  def other_class_table
    other_class.table_name
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
    define_method(name) do
      query = <<-SQL
      SELECT
        *
      FROM
        #{aps.other_class_table}
      WHERE
        #{aps.primary_key} = ?
      SQL


      fk = self.send(aps.foreign_key)
      results = DBConnection.execute(query, fk)

      result = aps.other_class.parse_all(results)[0]
      result
    end


  end

  def has_many(name, params = {})

  end

  def has_one_through(name, assoc1, assoc2)
  end

end
