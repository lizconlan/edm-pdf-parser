require 'tempfile'

class Parser
  TITLEHEADER = %r|^(No\.\s*\d+)\s*(\d+)$|
  LEFTFACINGHEADER = %r|^\s?(\d+)\s+Notices of Motions: \d+ [A-Z][a-z]* \d{4}\s+No.\s?\d+$|
  RIGHTFACINGHEADER = %r|^\s?No.\s?\d+\s+Notices of Motions: \d+ [A-Z][a-z]* \d{4}\s+(\d+)$|
  HOUSEHEADER = %r{^\s*(House of Commons|Lords)$}
  DATEHEADER = %r|^\s*([A-Z][a-z]+day \d+ [A-Z][a-z]+ \d{4})$|
  HEADER1 = %r|^(Notices of Motions for which no days have been)$|
  HEADER2 = %r{^\s*(fixed)$}
  HEADER3 = %r|^\s*(\(Early Day Motions\))$|
  INTROSTART = %r|^\s*\$\s+The figure following this symbol|
  EDM_HEADER = %r|^\s*(\d+)\s+((?:[^\s]+\s)+)\s+(\d+:\d+:\d+)$|
  EDM_HEADER_START = %r|^\s*(\d+)\s+((?:[^\s]+\s)+)|
  SPONSOR = %r{^\s+((?:[A-Z][a-z]+\s)+(?:Ma?c[A-Z]|O\'[A-Z]|[A-Z])[a-z]+(?:\-[A-Z][a-z]+)?(?: \[[A-Z]\])?)$}
  SIGNATORY = %r{^\s+((?:[A-Z][a-z]+\s)+(?:Ma?c[A-Z]|[A-Z])[a-z]+(?:\-[A-Z][a-z]+)?)(?:\s+((?:[A-Z][a-z]+\s)+(?:Ma?c[A-Z]|[A-Z])[a-z]+(?:\-[A-Z][a-z]+)?))?(?:\s+((?:[A-Z][a-z]+\s)+(?:Ma?c[A-Z]|[A-Z])[a-z]+(?:\-[A-Z][a-z]+)?))?$}
  SUPPORTERS = %r|^\s+\$\s+(\d+)$|
  MOTIONSTART = %r|^\s+That .*$|
  NAMESWITHDRAWN = %r|^\s+NAMES WITHDRAWN$|
  
  def pdf_to_text pdf_file
    pdf_txt_file = Tempfile.new("#{pdf_file.gsub('/','_')}.txt", "./")
    pdf_txt_file.close # was open

    Kernel.system %Q|pdftotext -layout -enc UTF-8 "#{pdf_file}" "#{pdf_txt_file.path}"|

    pdf_txt_file
  end
  
  def parse pdf_file_path, output_path
    text_file = pdf_to_text(pdf_file_path)
    html = parse_text_file(text_file.path)
    text_file.delete
    
    File.open(output_path, 'w') { |f| f.write(html) }
  end  

  def parse_text_file input_file
    @html = ""
    @doc_number = ""
    @start_column = ""
    @current_column = ""
    
    init_vars()
    
    doc_text = File.open(input_file)
    doc_text.each do |line|
      handle_txt_line(line)
    end
    
    @html += "\n  </section>"
    @html.gsub("<br /></p>", "</p>").gsub(" </p>", "</p>")
  end
  
  def init_vars
    @in_edm = false
    @end_of_sponsors = false
    @in_signatories = false
    @in_sponsors = false
    @broken_header = false
    @last_line = ""
    @in_names_withdrawn = false
    @in_intro = false
    @in_para = false
  end
      
  def handle_txt_line line
    line.gsub!("ﬁ", "fi")
    line.gsub!("’", "'")
    
    case line
      when TITLEHEADER
        @doc_number = $1
        @start_column = $2
        @current_column = $2
        @html += %Q|<section class="page" data-column="#{@current_column}">|
        
      when LEFTFACINGHEADER
        @current_column = $1
        if @in_para
          @html += "</p>"
          @in_para = false
        end
        if @in_edm
          @html += "\n  </article>"
          @in_edm = false
          init_vars()
        end
        @html += %Q|\n</section>\n<section class="page" data-column="#{@current_column}">|
    
      when RIGHTFACINGHEADER
        @current_column = $1
        if @in_para
          @html += "</p>"
          @in_para = false
        end
        if @in_edm
          @html += "\n  </article>"
          @in_edm = false
          init_vars()
        end
        @html += %Q|\n</section>\n<section class="page" data-column="#{@current_column}">|

      when HOUSEHEADER
        @html += %Q|\n  <h1 class="house">#{$1}</h1>\n|
        
      when DATEHEADER
        @html += %Q|  <h2 class="date">#{$1}</h2>\n|
        
      when HEADER1
        @html += %Q|  <h3 class="header">#{$1}<br />|
        
      when HEADER2
        @html += %Q|fixed<br />|
        
      when HEADER3
        @html += %Q|#{$1}</h3>\n|
      
      when INTROSTART
        @in_intro = true
        @html += %Q|  <p class="intro">#{line.gsub("$", "&#x2605;")}<br />|
        @in_para = true
          
      when EDM_HEADER
        if @in_para
          @html += "</p>"
          @in_para = false
        end
        
        if @in_edm
          @html += "\n  </article>"
          init_vars()
        end
        @html += %Q|\n  <article class="edm">\n|
        @html += %Q|    <h4><span class="edm-number">#{$1}</span> <span class="edm-title">#{$2.strip}</span> <span class="edm-date">#{$3}</span></h4>|
        @in_edm = true
        
      when EDM_HEADER_START
        @last_line = line.gsub("\n", "")
        @broken_header = true
        
      when SPONSOR
        if @end_of_sponsors
          unless @in_signatories
            @html += %Q|\n    <section class="signatures">|
            @in_signatories = true
          end
          @html += %Q|\n      <span class="signature">#{$1}</span>|
        else
          unless @in_sponsors
            @html += %Q|\n    <section class="sponsors">|
            @in_sponsors = true
          end
          @html += %Q|\n      <span class="sponsor">#{$1}</span>|
        end
        
      when SUPPORTERS
        if @in_sponsors
          @in_sponsors = false
          @end_of_sponsors = true
          @html += "\n    </section>"
        end
        @html += %Q|\n    <span class="supporters">&#x2605; #{$1}</span>|
        
      when SIGNATORY
        if @in_sponsors
          @html += "\n    </section>"
          @in_sponsors = false
        end
        unless @in_signatories
          @html += %Q|\n    <section class="signatures">|
          @in_signatories = true
        end
        @html += %Q|\n      <span class="signature">#{$1}</span>|
        @html += %Q|\n      <span class="signature">#{$2}</span>| if $2
        @html += %Q|\n      <span class="signature">#{$3}</span>| if $3
        
      when MOTIONSTART
        if @in_signatories
          @html += "\n    </section>"
          @in_signatories = false
        end
        if @in_sponsors
          @html += "\n    </section>"
          @in_sponsors = false
        end
        @html += %Q|\n    <p class="motion">#{line.strip} <br />|
        @in_para = true
      
      when NAMESWITHDRAWN
        if @in_para
          @html += "</p>"
          @in_para = false
        end
        @html += "\n  </article>"
        @in_edm = false
        @in_names_withdrawn = true
        @html += %Q|  <h4>NAMES WITHDRAWN</h4>|
        
      else
        if @broken_header
          @broken_header = false
          new_line = "#{@last_line}<br /> #{line.strip}"
          if new_line =~ EDM_HEADER
            if @in_para
              @html += "</p>"
              @in_para = false
            end

            if @in_edm
              @html += "\n  </article>"
            end
            init_vars()
            
            @html += %Q|\n  <article class="edm">\n|
            @html += %Q|    <h4><span class="edm-number">#{$1}</span> <span class="edm-title">#{$2}</span> <span class="edm-date">#{$3}</span></h4>|
            @in_edm = true
          else
            @html += "#{@last_line.strip} <br />"
            if line.strip == ""
              if @in_para
                @html += "</p>"
                @in_para = false
              end
            else
              @html += "#{line.strip} <br />"
            end
          end
        else
          if line.strip == ""
            if @in_para
              @html += "</p>"
              @in_para = false
            end
          else
            @html += "#{line.strip} <br />"
          end
        end  
        
    end
    
  end
end