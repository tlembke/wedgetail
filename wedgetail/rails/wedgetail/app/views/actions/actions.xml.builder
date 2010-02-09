xml.instruct!
xml.errors{
  for error in @errors
    xml.error(error)
  end
}
