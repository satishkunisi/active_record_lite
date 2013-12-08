require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject

  extend Searchable
  extend Associatable

  # sets the table_name
  def self.set_table_name(table_name)
    @table_name = table_name
  end

  # gets the table_name
  def self.table_name
    @table_name
  end

  # querys database for all records for this type. (result is array of hashes)
  # converts resulting array of hashes to an array of objects by calling ::new
  # for each row in the result. (might want to call #to_sym on keys)
  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    rows.map do |row|
      self.new(row)
    end

  end

  # querys database for record of this type with id passed.
  # returns either a single object or nil.
  def self.find(id)
    result = DBConnection.execute(<<-SQL, :id => id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = :id
    SQL

    if result.empty?
      nil
    else
      self.new(result[0])
    end
  end

  # executes query that creates record in db with objects attribute values.
  # use send and map to get instance values.
  # after, update the id attribute with the helper method from db_connection
  def create
    attr_names = self.class.attributes.join(", ")
    values = []

    attribute_values.length.times do |n|
      values.concat(['?'])
    end

    values_string = values.join(",")

    # p attr_names

    query = <<-SQL
    INSERT INTO
      #{self.class.table_name}
      (#{attr_names})
    VALUES
      (#{values_string})
    SQL

    puts query

    DBConnection.execute(query, *attribute_values)

  end

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
  def update
    attr_names = self.class.attributes.join(", ")
    attr_values = attribute_values

    set_line = self.class.attributes.map { |attr_name| " #{attr_name} = ?" }.join(",")

    query = <<-SQL
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
       id = ?
    SQL

    DBConnection.execute(query, *attr_values, self.id)

  end

  # call either create or update depending if id is nil.
  def save
    self.id.nil? ? self.create : self.update
  end

  # helper method to return values of the attributes.
  def attribute_values
    self.class.attributes.map { |attr_name| self.send(attr_name) }
  end
end
