/**
 * @author       Ryan Wilson
 * @date         12.Jan.2017
 * @description  test class for BMSMassEmailContactCSVBatch, BMSCSVSearch
 * @revision
 *  01.MAR.2021     Nick Guia   - updated all test class logic
 */
@isTest(isParallel=true)
private class BMSMassEmailContactCSVBatch_Test {

	@TestSetup
	static void makeData() {
		//create test contacts
		List<Contact> contactRecordList = BMS_TestDataHelper.buildSampleContacts();
		insert contactRecordList;

		//create test campaign
		Campaign bms = BMS_TestDataHelper.buildSampleCRMMassEmail(null);
		insert bms;
	}

	/**
	 * @description test upload and read a csv file containing Person IDs
	 */
	@isTest
	static void shouldExecuteUsingPersonIdCSV() {
		//given
		String strCsvContent = 'PERSON_ID'+'\r\n'+'1234567890'+'\r\n'+'1324567890'+'\r\n'+'1474567890'+'\r\n';
		Blob csvBlob = Blob.valueOf(strCsvContent);

		Id bmsRecType = Schema.SObjectType.Campaign
		                .getRecordTypeInfosByDeveloperName()
		                .get(Label.Campaign_Record_Type_BMS)
		                .getRecordTypeId();
		Campaign bms = [SELECT Id FROM Campaign WHERE RecordTypeId = :bmsRecType LIMIT 1];

		String fileName = 'PersonId.csv';
		Attachment csv = new Attachment();
		csv.Body = csvBlob;
		csv.Name = fileName;
		csv.ParentId = bms.Id;
		insert csv;

		BMSMassEmailContactCSVBatch csvBatch;
		Id batchJobId;

		Test.startTest();

		//when
		csvBatch = new BMSMassEmailContactCSVBatch(csv.Id, bms.Id, true);
		batchJobId = Database.executeBatch(csvBatch, 200);

		Test.stopTest();

		//then
		System.assert (batchJobId != null, 'Unable to execute BMSMassEmailContactCSVBatch');
    }

	/**
	 * @description test upload and read a csv file containing FN, LN, and Emails of Contacts
	 */
	@isTest
	static void shouldExecuteUsingEmailCSV() {
		//given
		String strCsvContent = 'FirstName,LastName,Email'+'\r\n'+'Doe0,John,0testemailAddress@monash.edu'+'\r\n'+'Doe1,John,1testemailAddress@monash.edu'+'\r\n'+'Doe2,John,2testemailAddress@monash.edu'+'\r\n';
		Blob csvBlob = Blob.valueOf(strCsvContent);

		Id bmsRecType = Schema.SObjectType.Campaign
		                .getRecordTypeInfosByDeveloperName()
		                .get(Label.Campaign_Record_Type_BMS)
		                .getRecordTypeId();
		Campaign bms = [SELECT Id FROM Campaign WHERE RecordTypeId = :bmsRecType LIMIT 1];

		String fileName = 'PersonId.csv';
		Attachment csv = new Attachment();
		csv.Body = csvBlob;
		csv.Name = fileName;
		csv.ParentId = bms.Id;
		insert csv;

		BMSMassEmailContactCSVBatch csvBatch;
		Id batchJobId;

		Test.startTest();

		//when
		csvBatch = new BMSMassEmailContactCSVBatch(csv.Id, bms.Id, false);
        batchJobId = Database.executeBatch(csvBatch, 200);

		Test.stopTest();

		//then
		System.assert (batchJobId != null, 'Unable to execute BMSMassEmailContactCSVBatch');
    }

    /**
	 * @description test upload and read a csv file containing FN, LN, and Emails of Contacts.
     * Any non UTF-8 character should still be accepted.
	 */
    @isTest
    static void shouldExecuteWithEmailCSVWithInvalidUTF8() {
        //given
        String strCsvContent = 'FirstName,LastName,Email'+'\r\n'+'Jo€,Bloggs,jbloggs@monashtest.edu'+'\r\n'+'Marie,Claire,some1email@monashtest.edu'+'\r\n'+'Ant,Custodio,ant.custodio@monashtest.edu'+'\r\n';
        Blob csvBlob = Blob.valueOf(strCsvContent);
        
        Id bmsRecType = Schema.SObjectType.Campaign
		                .getRecordTypeInfosByDeveloperName()
		                .get(Label.Campaign_Record_Type_BMS)
		                .getRecordTypeId();
		Campaign bms = [SELECT Id FROM Campaign WHERE RecordTypeId = :bmsRecType LIMIT 1];

		String fileName = 'PersonId.csv';
		Attachment csv = new Attachment();
		csv.Body = csvBlob;
		csv.Name = fileName;
        csv.ParentId = bms.Id;
        insert csv;

        BMSMassEmailContactCSVBatch csvBatch;
        Id batchJobId;

		Test.startTest();

		//when
		csvBatch = new BMSMassEmailContactCSVBatch(csv.Id, bms.Id, false);
        batchJobId = Database.executeBatch(csvBatch, 200);

		Test.stopTest();

		//then
		System.assert (batchJobId != null, 'Unable to execute BMSMassEmailContactCSVBatch');
    }
}