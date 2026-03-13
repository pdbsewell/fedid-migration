/**
 * @description       : Utility class for StagedProspectiveStudentServices
 * @author            : Nick Guia
 * @date 			  : 06-02-2018
 * @last modified on  : 05-07-2023
 * @last modified by  : Nick Guia
 * @revision
 *  08-07-2019 	Nick Guia   - added constructor, and retrieveSPSMapping()
 * 	04-07-2023 	Nick Guia 	- removed CPA from commit order of exploding leads v2
**/
public with sharing class StagedProspectiveStudentUtil {

	public static final Id CONTACT_RECTYPE_PROPECTIVESTUDENT = Schema.SObjectType.Contact
	                                                           .getRecordTypeInfosByName()
	                                                           .get(Label.Contact_Rectype_ProspectiveStudent)
	                                                           .getRecordTypeId();
	public static final Id LEAD_RECTYPE_PROPECTIVESTUDENT = Schema.SObjectType.Lead
	                                                        .getRecordTypeInfosByName()
	                                                        .get(Label.Lead_Rectype_ProspectiveStudent)
	                                                        .getRecordTypeId();

	public static Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;

	/**
	 * @description  indicates the order of commit of SObjects for
	 *  Exploding Leads use cases. This will be utilised by BaseClass
	 */
	public static List<Schema.SObjectType> commitOrder {
		get {
			if(commitOrder == null) {
				commitOrder = getObjCommitOrder();
			}
			return commitOrder;
		}
		set;
	}

	/**
	 * @description  indicates the order of commit of SObjects for
	 *  Exploding Leads use cases. This will be utilised by BaseClass
	 */
	public static List<Schema.SObjectType> commitOrderV2 {
		get {
			if(commitOrderV2 == null) {
				commitOrderV2 = getObjCommitOrderV2();
			}
			return commitOrderV2;
		}
		set;
	}

	public static Map<String, List<Staging_Object_Mapping__mdt> > mappingByTargetObject {
		get {
			if(mappingByTargetObject == null) {
				mappingByTargetObject = retrieveSPSMapping();
			}
			return mappingByTargetObject;
		} set;
	}

	/**
	 * @description utility method for building key matching criteria for contacts
	 *              and related objects : 'fname ::: lName ::: email'
	 */
	public static String buildMatchingKey(String fName, String lName, String email) {
		return fName.toLowerCase() + ':::' + lName.toLowerCase() + ':::' + email.toLowerCase();
	}

	/**
	 * @description utility method for building unique key for matching contact qualification
	 *              'contact ID ::: Contact_Qualification__c.Other_Qualification__c ::: Contact_Qualification__c.Institution_Name__c'
	 */
	public static String buildContactQualificationKey(Contact_Qualification__c cq) {
		return cq.Other_Qualification__c.toLowerCase() + ':::' + cq.Institution_Name__c.toLowerCase();
	}

	/**
	 * @description utility method for building unique key for matching contact qualification
	 *              'contact ID ::: Contact_Qualification__c.Other_Qualification__c ::: Contact_Qualification__c.Institution_Name__c'
	 * @deprecate : will be deleted once ProspectiveStudentwrapper is deleted
	 */
	public static String buildContactQualificationKey(Id conId, String otherQualification, String institutionName) {
		return conId + ':::' + otherQualification.toLowerCase() + ':::' + institutionName.toLowerCase();
	}

	/**
	 * @description
	 * @param ld : lead to be updated
	 * @param sps : Staged Prospective Student record
	 * @return updated Lead record
	 */
	public static String getLatestLeadInterest(Lead ld, Staged_Prospective_Student__c sps) {
		String baoi = ld.Broad_area_s_of_interest__c;
		if(String.isNotBlank(sps.Broad_area_s_of_interest__c)) {
			//check if BAOI updatemode is 'Overwrite'. if not provided, default to Overwrite
			if(String.isBlank(sps.Broad_Area_of_Interest_Update_Mode__c) ||
			   sps.Broad_Area_of_Interest_Update_Mode__c.equalsIgnoreCase(Label.SPS_Update_Mode_Overwrite))
			{
				//update mode is overwrite
				// ld.Broad_area_s_of_interest__c = sps.Broad_area_s_of_interest__c;
				baoi = sps.Broad_area_s_of_interest__c;
			} else {
				//update mode is append
				Set<String> broadAreaSet = new Set<String>();
				//Retrieve existing areas of interest if it exists
				if(String.isNotBlank(baoi)) {
					broadAreaSet.addAll(baoi.split(';'));
				}
				//Add the new values to the set
				broadAreaSet.addAll(sps.Broad_area_s_of_interest__c.split(';'));
				//Assign the set values to the multi select picklist
				baoi = String.join(new List<String>(broadAreaSet), ';');
			}
		}
		return baoi;
	}

	/**
	 * @description logic for identifying Acquisition Source Campaign
	 * @param sps : Staged Prospective Student record
	 * @return Id of campaign record
	 */
	public static Id getAcquisitionSourceCampaign(Staged_Prospective_Student__c sps) {
		Id cmpId;
		if(sps.Acquisition_Source_Campaign__c != null) {
			//Set subscription/acquisition source campaign fields to the acquisition source campaign if it is not blank
			cmpId = sps.Acquisition_Source_Campaign__c;
		} else if(String.isNotBlank(sps.Event_Campaigns__c)) {
			//Set subscription/acquisition source campaign fields to the selected event if only 1 is selected
			if(sps.Event_Campaigns__c.split(Label.SPS_Text_Area_Value_Delimiter_Regex).size() == 1) {
				cmpId = Id.valueOf(sps.Event_Campaigns__c.trim());
			}
		}
		if(cmpId != null) {
			//validate campaign ID
			if(!CampaignMemberServices.validateCampaignId(cmpId)) {
				//if not a valid campaign ID, do not assign
				cmpId = null;
			}
		}
		return cmpId;
	}
	/**
	 * @description for getting the boolean value from a text.
	 *  this is for possible string value that Boolean.valueOf cannot parse
	 *  i.e. 't', 'T', '1', 'F', 'f'
	 * @param strBool : String value of the Boolean information
	 * @return Boolean : the Boolean value of the parsed String
	 */
	public static Boolean getBooleanFromText(String strBool) {
		Boolean bool;
		if(String.isNotBlank(strBool)) {
			if(strBool.equalsIgnoreCase('t') || strBool == '1') {
				bool = true;
			} else {
				bool = Boolean.valueOf(strBool);
			}
		}
		return bool;
	}

	/**
	 * @description for collecting Salesforce IDs from a String format.
	 *   The String will be delimited via the regex defined in
	 *   Label.SPS_Text_Area_Value_Delimiter_Regex
	 * @param String strVal : String value of collection of IDs
	 * @return Set<String> : unique key values from the String
	 * TO BE DEPRECATED AFTER CUTOVER TO EXPLODINGLEADSV2
	 **/
	public static Set<String> collectIdsFromString(String strVal) {
		Set<String> setDelimited = new Set<String>();
		if(String.isNotBlank(strVal)) {
			try {
				for(String iStr : strVal.split(Label.SPS_Text_Area_Value_Delimiter_Regex)) {
					if(String.isNotBlank(iStr)) {
						//check if String is a valid ID
						Id sObjId = (Id) iStr;
						setDelimited.add(iStr);
					}
				}
			} catch(Exception e) {
				System.debug(LoggingLevel.DEBUG, e.getMessage());
				throw e;
			}
		}
		return setDelimited;
	}

	/**
	 * @description for collecting Salesforce IDs from a String format.
	 *   The String will be delimited via the regex defined in
	 *   Label.SPS_Text_Area_Value_Delimiter_Regex
	 * @param String strVal : String value of collection of IDs
	 * @return Set<String> : unique key values from the String
	 **/
	public static Set<Id> collectIdsFromStringV2(String strVal) {
		Set<Id> setDelimited = new Set<Id>();
		if(String.isNotBlank(strVal)) {
			try {
				for(String iStr : strVal.split(Label.SPS_Text_Area_Value_Delimiter_Regex)) {
					if(String.isNotBlank(iStr)) {
						//check if String is a valid ID
						Id sObjId = (Id) iStr;
						setDelimited.add(sObjId);
					}
				}
			} catch(Exception e) {
				System.debug(LoggingLevel.DEBUG, e.getMessage());
				throw e;
			}
		}
		return setDelimited;
	}

	/**
	 * @description for collecting delimited record IDs OR course codes 
	 * 	 from a String format. The String will be delimited via the regex 
	 * 	 defined in Label.SPS_Text_Area_Value_Delimiter_Regex
	 * @param String strVal : String value of collection of IDs
	 * @return Set<String> : unique key values from the String
	 **/
	public static Set<String> collectCourseIdsFromString(String strVal) {
		Set<String> setDelimited = new Set<String>();
		if(String.isNotBlank(strVal)) {
			for(String iStr : strVal.split(Label.SPS_Text_Area_Value_Delimiter_Regex)) {
				if(String.isNotBlank(iStr)) {
					setDelimited.add(iStr);
				}
			}
		}
		return setDelimited;
	}

	/**
	 * @description retrieve the SPS to SObject field mapping from Staging_Object_Mapping__mdt
	 * @revision
	 * 	05-07-2023 	Nick Guia 	- removed unnecessary getDescribe() calls to improve speed
	 */
	private static Map<String, List<Staging_Object_Mapping__mdt> > retrieveSPSMapping() {
		Map<String, List<Staging_Object_Mapping__mdt> > spsMapping = new Map<String, List<Staging_Object_Mapping__mdt> >();
		String spsAPI = 'Staged_Prospective_Student__c';
		for(Staging_Object_Mapping__mdt iMap : [SELECT is_Overwrite__c,
		                                        Staging_SObject__c, Staging_SObject_Field__c,
		                                        Target_SObject__c, Target_SObject_Field__c,
		                                        Staging_SObject__r.QualifiedApiName,
		                                        Target_SObject__r.QualifiedApiName,
		                                        is_Text_to_Boolean__c
		                                        FROM Staging_Object_Mapping__mdt
		                                        WHERE Staging_SObject__r.QualifiedApiName = :spsAPI])
		{
			List<Staging_Object_Mapping__mdt> sObjMapping = spsMapping.get(iMap.Target_SObject__r.QualifiedApiName);
			if(sObjMapping == null) {
				sObjMapping = new List<Staging_Object_Mapping__mdt>();
			}
			sObjMapping.add(iMap);
			spsMapping.put(iMap.Target_SObject__r.QualifiedApiName, sObjMapping);
		}
		return spsMapping;
	}

    private static List<Schema.SObjectType> getObjCommitOrder() {
        return new List<Schema.SObjectType> {
            Account.SObjectType,
            Contact.SObjectType,
            Lead.SObjectType,
            Lead_Course_Association__c.SObjectType,
            Campaign.SObjectType,
            CampaignMember.SObjectType,
            Roles__c.SObjectType,
            Channel__c.SObjectType,
            Contact_Qualification__c.SObjectType,
            Case.SObjectType,
            Staged_Prospective_Student__c.SObjectType
        };
	}
	
	private static List<Schema.SObjectType> getObjCommitOrderV2() {
        return new List<Schema.SObjectType> {
            Account.SObjectType,
            Contact.SObjectType,
            Lead.SObjectType,
            Lead_Course_Association__c.SObjectType,
            Campaign.SObjectType,
            CampaignMember.SObjectType,
            Affiliation__c.SObjectType,
            Address__c.SObjectType,
            Email__c.SObjectType,
            Phone__c.SObjectType,
            Social__c.SObjectType,
            Name__c.SObjectType,
            Contact_Qualification__c.SObjectType,
            Case.SObjectType,
            Staged_Prospective_Student__c.SObjectType
        };
    }
}