require File.dirname(__FILE__) + '/../test_helper'

class NarrativeTest < Test::Unit::TestCase
  fixtures :narratives,:codes,:users

  # Replace this with your real tests.
  def test_object_codes
    narr = narratives(:first)
    assert narr.clinical_objects == []
    narr = narratives(:second)
    objs = narr.clinical_objects(true)
    assert objs[0].name == "risperidone 2mg tab"
    assert objs[0].code_class == Drug
    assert objs[1].name == "yellow fever"
    assert objs[1].code_class == Diagnosis
  end


  def test_hl7
    narr = narratives(:first)
    hl7 = narr.make_outgoing_hl7
    hl7_2 = HL7::Message.parse(hl7.to_hl7)
    hl7_2.obx.value == "This is a narrative"
  end
end
