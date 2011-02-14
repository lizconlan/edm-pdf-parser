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
  
  INTROSTART = %r|^\s*This paper contains only Written Questions for answer on the date of issue|
  INTROP2 = %r|^\s*For other Written Questions for answer on the date|
  INTROP3 = %r|^\s*For Written and Oral Questions for answer after the date|
  
  PAGEHEADING = %r|^\s*([A-Z]+DAY \d+ [A-Z]+(?: \d{4})?)$|
  
  QUESTIONSTART = %r|^\s*(\d+)\s*((?:[A-Z][^\(]*))\(([^\)]*)\):\s*(.*)|
  QUESTIONNUMBER = %r|(\(\d+\))\s*$|
  
  def init_vars
    @in_question = false
    @last_line = ""
    @in_intro = false
    @in_para = false
    @current_page = 0
    @current_order_num = 0
    @transferred = false
  end
  
  def parse_text_file input_file, type
    output = super(input_file, type)
    output.sub(%Q|<section class="page" data-page="#{@current_page}"|, %Q|<section class="page last" data-page="#{@current_page}"|)
  end
      
  def handle_txt_line line
    line = fix_misreads(line)
    
    case line
      when FRONTPAGEHEADER
        @html += %Q|<section class="page" data-page="1">|
      
      when PAGEHEADING
        #skip the line
      
      when LEFTFACINGHEADER
        @current_page = $1
        if @in_para
          @html += "</p>"
          @in_para = false
        end
        if @in_question
          @html += "\n  </article>"
          @in_question = false
          init_vars()
        end
        @html += %Q|\n</section>\n<section class="page" data-page="#{@current_page}">|
    
      when RIGHTFACINGHEADER
        @current_page = $1
        if @in_para
          @html += "</p>"
          @in_para = false
        end
        if @in_question
          @html += "\n  </article>"
          @in_question = false
          init_vars()
        end
        @html += %Q|\n</section>\n<section class="page" data-page="#{@current_page}">|

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
          @html += %Q|    |
          @html += %Q|</p>| if @in_para  
          @html += %Q|\n    <p>#{line}<br />|
          @in_para  = true
        end
          
      when QUESTIONSTART
        if @in_para
          @html += "</p>"
          @in_para = false
        end
        if @in_intro
          @html += "</section>"
          @in_intro = false
        end
        
        if @in_question
          @html += "\n  </article>"
          init_vars()
        end
        
        @html += %Q|\n  <br /><br />| if @kindle_friendly
        @html += %Q|\n  <article class="question">\n|
        
        @html += %Q|      <table class="question">\n|
        @html += %Q|        <tr>\n|
        @html += %Q|          <td class="col1"><span class="order_number">#{$1}</span></td>\n|
        @html += %Q|          <td class="col2">\n            <div>\n              <span class="member">#{$2}</span>\n|
        @html += %Q|              (<span class="constituency">#{$3}</span>): \n|
        @html += %Q|              <span class="question">#{$4}|
        @current_order_num = $1
        @in_question = true
        
      when QUESTIONNUMBER
        question_num = $1
        rest_of_question = line.gsub(question_num, "").strip
        if rest_of_question and rest_of_question =~ /\[Transferred\]\s*$/
          rest_of_question = rest_of_question.gsub("[Transferred]", "")
          @transferred = true
        end
        unless rest_of_question == ""
          @html += "#{rest_of_question.rstrip}<br />"
        end
        @html += %Q|</span>\n|
        @html += %Q|              <div class="footnotes">\n|
        if @transferred
          @html += %Q|              <span class="transferred">[Transferred]</span>\n|
          @transferred = false
        end
        @html += %Q|                <span class="question-number">#{question_num}</span>\n|
        @html += %Q|               </div>\n|
        @html += %Q|             </div>\n|
        @html += %Q|          </td>\n|
        @html += %Q|      </tr>\n|
        @html += %Q|    </table>|
        @html += %Q|  </article>|
        @in_question = false
      else  
        if line.strip == ""
          if @in_para
            @html += "</p>"
            @in_para = false
          end
        else
          if @in_question
            if line =~ /^\s*(N)/
              @html.gsub!(%Q|<span class="order_number">#{@current_order_num}</span>|, %Q|<span class="order_number">#{@current_order_num}</span><span class="marker">N</span>|)
              line = line.sub(/^\s*(N)/, "")
            end
          end
          if @kindle_friendly and line =~ /^\s*\[[A-Z]\]/
            @html += "<br />"
          end
          @html += "                #{line.strip} \n"
        end
      end
    
  end
end