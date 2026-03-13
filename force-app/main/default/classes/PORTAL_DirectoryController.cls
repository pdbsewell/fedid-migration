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
 * @author          PwC
 * @description     This class contains methods related to alumni directory.
 * @group           Service Class
 * @revision
 *	1.1 				12/08/2022 - Inderpal D        - SOQL vulnerability PENGAGE-2471
 *  1.0                 15/10/2019 - Ken Tang     	   - Initial version
 */

public without sharing class PORTAL_DirectoryController {

    /**
     * Get all the constituents to show in the alumni directory listing.
     *
     * @param: searchString     Search string to narrow down the constituent list.
     * @param: classYear   		Class year to narrow down the constituent list.
     * @param: constituentType	Whether to filter based on constituent type, such as 'Student' and 'FacultyStaff'.
     * @param: department   	Department to narrow down the constituent list.
     * @param: employer   		Filter based on the employee the constituent works for.
     * @return: 				List of constituents that satifies the various filtering criteria.
     * @since: 					1.0
     */
    
    @AuraEnabled
    public static List<Contact> SERVER_getContacts(String searchString,
                                                   String classYear,
                                                   String constituentType,
                                                   String department,
                                                   String employer) {
        //ucinn_ascendv2__Contact_Type__c
        System.debug('searchString: ' + searchString);
        System.debug('classYear: ' + classYear);
        System.debug('constituentType: ' + constituentType);
        System.debug('department: ' + department);                                                
        System.debug('employer: ' + employer);
                                        
        String soqlString = '';
        String whereClause = ''; 
                                                
        if (!String.isBlank(searchString)) {
            whereClause = ' WHERE Name LIKE \'%' + searchString + '%\'';
        }

		String whereClausePrefix = '';
                                                
        if (!String.isBlank(constituentType)) {
            if (String.isBlank(whereClause)) {
                whereClausePrefix = ' WHERE';
            }
            else {
                whereClausePrefix = ' AND';
            }

            if (constituentType == 'Student') {
            	whereClause = whereClause + whereClausePrefix + ' ucinn_ascendv2__Contact_Type__c INCLUDES (\'Current Student\')';
            }
            else if (constituentType == 'FacultyStaff') {
            	whereClause = whereClause + whereClausePrefix + ' ucinn_ascendv2__Contact_Type__c INCLUDES (\'Faculty Full-time\', \'Faculty Part-time\', \'Staff Full-time\', \'Staff Part-time\')';
            }
        }                             
        else if (!String.isBlank(classYear)) {
            if (String.isBlank(whereClause)) {
                whereClausePrefix = ' WHERE';
            }
            else {
                whereClausePrefix = ' AND';
            }
            
            whereClause = whereClause + whereClausePrefix + ' ucinn_ascendv2__Preferred_Class_Year__c = :classYear';
        }
                                                
        List<List<SObject>> soslResultList;

        if(String.isNotBlank(whereClause)){
            whereClause = whereClause.trim();
            // Remove the WHERE key word from the SOQL
            whereClause = whereClause.substring(whereClause.indexOf(' '), whereClause.length());
        }        

        if(!String.isBlank(employer)){
            soqlString = DynamicSoqlBuilder.getInstance()
                        .showSOQLStatement(true)
                        .setEnforced(false)
                        .setLimit(null) 
                        .querySObject('Contact')
                        .queryFields(new Set<String> {'Id', 'FirstName', 'LastName', 'Phone', 'Email', 'ucinn_ascendv2__Preferred_Class_Year__c'})
                        .subSelect('SELECT Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Post_Code__r.ucinn_ascendv2__School_1_Name_Formula__c FROM ucinn_ascendv2__Degree_Information_Contact__r')
                        .subSelect('SELECT Id, Name FROM ucinn_ascendv2__Affiliations_Contact__r WHERE ucinn_ascendv2__Constituent_Role__c = \'Employee\' AND ucinn_ascendv2__Status__c = \'Current\' AND ucinn_ascendv2__Account__c = :employer')
                        .subSelect('SELECT Id, ucinn_ascendv2__Service_Indicator_Value__r.Name FROM ucinn_ascendv2__Service_Indicators_Contact__r WHERE ucinn_ascendv2__Service_Indicator_Value__r.Name = \'AlumniDirectory\' AND ucinn_ascendv2__Is_Active__c = true')
                        .getQuery(whereClause);
        }else{
            soqlString = DynamicSoqlBuilder.getInstance()
                        .showSOQLStatement(true)
                        .setEnforced(false)
                        .setLimit(null) 
                        .querySObject('Contact')
                        .queryFields(new Set<String> {'Id', 'FirstName', 'LastName', 'Phone', 'Email', 'ucinn_ascendv2__Preferred_Class_Year__c'})
                        .subSelect('SELECT Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Post_Code__r.ucinn_ascendv2__School_1_Name_Formula__c FROM ucinn_ascendv2__Degree_Information_Contact__r')
                        .subSelect('SELECT Id, ucinn_ascendv2__Service_Indicator_Value__r.Name FROM ucinn_ascendv2__Service_Indicators_Contact__r WHERE ucinn_ascendv2__Service_Indicator_Value__r.Name = \'AlumniDirectory\' AND ucinn_ascendv2__Is_Active__c = true')
                        .getQuery(whereClause);
        }
        soqlString = soqlString + ' ORDER BY LastName';
        
        List<Contact> contactList = Database.query(soqlString);
        
        System.debug('contactList:size ' + contactList.size());
        System.debug('contactList: ' + contactList);
                                                
        List<Contact> tempContactList = new List<Contact>();

        // Need to filter out all contacts that don't want to be listed in the alumni directory                                       
		for (Contact cont : contactList) {
            System.debug('contact last name: ' + cont.LastName);
            System.debug('cont.ucinn_ascendv2__Service_Indicators_Contact__r: ' + cont.ucinn_ascendv2__Service_Indicators_Contact__r);
            
            if (cont.ucinn_ascendv2__Affiliations_Contact__r != null &&
                cont.ucinn_ascendv2__Service_Indicators_Contact__r.size() > 0) {
                    System.debug('removing contact: ' + contactList);
            }
            else {
				tempContactList.add(cont);
            }
        }

        System.debug('tempContactList: ' + tempContactList); 
                                                
        contactList = tempContactList;                                  
                                                
        List<Contact> contactListToReturn = new List<Contact>();
        
        if (!String.isBlank(employer)) {
            for (Contact cont : contactList) {
                System.debug('cont: ' + cont);
                System.debug('cont.ucinn_ascendv2__Affiliations_Contact__r: ' + cont.ucinn_ascendv2__Affiliations_Contact__r);
                
                if (cont.ucinn_ascendv2__Affiliations_Contact__r != null &&
                    cont.ucinn_ascendv2__Affiliations_Contact__r.size() > 0) {
                        contactListToReturn.add(cont);
                }
            }
        } else if (!String.isBlank(department)) {
            for (Contact cont : contactList) {
                System.debug('cont: ' + cont);
                System.debug('cont.ucinn_ascendv2__Degree_Information_Contact__r: ' + cont.ucinn_ascendv2__Degree_Information_Contact__r);
                
                if (cont.ucinn_ascendv2__Degree_Information_Contact__r != null &&
                    cont.ucinn_ascendv2__Degree_Information_Contact__r.size() > 0) {
                        
                    for (ucinn_ascendv2__Degree_Information__c degreeInfo : cont.ucinn_ascendv2__Degree_Information_Contact__r) {
                		//System.debug('degreeInfo.ucinn_ascendv2__Post_Code__r.ucinn_ascendv2__School_1_Name_Formula__c : ' + degreeInfo.ucinn_ascendv2__Post_Code__r.ucinn_ascendv2__School_1_Name_Formula__c);

                        if (degreeInfo.ucinn_ascendv2__Post_Code__r.ucinn_ascendv2__School_1_Name_Formula__c == department) {
                            contactListToReturn.add(cont);
                            break;
                        }
                    }
                }
            }
        }
        else {
            contactListToReturn = contactList;
        }
                                                
        System.debug('contactListToReturn:size ' + contactListToReturn.size());                          
        System.debug('contactListToReturn: ' + contactListToReturn);
            
        //soslResultList = [FIND :searchString IN ALL FIELDS  RETURNING Contact(Id, FirstName, LastName, Phone, Email)];
		return contactListToReturn;

/*
            //searchString = '%' + searchString + '%';
            //searchString = searchString + '*';

           List<Contact> contactList = [SELECT
                   Id, FirstName, LastName, Phone, Email
                   FROM Contact ORDER BY CreatedDate LIMIT 2000];

            System.debug('contactList: ' + contactList);
            //soslResultList = [FIND :searchString IN ALL FIELDS  RETURNING Contact(Id, FirstName, LastName, Phone, Email)];

            //return soslResultList[0];
        
        //return soslResultList[0];
        return contactList;
*/
    }

    /**
     * Get the top three countries the constituents are located at.
     *
     * @return:	Top three countries the constituents are located at.
     * @since: 	1.0
     */
    
    @AuraEnabled
    public static AggregateResult[] SERVER_getTopCountriesList() {

    	AggregateResult[] groupedResults = [SELECT MailingCountry, COUNT(Id)
                                            FROM Contact
                                            WHERE MailingCountry <> null
                                            GROUP BY MailingCountry
                                            ORDER BY Count(Id) DESC LIMIT 3];
        
		return groupedResults;
     }

    /**
     * Get the total constituent count.
     *
     * @return:	Total constituent count.
     * @since: 	1.0
     */
    
    @AuraEnabled
    public static Integer SERVER_getTotalAlumniCount() {

    	Integer count = [SELECT COUNT()
                         FROM Contact];
        
		return count;
     }

    /**
     * Get the top three industries the constituents work at.
     *
     * @return:	Top three industries the constituents work at.
     * @since: 	1.0
     */
    
    @AuraEnabled
    public static AggregateResult[] SERVER_getTopIndustriesList() {

    	AggregateResult[] groupedResults = [SELECT ucinn_ascendv2__Account__r.Name, COUNT(Id)
                                            FROM ucinn_ascendv2__Affiliation__c	
                                            WHERE ucinn_ascendv2__Status__c = 'Current' AND
                                                  ucinn_ascendv2__Organization_Role__c = 'Employer'
                                            GROUP BY ucinn_ascendv2__Account__r.Name
                                            ORDER BY Count(Id) DESC LIMIT 3];
        
		return groupedResults;
	}

    /**
     * Get contact information associated with the logged in user.
     *
     * @return:			Contact associated with the logged in user.
     * @since: 			1.0
     */
    @AuraEnabled
   	public static Contact SERVER_getMyContactInfo() {
        Id userId = UserInfo.getUserId();
        
        return PORTAL_CommunityUtils.getContactInfoFromUser(userId);
    }

    /**
     * Get constituent data to show in the alumni portal.
     *
     * @param: contactId	The constituent data to show.
     * @return: 			Constituent data.
     * @since: 				1.0
     */
    
    @AuraEnabled
   	public static Contact SERVER_getContactInfo(String contactId) {
               
        	String soqlString = 'SELECT Id, Name, FirstName, LastName, Phone, Email, Department, ucinn_ascendv2__Preferred_Class_Year__c,' +
                         '(SELECT Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Post_Code__r.ucinn_ascendv2__School_1_Name_Formula__c, ucinn_ascendv2__Major_Formula__c, ucinn_ascendv2__Degree__c FROM ucinn_ascendv2__Degree_Information_Contact__r), ' +
                         '(SELECT Id, Name FROM ucinn_ascendv2__Affiliations_Contact__r WHERE ucinn_ascendv2__Constituent_Role__c = \'Employee\' AND ucinn_ascendv2__Status__c = \'Current\') ' +
                         'FROM Contact ' +
                         'WHERE Id = :contactId';

        SObject contSobj = Database.query(soqlString);
        
        system.debug('contSobj: ' + contSobj);
        
		Contact cont = (Contact)contSobj;
        
        if (cont != null) {
            System.debug('cont.ucinn_ascendv2__Degree_Information_Contact__r: ' + cont.ucinn_ascendv2__Degree_Information_Contact__r);
            if (cont.ucinn_ascendv2__Degree_Information_Contact__r != null && !cont.ucinn_ascendv2__Degree_Information_Contact__r.isEmpty()) {
                system.debug('department: ' + cont.ucinn_ascendv2__Degree_Information_Contact__r[0].ucinn_ascendv2__Major_Formula__c);
                cont.Department = cont.ucinn_ascendv2__Degree_Information_Contact__r[0].ucinn_ascendv2__Major_Formula__c;
            }
        }

        return cont;
    }
    
    /**
     * Get constituent data to show in the alumni portal.
     *
     * @param: toContactId	The constituent to send a message to.
     * @param: subject		The subject of the message.
     * @param: body			The body of the message.
     * @since: 				1.0
     */
    
    @AuraEnabled
    public static void SERVER_sendDirectMessage(String toContactId, String subject, String body) {
        
        system.debug('toContactId: ' + toContactId);
        system.debug('subject: ' + subject);
        system.debug('body: ' + body);
        
        User toUsr = [SELECT Id, ContactId FROM User WHERE ContactId = :toContactId];
        
        // Define the FeedItemInput object to pass to postFeedElement
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
         
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = body;

        ConnectApi.TextSegmentInput textSegment;
        ConnectApi.MarkupBeginSegmentInput markupBeginSegment;
        ConnectApi.MarkupEndSegmentInput markupEndSegment;
        
        List<ConnectApi.MessageSegmentInput> messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
        markupBeginSegment.markupType = ConnectApi.MarkupType.Paragraph;
      	//messageSegments.add(markupBeginSegment);
        
        textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = body;
        messageSegments.add(textSegment);
        
        markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
        markupEndSegment.markupType = ConnectApi.MarkupType.Paragraph;
        //messageSegments.add(markupEndSegment);

        // The MessageBodyInput object holds the text in the post
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = messageSegments;

        feedItemInput.body = messageBodyInput;
         
        // The FeedElementCapabilitiesInput object holds the capabilities of the feed item.
        // For this feed item, we define a direct message capability to hold the member(s) and the subject.
         
        List<String> memberIds = new List<String>();
        memberIds.add(toUsr.Id);

        ConnectApi.DirectMessageCapabilityInput dmInput = new ConnectApi.DirectMessageCapabilityInput();
        dmInput.subject = subject;
        dmInput.membersToAdd = memberIds;
         
        ConnectApi.FeedElementCapabilitiesInput feedElementCapabilitiesInput = new ConnectApi.FeedElementCapabilitiesInput();
        feedElementCapabilitiesInput.directMessage = dmInput;
         
        feedItemInput.capabilities = feedElementCapabilitiesInput;
        
        if (!Test.isRunningTest()) {
            // Post the feed item. 
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        }
    }

    /**
     * Get the base URL of the community portal
     *
     * @return:	The base URL of the community portal.
     * @since: 	1.0
     */      
    @AuraEnabled
    public static String SERVER_getBaseUrl () {
		return PORTAL_CommunityUtils.getBaseUrl();
    } 
}