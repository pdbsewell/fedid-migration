/**
 * Test Class for CSV Parser
 * 
 * @author Mark Johnson - UC Innovation
 * @date         12/03/2019    
 * @revision
 */

@isTest(isParallel=false)
private class EngageCSVParserController_Test {

    @isTest
    public static void testFetchingCustomMetadataMappings() {
        Map<String, String> eventMemberToContactIDMapping = EngageCSVParserController.getEventMemberToContactIDMapping();
        Map<String, String> interimFieldMap = EngageCSVParserController.getInterimFieldMapping();
        List<String> requiredFields = EngageCSVParserController.getRequiredFields();
        List<String> fieldsOnTemplate = EngageCSVParserController.getFieldsOnTemplate();

        System.assertEquals(false, eventMemberToContactIDMapping.isEmpty());
        System.assertEquals(false, requiredFields.isEmpty());
        System.assertEquals(false, interimFieldMap.isEmpty());
        System.assertEquals(false, fieldsOnTemplate.isEmpty());
    }

    @isTest
    public static void testUploadingCSVNoConstituents() {

        Profile p = [SELECT Id FROM Profile WHERE Name='ascend Admin User'];

        User u2 = new User( Alias = 'newUser', 
                            Email='newuser@testorg.com',
                            EmailEncodingKey='UTF-8', 
                            LastName='Testing', 
                            LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', 
                            ProfileId = p.Id,
                            TimeZoneSidKey='America/Los_Angeles', 
                            UserName='newuser@testorg.com123');

        insert u2;

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ascend_Event_Admin'];
    
        insert new PermissionSetAssignment(AssigneeId = u2.id, PermissionSetId = ps.Id);

        System.runAs(u2) {

            Id erdaCampaignRecordTypeID = Campaign.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('ERDA_Event').getRecordTypeID();

            Campaign campaign = new Campaign(Name = 'ERDA Test Event', RecordTypeId = erdaCampaignRecordTypeID);

            insert campaign;

           /* String jsonInput =  '[["Johnson","Mark","MD","Dr.","Wells Fargo","CEO","1341 San Juan Ave","Apt H3","CA","21123","USA","8181811621","Tsaw@gmail.com","Y","Y","N","Y","2/2/2019","Confirmed","5/2/2019",null,null,"16117171711",null], ' + 
                                '["Smith","Mary",null,"Ms.",null,null,"10538 Monogram Ave",null,"CA","32136","USA","1262131723","laca@gmail.com","N","Y","Y","Y","3/2/2019","CheckedIn","6/2/2019",null,"1251","121216112","C-A04713750"], ' + 
                                '["James","Haley","DDS","Dr.","Google","Software Engineer","1644 Newport Blvd","Apt 1211A","CA","23212","USA","7123124122","ghills@yahoo.com","Y","Y","Y","Y","2/2/2019","Declined","8/2/2019",null,"161111",null,null], ' +
                                '["Corvera","Marco","Esq.","Mr.",null,null,"125161 Melbourne Street",null,"Victoria","6121621","Australia","66232172233","Gen@ge.com","N","Y","Y","Y","2/2/2019","Unconfirmed",null,null,null,"21511",null], ' +
                                '["Herrera","Billy",null,null,null,null,"125161 Billy Street",null,"Victoria","6121621","Australia","1251211","TestEmail@ge.com","N","Y","Y","Y","2/2/2019","Unconfirmed",null,null,null,null,null]]';*/
            
            String jsonInput =  '[["Johnson","Mark","MD","Dr.","Wells Fargo","CEO","1341 San Juan Ave","Apt H3","CA","21123","USA","8181811621","Tsaw@gmail.com","Y","Y","N","Y","2/2/2019","Confirmed","5/2/2019","1234567",null,"123456","These are notes","1234"], ' + 
                                '["Smith","Mary",null,"Ms.",null,null,"10538 Monogram Ave",null,"CA","32136","USA","1262131723","laca@gmail.com","N","Y","Y","Y","3/2/2019","CheckedIn","6/2/2019",null,"121216112","12121611212","Test Notes","7665"], ' + 
                                '["James","Haley","DDS","Dr.","Google","Software Engineer","1644 Newport Blvd","Apt 1211A","CA","23212","USA","7123124122","ghills@yahoo.com","Y","Y","Y","Y","2/2/2019","Declined","8/2/2019",null,"161111",null,null,"87878"], ' +
                                '["Corvera","Marco","Esq.","Mr.",null,null,"125161 Melbourne Street",null,"Victoria","6121621","Australia","66232172233","Gen@ge.com","N","Y","Y","Y","2/2/2019","Unconfirmed",null,null,null,"21511",null,"8788"], ' +
                                '["Herrera","Billy",null,null,null,null,"125161 Billy Street",null,"Victoria","6121621","Australia","1251211","TestEmail@ge.com","N","Y","Y","Y","2/2/2019","Unconfirmed",null,null,null,null,null,"766554"]]';


            //Test Case 1: Attempt to create 5 event members on the campaign. Should create 5 interims as org contains no constituents.
            String errorMessage = EngageCSVParserController.createEventMembers(jsonInput, campaign.Id);
            System.assertEquals('', errorMessage, 'An error has occurred');

            List<Campaign> guestList = [SELECT Id FROM Campaign WHERE Parent_ERDA_Event__c =: campaign.Id];
            System.assertEquals(1, guestList.size(), 'A guest list should be associated with the parent event.');

            Integer associatedInterimsCount = [SELECT COUNT() FROM ucinn_ascendv2__Interim__c WHERE Guest_List__c =: guestList[0].Id];
            System.assertEquals(5, associatedInterimsCount, 'Interims should be created for members that are input without corresponding constituents in the system.');
        }
    }

    @isTest
    public static void testUploadingCSVExistingConstituents() {
        Profile p = [SELECT Id FROM Profile WHERE Name='ascend Admin User'];

        User u2 = new User( Alias = 'newUser', 
                            Email='newuser@testorg.com',
                            EmailEncodingKey='UTF-8', 
                            LastName='Testing', 
                            LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', 
                            ProfileId = p.Id,
                            TimeZoneSidKey='America/Los_Angeles', 
                            UserName='newuser@testorg.com123');

        insert u2;

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ascend_Event_Admin'];
    
        insert new PermissionSetAssignment(AssigneeId = u2.id, PermissionSetId = ps.Id);

        System.runAs(u2) {

            Id erdaCampaignRecordTypeID = Campaign.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('ERDA_Event').getRecordTypeID();

            Campaign campaign = new Campaign(Name = 'ERDA Test Event', RecordTypeId = erdaCampaignRecordTypeID);

            insert campaign;

            List<Contact> contactList = new List<Contact>{  new Contact(LastName = 'CRM', ucinn_ascendv2__Donor_Id__c='123456'), 
                                                            new Contact(LastName = 'STUDENT', Person_ID_unique__c = '121216112')};


            insert contactList;

            //CRM_ID is system generated. Therefore we cannot assign a CRM_ID.
            List<Contact> crmContact = [SELECT CRM_Id__c FROM Contact WHERE Name = 'CRM'];
            String crmId = crmContact[0].CRM_Id__c;
            system.debug('crmidd'+ crmId);

            String jsonInput =  '[["Johnson","Mark","MD","Dr.","Wells Fargo","CEO","1341 San Juan Ave","Apt H3","CA","21123","USA","8181811621","Tsaw@gmail.com","Y","Y","N","Y","2/2/2019","Confirmed","5/2/2019","1234567",null,"123456","These are notes","1234"], ' + 
                                '["Smith","Mary",null,"Ms.",null,null,"10538 Monogram Ave",null,"CA","32136","USA","1262131723","laca@gmail.com","N","Y","Y","Y","3/2/2019","CheckedIn","6/2/2019",null,"121216112","12121611212","Test Notes","7665"], ' + 
                                '["James","Haley","DDS","Dr.","Google","Software Engineer","1644 Newport Blvd","Apt 1211A","CA","23212","USA","7123124122","ghills@yahoo.com","Y","Y","Y","Y","2/2/2019","Declined","8/2/2019",null,"161111",null,null,"87878"], ' +
                                '["Corvera","Marco","Esq.","Mr.",null,null,"125161 Melbourne Street",null,"Victoria","6121621","Australia","66232172233","Gen@ge.com","N","Y","Y","Y","2/2/2019","Unconfirmed",null,null,null,"21511",null,"8788"], ' +
                                '["Herrera","Billy",null,null,null,null,"125161 Billy Street",null,"Victoria","6121621","Australia","1251211","TestEmail@ge.com","N","Y","Y","Y","2/2/2019","Unconfirmed",null,null,null,null,null,"766554"]]';

            //Test Case 2: Attempt to create 5 event members on the campaign. Where constituents exist already. If a constituent exists with a similar unique ID, we create an campaignmember instead of an interim.
            String errorMessage = EngageCSVParserController.createEventMembers(jsonInput, campaign.Id);
            system.debug('errorMessage'+ errorMessage);
            System.assertEquals('', errorMessage, 'An error has occurred');
			
            List<Campaign> guestList = [SELECT Id FROM Campaign WHERE Parent_ERDA_Event__c =: campaign.Id];
            system.debug('guestList'+guestList);
            
            System.assertEquals(1, guestList.size(), 'A guest list should be associated with the parent event.');

            Integer associatedInterimsCount = [SELECT COUNT() FROM ucinn_ascendv2__Interim__c WHERE Guest_List__c =: guestList[0].Id];
            system.debug('associatedInterimsCount'+associatedInterimsCount);
            
            System.assertEquals(4, associatedInterimsCount, 'Interims should be created for members that are input without corresponding constituents in the system.');

            Integer associatedCampaignMembersCount = [SELECT COUNT() FROM CampaignMember WHERE CampaignId =: guestList[0].Id];
            System.assertEquals(1, associatedCampaignMembersCount, 'Campaign Members should be created for members that are input with corresponding constituents in the system.');

            String jsonInput2 = '[["Johnson","Mark","MD",null,"Dr.","Wells Fargo","CEO","1341 San Juan Ave","Apt H3",null,null,"Tustin","CA","21123","USA","8181811621","Tsaw@gmail.com","Y","Y","N","Y","2/2/2019","Confirmed","5/2/2019","Doesn\'t want to sit next to Bob next time.",null,"16117171711","' + crmId + '"], ' + 
                                '["Smith","Mary",null,null,"Ms.",null,null,"10538 Monogram Ave",null,null,null,"Los Angeles","CA","32136","USA","1262131723","laca@gmail.com","N","Y","Y","Y","3/2/2019","CheckedIn","6/2/2019",null,"1251","121216112","C-A04713750"], ' + 
                                '["James","Haley","DDS",null,"Dr.","Google","Software Engineer","1644 Newport Blvd","Apt 1211A","Suite 14",null,"Granada Hills","CA","23212","USA","7123124122","ghills@yahoo.com","Y","Y","Y","Y","2/2/2019","Declined","8/2/2019",null,"161111",null,null], ' +
                                '["Corvera","Marco","Esq.","The Honorable","Mr.",null,null,"125161 Melbourne Street",null,null,null,"Clayton","Victoria","6121621","Australia","66232172233","Gen@ge.com","N","Y","Y","Y","2/2/2019","Unconfirmed",null,"Hates fish.",null,"21511",null], ' +
                                '["Herrera","Billy",null,null,null,null,null,"125161 Billy Street",null,null,null,"Clayton","Victoria","6121621","Australia","1251211","TestEmail@ge.com","N","Y","Y","Y","2/2/2019","Unconfirmed",null,null,null,null,null]]';

            //Test Case 2:  Pre-Existing campaign members exist. If I upload a CSV to a campaign with existing campaign members that have matching Unique IDs to the ones on the list, no duplicates will be created,
            //              And the existing guests on the lists will be updated. In addition, Interims with matching unique IDs will be overridden. Interims with NO unique IDs will be created again for processing.
            String errorMessage2 = EngageCSVParserController.createEventMembers(jsonInput, campaign.Id);
            System.assertEquals('', errorMessage2, 'An error has occurred');

            List<Campaign> guestList2 = [SELECT Id,(select id from campaignmembers) FROM Campaign WHERE Parent_ERDA_Event__c =: campaign.Id ORDER BY CreatedDate DESC];
            System.assertEquals(1, guestList2.size(), '2 guest lists should be associated with the parent event.');
			system.debug('guestList2'+guestList2);
            Integer associatedInterimsCountOnNewGuestList = [SELECT COUNT() FROM ucinn_ascendv2__Interim__c WHERE Guest_List__c =: guestList2[0].Id];
            System.assertEquals(4, associatedInterimsCountOnNewGuestList, 'Interims should be created for members that are input without corresponding constituents in the system.');

            Integer associatedCampaignMembersCountOnNewGuestList = [SELECT COUNT() FROM CampaignMember WHERE CampaignId =: guestList2[0].Id];
            System.assertEquals(1, associatedCampaignMembersCountOnNewGuestList, 'Campaign Members should be created for members that are input with corresponding constituents in the system.');

            //Integer associatedInterimsCountOnOldGuestList = [SELECT COUNT() FROM ucinn_ascendv2__Interim__c WHERE Guest_List__c =: guestList2[1].Id];
            //System.assertEquals(3, associatedInterimsCountOnOldGuestList, 'Interims should be created for members that are input without corresponding constituents in the system.');

           // Integer associatedCampaignMembersCountOnOldGuestList = [SELECT COUNT() FROM CampaignMember WHERE CampaignId =: guestList2[1].Id];
            //System.assertEquals(2, associatedCampaignMembersCountOnOldGuestList, 'Campaign Members should be created for members that are input with corresponding constituents in the system.');
        }

    }
}