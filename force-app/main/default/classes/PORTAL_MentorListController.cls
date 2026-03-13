/*
 * Copyright (c) 2019, UC Innovation, Inc.  All Rights Reserved.
 *                     http://www.ucinnovation.com
 *
 * This source code is licensed, not sold, and is subject to a written
 * license agreement.  Among other things, no portion of this source
 * code may be copied, transmitted, disclosed, displayed, distributed,
 * translated, used as the basis for a derivative work, or used, in
 * whole or in part, for any program or purpose other than its intended
 * use in compliance with the license agreement as part of UC Innovation's
 * software.  This source code and certain of the algorithms contained
 * within it are confidential trade secrets of UC Innovation, Inc.
 * and may not be used as the basis for any other
 * software, hardware, product or service.
 */
 
 /**
 * Handles methods related to mentor/mentee.
 *
 * @author:  Ken Tang
 * @version: 1.0
 * @since:   1.0
 */
global without sharing class PORTAL_MentorListController {

    /**
     * Get a list of mentors.
     *
     * @param: sharing     	'All, 'Me', 'My Request'
     * @param: relevance   	'All', 'Recommended', 'Non-Recommended'
     * @param: maxItems    	Maximum number of mentors to return.  It's a string since Salesforce has issues with passing
     *                     	integers from Lightning Component controller to Apex controller.
     * @return:            	List of mentors.
     * @since: 				1.0
     */
    @AuraEnabled
    global static List<Mentor__c> SERVER_getMentorList(String sharing, String relevance, String maxItems, String searchText) {
        
        Integer maxItemsInt = Integer.valueOf(maxItems);
        
        if (!String.isBlank(searchText)) {
            searchText = '%' + searchText + '%';
        }                                                          
        
        Id userId = UserInfo.getUserId();
        
        System.debug('userId: ' + userId);
        
        User usr = PORTAL_CommunityUtils.getLoggedInUserInfo(userId);
        
        Id contactId = usr.ContactId;
        
        System.debug('contactId: ' + contactId);
        
        // If not contact, then must be a regular Salesforce user.
        if (contactId == null) {
            return new List<Mentor__c>();
        }
        
        system.debug('searchText: ' + searchText);
        system.debug('maxItemsInt: ' + maxItemsInt);
        
        List<Mentor__c> mentorList = new List<Mentor__c>();
        
        String queryString = 'SELECT Id, Name, CreatedById, Application_Status__c, Is_Available__c, Mentor_Name__c, Additional_Role_Details_and_Notes__c, Number_of_Mentees_Accepted__c, Mentoring_Category__c, Total_Openings__c, Job_Responsibilities__c, ' +
            '(SELECT Id, Name, Mentor__c, Mentee__c, Mentee__r.FirstName, Mentee__r.LastName, Mentee_Name__c, Application_Status__c, Topics_of_Interest__c FROM Mentees_Mentor__r) ' +
            'FROM Mentor__c ';
        
        if (!String.isBlank(searchText)) {
            queryString = queryString + 'WHERE Name LIKE :searchText';
        }
        
        mentorList = Database.query(queryString);                  
        
        System.debug('mentorList: ' + mentorList);
        
        List<Mentor__c> myMentorList = new List<Mentor__c>();
        List<Mentor__c> notMyMentorList = new List<Mentor__c>();
        List<Mentor__c> myMentorRequestList = new List<Mentor__c>();
        
        for (Mentor__c mentorRec : mentorList) {
            // I'm the mentor...
            if (mentorRec.CreatedById == userId) {
                myMentorList.add(mentorRec);
            }
            // Check for my list of mentors I applied for.
            else if (mentorRec.Mentees_Mentor__r != null && !mentorRec.Mentees_Mentor__r.isEmpty()) {
                Boolean found = false;
                
                for (Mentee__c menteeRec : mentorRec.Mentees_Mentor__r) {
                    
                    // If I'm a mentee, then must be my mentor.
                    if (menteeRec.Mentee__c == contactId) {
                        myMentorRequestList.add(mentorRec);
                        found = true;
                        break;
                    }
                }
                
                if (!found && mentorRec.Application_Status__c == 'Approved') {
                    notMyMentorList.add(mentorRec);
                }
            }            
            else if (mentorRec.Application_Status__c == 'Approved') {
                notMyMentorList.add(mentorRec);
            }
        }
        
        System.debug('myMentorList: ' + myMentorList);
        System.debug('notMyMentorList: ' + notMyMentorList);
        System.debug('myMentorRequestList: ' + myMentorRequestList);
        
        List<Mentor__c> resultMentorList = new List<Mentor__c>();
        List<Mentor__c> tempMentorList = new List<Mentor__c>();
        
        if (sharing == 'Me') {
            tempMentorList = myMentorList;
        }
        else if (sharing == 'My Request') {
            tempMentorList = myMentorRequestList;
        }
        else {
            tempMentorList = notMyMentorList;
        }
        
        System.debug('tempMentorList: ' + tempMentorList);
        
        for (Mentor__c mentorRec : tempMentorList) {
            resultMentorList.add(mentorRec);
            
            if (resultMentorList.size() >= maxItemsInt) {
                break;
            }
        }
        
        System.debug('resultMentorList: ' + resultMentorList);
        
        return resultMentorList;
    }

    /**
     * Get contact information associated with the logged in user.
     *
     * @return:	Contact associated with the logged in user.
     * @since: 	1.0
     */
    @AuraEnabled
    public static Contact SERVER_getContactInfo() {
		return PORTAL_CommunityUtils.getContactInfoFromUser(UserInfo.getUserId());
    }

    /**
     * Update the application status of the mentee.
     *
     * @param: menteeRec    Mentee to be updated.
     * @param: status     	Status to update the application status to.
     * @since: 1.0
     */
    @AuraEnabled
    public static void SERVER_updateMenteeApplicationStatus(Mentee__c menteeRec, String status) {
        menteeRec.Application_Status__c = status;
        update menteeRec;
    }

    /**
     * Update the application status of the mentee.
     *
     * @param: mentorRecId  Record ID of the mentor.
     * @param: contactId    Record ID of the contact associated with the logged in user.
     * @return: Mentee associated with the mentor and logged in user (contact).
     * @since: 	1.0
     */
    @AuraEnabled
    global static Mentee__c SERVER_getMentee(Id mentorRecId, Id contactId) {
        
		Mentee__c mentee = [SELECT Id FROM Mentee__c WHERE Mentor__c = :mentorRecId AND Mentee__c = :contactId];

        System.debug('mentee: ' + mentee);
        
        return mentee;
    }    
}