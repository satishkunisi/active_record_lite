require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
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
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params = {})
    name = name.to_s.camelcase

    if name.split('').include?('_')
      name_arr = name.split('')
      name = name_arr.reject! { |l| l == '_'}.join('')
    end

    defaults = {
      :other_class_name => name,
      :primary_key => "id",
      :foreign_key => "#{name.downcase}_id"
    }

    @params = defaults.merge(params)
  end

end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    name = name.to_s.camelcase

    if name.split('').include?('_')
      name_arr = name.split('')
      name = name_arr.reject! { |l| l == '_'}.join('')
    end

    defaults = {
      :other_class_name => name.singularize,
      :primary_key => "id",
      :foreign_key => "#{self_class.to_s.underscore}_id"
    }

    @params = defaults.merge(params)
  end

end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)

    self.assoc_params[name] = aps

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
    aps = HasManyAssocParams.new(name, params, self.class)

    #human.cats
    # give me all cats where their foreign_key = my id

    define_method(name) do
      query = <<-SQL
      SELECT
        *
      FROM
        #{aps.other_class_table}
      WHERE
        #{aps.foreign_key} = ?
      SQL

      results = DBConnection.execute(query, self.send(aps.primary_key))

      result = aps.other_class.parse_all(results)
      result
    end


  end

  def has_one_through(name, assoc1, assoc2)


    define_method(name) do

      # through
      aps1 = self.class.assoc_params[assoc1]
      # source
      aps2 = aps1.other_class.assoc_params[assoc2]

      fk = self.send(aps1.foreign_key)

      query = <<-SQL
        SELECT
          #{aps2.other_class_table}.*
        FROM
        #{aps2.other_class_table}
        JOIN
        #{aps1.other_class_table}
        ON
        #{aps2.foreign_key} = #{aps2.other_class_table}.#{aps2.primary_key}
        WHERE
        #{aps1.other_class_table}.#{aps1.primary_key} = ?
      SQL

      results = DBConnection.execute(query, fk)
      aps2.other_class.parse_all(results)[0]
    end

  end

end
