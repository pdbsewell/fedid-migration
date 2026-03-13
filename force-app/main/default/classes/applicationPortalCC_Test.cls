/*******************************************************************************
* @author       Ant Custodio
* @date         6.Apr.2017        
* @description  test class for applicationPortalCC
* @revision     
*******************************************************************************/
@isTest(isParallel=true)
private class applicationPortalCC_Test {
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         6.Apr.2017        
    * @description  test class for applicationPortalCC
    * @revision     
    *******************************************************************************/
    static testMethod void test_UserDetailsForm() {
        User communityUserRec = StudFirst_TestHelper.createCommunityUser();

        //only run if there is a Domestic Applicant Profile
        if (communityUserRec != null) {
            system.runAs(communityUserRec) {
                
                Test.startTest();
                createSampleData();

                //check if user is retrieved
                User userRecord = applicationPortalCC.retrieveUserDetails();
                system.assertEquals(communityUserRec.Id, userRecord.Id);

                //legacy method - TODO - remove soon
                applicationPortalCC.updateDetails();

                //retrieving picklist values
                List<String> salutationList = applicationPortalCC.retrieveSalutations();
                system.assert(!salutationList.isEmpty(), 'picklist field should have values');
                List<String> genderList = applicationPortalCC.retrieveGender();
                system.assert(!genderList.isEmpty(), 'picklist field should have values');
                List<String> citizenshipList = applicationPortalCC.retrieveCitizenship();
                system.assert(!citizenshipList.isEmpty(), 'picklist field should have values');
                List<String> residenceList = applicationPortalCC.retrieveResidence();
                system.assert(!residenceList.isEmpty(), 'picklist field should have values');
                List<String> residencystatusList = applicationPortalCC.retrieveResidencyStatus();
                system.assert(!residencystatusList.isEmpty(), 'picklist field should have values');
                List<String> institutionsList = applicationPortalCC.retrievePreviousInstitutions();
                system.assert(!institutionsList.isEmpty(), 'picklist field should have values');
                List<String> citizenshipTypeList = applicationPortalCC.retrieveCitizenshipTypeOptions();
                system.assert(!citizenshipTypeList.isEmpty(), 'picklist field should have values');
                List<String> campusOfStudyList = applicationPortalCC.retrieveCampusOfStudyOptions();
                system.assert(!campusOfStudyList.isEmpty(), 'picklist field should have values');
                List<String> stateList = applicationPortalCC.retrieveState();
                system.assert(!stateList.isEmpty(), 'picklist field should have values');
                List<String> countriesList = applicationPortalCC.retrieveCountries();
                system.assert(!countriesList.isEmpty(), 'picklist field should have values');

                Callista_Citizenship_Type__c selectedCitizenshipType = applicationPortalCC.retrieveCitizenshipTypeByName('DOM-AUS');
                system.assertEquals('I am an Australian citizen (with or without dual citizenship)', selectedCitizenshipType.Explanation__c , 'Callista_Citizenship_Type__c not created on initialise');

                Boolean isPostcodeFound = applicationPortalCC.findPostCodeNumber('3000');
                system.assert(isPostcodeFound , 'Australian_Postcodes__c not created on initialise');

                //user updates his details using the communities
                userRecord.FirstName = 'UpdatedFirst';
                userRecord.LastName = 'UpdatedLast';
                userRecord.Email = 'email@test.edu';
                userRecord.App_Birthdate__c = date.newInstance(1993, 1, 1);

                //untoggles the 'previously studied' box
                applicationPortalCC.removeValuesWhenUnticked(userRecord);
                system.assertEquals('', userRecord.App_Previous_Monash_ID__c);
                
                Boolean hasError = false;
                try {
                    //exception check - invalid picklist value
                    userRecord.App_Address_Type__c = 'RESTRICTED PICKLIST';
                    //clicks on update
                    
                    
                    applicationPortalCC.updateUserRecord(userRecord, null);
                } catch (Exception ex) {
                    hasError = true;
                }
                system.assert(hasError, 'Valid Picklist value');
                
                //valid address type
                userRecord.App_Address_Type__c = 'POSTAL';
                //clicks on update
                applicationPortalCC.updateUserRecord(userRecord, null);

                //check if it was updated
                system.assertEquals('UpdatedFirst', userRecord.FirstName);
                
                test.stopTest(); // force queueable on User trigger to execute

                //check if the beforeUpdate trigger fired and updated the related contact 
                //class that runs the update: UserServices.updateAssociatedContact
                Contact contactToCheck = [SELECT Id, FirstName 
                                            FROM Contact 
                                           WHERE Id =: communityUserRec.ContactId];
                
                //Removed assert as personal details are no longer copied from User to Contact
                //system.assertEquals(contactToCheck.FirstName , userRecord.FirstName);
                
                //mock insert an application for the method to return true
                Application__c newApp = StudFirst_TestHelper.createApplication(contactToCheck);
                newApp.Status__c = 'Submitted';
                insert newApp;
                system.assert(applicationPortalCC.hasSubmittedApplication(contactToCheck.Id), 'application is not submitted');
            }
        }       
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         6.Apr.2017        
    * @description  creates all sample data required
    * @revision     
    *******************************************************************************/
    static void createSampleData () {
        Callista_Citizenship_Type__c citizenshipType = StudFirst_TestHelper.createCitizenshipTypeRecord();
        insert citizenshipType;

        Australian_Postcodes__c ausPostal = StudFirst_TestHelper.createAustralicanPostcodeRecord();
        insert ausPostal;
    }
    
}