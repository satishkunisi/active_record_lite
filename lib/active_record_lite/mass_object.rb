class MassObject
  # takes a list of attributes.
  # creates getters and setters.
  # adds attributes to whitelist.


  def self.my_attr_accessor(*attributes)
    attributes.each do |attribute|
      attr_to_var = ("@" + attribute.to_s ).to_sym

      define_method("#{attribute}") do
        self.instance_variable_get(attr_to_var)
      end

      define_method("#{attribute}=") do |value|
        self.instance_variable_set(attr_to_var, value)
      end
    end
  end

  def self.my_attr_accessible(*attributes)
    @attributes ||= []

    attributes.each do |attribute|
      self.my_attr_accessor(attribute)
      @attributes << attribute
    end
  end

  # returns list of attributes that have been whitelisted.
  def self.attributes
    @attributes
  end

  # takes an array of hashes.
  # returns array of objects.
  def self.parse_all(results)
    new_obj = []

    results.each do |result|
      new_obj << self.new(result)
    end

    new_obj
  end

  # takes a hash of { attr_name => attr_val }.
  # checks the whitelist.
  # if the key (attr_name) is in the whitelist, the value (attr_val)
  # is assigned to the instance variable.
  def initialize(params = {})

    unless params.nil?
      params.each do |attr_name, attr_value|

        attr_name = attr_name.to_sym

        if self.class.attributes.include?(attr_name)
          self.send("#{attr_name}=", attr_value)
        else
          raise "Can't mass-asign non-whitelisted attributes: #{attr_name}"
        end
      end

    end

  end
end