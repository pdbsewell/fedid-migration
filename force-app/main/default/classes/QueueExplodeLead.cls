/**
 * @author Nick Guia
 * @group Lead Management
 * @description : For running Exploding Leads asynchronously. Expects an AsyncExplodingLeadsDispatcher parameter to instantiate.
 **/
public class QueueExplodeLead implements Queueable {
	@TestVisible
	private List<Staged_Prospective_Student__c> spsList;
	@TestVisible
	private AsyncExplodingLeadsDispatcher dispatcher;

	public QueueExplodeLead(AsyncExplodingLeadsDispatcher dispatcher) {
		this.spsList = new List<Staged_Prospective_Student__c>();

		if(dispatcher != null) {
			this.dispatcher = dispatcher;
			for(Staged_Prospective_Student__c iSps : (List<Staged_Prospective_Student__c>) dispatcher.getRecords()) {
				this.spsList.add(iSps);
			}
		}
	}

	public void execute(QueueableContext context) {
		if(this.dispatcher != null) {
			if(!this.spsList.isEmpty()) {
				executeExplodingLeadsV2(this.spsList);
			}
			this.dispatcher.callBack();
		}
	}

	@TestVisible
	private void executeExplodingLeadsV2(List<Staged_Prospective_Student__c> spsRecords) {
		try {
			//STEP 1 : Assign the right Acquisition Source Campaign for each SPS
			spsRecords = new StagedProspectiveStudentServices(spsRecords).assignAcquisitionSourceCampaign();

			//STEP 2 : separate those SPS without a Contact ID, and run the Contact matching for them
			List<Staged_Prospective_Student__c> spsListWithContact =
					new List<Staged_Prospective_Student__c>();
			List<Staged_Prospective_Student__c> spsListNoContact =
				new List<Staged_Prospective_Student__c>();

			for(Staged_Prospective_Student__c iSps : spsRecords) {
				if(iSps.Exploded_Target__c != null) {
					spsListWithContact.add(iSps);
				} else {
					spsListNoContact.add(iSps);
				}
			}
			spsListWithContact.addAll(
				new StagedProspectiveStudentServices(spsListNoContact).assignProspectiveStudentContact()
			);

			//STEP 3: run exploding leads
			new StagedProspectiveStudentServices(spsListWithContact).executeExplodingLeads();

		} catch(Exception e) {
			LogUtilityException.logException(e);
		}
	}
}