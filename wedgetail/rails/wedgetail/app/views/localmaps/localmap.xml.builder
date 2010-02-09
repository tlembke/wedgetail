xml.instruct!
xml.mapResult{
  xml.message(@message)
  if @localmap
    xml.localmap{
      xml.localID(@localmap.localID)
      xml.wedgetail(@localmap.wedgetail)
    }
  end
}
