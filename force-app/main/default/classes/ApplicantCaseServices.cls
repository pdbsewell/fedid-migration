/**
 * @description Applicant Services class to provide Case sObject centric logical support
 * @author      Vinothraja
 * @date        27/09/2023       
 * @group       Admissions
 */
public with sharing class ApplicantCaseServices {
    /**
	 * @author         Vinothraja
	 * @description    populates the the external_stakeholder__c field based on the ACP's Application_Agent_Code (the Agency which submitted the Application)
     * @revision
	 * 27/09/2023   Vinothraja      Created
	*/
    public void populateExternalStakeholder(List<Case> enquiries, Set<String> acpIDs) {
        // Fetch list of invalid Org unit codes
        List<String> invalidOrgUnits = SystemSettingsUtil.getInstance().getByKeyFeature('APNG', 'INVALID_ORG_UNIT_CODES')?.value__c?.split(',');
		// Construct a map of ACPs and Agency IDs, based on the ACP's application's Org unit code
        Map<Id, String> mapACPAgency = new Map<Id, String> ();
        for (Application_Course_Preference__c acp : [SELECT Application_Agent_Code__c, Application__r.Agent__c  FROM Application_Course_Preference__c WHERE id in :acpIDs]) {
            if (invalidOrgUnits == null || !invalidOrgUnits.contains(acp.Application_Agent_Code__c?.toUpperCase())) { // Checks if the Agency isn't blacklisted
                mapACPAgency.put(acp.Id, acp.Application__r.Agent__c);
            }
        }
        // Populate the External Stakeholder field from the Map
        if (!mapACPAgency.isEmpty()) {
            for (Case caseRecord : enquiries) {
                caseRecord.External_stakeholder__c = mapACPAgency.get(caseRecord.Application_Course_Preference__c);
            }
        }
    }
    /**
	 * @author         Vinothraja
	 * @description    populates the the external_stakeholder_email__c field based on the Agent who is creating the Enquiry
     * @revision
	 * 30/10/2023   Vinothraja      Created
	*/
    public void populateExternalStakeholderEmail(List<Case> enquiries, String agentEmail) {
        // Populate the External Stakeholder Email field
        if (enquiries != null) {
            for (Case caseRecord : enquiries) {
                caseRecord.External_stakeholder_Email__c = agentEmail;
            }
        }
    }
}