class OrderBookParser < Parser
  FRONTPAGEHEADER = %r|^\s+(1)$|
  LEFTFACINGHEADER = %r|^\s?(\d+)\s+Questions Book$|
  RIGHTFACINGHEADER = %r|^\s+Questions Book \s+(\d+)$|
  HOUSEHEADER = %r{^\s*(House of Commons|Lords)$}
  
  HEADER1 = %r|^\s*(Questions for Oral or Written Answer)\s*$|
  HEADER2 = %r{^\s*(beginning on [A-Z][a-z]+day \d+ [A-Z][a-z]+ \d{4})$}
  HEADER3 = %r|^\s*(\(the '?Questions Book'?\))$|
  
  PARTHEADER1 = %r{^\s*(Part 1: Written Questions for Answer on)$}
  PARTHEADER2 = %r|^\s*([A-Z][a-z]+day \d+ [A-Z][a-z]+ \d{4})$|
  
  INTROSTART = %r|^\s*\$\s+This paper contains only Written Questions for answer on the date of issue|
  INTROP2 = %r|^\s*For other Written Questions for answer on the date|
  INTROP3 = %r|^\s*For Written and Oral Questions for answer after the date|
  
  PAGEHEADING = %r|^\s*([A-Z]+DAY \d+ [A-Z]+)$|
  
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
      when FRONTPAGEHEADER
        @html += %Q|<section class="page" data-page="1">|
        
      when LEFTFACINGHEADER
        @current_column = $1
        if @in_amendment
          @html += "</p>\n    </section>"
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
        @html += %Q|\n</section>\n<section class="page" data-page="#{@current_column}">|
    
      when RIGHTFACINGHEADER
        @current_column = $1
        if @in_amendment
          @html += "</p>\n    </section>"
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
        @html += %Q|\n</section>\n<section class="page" data-page="#{@current_column}">|

      when HOUSEHEADER
        @html += %Q|\n  <h1 class="house">#{$1}</h1>\n|
        
      when HEADER1
        @html += %Q|  <h2 class="header">#{$1} |
        @html += %Q|<br />| unless @kindle_friendly
        
      when HEADER2
        @html += %Q|#{$1}|
        @html += %Q|<br />| unless @kindle_friendly
        
      when HEADER3
        @html += %Q|#{$1}</h2>\n|
      
      when PARTHEADER1
        @html += %Q|  <h2 class="header">#{$1} |
        @html += %Q|<br />| unless @kindle_friendly
          
      when PARTHEADER2
        @html += %Q|#{$1}</h2>\n|
      
      when INTROSTART
        @in_intro = true
        if @kindle_friendly
          @html += %Q|  <br /><section class="intro">\n   #{line.gsub("$", "&#x2605;")} |
        else
          @html += %Q|  <section class="intro">\n   <p>#{line.gsub("$", "&#x2605;")}<br />|
          @in_para = true
        end
        
      when INTROP2, INTROP3
        if @kindle_friendly
          @html += %Q|    <br /><br />\n    #{line}|
        else
          @html += %Q|    </p>\n    <p>#{line}<br />|
        end
          
      # when EDM_HEADER
      #   if @in_para
      #     @html += "</p>"
      #     @in_para = false
      #   end
      #   if @in_intro
      #     @html += "</section>"
      #     @in_intro = false
      #   end
      #   
      #   if @in_edm
      #     @html += "\n  </article>"
      #     init_vars()
      #   end
      #   
      #   @html += %Q|\n  <br /><br />| if @kindle_friendly
      #   @html += %Q|\n  <article class="edm">\n|
      #   @html += %Q|    <h4><span class="edm-number">#{$1}</span> <span class="edm-title">#{$2.strip}</span> <span class="edm-date">#{$3}</span></h4>|
      #   @in_edm = true
      #   
      # when EDM_HEADER_START
      #   @last_line = line.gsub("\n", "")
      #   @broken_header = true
      #   
      # when SPONSOR
      #   if @end_of_sponsors
      #     unless @in_signatories
      #       if @kindle_friendly
      #         @html += %Q|\n    <table class="signatures">|
      #       else
      #         @html += %Q|\n    <section class="signatures">|
      #       end
      #       @in_signatories = true
      #     end
      #     if @kindle_friendly
      #       @html += %Q|\n      <tr><td class="signature">#{$1}</td></tr>|
      #     else
      #       @html += %Q|\n      <span class="signature">#{$1}</span>|
      #     end
      #   else
      #     if @in_para
      #       unless @in_amendment
      #         @html += %Q|\n    <section class="amendment">|
      #         @in_amendment = true
      #       end
      #     end
      #     unless @in_sponsors
      #       if @kindle_friendly
      #         @html += %Q|\n    <table class="sponsors">|
      #       else
      #         @html += %Q|\n    <section class="sponsors">|
      #       end
      #       @in_sponsors = true
      #     end
      #     if @kindle_friendly
      #       @html += %Q|\n      <tr><td class="sponsor">#{$1}</td></tr>|
      #     else
      #       @html += %Q|\n      <span class="sponsor">#{$1}</span>|
      #     end
      #   end
      #   
      # when SUPPORTERS
      #   if @in_sponsors
      #     @in_sponsors = false
      #     @end_of_sponsors = true
      #     if @kindle_friendly
      #       @html += "\n    </table>"
      #     else
      #       @html += "\n    </section>"
      #     end
      #   end
      #   if @kindle_friendly
      #     @html += %Q|\n    <div width="100%" align="right" class="supporters">&#x2605; #{$1}</div>|
      #   else
      #     @html += %Q|<span class="supporters">&#x2605; #{$1}</span>|
      #   end
      #   
      # when SIGNATORY
      #   if @in_sponsors
      #     if @kindle_friendly
      #       @html += "\n    </table>"
      #     else
      #       @html += "\n    </section>"
      #     end
      #     @in_sponsors = false
      #   end
      #   unless @in_signatories
      #     if @kindle_friendly
      #       @html += %Q|\n    <table class="signatures">|
      #     else
      #       @html += %Q|\n    <section class="signatures">|
      #     end
      #     @in_signatories = true
      #     @end_of_sponsors = false
      #   end
      #   if @kindle_friendly
      #     @html += %Q|\n      <tr>|
      #     @html += %Q|\n      <td width="30%" class="signature">#{$1}</td>|
      #     @html += %Q|\n      <td width="30%" class="signature">#{$2}</td>| if $2
      #     @html += %Q|\n      <td width="30%" class="signature">#{$3}</td>| if $3
      #     @html += %Q|\n      </tr>|
      #   else
      #     @html += %Q|\n      <span class="signature">#{$1}</span>|
      #     @html += %Q|\n      <span class="signature">#{$2}</span>| if $2
      #     @html += %Q|\n      <span class="signature">#{$3}</span>| if $3
      #   end
      #         
      # when NAMESWITHDRAWN
      #   if @in_amendment
      #     @html += "</p>\n    </section>"
      #     @in_amendment = false
      #   end
      #   if @in_para
      #     @html += "</p>"
      #     @in_para = false
      #   end
      #   @html += "\n  </article>"
      #   @in_edm = false
      #   @in_names_withdrawn = true
      #   @html += %Q|  <br /><br />| if @kindle_friendly
      #   @html += %Q|  <h4>NAMES WITHDRAWN</h4>|
      #   
      else  
        if @broken_header
          @broken_header = false
          new_line = "#{@last_line}<br /> #{line.strip}"
          if new_line =~ EDM_HEADER
            if @in_amendment
              @html += "</p>\n    </section>"
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
            @html += %Q|    <h4><span class="edm-number">#{$1}</span> <span class="edm-title">#{$2}</span> <span class="edm-date">#{$3}</span></h4>|
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
              if @kindle_friendly
                @html += "\n    </table>"
              else
                @html += "\n    </section>"
              end
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