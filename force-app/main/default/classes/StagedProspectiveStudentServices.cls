/**
 * @author Nick Guia
 * @group Lead Management
 * @description : Service Class to orchestrate SPS record processing
 **/
public class StagedProspectiveStudentServices {

	@TestVisible
	private List<Staged_Prospective_Student__c> spsList;

	public StagedProspectiveStudentServices(List<Staged_Prospective_Student__c> spsRecords) {
		this.spsList = spsRecords;
	}

	public StagedProspectiveStudentServices(Staged_Prospective_Student__c sps) {
		this.spsList = new List<Staged_Prospective_Student__c> {sps};
	}

	/**
	 * @description assign acquisition source campaign for each SPS
	 */
	public List<Staged_Prospective_Student__c> assignAcquisitionSourceCampaign() {
		for(Staged_Prospective_Student__c iSps : this.spsList) {
			try {
				if(String.isNotBlank(iSps.Event_Campaigns__c)) {
					iSps.Acquisition_Source_Campaign__c = StagedProspectiveStudentUtil.getAcquisitionSourceCampaign(iSps);
				}
			} catch(Exception e) {
				LogUtilityException.logException(e);
			}
		}
		return this.spsList;
	}

	/**
	 * @description Attempt match duplicate / create a new Contact then link back to SPS "Exploded Target"
	 */
	public List<Staged_Prospective_Student__c> assignProspectiveStudentContact() {
		try {
			if(this.spsList != null && !this.spsList.isEmpty()) {
				ExplodingLeadsContactMatcher matcher = new ExplodingLeadsContactMatcher(this.spsList);
				matcher.findAllEmailFields();
				matcher.run();
				this.spsList = matcher.getSpsRecords();
			}
		} catch(Exception e) {
			LogUtilityException.logException(e);
		}
		return this.spsList;
	}

	/**
	 * @description run exploding leads
	 * 	Create Person 360 model out of the related Contact
	 *  Create an active Lead and Lead course interest
	 * 	Create Campaign Member records for the Contact
	 * 	Create Enquiries
	 * @return List<Staged_Prospective_Student__c> processed SPS records
	 */
	public List<Staged_Prospective_Student__c> executeExplodingLeads() {
		try {
			this.spsList = new ExplodingLeadsServiceV2(this.spsList)
							.createPerson360()
							.createLeadsAndCourseInterest()
							.createContactQualifications()
							.createCampaignMembers()
							.save();
		} catch(Exception e) {
			LogUtilityException.logException(e);
		}
		return this.spsList;
	}

	/**
	 * @description create a Contact record for SPS records
	 *   and link it back to the Exploded_Target__c field.
	 * @return List<Staged_Prospective_Student__c> : spsList with Exploded_Target__c
	 * TO BE DEPRECATED AFTER MIGRATING TO V2
	 */
	public List<Staged_Prospective_Student__c> processProspectiveStudentContact() {
		List<Staged_Prospective_Student__c> spsWithContactIds = new List<Staged_Prospective_Student__c> ();
		try {
			ExplodingLeadsService exLeadsService = new ExplodingLeadsService(this.spsList);
			List<StagedProspectiveStudentDAO> daoList = exLeadsService.buildPSContact();
			spsWithContactIds = exLeadsService.upsertProspectiveStudentContact(daoList);
		} catch(Exception e) {
			LogUtilityException.logException(e);
		}
		return spsWithContactIds;
	}

	/**
	 * @description initialise, execute, and commit Exploding Leads
	 * @return void
	 * TO BE DEPRECATED AFTER MIGRATING TO V2
	 */
	public void runExplodingLeads() {
		ExplodingLeadsService exLeads = new ExplodingLeadsService(this.spsList);
        exLeads.initialiseExplodingLeads();
        exLeads.execute();
        Set<Id> partialErrorContacts = exLeads.commitRecords();
        exLeads.updateSPSRecords(partialErrorContacts);
    }
}