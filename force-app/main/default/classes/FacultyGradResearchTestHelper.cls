@isTest
@SuppressWarnings('PMD.ClassNamingConventions')
public class FacultyGradResearchTestHelper {
    
    // Case defaults
    public class CaseDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object>{
                Case.RecordTypeId => Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                    .get('Faculty_Graduate_Research')
                    .getRecordTypeId(),
                Case.Subject => 'Test Subject',
                Case.Description => 'Test Description',
                Case.SuppliedEmail => 'testEmail@monash.edu',
                Case.Status => 'Open',
                Case.Origin => 'Email - buseco-research.degrees@monash.edu',
                Case.Priority => 'Medium',
                Case.Enquiry_Type__c => 'Current Course',
                Case.Category_Level_1__c => 'Candidature',
                Case.Category_Level_2__c => 'Enrolment'
            };
        }
    }
}