xml.instruct!
if @message
  xml.message(@message)
end
if @narratives.length>0
  xml.narratives{
    for narrative in @narratives
      xml.narrative do
        xml.wedgetail(narrative.wedgetail)
        xml.narrative_type_id(narrative.narrative_type_id)
        xml.title(narrative.title)
        xml.content(narrative.content)
        xml.content_type(narrative.content_type)
        xml.narrative_date(narrative.narrative_date)
      end
    end
  }
end
