require 'test_helper'

class StaticSiteImportExportTest < ActionDispatch::IntegrationTest
  # i should be testing the rake task directly?
  # and i should be able to:
  # - test this without the test suite being run in "static mode"
  # - test the wget interaction from within rails test, vs starting
  # a separate test command (ie booting up the server first)
  # BUT one step at a time.
  #
  # First let's build some guarantees that the SyncerFromDisk
  # does the right thing:

  test "we can import non-standard notebook paths, make some clever inferences wrt content, and generate a default site using the simple_site fixture" do
    if !Arquivo.static?
      puts "Not in static mode. Try again, with STATIC_PLS=true"
      return
    end

    # let's establish that the system is empty
    assert_equal 0, Notebook.count
    assert_equal 0, Entry.count

    notebook_path = File.join(Rails.root, "test/fixtures/static_sites/simple_site")
    SyncFromDisk.new(notebook_path).import!

    assert_equal 1, Notebook.count
    notebook = Notebook.last
    assert_equal "simple_site", notebook.name
    assert_equal 4, notebook.entries.count
    assert_equal 2, notebook.entries.documents.count
    assert_equal 2, notebook.entries.notes.count

    # okay so a count of 2 documents is wrong:
    # we want the about.html to be processed as an entry methinks,
    # not a plain ol' document. TODO: let's fix that later.

    get "/"
    assert_response 200, "if this fails, ensure that the spring preloader isn't stuck loading tests in non-static mode"
    # TODO: ideally, test that pagination triggers, works, etc

    # by default we get the following links for free:
    # /tags, /contacts, /hidden_entries
    get "/tags"
    assert_response 200

    get "/contacts"
    assert_response 200

    # the simple_site fixture intentionally does not define @mentions or #tags
    # TODO: test that /tags and /contacts are empty?

    # we also get /hidden_entries to process entries with hide: true, ie
    # entries that aren't linked from the timeline view / document type entries
    get "/hidden_entries"
    assert_response 200

    # i expect exactly two links:
    assert_equal 2, css_select("a").count
    assert_select "a[href='/youvechanged.jpg']"
    assert_select "a[href='/about.html']"

    # try getting individual pages:
    # get "/about.html"
    get "/2021/new_blog.html"
    assert_response 200

    get "/musings.html"
    assert_response 200

    # TODO: needs a /foo entry too

    get "/youvechanged.jpg"
    # we get redirected to the blobs path
    assert_response 302

    get response.location
    # we get redirected to the signed service url
    assert_response 302

    get response.location
    # we finally get the content:
    assert_response 200
    assert_equal "image/jpeg", response.content_type

    # want to test certain extensions (md & markdown),
    # want to test the folder paths
    # want to test the dates being set properly in the entries
    # want to test hidden field, and that hidden entries do not show up in the timeline

    # in the future, we can do:
    # get /feed.atom
    # get /calendar or /archive

    # and then we can start doing fancy shit like,
    # overriding layouts and custom stylesheets


    # okay so i've already discovered i want to test at least 3 versions of
    # static site generation:
    # 1. all the proper importing, markdown or not, entry paths etc
    # 2. a very basic site with no tags or contacts
    # 3. same as 1 or 2 but overriding the templates
  end
end
