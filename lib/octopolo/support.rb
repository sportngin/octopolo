module Octopolo
  module Support

    private 
    
    def symbolize_keys(objekt)
      case objekt
      when Hash then symbolize_hash(objekt)
      when Array then symbolize_array(objekt)
      else objekt
      end
    end

    def symbolize_hash(hash)
      hash.inject({}) do |result, (key, value)|
        new_key         = key.to_sym rescue key
        result[new_key] = symbolize_keys(value)
        result
      end
    end

    def symbolize_array(array)
      array.map {|val| symbolize_keys(val)}
    end

  end
end