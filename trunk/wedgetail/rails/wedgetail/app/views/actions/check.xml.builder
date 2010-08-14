xml.instruct!

xml.results{
  for @next_result in @return_list
    xml.result do
      xml.request_set(@next_result[:request_set])
      xml.identifier(@next_result[:identifier])
      xml.viewed(@next_result[:viewed])
    end
  end
}