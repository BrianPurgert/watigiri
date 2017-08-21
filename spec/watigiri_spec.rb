require "watirspec_helper"

describe Watigiri do
  require 'watirspec_helper'

  describe '#text!' do
    before do
      browser.goto(WatirSpec.url_for("non_control_elements.html"))
    end

    it "locates with page_source driver call" do
      expect(browser.driver).to receive(:page_source).once.and_return(browser.driver.page_source)
      expect(browser.driver).to_not receive(:find_element)

      expect(browser.li(id: "non_link_1").text!).to eq 'Non-link 1'
      expect(browser.li(id: /non_link_1/).text!).to eq 'Non-link 1'
      expect(browser.li(title: "This is not a link!").text!).to eq 'Non-link 1'
      expect(browser.li(title: /This is not a link!/).text!).to eq 'Non-link 1'
      expect(browser.li(text: "Non-link 1").text!).to eq 'Non-link 1'
      expect(browser.li(text: /Non-link 1/).text!).to eq 'Non-link 1'
      expect(browser.li(class: "nonlink").text!).to eq 'Non-link 1'
      expect(browser.li(class: /nonlink/).text!).to eq 'Non-link 1'
      expect(browser.li(id: /non_link/, index: 1).text!).to eq 'Non-link 2'
      expect(browser.li(xpath: "//li[@id='non_link_1']").text!).to eq 'Non-link 1'
      expect(browser.li(css: "li#non_link_1").text!).to eq 'Non-link 1'
    end

    it "reloads the cached document from after hooks" do
      expect(browser.driver).to receive(:page_source).exactly(3).times.and_return(browser.driver.page_source)

      expect(browser.li(id: "non_link_1").text!).to eq 'Non-link 1'
      browser.refresh
      expect(browser.li(id: /non_link_1/).text!).to eq 'Non-link 1'
      browser.li.click
      expect(browser.li(title: "This is not a link!").text!).to eq 'Non-link 1'
      browser.li.click
    end

    it "locates by sub-element" do
      navbar = browser.ul(id: 'navbar').tap { |el| el.exist? }
      expect(browser.driver).to_not receive(:find_element)
      expect(navbar.li(id: "non_link_1").text!).to eq "Non-link 1"
    end

  end
end
