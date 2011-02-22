class EdmParser < Parser
  TITLEHEADER = %r|^(No\.\s*\d+)\s*(\d+)$|
  LEFTFACINGHEADER = %r|^\s?(\d+)\s+Notices of Motions: \d+ [A-Z][a-z]* \d{4}\s+No.\s?\d+$|
  RIGHTFACINGHEADER = %r|^\s?No.\s?\d+\s+Notices of Motions: \d+ [A-Z][a-z]* \d{4}\s+(\d+)$|
  HOUSEHEADER = %r{^\s*(House of Commons|Lords)$}
  DATEHEADER = %r|^\s*([A-Z][a-z]+day \d+ [A-Z][a-z]+ \d{4})$|
  HEADER1 = %r|^(Notices of Motions for which no days have been)$|
  HEADER2 = %r{^\s*(fixed)$}
  HEADER3 = %r|^\s*(\('?Early Day Motions'?\))$|
  INTROSTART = %r|^\s*\$\s+The figure following this symbol|
  INTROP2 = %r|^\s*After an Early Day Motion \(EDM\) has been|
  EDM_HEADER = %r|^\s*(\d+)\s+((?:[^\s]+\s)+)\s*(\d+:\d+:\d+)$|
  EDM_HEADER_START = %r|^\s*(\d+)\s+((?:[^\s]+\s)+)|
  SPONSOR = %r{^\s+((?:[A-Z][a-z]+\s)+(?:[A-Z]\.\s)*(?:Ma?c[A-Z]|O\'[A-Z]|[A-Z])[a-z]+(?:\-[A-Z][a-z]+)?(?: \[[A-Z]\])?)$}
  SIGNATORY = %r{^\s+((?:[A-Z][a-z]+\s)+(?:[A-Z]\.\s)*(?:Ma?c[A-Z]|[A-Z])[a-z]+(?:\-[A-Z][a-z]+)?)(?:\s+((?:[A-Z][a-z]+\s)+(?:[A-Z]\.\s)*(?:Ma?c[A-Z]|[A-Z])[a-z]+(?:\-[A-Z][a-z]+)?))?(?:\s+((?:[A-Z][a-z]+\s)+(?:[A-Z]\.\s)*(?:Ma?c[A-Z]|[A-Z])[a-z]+(?:\-[A-Z][a-z]+)?))?$}
  SUPPORTERS = %r|^\s+\$\s+(\d+)$|
  NAMESWITHDRAWN = %r|^\s+NAMES WITHDRAWN$|
  
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
    @in_amendment = false
  end
      
  def handle_txt_line line
    line = fix_misreads(line)
    
    case line
      when TITLEHEADER
        @doc_number = $1
        @start_column = $2
        @current_column = $2
        unless @kindle_friendly
          @html += %Q|<section class="page" data-column="#{@current_column}">|
        end
        
      when LEFTFACINGHEADER
        @current_column = $1
        if @in_amendment
          @html += "</p>\n    </section>"
          @in_para = false
          @in_amendment = false
        end
        if @in_para
          @html += "</p>"
          @in_para = false
        end
        if @in_edm
          @html += "\n  </article>"
          @in_edm = false
          init_vars()
        end
        unless @kindle_friendly
          @html += %Q|\n</section>\n<section class="page" data-column="#{@current_column}">|
        end
    
      when RIGHTFACINGHEADER
        @current_column = $1
        if @in_amendment
          @html += "</p>\n    </section>"
          @in_para = false
          @in_amendment = false
        end
        if @in_para
          @html += "</p>"
          @in_para = false
        end
        if @in_edm
          @html += "\n  </article>"
          @in_edm = false
          init_vars()
        end
        unless @kindle_friendly
          @html += %Q|\n</section>\n<section class="page" data-column="#{@current_column}">|
        end

      when HOUSEHEADER
        @html += %Q|\n  <h1 class="house">#{$1}</h1>\n|
        
      when DATEHEADER
        @html += %Q|  <h2 class="date">#{$1}</h2>\n|
        @date = $1
        
      when HEADER1
        @html += %Q|  <h3 class="header">#{$1} |
        @html += %Q|<br />| unless @kindle_friendly
        
      when HEADER2
        @html += %Q|fixed<br />|
        
      when HEADER3
        @html += %Q|#{$1}</h3>\n|
      
      when INTROSTART
        @in_intro = true
        if @kindle_friendly
          @html += %Q|  <br /><section class="intro">\n   #{line.gsub("$", "&#x2605;")} |
        else
          @html += %Q|  <section class="intro">\n   <p>#{line.gsub("$", "&#x2605;")}<br />|
          @in_para = true
        end
        
      when INTROP2
        if @kindle_friendly
          @html += %Q|    <br /><br />\n    #{line}|
        else
          @html += %Q|    </p>\n    <p>#{line}<br />|
        end
          
      when EDM_HEADER
        if @in_para
          @html += "</p>"
          @in_para = false
        end
        if @in_intro
          @html += "</section>"
          @in_intro = false
        end
        
        if @in_edm
          @html += "\n  </article>"
          init_vars()
        end
        
        @html += %Q|\n  <br /><br />| if @kindle_friendly
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
          if @in_para
            unless @in_amendment
              @html += %Q|\n    <section class="amendment">|
              @in_amendment = true
            end
          end
          unless @in_sponsors
            @html += %Q|\n    <section class="sponsors">|
            @html += "<br>" if @kindle_friendly
            @in_sponsors = true
          end
          @html += %Q|\n      <span class="sponsor">#{$1}</span>|
          @html += "<br>" if @kindle_friendly
        end
        
      when SUPPORTERS
        if @in_sponsors
          @in_sponsors = false
          @end_of_sponsors = true
          @html += "\n    </section>"
        end
        if @kindle_friendly
          @html += %Q|<div class="supporters" width="100%" style="display: block; text-align: right">&#x2605; #{$1}</div>|
        else
          @html += %Q|<span class="supporters">&#x2605; #{$1}</span>|
        end
        
      when SIGNATORY
        if @in_sponsors
          @html += "\n    </section>"
          @in_sponsors = false
        end
        unless @in_signatories
          @html += %Q|\n    <section class="signatures">|
          @in_signatories = true
          @end_of_sponsors = false
        end
        @html += %Q|\n      <span class="signature">#{$1}</span>|
        @html += "<br>" if @kindle_friendly
        if $2
          @html += %Q|\n      <span class="signature">#{$2}</span>|
          @html += "<br>" if @kindle_friendly
        end
        if $3
          @html += %Q|\n      <span class="signature">#{$3}</span>|
          @html += "<br>" if @kindle_friendly
        end
              
      when NAMESWITHDRAWN
        if @in_amendment
          @html += "</p>\n    </section>"
          @in_para = false
          @in_amendment = false
        end
        if @in_para
          @html += "</p>"
          @in_para = false
        end
        @html += "\n  </article>"
        @in_edm = false
        @in_names_withdrawn = true
        @html += %Q|  <br /><br />| if @kindle_friendly
        @html += %Q|  <h4>NAMES WITHDRAWN</h4>|
        
      else  
        if @broken_header
          @broken_header = false
          new_line = "#{@last_line}<br /> #{line.strip}"
          if new_line =~ EDM_HEADER
            number = $1
            title = $2
            date = $3
            if @in_amendment
              @html += "</p>\n    </section>"
              @in_para = false
              @in_amendment = false
            end
            if @in_para
              @html += "</p>"
              @in_para = false
            end

            if @in_edm
              @html += "\n  </article>"
            end
            init_vars()
            
            @html += %Q|\n  <br /><br />| if @kindle_friendly
            @html.gsub!("£", "&#163;") if @kindle_friendly
            @html += %Q|\n  <article class="edm">\n|
            @html += %Q|    <h4><span class="edm-number">#{number}</span> <span class="edm-title">#{title}</span> <span class="edm-date">#{date}</span></h4>|
            @in_edm = true
          else
            @html += "#{@last_line.strip} "
            @html += "<br />" unless @kindle_friendly
            if line.strip == ""
              if @in_para
                @html += "</p>"
                @in_para = false
              end
            else
              @html += "#{line.strip} "
              @html += "<br />" unless @kindle_friendly
            end
          end
        else
          if @in_signatories
            unless line.strip == ""
              @html += "\n    </section>"
              @in_signatories = false
              @html += %Q|\n    <p class="motion">#{line.strip} |
              @html += "<br />" unless @kindle_friendly
              @in_para = true
              @end_of_sponsors = false
            end
          elsif @in_sponsors
            unless line.strip == ""
              @html += "\n    </section>"
              @in_sponsors = false
              @html += %Q|\n    <p class="motion">#{line.strip} |
              @html += "<br />" unless @kindle_friendly
              @in_para = true
              @end_of_sponsors = false
            end
          elsif @end_of_sponsors
            unless line.strip == ""
              @html += %Q|\n    <p class="motion">#{line.strip} |
              @html += "<br />" unless @kindle_friendly
              @in_para = true
              @end_of_sponsors = false
            end
          else
            if line.strip == ""
              if @in_para
                @html += "</p>"
                @in_para = false
              end
            else
              if @kindle_friendly and line =~ /^\s*\[[A-Z]\]/
                @html += "<br />"
              end
              @html += "#{line.strip} "
              @html += "<br />" unless @kindle_friendly
            end
          end
        end  
        
    end
    
  end
end