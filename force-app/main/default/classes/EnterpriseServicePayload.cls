/**
 * @description       : Enterprise service payload
 * @author            : Angelo Rivera
 * @group             : Engage Enterprise
 * @version           : Modifications Log
 * Ver   Date           Author              Modification
 * 1.0   30-08-2023     Angelo Rivera       Initial Creation
 * 1.1   22-11-2023     Angelo Rivera       Added mapping for In_Kind_Amount__c
 * 1.2   05-12-2023     Angelo Rivera       Added mapping for lead collaborator
 * 1.2   05-12-2023     Angelo Rivera       Added mapping for lead collaborator
 * 1.3   17-04-2024     Sachin Shetty       Update to point to DBConnect fields
 * 2.0	 17-08-2025		Sachin Shetty		Added a default constructor
**/

global class EnterpriseServicePayload{

    global String applicationId;	                 // Monash_System_ID__c                     // 380600209
    global String externalFunderId;	                 // External_Funder_ID__c                   // CAF-2022-1513
    global String opportunityName;	                 // Name                                    // Track Geometry Measurement and Assessment
    global String serviceCatalogue;		             // Service_Catalogue_Alignment__c          // Research collaboration
    global String facultyType;	                     // Broad_area_s_of_interest__c             // Information Technology
    global String agreementCloseDate;	             // CloseDate                               // 2013-07-26
    global String applicationStage;	                 // StageName                               // Pre-Approval
    global String provenance;	                     // Provenance__c                           // PURE
    global String leadTimeToConvert;	             // Lead_Time_To_Convert__c                 // Less than 3 Months
    global String submissionDueDate;	             // Proposal_Due_Date__c                    // 2021-08-01
    global String projectDuration;	                 // Expected_Project_Duration__c            // 120
    global String projectStartDate;	                 // Expected_Funding_Start_Date__c          // 2022-08-25
    global String projectEndDate;	                 // Expected_Funding_End_Date__c            // 2022-08-25
    global String proposalStatus;	                 // Proposal_Status__c                      // In-Progress
    global String proposalSubmissionDate;	         // Proposal_Submission_Date__c             // 2013-07-26
    global String competitiveGrantFlag;	             // Presentation_Required__c                // TRUE
    global String presentationSubmissionDate;   	 // Presentation_Date__c                    // 2013-07-26
    global String dateOfSubmissionToPartner;    	 // Date_of_submission_to_partner__c        // 2013-07-26
    global String contractSignedDate;	             // Contract_Signed_Date__c                 // 2013-07-26
    global String applicationReviewedFlag;	         // Reviewed_By_Internal_Stakeholders__c    // TRUE
    global String ogc_mroReferenceNumber;	         // OGC_MRO_Reference_number__c             // TYH789742
    global String applicationStatus;	             // Application_Status__c                   // Draft proposal
    global String applicationType;	                 // Application_Type__c                     // Internship
    global String awardTransferredIndicator;    	 // Award_Transferred_Status__c             // Transfer In
    global String awardId;	                         // PURE_Award_ID__c                        // AWA12345
    global String awardType;	                     // Type                                    // Fellowship
    global String projectId;	                     // Pure_Project_Id__c                      // 567384
    global String leadCollaborator;	                 // Lead_Collaborator__c                    // Monash Led
    global String fundingSchemeName;	             // Name_of_funding_scheme__c               // City of Whittlesea
    global String funderReferenceNumber;	         // Funder_Ref__c                           // LP180101178
    global String collaboratorCount;	             // No_of_Collaborators__c                  // 5
    global String contractStatus;	                 // Contract_Status__c                      // In Development
    global String fundingId;	                     //                                         // 9878989
    global String industryRelatedFlag;    	         // Industry_Related__c                     // TRUE
    global String applicationWorkflowStatus;    	     // Workflow_Status_Application__c           // Reply Received From Funder
    global String awardWorkflowStatus;	             // Workflow_Status_Award__c                 // Reply Received From Funder
    global String awardVisibility;	                 // Award_Visibility_c                      // Visible
    global String applicationVisibility;	         // Application_Visibility__c               // Visible
    global String closedLostReason;	                 // Closed_Reason__c                        // Scope Aligned
    global String managingOrgUnitCode;	             // MANAGING_ORGANISATION_UNIT_CODE         // Callista Org Unit Code
    global String managingOrgUnitId;	             // MANAGING_ORGANISATION_UNIT_ID           // Pure Organisation ID
    global String managingOrgUnit;	                 // MANAGING_ORGANISATION_UNIT              // account name

    global cls_accounts[] accounts;
    global cls_contacts[] contacts;
    
    // Default constructor
    global EnterpriseServicePayload() {} //NOPMD

    global class cls_accounts {
        global String organisationID;               // PURE_Organisation_ID__c	        //297712623
        global String accountName;	                // Name                             //James
        global String accountType;	                // Type                             // Business or Corporation
        global String externalIdentifier;	        // RecordType                       //Test type
        global String tradingName;                  // Trading_Name__c          	    //Test Trading
        global String organisationParent;	        // Parent                           //Test Parent Organisation
        global String globalUltimateAccountName;	// Global_Ultimate_Account_Name__c  //Test Global Ultimate Account Name
        global String description;	                // Description                      //Test description about the collaborator
        global String website;	                    // Website                          //http://abc.com
        global String tickerSymbol;	                // TickerSymbol                     //Test symbol
        global String phone;	                    // Phone                            //+61411415613
        global String billingStreet;	            // BillingStreet                    //Burwood street
        global String organisationCity;	            // BillingCity                      //Sydney
        global String organisationState;	        // BillingState                     //New South Wales
        global String organisationZipCode;	            // BillingPostalCode                //8887
        global String organisationCountry;	        // BillingCountry                   //Australia
        global String shippingStreet;	            // ShippingStreet                   //Swanston Street
        global String shippingCity;	                // ShippingCity                     //Perth
        global String shippingState;	            // ShippingState                    //Western Australia
        global String shippingZipCode;	            // ShippingPostalCode               //8889
        global String shippingCountry;	            // ShippingCountry                  //Australia
        global String dunsNumber;	                // DBC_DUNS_Number__c               //1256789
        global String matchScore;	                // Match_Score__c                   // Test score
        global String globalUltimateDuns;	        // Global_Ultimate_DUNS_Number__c   // GLO1456787
        global String organisationIdentifierType;	// Organisation_Identifier_Type__c   // ACN
        global String organisationIdentifier;	    // Organisation_Identifier__c        //ORG456778
        global String altOrganisationIdentifierType;	// Organisation_Identifier_Type_Alternative__c  // ACN
        global String altOrganisationIdentifier;	    // Organisation_Identifier_Alternative__c   // ALTORG76869
        global String industryDivision;	            // SIC_Division__c                  //Test division
        global String industryMajorGroup;	        // SicDesc                          // Test Group
        global String industryClassificationSIC4;	// Sic                              // Test SIC4
        global String industryClassificationSIC8;	// SIC8_Code__c                     // Test SIC8
        global String outOfBusinessIndicator;	    // Out_of_Business_Indicator__c     // Test Indicator
        global String employeesCount;	            // NumberOfEmployees                // 15000
        global String employeeOverall;	            // Employees_Overall__c             // 15000
        global String annualRevenue;	            // AnnualRevenue                    // 10,00,000
        global String fortuneRank;	                // Fortune_1000_Rank__c             // 49
        global String legalStructure;	            // Legal_Structure__c               // Test structure
        global String publicPrivateIndicator;	    // Public_Private_Indicator__c      // global
        global String salesVolume;	                // Sales_Volume__c                  // 10,000
        global String salesVolumeAccuracy;	        // Sales_Volume_Accuracy__c         // 68
        global String fiscalYearEnd;	                // Fiscal_Year_End__c               // March
        global String tradingName2;	                // Trading_Name_2__c                // Company ABC
        global String tradingName3;	                // Trading_Name_3__c                // Renolds Company
        global String nationalIdentifier3;	        // Organisation_Identifier_3__c      // ACN
        global String nationalIdentifier4;	        // Organisation_Identifier_4__c      // ACN
        global String badDebtor;	                // Bad_Debtor__c                    // TRUE
        global String primaryAccountFlag;	        // identifies primary account        //TRUE

        global cls_funding[] funding;
        
        // Default constructor
        global cls_accounts() {} //NOPMD
    }

    global class cls_funding {
        global String applicationId;	                // PURE_Application_ID__c           // 5928647
        global String appliedGrantAmount;	            // Applied_Amount__c                // 50,000
        global String discountAmount;	                // Discount_Amount__c               // 50,000
        global String discountPercentage;	            // Discount__c                      // 40
        global String awardedAmount;	                // Awarded_Amount__c                // 50,000
        global String fundingDescription;	            // Funding_Description__c           // Australian Competitive Grants
        global String funderReferenceNumber;	        //                                  // 606788
        global String fundingCategory;	                // Funding_Category__c              // Category 1
        global String fundingCategoryDescription;	    // Funding_Category_Description__c  // Australian Competitive Grants
        global String fundingScheme;	                // Funding_Scheme__c                // NHMRC Program Grant 2011 - applied 2009
        global String fundingType;	                    // Funding_Type__c                  // Financial
        global String collaboratorIndicator;	        // identifies collaborator           // Funder or Collaborator
        global String fundingOpportunity;	            // Funding_Opportunity__c           // ARC Linkage Projects (LP)
        global String fundingSchemeId;	                // Fundung Scheme Id                // 1006
        global String fundingOrder;	                    // Flag for Primary_Funder__c       // 1 = Primary or 0 = Not Primary
        global String inKindAmount;	                    // In_Kind_Amount__c                // 50000
        
        // Default constructor
        global cls_funding() {}
    }

    global class cls_contacts {
        global String firstName;	                // Firstname                                        // Josh
        global String lastName;	                // Lastname                                         // Lee
        global String fullName;	                // Name                                             // Josh
        global String preferredName;	        // Preferred_Name__c                                // Josh
        global String profile;	                // Contact_Profile__c                                // Test profile
        global String salutation;	            // Salutation                                       // Mr
        global String gender;	                // GenderIdentity                                   // Male
        global String primaryEmail;	            // Personal_Email__c                                // primary@monuni.com
        global String secondaryEmail;	        // Business_Email_Address__c                        // abc@gmail.com
        global String description;	            // Description                                      // Description of the researcher
        global String orcId;	                // ORCID__c                                         // 87765365
        global String researcherId;	            // Researcher_ID__c                                 // 87765365
        global String accountName;	            // lookup to Account                                // Australian Board
        global String facultyPortfolio;	        // Faculty_Portfolio__c                             // Test faculty
        global String divisionName;	            // School_Division_Name__c                          //Test division
        global String primaryContactFlag;	    // Flag to identify primary                         // TRUE
        global String teamRole;	                // opportunity contact role                         // Default contact
        global String organisationId;	        // Account's PURE_Organisation_ID__c                // 5467890
        
        // Default constructor
        global cls_contacts() {} //NOPMD
    }

    global class cls_response {
        global String response;
        
        // Default constructor
        global cls_response() {} //NOPMD
    }

}