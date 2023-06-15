class Setting < KeyValue
  # fyi, this gets overridden in test_helper
  DATA_PATH = ENV["ARQUIVO_PATH"] || File.join(ENV["HOME"], "Documents", "arquivo")
  DEFAULTS = {
    :arquivo => {
      arquivo_path: DATA_PATH
    },
    :site => {
      host: "example.com",
      port: "80",
      title: "This is a default title.",
      author_name: "Example Author Name",
    }
  }

  def self.default(namespace, key)
    if DEFAULTS.dig(namespace, key)
      self.new(namespace: namespace,
               key: key,
               value: DEFAULTS[namespace][key])
    end
  end

  def self.get(namespace, key)
    v = super
    if v.nil?
      DEFAULTS.dig(namespace, key)
    else
      v
    end
  end

  def self.fetch(namespace, key)
    kv = super
    if kv.nil?
      default(namespace, key)
    else
      kv
    end
  end
end
