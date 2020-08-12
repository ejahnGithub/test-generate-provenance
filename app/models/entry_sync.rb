class EntrySync
  attr_accessor :notebook, :entry, :dirname, :notebook_folder_path, :exporter
  def initialize(entry, dirname = nil)
    @entry = entry
    @notebook = Notebook.find_by(name: entry.notebook)
    @dirname = dirname || @notebook.sync_path # i.e. Documents/arquivo
    @notebook_folder_path = File.join(@dirname, @notebook.to_s)
    @exporter = Exporter.new(dirname, notebook)
  end

  def versions
    repo = init_repo(notebook_folder_path)
    full_filepath = entry.to_full_filepath(dirname)
    if File.exist?(full_filepath)
      repo.log.path(full_filepath).map { |c| [c.sha, c.date] }
    else
      []
    end
  end

  def get_version(sha)
    repo = init_repo(notebook_folder_path)
    full_filepath = entry.to_full_filepath(dirname)
    if File.exist?(full_filepath)
      yaml = repo.object("#{sha}:#{entry.to_relative_filepath}").contents
      PastEntry.new(YAML.load(yaml))
    else
      nil
    end
  end

  def write!
    repo = init_repo(notebook_folder_path)
    entry_folder_path = write_to_disc(entry, dirname)
    commit_to_repo(repo, entry, entry_folder_path)
  end

  def init_repo(working_dir)
    FileUtils.mkdir_p(working_dir)
    Git.init(working_dir)
  end

  # should also work on an individual file eh?
  def write_to_disc(entry, dirname)
    exporter.export_entry!(entry, dirname)
  end

  def commit_to_repo(repo, entry, entry_folder_path)
    repo.add(entry_folder_path)
    repo.commit(entry.identifier)
  end

  def ready?
    raise "can't see git in PATH" unless do_we_have_git?
    raise "can't write to #{dirname}" unless File.writable?(dirname)
  end

  def do_we_have_git?
    %x[which git].present?
  end

end

