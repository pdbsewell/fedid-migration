@IsTest(isParallel=true)
public class CallistaNotesService_Test {

    /**
     * @description Test fetching Person notes from Callista
     */
    @IsTest
    static void testGetCallistaPersonNotes() {
        // GIVEN : a person note in Callista
        String mockResponse =
            '{' +
            '"notes": [{' +
            '"type": "personNote",' +
            '"admissionApplicationId": null,' +
            '"noteType": "AUTHINFO",' +
            '"typeDescription": "STUDENT AUTHORISED CONTACT FOR RELEASE OF INFORMATION",' +
            '"updateBy": "JPAD0005",' +
            '"updateOn": "2024-11-25T11:31:53",' +
            '"text": "AUTHINFO Test",' +
            '"portalApplicationID": null' +
            '}]' +
            '}';
        Test.setMock(HttpCalloutMock.class, new AssessmentsTestHelper.MockHttpResGenerator(mockResponse, 200));

        // WHEN: Callista Notes service is called
        CallistaNotesService.PersonNote result = CallistaNotesService.getCallistaPersonNotes('123456');

        // THEN: person note is returned
        Assert.areEqual(1, result.notes.size());
        Assert.areEqual('AUTHINFO', result.notes[0].noteType);
        Assert.areEqual('AUTHINFO Test', result.notes[0].text);
    }

    /**
     * @description Test posting person notes to Callista
     */
    @IsTest
    static void testPostCallistaPersonNotes() {
        String mockResponse = '{"id": "123456"}';
        Test.setMock(HttpCalloutMock.class, new AssessmentsTestHelper.MockHttpResGenerator(mockResponse, 200));

        // WHEN: a person note is posted to Callista
        String result = CallistaNotesService.postCallistaPersonNotes(
            '123456',
            '{"noteType": "INTPAYMENT", "text": "Package Deposit: $0\nOSHC: $9792\nOSHC Sponsored: Y\n Tuition Sponsored: Y"}'
        );

        // THEN: a reference Id is returned
        Assert.areEqual('123456', result);
    }

    /**
     * @description Test fetching ACAI notes from Callista
     */
    @IsTest
    static void testGetCallistaACAINotes() {
        // GIVEN : an acai note in Callista
        String mockResponse =
            '{' +
            '"acaiNotes": [{' +
            '"type": "acaiNote",' +
            '"admissionApplicationId": "33072043-1-S6005-2",' +
            '"noteType": "SCHOLARSHP",' +
            '"typeDescription": "APPLICATION COURSE NOTE",' +
            '"updateBy": "JPAD0005",' +
            '"updateOn": "2024-11-21T11:54:14",' +
            '"text": "Deferral form received for the Grad Cert Business Law (09/06/06).",' +
            '"portalApplicationID": "1297856-S6005-2"' +
            '}]' +
            '}';
        Test.setMock(HttpCalloutMock.class, new AssessmentsTestHelper.MockHttpResGenerator(mockResponse, 200));

        // WHEN: Callista Notes service is called
        CallistaNotesService.ACAINote result = CallistaNotesService.getCallistaACAINotes('123456');

        // THEN: acai note is returned
        Assert.areEqual(1, result.acaiNotes.size());
        Assert.areEqual('SCHOLARSHP', result.acaiNotes[0].noteType);
        Assert.areEqual(
            'Deferral form received for the Grad Cert Business Law (09/06/06).',
            result.acaiNotes[0].text
        );
    }

    /**
     * @description Test posting acai notes to Callista
     */
    @IsTest
    static void testPostCallistaACAINotes() {
        String mockResponse = '{"referenceNumber": "12345678"}';
        Test.setMock(HttpCalloutMock.class, new AssessmentsTestHelper.MockHttpResGenerator(mockResponse, 200));

        // WHEN: an acai note is posted to Callista
        String result = CallistaNotesService.postCallistaACAINotes(
            '12345678',
            '{"type": "acaiNote", "noteType": "STDY-GRNT", "text": "2025/2-Pathwaygrant-5000x2-31/01/2024-Accepted", "admissionApplNumber": 1,  "courseCode": "S6005",  "sequenceNumber": 2}'
        );

        // THEN: a reference Id is returned
        Assert.areEqual('12345678', result);
    }
}