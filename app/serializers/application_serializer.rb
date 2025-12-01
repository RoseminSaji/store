class ApplicationSerializer
  include FastJsonapi::ObjectSerializer

  def self.serialize(resource)
    new(resource).serializable_hash
  end
end
