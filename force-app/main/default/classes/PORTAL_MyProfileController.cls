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
 * Handles methods related to the logged in constituent profile information.
 *
 * @author:  Ken Tang
 * @version: 1.0
 * @since:   1.0
 */
global without sharing class PORTAL_MyProfileController {

    // Used for test class only. Needed because we can't use Custumer Community User profile
    // to access Opportunity, etc...
    public static Contact testContact;
    
    global class UserDataInfo {
        String userId;
        String contactId;
    }

    /**
     * Get the logged in constituent profile information, including service indicators.
     *
     * @return: Constituent profile information, along with service indicators.
     * @since:  1.0
     */
    @AuraEnabled
    global static Map<String, Object> SERVER_getUserInfo() {
        Boolean isDirectorySearch = false;
        Boolean isNewsletter = false;

        Id userId = UserInfo.getUserId();

        User usr = [SELECT Id,
                           ContactId
                    FROM User
                    WHERE Id = :userId];
        
        System.debug('usr: ' + usr);
        
        Id contactId = usr.ContactId;
        
        if (Test.isRunningTest()) {
            contactId = testContact.Id;
        }           
        
        Contact cont = [SELECT Id, Name, FirstName, LastName, ucinn_ascendv2__Personal_Email__c, MobilePhone, MailingAddress, MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode
                        FROM Contact
                        WHERE Id = :contactId];
        
        List<ucinn_ascendv2__Service_Indicator__c> serviceIndicators = [SELECT id,
                                                                             ucinn_ascendv2__Service_Indicator_Value__r.Name,
                                                                             ucinn_ascendv2__Is_Active__c,
                                                                             ucinn_ascendv2__Contact__c
                                                                        FROM ucinn_ascendv2__Service_Indicator__c
                                                                        WHERE ucinn_ascendv2__Contact__c = :contactId AND
                                                                              ucinn_ascendv2__Is_Active__c = true];
        
        system.debug('serviceIndicators: ' + serviceIndicators);
        
        for (ucinn_ascendv2__Service_Indicator__c indicator : serviceIndicators) {
            if (indicator.ucinn_ascendv2__Service_Indicator_Value__r.Name == 'AlumniDirectory') {
                isDirectorySearch = true;
            }
            
            if (indicator.ucinn_ascendv2__Service_Indicator_Value__r.Name == 'AlumniNewsletter') {
                isNewsletter = true;
            }
        }
        
        
        Map<String, Object> resultMap = new Map<String, Object>();
        resultMap.put('contact', cont);
        
        resultMap.put('isDirectorySearch', isDirectorySearch);
        resultMap.put('isNewsletter', isNewsletter);

        return resultMap;
    }

    /**
     * Save the logged in constituent profile information, including the service indicators.
     *
     * @param: updatedContact       Profile information to update for the constituent.
     * @param: isDirectorySearch    Directory search service indicator.
     * @param: isNewsletter         Newsletter service indicator.
     * @since:              1.0
     */
    @AuraEnabled
    global static void SERVER_saveUserInfo(Contact updatedContact, Boolean isDirectorySearch, Boolean isNewsletter) {
        
        Boolean isDirectorySearchFound = false;
        Boolean isNewsletterFound = false;
        
        List<ucinn_ascendv2__Service_Indicator__c> serviceIndicatorsToUpdate = new List<ucinn_ascendv2__Service_Indicator__c>();
        
        System.debug('updatedContact: ' + updatedContact);
        
        update updatedContact;
        
        List<ucinn_ascendv2__Service_Indicator__c> serviceIndicators = [SELECT id,
                                                                             ucinn_ascendv2__Service_Indicator_Value__r.Name,
                                                                             ucinn_ascendv2__Is_Active__c,
                                                                             ucinn_ascendv2__Contact__c
                                                                        FROM ucinn_ascendv2__Service_Indicator__c
                                                                        WHERE ucinn_ascendv2__Contact__c = :updatedContact.Id];
        
        List<ucinn_ascendv2__Service_Indicator_Value__c> directorSearchValueList = [SELECT Id, Name
                                                                                    FROM ucinn_ascendv2__Service_Indicator_Value__c
                                                                                    WHERE Name = 'AlumniDirectory'];
        
        List<ucinn_ascendv2__Service_Indicator_Value__c> newsletterValueList = [SELECT Id, Name
                                                                          		FROM ucinn_ascendv2__Service_Indicator_Value__c
                                                                          		WHERE Name = 'AlumniNewsletter'];  
        
        system.debug('serviceIndicators: ' + serviceIndicators);
        
        for (ucinn_ascendv2__Service_Indicator__c indicator : serviceIndicators) {
            if (indicator.ucinn_ascendv2__Service_Indicator_Value__r.Name == 'AlumniDirectory') {
                isDirectorySearchFound = true;
                
                indicator.ucinn_ascendv2__Is_Active__c = isDirectorySearch;
                
                serviceIndicatorsToUpdate.add(indicator);
            }
            
            if (indicator.ucinn_ascendv2__Service_Indicator_Value__r.Name == 'AlumniNewsletter') {
                isNewsletterFound = true;
                
                indicator.ucinn_ascendv2__Is_Active__c = isNewsletter;
                
                serviceIndicatorsToUpdate.add(indicator);                
            }
        }
        
        update serviceIndicatorsToUpdate;
        
        if (!isDirectorySearchFound && !directorSearchValueList.isEmpty()) {
            ucinn_ascendv2__Service_Indicator__c indicator = new ucinn_ascendv2__Service_Indicator__c();
            indicator.ucinn_ascendv2__Is_Active__c = isDirectorySearch;
            indicator.ucinn_ascendv2__Contact__c = updatedContact.Id;
            indicator.ucinn_ascendv2__Service_Indicator_Value__c = directorSearchValueList.get(0).Id;
            
            insert indicator;
        }
        
        if (!isNewsletterFound && !newsletterValueList.isEmpty()) {
            ucinn_ascendv2__Service_Indicator__c indicator = new ucinn_ascendv2__Service_Indicator__c();
            indicator.ucinn_ascendv2__Is_Active__c = isNewsletter;
            indicator.ucinn_ascendv2__Contact__c = updatedContact.Id;
            indicator.ucinn_ascendv2__Service_Indicator_Value__c = newsletterValueList.get(0).Id;
            
            insert indicator;
        }        
    }    
}