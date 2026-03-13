export const fieldConfig = {
    basicInfoFields : [
        {
            key: 'First_Name__c',
            fieldName: 'FirstName',
            largeDeviceSize : '6'
        },
        {
            key: 'Last_Name__c',
            fieldName: 'LastName',
            largeDeviceSize: '6'
        },
        {
            key: 'Email__c',
            fieldName: 'Email',
            largeDeviceSize: '6'
        },
        {
            key: 'Mobile__c',
            fieldName: 'MobilePhone',
            largeDeviceSize: '6'
        },
    ],

    additionalInfoFields: [
        {
            key: 'Gender__c',
            fieldName: 'Gender__c',
            largeDeviceSize: '6'
        },
        {
            key: 'Country_of_Residence__c',
            fieldName: 'Country_of_Residence__c',
            largeDeviceSize: '6'
        },
        {
            key: 'Nationality__c',
            fieldName: 'Nationality__c',
            largeDeviceSize: '6'
        },
        {
            key: 'Birthdate__c',
            fieldName: 'Birthdate',
            largeDeviceSize: '6'
        },
        {
            key: 'Phone__c',
            fieldName: 'OtherPhone',
            largeDeviceSize: '6',
        },
        {
            key: 'residencyStatus',
            fieldName: 'Residency_Status__c',
            largeDeviceSize: '6',
        },
        {
            key: 'educLevel',
            fieldName: 'Highest_level_of_education_to_date__c',
            largeDeviceSize: '6',
        },
        {
            key: 'conProf',
            fieldName: 'Contact_Profile__c',
            largeDeviceSize: '12',
        }
    ],

    spsFields : [
        {
            key: 'MailingStreet',
            fieldName: 'Mailing_Street__c',
            largeDeviceSize: '12'
        },
        {
            key: 'MailingCity',
            fieldName: 'Mailing_City__c',
            largeDeviceSize: '6'
        },
        {
            key: 'MailingPostalCode',
            fieldName: 'Mailing_Postcode__c',
            largeDeviceSize: '6'
        },
        {
            key: 'MailingState',
            fieldName: 'Mailing_State__c',
            largeDeviceSize: '6'
        },
        {
            key: 'MailingCountry',
            fieldName: 'Mailing_Country__c',
            largeDeviceSize: '6'
        },
    ],
    caseFieldMapping : [
        //caseField : Case field API Name
        //contactField : field key used as data-id
        {
            caseField : 'Supplied_First_Name__c',
            contactField : 'FirstName'
        },
        {
            caseField : 'Supplied_Last_Name__c',
            contactField : 'LastName'
        },
        {
            caseField : 'Supplied_Date_of_Birth__c',
            contactField : 'Birthdate'
        },
        {
            caseField : 'SuppliedPhone',
            contactField : 'OtherPhone'
        },
        {
            caseField : 'SuppliedEmail',
            contactField : 'Email'
        },
        {
            caseField : 'Supplied_Mobile__c',
            contactField : 'MobilePhone'
        },
        {
            caseField : 'Supplied_Nationality__c',
            contactField : 'Nationality__c'
        },
        {
            caseField : 'Supplied_Postcode__c',
            contactField : 'MailingPostalCode'
        },
        {
            caseField : 'Supplied_State__c',
            contactField : 'MailingState'
        },
        {
            caseField : 'Residency_Status__c',
            contactField : 'Residency_Status__c'
        },
        {
            caseField : 'Supplied_City__c',
            contactField : 'MailingCity'
        },
        {
            caseField : 'Supplied_Country_of_Residence__c',
            contactField : 'Country_of_Residence__c'
        },
        {
            caseField : 'Highest_Level_of_Study__c',
            contactField : 'Highest_level_of_education_to_date__c'
        },
    ]
};