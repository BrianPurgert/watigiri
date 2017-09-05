module Watigiri
  class Element
    attr_reader :element, :selector

    def initialize(element:, selector:)
      @element = element
      @selector = selector
    end
  end

  module Locators
    class Element
      class Locator < Watir::Locators::Element::Locator

        def locate
          @nokogiri = @selector.delete(:nokogiri)
          @regex = @selector.values.any? { |e| e.is_a? Regexp }

          return super unless @nokogiri || @regex
          @query_scope.browser.doc ||= Nokogiri::HTML(@query_scope.html).tap { |d| d.css('script').remove }

          element = find_first_by_multiple
          @nokogiri ? element.element : nokogiri_to_selenium(element)
        end

        def locate_all
          @nokogiri = @selector.delete(:nokogiri)
          @regex = @selector.values.any? { |e| e.is_a? Regexp }

          return super unless @nokogiri || @regex

          elements = find_all_by_multiple.map(&:element)
          @nokogiri ? elements : @elements.map { |element| nokogiri_to_watir element }
        end

        # Is only used when there is no regex, index or visibility locators
        def locate_element(how, what)
          return super unless @nokogiri

          el = @query_scope.browser.doc.send("at_#{how}", what)
          Watigiri::Element.new element: el, selector: {how => what}
        end

        # "how" can only be :css or :xpath
        def locate_elements(how, what, _scope = @query_scope.wd)
          return super unless @nokogiri || @regex

          @query_scope.browser.doc.send(how, what).map do |el|
            Watigiri::Element.new element: el, selector: {how => what}
          end
        end

        def filter_elements noko_elements, visible, idx, number
          return super unless @nokogiri || @regex
          unless visible.nil?
            noko_elements.select! { |el| visible == nokogiri_to_watir(el.element).visible? }
          end
          number == :single ? noko_elements[idx || 0] : noko_elements
        end

        def filter_elements_by_regex(noko_elements, rx_selector, method)
          return if noko_elements.empty?

          if @nokogiri || !@regex
            return noko_elements.__send__(method) { |el| matches_selector?(el.element, rx_selector) }
          end

          selenium_elements = ensure_scope_context.find_elements(noko_elements.first.selector)

          if method == :select
            selenium_elements.zip(noko_elements).each_with_object([]) do |els, array|
              array << els.first if matches_selector?(els.last.element, rx_selector)
            end
          else
            index = noko_elements.find_index { |el| matches_selector?(el.element, rx_selector) }
            selenium_elements[index]
          end
        end

        def fetch_value(element, how)
          return super unless @nokogiri || @regex
          case how
          when :text
            element.inner_text
          when :tag_name
            element.name.to_s.downcase
          when :href
            (href = element.attribute('href')) && href.to_s.strip
          else
            element.attribute(how.to_s.tr("_", "-")).to_s
          end
        end

        def nokogiri_to_watir(element)
          se_element = nokogiri_to_selenium(element)
          tag = element.name
          Watir.element_class_for(tag).new(@query_scope, element: se_element)
        end

        def nokogiri_to_selenium(element)
          return element if element.is_a?(Selenium::WebDriver::Element)
          tag = element.name
          index = @query_scope.browser.doc.xpath("//#{tag}").find_index { |el| el == element }
          Watir::Element.new(@query_scope, index: index, tag_name: tag).wd
        end

      end
    end
  end
end
