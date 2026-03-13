/**
 * @author          Mark Johnson: UC Innovation
 * @description    	This override class is to provide custom logic for Monash to ascend's Manual Merge Interim component.
 * @revision        10/09/2019 - Mark Johnson - Initial version
 * Modifications Log 
 * Ver   Date         Author          	Modification
 * 1.1   14-12-2022   Inderpal Dhanoa   PENGAGE-2597 Remove decommissioned methods not needed
 * 1.0   10-09-2019   Mark Johnson     Initial Version
 * 
 */

global inherited sharing class EngageManualMergeOverride extends ucinn_ascendv2.ascend_BIO_ManualMergeBase {

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Static global describe, increases processing time. We allow override here, so that ascend can process fields and objects with the same name within managed package.
					This is a workaround for the "https://help.salesforce.com/articleView?id=000181257&language=en_US&r=https%3A%2F%2Fwww.google.com%2F&type=1" issue,
					Which applies to queries, and also global describe within package.
	*******************************************************************************/
    global override Map<String, Schema.SObjectType> getGlobalDescribe() {
        if (globalDescribe == null) {
            return Schema.getGlobalDescribe();
        } else {
            return globalDescribe;
        }
    }
    
    global override SObject createNewSObjectFromDescribe(String sObjectName) {
        return globalDescribe.get(sObjectName).newSObject();
    }
    
    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  For merging Monash specific fields/cards in manual merge interim component.
					Cards hold specific logic about an object rleated to a contact. Tabs can hold many cards.
	*******************************************************************************/
    global override void performInterimCardMerge() {
        for (TabInfo tab : tabsWithCardsToMerge) {
            if (tab.tabDeveloperName == 'Monash_Address') {
                processMonashAddressTabDefault(tab);
            } else if (tab.tabDeveloperName == 'Monash_Email') {
                processMonashEmailTabDefault(tab);
            } else if (tab.tabDeveloperName == 'Monash_Phone') {
                processMonashPhoneTabDefault(tab);
            } else {
                processDefaultLogic(tab);
            }
        }
    }


    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Manipulate the types that the interim will be taking in from RE for proper processing into Engage Environment.
					Cards can have 
					This override function is for manipulating default logic. Value mappings from Travis (ERDA)
	*******************************************************************************/
    global void processMonashAddressTabDefault(TabInfo tab) {
        List<SObject> addressList = performCardMergeDefaultLogicForRelatedListTarget(tab);

        for (SObject address : addressList) {
            String addressType = (String) address.get('Type__c');
            String newAddressType;
            String newAddressClassification;

            if (addressType == 'Business' || addressType == 'Ministerial' || addressType == 'Electorate' || addressType == 'GovernmentAPH') {
                newAddressType = null;
                newAddressClassification = 'Business';
            } else if (addressType == 'Home') {
                newAddressType = null;
                newAddressClassification = 'Private';
            } else if (addressType == 'Mailing') {
                newAddressType = 'Mailing';
                newAddressClassification = 'Private';
            } else {
                newAddressClassification = 'Private';
            }

            address.put('Type__c', newAddressType);
            address.put('Classification__c', newAddressClassification);

            EngageDedupeUtils.fixCreationDate(address);
        }

        sObjectsToInsert.addAll(addressList);
    }


    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Override to fix creation date on manual merge of emails
	*******************************************************************************/
    global void processMonashEmailTabDefault(TabInfo tab) {
        List<SObject> emailList = performCardMergeDefaultLogicForRelatedListTarget(tab);

        for (SObject email : emailList) {
            EngageDedupeUtils.fixCreationDate(email);
        }

        sObjectsToInsert.addAll(emailList);
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Override to fix Phone types and creation date on manual merge of emails
	*******************************************************************************/
    global void processMonashPhoneTabDefault(TabInfo tab) {
        List<SObject> phoneList = performCardMergeDefaultLogicForRelatedListTarget(tab);

        for (SObject phone : phoneList) {

            String phoneType = (String) phone.get('Type__c');
            String newPhoneType;
            String newPhoneClassification;

            if (phoneType == 'Undefined' || phoneType == 'Assistant') {
                newPhoneClassification = 'Business';
            } else {
                newPhoneClassification = 'Private';
            }

            phone.put('Classification__c', newPhoneClassification);

            EngageDedupeUtils.fixCreationDate(phone);
        }

        sObjectsToInsert.addAll(phoneList);
    }

    /*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         10/9/2019 
	* @description  Process default logic for fields and junction objects added through custom metadata type.
	*******************************************************************************/    
    global void processDefaultLogic(TabInfo tab) {
        if (tab.targetTabType == 'Info') {
            performCardMergeDefaultLogicForInfoTarget(tab);

        } else if (tab.targetTabType == 'Related List' && tab.parentObjectLookupAPIName != null) {
            
            //When attempting to merge junction objects.
            List<SObjectJunctionWrapper> sobjectWrapperList = performCardMergeDefaultLogicForRelatedListTargetWithJunction(tab);
            List<SObject> parentSObjects = preProcessJunctionInfo(tab, sobjectWrapperList);
            
            sObjectsToInsertFirst.addAll(parentSObjects);
            sobjectJunctionWrapperList.addAll(sobjectWrapperList);

        } else if (tab.targetTabType == 'Related List') {
            
            //When attempting to merge standard objects without junctions.
            sObjectsToInsert.addAll(performCardMergeDefaultLogicForRelatedListTarget(tab));
        }
    }
}