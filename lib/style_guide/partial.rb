require 'nokogiri'
require 'kramdown'

module StyleGuide
  class Partial
    attr_reader :path, :section

    def initialize(path, section)
      @path = path
      @section = section
    end

    def id
      @id ||= title.downcase.gsub(/[^a-zA-Z0-9]+/, '_')
    end

    def title
      @title ||= File.basename(path, File.extname(path)).titleize.strip
    end

    def description
      return @description if defined? @description
      return @description = nil unless (description = translated('description')).present?
      @description = Kramdown::Document.new(description).to_html
    end

    def classes
      @classes ||= begin
        parsed.css('[class]').reduce({}) do |output, tag|
          output.tap do |tags|
            tag['class'].split.each do |class_name|
              tags[".#{class_name}"] = true
            end
          end
        end.keys
      end
    end

    def ids
      @ids ||= parsed.css('[id]').map { |tag| %(##{tag['id']}) }
    end

    def identifiers
      if (selectors = translated('identifiers')).present?
        selectors.split
      else
        ids + classes
      end
    end

    def render
      @render ||= action_view.render(file: path)
    end

    private

    def action_view
      ActionView::Base.new(Rails.root.join('app', 'views'))
    end

    def style_guide_scope
      [:style_guide, section.id.to_sym]
    end

    def translated(suffix)
      I18n.translate!("#{id}.#{suffix}", scope: style_guide_scope)
    rescue I18n::MissingTranslationData
      nil
    end

    def parsed
      @parsed ||= Nokogiri::HTML.parse(render)
    end
  end
end
