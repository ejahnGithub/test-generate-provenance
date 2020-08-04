require 'task_list/filter'
class EntryRenderer
  # nota bene:
  # must use MarkdownFilter with unsafe
  # which means must use SanitizationFilter
  # which means must not have CommonMarker insert TaskLists and
  # instead must have a filter transform AFTER sanitization
  PIPELINE = HTML::Pipeline.new [
    PipelineFilter::MarkdownFilter,
    HTML::Pipeline::SanitizationFilter,
    PipelineFilter::MyTaskListFilter,
    PipelineFilter::HashtagFilter,
    PipelineFilter::MentionFilter,
    HTML::Pipeline::TableOfContentsFilter,
    HTML::Pipeline::ImageMaxWidthFilter,
  ], { unsafe: true,
       commonmarker_render_options: [:SOURCEPOS],
       whitelist: PipelineFilter::ENTRY_SANITIZATION_WHITELIST
  }

  attr_accessor :entry, :notebook
  def initialize(entry)
    @entry = entry
    @notebook = entry.notebook
  end

  # TODO: to_html should accept… a string, maybe?
  # not clear how this api should work.
  # should it accept: an attribute, a method, a full string?, a flag (i.e. :todo)
  # or just make everything a named keyword.

  def to_html(attribute_name = "body")
    attribute = entry.attributes[attribute_name]
    if !attribute
      ""
    else
      PIPELINE.to_html(attribute, entry: entry).html_safe
    end
  end

  # i don't love this - maybe this should be folded into #to_html
  # but for now this is easy to cache
  def todo_to_html
    @todo_to_html ||= PIPELINE.to_html(entry.body, entry: entry, todo_only: true).html_safe
  end

  # TODO: fold this into the HashtagFilter, maybe?
  def extract_tags
    entry.body&.scan(PipelineFilter::HashtagFilter::HASHTAG_REGEX)&.flatten || []
  end
end
