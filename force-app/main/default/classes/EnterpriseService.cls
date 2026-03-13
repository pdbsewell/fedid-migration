/**
 * @description       : Allow MIX integration to access (inbound) SF data.
 * @author            : Angelo Rivera
 * @group             : Engage Enterprise
 * @version           : Modifications Log
 * Ver   Date           Author              Modification
 * 1.0   30-08-2023     Angelo Rivera       Initial Creation
 * 1.0   18-10-2023     Angelo Rivera       Implemented the usage of BaseClass
 * 1.1   24-10-2023     Angelo Rivera       Handle duplicate accounts via duns and ABN
 * 1.2   14-11-2023     Angelo Rivera       ENGAGEIE-1836: Match correct Contact record
 * 1.3   15-11-2023     Angelo Rivera       ENGAGEIE-1835: Do not change Stage flag for opportunity
 * 1.4   17-11-2023     Angelo Rivera       ENGAGEIE-1844: Updated Search Contact logic
 * 1.5   21-11-2023     Angelo Rivera       ENGAGEIE-1845: Update Account with Pure Org Id
 * 1.5   24-11-2023     Angelo Rivera       Updating the Researcher ID, Orc ID and Email on existing contacts
 *                                              when any of the three fields mentioned are blank.
 * 1.6   29-11-2023     Angelo Rivera       ENGAGEIE-1855: Handle zero account and contacts on payload chunks
 * 1.7   05-12-2023     Angelo Rivera       ENGAGEIE-1865: Added logic and mapping for opportunity lead collaborator
 * 1.8   24-01-2024     Angelo Rivera       ENGAGEIE-1894: Create Opportunities with Primary Contacts
 *                                              that lack associated account details
 * 1.9   25-03-2024     Angelo Rivera       ENGAGEIE-1910: Do not change Closed Date flag for opportunity
 * 2.0   26-03-2024     Angelo Rivera       Updated the exception logging and used Nebula logger framework
 * 2.1   13-08-2025     Jackie Ho           ENGAGEIE-2006: Updated the logic for opportunity fields (PURE Award + Project ID)
**/

@RestResource(UrlMapping='/EnterpriseServices/*')
global without sharing class EnterpriseService {

    /**
     * @description Returns updated account record
     * @param       accountPayload - Account payload
     * @param       existingAccount - Existing Account record
     * @return      Account
     * @revision    22-11-2023     Angelo Rivera       Initial Creation
     */
    public static Account updateAccount(EnterpriseServicePayload.cls_accounts accountPayload, Account existingAccount){
        Account updatedAccount = new Account();
        updatedAccount = existingAccount;

        if(String.isBlank(updatedAccount.Trading_Name__c)) updatedAccount.Trading_Name__c = accountPayload.tradingName;
        if(String.isBlank(updatedAccount.Global_Ultimate_Account_Name__c)) updatedAccount.Global_Ultimate_Account_Name__c = accountPayload.globalUltimateAccountName;
        if(String.isBlank(updatedAccount.Description)) updatedAccount.Description = accountPayload.description;
        if(String.isBlank(updatedAccount.Website)) updatedAccount.Website = accountPayload.website;
        if(String.isBlank(updatedAccount.Phone)) updatedAccount.Phone = accountPayload.phone;
        if(String.isBlank(updatedAccount.BillingStreet)) updatedAccount.BillingStreet = accountPayload.billingStreet;
        if(String.isBlank(updatedAccount.BillingCity)) updatedAccount.BillingCity = accountPayload.organisationCity;
        if(String.isBlank(updatedAccount.BillingState)) updatedAccount.BillingState = accountPayload.organisationState;
        if(String.isBlank(updatedAccount.BillingPostalCode)) updatedAccount.BillingPostalCode = accountPayload.organisationZipCode;
        if(String.isBlank(updatedAccount.BillingCountry)) updatedAccount.BillingCountry = accountPayload.organisationCountry;
        if(String.isBlank(updatedAccount.ShippingStreet)) updatedAccount.ShippingStreet = accountPayload.shippingStreet;
        if(String.isBlank(updatedAccount.ShippingCity)) updatedAccount.ShippingCity = accountPayload.shippingCity;
        if(String.isBlank(updatedAccount.ShippingState)) updatedAccount.ShippingState = accountPayload.shippingState;
        if(String.isBlank(updatedAccount.ShippingPostalCode)) updatedAccount.ShippingPostalCode = accountPayload.shippingZipCode;
        if(String.isBlank(updatedAccount.ShippingCountry)) updatedAccount.ShippingCountry = accountPayload.shippingCountry;
        if(String.isBlank(updatedAccount.DBC_DUNS_Number__c)) updatedAccount.DBC_DUNS_Number__c = accountPayload.dunsNumber;
        if(String.isBlank(updatedAccount.Type)) updatedAccount.Type = accountPayload.accountType;
        if(String.isBlank(updatedAccount.Match_Score__c)) updatedAccount.Match_Score__c = accountPayload.matchScore;
        if(String.isBlank(updatedAccount.Global_Ultimate_DUNS_Number__c)) updatedAccount.Global_Ultimate_DUNS_Number__c = accountPayload.globalUltimateDuns;
        if(String.isBlank(updatedAccount.Organisation_Identifier_Type__c)) updatedAccount.Organisation_Identifier_Type__c = accountPayload.organisationIdentifierType;
        if(String.isBlank(updatedAccount.Organisation_Identifier__c)) updatedAccount.Organisation_Identifier__c = accountPayload.organisationIdentifier;
        if(String.isBlank(updatedAccount.Organisation_Identifier_Type_Alternative__c)) updatedAccount.Organisation_Identifier_Type_Alternative__c = accountPayload.altOrganisationIdentifierType;
        if(String.isBlank(updatedAccount.Organisation_Identifier_Alternative__c)) updatedAccount.Organisation_Identifier_Alternative__c = accountPayload.altOrganisationIdentifier;
        if(String.isBlank(updatedAccount.SIC_Division__c)) updatedAccount.SIC_Division__c = accountPayload.industryDivision;
        if(String.isBlank(updatedAccount.SicDesc)) updatedAccount.SicDesc = accountPayload.industryMajorGroup;
        if(String.isBlank(updatedAccount.Sic)) updatedAccount.Sic = accountPayload.industryClassificationSIC4;
        if(String.isBlank(updatedAccount.SIC8_Code__c)) updatedAccount.SIC8_Code__c = accountPayload.industryClassificationSIC8;
        if(String.isBlank(updatedAccount.Out_of_Business_Indicator__c)) updatedAccount.Out_of_Business_Indicator__c = accountPayload.outOfBusinessIndicator;
        if(String.isBlank(updatedAccount.Fortune_1000_Rank__c)) updatedAccount.Fortune_1000_Rank__c = accountPayload.fortuneRank;
        if(String.isBlank(updatedAccount.Legal_Structure__c)) updatedAccount.Legal_Structure__c = accountPayload.legalStructure;
        if(String.isBlank(updatedAccount.Public_Private_Indicator__c)) updatedAccount.Public_Private_Indicator__c = accountPayload.publicPrivateIndicator;
        if(String.isBlank(updatedAccount.Sales_Volume_Accuracy__c)) updatedAccount.Sales_Volume_Accuracy__c = accountPayload.salesVolumeAccuracy;
        if(String.isBlank(updatedAccount.Fiscal_Year_End__c)) updatedAccount.Fiscal_Year_End__c = accountPayload.fiscalYearEnd;
        if(String.isBlank(updatedAccount.Trading_Name_2__c)) updatedAccount.Trading_Name_2__c = accountPayload.tradingName2;
        if(String.isBlank(updatedAccount.Trading_Name_3__c)) updatedAccount.Trading_Name_3__c = accountPayload.tradingName3;
        if(String.isBlank(updatedAccount.Organisation_Identifier_3__c)) updatedAccount.Organisation_Identifier_3__c = accountPayload.nationalIdentifier3;
        if(String.isBlank(updatedAccount.Organisation_Identifier_4__c)) updatedAccount.Organisation_Identifier_4__c = accountPayload.nationalIdentifier4;
        if(String.isBlank(updatedAccount.Original_Id__c)) updatedAccount.Original_Id__c = (!String.isBlank(accountPayload.organisationID)) ? accountPayload.organisationID : accountPayload.dunsNumber;
        if(!String.isBlank(accountPayload.badDebtor)) updatedAccount.Bad_Debtor__c = Boolean.valueOf(accountPayload.badDebtor);
        if(String.isBlank(updatedAccount.TickerSymbol)){
            if(accountPayload.tickerSymbol.length() <= 20) updatedAccount.TickerSymbol = accountPayload.tickerSymbol;
        }
        if(String.isBlank(String.valueOf(updatedAccount.Sales_Volume__c))){
            if(!String.isBlank(accountPayload.salesVolume)) updatedAccount.Sales_Volume__c = Integer.valueOf(accountPayload.salesVolume.replaceAll('[^.\\d]',''));
        }
        if(String.isBlank(String.valueOf(updatedAccount.NumberOfEmployees))){
            if(!String.isBlank(accountPayload.employeesCount)) updatedAccount.NumberOfEmployees = Integer.valueOf(accountPayload.employeesCount.replaceAll('[^.\\d]',''));
        }
        if(String.isBlank(String.valueOf(updatedAccount.Employees_Overall__c))){
            if(accountPayload.employeeOverall.replaceAll('[^.\\d]','').isNumeric()){
                updatedAccount.Employees_Overall__c = Integer.valueOf(accountPayload.employeeOverall.replaceAll('[^.\\d]',''));
            }else{
                Nebula.Logger.info('Incorrect value for Employees_Overall__c - ' +  JSON.serialize(accountPayload));
            }
        }
        if(String.isBlank(String.valueOf(updatedAccount.AnnualRevenue))){
            if(!String.isBlank(accountPayload.annualRevenue)) updatedAccount.AnnualRevenue = Integer.valueOf(accountPayload.annualRevenue.replaceAll('[^.\\d]',''));
        }
        return updatedAccount;
    }

    /**
     * @description Returns account record
     * @param       accountPayload - Account payload
     * @param       externalAccountRecordTypeId - Account record type Id
     * @param       accountRecordId - account record Id
     * @return      Account
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     */
    public static Account generateAccount(EnterpriseServicePayload.cls_accounts accountPayload, Id externalAccountRecordTypeId, Id accountRecordId){
        Account newAccount = new Account();
        if(accountRecordId != null) newAccount.Id = accountRecordId;
        newAccount.RecordTypeId = externalAccountRecordTypeId;
        newAccount.Name = accountPayload.accountName;
        newAccount.PURE_Organisation_ID__c = accountPayload.organisationID;
        newAccount.Trading_Name__c = accountPayload.tradingName;
        newAccount.Global_Ultimate_Account_Name__c = accountPayload.globalUltimateAccountName;
        newAccount.Description = accountPayload.description;
        newAccount.Website = accountPayload.website;
        newAccount.Phone = accountPayload.phone;
        newAccount.BillingStreet = accountPayload.billingStreet;
        newAccount.BillingCity = accountPayload.organisationCity;
        newAccount.BillingState = accountPayload.organisationState;
        newAccount.BillingPostalCode = accountPayload.organisationZipCode;
        newAccount.BillingCountry = accountPayload.organisationCountry;
        newAccount.ShippingStreet = accountPayload.shippingStreet;
        newAccount.ShippingCity = accountPayload.shippingCity;
        newAccount.ShippingState = accountPayload.shippingState;
        newAccount.ShippingPostalCode = accountPayload.shippingZipCode;
        newAccount.ShippingCountry = accountPayload.shippingCountry;
        newAccount.DBC_DUNS_Number__c = accountPayload.dunsNumber;
        newAccount.Type = accountPayload.accountType;
        newAccount.Match_Score__c = accountPayload.matchScore;
        newAccount.Global_Ultimate_DUNS_Number__c = accountPayload.globalUltimateDuns;
        newAccount.Organisation_Identifier_Type__c = accountPayload.organisationIdentifierType;
        newAccount.Organisation_Identifier__c = accountPayload.organisationIdentifier;
        newAccount.Organisation_Identifier_Type_Alternative__c = accountPayload.altOrganisationIdentifierType;
        newAccount.Organisation_Identifier_Alternative__c = accountPayload.altOrganisationIdentifier;
        newAccount.SIC_Division__c = accountPayload.industryDivision;
        newAccount.SicDesc = accountPayload.industryMajorGroup;
        newAccount.Sic = accountPayload.industryClassificationSIC4;
        newAccount.SIC8_Code__c = accountPayload.industryClassificationSIC8;
        newAccount.Out_of_Business_Indicator__c = accountPayload.outOfBusinessIndicator;
        newAccount.Fortune_1000_Rank__c = accountPayload.fortuneRank;
        newAccount.Legal_Structure__c = accountPayload.legalStructure;
        newAccount.Public_Private_Indicator__c = accountPayload.publicPrivateIndicator;
        newAccount.Sales_Volume_Accuracy__c = accountPayload.salesVolumeAccuracy;
        newAccount.Fiscal_Year_End__c = accountPayload.fiscalYearEnd;
        newAccount.Trading_Name_2__c = accountPayload.tradingName2;
        newAccount.Trading_Name_3__c = accountPayload.tradingName3;
        newAccount.Organisation_Identifier_3__c = accountPayload.nationalIdentifier3;
        newAccount.Organisation_Identifier_4__c = accountPayload.nationalIdentifier4;
        newAccount.Original_Id__c = (!String.isBlank(accountPayload.organisationID)) ? accountPayload.organisationID : accountPayload.dunsNumber;
        if(!String.isBlank(accountPayload.salesVolume)) newAccount.Sales_Volume__c = Decimal.valueOf(accountPayload.salesVolume.replaceAll('[^.\\d]',''));
        if(!String.isBlank(accountPayload.employeesCount)) newAccount.NumberOfEmployees = Integer.valueOf(accountPayload.employeesCount.replaceAll('[^.\\d]',''));
        if(accountPayload.tickerSymbol.length() <= 20) newAccount.TickerSymbol = accountPayload.tickerSymbol;
        if(!String.isBlank(accountPayload.annualRevenue)) newAccount.AnnualRevenue = Decimal.valueOf(accountPayload.annualRevenue.replaceAll('[^.\\d]',''));
        if(!String.isBlank(accountPayload.badDebtor)) newAccount.Bad_Debtor__c = Boolean.valueOf(accountPayload.badDebtor);
        if(!String.isBlank(accountPayload.employeeOverall)){
            if(accountPayload.employeeOverall.replaceAll('[^.\\d]','').isNumeric()){
                newAccount.Employees_Overall__c = Integer.valueOf(accountPayload.employeeOverall.replaceAll('[^.\\d]',''));
            } else{
                Nebula.Logger.info('Incorrect value for Employees_Overall__c - ' + JSON.serialize(accountPayload), newAccount.Id);
            }
        }
        return newAccount;
    }

    /**
     * @description Returns Contact record
     * @param       contactPayload - Contact payload
     * @param       unknownContactRecordTypeId - Not Known To Monash Contact record type
     * @return      Contact
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     * @revision    14-11-2023     Angelo Rivera       Contact Profile assignment; Contact Recordtype Classification
     */
    public static Contact generateContact(EnterpriseServicePayload.cls_contacts contactPayload, Id unknownContactRecordTypeId){
        Contact newContact = new Contact();
        newContact.FirstName = contactPayload.firstName;
        newContact.LastName = contactPayload.lastName;
        newContact.Preferred_Name__c = contactPayload.preferredName;
        newContact.Salutation = contactPayload.salutation;
        newContact.GenderIdentity = contactPayload.gender;
        newContact.Personal_Email__c = contactPayload.secondaryEmail;
        newContact.Description = contactPayload.description;
        newContact.Researcher_ID__c = contactPayload.researcherId;
        newContact.ORCID__c = contactPayload.orcId;
        newContact.Faculty_Portfolio__c = contactPayload.facultyPortfolio;
        newContact.School_Division_Name__c = contactPayload.divisionName;
        newContact.RecordTypeId = unknownContactRecordTypeId;
        newContact.Contact_Profile__c = contactPayload.profile.contains('Monash Staff') ? 'Monash Staff [MST]' : contactPayload.profile;
        if(contactPayload.profile.contains('Monash Staff') && contactPayload.primaryEmail.contains('monash.edu')){
            newContact.Monash_Email_Address__c = contactPayload.primaryEmail;
        } else{
            newContact.Business_Email_Address__c = contactPayload.primaryEmail;
        }
        return newContact;
    }

    /**
     * @description Returns Opportunity record
     * @param       enterpriseServicePayload - Opportunity payload
     * @param       recordTypeId - Opportunity record type
     * @param       opportunityId - Opportunity record Id
     * @param       bDoNotChangeStageFlag - Do Not Change Stage flag
     * @param       bDoNotChangeClosedDateFlag - Do Not Change Closed Date flag
     * @return      Opportunity
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     * @revision    15-11-2023     Angelo Rivera       ENGAGEIE-1835: Do not change Stage flag for opportunity
     * @revision    25-03-2024     Angelo Rivera       ENGAGEIE-1910: Do not change Closed Date flag for opportunity
     */
    public static Opportunity generateOpportunity(EnterpriseServicePayload enterpriseServicePayload, Id recordTypeId, Id opportunityId, Boolean bDoNotChangeStageFlag, Boolean bDoNotChangeClosedDateFlag){
        Opportunity newOpp = new Opportunity();

        if(opportunityId != null) newOpp.Id = opportunityId;
        newOpp.RecordTypeId = recordTypeId;
        newOpp.Monash_System_ID__c = enterpriseServicePayload.applicationId;
        newOpp.PURE_Application_ID__c = enterpriseServicePayload.applicationId;
        newOpp.External_Funder_ID__c = enterpriseServicePayload.externalFunderId;
        newOpp.Name = enterpriseServicePayload.opportunityName;
        newOpp.Service_Catalogue_Alignment__c = enterpriseServicePayload.serviceCatalogue;
        newOpp.Broad_area_s_of_interest__c = enterpriseServicePayload.facultyType;
        if(!bDoNotChangeClosedDateFlag){
            if(!String.isBlank(enterpriseServicePayload.agreementCloseDate)) newOpp.CloseDate = Date.valueOf(enterpriseServicePayload.agreementCloseDate);
        }
        if(!bDoNotChangeStageFlag) newOpp.StageName = enterpriseServicePayload.applicationStage;
        newOpp.Provenance__c = enterpriseServicePayload.provenance;
        newOpp.Lead_Time_To_Convert__c = enterpriseServicePayload.leadTimeToConvert;
        if(!String.isBlank(enterpriseServicePayload.submissionDueDate)) newOpp.Proposal_Due_Date__c =Date.valueOf(enterpriseServicePayload.submissionDueDate);
        if(!String.isBlank(enterpriseServicePayload.projectStartDate)) newOpp.Expected_Funding_Start_Date__c = Date.valueOf(enterpriseServicePayload.projectStartDate);
        if(!String.isBlank(enterpriseServicePayload.projectEndDate)) newOpp.Expected_Funding_End_Date__c = Date.valueOf(enterpriseServicePayload.projectEndDate);
        newOpp.Proposal_Status__c = enterpriseServicePayload.proposalStatus;
        if(!String.isBlank(enterpriseServicePayload.proposalSubmissionDate)) newOpp.Proposal_Submission_Date__c = Date.valueOf(enterpriseServicePayload.proposalSubmissionDate);
        if(!String.isBlank(enterpriseServicePayload.competitiveGrantFlag)) newOpp.Presentation_Required__c = Boolean.valueOf(enterpriseServicePayload.competitiveGrantFlag);
        if(!String.isBlank(enterpriseServicePayload.presentationSubmissionDate)) newOpp.Presentation_Date__c = Date.valueOf(enterpriseServicePayload.presentationSubmissionDate);
        if(!String.isBlank(enterpriseServicePayload.dateOfSubmissionToPartner)) newOpp.Date_of_submission_to_partner__c = Date.valueOf(enterpriseServicePayload.dateOfSubmissionToPartner);
        if(!String.isBlank(enterpriseServicePayload.contractSignedDate)) newOpp.Contract_Signed_Date__c = Date.valueOf(enterpriseServicePayload.contractSignedDate);
        if(!String.isBlank(enterpriseServicePayload.applicationReviewedFlag)) newOpp.Reviewed_By_Internal_Stakeholders__c = Boolean.valueOf(enterpriseServicePayload.applicationReviewedFlag);
        newOpp.OGC_MRO_Reference_number__c = enterpriseServicePayload.ogc_mroReferenceNumber;
        newOpp.Application_Status__c = enterpriseServicePayload.applicationStatus;
        newOpp.Application_Type__c = enterpriseServicePayload.applicationType;
        newOpp.Award_Transferred_Status__c = enterpriseServicePayload.awardTransferredIndicator;
        if(!String.isBlank(enterpriseServicePayload.awardId)) newOpp.PURE_Award_ID__c = enterpriseServicePayload.awardId;
        newOpp.Type = enterpriseServicePayload.awardType;
        if(!String.isBlank(enterpriseServicePayload.projectId)) newOpp.Pure_Project_Id__c = enterpriseServicePayload.projectId;
        newOpp.Lead_Collaborator__c = enterpriseServicePayload.leadCollaborator;
        newOpp.Name_of_funding_scheme__c = enterpriseServicePayload.fundingSchemeName;
        newOpp.Funder_Ref__c = enterpriseServicePayload.funderReferenceNumber;
        if(!String.isBlank(enterpriseServicePayload.collaboratorCount)) newOpp.No_of_Collaborators__c = Decimal.valueOf(enterpriseServicePayload.collaboratorCount.replaceAll('[^.\\d]',''));
        newOpp.Contract_Status__c = enterpriseServicePayload.contractStatus;
        newOpp.Workflow_Status_Application__c = enterpriseServicePayload.applicationWorkflowStatus;
        newOpp.Workflow_Status_Award__c = enterpriseServicePayload.awardWorkflowStatus;
        newOpp.Award_Visibility__c = enterpriseServicePayload.awardVisibility;
        newOpp.Application_Visibility__c = enterpriseServicePayload.applicationVisibility;
        if(!String.isBlank(newOpp.StageName)){
            if(newOpp.StageName.contains('Closed Won') || newOpp.StageName.contains('Closed Lost')){
                if(!String.isBlank(enterpriseServicePayload.closedLostReason)){
                    newOpp.Closed_Reason__c = enterpriseServicePayload.closedLostReason;
                } else {
                    newOpp.Closed_Reason__c = 'Other';
                }
            }
        }
        if(!String.isBlank(enterpriseServicePayload.industryRelatedFlag)) newOpp.Industry_Related__c = Boolean.valueOf(enterpriseServicePayload.industryRelatedFlag);
        return newOpp;
    }

    /**
     * @description Checks if the opportunity is Industry Related
     * @param       bOpportunityIndustryRelatedFlag - Boolean flag
     * @param       funding - Funding Payload
     * @param       mapSetFundingOppQueryBySchemedId -  Map<String,Set<String>>
     * @param       setFundingSchemeIdsWithoutQuery - Set<String>
     * @return      Boolean
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     */
    public static Boolean setIndustryRelated(Boolean bOpportunityIndustryRelatedFlag, EnterpriseServicePayload.cls_funding funding,
            Map<String,Set<String>> mapSetFundingOppQueryBySchemedId, Set<String> setFundingSchemeIdsWithoutQuery){

        Boolean bIndustryRelated = false;
        // if opportunity payload's industryRelatedFlag = false
        if(!bOpportunityIndustryRelatedFlag){
            if(!setFundingSchemeIdsWithoutQuery.isEmpty()){
                // check the fundingSchemeId from FundingSchemeIds Without Query(Funding Scheme Broad)
                if(setFundingSchemeIdsWithoutQuery.contains(funding.fundingSchemeId)){
                    bIndustryRelated = true;
                }else{
                    if(!mapSetFundingOppQueryBySchemedId.isEmpty()){
                        // check the fundingSchemeId from FundingSchemeIds With Query(Funding Scheme Broad)
                        if(mapSetFundingOppQueryBySchemedId.containsKey(funding.fundingSchemeId)){
                            for(String fundingOpp : mapSetFundingOppQueryBySchemedId.get(funding.fundingSchemeId)){
                                // check the funding opportunity
                                if(String.isNotBlank(funding.fundingOpportunity) && funding.fundingOpportunity.contains(fundingOpp)){
                                    bIndustryRelated = true;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        return bIndustryRelated;
    }

    /**
     * @description Returns the data from Industry_Funding_Scheme__mdt
     * @return      Map
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     */
    public static Map<String, Industry_Funding_Scheme__mdt> getIndustryFunding(){
        Map<String, Industry_Funding_Scheme__mdt> mapIndustryFundingSchemesByScheme = new Map<String, Industry_Funding_Scheme__mdt>();
        mapIndustryFundingSchemesByScheme = Industry_Funding_Scheme__mdt.getAll();
        return mapIndustryFundingSchemesByScheme;
    }

    /**
     * @description Returns Funding record
     * @param       fundingPayload - Funding payload
     * @param       oppId - Opportunity IF
     * @param       acctId - account Id
     * @return      Funding__c
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     * @revision    22-11-2023     Angelo Rivera       Added mapping for In_Kind_Amount__c
     */
    public static Funding__c generateFunding(EnterpriseServicePayload.cls_funding fundingPayload, Id oppId, Id acctId){
        Funding__c newFunding = new Funding__c();
        newFunding.Opportunity__c = oppId;
        newFunding.Funder__c = acctId;
        newFunding.PURE_Application_ID__c = fundingPayload.applicationId;
        if(!String.isBlank(fundingPayload.appliedGrantAmount)) newFunding.Applied_Amount__c = Decimal.valueOf(fundingPayload.appliedGrantAmount.replaceAll('[^.\\d]',''));
        if(!String.isBlank(fundingPayload.discountAmount)) newFunding.Discount_Amount__c = Decimal.valueOf(fundingPayload.discountAmount.replaceAll('[^.\\d]',''));
        if(!String.isBlank(fundingPayload.discountPercentage)) newFunding.Discount__c = Decimal.valueOf(fundingPayload.discountPercentage.replaceAll('[^.\\d]',''));
        if(!String.isBlank(fundingPayload.awardedAmount)) newFunding.Awarded_Amount__c = Decimal.valueOf(fundingPayload.awardedAmount);
        newFunding.Funding_Description__c = fundingPayload.fundingDescription;
        newFunding.Funding_Category__c = fundingPayload.fundingCategory;
        newFunding.Funding_Category_Description__c = fundingPayload.fundingCategoryDescription;
        newFunding.Funding_Scheme__c = fundingPayload.fundingScheme;
        if(!String.isBlank(fundingPayload.fundingType)) newFunding.Funding_Type__c = fundingPayload.fundingType == 'Y' ? 'Financial' : 'Non-Financial';
        newFunding.Funding_Opportunity__c = fundingPayload.fundingOpportunity;
        if(!String.isBlank(fundingPayload.fundingOrder)){
            if(Integer.valueOf(fundingPayload.fundingOrder) == 1){
                newFunding.Primary_Funder__c = true;
            } else{
                newFunding.Primary_Funder__c = false;
            }
        }
        newFunding.UID__c = String.valueOf(oppId) + String.valueOf(acctId) + newFunding.Funding_Type__c + newFunding.Primary_Funder__c;
        if(!String.isBlank(fundingPayload.inKindAmount)) newFunding.In_Kind_Amount__c = Decimal.valueOf(fundingPayload.inKindAmount);
        return newFunding;
    }

    /**
     * @description Returns Opportunity Contact Role record
     * @param       bIsPrimary -  primary contact flag
     * @param       strRole -  contact role
     * @return      OpportunityContactRole
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     */
    public static OpportunityContactRole generateContactRole(Boolean bIsPrimary, String strRole){
        OpportunityContactRole opportunityContactRole = new OpportunityContactRole();
        opportunityContactRole.IsPrimary = bIsPrimary;
        opportunityContactRole.Role = strRole;
        return opportunityContactRole;
    }

    /**
     * @description Upserts record in database
     * @param       listSObjects - list of sObjects
     * @param       responseBody - EnterpriseServicePayload.cls_response
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     */
    public static void upsertRecords(List<SObject> listSObjects, EnterpriseServicePayload.cls_response responseBody){
        if(!listSObjects.isEmpty()){
            Database.UpsertResult[] csr;
            if(listSObjects.getSObjectType().getDescribe().getName()  == 'Opportunity_Collaborator__c'){
                Schema.SObjectField ocf = Opportunity_Collaborator__c.fields.UID__c;
                csr = Database.upsert(listSObjects, ocf, false);
            } else if(listSObjects.getSObjectType().getDescribe().getName()  == 'Funding__c'){
                Schema.SObjectField ff = Funding__c.fields.UID__c;
                csr = Database.upsert(listSObjects, ff,false);
            } else{
                csr = Database.upsert(listSObjects,false);
            }

            // Create counter
            Integer i=0;
            // Process the save results
            for(Database.UpsertResult sr : csr){
                if(!sr.isSuccess()){
                    // Get the first save result error
                    Database.Error err = sr.getErrors()[0];
                    Nebula.Logger.error('Database Error: ' + err, listSObjects[i]);
                    responseBody.response =  listSObjects.getSObjectType() + ': Error - ' + err.getMessage();
                }
                i++;
            }
            Nebula.Logger.saveLog();
        }
    }

    /**
     * @description Returns existing accounts from crm
     * @param       listDunsNumber - List of Duns Number
     * @param       listOrgIds - List of Organisation Ids
     * @param       listOrgIdentifiers -  List of Organisation identifiers
     * @param       listCallistaOrgUnitCode -  List of Callista Org Unit code
     * @return      List<Account>
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     * @revision    22-11-2023     Angelo Rivera       Added fields to query
     * @revision    05-12-2023     Angelo Rivera       Added Callista_Org_Unit_Code__c to query
     */
    public static List<Account> getExistingAccounts(List<String> listDunsNumber, List<String> listOrgIds, List<String> listOrgIdentifiers, List<String> listCallistaOrgUnitCode){
        String strWHERE =  ' DBC_DUNS_Number__c IN: listDunsNumber OR PURE_Organisation_ID__c IN: listOrgIds ' +
                            'OR Organisation_Identifier__c IN: listOrgIdentifiers OR Callista_Org_Unit_Code__c IN: listCallistaOrgUnitCode' ;
        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(true)
                .querySObject('Account')
                .queryFields(new Set<String> {'Id', 'Name', 'Callista_Org_Unit_Code__c', 'DBC_DUNS_Number__c' , 'PURE_Organisation_ID__c', 'Organisation_Identifier__c',
                        'Trading_Name__c','Global_Ultimate_Account_Name__c','Description','Website','Phone','BillingStreet','BillingCity','BillingState','BillingPostalCode',
                        'BillingCountry','ShippingStreet','ShippingCity','ShippingState','ShippingPostalCode','ShippingCountry','Organisation_Identifier_3__c','Type',
                        'Match_Score__c','Global_Ultimate_DUNS_Number__c','Organisation_Identifier_Type__c','Organisation_Identifier_Type_Alternative__c',
                        'Organisation_Identifier_Alternative__c','SIC_Division__c','SicDesc','SicDesc','Sic','SIC8_Code__c','Out_of_Business_Indicator__c','Fortune_1000_Rank__c',
                        'Legal_Structure__c','Public_Private_Indicator__c','Sales_Volume_Accuracy__c','Fiscal_Year_End__c','Trading_Name_2__c','Trading_Name_3__c',
                        'Organisation_Identifier_4__c','Original_Id__c','Bad_Debtor__c','TickerSymbol','Sales_Volume__c','NumberOfEmployees','Employees_Overall__c','AnnualRevenue'})
                .getQuery(strWHERE);
        List<Account> listExistingAccounts = new List<Account>();
        listExistingAccounts = Database.query(dynamicSOQL);
        return listExistingAccounts;
    }

    /**
     * @description Returns existing accounts from crm
     * @param       setContactEmails - List of Emails
     * @param       setContactOrcIds - List of Contact ORC Ids
     * @param       setResearcherIds -  List of Contact Researcher Ids
     * @param       knownRecordTypeId -  Known to Monash System contact record type
     * @param       unknownRecordTypeId - Not Known to Monash System contact record type
     * @return      List<Contact>
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     * @revision    14-11-2023     Angelo Rivera       Added logic on the query
     */
    public static List<Contact> getExistingContacts(Set<String> setContactEmails, Set<String> setContactOrcIds, Set<String> setResearcherIds, Id knownRecordTypeId, Id unknownRecordTypeId){
        String strWHERE = ' (Email IN: setContactEmails OR Monash_Email_Address__c IN: setContactEmails OR Personal_Email__c IN: setContactEmails OR Business_Email_Address__c IN: setContactEmails  ' +
                'OR ORCID__c IN: setContactOrcIds OR Researcher_ID__c IN: setResearcherIds) AND (RecordTypeId =: knownRecordTypeId OR RecordTypeId =: unknownRecordTypeId)';
        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(true)
                .querySObject('Contact')
                .queryFields(new Set<String> {'Id', 'Email','ORCID__c','RecordTypeId','Researcher_ID__c','SAP_Staff_Id__c', 'Monash_Email_Address__c','Personal_Email__c','Business_Email_Address__c'})
                .getQuery(strWHERE);
        dynamicSOQL += ' ORDER BY SAP_Staff_Id__c ASC NULLS Last';
        List<Contact> listExistingContacts = new List<Contact>();
        listExistingContacts = Database.query(dynamicSOQL);
        return listExistingContacts;
    }

    /**
     * @description Returns existing Opportunity from crm
     * @param       applicationId - Opportunity's Monash_System_ID__c
     * @param       opportunityRecordTypeId -  Opportunity record type id
     * @return      List<Opportunity>
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     */
    public static List<Opportunity> getExistingOpportunities(String applicationId, Id opportunityRecordTypeId){
        String strWHERE = ' RecordTypeId =: opportunityRecordTypeId AND (PURE_Application_ID__c =: enterpriseServicePayload.applicationId OR Monash_System_ID__c =: enterpriseServicePayload.applicationId)';
        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(true)
                .setLimit(1)
                .querySObject('Opportunity')
                .queryFields(new Set<String> {'Id', 'Monash_System_ID__c' , 'RecordTypeId', 'Do_not_change_Stage__c', 'PURE_Application_ID__c', 'Do_not_change_close_date__c'})
                .getQuery(strWHERE);

        List<Opportunity> listExistingOpportunities = new List<Opportunity>();
        listExistingOpportunities = Database.query(dynamicSOQL);
        return listExistingOpportunities;
    }

    /**
     * @description Returns existing OpportunityContactRole from crm
     * @param       opportunityId - opportunity record id
     * @return      List<OpportunityContactRole>
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     */
    public static List<OpportunityContactRole> getOpportunityContactRoles(Id opportunityId){
        String strWHERE = ' OpportunityId =: opportunityId';
        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(true)
                .querySObject('OpportunityContactRole')
                .queryFields(new Set<String> {'Id', 'ContactId', 'Contact.Researcher_ID__c', 'Contact.ORCID__c', 'Contact.Email','OpportunityId', 'Role'})
                .getQuery(strWHERE);

        List<OpportunityContactRole> listOpportunityContactRoles = new List<OpportunityContactRole>();
        listOpportunityContactRoles = Database.query(dynamicSOQL);
        return listOpportunityContactRoles;
    }

    /**
     * @description Returns existing Opportunity_Collaborator__c from crm
     * @param       opportunityId - opportunity record id
     * @return      List<OpportunityContactRole>
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     */
    public static List<Opportunity_Collaborator__c> getOpportunityCollaborator(Id opportunityId){
        String strWHERE = ' Opportunity__c =: opportunityId';
        String dynamicSOQL = DynamicSoqlBuilder.getInstance()
                .showSOQLStatement(true)
                .setEnforced(true)
                .querySObject('Opportunity_Collaborator__c')
                .queryFields(new Set<String> { 'Id', 'Organisation__r.PURE_Organisation_ID__c','Organisation__r.DBC_DUNS_Number__c','Opportunity__c', 'Organisation__c'})
                .getQuery(strWHERE);

        List<Opportunity_Collaborator__c> listOpportunityCollaborator = new List<Opportunity_Collaborator__c>();
        listOpportunityCollaborator = Database.query(dynamicSOQL);
        return listOpportunityCollaborator;
    }

    /**
     * @description Returns existing contact record
     * @param       contactPayload - contact payload
     * @param       mapContactWithSAPStaffIdByEmail - map of contact with SAP Staff Id by Email
     * @param       mapContactByResearcherId - map of contact by Researcher ID
     * @param       mapContactByOrcId - map of contact by ORC Id
     * @param       mapContactWithResearcherOrcIdByEmail - map of contact with Researcher or ORC ID by Email
     * @param       mapContactByEmail - map of contact
     * @return      contactRecord
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     */
    public static Contact selectContactRecord(EnterpriseServicePayload.cls_contacts contactPayload, Map<String, Contact> mapContactWithSAPStaffIdByEmail, Map<String, Contact> mapContactByResearcherId,
            Map<String, Contact> mapContactByOrcId, Map<String, Contact> mapContactWithResearcherOrcIdByEmail, Map<String, Contact> mapContactByEmail){
        Contact contactRecord;
        // check if contact payload has monash email; Profile=Monash Staff; has SAP Staff Id (if Existing)
        if(String.isNotBlank(contactPayload.primaryEmail) && contactPayload.primaryEmail.contains('monash.edu') && contactPayload.profile.contains('Monash') && mapContactWithSAPStaffIdByEmail.containsKey(contactPayload.primaryEmail)){
            contactRecord = mapContactWithSAPStaffIdByEmail.get(contactPayload.primaryEmail);
        }
        // check if primary contact payload matches the existing contact using researcherId
        else if(String.isNotBlank(contactPayload.researcherId) && mapContactByResearcherId.containsKey(contactPayload.researcherId)){
            contactRecord = mapContactByResearcherId.get(contactPayload.researcherId);
        }
        // check if primary contact payload matches the existing contact using orcId
        else if(String.isNotBlank(contactPayload.orcId) && mapContactByOrcId.containsKey(contactPayload.orcId)){
            contactRecord = mapContactByOrcId.get(contactPayload.orcId);
        }
        // check if primary contact payload matches the email; in case there are duplicate contacts with same email, prioritise contacts with Researcher Id or ORC Id
        else if(String.isNotBlank(contactPayload.primaryEmail) && mapContactWithResearcherOrcIdByEmail.containsKey(contactPayload.primaryEmail)){
            contactRecord = mapContactWithResearcherOrcIdByEmail.get(contactPayload.primaryEmail);
        }
        // check if primary contact payload matches the email; in case there are duplicate contacts with same email, and both without Researcher Id and ORC Id
        // the most recently created contact will be selected
        else if(String.isNotBlank(contactPayload.primaryEmail) && mapContactByEmail.containsKey(contactPayload.primaryEmail)){
            contactRecord = mapContactByEmail.get(contactPayload.primaryEmail);
        }
        return contactRecord;
    }

    /**
   * @description Returns existing account record
   * @param       mapAccountByOrgIds - map of account Pure Org id
   * @param       mapAccountByDunsNumber - map of account by Duns Number
   * @param       mapAccountByABN - map of Account by ABN
   * @param       accountPayload - account payload
   * @return      Account record
   * @revision    05-12-2023     Angelo Rivera       Initial Creation
   */
    public static Account selectAccountRecord(Map<String, Account> mapAccountByOrgIds, Map<String, Account> mapAccountByDunsNumber,
                                                Map<String, Account> mapAccountByABN, EnterpriseServicePayload.cls_accounts accountPayload){
        Account selectedAccount = new Account();
        if (mapAccountByOrgIds.containsKey(accountPayload.organisationID)) {
            selectedAccount = mapAccountByOrgIds.get(accountPayload.organisationID);
        } else if (mapAccountByDunsNumber.containsKey(accountPayload.dunsNumber)) {
            selectedAccount = mapAccountByDunsNumber.get(accountPayload.dunsNumber);
        } else if (mapAccountByABN.containsKey(accountPayload.organisationIdentifier)) {
            selectedAccount = mapAccountByABN.get(accountPayload.organisationIdentifier);
        }
        return  selectedAccount;
    }

    /**
    * @description Returns map of funding scheme
    * @param       mapSetFundingWithOppQuery - set of Opportunity Query for funding scheme
    * @param       setFundingSchemeIdsWithoutOppQuery - Set fo Funding Scheme
    * @param       mapIndustryFundingSchemesByScheme - map of Industry funding by scheme
    * @revision    05-12-2023     Angelo Rivera       Initial Creation
    */
    public static void getMapOfFundingSchemes( Map<String,Set<String>> mapSetFundingWithOppQuery, Set<String> setFundingSchemeIdsWithoutOppQuery, Map<String, Industry_Funding_Scheme__mdt> mapIndustryFundingSchemesByScheme){
        for(String fundingSchemeName : mapIndustryFundingSchemesByScheme.keySet()){
            if(mapIndustryFundingSchemesByScheme.get(fundingSchemeName).Funding_Opportunity_Query__c == null){
                setFundingSchemeIdsWithoutOppQuery.add(mapIndustryFundingSchemesByScheme.get(fundingSchemeName).Funding_Scheme_ID__c);
            } else {
                if(mapSetFundingWithOppQuery.containsKey(mapIndustryFundingSchemesByScheme.get(fundingSchemeName).Funding_Scheme_ID__c)){
                    mapSetFundingWithOppQuery.get(mapIndustryFundingSchemesByScheme.get(fundingSchemeName).Funding_Scheme_ID__c).add(mapIndustryFundingSchemesByScheme.get(fundingSchemeName).Funding_Opportunity_Query__c);
                }else{
                    Set<String> srtFundingOppQuery = new Set<String>();
                    srtFundingOppQuery.add(mapIndustryFundingSchemesByScheme.get(fundingSchemeName).Funding_Opportunity_Query__c);
                    mapSetFundingWithOppQuery.put(mapIndustryFundingSchemesByScheme.get(fundingSchemeName).Funding_Scheme_ID__c, srtFundingOppQuery);
                }
            }
        }
    }

    /**
     * @description This api receives payload from MIX which contains Application, Account, contact and funding records
     * @revision    30-08-2023     Angelo Rivera       Initial Creation
     * @revision    14-11-2023     Angelo Rivera       ENGAGEIE-1836: Match correct Contact record
     * @revision    15-11-2023     Angelo Rivera       ENGAGEIE-1835: Do not change Stage flag for opportunity
     * @revision    17-11-2023     Angelo Rivera       ENGAGEIE-1844: Updated Search Contact logic
     * @revision    21-11-2023     Angelo Rivera       ENGAGEIE-1845: Update Account with Pure Org Id
     * @revision    24-11-2023     Angelo Rivera       Updating the Researcher ID, Orc ID and Email on existing contacts
     *                                                      when any of the three fields mentioned are blank.
     * @revision    29-11-2023     Angelo Rivera       ENGAGEIE-1855: Handle zero account and contacts on payload chunks
     * @revision    05-12-2023     Angelo Rivera       ENGAGEIE-1865: Added logic and mapping for opportunity lead collaborator
     * @revision    24-01-2024     Angelo Rivera       ENGAGEIE-1894: Create Opportunities with Primary Contacts
     *                                                      that lack associated account details
     * @revision    25-03-2024     Angelo Rivera       ENGAGEIE-1910: Do not change Closed Date flag for opportunity
     */
    @HttpPost
    webService static void updateData() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        EnterpriseServicePayload.cls_response responseBody = new EnterpriseServicePayload.cls_response();
        responseBody.response = '';
        if(request.requestBody.toString() != null){
            try {
                // deserialize JSON payload here
                EnterpriseServicePayload enterpriseServicePayload =  (EnterpriseServicePayload) JSON.deserialize(request.requestBody.toString(), EnterpriseServicePayload.class);
                //LogUtilityException.addLogEvent('Payload','EnterpriseService', JSON.serializePretty(enterpriseServicePayload),'EnterpriseService');

                // check for existing opportunity
                Boolean bExistingOpportunity = false;
                Id opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
                for(Opportunity opportunity : getExistingOpportunities(enterpriseServicePayload.applicationId, opportunityRecordTypeId)){
                    if(opportunity.Id != null) bExistingOpportunity = true;
                }

                if(!bExistingOpportunity && enterpriseServicePayload.accounts.isEmpty()){
                    responseBody.response = 'Error: No Account found in the payload!';
                    Nebula.Logger.error('No Account found in the payload! - ' + JSON.serialize(enterpriseServicePayload));
                    response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
                    response.statusCode = 400;
                    return;
                }
                // Account Logic
                // iterate through account payload
                if((bExistingOpportunity && !enterpriseServicePayload.accounts.isEmpty()) || (bExistingOpportunity && enterpriseServicePayload.accounts.isEmpty()) || (!bExistingOpportunity && !enterpriseServicePayload.accounts.isEmpty())){
                    Id externalAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId();
                    Id monashOrgAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();
                    List<Account> listNewAccounts = new List<Account>();
                    Map<String,EnterpriseServicePayload.cls_accounts> mapAccountPayloadByPureOrgId = new Map<String, EnterpriseServicePayload.cls_accounts>();
                    Map<String,EnterpriseServicePayload.cls_accounts> mapAccountPayloadByDunsNumber = new Map<String, EnterpriseServicePayload.cls_accounts>();
                    EnterpriseServicePayload.cls_accounts primaryAccountPayload = new EnterpriseServicePayload.cls_accounts();
                    List<String> listDunsNumber = new List<String>();
                    List<String> listOrgIds = new List<String>();
                    List<String> listOrgIdentifiers = new List<String>();
                    List<String> listCallistaOrgUnitCode = new List<String>();
                    Opportunity opp = new Opportunity();
                    List<Funding__c> listFunding = new List<Funding__c>();

                    BaseClass bc = new BaseClass();
                    bc.initialize(new List<Schema.SObjectType> {
                            Account.SObjectType,
                            Contact.SObjectType,
                            Opportunity.SObjectType,
                            Funding__c.SObjectType,
                            Opportunity_Collaborator__c.SObjectType,
                            OpportunityContactRole.SObjectType
                    });

                    // iterate over Account payload to collate account identifiers
                    if(!enterpriseServicePayload.accounts.isEmpty()){
                        for (EnterpriseServicePayload.cls_accounts accountPayload : enterpriseServicePayload.accounts) {
                            if (!String.isBlank(accountPayload.dunsNumber)) listDunsNumber.add(accountPayload.dunsNumber);
                            if (!String.isBlank(accountPayload.organisationID)) listOrgIds.add(accountPayload.organisationID);
                            if (!String.isBlank(accountPayload.organisationIdentifier)) listOrgIdentifiers.add(accountPayload.organisationIdentifier);
                            if (!String.isBlank(accountPayload.organisationParent)) listOrgIds.add(accountPayload.organisationParent);
                            if (!String.isBlank(accountPayload.dunsNumber)) mapAccountPayloadByDunsNumber.put(accountPayload.dunsNumber, accountPayload);
                            if (!String.isBlank(accountPayload.organisationID)) mapAccountPayloadByPureOrgId.put(accountPayload.organisationID, accountPayload);

                            // Logic for primaryAccountFlag; Opportunity's Parent Account
                            if (Boolean.valueOf(accountPayload.primaryAccountFlag)) {
                                primaryAccountPayload = accountPayload;
                            }
                        }
                    }
                    // get the opportunity's lead collaborator
                    if(!String.isBlank(enterpriseServicePayload.managingOrgUnitId)) listOrgIds.add(enterpriseServicePayload.managingOrgUnitId);
                    if(!String.isBlank(enterpriseServicePayload.managingOrgUnitCode)) listCallistaOrgUnitCode.add(enterpriseServicePayload.managingOrgUnitCode);

                    // iterate over contact payload to collate account org ids
                    for(EnterpriseServicePayload.cls_contacts contactPayload : enterpriseServicePayload.contacts){
                        if(!String.isBlank(contactPayload.organisationId)) listOrgIds.add(contactPayload.organisationId);
                    }

                    // get all existing accounts using the PURE_Organisation_ID__c
                    List<Account> listExistingAccounts = new List<Account>();
                    Map<String, Account> mapAccountByOrgIds = new Map<String, Account>();
                    Map<String, Account> mapAccountByDunsNumber = new Map<String, Account>();
                    Map<String, Account> mapAccountByABN = new Map<String, Account>();
                    Map<String, Account> mapAccountByCallistaOrgUnitCode = new Map<String, Account>();

                    listExistingAccounts.addAll(getExistingAccounts(listDunsNumber,listOrgIds,listOrgIdentifiers,listCallistaOrgUnitCode));
                    if(!listExistingAccounts.isEmpty()){
                        for(Account acc : listExistingAccounts){
                            mapAccountByOrgIds.put(acc.PURE_Organisation_ID__c, acc);
                            mapAccountByCallistaOrgUnitCode.put(acc.Callista_Org_Unit_Code__c,acc);
                            mapAccountByDunsNumber.put(acc.DBC_DUNS_Number__c, acc);
                            mapAccountByABN.put(acc.Organisation_Identifier__c, acc);
                        }
                    }

                    // Create/Update account
                    Set<String> setAccountPayloadOrgId = new Set<String>();
                    Set<String> setAccountPayloadDunsNumber = new Set<String>();
                    if(!enterpriseServicePayload.accounts.isEmpty()) {
                        for (EnterpriseServicePayload.cls_accounts accountPayload : enterpriseServicePayload.accounts) {
                            if (!String.isBlank(accountPayload.accountName)) {
                                if (!setAccountPayloadOrgId.contains(accountPayload.organisationID)) {
                                    if (!setAccountPayloadDunsNumber.contains(accountPayload.dunsNumber)) {
                                        if (accountPayload != null) {
                                            Account existingAccount = new Account();
                                            Boolean bDunsExist = false;
                                            Boolean bPureOrgIdExist = false;

                                            if (mapAccountByOrgIds.containsKey(accountPayload.organisationID)) {
                                                existingAccount = mapAccountByOrgIds.get(accountPayload.organisationID);
                                                bPureOrgIdExist = true;
                                            } else if (mapAccountByDunsNumber.containsKey(accountPayload.dunsNumber)) {
                                                existingAccount = mapAccountByDunsNumber.get(accountPayload.dunsNumber);
                                                bDunsExist = true;
                                            } else if (mapAccountByABN.containsKey(accountPayload.organisationIdentifier)) {
                                                existingAccount = mapAccountByABN.get(accountPayload.organisationIdentifier);
                                            }

                                            // generate account
                                            // if Account is not existing create it in CRM
                                            Account acc = new Account();
                                            if (String.isBlank(existingAccount.Id)) {
                                                acc = generateAccount(accountPayload, externalAccountRecordTypeId, existingAccount.Id);
                                                bc.push(acc);
                                            }

                                            // check if account exists, found using the Org Id (meaning DBC_DUNS_Number__c is empty)
                                            // update the details of the account
                                            if (bPureOrgIdExist && String.isBlank(existingAccount.DBC_DUNS_Number__c)) {
                                                if (String.isNotBlank(accountPayload.dunsNumber)) {
                                                    acc = updateAccount(accountPayload, existingAccount);
                                                    bc.push(acc);
                                                }
                                            }

                                            // check if account exists, found using the duns number (meaning PURE_Organisation_ID__c is empty)
                                            // Update only the PURE_Organisation_ID__c
                                            if (bDunsExist && String.isNotBlank(accountPayload.organisationID)) {
                                                Account existingAcc = new Account();
                                                existingAcc.Id = existingAccount.Id;
                                                existingAcc.PURE_Organisation_ID__c = accountPayload.organisationID;
                                                bc.push(existingAcc);
                                            }

                                            // get the parent account and relate it to the account
                                            Account parentAccount;
                                            if (mapAccountByOrgIds.containsKey(accountPayload.organisationParent)) {
                                                parentAccount = mapAccountByOrgIds.get(accountPayload.organisationParent);
                                                bc.relate(acc, Account.ParentId, parentAccount);
                                            }

                                            setAccountPayloadOrgId.add(accountPayload.organisationID);
                                            setAccountPayloadDunsNumber.add(accountPayload.dunsNumber);
                                            listNewAccounts.add(acc);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // check if the opportunity lead collaborator is an existing account
                    Account leadCollaboratorAccount;
                    if(String.isNotBlank(enterpriseServicePayload.managingOrgUnitCode)){
                        if(mapAccountByCallistaOrgUnitCode.containsKey(enterpriseServicePayload.managingOrgUnitCode)){
                            // pick the existing lead collaborator account using the Callista Org Unit Code
                            leadCollaboratorAccount = mapAccountByCallistaOrgUnitCode.get(enterpriseServicePayload.managingOrgUnitCode);
                        } else{
                            // pick the existing lead collaborator account using the Pure Org Id
                            if(mapAccountByOrgIds.containsKey(enterpriseServicePayload.managingOrgUnitId)){
                                leadCollaboratorAccount = mapAccountByOrgIds.get(enterpriseServicePayload.managingOrgUnitId);
                            }
                        }
                        // create the account before creating as lead collaborator
                        if(leadCollaboratorAccount == null){
                            leadCollaboratorAccount = new Account();
                            leadCollaboratorAccount.RecordTypeId = monashOrgAccountRecordTypeId;
                            leadCollaboratorAccount.Name = enterpriseServicePayload.managingOrgUnit;
                            leadCollaboratorAccount.PURE_Organisation_ID__c = enterpriseServicePayload.managingOrgUnitId;
                            leadCollaboratorAccount.Callista_Org_Unit_Code__c = enterpriseServicePayload.managingOrgUnitCode;
                            bc.push(leadCollaboratorAccount);
                            listNewAccounts.add(leadCollaboratorAccount);
                        }
                    }

                    // generate map of account for later use
                    if(!listNewAccounts.isEmpty()) {
                        for (Account acc : listNewAccounts) {
                            if (!mapAccountByOrgIds.containsKey(acc.PURE_Organisation_ID__c)) mapAccountByOrgIds.put(acc.PURE_Organisation_ID__c, acc);
                            if (!mapAccountByDunsNumber.containsKey(acc.DBC_DUNS_Number__c)) mapAccountByDunsNumber.put(acc.DBC_DUNS_Number__c, acc);
                            if (!mapAccountByABN.containsKey(acc.Organisation_Identifier__c)) mapAccountByABN.put(acc.Organisation_Identifier__c, acc);
                            if (!mapAccountByCallistaOrgUnitCode.containsKey(acc.Callista_Org_Unit_Code__c)) mapAccountByCallistaOrgUnitCode.put(acc.Callista_Org_Unit_Code__c, acc);
                        }
                    }

                    // Contact Logic
                    Id unknownContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId();
                    Id knownContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId();
                    Set<String> setContactEmails = new Set<String>();
                    Set<String> setContactResearcherIds = new Set<String>();
                    Set<String> setContactOrcIds = new Set<String>();
                    EnterpriseServicePayload.cls_contacts primaryContactPayload = new EnterpriseServicePayload.cls_contacts();
                    Map<String, EnterpriseServicePayload.cls_contacts> mapContactPayloadByAccountName = new Map<String, EnterpriseServicePayload.cls_contacts>();
                    List<Contact> listNewContacts = new List<Contact>();
                    List<Contact> listExistingContacts = new List<Contact>();
                    Contact primaryContact = new Contact();
                    Map<String, Contact> mapContactByEmail = new Map<String, Contact>();
                    Map<String, Contact> mapContactByOrcId = new Map<String, Contact>();
                    Map<String, Contact> mapContactByResearcherId = new Map<String, Contact>();
                    Map<String, Contact> mapContactWithSAPStaffIdByEmail = new Map<String, Contact>();
                    Map<String, Contact> mapContactWithResearcherOrcIdByEmail = new Map<String, Contact>();

                    // Opportunity Logic
                    opportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();

                    // get existing opportunity
                    Boolean bOpportunityIndustryRelatedFlag = false;
                    Boolean bDoNotChangeStageFlag = false;
                    Boolean bDoNotChangeClosedDate = false;

                    for(Opportunity opportunity : getExistingOpportunities(enterpriseServicePayload.applicationId, opportunityRecordTypeId)){
                        // check if 'Do not change Stage' is true
                        if(opportunity.Do_not_change_Stage__c) bDoNotChangeStageFlag = true;
                        if(opportunity.Do_not_change_close_date__c) bDoNotChangeClosedDate = true;
                        opp = generateOpportunity(enterpriseServicePayload, opportunityRecordTypeId, opportunity.Id, bDoNotChangeStageFlag, bDoNotChangeClosedDate);
                        bExistingOpportunity = true;
                    }
                    // Generate new opportunity
                    if(!bExistingOpportunity){
                        opp = generateOpportunity(enterpriseServicePayload, opportunityRecordTypeId, null, false, false);
                    }

                    Account primaryAccountRecord;
                    // checks that there is primary account payload for new opportunity
                    if(String.isBlank(primaryAccountPayload.organisationID) && !bExistingOpportunity){
                        responseBody.response = 'Error: No Primary Account found from the payload!';
                        response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
                        response.statusCode = 400;
                        Nebula.Logger.error('No Primary Account found from the payload! - ' +  JSON.serialize(enterpriseServicePayload));
                        return;
                    }
                    else{
                        // get the existing primary account
                        primaryAccountRecord = selectAccountRecord(mapAccountByOrgIds,mapAccountByDunsNumber,mapAccountByABN,primaryAccountPayload);

                        // make sure the parent account exists before adding Opportunity, Contact
                        if(primaryAccountRecord == null && !bExistingOpportunity){
                            responseBody.response = 'Error: No Primary Account found from the the system!';
                            response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
                            response.statusCode = 400;
                            Nebula.Logger.error('No Primary Account found from the system! - ' + JSON.serialize(enterpriseServicePayload));
                            return;
                        }
                        else {
                            if(opp.Id == null){
                                bc.push(opp, Opportunity.AccountId, primaryAccountRecord);
                            }else{
                                bc.push(opp);
                            }

                            if(!enterpriseServicePayload.contacts.isEmpty()){
                                // iterate through contact payload to check for the Opportunity's primary contact
                                for(EnterpriseServicePayload.cls_contacts contactPayload: enterpriseServicePayload.contacts){
                                    if(String.isNotBlank(contactPayload.primaryEmail)) setContactEmails.add(contactPayload.primaryEmail);
                                    if(String.isNotBlank(contactPayload.researcherId))setContactResearcherIds.add(contactPayload.researcherId);
                                    if(String.isNotBlank(contactPayload.orcId))setContactOrcIds.add(contactPayload.orcId);
                                    if(String.isNotBlank(contactPayload.accountName)) mapContactPayloadByAccountName.put(contactPayload.accountName, contactPayload);
                                    if(Boolean.valueOf(contactPayload.primaryContactFlag)) primaryContactPayload = contactPayload;
                                }
                            }
                            if(String.isBlank(primaryContactPayload.lastName) && !bExistingOpportunity){
                                responseBody.response = 'Error: Opportunity\'s Primary Contact cannot be found!';
                                response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
                                response.statusCode = 400;
                                Nebula.Logger.error('Primary Contact cannot be found! - ' + JSON.serialize(enterpriseServicePayload));
                                return;
                            }
                            else{
                                if(!enterpriseServicePayload.contacts.isEmpty()){
                                    // Check and get all existing contact using contact payload's email, ORC ids, Researcher ids
                                    listExistingContacts.addAll(getExistingContacts(setContactEmails, setContactOrcIds, setContactResearcherIds,unknownContactRecordTypeId,knownContactRecordTypeId));
                                    if(!listExistingContacts.isEmpty()){
                                        for(Contact con : listExistingContacts){
                                            mapContactByEmail.put(con.Email, con);
                                            mapContactByEmail.put(con.Monash_Email_Address__c, con);
                                            mapContactByEmail.put(con.Personal_Email__c, con);
                                            mapContactByEmail.put(con.Business_Email_Address__c, con);
                                            mapContactByOrcId.put(con.ORCID__c, con);
                                            mapContactByResearcherId.put(con.Researcher_ID__c, con);
                                            // if contact email has SAP_Staff_Id__c
                                            if(String.isNotBlank(con.SAP_Staff_Id__c)){
                                                mapContactWithSAPStaffIdByEmail.put(con.Email, con);
                                                mapContactWithSAPStaffIdByEmail.put(con.Monash_Email_Address__c, con);
                                                mapContactWithSAPStaffIdByEmail.put(con.Personal_Email__c, con);
                                                mapContactWithSAPStaffIdByEmail.put(con.Business_Email_Address__c, con);
                                            }
                                            // if contact email has Researcher_ID__c or ORCID__c
                                            if(String.isNotBlank(con.Researcher_ID__c) || String.isNotBlank(con.ORCID__c)){
                                                mapContactWithResearcherOrcIdByEmail.put(con.Email, con);
                                                mapContactWithResearcherOrcIdByEmail.put(con.Monash_Email_Address__c, con);
                                                mapContactWithResearcherOrcIdByEmail.put(con.Personal_Email__c, con);
                                                mapContactWithResearcherOrcIdByEmail.put(con.Business_Email_Address__c, con);
                                            }
                                        }
                                    }

                                    // Contact Payload Handling Logic
                                    for(EnterpriseServicePayload.cls_contacts contactPayload: enterpriseServicePayload.contacts){
                                        // if the contact does not match any of the three unique parameters, then create a new one
                                        if(!mapContactByEmail.containsKey(contactPayload.primaryEmail) && !mapContactByOrcId.containsKey(contactPayload.orcId)
                                                && !mapContactByResearcherId.containsKey(contactPayload.researcherId)){
                                            // make sure that at least one of the three unique parameters is present before creating the contact
                                            if(String.isNotBlank(contactPayload.primaryEmail) || String.isNotBlank(contactPayload.researcherId) || String.isNotBlank(contactPayload.orcId)){
                                                // get the contact's existing parent account
                                                Account acct;
                                                if(String.isNotBlank(contactPayload.organisationId)){
                                                if(mapAccountByOrgIds.containsKey(contactPayload.organisationId)){
                                                    acct = mapAccountByOrgIds.get(contactPayload.organisationId);
                                                } else{ // generate account if it is not existing
                                                        if(String.isNotBlank(contactPayload.accountName)){
                                                    acct = new Account();
                                                    acct.RecordTypeId = externalAccountRecordTypeId;
                                                    acct.Name = contactPayload.accountName;
                                                    acct.PURE_Organisation_ID__c = contactPayload.organisationId;
                                                    bc.push(acct);
                                                }
                                                    }
                                                }
                                                // create the contact and link to the account
                                                    Contact con = new Contact();
                                                    con = generateContact(contactPayload, unknownContactRecordTypeId);
                                                if(acct != null){
                                                    bc.push(con, Contact.AccountId, acct);
                                                } else{
                                                    bc.push(con);
                                                }
                                                listNewContacts.add(con);
                                            }
                                        }
                                        else{ // logic to update the contact when it is existing
                                            Contact existingCon = new Contact();
                                            //check if the contact payload is matching with the existing contact's email with SAP Id
                                            if(mapContactWithSAPStaffIdByEmail.containsKey(contactPayload.primaryEmail) && String.isNotBlank(contactPayload.primaryEmail)){
                                                existingCon = mapContactWithSAPStaffIdByEmail.get(contactPayload.primaryEmail);
                                                if(String.isBlank(existingCon.Researcher_ID__c) && String.isNotBlank(contactPayload.researcherId)){
                                                    existingCon.Researcher_ID__c = contactPayload.researcherId;
                                                }
                                                if(String.isBlank(existingCon.ORCID__c) && String.isNotBlank(contactPayload.orcId)){
                                                    existingCon.ORCID__c = contactPayload.orcId;
                                                }
                                            }
                                            //check if the contact payload is matching with the existing contact's Researcher ID
                                            else if(mapContactByResearcherId.containsKey(contactPayload.researcherId) && String.isNotBlank(contactPayload.researcherId)){
                                                existingCon = mapContactByResearcherId.get(contactPayload.researcherId);
                                                //update ORCID__c and/or Email
                                                if(String.isBlank(existingCon.ORCID__c) && String.isNotBlank(contactPayload.orcId)){
                                                    existingCon.ORCID__c = contactPayload.orcId;
                                                }
                                                if(String.isNotBlank(contactPayload.primaryEmail)){
                                                    if(contactPayload.profile.contains('Monash Staff') && contactPayload.primaryEmail.contains('monash.edu')){
                                                        if(String.isBlank(existingCon.Monash_Email_Address__c)) existingCon.Monash_Email_Address__c = contactPayload.primaryEmail;
                                                    } else{
                                                        if(String.isBlank(existingCon.Business_Email_Address__c)) existingCon.Business_Email_Address__c = contactPayload.primaryEmail;
                                                    }
                                                }
                                            }
                                            //check if the contact payload is matching with the existing contact's ORC ID
                                            else if(mapContactByOrcId.containsKey(contactPayload.orcId)  && String.isNotBlank(contactPayload.orcId)){
                                                existingCon = mapContactByOrcId.get(contactPayload.orcId);
                                                //update Researcher_ID__c and/or Email
                                                if(String.isBlank(existingCon.Researcher_ID__c) && String.isNotBlank(contactPayload.researcherId)){
                                                    existingCon.Researcher_ID__c = contactPayload.researcherId;
                                                }
                                                if(String.isNotBlank(contactPayload.primaryEmail)){
                                                    if(contactPayload.profile.contains('Monash Staff') && contactPayload.primaryEmail.contains('monash.edu')){
                                                        if(String.isBlank(existingCon.Monash_Email_Address__c)) existingCon.Monash_Email_Address__c = contactPayload.primaryEmail;
                                                    } else{
                                                        if(String.isBlank(existingCon.Business_Email_Address__c)) existingCon.Business_Email_Address__c = contactPayload.primaryEmail;
                                                    }
                                                }
                                            }
                                            //check if the contact payload is matching with the existing contact's email
                                            else if(mapContactByEmail.containsKey(contactPayload.primaryEmail) && String.isNotBlank(contactPayload.primaryEmail)){
                                                existingCon = mapContactByEmail.get(contactPayload.primaryEmail);
                                                // just update update Researcher_ID__c and/or ORCID__c
                                                if(String.isBlank(existingCon.Researcher_ID__c) && String.isNotBlank(contactPayload.researcherId)){
                                                    existingCon.Researcher_ID__c = contactPayload.researcherId;
                                                }
                                                if(String.isBlank(existingCon.ORCID__c) && String.isNotBlank(contactPayload.orcId)){
                                                    existingCon.ORCID__c = contactPayload.orcId;
                                                }
                                            }
                                            // update the existing contact in CRM
                                            if(existingCon.Id != null) bc.push(existingCon);
                                        }
                                    }
                                }

                                if(primaryContactPayload != null){
                                    // locate opportunity primary contact from the existing contacts
                                    primaryContact = selectContactRecord(primaryContactPayload, mapContactWithSAPStaffIdByEmail, mapContactByResearcherId,mapContactByOrcId,mapContactWithResearcherOrcIdByEmail,mapContactByEmail);

                                    // If opportunity primary contact from the payload is not existing, link the generated primary contact to the opportunity
                                    if(primaryContact == null){
                                        for(Contact con : listNewContacts){
                                            if(primaryContactPayload.primaryEmail == con.Email || primaryContactPayload.orcId == con.ORCID__c ||  primaryContactPayload.researcherId == con.Researcher_ID__c){
                                                primaryContact = con;
                                            }
                                        }
                                        if(primaryContact != null) bc.relate(opp, Opportunity.PrimaryContact__c, primaryContact);
                                    }
                                }

                                // add the newly generated contacts to the contact map for later usage
                                Set<Id> setContactIds = new Set<Id>();
                                for(Contact con : listNewContacts){
                                    if(!mapContactByOrcId.containsKey(con.ORCID__c)) mapContactByOrcId.put(con.ORCID__c, con);
                                    if(!mapContactByResearcherId.containsKey(con.Researcher_ID__c)) mapContactByResearcherId.put(con.Researcher_ID__c, con);
                                    if(!mapContactByEmail.containsKey(con.Email)) mapContactByEmail.put(con.Email, con);
                                    setContactIds.add(con.Id);
                                }

                                // get existing OpportunityContactRole
                                Set<String> setResearcherIds = new Set<String>();
                                for(OpportunityContactRole opportunityContactRole : getOpportunityContactRoles(opp.Id)){
                                    setResearcherIds.add(opportunityContactRole.Contact.Researcher_ID__c);
                                    setResearcherIds.add(opportunityContactRole.Contact.ORCID__c);
                                    setResearcherIds.add(opportunityContactRole.Contact.Email);
                                }

                                // iterate over Contact payload and get the contact record
                                for(EnterpriseServicePayload.cls_contacts contactPayload: enterpriseServicePayload.contacts){
                                    Contact contactRecord;
                                    // locate contact each contact payload from the map of existing contacts
                                    contactRecord = selectContactRecord(contactPayload, mapContactWithSAPStaffIdByEmail, mapContactByResearcherId,mapContactByOrcId,mapContactWithResearcherOrcIdByEmail,mapContactByEmail);

                                    // generate opportunity contact roles and push
                                    if(contactRecord != null && !setResearcherIds.contains(contactPayload.researcherId)
                                            && !setResearcherIds.contains(contactPayload.orcId) && !setResearcherIds.contains(contactPayload.primaryEmail)){
                                        OpportunityContactRole ocr = new OpportunityContactRole();
                                        ocr = generateContactRole(Boolean.valueOf(contactPayload.primaryContactFlag), contactPayload.teamRole);
                                        bc.push(ocr, OpportunityContactRole.ContactId, contactRecord);
                                        bc.relate(ocr, OpportunityContactRole.OpportunityId, opp);
                                    }
                                }
                                // commit records - Account, Opportunity, Contact, Opportunity Contact Roles
                                bc.commitRecords();
                                responseBody.response = 'Success';

                                // check that there are accounts from payload before processing Fundings
                                if(!enterpriseServicePayload.accounts.isEmpty()) {
                                    // funding logic
                                    Id oppCollabRecordTypeId = Schema.SObjectType.Opportunity_Collaborator__c.getRecordTypeInfosByDeveloperName().get('Opportunity').getRecordTypeId();

                                    // get Industry Funding from custom metadata
                                    Map<String, Industry_Funding_Scheme__mdt> mapIndustryFundingSchemesByScheme = new Map<String, Industry_Funding_Scheme__mdt>();
                                    mapIndustryFundingSchemesByScheme.putAll(EnterpriseService.getIndustryFunding());

                                    Map<String,Set<String>> mapSetFundingWithOppQuery = new Map<String, Set<String>>();
                                    Set<String> setFundingSchemeIdsWithoutOppQuery = new Set<String>();

                                    // perform logic of getting the funding scheme for later use (setting the Opportunity as Industry Related)
                                    getMapOfFundingSchemes(mapSetFundingWithOppQuery,setFundingSchemeIdsWithoutOppQuery,mapIndustryFundingSchemesByScheme);

                                    Map<String, Opportunity_Collaborator__c> mapOppCollaboratorByOrgId = new Map<String, Opportunity_Collaborator__c>();
                                    Map<String, Opportunity_Collaborator__c> mapOppCollaboratorByDunsNumber = new Map<String, Opportunity_Collaborator__c>();
                                    for(Opportunity_Collaborator__c oc : getOpportunityCollaborator(opp.Id)){
                                        if(!mapOppCollaboratorByOrgId.containsKey(oc.Organisation__r.PURE_Organisation_ID__c))mapOppCollaboratorByOrgId.put(oc.Organisation__r.PURE_Organisation_ID__c, oc);
                                        if(!mapOppCollaboratorByDunsNumber.containsKey(oc.Organisation__r.DBC_DUNS_Number__c))mapOppCollaboratorByDunsNumber.put(oc.Organisation__r.DBC_DUNS_Number__c, oc);
                                    }

                                    // generate the Lead Opportunity Collaborator and push
                                    if(leadCollaboratorAccount != null){
                                        Opportunity_Collaborator__c olc = new Opportunity_Collaborator__c();
                                        if(!mapOppCollaboratorByOrgId.containsKey(enterpriseServicePayload.managingOrgUnitId)) {
                                            olc.RecordTypeId = oppCollabRecordTypeId;
                                            olc.Lead__c = true;
                                            olc.Relationship_Type__c = 'Internal Organisation';
                                            bc.push(olc, Opportunity_Collaborator__c.Opportunity__c, opp);
                                            bc.relate(olc, Opportunity_Collaborator__c.Organisation__c, leadCollaboratorAccount);
                                        } else{
                                            olc.Id = mapOppCollaboratorByOrgId.get(enterpriseServicePayload.managingOrgUnitId).Id;
                                            if(!olc.Lead__c){
                                                olc.Lead__c = true;
                                                bc.push(olc, Opportunity_Collaborator__c.Opportunity__c, opp);
                                            }
                                        }
                                    }

                                    // loop through account payload and get funding payload
                                    Set<String> setStringUID = new Set<String>();
                                    for (EnterpriseServicePayload.cls_accounts accountPayload : enterpriseServicePayload.accounts) {
                                        // make sure theres funding payload
                                        if (!accountPayload.funding.isEmpty()) {
                                            for (EnterpriseServicePayload.cls_funding funding : accountPayload.funding) {

                                                Account acc;
                                                // get the existing Funder or Collaborator Account first
                                                acc = selectAccountRecord(mapAccountByOrgIds,mapAccountByDunsNumber,mapAccountByABN,accountPayload);

                                                if (funding.collaboratorIndicator == 'Funder') {
                                                    //generate funding and push
                                                    if (acc != null) {
                                                        Funding__c f = new Funding__c();
                                                        f = generateFunding(funding, opp.Id, acc.Id);
                                                        if (!setStringUID.contains(f.UID__c)) listFunding.add(f);
                                                        setStringUID.add(f.UID__c);
                                                    }
                                                    // check to see if Funding is Industry Related, if yes, update Opportunity
                                                    if (!String.isBlank(enterpriseServicePayload.industryRelatedFlag)) {
                                                        bOpportunityIndustryRelatedFlag = EnterpriseService.setIndustryRelated(Boolean.valueOf(enterpriseServicePayload.industryRelatedFlag), funding, mapSetFundingWithOppQuery, setFundingSchemeIdsWithoutOppQuery);
                                                    }
                                                } else {
                                                    if (acc != null) {
                                                        // generate Opportunity Collaborator and push
                                                        if(!mapOppCollaboratorByOrgId.isEmpty() && !mapOppCollaboratorByOrgId.containsKey(accountPayload.organisationID)
                                                                && !mapOppCollaboratorByDunsNumber.containsKey(accountPayload.dunsNumber)) {
                                                            Opportunity_Collaborator__c oc = new Opportunity_Collaborator__c();
                                                            oc.RecordTypeId = oppCollabRecordTypeId;
                                                            bc.push(oc, Opportunity_Collaborator__c.Opportunity__c, opp);
                                                            bc.relate(oc, Opportunity_Collaborator__c.Organisation__c, acc);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                // check to see if Funding is Industry Related, if yes, update Opportunity
                                if(bOpportunityIndustryRelatedFlag){
                                    Opportunity oppToUpdate = new Opportunity();
                                    oppToUpdate = opp;
                                    opp.Industry_Related__c = true;
                                    bc.push(oppToUpdate);
                                }
                                // commit records -  Opportunity_Collaborator__c, Opportunity Update
                                bc.commitRecords();
                            }
                        }
                    }
                    // need to use upsert to make use of the external id
                    if(!listFunding.isEmpty()){
                        upsertRecords(listFunding, responseBody);
                    }
                }
                else{
                    responseBody.response = 'Error: No Account found in the payload!';
                    Nebula.Logger.error('No Account found in the payload! - ' +  JSON.serialize(enterpriseServicePayload));
                    response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
                    response.statusCode = 400;
                }
            } catch (Exception e) {
                responseBody.response = 'Caught an Error: ' + e.getTypeName() + ' - ' + e.getMessage();
                response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
                response.statusCode = 400;
                Nebula.Logger.error('Line number ' + e.getLineNumber() + ' : ' + e.getMessage() + ' - ' + e.getStackTraceString());
            }
        } else{
            responseBody.response = 'Error in request payload';
            response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
            response.statusCode = 400;
            Nebula.Logger.error('Error in request payload - ' +  JSON.serialize(response));
        }
        // Log the exceptions
        Nebula.Logger.saveLog();
        response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
        return;
    }
}