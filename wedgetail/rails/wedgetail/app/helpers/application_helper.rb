# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def displayComment(comment)
    if comment
      if comment.starts_with?("{\\rtf")
        comment=MessageProcessor.abiwordise("doc.rtf",comment,false)
        comment=comment.gsub("background:#000000","background:#FFFFFF")
        comment=comment.gsub("color:#ffffff","color:#000000")
      end
    end
    return comment 
  end

  def show_button(icon_name,link_path="",link_text='',tooltip_title="",tooltip_text="",icon_size='medium',icon_set='tango',tooltip_extra="")
    @theme=Theme.find_by_css(@chosen_theme)
    text_part1=""
    if @theme.button==0
      return show_icon(icon_name,link_path,link_text,tooltip_title,tooltip_text,icon_size,icon_set,tooltip_extra)
    else
      text_part1="<a class=side-button href=#{link_path} id=#{icon_name}><span>#{link_text}</span></a>"
      text_part2=""
      ttt_text=""
      if (tooltip_text!="" or tooltip_title!="")
        ttt_text=",{"
        if (tooltip_title!="")
          ttt_text+="title:'"+tooltip_title+"', "
        end
        ttt_text+=tooltip_extra+"}"
        text_part2="\n<script>new Tip(\""+icon_name+"\",\""+tooltip_text+"\""+ttt_text+");</script>\n"
      end
   
      return text_part1+text_part2
    end
  end

  def show_buttonOld(icon_name,link_path="",link_text='',tooltip_title="",tooltip_text="",icon_size='medium',icon_set='tango',tooltip_extra="")
    @theme=Theme.find_by_css(@chosen_theme)
    text_part1=""
    if @theme.button==0
      text_part1=image_tag("icons/"+icon_set+"/"+icon_size+"/"+icon_name+".png",:valign=>"middle",:border=>"0")
      text_part1="<span id=\'"+icon_name+"\'>"+text_part1+"</span>"
      if link_text!=""
        text_part1+=link_text
      end
      if link_path!=""
        text_part1=link_to(text_part1,link_path)
      end
    else
      text_part1="<a class=side-button href=#{link_path} id=#{icon_name}><span>#{link_text}</span></a>"
    end
    

    
    
    text_part2=""
    ttt_text=""

    if (tooltip_text!="" or tooltip_title!="")
      ttt_text=",{"
      if (tooltip_title!="")
        ttt_text+="title:'"+tooltip_title+"', "
      end

      ttt_text+=tooltip_extra+"}"
      text_part2="\n<script>new Tip(\""+icon_name+"\",\""+tooltip_text+"\""+ttt_text+");</script>\n"
    end
    
    return text_part1+text_part2
  end

  
  
  def show_icon(icon_name,link_path="",link_text='',tooltip_title="",tooltip_text="",icon_size='medium',icon_set='tango',tooltip_extra="")
    
    text_part1=image_tag("icons/"+icon_set+"/"+icon_size+"/"+icon_name+".png",:valign=>"middle",:border=>"0")
    if link_text!=""
      text_part1+=link_text
    end
    if link_path!=""
      text_part1=link_to(text_part1,link_path)
    end
    
    text_part1="<span id=\'"+icon_name+"\'>"+text_part1+"</span>"
    text_part2=""
    ttt_text=""

    if (tooltip_text!="" or tooltip_title!="")
      ttt_text=",{"
      if (tooltip_title!="")
        ttt_text+="title:'"+tooltip_title+"', "
      end

      ttt_text+=tooltip_extra+"}"
      text_part2="\n<script>new Tip(\""+icon_name+"\",\""+tooltip_text+"\""+ttt_text+");</script>\n"
    end
    return text_part1+text_part2
  end
  
  def claim_date(claim)
    unless claim.date
      return "Not recorded"
    else
      return claim.date.strftime("%d/%m/%y")
    end

      
  end
  
  def date_format1(time_str)
    if time_str=="" or time_str==0 or time_str ==false or time_str=="0000-00-00"
      return "Not recorded"
    else
      time_str.strftime("%d/%m/%y")
    end
  end
 
  def showCount(total,start,limit)
    text=''
    if total.to_i>0
      total=total.to_i
      start=start.to_i
      limit=limit.to_i
      last=start+limit
      last=start+limit if limit-start>total
      last=total if total<last
      the_start=start+1
      text="Showing "+the_start.to_s+" to "+last.to_s+" of "+total.to_s
    end
  end
  
  def expandable_section(display_name,start='show')
      name=display_name.downcase.gsub(" ","_")
      
      if start=='hide'
        display2='none'
        display1='inline'
      else
        display1='none'
        display2='inline'       
      end
      
      text="<span class='sectionhead'>#{display_name}</span>\r"
      #text+="<span id='#{name}_show' class='expand' style='display:#{display1}'>"
      #text+="<a href='#' onclick=\"$('#{name}','#{name}_show','#{name}_hide').invoke('toggle');return false;\">(Show)</a></span>" 
      #text+="<span id='#{name}_hide' class='expand' style='display:#{display2}'>"
      #text+="<a href='#' onclick=\"$('#{name}','#{name}_show','#{name}_hide').invoke('toggle');return false;\">(Hide)</a></span>"
      text+="<a href='#' id='#{name}_show' class='expand' style='display:#{display1}' onclick=\"$('#{name}','#{name}_show','#{name}_hide').invoke('toggle');return false;\">(Show)</a>" 
      text+="<a href='#' id='#{name}_hide' class='expand' style='display:#{display2}' onclick=\"$('#{name}','#{name}_show','#{name}_hide').invoke('toggle');return false;\">(Hide)</a></span>"

  end
  
  def pdf_image_tag(image, options = {})
    options[:src] = File.expand_path(RAILS_ROOT) + '/public/images/' + image
    tag(:img, options)
  end
  
  def pdf_stylesheet_tag(css, options = {})
    options[:src] = File.expand_path(RAILS_ROOT) + '/public/stylesheets/' + css +".css"
    tag(:css, options)
  end
end
