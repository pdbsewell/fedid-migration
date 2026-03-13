/**
 * @description       : This class is responsible for generating Prospective Student related 
 *                      records based on Exploding Leads logic.
 * @author            : Nick Guia
 * @group             : Lead Management
 * @last modified on  : 04-07-2023
 * @last modified by  : Nick Guia
 * @revision
 *  03-07-2023    Nick Guia   - added defaulting Account_Record_Type_Name__c = 'Household_Account' on contact creation
**/
public without sharing virtual class ExplodingLeadsFactory {

    public ExplodingLeadsFactory() {}

    /**
     * @description For building a Prospective Student Contact. Field mapping
     *  is based on Staging_Object_Mapping__mdt metadata records
     * @param sps : sps record where we're basing the information on
     * @return Contact : prospective Student contact
     */
    public Contact buildProspectiveContact(Staged_Prospective_Student__c sps) {
        Contact newContact = new Contact();
        List<Staging_Object_Mapping__mdt> contactMapping = new List<Staging_Object_Mapping__mdt>();
        contactMapping = StagedProspectiveStudentUtil.mappingByTargetObject.get(Contact.SObjectType.getDescribe().getName());

        for(Staging_Object_Mapping__mdt iMap : contactMapping) {
            String spsField = String.valueOf(iMap.Staging_SObject_Field__c);
            String contactField = String.valueOf(iMap.Target_SObject_Field__c);
            newContact.put(contactField, sps.get(spsField));
        }
        newContact.RecordTypeId = StagedProspectiveStudentUtil.CONTACT_RECTYPE_PROPECTIVESTUDENT;
        newContact.Account_Record_Type_Name__c = 'Household_Account';
        return newContact;
    }

    /**
     * @description Merges information of the existing contact with the virtual contact
     *  which was derived from sps record. Each field update has specific conditions for update
     * @param existingCon : Existing contact found
     * @param newCon : new built contact based on SPS record
     * @return Contact : merged version of the two contacts
     */
    public Contact mergeProspectiveContact(Contact existingCon, Contact newCon) {
        //TODO: MOVE THIS TO CUSTOM METADATA
        //update only the below fields in contact
        if(newCon.Birthdate != null && existingCon.Birthdate == null) {
            existingCon.Birthdate = newCon.Birthdate;
        }

        if(!String.isBlank(newCon.Birth_year__c) && String.isBlank(existingCon.Birth_year__c)) {
            existingCon.Birth_year__c = newCon.Birth_year__c;
        }

        if(!String.isBlank(newCon.Gender__c) && String.isBlank(existingCon.Gender__c)) {
            existingCon.Gender__c = newCon.Gender__c;
        }

        if(!String.isBlank(newCon.Country_of_Residence__c) && String.isBlank(existingCon.Country_of_Residence__c) ) {
            existingCon.Country_of_Residence__c = newCon.Country_of_Residence__c;    
        }

        if(!String.isBlank(newCon.Nationality__c)) {
            existingCon.Nationality__c = newCon.Nationality__c;    
        }
        return existingCon;
    }

    /**
     * @description for creating a new role based on SPS record.
     * @param sps : Staged Prospective Student record
     * @return Role record to be created
     */
    public Roles__c buildProspectiveRole(Staged_Prospective_Student__c sps) {
        Roles__c returnVal;
        if(sps != null) {
            Boolean isParent = false;
            if(String.isNotBlank(sps.Seeking_information_for__c)) {
                if(sps.Seeking_information_for__c.toLowerCase().equalsIgnoreCase('child')) {
                    isParent = true;
                }
            }
            returnVal = new Roles__c(
                Role__c = Label.Roles_Role_ProspectiveStudent,
                Status__c = Label.Roles_Status_Current,
                External_ID__c = sps.Id,
                Is_Parent__c = isParent,
                Account__c = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID
            );
        }
        return returnVal;
    }

    /**
     * @description for creating a new Channel based on SPS record.
     *              Start date not populated on purpose. As it should
     *              be coming from the overloaded method.
     * @param sps : Staged Prospective Student record
     * @return Channel record to be created
     */
    public Channel__c buildProspectiveChannel(Staged_Prospective_Student__c sps) {
        Channel__c returnVal;
        if(sps != null) {
            returnVal = new Channel__c(
                Email__c = sps.Email__c,
                Mobile_Phone__c = sps.Mobile__c,
                Phone__c = sps.Phone__c,
                Street__c = sps.Mailing_Street__c,
                City__c = sps.Mailing_City__c,
                Post_Code__c = sps.Mailing_Postcode__c,
                State__c = sps.Mailing_State__c,
                Country__c = sps.Mailing_Country__c,
                Type__c = Label.ExLeads_Channel_Type,
                Start_Date__c = Date.today(),
                Is_Processed__c = false
            );
        }
        return returnVal;
    }

    /**
     * @description overloaded method for buildProspectiveLead
     */
    public Lead buildProspectiveLead(Staged_Prospective_Student__c sps) {
        return buildProspectiveLead(null, new List<Staged_Prospective_Student__c>{sps});
    } 

    /**
     * @description for creating a new Lead based on List of SPS records.
     *              Lead mapping is stored in a custom metadata:
     *              SPS_to_Lead_Field_Mapping__mdt
     * @param existingLead : the existing Lead to be updated
     *        spsList : Staged Prospective Student records
     * @return Lead record to be created
     */
    public Lead buildProspectiveLead(Lead existingLead, List<Staged_Prospective_Student__c> spsList) {
        
        Lead leadRec = new Lead();
        String leadSource;

        if(existingLead != null) {
            leadRec.Broad_area_s_of_interest__c = existingLead.Broad_area_s_of_interest__c;

            // store original lead source so we don't overwrite it
            if(String.isNotBlank(existingLead.LeadSource)) {
                leadSource = existingLead.LeadSource;
            }
            
            // store original acquisition source so we don't overwrite it
            if(existingLead.Acquisition_Source__c != null) {
                leadRec.Acquisition_Source__c = existingLead.Acquisition_Source__c;
            }
        }

        List<Staging_Object_Mapping__mdt> leadMapping = StagedProspectiveStudentUtil.mappingByTargetObject.get('Lead');

        for(Staged_Prospective_Student__c iSps : spsList) {
            for(Staging_Object_Mapping__mdt fieldMap : leadMapping) {
                String spsField = String.valueOf(fieldMap.Staging_SObject_Field__c);
                String leadField = String.valueOf(fieldMap.Target_SObject_Field__c);
                String spsVal = String.valueOf(iSps.get(spsField));

                if(String.isNotBlank(spsVal)) {
                    // This is for checking Text fields being parsed to checkboxes
                    if(fieldMap.is_Text_to_Boolean__c) {
                        Boolean bool = StagedProspectiveStudentUtil.getBooleanFromText(spsVal);
                        leadRec.put(leadField, bool);
                    } else {
                        leadRec.put(leadField, spsVal);
                    }
                }
            }

            // get lead Acquisition Source
            if(leadRec.Acquisition_Source__c == null) {
                leadRec.Acquisition_Source__c = StagedProspectiveStudentUtil.getAcquisitionSourceCampaign(iSps);
            }

            // get Lead interest
            leadRec.Broad_area_s_of_interest__c = StagedProspectiveStudentUtil.getLatestLeadInterest(leadRec, iSps);
        }


        // default to 'N/A' if blank
        if(String.isBlank(leadRec.Company)) {
            leadRec.Company = 'N/A';
        }

        // never overwrite lead source
        if(String.isNotBlank(leadSource)) {
            leadRec.LeadSource = leadSource;
        }

        // assign constants
        leadRec.Status = 'Open';
        leadRec.RecordTypeId = StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT;
        return leadRec;
    }

    /**
     * @description for creating a new Lead Course Association record
     * @param courseMasterId : ID of Course Master record
     *        rank : order of preference
     * @return Lead_Course_Association__c record to be created
     */
    public Lead_Course_Association__c buildLeadCourseAssociation(Id courseMasterId, Integer rank) {
        Lead_Course_Association__c lcaRec = new Lead_Course_Association__c();
        lcaRec.Course_Master__c = courseMasterId;
        lcaRec.Last_Associated_Rank__c = rank;
        lcaRec.Associated_Date__c = System.now();
        return lcaRec;
    }

    /**
    * @description for assigning contact as campaign member to
    *   subscription list based on sps details.
    * @param Campaign cmp : parent Campaign
    * @param CampaignMember cm : existing Campaign Member record of this contact
    * @param Staged_Prospective_Student__c sps : sps record to derive our details from
    * @return CampaignMember : resulting Campaign Member (new/update)
    **/
    public CampaignMember buildSubscriptionMember(Campaign cmp, CampaignMember cm, Staged_Prospective_Student__c sps) {

        Id subscriptionSourceCampaign = StagedProspectiveStudentUtil.getAcquisitionSourceCampaign(sps);

        if(cmp.Channel_Type__c != null) {
            if(cmp.Channel_Type__c.containsIgnoreCase('Email') &&
            (!cm.Active__c || !cm.ChannelEmail__c)) {
                /**
                 * Set source to campaign if the subscription source is a campaign else
                 * default to the source from the staged prospective student
                 */
                if(subscriptionSourceCampaign != null) {
                    cm.Email_Subscription_Source__c = 'Campaign';
                    cm.Email_Subscription_Source_Campaign__c = subscriptionSourceCampaign;
                } else {
                    //set as Web
                    cm.Email_Subscription_Source__c = sps.Lead_Source__c;
                }
                //populate channel email and subscribed date
                cm.ChannelEmail__c = true;
                cm.Email_Subscribed_Date__c = System.today();
            }
            
            if(cmp.Channel_Type__c.containsIgnoreCase('SMS') &&
            (!cm.Active__c || !cm.ChannelSMS__c)) {
                /**
                 * Set source to campaign if the subscription source is a campaign else
                 * default to the source from the staged prospective student
                 */ 
                if(subscriptionSourceCampaign != null){
                    cm.SMS_Subscription_Source__c = 'Campaign';
                    cm.SMS_Subscription_Source_Campaign__c = subscriptionSourceCampaign;
                } else {
                    //set as Web
                    cm.SMS_Subscription_Source__c = sps.Lead_Source__c;
                }
                cm.ChannelSMS__c = true;
                cm.SMS_Subscribed_Date__c = System.today();
            }
        }
        cm.Active__c = true;
        return cm;
    }

}