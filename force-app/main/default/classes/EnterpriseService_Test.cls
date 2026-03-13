/**
 * @description       : Test Class for EnterpriseServicePayload
 * @author            : Angelo Rivera
 * @group             : Engage Enterprise
 * @version           : Modifications Log
 * Ver   Date           Author              Modification
 * 1.0   20-09-2023     Angelo Rivera       Initial Creation
 * 1.1   22-11-2023     Angelo Rivera       added test coverage
**/
@IsTest(IsParallel=false) // System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests
private class EnterpriseService_Test {

    @TestSetup
    static void makeData(){

        List<Contact> listContacts = new List<Contact>();
        Contact con = StudFirst_TestHelper.createApplicant();
        con.AssistantName = 'CPA Test Contact';
        con.Researcher_ID__c = '346226526';
        con.Email = '';

        Contact con2 = StudFirst_TestHelper.createApplicant();
        con2.AssistantName = 'CPA Test Contact2';
        con2.ORCID__c = '1323226526';
        con2.Email = '';

        Contact con3 = StudFirst_TestHelper.createApplicant();
        con3.AssistantName = 'CPA Test Contact3';
        con3.Email = 'testemail@monash.edu';

        listContacts.add(con);
        listContacts.add(con2);
        listContacts.add(con3);
        insert listContacts;
    }

    /*
     * @description     This method will verify sample data from PURE will be Create/Update records in CRM
     * Expected result: Account, Contact and Opportunity will be created.
     *
     * GIVEN payload from PURE, processed by MIX
     * WHEN mix posted the request to CRM webservice api
     * THEN payload will be transformed as Account, Contact and Opportunity
    */
    @IsTest
    static void testIntegration() {
        EnterpriseServicePayload esp = new EnterpriseServicePayload();
        esp.accounts = new List<EnterpriseServicePayload.cls_accounts>();
        esp.contacts = new List<EnterpriseServicePayload.cls_contacts>();

        esp.applicationId = '1027198928';
        esp.externalFunderId = 'CAF-2022-1513';
        esp.opportunityName = 'Test Opportunity for Friends Corporation';
        esp.serviceCatalogue = 'Research collaboration';
        esp.facultyType = 'Information Technology';
        esp.agreementCloseDate = '2013-07-26';
        esp.applicationStage = 'Closed Won';
        esp.provenance = 'PURE';
        esp.leadTimeToConvert = 'Less than 3 Months';
        esp.submissionDueDate = '2021-08-01';
        esp.projectDuration = '120';
        esp.projectStartDate = '2022-08-25';
        esp.projectEndDate = '2022-09-25';
        esp.proposalStatus = 'In-Progress';
        esp.proposalSubmissionDate = '2013-07-26';
        esp.competitiveGrantFlag = 'TRUE';
        esp.presentationSubmissionDate = '2013-07-26';
        esp.dateOfSubmissionToPartner = '2013-07-26';
        esp.contractSignedDate = '2013-07-26';
        esp.ogc_mroReferenceNumber = 'TYH789742';
        esp.applicationReviewedFlag = 'TRUE';
        esp.applicationStatus = 'Draft proposal';
        esp.applicationType = 'Internship';
        esp.awardTransferredIndicator = 'Transfer In';
        esp.awardVisibility = 'Confidential';
        esp.applicationVisibility = 'Confidential';
        esp.awardId = 'AWA12345';
        esp.awardType = 'New Business';
        esp.projectId = '567384';
        esp.leadCollaborator = 'Monash Led';
        esp.fundingSchemeName = 'City of Whittlesea';
        esp.funderReferenceNumber = 'LP180101178';
        esp.collaboratorCount = '5';
        esp.fundingId = '12341234';
        esp.contractStatus = 'In Development';
        esp.industryRelatedFlag = 'False';
        esp.managingOrgUnitCode = '100021002';
        esp.managingOrgUnitId = '100021002';
        esp.managingOrgUnit = 'New Lead Collaborator Account';

        EnterpriseServicePayload.cls_accounts acct = new EnterpriseServicePayload.cls_accounts();
        acct.organisationID = '12344321';
        acct.dunsNumber = '12344321';
        acct.organisationIdentifier = 'ORG00001234';
        acct.accountName = 'Friendly Corporation';
        acct.accountType = 'Government';
        acct.externalIdentifier = 'Internal';
        acct.tradingName = 'Friendship Corporation';
        acct.organisationParent = '37899';
        acct.globalUltimateAccountName = 'Test Global Ultimate Account Name';
        acct.description = 'Test description about the collaborator';
        acct.website = 'http://abc.com';
        acct.tickerSymbol = 'Test symbol';
        acct.phone = '+61411415613';
        acct.billingStreet = 'Burwood street';
        acct.organisationCity = 'Sydney';
        acct.organisationState = 'New South Wales';
        acct.organisationZipCode = '8887';
        acct.organisationCountry = 'Australia';
        acct.shippingStreet = 'Swanston Street';
        acct.shippingCity = 'Perth';
        acct.shippingState = 'Western Australia';
        acct.shippingZipCode = '8889';
        acct.shippingCountry = 'Australia';
        acct.matchScore = '10';
        acct.globalUltimateDuns = 'GLO145678';
        acct.organisationIdentifierType = 'ACN';
        acct.altOrganisationIdentifierType = 'ACN';
        acct.altOrganisationIdentifier = 'ALTORG76869';
        acct.industryDivision = 'Test division';
        acct.industryMajorGroup = 'Test Group';
        acct.industryClassificationSIC4 = '200';
        acct.industryClassificationSIC8 = '100';
        acct.outOfBusinessIndicator = 'Test Indicator';
        acct.employeesCount = '15000';
        acct.employeeOverall = '15000';
        acct.annualRevenue = '1000,000';
        acct.fortuneRank = '49';
        acct.legalStructure = 'Test structure';
        acct.publicPrivateIndicator = 'Public';
        acct.salesVolume = '10,000';
        acct.salesVolumeAccuracy = '68';
        acct.fiscalYearEnd = 'March';
        acct.tradingName2 = 'Company ABC';
        acct.tradingName3 = 'Renolds Company';
        acct.nationalIdentifier3 = 'ACN';
        acct.nationalIdentifier4 = 'ACN';
        acct.badDebtor = 'FALSE';
        acct.primaryAccountFlag = 'FALSE';

        EnterpriseServicePayload.cls_accounts acct2 = new EnterpriseServicePayload.cls_accounts();
        acct2.organisationID = '12345432';
        acct2.dunsNumber = '02340002';
        acct2.organisationIdentifier = 'ORG00005432';
        acct2.accountName = 'Bestfriend Corporation';
        acct2.accountType = 'Government';
        acct2.externalIdentifier = 'External';
        acct2.tradingName = 'Bestfriend Corporation';
        acct2.organisationParent = '12344321';
        acct2.globalUltimateAccountName = 'Test Global Ultimate Account Name';
        acct2.description = 'Test description about the collaborator';
        acct2.website = 'http://abc.com';
        acct2.tickerSymbol = 'Test symbol';
        acct2.phone = '+61411415613';
        acct2.billingStreet = 'Burwood street';
        acct2.organisationCity = 'Sydney';
        acct2.organisationState = 'New South Wales';
        acct2.organisationZipCode = '8887';
        acct2.organisationCountry = 'Australia';
        acct2.shippingStreet = 'Swanston Street';
        acct2.shippingCity = 'Perth';
        acct2.shippingState = 'Western Australia';
        acct2.shippingZipCode = '8889';
        acct2.shippingCountry = 'Australia';
        acct2.matchScore = '10';
        acct2.globalUltimateDuns = 'GLO145678';
        acct2.organisationIdentifierType = 'ACN';
        acct2.altOrganisationIdentifierType = 'ACN';
        acct2.altOrganisationIdentifier = 'ALTORG76869';
        acct2.industryDivision = 'Test division';
        acct2.industryMajorGroup = 'Test Group';
        acct2.industryClassificationSIC4 = '200';
        acct2.industryClassificationSIC8 = '100';
        acct2.outOfBusinessIndicator = 'Test Indicator';
        acct2.employeesCount = '15000';
        acct2.employeeOverall = '15000';
        acct2.annualRevenue = '1000,000';
        acct2.fortuneRank = '49';
        acct2.legalStructure = 'Test structure';
        acct2.publicPrivateIndicator = 'Public';
        acct2.salesVolume = '10,000';
        acct2.salesVolumeAccuracy = '68';
        acct2.fiscalYearEnd = 'March';
        acct2.tradingName2 = 'Company ABC';
        acct2.tradingName3 = 'Renolds Company';
        acct2.nationalIdentifier3 = 'ACN';
        acct2.nationalIdentifier4 = 'ACN';
        acct2.badDebtor = 'FALSE';
        acct2.primaryAccountFlag = 'TRUE';

        EnterpriseServicePayload.cls_accounts acct3 = new EnterpriseServicePayload.cls_accounts();
        acct3.organisationID = '12345678';
        acct3.dunsNumber = '11102340002';
        acct3.organisationIdentifier = 'ORG10015432';
        acct3.accountName = 'Microsoft Corporation';
        acct3.accountType = 'Government';
        acct3.externalIdentifier = 'External';
        acct3.tradingName = 'Test Microsoft Corporation';
        acct3.globalUltimateAccountName = 'Test Global Ultimate Account Name';
        acct3.description = 'Test description about the collaborator';
        acct3.website = 'http://abc.com';
        acct3.tickerSymbol = 'Test symbol';
        acct3.phone = '+61411415613';
        acct3.billingStreet = 'Burwood street';
        acct3.organisationCity = 'Sydney';
        acct3.organisationState = 'New South Wales';
        acct3.organisationZipCode = '8887';
        acct3.organisationCountry = 'Australia';
        acct3.shippingStreet = 'Swanston Street';
        acct3.shippingCity = 'Perth';
        acct3.shippingState = 'Western Australia';
        acct3.shippingZipCode = '8889';
        acct3.shippingCountry = 'Australia';
        acct3.matchScore = '10';
        acct3.globalUltimateDuns = 'GLO145678';
        acct3.organisationIdentifierType = 'ACN';
        acct3.altOrganisationIdentifierType = 'ACN';
        acct3.altOrganisationIdentifier = 'ALTORG76869';
        acct3.industryDivision = 'Test division';
        acct3.industryMajorGroup = 'Test Group';
        acct3.industryClassificationSIC4 = '200';
        acct3.industryClassificationSIC8 = '100';
        acct3.outOfBusinessIndicator = 'Test Indicator';
        acct3.employeesCount = '15000';
        acct3.employeeOverall = '15000';
        acct3.annualRevenue = '1000000';
        acct3.fortuneRank = '49';
        acct3.legalStructure = 'Test structure';
        acct3.publicPrivateIndicator = 'Public';
        acct3.salesVolume = '10,000';
        acct3.salesVolumeAccuracy = '68';
        acct3.fiscalYearEnd = 'March';
        acct3.tradingName2 = 'Company ABC';
        acct3.tradingName3 = 'Reynolds Company';
        acct3.nationalIdentifier3 = 'ACN';
        acct3.nationalIdentifier4 = 'ACN';
        acct3.badDebtor = 'FALSE';
        acct3.primaryAccountFlag = 'FALSE';

        EnterpriseServicePayload.cls_funding acctFunding = new EnterpriseServicePayload.cls_funding();
        acctFunding.applicationId = '10272003';
        acctFunding.collaboratorIndicator = 'Collaborator';
        acct.funding = new List<EnterpriseServicePayload.cls_funding>();
        acct.funding.add(acctFunding);

        EnterpriseServicePayload.cls_funding acctFunding4 = new EnterpriseServicePayload.cls_funding();
        acctFunding4.applicationId = '10272003';
        acctFunding4.collaboratorIndicator = 'Collaborator';
        acct3.funding = new List<EnterpriseServicePayload.cls_funding>();
        acct3.funding.add(acctFunding4);

        EnterpriseServicePayload.cls_funding acctFunding1 = new EnterpriseServicePayload.cls_funding();
        EnterpriseServicePayload.cls_funding acctFunding2 = new EnterpriseServicePayload.cls_funding();
        EnterpriseServicePayload.cls_funding acctFunding3 = new EnterpriseServicePayload.cls_funding();

        acctFunding1.applicationId = '6595887';
        acctFunding1.appliedGrantAmount = '1000';
        acctFunding1.discountAmount = '';
        acctFunding1.awardedAmount = '-60000';
        acctFunding1.discountPercentage = '';
        acctFunding1.fundingDescription = '';
        acctFunding1.fundingCategory = 'Category 1';
        acctFunding1.funderReferenceNumber = 'DP110100752';
        acctFunding1.fundingCategoryDescription = 'Australian Competitive Grants';
        acctFunding1.fundingScheme = 'ARC Discovery Projects 2011 - applied 2010 - Grant component';
        acctFunding1.fundingType = 'Y';
        acctFunding1.fundingOrder = '1';
        acctFunding1.collaboratorIndicator = 'Funder';
        acctFunding1.fundingOpportunity = 'ARC Discovery Projects';
        acctFunding1.fundingSchemeId = '1001';

        acctFunding2.applicationId = '6595887';
        acctFunding2.appliedGrantAmount = '1000';
        acctFunding2.discountAmount = '';
        acctFunding2.awardedAmount = '150000';
        acctFunding2.discountPercentage = '';
        acctFunding2.fundingDescription = '';
        acctFunding2.fundingCategory = 'Category 1';
        acctFunding2.funderReferenceNumber = 'DP110100752';
        acctFunding2.fundingCategoryDescription = 'Australian Competitive Grants';
        acctFunding2.fundingScheme = 'ARC Discovery Projects 2011 - applied 2010 - Grant component';
        acctFunding2.fundingType = 'Y';
        acctFunding2.fundingOrder = '2';
        acctFunding2.collaboratorIndicator = 'Funder';
        acctFunding2.fundingOpportunity = 'ARC Discovery Projects';
        acctFunding2.fundingSchemeId = '1001';

        acctFunding3.applicationId = '6595887';
        acctFunding3.appliedGrantAmount = '1000';
        acctFunding3.discountAmount = '';
        acctFunding3.awardedAmount = '150000';
        acctFunding3.discountPercentage = '';
        acctFunding3.fundingDescription = '';
        acctFunding3.fundingCategory = 'Category 1';
        acctFunding3.funderReferenceNumber = 'DP110100752';
        acctFunding3.fundingCategoryDescription = 'Australian Competitive Grants';
        acctFunding3.fundingScheme = 'ARC Discovery Projects 2011 - applied 2010 - Grant component';
        acctFunding3.fundingType = 'N';
        acctFunding3.fundingOrder = '2';
        acctFunding3.collaboratorIndicator = 'Funder';
        acctFunding3.fundingOpportunity = 'ARC Discovery Projects';
        acctFunding3.fundingSchemeId = '1013';

        acct2.funding = new List<EnterpriseServicePayload.cls_funding>();
        acct2.funding.add(acctFunding1);
        acct2.funding.add(acctFunding2);
        acct2.funding.add(acctFunding3);

        EnterpriseServicePayload.cls_contacts con1 = new EnterpriseServicePayload.cls_contacts();
        con1.firstName = 'Joey';
        con1.lastName = 'Tribbiani';
        con1.fullName = 'Joey Tribbiani';
        con1.preferredName = 'Joey';
        con1.profile = 'Alumni';
        con1.salutation = 'Mr';
        con1.gender = 'Male';
        con1.primaryEmail = 'testemail@monash.edu';
        con1.secondaryEmail = '';
        con1.description = 'Description of the researcher';
        con1.orcId = '12341235';
        con1.researcherId = '346226525';
        con1.accountName = 'Friends Corporation';
        con1.facultyPortfolio = 'Test faculty';
        con1.divisionName = 'Test division';
        con1.primaryContactFlag = 'TRUE';
        con1.teamRole = 'Decision Maker';
        con1.organisationId = '12344321';

        EnterpriseServicePayload.cls_contacts con2 = new EnterpriseServicePayload.cls_contacts();
        con2.firstName = 'Chandler';
        con2.lastName = 'Bing';
        con2.fullName = 'Chandler Bing';
        con2.preferredName = 'Chandler';
        con2.profile = 'Monash Staff';
        con2.salutation = 'Mr';
        con2.gender = 'Male';
        con2.primaryEmail = 'chandlerbing@monash.edu';
        con2.secondaryEmail = '';
        con2.description = 'Description of the researcher';
        con2.orcId = '12344322';
        con2.researcherId = '346226526';
        con2.accountName = 'Bestfriends Corporation';
        con2.facultyPortfolio = 'Test faculty';
        con2.divisionName = 'Test division';
        con2.primaryContactFlag = 'False';
        con2.teamRole = 'Executive Sponsor';
        con2.organisationId = '12345432';

        EnterpriseServicePayload.cls_contacts con3 = new EnterpriseServicePayload.cls_contacts();
        con3.firstName = 'Rachel';
        con3.lastName = 'Green';
        con3.fullName = 'Rachel Green';
        con3.preferredName = 'Rachel';
        con3.profile = 'Monash Staff';
        con3.salutation = 'Ms';
        con3.gender = 'Female';
        con3.primaryEmail = 'rachelgreen@monash.edu';
        con3.secondaryEmail = '';
        con3.description = 'Description of the researcher';
        con3.orcId = '1323226526';
        con3.researcherId = '12344300';
        con3.accountName = 'Test Best friend Corporation';
        con3.facultyPortfolio = 'Test faculty';
        con3.divisionName = 'Test division';
        con3.primaryContactFlag = 'False';
        con3.teamRole = 'Executive Sponsor';
        con3.organisationId = '987654321';

        esp.accounts.add(acct);
        esp.accounts.add(acct2);
        esp.contacts.add(con1);
        esp.contacts.add(con2);
        esp.contacts.add(con3);

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(esp));
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
            EnterpriseService.updateData();
        Test.stopTest();

        System.assert([SELECT Id, PURE_Organisation_ID__c FROM Account WHERE PURE_Organisation_ID__c != NULL]?.isEmpty() == false, 'Create Account failed.' );
        System.assert([SELECT Id, Monash_System_ID__c FROM Opportunity WHERE Monash_System_ID__c !=NULL]?.isEmpty() == false, 'Create Opportunity failed.' );
        System.assert([SELECT Id, ORCID__c FROM Contact WHERE ORCID__c = '12341235']?.isEmpty() == false, 'Create Contact failed.' );

    }

    @IsTest
    static void testIntegrationUpdateAccount() {

        Id acctRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId();
        Account accountRecord = new Account(Name ='AccountTest', PURE_Organisation_ID__c='12345678', RecordTypeId=acctRecordTypeId) ;
        insert accountRecord;

        EnterpriseServicePayload esp = new EnterpriseServicePayload();
        esp.accounts = new List<EnterpriseServicePayload.cls_accounts>();
        esp.contacts = new List<EnterpriseServicePayload.cls_contacts>();

        esp.applicationId = '1027198990';
        esp.externalFunderId = 'CAF-2022-1513';
        esp.opportunityName = 'Test Opportunity for Friends Corporation';
        esp.serviceCatalogue = 'Research collaboration';
        esp.facultyType = 'Information Technology';
        esp.agreementCloseDate = '2013-07-26';
        esp.applicationStage = 'Closed Won';
        esp.provenance = 'PURE';
        esp.leadTimeToConvert = 'Less than 3 Months';
        esp.submissionDueDate = '2021-08-01';
        esp.projectDuration = '120';
        esp.projectStartDate = '2022-08-25';
        esp.projectEndDate = '2022-09-25';
        esp.proposalStatus = 'In-Progress';
        esp.proposalSubmissionDate = '2013-07-26';
        esp.competitiveGrantFlag = 'TRUE';
        esp.presentationSubmissionDate = '2013-07-26';
        esp.dateOfSubmissionToPartner = '2013-07-26';
        esp.contractSignedDate = '2013-07-26';
        esp.ogc_mroReferenceNumber = 'TYH789742';
        esp.applicationReviewedFlag = 'TRUE';
        esp.applicationStatus = 'Draft proposal';
        esp.applicationType = 'Internship';
        esp.awardTransferredIndicator = 'Transfer In';
        esp.awardVisibility = 'Confidential';
        esp.applicationVisibility = 'Confidential';
        esp.awardId = 'AWA12345';
        esp.awardType = 'New Business';
        esp.projectId = '567384';
        esp.leadCollaborator = 'Monash Led';
        esp.fundingSchemeName = 'City of Whittlesea';
        esp.funderReferenceNumber = 'LP180101178';
        esp.collaboratorCount = '5';
        esp.fundingId = '12341234';
        esp.contractStatus = 'In Development';
        esp.industryRelatedFlag = 'False';

        EnterpriseServicePayload.cls_accounts acct = new EnterpriseServicePayload.cls_accounts();
        acct.organisationID = '12345678';
        acct.dunsNumber = '12344321';
        acct.organisationIdentifier = 'ORG00001234';
        acct.accountName = 'Friendly Corporation';
        acct.accountType = 'Government';
        acct.externalIdentifier = 'Internal';
        acct.tradingName = 'Friendship Corporation';
        acct.organisationParent = '37899';
        acct.globalUltimateAccountName = 'Test Global Ultimate Account Name';
        acct.description = 'Test description about the collaborator';
        acct.website = 'http://abc.com';
        acct.tickerSymbol = 'Test symbol';
        acct.phone = '+61411415613';
        acct.billingStreet = 'Burwood street';
        acct.organisationCity = 'Sydney';
        acct.organisationState = 'New South Wales';
        acct.organisationZipCode = '8887';
        acct.organisationCountry = 'Australia';
        acct.shippingStreet = 'Swanston Street';
        acct.shippingCity = 'Perth';
        acct.shippingState = 'Western Australia';
        acct.shippingZipCode = '8889';
        acct.shippingCountry = 'Australia';
        acct.matchScore = '10';
        acct.globalUltimateDuns = 'GLO145678';
        acct.organisationIdentifierType = 'ACN';
        acct.altOrganisationIdentifierType = 'ACN';
        acct.altOrganisationIdentifier = 'ALTORG76869';
        acct.industryDivision = 'Test division';
        acct.industryMajorGroup = 'Test Group';
        acct.industryClassificationSIC4 = '200';
        acct.industryClassificationSIC8 = '100';
        acct.outOfBusinessIndicator = 'Test Indicator';
        acct.employeesCount = '15000';
        acct.employeeOverall = '15000';
        acct.annualRevenue = '1000000';
        acct.fortuneRank = '49';
        acct.legalStructure = 'Test structure';
        acct.publicPrivateIndicator = 'Public';
        acct.salesVolume = '10,000';
        acct.salesVolumeAccuracy = '68';
        acct.fiscalYearEnd = 'March';
        acct.tradingName2 = 'Company ABC';
        acct.tradingName3 = 'Renolds Company';
        acct.nationalIdentifier3 = 'ACN';
        acct.nationalIdentifier4 = 'ACN';
        acct.badDebtor = 'FALSE';
        acct.primaryAccountFlag = 'FALSE';

        EnterpriseServicePayload.cls_accounts acct2 = new EnterpriseServicePayload.cls_accounts();
        acct2.organisationID = '12345432';
        acct2.dunsNumber = '02340002';
        acct2.organisationIdentifier = 'ORG00005432';
        acct2.accountName = 'Bestfriend Corporation';
        acct2.accountType = 'Government';
        acct2.externalIdentifier = 'External';
        acct2.tradingName = 'Bestfriend Corporation';
        acct2.organisationParent = '12344321';
        acct2.globalUltimateAccountName = 'Test Global Ultimate Account Name';
        acct2.description = 'Test description about the collaborator';
        acct2.website = 'http://abc.com';
        acct2.tickerSymbol = 'Test symbol';
        acct2.phone = '+61411415613';
        acct2.billingStreet = 'Burwood street';
        acct2.organisationCity = 'Sydney';
        acct2.organisationState = 'New South Wales';
        acct2.organisationZipCode = '8887';
        acct2.organisationCountry = 'Australia';
        acct2.shippingStreet = 'Swanston Street';
        acct2.shippingCity = 'Perth';
        acct2.shippingState = 'Western Australia';
        acct2.shippingZipCode = '8889';
        acct2.shippingCountry = 'Australia';
        acct2.matchScore = '10';
        acct2.globalUltimateDuns = 'GLO145678';
        acct2.organisationIdentifierType = 'ACN';
        acct2.altOrganisationIdentifierType = 'ACN';
        acct2.altOrganisationIdentifier = 'ALTORG76869';
        acct2.industryDivision = 'Test division';
        acct2.industryMajorGroup = 'Test Group';
        acct2.industryClassificationSIC4 = '200';
        acct2.industryClassificationSIC8 = '100';
        acct2.outOfBusinessIndicator = 'Test Indicator';
        acct2.employeesCount = '15000';
        acct2.employeeOverall = '15000';
        acct2.annualRevenue = '1000,000';
        acct2.fortuneRank = '49';
        acct2.legalStructure = 'Test structure';
        acct2.publicPrivateIndicator = 'Public';
        acct2.salesVolume = '10,000';
        acct2.salesVolumeAccuracy = '68';
        acct2.fiscalYearEnd = 'March';
        acct2.tradingName2 = 'Company ABC';
        acct2.tradingName3 = 'Renolds Company';
        acct2.nationalIdentifier3 = 'ACN';
        acct2.nationalIdentifier4 = 'ACN';
        acct2.badDebtor = 'FALSE';
        acct2.primaryAccountFlag = 'TRUE';

        EnterpriseServicePayload.cls_funding acctFunding = new EnterpriseServicePayload.cls_funding();
        acctFunding.applicationId = '10272003';
        acctFunding.collaboratorIndicator = 'Collaborator';
        acct.funding = new List<EnterpriseServicePayload.cls_funding>();
        acct.funding.add(acctFunding);

        EnterpriseServicePayload.cls_funding acctFunding1 = new EnterpriseServicePayload.cls_funding();

        acctFunding1.applicationId = '6595887';
        acctFunding1.appliedGrantAmount = '1000';
        acctFunding1.discountAmount = '';
        acctFunding1.awardedAmount = '-60000';
        acctFunding1.discountPercentage = '';
        acctFunding1.fundingDescription = '';
        acctFunding1.fundingCategory = 'Category 1';
        acctFunding1.funderReferenceNumber = 'DP110100752';
        acctFunding1.fundingCategoryDescription = 'Australian Competitive Grants';
        acctFunding1.fundingScheme = 'ARC Discovery Projects 2011 - applied 2010 - Grant component';
        acctFunding1.fundingType = 'Y';
        acctFunding1.fundingOrder = '1';
        acctFunding1.collaboratorIndicator = 'Funder';
        acctFunding1.fundingOpportunity = 'ARC Discovery Projects';
        acctFunding1.fundingSchemeId = '1001';

        acct2.funding = new List<EnterpriseServicePayload.cls_funding>();
        acct2.funding.add(acctFunding1);

        EnterpriseServicePayload.cls_contacts con1 = new EnterpriseServicePayload.cls_contacts();
        con1.firstName = 'Joey';
        con1.lastName = 'Tribbiani';
        con1.fullName = 'Joey Tribbiani';
        con1.preferredName = 'Joey';
        con1.profile = 'Alumni';
        con1.salutation = 'Mr';
        con1.gender = 'Male';
        con1.primaryEmail = 'joeytribiani@gmail.com';
        con1.secondaryEmail = '';
        con1.description = 'Description of the researcher';
        con1.orcId = '12341235';
        con1.researcherId = '346226525';
        con1.accountName = 'Test Friends Corporation';
        con1.facultyPortfolio = 'Test faculty';
        con1.divisionName = 'Test division';
        con1.primaryContactFlag = 'TRUE';
        con1.teamRole = 'Decision Maker';
        con1.organisationId = '123400001';

        EnterpriseServicePayload.cls_contacts con2 = new EnterpriseServicePayload.cls_contacts();
        con2.firstName = 'Chandler';
        con2.lastName = 'Bing';
        con2.fullName = 'Chandler Bing';
        con2.preferredName = 'Chandler';
        con2.profile = 'Monash Staff';
        con2.salutation = 'Mr';
        con2.gender = 'Male';
        con2.primaryEmail = 'chandlerbing@monash.edu';
        con2.secondaryEmail = '';
        con2.description = 'Description of the researcher';
        con2.orcId = '12344322';
        con2.researcherId = '346226526';
        con2.accountName = 'Bestfriends Corporation';
        con2.facultyPortfolio = 'Test faculty';
        con2.divisionName = 'Test division';
        con2.primaryContactFlag = 'False';
        con2.teamRole = 'Executive Sponsor';
        con2.organisationId = '12345432';

        esp.accounts.add(acct);
        esp.accounts.add(acct2);
        esp.contacts.add(con1);
        esp.contacts.add(con2);

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(esp));
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        EnterpriseService.updateData();
        Test.stopTest();

        System.assert([SELECT Id, PURE_Organisation_ID__c FROM Account WHERE PURE_Organisation_ID__c != NULL]?.isEmpty() == false, 'Create Account failed.' );
        System.assert([SELECT Id, Monash_System_ID__c FROM Opportunity WHERE Monash_System_ID__c !=NULL]?.isEmpty() == false, 'Create Opportunity failed.' );
        System.assert([SELECT Id, ORCID__c FROM Contact WHERE ORCID__c = '12341235']?.isEmpty() == false, 'Create Contact failed.' );

    }

    @IsTest
    static void testIntegrationUpdatePureOrgId() {

        Id acctRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId();
        Account accountRecord = new Account(Name ='AccountTest', DBC_DUNS_Number__c='12345678', RecordTypeId=acctRecordTypeId) ;
        insert accountRecord;

        EnterpriseServicePayload esp = new EnterpriseServicePayload();
        esp.accounts = new List<EnterpriseServicePayload.cls_accounts>();
        esp.contacts = new List<EnterpriseServicePayload.cls_contacts>();

        esp.applicationId = '1027198990';
        esp.externalFunderId = 'CAF-2022-1513';
        esp.opportunityName = 'Test Opportunity for Friends Corporation';
        esp.serviceCatalogue = 'Research collaboration';
        esp.facultyType = 'Information Technology';
        esp.agreementCloseDate = '2013-07-26';
        esp.applicationStage = 'Closed Won';
        esp.provenance = 'PURE';
        esp.leadTimeToConvert = 'Less than 3 Months';
        esp.submissionDueDate = '2021-08-01';
        esp.projectDuration = '120';
        esp.projectStartDate = '2022-08-25';
        esp.projectEndDate = '2022-09-25';
        esp.proposalStatus = 'In-Progress';
        esp.proposalSubmissionDate = '2013-07-26';
        esp.competitiveGrantFlag = 'TRUE';
        esp.presentationSubmissionDate = '2013-07-26';
        esp.dateOfSubmissionToPartner = '2013-07-26';
        esp.contractSignedDate = '2013-07-26';
        esp.ogc_mroReferenceNumber = 'TYH789742';
        esp.applicationReviewedFlag = 'TRUE';
        esp.applicationStatus = 'Draft proposal';
        esp.applicationType = 'Internship';
        esp.awardTransferredIndicator = 'Transfer In';
        esp.awardVisibility = 'Confidential';
        esp.applicationVisibility = 'Confidential';
        esp.awardId = 'AWA12345';
        esp.awardType = 'New Business';
        esp.projectId = '567384';
        esp.leadCollaborator = 'Monash Led';
        esp.fundingSchemeName = 'City of Whittlesea';
        esp.funderReferenceNumber = 'LP180101178';
        esp.collaboratorCount = '5';
        esp.fundingId = '12341234';
        esp.contractStatus = 'In Development';
        esp.industryRelatedFlag = 'False';

        EnterpriseServicePayload.cls_accounts acct = new EnterpriseServicePayload.cls_accounts();
        acct.organisationID = '12345678';
        acct.dunsNumber = '12345678';
        acct.organisationIdentifier = 'ORG00001234';
        acct.accountName = 'Friendly Corporation';
        acct.accountType = 'Government';
        acct.externalIdentifier = 'Internal';
        acct.tradingName = 'Friendship Corporation';
        acct.organisationParent = '37899';
        acct.globalUltimateAccountName = 'Test Global Ultimate Account Name';
        acct.description = 'Test description about the collaborator';
        acct.website = 'http://abc.com';
        acct.tickerSymbol = 'Test symbol';
        acct.phone = '+61411415613';
        acct.billingStreet = 'Burwood street';
        acct.organisationCity = 'Sydney';
        acct.organisationState = 'New South Wales';
        acct.organisationZipCode = '8887';
        acct.organisationCountry = 'Australia';
        acct.shippingStreet = 'Swanston Street';
        acct.shippingCity = 'Perth';
        acct.shippingState = 'Western Australia';
        acct.shippingZipCode = '8889';
        acct.shippingCountry = 'Australia';
        acct.matchScore = '10';
        acct.globalUltimateDuns = 'GLO145678';
        acct.organisationIdentifierType = 'ACN';
        acct.altOrganisationIdentifierType = 'ACN';
        acct.altOrganisationIdentifier = 'ALTORG76869';
        acct.industryDivision = 'Test division';
        acct.industryMajorGroup = 'Test Group';
        acct.industryClassificationSIC4 = '200';
        acct.industryClassificationSIC8 = '100';
        acct.outOfBusinessIndicator = 'Test Indicator';
        acct.employeesCount = '15000';
        acct.employeeOverall = '15000';
        acct.annualRevenue = '1000000';
        acct.fortuneRank = '49';
        acct.legalStructure = 'Test structure';
        acct.publicPrivateIndicator = 'Public';
        acct.salesVolume = '10,000';
        acct.salesVolumeAccuracy = '68';
        acct.fiscalYearEnd = 'March';
        acct.tradingName2 = 'Company ABC';
        acct.tradingName3 = 'Renolds Company';
        acct.nationalIdentifier3 = 'ACN';
        acct.nationalIdentifier4 = 'ACN';
        acct.badDebtor = 'FALSE';
        acct.primaryAccountFlag = 'FALSE';

        EnterpriseServicePayload.cls_accounts acct2 = new EnterpriseServicePayload.cls_accounts();
        acct2.organisationID = '12345432';
        acct2.dunsNumber = '02340002';
        acct2.organisationIdentifier = 'ORG00005432';
        acct2.accountName = 'Bestfriend Corporation';
        acct2.accountType = 'Government';
        acct2.externalIdentifier = 'External';
        acct2.tradingName = 'Bestfriend Corporation';
        acct2.organisationParent = '12344321';
        acct2.globalUltimateAccountName = 'Test Global Ultimate Account Name';
        acct2.description = 'Test description about the collaborator';
        acct2.website = 'http://abc.com';
        acct2.tickerSymbol = 'Test symbol';
        acct2.phone = '+61411415613';
        acct2.billingStreet = 'Burwood street';
        acct2.organisationCity = 'Sydney';
        acct2.organisationState = 'New South Wales';
        acct2.organisationZipCode = '8887';
        acct2.organisationCountry = 'Australia';
        acct2.shippingStreet = 'Swanston Street';
        acct2.shippingCity = 'Perth';
        acct2.shippingState = 'Western Australia';
        acct2.shippingZipCode = '8889';
        acct2.shippingCountry = 'Australia';
        acct2.matchScore = '10';
        acct2.globalUltimateDuns = 'GLO145678';
        acct2.organisationIdentifierType = 'ACN';
        acct2.altOrganisationIdentifierType = 'ACN';
        acct2.altOrganisationIdentifier = 'ALTORG76869';
        acct2.industryDivision = 'Test division';
        acct2.industryMajorGroup = 'Test Group';
        acct2.industryClassificationSIC4 = '200';
        acct2.industryClassificationSIC8 = '100';
        acct2.outOfBusinessIndicator = 'Test Indicator';
        acct2.employeesCount = '15000';
        acct2.employeeOverall = '15000';
        acct2.annualRevenue = '1000,000';
        acct2.fortuneRank = '49';
        acct2.legalStructure = 'Test structure';
        acct2.publicPrivateIndicator = 'Public';
        acct2.salesVolume = '10,000';
        acct2.salesVolumeAccuracy = '68';
        acct2.fiscalYearEnd = 'March';
        acct2.tradingName2 = 'Company ABC';
        acct2.tradingName3 = 'Renolds Company';
        acct2.nationalIdentifier3 = 'ACN';
        acct2.nationalIdentifier4 = 'ACN';
        acct2.badDebtor = 'FALSE';
        acct2.primaryAccountFlag = 'TRUE';

        EnterpriseServicePayload.cls_funding acctFunding = new EnterpriseServicePayload.cls_funding();
        acctFunding.applicationId = '10272003';
        acctFunding.collaboratorIndicator = 'Collaborator';
        acct.funding = new List<EnterpriseServicePayload.cls_funding>();
        acct.funding.add(acctFunding);

        EnterpriseServicePayload.cls_funding acctFunding1 = new EnterpriseServicePayload.cls_funding();

        acctFunding1.applicationId = '6595887';
        acctFunding1.appliedGrantAmount = '1000';
        acctFunding1.discountAmount = '';
        acctFunding1.awardedAmount = '-60000';
        acctFunding1.discountPercentage = '';
        acctFunding1.fundingDescription = '';
        acctFunding1.fundingCategory = 'Category 1';
        acctFunding1.funderReferenceNumber = 'DP110100752';
        acctFunding1.fundingCategoryDescription = 'Australian Competitive Grants';
        acctFunding1.fundingScheme = 'ARC Discovery Projects 2011 - applied 2010 - Grant component';
        acctFunding1.fundingType = 'Y';
        acctFunding1.fundingOrder = '1';
        acctFunding1.collaboratorIndicator = 'Funder';
        acctFunding1.fundingOpportunity = 'ARC Discovery Projects';
        acctFunding1.fundingSchemeId = '1001';

        acct2.funding = new List<EnterpriseServicePayload.cls_funding>();
        acct2.funding.add(acctFunding1);

        EnterpriseServicePayload.cls_contacts con1 = new EnterpriseServicePayload.cls_contacts();
        con1.firstName = 'Joey';
        con1.lastName = 'Tribbiani';
        con1.fullName = 'Joey Tribbiani';
        con1.preferredName = 'Joey';
        con1.profile = 'Alumni';
        con1.salutation = 'Mr';
        con1.gender = 'Male';
        con1.primaryEmail = 'joeytribiani@gmail.com';
        con1.secondaryEmail = '';
        con1.description = 'Description of the researcher';
        con1.orcId = '12341235';
        con1.researcherId = '346226525';
        con1.accountName = 'Test Friends Corporation';
        con1.facultyPortfolio = 'Test faculty';
        con1.divisionName = 'Test division';
        con1.primaryContactFlag = 'TRUE';
        con1.teamRole = 'Decision Maker';
        con1.organisationId = '123400001';

        EnterpriseServicePayload.cls_contacts con2 = new EnterpriseServicePayload.cls_contacts();
        con2.firstName = 'Chandler';
        con2.lastName = 'Bing';
        con2.fullName = 'Chandler Bing';
        con2.preferredName = 'Chandler';
        con2.profile = 'Monash Staff';
        con2.salutation = 'Mr';
        con2.gender = 'Male';
        con2.primaryEmail = 'chandlerbing@monash.edu';
        con2.secondaryEmail = '';
        con2.description = 'Description of the researcher';
        con2.orcId = '12344322';
        con2.researcherId = '346226526';
        con2.accountName = 'Bestfriends Corporation';
        con2.facultyPortfolio = 'Test faculty';
        con2.divisionName = 'Test division';
        con2.primaryContactFlag = 'False';
        con2.teamRole = 'Executive Sponsor';
        con2.organisationId = '12345432';

        esp.accounts.add(acct);
        esp.accounts.add(acct2);
        esp.contacts.add(con1);
        esp.contacts.add(con2);

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(esp));
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        EnterpriseService.updateData();
        Test.stopTest();

        System.assert([SELECT Id, PURE_Organisation_ID__c FROM Account WHERE PURE_Organisation_ID__c != NULL]?.isEmpty() == false, 'Create Account failed.' );
        System.assert([SELECT Id, Monash_System_ID__c FROM Opportunity WHERE Monash_System_ID__c !=NULL]?.isEmpty() == false, 'Create Opportunity failed.' );
        System.assert([SELECT Id, ORCID__c FROM Contact WHERE ORCID__c = '12341235']?.isEmpty() == false, 'Create Contact failed.' );

    }
}