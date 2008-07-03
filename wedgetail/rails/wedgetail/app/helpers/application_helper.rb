# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
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
 
end
