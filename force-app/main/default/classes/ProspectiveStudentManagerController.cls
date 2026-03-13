/**
 * @File Name          : ProspectiveStudentManagerController.cls
 * @Description        : Controller class for Universal Lead CRUD components
 * @Author             : Nick Guia
 * @Group              : Lead Management
 **/
public with sharing class ProspectiveStudentManagerController {

	/**
	 * @description create a new prospective student record. This will leverage the
	 *	StagedProspectiveStudentServices by feeding an SPS SObject-format JSON input parameter.
	 *  Shouldn't create any SPS records within CRM.
	 * @param Staged_Prospective_Student__c sps : SPS record
	 * @return Id : resulting Contact ID
	 */
	@AuraEnabled
	public static Id createProspectiveStudent(PsmDTO dto) {
		Staged_Prospective_Student__c sps = dto.sps;
		Id contactId;
		try {
			// create/match the prospective student Contact using the Service class
			ExplodingLeadsService service = new ExplodingLeadsService(sps);

			//bypass Lead matching criteria if only Last name is present
			if(String.isBlank(sps.First_Name__c) || String.isBlank(sps.Email__c)) {
				Contact psCon = service.buildProspectiveContact(sps);
				psCon = populateOtherContactFields(psCon, dto);
				insert psCon;
				sps.Exploded_Target__c = psCon.Id;
				service = new ExplodingLeadsService(sps); //reconstruct with SPS with Contact ID
			} else {
				List<StagedProspectiveStudentDAO> spsDaoList = service.buildPSContact();
				Contact psCon = service.buildProspectiveContact(sps);
				psCon = populateOtherContactFields(psCon, dto);
				System.debug('psCon : ' + JSON.serializePretty(psCon));
				//expected to only have one DAO class return given that we're only process one sps
				spsDaoList[0].setPerson(psCon);
				sps = service.upsertProspectiveStudentContact(spsDaoList)[0];
			}
 
			// run the exploding logic
			service.initialiseExplodingLeads();
			service.execute();

			// capture any contact IDs that ended up with "Partial Error SPS"
			Set<Id> partialErrorContacts = service.commitRecords();
			contactId = sps.Exploded_Target__c; // return Contact ID
		} catch(Exception e) {
			LogUtilityException.logException(e);
			System.debug(LoggingLevel.ERROR, e.getMessage() + ' ' + e.getStackTraceString());
			throw new AuraHandledException('An unexpected error occurred. Please contact your System Administrator');
		}
		return contactId;
	}

	/**
	 * @description map field updates on Contact (from the DTO class) 
	 * for fields that does not exist in SPS object
	 */
	public static Contact populateOtherContactFields(Contact con, PsmDTO dto) {
		// if(con != null && dto != null) {
			if(String.isNotBlank(dto.residencyStatus)) {
				con.Residency_Status__c = dto.residencyStatus;
			}

			if(String.isNotBlank(dto.educLevel)) {
				con.Highest_level_of_education_to_date__c = dto.educLevel;
			}

			if(String.isNotBlank(dto.conProf)) {
				con.Contact_Profile__c = dto.conProf;
			}
		// }
		return con;
	}

	/**
	 * @description create a new prospective student record WITH contact ID. This will leverage the
	 * 	StagedProspectiveStudentServices by feeding an SPS SObject-format JSON input parameter.
	 *  Shouldn't create any SPS records within CRM.
	 * @param Staged_Prospective_Student__c sps : SPS record
	 * @return Id : resulting Lead ID
	 */
	@AuraEnabled
	public static Id createProspectiveStudentLead(PsmDTO dto) {
		Staged_Prospective_Student__c sps = dto.sps;
		Id leadId;
		try {
			updateContactFromSps(dto);
			Id contactId = sps.Exploded_Target__c;
			ExplodingLeadsService exLeads = new ExplodingLeadsService(new List<Staged_Prospective_Student__c> {sps});
			exLeads.initialiseExplodingLeads();
			exLeads.execute();
			Set<Id> partialErrorContacts = exLeads.commitRecords();
			StagedProspectiveStudentDAO spsDAO = exLeads.getSpsDAOMap().get(contactId);
			Lead leadRec = spsDAO.getLead();
			if(leadRec != null) {
				leadId = leadRec.Id;
			}
		} catch(Exception e) {
			LogUtilityException.logException(e);
			System.debug(LoggingLevel.ERROR, e.getMessage() + ' ' + e.getStackTraceString());
			throw new AuraHandledException('An unexpected error occurred. Please contact your System Administrator');
		}
		return leadId;
	}

	/**
	 * @description for updating existing Contact / Lead record
	 * @param Staged_Prospective_Student__c sps : SPS SObject-formatted deserialized JSON
	 */
	@AuraEnabled
	public static void updateProspectiveStudent(PsmDTO dto) {
		Staged_Prospective_Student__c sps = dto.sps;
		try {
			ExplodingLeadsFactory factory = new ExplodingLeadsFactory();
			ExplodingLeadsSelector selector = new ExplodingLeadsSelector();
			// separately update Contact first
			updateContactFromSps(dto);
			// get existing Lead values to make sure we won't overwrite with null
			Lead existingRec = selector.selectExistingLeads(new Set<Id>{ sps.Exploded_Target__c })[0];
			// use ExplodingLeads Factory to create updated version of lead
			Lead newRec = factory.buildProspectiveLead(existingRec, new List<Staged_Prospective_Student__c> { sps });
			newRec.Id = sps.Exploded_Lead__c;
			if(newRec.Id != null) {
				update newRec;
			}
		} catch(Exception e) {
			LogUtilityException.logException(e);
			System.debug(LoggingLevel.ERROR, e.getMessage() + ' ' + e.getStackTraceString());
			throw new AuraHandledException('An unexpected error occurred. Please contact your System Administrator');
		}
	}

	/**
	 * @description update contact based on SPS details.
	 * 	ExplodingLeadsFactory was not used for this because 
	 * 	it attempts to update the contact's record type 
	 */
	private static void updateContactFromSps(PsmDTO dto) {
		Staged_Prospective_Student__c sps = dto.sps;
		Contact con = new Contact(Id = sps.Exploded_Target__c);
		con.FirstName = sps.First_Name__c;
		con.LastName = sps.Last_Name__c;
		con.Email = sps.Email__c;
		con.MobilePhone = sps.Mobile__c;
		con.Gender__c = sps.Gender__c;
		con.Country_of_Residence__c = sps.Country_of_Residence__c;
		con.Nationality__c = sps.Nationality__c;
		con.Birthdate = sps.Birthdate__c;
		con.OtherPhone = sps.Phone__c;
		con.MailingStreet = sps.Mailing_Street__c;
		con.MailingCity = sps.Mailing_City__c;
		con.MailingPostalCode = sps.Mailing_Postcode__c;
		con.MailingState = sps.Mailing_State__c;
		con.MailingCountry = sps.Mailing_Country__c;
		con.Residency_Status__c = dto.residencyStatus;
		con.Highest_level_of_education_to_date__c = dto.educLevel;
		con.Contact_Profile__c = dto.conProf;

		if(con.Id != null) {
			update con;
		}
	}

	/**
	 * @description get Lead Course Association records of a Lead
	 * @param String leadId : Lead ID
	 * @return List<Lead_Course_Association__c> : list of LCA's
	 */
	@AuraEnabled(cacheable=true)
	public static List<Lead_Course_Association__c> getLeadCourseInterests(String leadId){
		List<Lead_Course_Association__c> lcaList = new List<Lead_Course_Association__c>();
		try {
			if(String.isNotBlank(leadId)) {
				lcaList =  [SELECT Id, Course_Code__c, Course_Description__c
				            FROM Lead_Course_Association__c
				            WHERE Lead__c = :leadId
				                            AND IsLatestCourseAssociation__c = TRUE
				                                                               ORDER BY Last_Associated_Rank__c ASC];
			}
		} catch(Exception e) {
			LogUtilityException.logException(e);
			System.debug(LoggingLevel.ERROR, e.getMessage() + ' ' + e.getStackTraceString());
			throw new AuraHandledException('An unexpected error occurred. Please contact your System Administrator');
		}
		return lcaList;
	}

	/**
	 * @description save the lead course interest through SPS
	 * @param Staged_Prospective_Student__c sps : SPS SObject-formatted deserialized JSON
	 */
	@AuraEnabled
	public static void saveLeadCourseInterests(Staged_Prospective_Student__c sps){
		try {
			Id contactId = sps.Exploded_Target__c;
			ExplodingLeadsService exLeads = new ExplodingLeadsService(new List<Staged_Prospective_Student__c> {sps});
			exLeads.initialiseExplodingLeads();
			exLeads.execute();
			Set<Id> partialErrorContacts = exLeads.commitRecords();
		} catch(Exception e) {
			LogUtilityException.logException(e);
			System.debug(LoggingLevel.ERROR, e.getMessage() + ' ' + e.getStackTraceString());
			throw new AuraHandledException('An unexpected error occurred. Please contact your System Administrator');
		}
	}

	/**
	 * @description retrieves Prospective Student data from a Case - Contact, and latest active Lead
	 * @return CaseProspectiveStudent : wrapper class of data
	 */
	@AuraEnabled(cacheable=true)
	public static CaseProspectiveStudent getPsData(String caseId){
		CaseProspectiveStudent cps;
		try {
			cps = new CaseProspectiveStudent(caseId);
		} catch(Exception e) {
			LogUtilityException.logException(e);
			System.debug(LoggingLevel.ERROR, e.getMessage() + ' ' + e.getStackTraceString());
			throw new AuraHandledException('An unexpected error occurred. Please contact your System Administrator');
		}
		return cps;
	}

	public class CaseProspectiveStudent {
		@AuraEnabled public Case caseRec {get; set;}
		@AuraEnabled public Contact contactRec {get; set;}
		@AuraEnabled public Lead leadRec {get; set;}

		public CaseProspectiveStudent(Id caseId) {
			this.caseRec = getCaseDetails(caseId);
			if(this.caseRec.ContactId != null) {
				this.contactRec = getContactDetails(this.caseRec.ContactId);
				if(!this.contactRec.Leads__r.isEmpty()) {
					this.leadRec = this.contactRec.Leads__r[0];
				}
			}
		}

		private Case getCaseDetails(Id caseId) {
			return [SELECT Id, ContactId, Lead__c, Supplied_First_Name__c,
				Supplied_Last_Name__c, Supplied_Date_of_Birth__c, SuppliedPhone, SuppliedEmail, Supplied_Mobile__c,
				Supplied_Nationality__c, Supplied_Postcode__c, Supplied_State__c, Residency_Status__c,
				Supplied_City__c, Commencement_Year__c, Supplied_Area_of_Interest__c, Highest_Level_of_Study__c,
				Supplied_Country_of_Residence__c, Level_of_Study__c, Supplied_Name_of_Institution__c, SuppliedCompany
				FROM Case WHERE Id = : caseId LIMIT 1];
		}

		private Contact getContactDetails(Id contactId) {
			return [SELECT Id, FirstName, LastName, MailingCity, MailingCountry, 
				MailingPostalCode, MailingState, MailingStreet, Birthdate,
			        (SELECT Id
			         FROM Leads__r
					 WHERE Active_Lead_Contact_Id__c = : contactId
					 AND RecordTypeId = :StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT
			         ORDER BY LastModifiedDate, CreatedDate
			         DESC)
			        FROM Contact
			        WHERE Id = : contactId];
		}
	}

	/**
	 * @description data transfer object for PSM component
	 */
	public class PsmDTO {
		@AuraEnabled
		public Staged_Prospective_Student__c sps {get; set;}
		@AuraEnabled
		public String residencyStatus {get; set;}
		@AuraEnabled
		public String educLevel {get; set;}
		@AuraEnabled
		public String conProf {get; set;}

		public PsmDTO() { }
	}
}