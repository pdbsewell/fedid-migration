/*******************************************************************************
* @author		Vishal Gupta
* @date         10/02/2025   
* @description  Request structure for scholarship offer response to callista
* @revision
*		2025-17-08	-	Sachin Shetty	-	Added Constructors
*******************************************************************************/
public class GRScholarshipOfferResponseJSON {
    public Scholarship scholarship;
    
    // Default constructor
    public GRScholarshipOfferResponseJSON() {} //NOPMD
    
	public class Scholarship {
		public ApplicationDetails applicationDetails;
		public String offerStatus;	//OFFERED/REJECTED
		public String responseStatus;	//DECLINED/ACCEPTED
		public boolean continueCandidatureWithoutScholarshipFlag;//TRUE/FALSE
		public String responseReason;	//Declined reason here
        
        public Scholarship() {} //NOPMD
	}
	public class ApplicationDetails {
		public Applicant applicant;
		public Application application;
        
        public ApplicationDetails() {} //NOPMD
	}
	public class Applicant {
		public String smsContactId;	//2454220
        
        public Applicant() {} //NOPMD
	}
	public class Application {
		public HdrApplicationDetails hdrApplicationDetails;
        
        public Application() {} //NOPMD
	}
	public class HdrApplicationDetails {
		public String hdrApplicationNumber;	//5239170
        
        public HdrApplicationDetails() {} //NOPMD
	}
}