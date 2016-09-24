require_relative 'common'
require 'nokogiri'
require 'excon'
require 'excon'
require 'zlib'
require 'fileutils'
require 'ostruct'
require 'yaml'

module TheNameMeaning
  rootdir = File.expand_path('../tmp', __dir__)
  Config = ExUtils::Configuration.new(File.expand_path('config.yml', rootdir), {
    rootpath: File.join(rootdir, 'thenamemeaning')
  })

  FileUtils.mkdir_p Config.get.rootpath

  class Api
    def initialize
      @rooturl = "http://www.thenamemeaning.com"

      @conn = Excon.new(@rooturl,
        headers: {
          'Host' => URI(@rooturl).host,
          'Connection' => 'keep-alive',
          'Accept' => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
          'Accept-Language' => 'en-US,en;q=0.8,ja;q=0.6',
          'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36'
        },
        excepts: [200, 301, 302],
        middlewares: Excon.defaults[:middlewares] + [Excon::Middleware::RedirectFollower]
      )
    end

    def next_valid_element(str)
      nxt = str.next
      if nxt.name == 'text'
        if nxt.text.strip.empty?
          nxt = next_valid_element(nxt)
        end
      end
      nxt
    end

    def collect_elements(str)
      nxt = next_valid_element(str)
      content = []
      case nxt.name
      when 'text'
        content << nxt.text
      when 'ul', 'ol'
        content.concat nxt.css('li').map(&:text)
      else
        puts "Unhandled node: #{nxt}"
      end
      [str.text, content]
    end

    def clear_empty_elements(root)
      root.elements.each do |node|
        if Nokogiri::XML::Text === node
          node.remove if node.text.strip.empty?
        else
          clear_empty_elements(node)
        end
      end
    end

    def get_page(name)
      filename = File.join(Config.get.rootpath, "#{name.downcase}.html")
      unless File.exist?(filename)
        request = @conn.get(path: "/#{name}/")
        File.write(filename, request.body)
      end
      File.read(filename)
    end

    def find_name(name)
      root = Nokogiri::HTML(get_page(name))
      root.css('head').remove
      root.css('script').remove
      root.css('style').remove
      root.css('br').remove
      clear_empty_elements(root)
      root.elements.each do |node|
        if Nokogiri::XML::Text === node
          node.remove if node.text.strip.empty?
        end
      end
      data = []
      root.css('.post-content').each do |node|
        #p node
        node.css('strong').each do |str|
          data << collect_elements(str)
        end
        node.css('> div b').each do |d|
          data << [d.text, d.parent.elements.map(&:text)]
        end
      end
      root.css("#content > strong").each do |str|
        data << [str.text, [str.next.text]]
      end
      data.each do |pairs|
        pairs[0] = pairs[0].strip
        pairs[1] = pairs[1].map { |d| d.strip }.reject { |s| s == ',' }
      end
    end
  end

  def self.instance
    @instance ||= Api.new
  end

  def self.find_name(name)
    sleep 1.0 # requests are delayed
    instance.find_name(name)
  end
end

p TheNameMeaning.find_name('baron')
p TheNameMeaning.find_name('elli')
p TheNameMeaning.find_name('chika')
