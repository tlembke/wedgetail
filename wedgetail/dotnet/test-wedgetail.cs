using System;
using Wedgetail;

/* This is an example to test out the library.
  compile using csc test-wedgetail.cs -r:wedgetail.dll */
	
class Test
{
	static void Main(string[] args)
	{
		int i;
		Server s = new Server("https://dev.wedgetail.org.au/");
		s.SetCredentials("admin","passw0rd");
		//s.AddPatient("Bloggs-Smythe","Joseph","JJ",new DateTime(1967,4,12),"1","2 Foo Av","Fooville","1111","","passw1rd","2714AK");
		s.AddNarrative(
			"2714AK",
			"text/plain",
			"A narrative II",
			NarrativeType.ClinicalNote,
			"This is another note entered from C# interface" 
			);
		s.AddMedication("risperidone","3mg","nocte",28.0,5,"1489");
		s.AddMedication("diazepam","5mg","2 nocte",50,0,"");
		s.AddMedication("fluoxetine","20mg","3 mane",28,0,"");
		s.UploadMedications("2714AK");
		s.AddDiagnosis("schizophrenia",1997,DiagnosisStatus.Confirmed);
		s.AddDiagnosis("insomnia",2002,DiagnosisStatus.Suspected);
		s.AddDiagnosis("sore toenail",1984,DiagnosisStatus.Confirmed);
		s.UploadDiagnoses("2714AK");
		Patient [] plist = s.findPatients("Bloggs-Smythe","Jo",new DateTime(1800,1,1),null);
		Narrative [] nlist = s.listNarratives(plist[0].wedgetail,NarrativeType.Diagnosis);
		Diagnosis [] dlist = s.getDiagnoses(nlist[0].id);
		for (i=0;i<dlist.Length;i++)
		    Console.WriteLine("{0} {1} {2}",dlist[i].name,dlist[i].year,dlist[i].status);
		nlist = s.listNarratives(plist[0].wedgetail,NarrativeType.MedicationChart);
		Medication [] mlist = s.getMeds(nlist[0].id);
		foreach (Medication m in mlist)
		    Console.WriteLine("{0} {1} {2}",m.name,m.strength,m.instructions);
	}
}