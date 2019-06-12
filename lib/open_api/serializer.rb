module OpenApi
  module Serializer
    def as_json(arg = {})
      previous = super
      encrypted_columns_set = (self.class.try(:encrypted_columns) || []).to_set
      encryption_filtered = previous.except(*encrypted_columns_set)
      version = version_from_path(arg)

      return encryption_filtered unless arg.key?(:prefixes) || version

      # We use "#{klass.name}Out" for the definitions on what are returned.
      schema = Api::Docs[version].definitions[self.class.name + "Out"]

      filter(encryption_filtered.slice(*schema["properties"].keys), schema, encrypted_columns_set)
    end

    private

    def version_from_path(arg)
      url = ManageIQ::API::Common::Request.current.instance_variable_get(:@original_url) || nil
      base_path = url ? URI.parse(url).path : arg[:prefixes].first
      api_version_from_prefix(base_path)
    end

    def filter(attrs, schema, encrypted_columns_set)
      schema["properties"].keys.each do |name|
        next if attrs[name].nil?

        attrs[name] = attrs[name].iso8601 if attrs[name].kind_of?(Time)
        attrs[name] = attrs[name].to_s if name.ends_with?("_id") || name == "id"
        attrs[name] = public_send(name) if !attrs.key?(name) && !encrypted_columns_set.include?(name)
      end
      attrs.compact
    end

    def api_version_from_prefix(prefix)
      return unless prefix

      /\/?\w+\/v(?<major>\d+)[x\.]?(?<minor>\d+)?\// =~ prefix
      [major, minor].compact.join(".")
    end
  end
end
