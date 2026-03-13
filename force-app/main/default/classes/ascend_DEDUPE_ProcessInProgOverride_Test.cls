@isTest
public class ascend_DEDUPE_ProcessInProgOverride_Test {

    @testSetup static void testSetup() {
        ucinn_ascendv2__Sync_Phone_Mapping__c var0 = new ucinn_ascendv2__Sync_Phone_Mapping__c(NAME='AssistantPhone', ucinn_ascendv2__Related_Phone_Type__c='Assistant');
        ucinn_ascendv2__Sync_Phone_Mapping__c var1 = new ucinn_ascendv2__Sync_Phone_Mapping__c(NAME='Fax', ucinn_ascendv2__Related_Phone_Type__c='Fax');
        ucinn_ascendv2__Sync_Phone_Mapping__c var2 = new ucinn_ascendv2__Sync_Phone_Mapping__c(NAME='HomePhone', ucinn_ascendv2__Related_Phone_Type__c='Home');
        ucinn_ascendv2__Sync_Phone_Mapping__c var3 = new ucinn_ascendv2__Sync_Phone_Mapping__c(NAME='MobilePhone', ucinn_ascendv2__Related_Phone_Type__c='Mobile');
        ucinn_ascendv2__Sync_Phone_Mapping__c var4 = new ucinn_ascendv2__Sync_Phone_Mapping__c(NAME='OtherPhone', ucinn_ascendv2__Related_Phone_Type__c='Other');
        ucinn_ascendv2__Sync_Phone_Mapping__c var5 = new ucinn_ascendv2__Sync_Phone_Mapping__c(NAME='Phone', ucinn_ascendv2__Related_Phone_Type__c=null);

        List<ucinn_ascendv2__Sync_Phone_Mapping__c> vars = new List<ucinn_ascendv2__Sync_Phone_Mapping__c>{var0, var1, var2, var3, var4, var5};
        insert vars;
    }

    static testMethod void testBatchV2() {
        insert new ucinn_ascendv2__Org_Wide_Configuration__c(Name='Default Org Wide Config');

        // GIVEN: contact record to update
        Contact con = new Contact(LastName='test');
        insert con;

        // GIVEN: phone number
        ucinn_ascendv2__Phone__c phoneToInsert = createContactPhoneNumber(con.Id, 'Mobile', '(949) 815-9969', 'B', false);

        // GIVEN: names
        List<ucinn_ascendv2__Contact_Name__c> lstOfContactNamesToInsert = new List<ucinn_ascendv2__Contact_Name__c>();
        lstOfContactNamesToInsert.add(new ucinn_ascendv2__Contact_Name__c(ucinn_ascendv2__Contact__c=con.Id, ucinn_ascendv2__Last_Name__c='test', ucinn_ascendv2__Type__c='Full Name'));
        lstOfContactNamesToInsert.add(new ucinn_ascendv2__Contact_Name__c(ucinn_ascendv2__Contact__c=con.Id, ucinn_ascendv2__Last_Name__c='test', ucinn_ascendv2__Type__c='Former'));
        lstOfContactNamesToInsert.add(new ucinn_ascendv2__Contact_Name__c(ucinn_ascendv2__Contact__c=con.Id, ucinn_ascendv2__Last_Name__c='test', ucinn_ascendv2__Type__c='Other'));
        insert lstOfContactNamesToInsert;

        ucinn_ascendv2__Address_Type_Mapping__c conMail = new ucinn_ascendv2__Address_Type_Mapping__c(Name = 'Contact_Mailing', ucinn_ascendv2__Address_Relation_Type__c = 'Mailing', ucinn_ascendv2__Address_Type_Label_Backend_Message__c = 'mailing',
        ucinn_ascendv2__Backend_Address_Type_API_Name__c = 'Mailing', ucinn_ascendv2__Object_Address_Field_Name__c = 'MailingAddress', ucinn_ascendv2__Object_API_Name__c = 'Contact');
        insert conMail;

        Id rtID= [Select Id From RecordType Where DeveloperName = 'Online_Donation_Interface' AND SobjectType =: ucinn_ascendv2__Interim__c.getSobjectType().getDescribe().getName()].get(0).Id;

        // GIVEN: addresses
        ucinn_ascendv2__Interim__c interimToInsert = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__Last_Name__c='test',
        ucinn_ascendv2__Address_1_Line_1__c = '123 Tmp Street',
        ucinn_ascendv2__Address_1_Line_2__c = '12',
        ucinn_ascendv2__Address_1_Line_3__c = '33',
        ucinn_ascendv2__Address_1_Type__c = 'Mailing',
        ucinn_ascendv2__City_1__c='Irvine',
        ucinn_ascendv2__State_1__c='California',
        ucinn_ascendv2__Country_1__c='USA',
        ucinn_ascendv2__Address_2_Line_1__c = '123 Tmp Street',
        ucinn_ascendv2__Address_2_Line_2__c = '12',
        ucinn_ascendv2__Address_2_Line_3__c = '33',
        ucinn_ascendv2__Address_2_Type__c = 'Mailing',
        ucinn_ascendv2__City_2__c='Irvine',
        ucinn_ascendv2__State_2__c='California',
        ucinn_ascendv2__Country_2__c='USA',
        ucinn_ascendv2__Phone_1__c='1234567890',
        ucinn_ascendv2__Phone_1_Type__c = 'Mobile',
        ucinn_ascendv2__Phone_2__c='1234567890',
        ucinn_ascendv2__Phone_2_Type__c = 'Home',
        ucinn_ascendv2__Email_1__c='123@example.com',
        ucinn_ascendv2__Email_1_Type__c = 'Campus',
        ucinn_ascendv2__Contact__c=con.Id,
        Name='test',
        ucinn_ascendv2__External_System_ID__c='STRC-001',
        ucinn_ascendv2__Status__c='In Progress',
        RecordTypeId = rtId);
        insert interimToInsert;

        // WHEN: process interims
        Map<String, Object> params1 = new Map<String, Object>();
        params1.put('interimList', new List<ucinn_ascendv2__Interim__c>{interimToInsert});
        ascend_DEDUPE_ProcessInProgOverride overrideClass = new ascend_DEDUPE_ProcessInProgOverride();
        overrideclass.batchConstructor('Online_Donation_Interface', 'ucinn_ascendv2');
        overrideclass.prepareContactInformation(params1);
        overrideclass.batchExecute(null, new List<ucinn_ascendv2__Interim__c>{interimToInsert});
        overrideclass.batchFinish(null);
    }

    private static ucinn_ascendv2__Phone__c createContactPhoneNumber(Id contactId, String type, String phoneNumber, String extension, Boolean shouldInsert) {
        ucinn_ascendv2__Org_Wide_Configuration__c customSetting = ucinn_ascendv2__Org_Wide_Configuration__c.getInstance('Default Org Wide Config');
        if (customSetting == null) {
            insert new ucinn_ascendv2__Org_Wide_Configuration__c(Name='Default Org Wide Config', ucinn_ascendv2__Is_Multiple_Current_Addresses_Enabled__c=false, ucinn_ascendv2__Is_Multiple_Current_Phones_Enabled__c=false, ucinn_ascendv2__Is_Multiple_Current_Emails_Enabled__c=false);
        }
        Id contactPhoneNumberId = [SELECT Id, Name FROM RecordType WHERE Name = 'Contact Phone'].Id;

        ucinn_ascendv2__Phone__c phone = new ucinn_ascendv2__Phone__c(ucinn_ascendv2__Contact__c = contactId, ucinn_ascendv2__Type__c = type, ucinn_ascendv2__Is_Preferred__c = true, ucinn_ascendv2__Status__c = 'Current',
        ucinn_ascendv2__Phone_Number__c = phoneNumber, ucinn_ascendv2__Extension__c = extension, RecordTypeId = contactPhoneNumberId);

        if (shouldInsert) {
            insert phone;
        }
        return phone;
    }
}