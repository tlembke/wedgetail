/*
  Wedgetail C# interface module
  Copyright (C) 2009,2010 Ian Haywood
  Some code contributed by Anton Knieriemen from the DCP project 
  compile using: csc wedgetail.cs -t:library -r:System.Web


    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/



using System;
using System.Text;
using System.Web;
using System.IO;
using System.Net;
using System.Reflection;

/// <summary>The Wedgetail interface module</summary>
namespace Wedgetail
{
  
  
  /// <summary>Types of narrative</summary>
  public enum NarrativeType
  {
    HealthSummary = 1, 
    MedicationChart = 2, 
    DischargeSummary = 3, 
    ClinicalNote = 4,
    Allergies = 5, 
    Scratchpad = 6,
    Results = 7, 
    Letter = 8, 
    Immunisations = 9, 
    Form = 10,
    Prescription = 11, 
    Diagnosis = 12, 
    CarePlan = 13
  }
  
  /// <summary>Levels of certainty for a diagnosis</summary>
  public enum DiagnosisStatus
  {
    Confirmed = 1,
    Probable = 2,
    Suspected = 3,
    Disproved = 4
  }
  
  
  public class Patient
  {
    public string wedgetail;
    public string family_name; 
    public string given_names; 
    public string known_as;
    public DateTime dob;
    public string gender;
    public string address_line;
    public string town;
    public string postcode;
    public string medicare;
  }


  public class Medication
  {	
    public string name; 
    public string strength; 
    public string instructions;
    public float quantity;
    public int repeats;
    public string authority;
  }


  public class Narrative
  {
    public int id;
    public NarrativeType clinical_type;    
    public string title;    
    public string mime;
    public DateTime created_at;
  }


  public class Diagnosis
  {
    public string name;
    public int year;
    public DiagnosisStatus status;
  }



  /// <summary>Represents the connection to a wedgetail server</summary>
  public class Server
  {
    
    /// <summary>Connect to the default server, currently
    /// https://dev.wedgetail.org.au/</summary>
    public Server():this("https://dev.wedgetail.org.au/")
      {  }
    
    /// <summary> connect to a named server</summary>
    /// <param name="url">The URL stem, must have 'https' and a final 
    //// slash</param> 
    public Server(string url)
    {
      host = url;
      firstParam = true;
      postString = new StringBuilder();
      yamlString = new StringBuilder();
    }
    
    /// <summary>set login details</summary>
    /// <param name="username2">The username</param>
    /// <param name="password2">The password</param>
    public void SetCredentials(string username2, string password2)
    {
      username = username2;
      password = password2;
    }
    
    
    /// <summary>Add a new patient</summary>
    public void AddPatient(
			   string family_name, 
			   string given_names, 
			   string known_as,
			   DateTime dob,
			   string gender,
			   string address_line,
			   string town,
			   string postcode,
			   string medicare,
			   string password,
			   string local_id)
    {
      AddParam("patient[family_name]",family_name);
      AddParam("patient[given_names]",given_names);
      AddParam("patient[known_as]",known_as);
      AddParam("patient[dob(3i)]",Convert.ToString(dob.Day));
      AddParam("patient[dob(2i)]",Convert.ToString(dob.Month));
      AddParam("patient[dob(1i)]",Convert.ToString(dob.Year));
      AddParam("patient[sex]",gender);
      AddParam("patient[address_line]",address_line);
      AddParam("patient[town]",town);
      AddParam("patient[postcode]",postcode);
      AddParam("patient[password]",password);
      AddParam("patient[localID]",local_id);
      postRequest("patients.txt");
    }
    
    /// <summary>Add an arbitrary narrative object</summary>
    /// <param name="local_id">The local ID as passed to AddPatient.
    /// must be unique across all patients at the local system,
    /// </param>
    /// <param name="mime">The MIME type of the narrative, this determines 
    /// the actual format of the content</param>
    /// <param name="title">The title, ideally a short meaningful descripton</param>
    /// <param name="clinical_type">The clinical type (i.e. function) of the 
    /// data. Doesn't have to have any connection with the MIME type
    /// </param>
    /// <param name="contents">The contents -- the actual data</param>
    public void AddNarrative(
			     string local_id,
			     string mime,
			     string title,
			     NarrativeType clinical_type,
			     string contents
			     )
    {
      AddParam("narrative[localID]",local_id);
      AddParam("narrative[title]",title);
      AddParam("narrative[content]",contents);
      AddParam("narrative[narrative_type_id]",Convert.ToString((int) clinical_type));
      AddParam("narrative[content_type]",mime);
      postRequest("narratives.txt");
    }
    
    /// <summary>Add a single medication</param>
    /// <remarks>One call to this function for each medication the patient
    /// is currently taking. Including medications previously uploaded
    /// (not just new ones. Must be followed by a call to UploadMedications.
    /// Calls to other AddXXX functions may not be interpersed before the
    /// call to UploadMedications</remarks> 
    public void AddMedication(
			      string name, 
			      string strength, 
			      string instructions,
			      double quantity,
			      int repeats,
			      string authority)
    {
      yamlString.AppendFormat("- name: {0}\n  strength: {1}\n  instructions: {2}\n  quantity: {3}\n  repeats: {4}\n  authority: {5}\n",
                              name,strength,instructions,quantity,repeats,authority);
    }
    
    
    /// <summary>Add a single diagnosis</param>
    /// <remarks>One call to this function for each diagnsis the patient
    /// is currently has. Including diagnoses previously uploaded
    /// (not just new ones) Must be followed by a call to UploadDiagnoses.
    /// Calls to other AddXXX functions may not be interpersed before the
    /// call to UploadDiagnoses</remarks> 
    public void AddDiagnosis(
			     string name,
			     int year,
			     DiagnosisStatus status)
    {
      yamlString.AppendFormat("- name: {0}\n  year: {1}\n  status: {2}\n",
			      name, year, Convert.ToString((int) status));
    }
    
    /// <summary>Uploads list of medications</summary>
    /// <remarks>Uploads to the server the list of medications
    /// previously described by one or more calls to AddMedication
    /// </remarks>
    public void UploadMedications(string local_id)
    {
      AddNarrative(local_id,"text/yaml","medication list",NarrativeType.MedicationChart,yamlString.ToString());
      yamlString = new StringBuilder ();
    }
    
    /// <summary>Uploads list of diagnoses</summary>
    /// <remarks>Uploads to the server the list of diagnoses
    /// previously described by one or more calls to AddDiagnosis
    /// </remarks>
    public void UploadDiagnoses(string local_id)
    {
      AddNarrative(local_id,"text/yaml","diagnoses list",NarrativeType.Diagnosis,yamlString.ToString());
      yamlString = new StringBuilder ();
    }
    

    /// <summary>Searches for patients.</summary>
    /// <remarks>All parameters can be null to not include in the search</remarks>
    /// <param name="dob">Date of birth. To not include provide a date prior to 1850</param>
    public Patient [] findPatients(string family_name,string given_name,DateTime dob, string postcode)
    {
      if (family_name != null)
	AddParam("family_name",family_name);
      if (given_name != null)
	AddParam("given_names",given_name);
      if (dob > new DateTime(1850,1,1))
	AddParam("dob",String.Format("{0}-{1}-{2}",dob.Year,dob.Month,dob.Day));
      if (postcode != null)
	AddParam("postcode",postcode);
      return Parser<Patient>.parse(getRequest("patients/search.txt"));
    }

    /// <summary>Retrieves all narratives of a particular type, newest first</summary>
    public Narrative [] listNarratives(string wedgetail, NarrativeType type)
    {
      AddParam("patient_id",wedgetail);
      AddParam("type",Convert.ToString((int) type));
      return Parser<Narrative>.parse(getRequest("narratives.txt"));
    }

    /// <summary>Given narrative ID from listNarratives, which is a list of medications, return it in C# format</summary>
    public Medication [] getMeds(int narrative_id)
    {
      return Parser<Medication>.parse(getRequest(String.Format("narratives/{0}.txt",narrative_id)));
    }

    /// <summary>Given narrative ID from listNarratives, which is a list of diagnoses, return it in C# format</summary>
    public Diagnosis [] getDiagnoses(int narrative_id)
    {
      return Parser<Diagnosis>.parse(getRequest(String.Format("narratives/{0}.txt",narrative_id)));
    }
    
    /// <summary>Return a narrative as simple HTML suitable for display in a client-side HTML widget</summary>
    public string getNarrativeAsHtml(int narrative_id)
    {
      AddParam("id",Convert.ToString(narrative_id));
      return getRequest("narratives/show_html.txt");
    }


/*****************************************
 *   PRIVATE parts of this class         *
 * Don't read below here unless you are  *
 * interested in hacking this module    *
 *****************************************/
   
    private string host;
    private StringBuilder postString;
    private StringBuilder yamlString;
    private bool firstParam;
    private string username;
    private string password;
    
    
    
    private void AddParam(string field, string value)
    {
      if (firstParam)
	firstParam=false;
      else
	postString.Append("&");
      postString.AppendFormat
	("{0}={1}", 
	 System.Web.HttpUtility.UrlEncode(field),
	 System.Web.HttpUtility.UrlEncode(value));
    }
    
    private string postRequest(string url)
    {
      ASCIIEncoding ascii = new ASCIIEncoding();
      byte[] postBytes = ascii.GetBytes(postString.ToString());
      
      // set up request object
      HttpWebRequest request = WebRequest.Create(host+url) as HttpWebRequest;
      request.Method = "POST";
      request.ContentType = "application/x-www-form-urlencoded";
      request.ContentLength = postBytes.Length;
      request.Credentials = new NetworkCredential(username, password);
      // add post data to request
      Stream postStream = request.GetRequestStream();
      postStream.Write(postBytes, 0, postBytes.Length);
      postStream.Close();
      string result = string.Empty;
      using (HttpWebResponse response = request.GetResponse() as HttpWebResponse)
	{
	  // Get the response stream  
	  StreamReader reader = new StreamReader(response.GetResponseStream());
	  // Console application output  
	  result = reader.ReadToEnd();
	}
      // reset variables
      firstParam = true;
      postString = new StringBuilder();
      
      return result;
    }
    
    private string getRequest(string url)
    {
      // set up request object
      HttpWebRequest request = WebRequest.Create(host+url+"?"+postString.ToString()) as HttpWebRequest;
      request.Method = "GET";
      request.Credentials = new NetworkCredential(username, password);
      string result = string.Empty;
      using (HttpWebResponse response = request.GetResponse() as HttpWebResponse)
	{
	  // Get the response stream  
	  StreamReader reader = new StreamReader(response.GetResponseStream());
	  // Console application output  
	  result = reader.ReadToEnd();
	}
      // reset variables
      firstParam = true;
      postString = new StringBuilder();
      
      return result;
    }
  }

  // generic parser for tab-separated lists
  internal class Parser<T> where T:new()
    {
      public static T [] parse(string data)
      {
	// introspect to get list of fields
	// we reply on type and order of fields being correct
	// in the class definition
	FieldInfo[] myFieldInfo = typeof(T).GetFields
	  (BindingFlags.Instance | BindingFlags.Public);
	string [] lines = data.Split('\n');
	T [] result = new T[lines.Length];
	for(int i = 0; i<lines.Length;i++)
	  {
	    result[i] = new T ();
	    string [] cells = lines[i].Split('\t');
	    for (int j=0; j<myFieldInfo.Length; j++)
	      {
		string s = cells[j];
		// strings
		if (myFieldInfo[j].FieldType == typeof(string))
		  myFieldInfo[j].SetValue(result[i],s);
		// dates: presume YYYY-MM-DD format 
		else if (myFieldInfo[j].FieldType == typeof(DateTime))
		  {
		    string [] k = s.Split('-');
		    myFieldInfo[j].SetValue(result[i],new DateTime(Convert.ToInt32(k[0]),Convert.ToInt32(k[1]),Convert.ToInt32(k[2])));
		  }
		// integers
		else if (myFieldInfo[j].FieldType == typeof(int))
		  myFieldInfo[j].SetValue(result[i],Convert.ToInt32(s));
		// floats
		else if (myFieldInfo[j].FieldType == typeof(float))
		  myFieldInfo[j].SetValue(result[i],Convert.ToSingle(s));
		// enums: map to integer
		else if (myFieldInfo[j].FieldType.IsEnum)
		  myFieldInfo[j].SetValue(result[i],Convert.ToInt32(s));
	      }
	  }
	return result;
      }
    }  
}
