require 'tempfile'

class Parser
  def initialize(kindle_friendly=false)
    @kindle_friendly = kindle_friendly
  end
  
  def pdf_to_text pdf_file
    pdf_txt_file = Tempfile.new("#{pdf_file.gsub('/','_')}.txt", "./")
    pdf_txt_file.close # was open

    Kernel.system %Q|pdftotext -layout -enc UTF-8 "#{pdf_file}" "#{pdf_txt_file.path}"|

    pdf_txt_file
  end
  
  def parse pdf_file_path, output_path, type="edm"
    text_file = pdf_to_text(pdf_file_path)
    html = parse_text_file(text_file.path, type)
    text_file.delete
    
    File.open(output_path, 'w') { |f| f.write(html) }
  end  

  def parse_text_file input_file, type
    @html = ""
    @doc_number = ""
    @start_column = ""
    @current_column = ""
    @date = ""
    
    init_vars()
    
    doc_text = File.open(input_file)
    doc_text.each do |line|
      handle_txt_line(line)
    end
    
    case type
      when "edm"
        title = "EDMs"
      when "orderbook"
        title = "Order Book"
    end
    
    @html_head = %Q|<!DOCTYPE html>\n<html lang="en-GB">\n<head>\n  <title>#{title} #{@date}</title>\n  <meta charset="utf-8" />|
    unless @kindle_friendly
      @html_head += %Q|\n  <link rel="stylesheet" type="text/css" href="styles.css" media="screen"/>|
      @html_head += %Q|\n  <link rel="stylesheet" type="text/css" href="print.css" media="print"/>|
    end
    @html_head += %Q|\n</head>\n<body>\n|

    @html += "\n</section>" unless @kindle_friendly
    
    "#{@html_head}#{@html.gsub("<br /></p>", "</p>").gsub(" </p>", "</p>")}\n</body>\n</html>"
  end

  def fix_misreads(text)
    text = text.gsub("ﬁ", "fi")
    text = text.gsub("ﬂ", "fl")
    text = text.gsub("’", "'")
    text = text.gsub("‘", "'")
    text
  end
end