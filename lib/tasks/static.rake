namespace :static do
  desc 'Generate static site in ./out/ directory'
  task :import => :environment do
    SyncFromDisk.new(ENV["NOTEBOOK_PATH"]).import!
  end

  task :generate do
    Dir.mkdir 'out' unless File.exist? 'out'
    Dir.chdir 'out' do
      puts `wget --version`
      puts "######\nwget --domains localhost  --recursive  --page-requisites  --html-extension  --convert-links -nH localhost:3000 localhost:3000/hidden_entries"
      `wget --domains localhost  --recursive  --page-requisites  --html-extension  --convert-links -nH localhost:3000 localhost:3000/hidden_entries`
      `rm -rf hidden_entries*`

      # i thought this was necessary but it turns out that in GH Pages it auto forwards /foo to /foo.html
      # Dir["*.html"].each do |file|
      #   next if file == "index.html"
      #   # we want to create symlinks from `foo.html` to `foo`
      #   # unless there's a directory, upon which we want
      #   # `foo/index.html`
      #
      #   identifier = file.chomp(".html")
      #
      #   if File.directory?(identifier)
      #     File.symlink(file, File.join(identifier, "index.html"))
      #
      #     thread_file = File.join(identifier, "thread.html")
      #     if File.exists?(thread_file)
      #       File.symlink(thread_file, File.join(identifier, "thread"))
      #     end
      #   else
      #     File.symlink(file, identifier)
      #   end
      # end
    end
  end
end
