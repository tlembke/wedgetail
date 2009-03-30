xml.instruct!
xml.patients{
  for patient in @patients
    xml.patient do
      xml.family_name(patient.family_name)
      xml.given_names(patient.given_names)
      xml.dob(patient.dob)
      xml.wedgetail(patient.wedgetail)
    end
  end
}