module TimelineHelper
  def truncate_class(entry)
    if (entry.body&.size || 0) > 1024
      " truncate"
    else
      ""
    end
  end
end
