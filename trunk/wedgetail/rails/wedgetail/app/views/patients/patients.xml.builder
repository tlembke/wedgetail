xml.instruct!

xml.patients{
  if @message
    xml.message(@message)
  end
  for patient in @patients
    xml.patient do
      xml.family_name(patient.family_name)
      xml.given_names(patient.given_names)
      xml.dob(patient.dob)
      xml.wedgetail(patient.wedgetail)
      xml.medicare(patient.medicare)
      xml.address_line(patient.address_line)
      xml.town(patient.town)
    end
  end
}