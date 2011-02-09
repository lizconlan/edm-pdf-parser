require 'rake'

require 'rubygems'

require 'models/parser'
require 'models/edm_parser'

desc "Convert PDF to web-ready HTML"
task :pdf_to_html do
  pdf_file = ENV['pdf']
  html = ENV['output']
  
  if pdf_file and html
    p = Parser.new()
    p.parse pdf_file, html
  else
    puts 'USAGE: rake pdf_to_html pdf=pdfs/test.pdf output=html/output.html'
  end
end

desc "Convert PDF to Kindle-ready HTML"
task :pdf_to_kindle_html do
  pdf_file = ENV['pdf']
  html = ENV['output']
  
  if pdf_file and html
    p = Parser.new(true)
    p.parse pdf_file, html
  else
    puts 'USAGE: rake pdf_to_kindle_html pdf=pdfs/test.pdf output=html/output.html'
  end
end

desc "Convert PDF to MobiPocket file"
task :pdf_to_mobi do
  pdf_file = ENV['pdf']
  mobi = ENV['output']
  type = ENV['type']
  
  if pdf_file and mobi and type
    html = mobi.gsub(".mobi", ".html")
    case type.downcase
      when "edm"
        p = EdmParser.new(true)
      when "orderbook"
        p = EdmParser.new(true)
      else
        raise "unrecognised type"
    end
    p.parse pdf_file, html
    `kindlegen #{html}`    
    `mv #{mobi} #{mobi.gsub("/html/", "/mobi/")}`
  else
    puts 'USAGE: rake pdf_to_mobi pdf=pdfs/test.pdf output=html/output.mobi type=edm'
  end
end