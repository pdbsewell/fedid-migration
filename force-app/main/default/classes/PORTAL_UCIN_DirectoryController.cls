/**
 * @author Charlie Park, UC Innovation
 * @date 10/1/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Controller for Directory  
 * Modifications Log 
 * Date         Author          Modification
 * 2019-10-01   Chaldrin Cruz   Initial Version
 * 2022-08-04   Inderpal Dhan   Security Fix PENGAGE-2414
 */
public without sharing class PORTAL_UCIN_DirectoryController {
    /**
    * Get contact information based on passed in ID
    *
    * @return:			Contact Id to query.
    * @since: 			1.0
    */
    @AuraEnabled
    public static Contact SERVER_getContactInfo(string contactId) {
        List<Contact> contactList = [SELECT ID, Name, Volunteer_Areas_of_Interest__c, Volunteer_Skills__c, 
                            (SELECT ID, Account__r.Name, Position__c
                                FROM Affiliations__r 
                                WHERE Is_Primary__c = true AND Is_Active__c = true AND (recordtype.developername = 'Employee' OR recordtype.developername = 'Industry_Contact') LIMIT 1),
                            (SELECT Id, Other_Qualification__c, Qualification__r.Qualification_Name__c, Date_Achieved__c FROM Contact_Qualifications__r 
                                WHERE Institution_Name__c = 'Monash University' AND Obtained_Status__c = 'MONASH-OBTAINED' ORDER BY Date_Achieved__c DESC),
                            (SELECT Id, Directory_Opt_In__c, Messaging_Opt_In__c, AboutMe FROM Users WHERE profile.Name = 'Customer Community General User' LIMIT 1)
                            FROM Contact WHERE Id =: contactId];

        if (!contactList.isEmpty()) {
            return contactList[0];
        }

        return null;
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
        
        return PORTAL_UCIN_CommunityUtils.getContactInfoFromUser(userId);
    }

    /**
    * Get the base URL of the community portal
    *
    * @return:	The base URL of the community portal.
    * @since: 	1.0
    */      
    @AuraEnabled
    public static String SERVER_getBaseUrl () {
        return PORTAL_UCIN_CommunityUtils.getBaseUrl();
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
        system.debug('dmInput' + dmInput);
        
        ConnectApi.FeedElementCapabilitiesInput feedElementCapabilitiesInput = new ConnectApi.FeedElementCapabilitiesInput();
        feedElementCapabilitiesInput.directMessage = dmInput;
        
        feedItemInput.capabilities = feedElementCapabilitiesInput;
        system.debug('feedItemInput: ' + feedItemInput);
        
        if (!Test.isRunningTest()) {
            // Post the feed item. 
            system.debug('Network.getNetworkId()' + Network.getNetworkId());
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        }
    }
    
    public class SearchCriteria {
        @AuraEnabled
        public String searchRule {get; set;}
        @AuraEnabled
        public String searchForSelected {get; set;}
        @AuraEnabled
        public List<String> value {get; set;}
    }
    
    /**
    * Query all contacts
    *
    * @param searchText         name search by this string
    * @param searchForSelected  category of filter
    * @param filterSearchText   search text for the specific filter category
    * @param sortedByApiName    Sort by in SOQL
    * @param sortDirection      asc or desc
    * @param itemsPerPage       items to show per page. Controls limit in soql
    * @param offset             Offset to control pagination. Used so we don't need to actually query the whole contact list
    * @param reverseList        Determine direction
    * @param contactId          latest contactId on current page (for pagination)
    * @param sortedValue        Latest value of the sorted field on current page (for pagination)
    * @return:			        Map containing total number of contacts and contact list
    * @since: 			        1.0
    */
    @AuraEnabled
    public static Map<String, Object> SERVER_getContacts(String searchText, 
                                                                 String searchForSelected,
                                                                 String filterSearchText,
                                                                 String sortedByApiName, 
                                                                 String sortDirection,
                                                                 Integer itemsPerPage, 
                                                                 Integer offset,
                                                                 Boolean reverseList,
                                                                 String contactId,
                                                                 String sortedValue) {
    	String soqlString = '';
        String whereClause = '';
        String employmentClause = '';
        Set<Id> contactIds = null;
        
        if (!String.isBlank(searchText)) {
            whereClause = ' WHERE ';
            // split searchText by whitespace
            List<String> searchList = searchText.split(' ');
            List<String> whereClauseList = new List<String>();

            for (String eachSearchText: searchList) {
                whereClauseList.add('Name LIKE \'%' + eachSearchText + '%\'');
            }
            whereClause += String.join(whereClauseList, ' AND ');
            
            //whereClause = ' WHERE Name LIKE \'%' + searchText + '%\'';
        }
        
        String whereClausePrefix = '';

        if (String.isBlank(whereClause)) {
            whereClausePrefix = ' WHERE ';
        } else {
            whereClausePrefix = ' AND ';
        }

        // Only bring in Alumni constituents
        whereClause = whereClause + whereClausePrefix + ' Contact_Profile__c includes (\'Alumni\')';

        // Exclude constituents who has a user record with directory opt in set to false. 
        //whereClause += ' AND ID NOT IN (SELECT ContactId FROM User WHERE Directory_Opt_In__c = false)';

        whereClause += getFilterWhereClause(searchForSelected, filterSearchText);

        // Get total number of constituents in query
        Integer totalNumberOfContacts = Database.countQuery('SELECT COUNT() FROM Contact ' + whereClause);
        Map<String, Object> resultMap = new Map<String, Object>();
        resultMap.put('count', totalNumberOfContacts);

        if (reverseList == true) {
            if (sortDirection == 'ASC') {
                sortDirection = 'DESC';
            } else {
                sortDirection = 'ASC';
            }
        }

        String orderClause = ' ORDER BY ' + sortedByApiName + ' ' + sortDirection + ', id ';

        if (reverseList == true) {
            orderClause = orderClause + ' DESC ';
        }

        // Paginate based on non unique field
        if (!String.isBlank(contactId) && !String.isBlank(sortedValue)) {
            if (String.isBlank(whereClause)) {
                whereClausePrefix = ' WHERE ';
            } else {
                whereClausePrefix = ' AND ';
            }

            String paginatedWhereClause = whereClause + whereClausePrefix + sortedByApiName + ' = \'' + sortedValue + '\' ';

            // Ensure order if we're going backwards
            if (reverseList == true) {
                paginatedWhereClause = paginatedWhereClause + ' AND id < \'' + contactId + '\' ';
            } else {
                paginatedWhereClause = paginatedWhereClause + ' AND id > \'' + contactId + '\' ';
            }

            Integer queryCount = Database.countQuery('SELECT COUNT() FROM Contact ' + paginatedWhereClause);
            Integer paginatedOffset = 0;

            // Second query should start from beginning if you can offset inside of the first query
            if (queryCount <= offset) {
                paginatedOffset = offset - queryCount;
            }

            String paginatedSoqlString = paginatedWhereClause.trim() + orderClause + ' LIMIT ' + itemsPerPage + ' OFFSET ' + offset;
            paginatedSoqlString = paginatedSoqlString.substring(paginatedSoqlString.indexOf(' '), paginatedSoqlString.length());
            String soql = DynamicSoqlBuilder.getInstance()
                        .showSOQLStatement(true)
                        .setEnforced(false)
                        .querySObject('Contact')
                        .queryFields(new Set<String> {'Id','FirstName','LastName'})
                        .subSelect('SELECT Id, Other_Qualification__c, Qualification__r.Qualification_Name__c, Date_Achieved__c FROM Contact_Qualifications__r WHERE Institution_Name__c = \'Monash University\' AND Obtained_Status__c = \'MONASH-OBTAINED\' ORDER BY Date_Achieved__c DESC')
                        .subSelect('SELECT Id, Account__r.Industry FROM Affiliations__r WHERE Is_Primary__c = true AND (recordtype.developername = \'Employee\' OR recordtype.developername = \'Industry_Contact\') LIMIT 1')
                        .subSelect('SELECT Id, Directory_Opt_In__c, Messaging_Opt_In__c FROM Users WHERE Profile.Name = \'Customer Community General User\' LIMIT 1')
                        .getQuery(paginatedSoqlString);
            List<Contact> contactList = Database.query(soql);

            // Return list if we have enough contacts
            if (contactList.size() == itemsPerPage) {
                resultMap.put('contactList', contactList);
                return resultMap;
            }

            // Query for remaining contacts
            Integer itemsLeft = itemsPerPage - contactList.size();

            // Ensure correct order depending on sort Direction
            if (sortDirection == 'ASC') {
                paginatedWhereClause = whereClause + whereClausePrefix + sortedByApiName + ' > \'' + sortedValue + '\'';
            } else {
                paginatedWhereClause = whereClause + whereClausePrefix + sortedByApiName + ' < \'' + sortedValue + '\''; 
            }

            paginatedSoqlString = paginatedWhereClause.trim() + orderClause + ' LIMIT ' + itemsLeft + ' OFFSET ' + paginatedOffset;
            paginatedSoqlString = paginatedSoqlString.substring(paginatedSoqlString.indexOf(' '), paginatedSoqlString.length());
            soql = DynamicSoqlBuilder.getInstance()
                        .showSOQLStatement(true)
                        .setEnforced(false)
                        .setLimit(null) 
                        .querySObject('Contact')
                        .queryFields(new Set<String> {'Id','FirstName','LastName'})
                        .subSelect('SELECT Id, Other_Qualification__c, Qualification__r.Qualification_Name__c, Date_Achieved__c FROM Contact_Qualifications__r WHERE Institution_Name__c = \'Monash University\' AND Obtained_Status__c = \'MONASH-OBTAINED\' ORDER BY Date_Achieved__c DESC')
                        .subSelect('SELECT Id, Account__r.Industry FROM Affiliations__r WHERE Is_Primary__c = true AND (recordtype.developername = \'Employee\' OR recordtype.developername = \'Industry_Contact\') LIMIT 1')
                        .subSelect('SELECT Id, Directory_Opt_In__c, Messaging_Opt_In__c FROM Users WHERE profile.Name = \'Customer Community General User\' LIMIT 1')
                        .getQuery(paginatedSoqlString);
            List<Contact> additionalContacts = Database.query(soql);
            contactList.addAll(additionalContacts);

            resultMap.put('contactList', contactList);
            return resultMap;
        }

        System.debug(whereClause);
        System.debug(orderClause);

        whereClause = whereClause.trim() + orderClause + ' LIMIT ' + itemsPerPage + ' OFFSET ' + offset;
        //Remove the WHERE word from the WHERE clause as it is added in the DynamicSOQLBuilder method
        whereClause = whereClause.substring(whereClause.indexOf(' '), whereClause.length());
        String soql = DynamicSoqlBuilder.getInstance()
                        .showSOQLStatement(true)
                        .setEnforced(false)
                        .setLimit(null)
                        .querySObject('Contact')
                        .queryFields(new Set<String> {'Id','FirstName','LastName'})
                        .subSelect('SELECT Id, Other_Qualification__c, Qualification__r.Qualification_Name__c, Date_Achieved__c FROM Contact_Qualifications__r WHERE Institution_Name__c = \'Monash University\' AND Obtained_Status__c = \'MONASH-OBTAINED\' ORDER BY Date_Achieved__c DESC')
                        .subSelect('SELECT Id, Account__r.Industry FROM Affiliations__r WHERE Is_Primary__c = true AND (recordtype.developername = \'Employee\' OR recordtype.developername = \'Industry_Contact\') LIMIT 1')
                        .subSelect('SELECT Id, Directory_Opt_In__c, Messaging_Opt_In__c FROM Users WHERE profile.Name = \'Customer Community General User\' LIMIT 1')
                        .getQuery(whereClause);
        List<Contact> contactList = Database.query(soql);
        resultMap.put('contactList', contactList);
        return resultMap;
    }

    /**
    * Get filter string based on the filter selected
    *
    * @param searchForSelected          selected filter
    * @param filterSearchText           search text for this specific filter
    * @return:			                SOQL where clause
    * @since: 			                1.0
    */
    private static string getFilterWhereClause(string searchForSelected, string filterSearchText) {
        String filterString = '';

        if (!String.isBlank(filterSearchText)) {
            if (searchForSelected.equals('Class Year')) {
                filterString += ' AND ID IN (SELECT Contact__c FROM Contact_Qualification__c WHERE CALENDAR_YEAR(Date_Achieved__c) = ' + filterSearchText +  
                + ' AND Institution_Name__c = \'Monash University\' AND Obtained_Status__c = \'MONASH-OBTAINED\') ';
            } else if (searchForSelected.equals('Industry')) {
                filterString += ' AND ID IN (SELECT Contact__c FROM Affiliation__c WHERE Account__r.Industry LIKE \'%' + filterSearchText + '%\') ';
            } else if (searchForSelected.equals('Country/State')) {
                filterString += ' AND (MailingCountry LIKE \'%' + filterSearchText + '%\' OR MailingState LIKE \'%' + filterSearchText + '%\') ';
            } else if (searchForSelected.equals('Degree')) {
                filterString += ' AND ID IN (SELECT Contact__c FROM Contact_Qualification__c WHERE (Qualification__r.Qualification_Name__c LIKE \'%' + filterSearchText + '%\' '
                            + 'OR Other_Qualification__c LIKE \'%' + filterSearchText + '%\') '
                            + 'AND Institution_Name__c = \'Monash University\' AND Obtained_Status__c = \'MONASH-OBTAINED\') ';
            }
        }

        return filterString;
    }
}