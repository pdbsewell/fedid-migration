/**
 * For updating the marketing segment associated with a contact based on their Contact Qualification.
 * 
 * @author      Charlie Park - UC Innovation
 * @date        01/05/2019    
 * @revision    08/03/2022 - APRivera - PENGAGE-1864 Change the definition of Alumni Segments Change
 */
global class EngageUpdateMarketSegmentBatch implements Database.Batchable<SObject> {
    global String query;
    List<Market_Segment_Criteria__mdt> criteriaList = [SELECT Age_High__c,Age_Low__c,Transition_Date_Range_High__c,Transition_Date_Range_Low__c,Market_Segment__c 
                                                        FROM Market_Segment_Criteria__mdt];

    /*******************************************************************************
    * @author       Charlie Park - UC Innovation
    * @date         02/10/2019    
    * @description  Query existing marketing segment, and existing contact qualifications from alumni.
    *******************************************************************************/  
    global EngageUpdateMarketSegmentBatch() {
        query = 'SELECT ID,Name,Age__c,Contact_Profile__c,Market_Segment__c ' 
              + 'FROM Contact WHERE Contact_Profile__c INCLUDES (\'Alumni\')';
    }

    global EngageUpdateMarketSegmentBatch(String query) {
        this.query = query;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
     
    /*******************************************************************************
    * @author       Charlie Park - UC Innovation
    * @date         02/10/2019    
    * @description  Based on age and time since qualification transition, determine market segment
    *******************************************************************************/  
    global void execute(Database.BatchableContext BC, List<Contact> contactList) {
        // Subquery in the execute to avoid cpu limit on start query
        List<Contact> contactsWithCQ = [SELECT Id ,Name,Age__c,Contact_Profile__c,Market_Segment__c,
                                                (SELECT Id, Date_Achieved__c, Honorary_Degree__c FROM Contact_Qualifications__r
                                                    WHERE Obtained_Status__c = 'MONASH-OBTAINED' AND Institution_Name__c = 'Monash University' 
                                                    AND Verification_Status__c = 'Verified' AND Date_Achieved__c != NULL
                                                    ORDER BY Date_Achieved__c ASC NULLS LAST LIMIT 1)
                                            FROM Contact WHERE Id IN: contactList];

        // Update Market Segment field based on when the constituent transitioned to be an alumni and their age.
        for (Contact eachContact: contactsWithCQ) {
            Date firstTransitionDate = null;
            if (!eachContact.Contact_Qualifications__r.isEmpty()) {
                firstTransitionDate = eachContact.Contact_Qualifications__r[0].Date_Achieved__c;

                // Default is Established Alumni
                eachContact.Market_Segment__c = 'Established Alumni';

                if (firstTransitionDate != null) {
                    for (Market_Segment_Criteria__mdt eachCriteria: criteriaList) {
                        Boolean bWithAge = true;
                        if(eachContact.Age__c == null){
                            bWithAge = false;
                        }
                        if (checkCriteria(eachCriteria, eachContact, bWithAge)) {
                            eachContact.Market_Segment__c = eachCriteria.Market_Segment__c;
                            break;
                        }
                    }
                }
            }
        }

        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('Contact', false);
        TriggerCommon.disableTrigger('Contact');
        update contactsWithCQ;
        TriggerCommon.enableTrigger('Contact');
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('Contact', true);
    }   
     
    global void finish(Database.BatchableContext BC) {

    }

    /*******************************************************************************
    * @author       Charlie Park - UC Innovation
    * @date         21/1/2020    
    * @description  Check age criteria only, if it meets criteria return true.
    *               if Contact Age is given, use the Life Stage Segments, otherwise, use the Contact Qualification Date Achieved to get the market segment
    * @revision     08/03/2022 - APRivera - updated the criteria checking based on PENGAGE-1864
    * @return       Boolean
    *******************************************************************************/  
    private Boolean checkCriteria(Market_Segment_Criteria__mdt thisCriteria, Contact thisContact, Boolean bWithAge) {
        if(bWithAge){
            if (thisContact.Age__c != null && thisContact.Age__c > thisCriteria.Age_Low__c && thisContact.Age__c < thisCriteria.Age_High__c) {
                return true;
            }
        }else{
            Date firstTransitionDate =  thisContact.Contact_Qualifications__r[0].Date_Achieved__c;
            Date dtLow = Date.newInstance(Integer.valueOf(thisCriteria.Transition_Date_Range_Low__c), 1, 1);
            Date dtHigh = Date.newInstance(Integer.valueOf(thisCriteria.Transition_Date_Range_High__c), 12, 31);

            // check if contact has Honorary Degree
            if(thisContact.Contact_Qualifications__r[0].Honorary_Degree__c){
                // get the year between Date_Achieved__c and today's year and add it to the 40 years(business rule) to get the proxy age
                Integer iProxyAge = 40 + (firstTransitionDate.monthsBetween(System.today())  / 12);
                if (iProxyAge > thisCriteria.Age_Low__c && iProxyAge < thisCriteria.Age_High__c) {
                    return true;
                }
            }else{
                // use the Transition_Date_Range_Low__c and Transition_Date_Range_High__c from Market_Segment_Criteria__mdt
                if(firstTransitionDate >= dtLow && firstTransitionDate <= dtHigh){
                    return true;
                }
            }
        }
        return false;
    }
}