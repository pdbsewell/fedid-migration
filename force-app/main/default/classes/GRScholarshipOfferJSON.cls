/*******************************************************************************
* @author		Vishal Gupta
* @date         07/01/2025   
* @description  structure for graduate research scholarship offer 
* @revision     
*******************************************************************************/
public with sharing class GRScholarshipOfferJSON {
	public Scholarship scholarship;
	public class Scholarship {
		public ApplicationDetails applicationDetails;
		public String offerStatus;	//OFFERED
		public String responseStatus;	//DECLINED
		public String offerLapseDate;	//2025-01-01
		public boolean hasFacultyScholarshipAwarded;
		public boolean hasFacultySponsorshipAwarded;
		public ScholarshipAwards[] scholarshipAwards;
	}
	public class ApplicationDetails {
		public Applicant applicant;
		public Application application;
	}
	public class Applicant {
		public String smsContactId;	//2346193
	}
	public class Application {
		public HdrApplicationDetails hdrApplicationDetails;
	}
	public class HdrApplicationDetails {
		public String hdrApplicationNumber;	//5239170
		public AcademicOrgUnit academicOrgUnit;
	}
	public class AcademicOrgUnit {
		public String effectiveDate;//2018-08-15
		public String id;//50239407
	}
	public class ScholarshipAwards {
		public String scholarshipType;	//MGS
		public String scholarshipName;	//Monash Graduate Scholarship (MGS)
		public String value;	//33000
		public String valueRange;	//$35,000 to $50,800
		public Integer valueYear;	//2024
		public String previousValue;	//32000
		public String previousValueRange;	//$31,000 to $50,000
		public Integer previousValueYear;	//2023
		public String status;	//Offered
		public String conditionText;	//This offer is subject to completing your current degree with a final Honours Weighted Average (HWA) mark of 82 or higher. Your offer of admission will be issued once we have received confirmation that you have met the required condition.
	}
	public static Map<String,Object> parse(String json) {
        return (Map<String,Object>) System.JSON.deserializeUntyped(json);
    }
}