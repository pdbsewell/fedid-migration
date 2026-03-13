/**
* @author            : Angelo Rivera
* @description       : Serves as test data factory for test classes
* @group             : Monash Connect
* @revision          : 25/02/25 - Removed MIX API Client/Secret + Tenant Name from codebase (EPCP-4204)
**/

@isTest
public with sharing class MonConTestDataFactorySettings {
    public interface FieldDefaults {
        Map<Schema.SObjectField, Object> getFieldDefaults();
    }

    //Application__c
    public class ApplicationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Application__c.Application_Type__c => 'Default',
                    Application__c.Active_Monash_Student__c => true,
                    Application__c.Category__c => 'PG-CSP',
                    // Application__c.Agent_Email__c => 'agent@monash.edu',
                    Application__c.Applicant_Email_Address__c => 'applicant@monash.edu',
                    Application__c.Callista_Applicant_Id__c => '123456789',
                    Application__c.Callista_Application_Id__c => '123456789'
            };
        }
    }

    //Application_Course_Preference__c
    public class ApplicationCoursePreferenceDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Application_Course_Preference__c.Callista_Unique_Key_AP__c => '123456-1',
                    Application_Course_Preference__c.Callista_Unique_Key_ADM__c => '123456789',
                    Application_Course_Preference__c.Unique_External_Id__c => 'generictest56801savcg'
            };
        }
    }

    //CalabrioIntegration__c
    public class CalabrioIntegrationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    CalabrioIntegration__c.Name => 'Credentials',
                    CalabrioIntegration__c.AllowCallout__c => true,
                    CalabrioIntegration__c.CalabrioURL__c => 'http://calabrio.ocio.monash.edu/cwfo/apps/Recordings.html?loadContact=',
                    CalabrioIntegration__c.Client_ID__c => 'e4300af3f0ca487b855031659cac6caa',
                    CalabrioIntegration__c.Client_Secret__c => '1414625753724c45830316ADDAE08C7C',
                    CalabrioIntegration__c.AllowedStaff__c => 'eSolutions'
            };
        }
    }


    //CalabrioIntegration__c
    public class MIXRPASettingsDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    MIX_RPA_Settings__c.Name => 'Credentials',
                    MIX_RPA_Settings__c.Course_Intermissions_Org_Unit_Id__c => '467521',
                    MIX_RPA_Settings__c.Course_Discontinuation_Org_Unit_Id__c => '467334',
                    MIX_RPA_Settings__c.Change_of_Residency_Org_Unit_Id__c => '446181',
                    MIX_RPA_Settings__c.Grade_to_WI_Org_Unit_Id__c => '467523',
                    MIX_RPA_Settings__c.COE_Org_Unit_Id__c => '467524'
            };
        }
    }

    //RecordTypes_Allowed_on_CaseTrigger__c
    public class RecordTypesAllowedonCaseTriggerDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    RecordTypes_Allowed_on_CaseTrigger__c.Name => 'Standard Enquiry',
                    RecordTypes_Allowed_on_CaseTrigger__c.API_Name__c => 'Standard Enquiry'
            };
        }
    }

    //Environment_Settings__c
    public class EnvironmentSettingsDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Environment_Settings__c.MC_Future_Course_Validation__c => true
            };
        }
    }

    //Case
    public class CaseDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Case.RecordTypeId => MonConCaseServices.MONCON_RECTYPEID,
                    Case.Subject => 'Test Subject',
                    Case.Description => 'Test Description',
                    Case.Status => 'Open',
                    Case.Origin => 'Phone',
                    Case.Type => 'Phone',
                    Case.Enquiry_Type__c => 'Current Course',
                    Case.SuppliedEmail => 'testEmail@test.edu',
                    Case.Category_Level_1__c => 'General Services',
                    Case.Category_Level_2__c => 'Personal Details'
            };
        }
    }

    //Contact
    public class ContactDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Contact.LastName => 'TestLName',
                    Contact.FirstName => 'TestFName',
                    Contact.Email => 'testEmail@test.edu',
                    Contact.Monash_Email_Address__c => 'testEmail@test.edu',
                    Contact.Person_ID_unique__c => '12345678'
            };
        }
    }

    //Lead
    public class LeadDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Lead.Email => 'testEmail@lead.com',
                    Lead.FirstName => 'TestFName',
                    Lead.LastName => 'TestLName',
                    Lead.RecordTypeId => StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT,
                    Lead.Student_type__c => Label.Student_Type_Domestic,
                    Lead.Company => 'Monash'
            };
        }
    }

    //LiveChatTranscript
    public class LiveChatTranscriptDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    LiveChatTranscript.Status => 'InProgress',
                    LiveChatTranscript.ChatKey => '123abc456def'
            };
        }
    }

    //Chat 365 Log
    public class Chat365LogDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Chat_365_Log__c.Chat_Key__c => '123abc456def',
                    Chat_365_Log__c.Session_Id__c => '123abc456def',
                    Chat_365_Log__c.Page_URL__c => 'www.askmonash.edu/',
                    Chat_365_Log__c.Bot_Name__c => 'Chat 365',
                    Chat_365_Log__c.Device_Type__c => 'Desktop',
                    Chat_365_Log__c.Last_Name__c => 'TestLName',
                    Chat_365_Log__c.First_Name__c => 'TestFName',
                    Chat_365_Log__c.Account_Type__c => 1,
                    Chat_365_Log__c.Email__c => 'testEmail@test.edu',
                    Chat_365_Log__c.Id_Number__c => '12345678'
            };
        }
    }

    //Chat 365 Log Detail
    public class Chat365LogDetailDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Chat_365_Log_Detail__c.Request__c => 'Hi there!',
                    Chat_365_Log_Detail__c.Response__c => 'Hi! Im Chat365 bot!',
                    Chat_365_Log_Detail__c.Topic__c => 'Other',
                    Chat_365_Log_Detail__c.Intent__c => 2,
                    Chat_365_Log_Detail__c.Intent_Name__c => 'Default Intent - Interaction',
                    Chat_365_Log_Detail__c.Subject__c => 'Test Subject',
                    Chat_365_Log_Detail__c.Description__c => 'Test Description'
            };
        }
    }

    //Account
    public class AccountDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Account.Name => 'Test Account'
            };
        }
    }

    //Enquiry_Interest__c
    public class EnquiryInterestsDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Enquiry_Interest__c.Attendance_Mode__c => 'On Campus',
                    Enquiry_Interest__c.Study_Area__c => 'Engineering',
                    Enquiry_Interest__c.Faculty_PickList__c => 'Engineering',
                    Enquiry_Interest__c.Level_of_Study__c => 'Postgraduate',
                    Enquiry_Interest__c.Location__c => 'Clayton',
                    Enquiry_Interest__c.Mode__c => 'FT',
                    Enquiry_Interest__c.Valid_Enquiry_Interest__c => true
            };
        }
    }

    //Course_Attempt__c
    public class CourseAttemptDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Course_Attempt__c.Name => 'TestCourseAttempt',
                    Course_Attempt__c.Course_Attempt_Status__c => 'Enrolled',
                    Course_Attempt__c.Campus__c => 'CLAYTON',
                    Course_Attempt__c.Campus_Country__c => 'AUSTRALIA',
                    Course_Attempt__c.Attendance_Mode__c => 'IN',
                    Course_Attempt__c.Attendance_Type__c => 'FT',
                    Course_Attempt__c.Fee_Payment_Option__c => 'Fee-Help',
                    Course_Attempt__c.Location__c => 'Clayton',
                    Course_Attempt__c.Student_Type__c => 'Domestic'
            };
        }
    }

    //Course__c
    public class CourseDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Course__c.Name => 'MARK1234',
                    Course__c.Abbreviation__c => 'MARK',
                    Course__c.Course_Code__c => 'MARK1234',
                    Course__c.Course_Description__c => 'Bachelor of Marketing',
                    Course__c.Title__c => 'Bachelor of Marketing',
                    Course__c.Short_Title__c => 'Bachelor of Marketing',
                    Course__c.Type__c => 'Course-All',
                    Course__c.Version__c => '1',
                    Course__c.Status__c => 'Active',
                    Course__c.Specialisation_Code__c => 'MARK1234'
            };
        }
    }

    //Course__c - Unit Set
    public class UnitSetDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Course__c.Name => 'BAMKTPRC01',
                    Course__c.Abbreviation__c => 'MARKETING PRAC',
                    Course__c.Course_Code__c => 'BAMKTPRC01',
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
                    Course__c.Course_Code__c => '3626',
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

    //Course__c - Unit Set - Monash English
    public class  MonashEnglishUnitSetDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                    Course__c.Name => 'MEB-AP-20',
                    Course__c.Abbreviation__c => 'MEB 20 WKS FOR ADP',
                    Course__c.Course_Code__c => 'MEB-AP-20',
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
                    Course__c.Course_Code__c => 'SC000',
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

    // When we create a list of SObjects, we need to(do we need this?)
    public static Map<String, String> nameFieldMap = new Map<String, String> {
            'Contact' => 'LastName',
            'Case' => 'Subject',
            'Chat_365_Log_Details__c' => 'Name'
    };
}