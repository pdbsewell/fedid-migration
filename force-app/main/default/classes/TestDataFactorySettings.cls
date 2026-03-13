/**
* @author David Browaeys
* @description Serves as test data factory for test classes
* @group SF Offers
**/
@isTest
public class TestDataFactorySettings {
    //Account
    public class AccountDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Account.Name => 'Test Account'
                
            };
    	}
    }
    //Contact
    public class ContactDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Contact.FirstName => 'First',
                Contact.LastName => 'Last'
            };
        }
    }
    //Course__c
    public class CourseDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Course__c.Name => 'MARK1234',
                Course__c.Abbreviation__c => 'MARK',
                Course__c.Course_Code__c => 'MARK1234_1',
                Course__c.Course_Description__c => 'Bachelor of Marketing',
                Course__c.Title__c => 'Bachelor of Marketing',
                Course__c.Short_Title__c => 'Bachelor of Marketing',
                Course__c.Type__c => 'Course-All',
                Course__c.Version__c => '1',
                Course__c.Status__c => 'Active',
                Course__c.Specialisation_Code__c => 'MARK1234',
                Course__c.Duration_FT__c => 1.5,
                Course__c.Faculty_Code__c => '50000563'
            };
        }
    }
    //Course__c - Unit Set
    public class UnitSetDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Course__c.Name => 'BAMKTPRC01',
                Course__c.Abbreviation__c => 'MARKETING PRAC',
                Course__c.Course_Code__c => 'BAMKTPRC01_1',
                Course__c.Course_Description__c => 'Marketing practice',
                Course__c.Title__c => 'Marketing practice',
                Course__c.Short_Title__c => 'Marketing practice',
                Course__c.Type__c => 'Unit Set',
                Course__c.Version__c => '1',
                Course__c.Status__c => 'Active'
            };
        }
    }
   //Course__c - Monash English
    public class MonashEnglishCourseDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Course__c.Name => '3626',
                Course__c.Abbreviation__c => 'MEB',
                Course__c.Course_Code__c => '3626_1',
                Course__c.Course_Description__c => 'Monash English',
                Course__c.Title__c => 'Monash English',
                Course__c.Short_Title__c => 'Monash English',
                Course__c.Type__c => 'Course-All',
                Course__c.Version__c => '1',
                Course__c.Status__c => 'Active',
                Course__c.Specialisation_Code__c => '3626'
            };
        }
    }

      //Course__c - Monash English
      public class BUNMECMonashEnglishCourseDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Course__c.Name => '3629',
                Course__c.Abbreviation__c => 'MEB',
                Course__c.Course_Code__c => '3629_1',
                Course__c.Course_Description__c => 'Monash English',
                Course__c.Title__c => 'Monash English',
                Course__c.Short_Title__c => 'Monash English',
                Course__c.Type__c => 'Course-All',
                Course__c.Version__c => '1',
                Course__c.Status__c => 'Active',
                Course__c.Specialisation_Code__c => '3629'
            };
        }
    }

     //Course__c - Indo course 
     public class IndoCourseDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Course__c.Name => 'F600',
                Course__c.Abbreviation__c => 'MEB',
                Course__c.Course_Code__c => 'F600_1',
                Course__c.Course_Description__c => 'Master of Urban Design',
                Course__c.Title__c => 'Master of Urban Design',
                Course__c.Short_Title__c => 'Master of Urban Design',
                Course__c.Type__c => 'Course-All',
                Course__c.Version__c => '1',
                Course__c.Status__c => 'Active',
                Course__c.Specialisation_Code__c => 'F600'
            };
        }
    }
    //Course__c - Unit Set - Monash English
    public class  MonashEnglishUnitSetDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Course__c.Name => 'MEB-AP-20',
                Course__c.Abbreviation__c => 'MEB 20 WKS FOR ADP',
                Course__c.Course_Code__c => 'MEB-AP-20_1',
                Course__c.Course_Description__c => 'MONASH ENGLISH BRIDGING 20 WEEKS FOR UNIVERSITY, ADVANCED PLUS',
                Course__c.Title__c => 'MONASH ENGLISH BRIDGING 20 WEEKS FOR UNIVERSITY, ADVANCED PLUS',
                Course__c.Short_Title__c => 'MEB 20 WKS FOR ADP',
                Course__c.Type__c => 'Unit Set',
                Course__c.Version__c => '1',
                Course__c.Status__c => 'Active'
            };
        }
    }
   //Course__c - Scholarship
    public class MonashGrantCoursDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Course__c.Name => 'SC000',
                Course__c.Abbreviation__c => 'MGS',
                Course__c.Course_Code__c => 'SC000_1',
                Course__c.Course_Description__c => 'Monash Scholarship',
                Course__c.Title__c => 'Scholarship',
                Course__c.Short_Title__c => 'Scholarship',
                Course__c.Type__c => 'Course-All',
                Course__c.Version__c => '1',
                Course__c.Status__c => 'Active',
                Course__c.Specialisation_Code__c => 'SC000'
            };
        }
    }
    //Calendar__c
    public class CalendarDefaults implements FieldDefaults{
        public Map<Schema.SObjectField,Object> getFieldDefaults() {
            return new Map<Schema.SObjectField,Object> {
                Calendar__c.Name => 'ADM 2021/1',
                Calendar__c.Calendar_Name_Alternate__c => '2021/1',
                Calendar__c.Category__c => 'ADMISSION' 
            };
        }
    }
    // Course_Offering__c
    public class CourseOfferingDefaults implements FieldDefaults{
        public Map<Schema.SObjectField,Object> getFieldDefaults() {
            return new Map<Schema.SObjectField,Object> {
                Course_Offering__c.Location_Code__c => 'Clayton',
                Course_Offering__c.Course_Code__c => 'MARK1234',
                Course_Offering__c.Course_Version_Number__c => 1,
                Course_Offering__c.Course_Title__c => 'Master Of Something Something',
                Course_Offering__c.Academic_Year__c => 2018,
                Course_Offering__c.Academic_CI_Sequence_Number__c => 666,
                Course_Offering__c.Admission_Calendar_Type__c => 'ADM',
                Course_Offering__c.Admission_CI_Sequence_Number__c => 666,
                Course_Offering__c.Attendance_Mode__c => 'SCG',
                Course_Offering__c.Attendance_Type__c => 'PT',
                Course_Offering__c.Citizenship_Type__c => 'DOM-AUS',
                Course_Offering__c.Course_Type__c => '10',
                Course_Offering__c.Faculty__c => 'Faculty of Law',
                Course_Offering__c.Location__c => 'Clayton',
                Course_Offering__c.Type_of_Place_Code__c => 'PC001',
                Course_Offering__c.Override_Reviewed__c => true
            };
        }
    }
    //Course_Fee__c
    public class CourseFeeDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Course_Fee__c.Name => 'MARK1234',
                Course_Fee__c.Course_Code__c => 'MARK1234',
                Course_Fee__c.Course_Code_Version__c => 1,
                Course_Fee__c.Base_Total_Course_Fee__c => 10000,
                Course_Fee__c.Course_Deposit_Amount__c => 1000,
                Course_Fee__c.Fee_Band_Code_Year__c => 2020,
                Course_Fee__c.Fee_Category__c => 'AU_INT',
                Course_Fee__c.Standard_Course_Point_Annual_Load__c => 45,
                Course_Fee__c.Unit_Set_Code__c => 'MARK1234',
                Course_Fee__c.Year_One_Fee__c => 3000,
                Course_Fee__c.Product_Bundle__c => 'BUNUNI'
            };
    	}
    }
    //Stg_Course_Fee__c
    public class MonashEnglishStgCourseFeeDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Stg_Course_Fee__c.Sync_Status__c => 'NOT SYNC',
                Stg_Course_Fee__c.Course_Status__c => 'PLANNED',
                Stg_Course_Fee__c.Name => 'MEB1234',
                Stg_Course_Fee__c.Course_Code__c => '3626',
                Stg_Course_Fee__c.Course_Version__c => '1',
                Stg_Course_Fee__c.Course_Type__c => '82',
                Stg_Course_Fee__c.Course_Type_Description__c => 'MUELC',
                Stg_Course_Fee__c.Base_Total_Course_Fee__c => 25200,
                Stg_Course_Fee__c.Course_Deposit_Amount__c => 12600,
                Stg_Course_Fee__c.Fee_Band_Code__c => 'MY_ELC_D_A',
                Stg_Course_Fee__c.Fee_Band_Code_Year__c => 2019,
                Stg_Course_Fee__c.Fee_Band_Course_Fee__c => 25200,
                Stg_Course_Fee__c.Fee_Category__c => 'MUELC_IS',
                Stg_Course_Fee__c.Standard_Course_Point_Annual_Load__c => 45,
                Stg_Course_Fee__c.Year_One_Fee__c => 25200, 
                Stg_Course_Fee__c.Publish_ind__c => 'Y',
                Stg_Course_Fee__c.Quote_Year_Ind__c => 'N',
                Stg_Course_Fee__c.Responsible_Org_Unit_Code__c => '50028341',
                Stg_Course_Fee__c.Responsible_Org_Unit_Desc__c => 'MONASH UNIVERSITY ENGLISH LANGUAGE CTR',
                Stg_Course_Fee__c.External_ID__c => '3626_1_2019_MY_ELC_D_A',
                Stg_Course_Fee__c.Calendar_Alternate_Code__c => '2019',
                Stg_Course_Fee__c.Calendar_Type__c => 'ACAD-YR',
                Stg_Course_Fee__c.Currency__c =>'AUD'

            };
    	}
    }

     //Stg_Course_Fee__c
     public class BUNMECMonashEnglishStgCourseFeeDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Stg_Course_Fee__c.Sync_Status__c => 'NOT SYNC',
                Stg_Course_Fee__c.Course_Status__c => 'PLANNED',
                Stg_Course_Fee__c.Name => 'MEB1234',
                Stg_Course_Fee__c.Course_Code__c => '3629',
                Stg_Course_Fee__c.Course_Version__c => '1',
                Stg_Course_Fee__c.Course_Type__c => '82',
                Stg_Course_Fee__c.Course_Type_Description__c => 'MUELC',
                Stg_Course_Fee__c.Base_Total_Course_Fee__c => 24000,
                Stg_Course_Fee__c.Course_Deposit_Amount__c => 12500,
                Stg_Course_Fee__c.Fee_Band_Code__c => 'MY_ELC_DMELC-INT-D',
                Stg_Course_Fee__c.Fee_Band_Code_Year__c => 2024,
                Stg_Course_Fee__c.Fee_Band_Course_Fee__c => 25200,
                Stg_Course_Fee__c.Fee_Category__c => 'MUELC_IS',
                Stg_Course_Fee__c.Standard_Course_Point_Annual_Load__c => 40,
                Stg_Course_Fee__c.Year_One_Fee__c => 25200, 
                Stg_Course_Fee__c.Publish_ind__c => 'Y',
                Stg_Course_Fee__c.Quote_Year_Ind__c => 'N',
                Stg_Course_Fee__c.Responsible_Org_Unit_Code__c => '50028341',
                Stg_Course_Fee__c.Responsible_Org_Unit_Desc__c => 'MONASH UNIVERSITY ENGLISH LANGUAGE CTR',
                Stg_Course_Fee__c.External_ID__c => '3629_1_2023_MELC-INT-D',
                Stg_Course_Fee__c.Calendar_Alternate_Code__c => '2024',
                Stg_Course_Fee__c.Calendar_Type__c => 'ACAD-YR',
                Stg_Course_Fee__c.Currency__c =>'AUD'

            };
    	}
    }
    //Stg_Course_Fee__c
    public class MarketingStgCourseFeeDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Stg_Course_Fee__c.Sync_Status__c => 'NOT SYNC',
                Stg_Course_Fee__c.Course_Status__c => 'ACTIVE',
                Stg_Course_Fee__c.Name => 'MARK1234',
                Stg_Course_Fee__c.Course_Code__c => 'MARK1234',
                Stg_Course_Fee__c.Course_Version__c => '1',
                Stg_Course_Fee__c.Unit_Set_Code__c => 'BAMKTPRC01',
                Stg_Course_Fee__c.Unit_Set_Version__c => '1',
                Stg_Course_Fee__c.Course_Type__c => '21MC',
                Stg_Course_Fee__c.Course_Type_Description__c => '21MC',
                Stg_Course_Fee__c.Base_Total_Course_Fee__c => 25200,
                Stg_Course_Fee__c.Course_Deposit_Amount__c => 12600,
                Stg_Course_Fee__c.Fee_Band_Code__c => 'F12345',
                Stg_Course_Fee__c.Fee_Band_Code_Year__c => 2019,
                Stg_Course_Fee__c.Fee_Band_Course_Fee__c => 25200,
                Stg_Course_Fee__c.Fee_Category__c => 'AU_INT',
                Stg_Course_Fee__c.Standard_Course_Point_Annual_Load__c => 45,
                Stg_Course_Fee__c.Year_One_Fee__c => 25200, 
                Stg_Course_Fee__c.Publish_ind__c => 'Y',
                Stg_Course_Fee__c.Quote_Year_Ind__c => 'N',
                Stg_Course_Fee__c.Responsible_Org_Unit_Code__c => '50000563',
                Stg_Course_Fee__c.Responsible_Org_Unit_Desc__c => 'FACULTY OF BUSINESS AND ECONOMICS',
                Stg_Course_Fee__c.External_ID__c => 'MARK1234_1_2019_F12345',
                Stg_Course_Fee__c.Calendar_Alternate_Code__c => '2019',
                Stg_Course_Fee__c.Calendar_Type__c => 'ACAD-YR',
                Stg_Course_Fee__c.Currency__c =>'AUD'
            };
    	}
    }
    
    //Course_Duration__c - English course
    public class CourseDurationDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults(){
            return new Map<Schema.SObjectField, Object>{
                Course_Duration__c.Course_Code__c => '3626',
                Course_Duration__c.Unit_Set_Code__c => 'MEB-AP-20',
                Course_Duration__c.Duration__c => 20,
                Course_Duration__c.External_ID__c => '3626-MEB-AP-20'
            };
        }
    }
    
    //Course_Duration__c - English course for BUNMEC
    public class CourseDurationDefaultsForBUNMEC implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults(){
            return new Map<Schema.SObjectField, Object>{
                Course_Duration__c.Course_Code__c => '3629',
                Course_Duration__c.Unit_Set_Code__c => 'MEB-AP-20',
                Course_Duration__c.Duration__c => 20,
                Course_Duration__c.External_ID__c => '3629-MEB-AP-20'
            };
        }
    }
    //Opportunity
    public class OpportunityDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Opportunity.RecordTypeId => Schema.SObjectType.Opportunity.getRecordtypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId(),
                Opportunity.Name => 'Test Opportunity',
                Opportunity.StageName => 'Identification',
                Opportunity.CloseDate => System.today()
            };
        }
    }
    //OpportunityLineItem
    public class OpportunityLineItemDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults(){
            return new Map<Schema.SObjectField, Object>{
               OpportunityLineItem.quantity => 1,
               OpportunityLineItem.UnitPrice => 1000    
        	};
    	}
    }
    //Form_Page__c
    public class FormPageDefaults implements FieldDefaults{
          public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Form_Page__c.Name => 'First name',
                Form_Page__c.API_Name__c => 'API Test',
                Form_Page__c.Display_Order__c => '1'    
            };
        }
    }
    //Form_Element__c
    public class FormElementDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Form_Element__c.Name => 'Test Form Element',
                Form_Element__c.Description__c => 'Test Description',
                Form_Element__c.Sort_Order__c => 'Ascending'
            };
        }
    }
    //SBQQ__Quote__c
    public class SBQQQuoteDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                SBQQ__Quote__c.SBQQ__Notes__c => 'Test notes for quote',
                SBQQ__Quote__c.Category__c => 'ISCA Deposit',
                SBQQ__Quote__c.Product_Search_Filter__c => 'Offer'
            };
        }
    }
    //SBQQ__Quote__c
    public class PublishedQuote implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                SBQQ__Quote__c.SBQQ__Notes__c => 'Test notes for quote',
                SBQQ__Quote__c.Category__c => 'ISCA Deposit',
                SBQQ__Quote__c.Primary_DocuSign_Envelop_Id__c => '23d956cc-3a5f-455b-8621-'+String.valueOf(Crypto.getRandomInteger()).substring(1,6),
                SBQQ__Quote__c.Product_Search_Filter__c => 'Offer',
                SBQQ__Quote__c.SBQQ__EndDate__c => Date.today().addMonths(2),
                SBQQ__Quote__c.SBQQ__StartDate__c => Date.today().addMonths(1),
                SBQQ__Quote__c.SBQQ__ExpirationDate__c => Date.today().addDays(-1),
                SBQQ__Quote__c.SBQQ__Type__c => 'Quote',
                SBQQ__Quote__c.Expiry_Status__c => 'Active Offer',
                SBQQ__Quote__c.Product_Status__c => 'Active Products',
                SBQQ__Quote__c.SBQQ__Status__c => 'Published'
            };
        }
    }
    //SBQQ__QuoteLine__c
    public class SBQQQuoteLineDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                SBQQ__QuoteLine__c.SBQQ__SpecialPriceDescription__c => 'Testing special price description'
            };
        }
    }
   //Product2
    public class Product2Defaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Product2.Name => 'Bachelor of Accounting',
				Product2.Family => 'Course',
				Product2.ProductCode => '123',
                Product2.IsActive => true,
                Product2.Description => 'Hello'   
           };
        }
    }
    //Product2 - Product Bundle
    public class ProductBundleDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Product2.Name => 'English',
				Product2.ProductCode => '1234',
				Product2.IsActive => true,
                Product2.External_ID__c => '1234',
                Product2.Description => 'Hello'
            };
        }
    }
    //Product2 - Product Bundle - Health Cover Bundle
    public class HealthCoverBundleDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Product2.Name => 'Overseas Health Cover Bundle',
				Product2.ProductCode => 'BUNHEALTH',
				Product2.IsActive => true,
                Product2.External_ID__c => 'BUNHEALTH',
                Product2.Family => 'OSHC',
                Product2.Description => 'Hello'
            };
        }
    }
    public class HealthOptionDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Product2.Name => 'Single OSHC',
				Product2.ProductCode => 'SINGLE',
				Product2.IsActive => true,
                Product2.External_ID__c => 'SINGLE',
                Product2.Family => 'OSHC',
                Product2.Sub_Family__c => 'SINGLE',
                Product2.Description => 'Hello'

            };
        }
    }

    //Product2 - Product Bundle - Monash University Bundle
    public class MonashUniBundleDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Product2.Name => 'Monash University',
				Product2.ProductCode => 'BUNUNI',
				Product2.IsActive => true,
                Product2.External_ID__c => 'BUNUNI',
                Product2.Family => 'Bundle',
                Product2.Description => 'Hello',
                Product2.CurrencyIsoCode => 'AUD'
            };
        }
    }
    //Product2 - Product Bundle - Monash English Bundle
    public class MonashEnglishBundleDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Product2.Name => 'Monash English',
				Product2.ProductCode => 'BUNENG',
				Product2.IsActive => true,
                Product2.External_ID__c => 'BUNENG',
                Product2.Family => 'Bundle',
                Product2.Description => 'Hello',
                Product2.CurrencyIsoCode => 'AUD'
                
            };
        }
    }
     //Product2 - Product Bundle - Monash English Bundle BUNMEC
     public class MonashEnglishBundleDefaultsBUNMEC implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Product2.Name => 'Monash English',
				Product2.ProductCode => 'BUNMEC',
				Product2.IsActive => true,
                Product2.External_ID__c => 'BUNMEC',
                Product2.Family => 'Bundle',
                Product2.Description => 'Hello',
                Product2.CurrencyIsoCode => 'AUD'
                
            };
        }
    }
    //Product2 - Product  - Monash Grant/Scholarship
    public class MonashGrantScholarshipDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Product2.Name => 'Monash Scholarship',
				Product2.ProductCode => '4001',
				Product2.IsActive => true,
				Product2.Family => 'Scholarship',
                Product2.External_ID__c => '4001',
                Product2.Face_Value__c => 500,
                Product2.Type__c => 'Capped',
                Product2.Description__c => 'test',
                Product2.Expiry_days__c => 1,
                Product2.Quota_Original__c => 10,
                Product2.Description => 'Hello',
                Product2.CurrencyIsoCode => 'AUD'
            };
        }
    }
    //SBQQ__ProductFeature__c
    public class SBQQProductFeatureDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				SBQQ__ProductFeature__c.SBQQ__MinOptionCount__c => 1,
				SBQQ__ProductFeature__c.SBQQ__OptionSelectionMethod__c => 'Dynamic',
				SBQQ__ProductFeature__c.External_Id__c => 'abcdefg'   
           };
        }
    }
    //SBQQ__ConfigurationAttribute__c
    public class SBQQConfigurationAttributeDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				SBQQ__ConfigurationAttribute__c.SBQQ__DisplayOrder__c => 1,
				SBQQ__ConfigurationAttribute__c.SBQQ__ColumnOrder__c => '1',
				SBQQ__ConfigurationAttribute__c.SBQQ__Position__c => 'Top'   
           };
        }
    }
    //Pricebook2
    public class Pricebook2Defaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Pricebook2.Name => 'International',
                Pricebook2.External_ID__c => 'AU_INT',
                Pricebook2.IsActive => true
           };
        }
    }

       //Pricebook2 - for Indonesia offers
       public class IndonesiaPricebook2Defaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Pricebook2.Name => 'Indonesia Domestic',
                Pricebook2.External_ID__c => 'MI_DOM',
                Pricebook2.IsActive => true
           };
        }
    }

       //Pricebook2 - for Monash online for Avenu offers
       public class AvenuPricebook2Defaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Pricebook2.Name => 'Monash Online',
                Pricebook2.External_ID__c => 'MO',
                Pricebook2.IsActive => true
           };
        }
    }
    //PricebookEntry
    public class PricebookEntryDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				PricebookEntry.unitprice => 25000,
                PricebookEntry.IsActive => true    
           };
        }
    }

    //Conga Clause Defaults
    public class APXTRedliningClauseDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				APXT_Redlining__Clause__c.Selection_Type__c => 'Auto',
                APXT_Redlining__Clause__c.Active__c => true,
                APXT_Redlining__Clause__c.APXT_Redlining__Text_Rich__c => 'test',
                APXT_Redlining__Clause__c.External_Id__c => 'TEST00001',
                APXT_Redlining__Clause__c.Location_in_Offer__c => 'Course notes' 
           };
        }
    }

    //Clause filtering criteria Couse Code Defaults
    public class ClauseFilteringCriteriaForContainsDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Clause_Filtering_Criteria__c.Active__c => true,
				Clause_Filtering_Criteria__c.Field__c => 'Application_Course_Preference__r.Course_Code__c',
                Clause_Filtering_Criteria__c.Operator__c => 'contains',
                Clause_Filtering_Criteria__c.Filtered_Value__c => 'MARK1234',
                Clause_Filtering_Criteria__c.Object_Type__c => 'SBQQ__QuoteLine__c'
           };
        }
    }

    //Clause filtering criteria  Coutry Of Residence Defaults
    public class ClauseFilteringCriteriaForEqualsDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Clause_Filtering_Criteria__c.Active__c => true,
				Clause_Filtering_Criteria__c.Field__c => 'SBQQ__Quote__r.SBQQ__PrimaryContact__r.Country_of_Residence__c',
                Clause_Filtering_Criteria__c.Operator__c => 'equals',
                Clause_Filtering_Criteria__c.Filtered_Value__c => 'INDIA',
                Clause_Filtering_Criteria__c.Object_Type__c => 'SBQQ__QuoteLine__c'
           };
        }
    }

    //Clause filtering criteria  Coutry Of Residence Defaults
    public class ClauseFilteringCriteriaForNotEqualsDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Clause_Filtering_Criteria__c.Active__c => true,
				Clause_Filtering_Criteria__c.Field__c => 'SBQQ__Quote__r.SBQQ__PrimaryContact__r.Country_of_Residence__c',
                Clause_Filtering_Criteria__c.Operator__c => 'not equals',
                Clause_Filtering_Criteria__c.Filtered_Value__c => 'CHILE',
                Clause_Filtering_Criteria__c.Object_Type__c => 'SBQQ__QuoteLine__c'
           };
        }
    }

    //Greater operator criteria defaults
    public class ClauseFilteringCriteriaGreaterThanDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Clause_Filtering_Criteria__c.Active__c => true,
				Clause_Filtering_Criteria__c.Field__c => 'Application_Course_Preference__r.Calendar_Start_Date__c',
                Clause_Filtering_Criteria__c.Operator__c => 'greater',
                Clause_Filtering_Criteria__c.Filtered_Value__c => String.valueOf(Date.today()),
                Clause_Filtering_Criteria__c.Object_Type__c => 'SBQQ__QuoteLine__c'
           };
        }
    }

    //Less operator criteria defaults
    public class ClauseFilteringCriteriaLessThanDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Clause_Filtering_Criteria__c.Active__c => true,
				Clause_Filtering_Criteria__c.Field__c => 'Application_Course_Preference__r.Calendar_Start_Date__c',
                Clause_Filtering_Criteria__c.Operator__c => 'less',
                Clause_Filtering_Criteria__c.Filtered_Value__c => String.valueOf(Date.today().addYears(2)),
                Clause_Filtering_Criteria__c.Object_Type__c => 'SBQQ__QuoteLine__c'
           };
        }
    }

 	//User
    public class UserDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                User.Username=>'test@mydomain.test',
                User.Email=>'test@mydomain.com.au',
                User.LastName=>'test',
                User.Alias=>'tst',
                User.TimeZoneSidKey=>'Australia/Sydney',
                User.LocaleSidKey=>'en_AU',
                User.EmailEncodingKey=>'ISO-8859-1',
                User.LanguageLocaleKey=>'en_US'
            };
        }
    }
    // When we create a list of SObjects, we need to(do we need this?)
    public static Map<String, String> nameFieldMap = new Map<String, String> {
        'Contact' => 'LastName',
        'Case' => 'Subject',
        'SBQQ__Quote__c' => 'SBQQ__Notes__c'
    };

    
 	//Bulk_Data_Processing__c object defaults
    public class BulkDataProcessingDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Bulk_Data_Processing__c.Person_ID__c=>'123456',
                Bulk_Data_Processing__c.Type__c=>'Course Transfer',
                Bulk_Data_Processing__c.Status__c=>'New',
                Bulk_Data_Processing__c.Current_Course_Campus__c => 'MALAYSIA',
                Bulk_Data_Processing__c.Current_Course_Code__c=>'C2001',
                Bulk_Data_Processing__c.Transfer_Course_Code__c=>'E6001',
                Bulk_Data_Processing__c.Transfer_Course_Campus__c=>'CLAYTON',
                Bulk_Data_Processing__c.Credit_Duration__c=>'2 Years',
                Bulk_Data_Processing__c.Transfer_Calendar__c=>'2021/1',
                Bulk_Data_Processing__c.Transfer_Admission_Category__c=>'UG-IS'
            };
        }
    }
}