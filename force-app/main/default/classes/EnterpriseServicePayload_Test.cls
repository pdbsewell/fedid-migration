/**
 * @description       : Test Class for EnterpriseServicePayload
 * @author            : Angelo Rivera
 * @group             : Engage Enterprise
 * @version           : Modifications Log
 * Ver   Date           Author              Modification
 * 1.0   30-08-2023     Angelo Rivera       Initial Creation
 * 1.1   17-04-2024     Sachin Shetty       Update to point to DBConnect fields
 * 2.0	 17-08-2025		Sachin Shetty		Formatting
**/
@IsTest(IsParallel=true)
public with sharing class EnterpriseServicePayload_Test {

    /*
     * @description     This method will verify sample data from PURE will be Create/Update records in CRM
     * Expected result: Account, Contact and Opportunity will be created.
     *
     * GIVEN payload from PURE, processed by MIX
     * WHEN mix posted the request to CRM webservice api
     * THEN payload will be transformed as Account, Contact and Opportunity
     */
    @IsTest
    private static void testEnterpriseServicePayload() {
            String jsonPayload=		'{\n' +
                    '    "applicationId": "1027198990",\n' +
                    '    "externalFunderId": "CAF-2022-1513",\n' +
                    '    "opportunityName": "Test Opportunity for Friends Corporation",\n' +
                    '    "serviceCatalogue": "Research collaboration",\n' +
                    '    "facultyType": "Information Technology",\n' +
                    '    "fundingAmount": "1500000",\n' +
                    '    "agreementCloseDate": "2013-07-26",\n' +
                    '    "primaryContactId": "CON12345",\n' +
                    '    "applicationStage": "Closed Won",\n' +
                    '    "provenance": "PURE",\n' +
                    '    "leadTimeToConvert": "Less than 3 Months",\n' +
                    '    "submissionDueDate": "2021-08-01",\n' +
                    '    "projectDuration": "120",\n' +
                    '    "projectStartDate": "2022-08-25",\n' +
                    '    "projectEndDate": "2022-08-25",\n' +
                    '    "proposalStatus": "In-Progress",\n' +
                    '    "proposalSubmissionDate": "2013-07-26",\n' +
                    '    "competitiveGrantFlag": "TRUE",\n' +
                    '    "presentationSubmissionDate": "2013-07-26",\n' +
                    '    "dateOfSubmissionToPartner": "2013-07-26",\n' +
                    '    "contractSignedDate": "2013-07-26",\n' +
                    '    "ogc_mroReferenceNumber": "TYH789742",\n' +
                    '    "applicationReviewedFlag": "TRUE",\n' +
                    '    "applicationStatus": "Draft proposal",\n' +
                    '    "applicationType": "Internship",\n' +
                    '    "awardTransferredIndicator": "Transfer In",\n' +
                    '    "awardVisibility": "Confidential",\n' +
                    '    "applicationVisibility": "Confidential",\n' +
                    '    "awardId": "AWA12345",\n' +
                    '    "awardType": "New Business",\n' +
                    '    "projectId": "567384",\n' +
                    '    "leadCollaborator": "Monash Led",\n' +
                    '    "fundingSchemeName": "City of Whittlesea",\n' +
                    '    "funderReferenceNumber": "LP180101178",\n' +
                    '    "collaboratorCount": "5",\n' +
                    '    "fundingId": "12341234",\n' +
                    '    "contractStatus": "In Development",\n' +
                    '    "industryRelatedFlag": "False",\n' +
                    '    "accounts": [\n' +
                    '        {\n' +
                    '            "organisationID": "12344321",\n' +
                    '            "dunsNumber": "12344321",\n' +
                    '            "organisationIdentifier": "ORG00001234",\n' +
                    '            "accountName": "Friendly Corporation",\n' +
                    '            "accountType": "Government",\n' +
                    '            "externalIdentifier":"Internal",\n' +
                    '            "tradingName": "Friendship Corporation",\n' +
                    '            "organisationParent": "37899",\n' +
                    '            "globalUltimateAccountName": "Test Global Ultimate Account Name",\n' +
                    '            "description": "Test description about the collaborator",\n' +
                    '            "website": "http://abc.com",\n' +
                    '            "tickerSymbol": "Test symbol",\n' +
                    '            "phone": "+61411415613",\n' +
                    '            "billingStreet": "Burwood street",\n' +
                    '            "organisationCity": "Sydney",\n' +
                    '            "organisationState": "New South Wales",\n' +
                    '            "organisationZipCode": "8887",\n' +
                    '            "organisationCountry": "Australia",\n' +
                    '            "shippingStreet": "Swanston Street",\n' +
                    '            "shippingCity": "Perth",\n' +
                    '            "shippingState": "Western Australia",\n' +
                    '            "shippingZipCode": "8889",\n' +
                    '            "shippingCountry": "Australia",\n' +
                    '            "matchScore": "10",\n' +
                    '            "globalUltimateDuns": "GLO145678",\n' +
                    '            "organisationIdentifierType": "ACN",\n' +
                    '            "altOrganisationIdentifierType": "ACN",\n' +
                    '            "altOrganisationIdentifier": "ALTORG76869",\n' +
                    '            "industryDivision": "Test division",\n' +
                    '            "industryMajorGroup": "Test Group",\n' +
                    '            "industryClassificationSIC4": "200",\n' +
                    '            "industryClassificationSIC8": "100",\n' +
                    '            "outOfBusinessIndicator": "Test Indicator",\n' +
                    '            "employeesCount": "15000",\n' +
                    '            "employeeOverall": "15000",\n' +
                    '            "annualRevenue": "10,00,000",\n' +
                    '            "fortuneRank": "49",\n' +
                    '            "legalStructure": "Test structure",\n' +
                    '            "publicPrivateIndicator": "Public",\n' +
                    '            "salesVolume": "10,000",\n' +
                    '            "salesVolumeAccuracy": "68",\n' +
                    '            "fiscalYearEnd": "March",\n' +
                    '            "tradingName2": "Company ABC",\n' +
                    '            "tradingName3": "Renolds Company",\n' +
                    '            "nationalIdentifier3": "ACN",\n' +
                    '            "nationalIdentifier4": "ACN",\n' +
                    '            "badDebtor": "FALSE",\n' +
                    '            "primaryAccountFlag": "FALSE",\n' +
                    '            "funding": [\n' +
                    '                {\n' +
                    '                    "applicationId": "10272003",\n' +
                    '                    "collaboratorIndicator": "Collaborator"\n' +
                    '                }\n' +
                    '            ]\n' +
                    '        },\n' +
                    '        {\n' +
                    '            "organisationID": "12345432",\n' +
                    '            "dunsNumber": "02340002",\n' +
                    '            "organisationIdentifier": "ORG00005432",\n' +
                    '            "accountName": "Bestfriend Corporation",\n' +
                    '            "accountType": "Government",\n' +
                    '            "externalIdentifier":"External",\n' +
                    '            "tradingName": "Bestfriend Corporation",\n' +
                    '            "organisationParent": "12344321",\n' +
                    '            "globalUltimateAccountName": "Test Global Ultimate Account Name",\n' +
                    '            "description": "Test description about the collaborator",\n' +
                    '            "website": "http://abc.com",\n' +
                    '            "tickerSymbol": "Test symbol",\n' +
                    '            "phone": "+61411415613",\n' +
                    '            "billingStreet": "Burwood street",\n' +
                    '            "organisationCity": "Sydney",\n' +
                    '            "organisationState": "New South Wales",\n' +
                    '            "organisationZipCode": "8887",\n' +
                    '            "organisationCountry": "Australia",\n' +
                    '            "shippingStreet": "Swanston Street",\n' +
                    '            "shippingCity": "Perth",\n' +
                    '            "shippingState": "Western Australia",\n' +
                    '            "shippingZipCode": "8889",\n' +
                    '            "shippingCountry": "Australia",\n' +
                    '            "matchScore": "10",\n' +
                    '            "globalUltimateDuns": "GLO145678",\n' +
                    '            "organisationIdentifierType": "ACN",\n' +
                    '            "altOrganisationIdentifierType": "ACN",\n' +
                    '            "altOrganisationIdentifier": "ALTORG76869",\n' +
                    '            "industryDivision": "Test division",\n' +
                    '            "industryMajorGroup": "Test Group",\n' +
                    '            "industryClassificationSIC4": "200",\n' +
                    '            "industryClassificationSIC8": "100",\n' +
                    '            "outOfBusinessIndicator": "Test Indicator",\n' +
                    '            "employeesCount": "15000",\n' +
                    '            "employeeOverall": "15000",\n' +
                    '            "annualRevenue": "10,00,000",\n' +
                    '            "fortuneRank": "49",\n' +
                    '            "legalStructure": "Test structure",\n' +
                    '            "publicPrivateIndicator": "Public",\n' +
                    '            "salesVolume": "10,000",\n' +
                    '            "salesVolumeAccuracy": "68",\n' +
                    '            "fiscalYearEnd": "March",\n' +
                    '            "tradingName2": "Company ABC",\n' +
                    '            "tradingName3": "Renolds Company",\n' +
                    '            "nationalIdentifier3": "ACN",\n' +
                    '            "nationalIdentifier4": "ACN",\n' +
                    '            "badDebtor": "FALSE",\n' +
                    '            "primaryAccountFlag": "TRUE",\n' +
                    '            "funding": [\n' +
                    '                {\n' +
                    '                    "applicationId": "6595887",\n' +
                    '                    "appliedGrantAmount": "1000",\n' +
                    '                    "discountAmount": "",\n' +
                    '                    "awardedAmount": "-60000",\n' +
                    '                    "discountPercentage": "",\n' +
                    '                    "fundingDescription": "",\n' +
                    '                    "fundingCategory": "Category 1",\n' +
                    '                    "funderReferenceNumber": "DP110100752",\n' +
                    '                    "fundingCategoryDescription": "Australian Competitive Grants",\n' +
                    '                    "fundingScheme": "ARC Discovery Projects 2011 - applied 2010 - Grant component",\n' +
                    '                    "fundingType": "Y",\n' +
                    '                    "fundingOrder": "1",\n' +
                    '                    "collaboratorIndicator": "Funder",\n' +
                    '                    "fundingOpportunity": "ARC Discovery Projects",\n' +
                    '                    "fundingSchemeId": "1001"\n' +
                    '                },\n' +
                    '                {\n' +
                    '                    "applicationId": "6595887",\n' +
                    '                    "appliedGrantAmount": "1000",\n' +
                    '                    "discountAmount": "",\n' +
                    '                    "awardedAmount": "150000",\n' +
                    '                    "discountPercentage": "",\n' +
                    '                    "fundingDescription": "",\n' +
                    '                    "fundingCategory": "Category 1",\n' +
                    '                    "funderReferenceNumber": "DP110100752",\n' +
                    '                    "fundingCategoryDescription": "Australian Competitive Grants",\n' +
                    '                    "fundingScheme": "ARC Discovery Projects 2011 - applied 2010 - Grant component",\n' +
                    '                    "fundingType": "Y",\n' +
                    '                    "fundingOrder": "2",\n' +
                    '                    "collaboratorIndicator": "Funder",\n' +
                    '                    "fundingOpportunity": "ARC Discovery Projects",\n' +
                    '                    "fundingSchemeId": "1001"\n' +
                    '                },\n' +
                    '                {\n' +
                    '                    "applicationId": "6595887",\n' +
                    '                    "appliedGrantAmount": "1000",\n' +
                    '                    "discountAmount": "",\n' +
                    '                    "awardedAmount": "150000",\n' +
                    '                    "discountPercentage": "",\n' +
                    '                    "fundingDescription": "",\n' +
                    '                    "fundingCategory": "Category 1",\n' +
                    '                    "funderReferenceNumber": "DP110100752",\n' +
                    '                    "fundingCategoryDescription": "Australian Competitive Grants",\n' +
                    '                    "fundingScheme": "ARC Discovery Projects 2011 - applied 2010 - Grant component",\n' +
                    '                    "fundingType": "N",\n' +
                    '                    "fundingOrder": "2",\n' +
                    '                    "collaboratorIndicator": "Funder",\n' +
                    '                    "fundingOpportunity": "ARC Discovery Projects",\n' +
                    '                    "fundingSchemeId": "1013"\n' +
                    '                }\n' +
                    '            ]\n' +
                    '        }\n' +
                    '    ],\n' +
                    '    "contacts": [\n' +
                    '        {\n' +
                    '            "firstName": "Joey",\n' +
                    '            "lastName": "Tribbiani",\n' +
                    '            "contactName": "Joey Tribbiani",\n' +
                    '            "preferredFirstName": "Joey",\n' +
                    '            "profile": "Test profile",\n' +
                    '            "salutation": "Mr",\n' +
                    '            "gender": "Male",\n' +
                    '            "primaryEmail": "joeytribiani@gmail.com",\n' +
                    '            "secondaryEmail": "",\n' +
                    '            "description": "Description of the researcher",\n' +
                    '            "orcId": "12341235",\n' +
                    '            "researcherId": "346226525",\n' +
                    '            "accountName": "Friends Corporation",\n' +
                    '            "facultyPortfolio": "Test faculty",\n' +
                    '            "divisionName": "Test division",\n' +
                    '            "primaryContactFlag": "TRUE",\n' +
                    '            "teamRole": "Decision Maker",\n' +
                    '            "dunsNumber": "12344321",\n' +
                    '            "organisationId": "12344321"\n' +
                    '        },\n' +
                    '        {\n' +
                    '            "firstName": "Chandler",\n' +
                    '            "lastName": "Bing",\n' +
                    '            "contactName": "Chandler Bing",\n' +
                    '            "preferredFirstName": "Chandler",\n' +
                    '            "profile": "Test profile",\n' +
                    '            "salutation": "Mr",\n' +
                    '            "gender": "Male",\n' +
                    '            "primaryEmail": "chandlerbing@gmail.com",\n' +
                    '            "secondaryEmail": "",\n' +
                    '            "description": "Description of the researcher",\n' +
                    '            "orcId": "12344322",\n' +
                    '            "researcherId": "346226526",\n' +
                    '            "accountName": "Bestfriends Corporation",\n' +
                    '            "facultyPortfolio": "Test faculty",\n' +
                    '            "divisionName": "Test division",\n' +
                    '            "primaryContactFlag": "False",\n' +
                    '            "teamRole": "Executive Sponsor",\n' +
                    '            "dunsNumber": "02340002",\n' +
                    '            "organisationId": "12345432"\n' +
                    '        }\n' +
                    '    ]\n' +
                    '}';

        Test.startTest();
            EnterpriseServicePayload  enterpriseServicePayload =  (EnterpriseServicePayload) JSON.deserialize(jsonPayload, EnterpriseServicePayload.class);
                enterpriseServicePayload.applicationId = '1027198990';
                enterpriseServicePayload.applicationId='1027198990';
                enterpriseServicePayload.externalFunderId='CAF-2022-1513';
                enterpriseServicePayload.opportunityName='Test Opportunity for Friends Corporation';
                enterpriseServicePayload.serviceCatalogue='Research collaboration';
                enterpriseServicePayload.facultyType='Information Technology';
                enterpriseServicePayload.agreementCloseDate='2013-07-26';
                enterpriseServicePayload.applicationStage='Closed Won';
                enterpriseServicePayload.provenance='PURE';
                enterpriseServicePayload.leadTimeToConvert='Less than 3 Months';
                enterpriseServicePayload.submissionDueDate='2021-08-01';
                enterpriseServicePayload.projectDuration='120';
                enterpriseServicePayload.projectStartDate='2022-08-25';
                enterpriseServicePayload.projectEndDate='2022-08-25';
                enterpriseServicePayload.proposalStatus='In-Progress';
                enterpriseServicePayload.proposalSubmissionDate='2013-07-26';

        Test.stopTest();

        Assert.areEqual('1027198990', enterpriseServicePayload.applicationId, 'Error on payload');
    }
    
    @IsTest
    static void testEnterpriseServicePayloadCoverage() {
        // GIVEN - Main payload instance
        EnterpriseServicePayload payload = new EnterpriseServicePayload();
        payload.applicationId = 'APP123';
        payload.externalFunderId = 'CAF-2022-1513';
        payload.opportunityName = 'Track Geometry Measurement';
        payload.serviceCatalogue = 'Research collaboration';
        payload.facultyType = 'Information Technology';
        payload.applicationStage = 'Pre-Approval';
        payload.provenance = 'PURE';
        payload.leadTimeToConvert = 'Less than 3 Months';
        payload.submissionDueDate = '2021-08-01';
        payload.projectDuration = '120';
        payload.projectStartDate = '2022-08-25';
        payload.projectEndDate = '2022-08-25';
        payload.proposalStatus = 'In-Progress';
        payload.applicationStatus = 'Draft proposal';
        payload.applicationType = 'Internship';
        payload.awardType = 'Fellowship';
        payload.awardId = 'AWA12345';
        payload.applicationWorkflowStatus = 'Reply Received From Funder';
        payload.awardWorkflowStatus = 'Reply Received From Funder';

        // AND - Nested account with funding
        EnterpriseServicePayload.cls_accounts account = new EnterpriseServicePayload.cls_accounts();
        account.accountName = 'James';
        account.accountType = 'Business or Corporation';
        account.phone = '+61411415613';
        account.billingStreet = 'Burwood street';
        account.organisationCity = 'Sydney';
        
        EnterpriseServicePayload.cls_funding funding = new EnterpriseServicePayload.cls_funding();
        funding.applicationId = 'APP123';
        funding.appliedGrantAmount = '50000';
        funding.awardedAmount = '50000';
        account.funding = new List<EnterpriseServicePayload.cls_funding>{ funding };
        
        payload.accounts = new List<EnterpriseServicePayload.cls_accounts>{ account };

        // AND - Nested contact
        EnterpriseServicePayload.cls_contacts contact = new EnterpriseServicePayload.cls_contacts();
        contact.firstName = 'Josh';
        contact.lastName = 'Lee';
        contact.primaryEmail = 'primary@monuni.com';
        contact.accountName = 'Australian Board';
        contact.facultyPortfolio = 'Test faculty';
        payload.contacts = new List<EnterpriseServicePayload.cls_contacts>{ contact };
            
        // AND - Response
        EnterpriseServicePayload.cls_response response = new EnterpriseServicePayload.cls_response();
        response.response = 'Success';

        // WHEN - Accessing nested values
        String accountName = payload.accounts[0].accountName;
        String fundingAmount = payload.accounts[0].funding[0].appliedGrantAmount;
        String contactEmail = payload.contacts[0].primaryEmail;
        String firstName = payload.contacts[0].firstName;
        String responseStatus = response.response;

        // THEN - Assert main payload values
        Assert.areEqual('APP123', payload.applicationId, 'Application ID should match');
        Assert.areEqual('CAF-2022-1513', payload.externalFunderId, 'External Funder ID should match');
        Assert.areEqual('Track Geometry Measurement', payload.opportunityName, 'Opportunity Name should match');
        Assert.areEqual('Research collaboration', payload.serviceCatalogue, 'Service Catalogue should match');
        Assert.areEqual('Pre-Approval', payload.applicationStage, 'Application stage should match');

        // THEN - Assert account and funding values
        Assert.areEqual('James', accountName, 'Account name should match');
        Assert.areEqual('50000', fundingAmount, 'Funding applied amount should match');

        // THEN - Assert contact values
        Assert.areEqual('Josh', firstName, 'Contact first name should match');
        Assert.areEqual('primary@monuni.com', contactEmail, 'Contact email should match');
        
        // THEN - Assert response value
        Assert.areEqual('Success', responseStatus, 'Response value should match');
    }
}