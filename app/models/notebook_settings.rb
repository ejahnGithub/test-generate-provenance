# honestly, just a quick convenience wrapper
class NotebookSettings
  attr_reader :notebook_namespace
  def initialize(notebook)
    @notebook_namespace = "notebook-#{notebook}"
  end

  def get(key)
    Setting.get(notebook_namespace, key) || Setting::DEFAULTS.dig(:site, key)
  end

  def set(key, value)
    Setting.set(notebook_namespace, key, value)
  end

  def all
    Setting.where(namespace: notebook_namespace)
  end
end
