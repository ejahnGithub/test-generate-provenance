class Search
  attr_reader :tokens

  FILTERS = Set.new([
    "is:everything",
    "is:calendar",
    "is:bookmark",
    "is:note",
    "has:todo",
    "has:done",
    "has:file",
    "not:todo",
    "not:note",
    "not:calendar",
    "not:bookmark",
    "hide:true",
    "sort:asc",
    "sort:created",
    "sort:created-asc",
    "only:todo"
  ])

  OPERATORS = [
    "before:",
    "after:"
  ]

  attr_reader :notebook
  def initialize(notebook)
    @notebook = notebook
  end

  def parse_query(query:)
    @tokens = []

    # super lazy quick way of doing this
    query.gsub(/"([^"]*)"/) do |match|
      @tokens << match.gsub('"', '')
      ""
    end.split do |s|
      @tokens << s
    end

    @filters, @tokens = parse_filters(@tokens)
    @operators, @tokens = parse_operators(@tokens)

    return [@tokens, @filters, @operators]
  end

  def find(query:)
    tokens, filters, operators = parse_query(query: query)

    sql_query = Entry.for_notebook(notebook).order(occurred_at: :desc).hitherto

    sql_where = tokens.map do |s|
      ["body like ? or subject like ? or url like ? or identifier like ?", "%#{s}%", "%#{s}%", "%#{s}%", "%#{s}%"]
    end

    sql_where.each do |where|
      sql_query = sql_query.where(*where)
    end

    filters.each do |op|
      sql_query = case op
                  when "is:everything"
                    sql_query
                  when "is:calendar"
                    sql_query.calendars
                  when "is:bookmark"
                    sql_query.bookmarks
                  when "is:note"
                    sql_query.notes
                  when "has:todo"
                    # sql_query.where("body like ?", "%- [ ]%")
                    sql_query.with_todos
                  when "has:done"
                    # sql_query.where("body like ?", "%- [x]%")
                    sql_query.with_completed_todos
                  when "has:file"
                    sql_query.with_files.group(:id)
                  when "hide:true"
                    sql_query.hidden
                  when "not:todo"
                    sql_query.where("body not like ?", "%- [ ]%")
                  when "not:calendar"
                    sql_query.except_calendars
                  when "not:bookmark"
                    sql_query.except_bookmarks
                  when "not:note"
                    sql_query.where("kind is not null")
                  when "sort:asc"
                    sql_query.reorder(occurred_at: :asc)
                  else
                    sql_query
                  end
    end

    operators.each do |op, arg|
      sql_query = case op
                  when "before:"
                    date = date_str_to_date(arg)
                    sql_query.before(date)
                  when "after:"
                    date = date_str_to_date(arg)
                    sql_query.after(date)
                  end
    end

    sql_query
  end

  def parse_filters(tokens)
    filters = []
    tokens = tokens.reject { |t| FILTERS.member?(t) && (filters << t) }

    [filters, tokens]
  end

  def parse_operators(tokens)
    operators = []
    tokens = tokens.reject do |t|
      OPERATORS.any? do |op|
        # token t is a string "foo:bar"
        # if substring "foo:" exists, and the character following ':'
        # a) is not nil (i.e. the string continues past the operator)
        # b) is not whitespace
        if (i = t.index(op)) && not_nil_nor_whitespace?(t[i+op.length])
          operators << [op, t[i+op.length..-1]]
        else
          nil
        end
      end
    end

    [operators, tokens]
  end

  def not_nil_nor_whitespace?(char)
    !char.nil? && !char.match?(/\s/)
  end

  def date_str_to_date(str)
     case str
     when "yesterday"
       Time.current.yesterday.end_of_day
     when "lastweek"
       8.days.ago.end_of_day
     when "lastmonth"
       Time.current.prev_month.end_of_month
     when "lastyear"
       Time.current.beginning_of_year
     else
       Time.zone.parse(str).beginning_of_day
     end
  end
end
