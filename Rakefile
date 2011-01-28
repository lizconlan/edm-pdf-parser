require 'rake'

require 'rubygems'
require 'lib/parser'

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
  
  if pdf_file and mobi
    html = mobi.gsub(".mobi", ".html")
    p = Parser.new(true)
    p.parse pdf_file, html
    `kindlegen #{html}`    
    `mv #{mobi} #{mobi.gsub("/html/", "/mobi/")}`
  else
    puts 'USAGE: rake pdf_to_mobi pdf=pdfs/test.pdf output=html/output.mobi'
  end
end