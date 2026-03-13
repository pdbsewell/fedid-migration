export const fieldConfig = {
    prospectiveStudentLeadInfo: [
        {
            key: 'Study_Funded_By__c',
            fieldName: 'Study_Funded_By__c',
            largeDeviceSize: '6'
        },
        {
            key: 'Desired_Start_Year__c',
            fieldName: 'Desired_Start_Year__c',
            largeDeviceSize: '6'
        },
        {
            key: 'Desired_Start_Period__c',
            fieldName: 'Desired_Start_Period__c',
            largeDeviceSize: '6'
        },
        {
            key: 'English_Proficiency_Level__c',
            fieldName: 'English_Proficiency_Level__c',
            largeDeviceSize: '6'
        },
        {
            key: 'Complete_Secondary_School__c',
            fieldName: 'complete_secondary_school__c',
            largeDeviceSize: '6'
        },
        {
            key: 'Current_Studies__c',
            fieldName: 'Current_Studies__c',
            largeDeviceSize: '6'
        },
        {
            key: 'Student_type__c',
            fieldName: 'Student_type__c',
            largeDeviceSize: '6'
        },
        {
            key: 'Study_Level__c',
            fieldName: 'Study_Level__c',
            largeDeviceSize: '6'
        },
        {
            key: 'Secondary_School__c',
            fieldName: 'Secondary_School__c',
            largeDeviceSize: '6'
        },
        {
            key: 'Company__c',
            fieldName: 'Company',
            largeDeviceSize: '6'
        },
    ],
    caseFieldMapping : [
        {
            caseField : 'Commencement_Year__c',
            leadField : 'Desired_Start_Year__c'
        },
        {
            caseField : 'Supplied_Name_of_Institution__c',
            leadField : 'Secondary_School__c'
        },
        {
            caseField : 'SuppliedCompany',
            leadField : 'Company'
        },
    ]
};