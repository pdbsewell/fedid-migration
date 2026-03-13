/**
 * @author Trent De Laney
 * @date 16 Dec 2019 at 8:13:25 pm
 * @group Test Class
 * @description Covers the DataValidatorFactory class
 */
@IsTest
public with sharing class DataValidatorFactory_Test {
    @IsTest
    public static void getAgentPortalValidator(){
        IDataValidator dataValidator = DataValidatorFactory.getValidator('AgentPortal');
        AgentPortalDataValidator apDataValidator = (AgentPortalDataValidator)dataValidator;
        System.assertNotEquals(null, apDataValidator, 'Not returning the correct Data Validator for Agent Portal');
    }
    @IsTest
    public static void getIDPValidator(){
        IDataValidator dataValidator = DataValidatorFactory.getValidator('IDP');
        IDPDataValidator idpDataValidator = (IDPDataValidator)dataValidator;
        System.assertNotEquals(null, idpDataValidator, 'Not returning the correct Data Validator for IDP');
    }

    @IsTest
    public static void getOESValidator(){
        IDataValidator dataValidator = DataValidatorFactory.getValidator('OES');
        IDPDataValidator idpDataValidator = (IDPDataValidator)dataValidator;
        System.assertNotEquals(null, idpDataValidator, 'Not returning the correct Data Validator for OES');
    }

    @IsTest
    public static void getValidatorNull(){
        IDataValidator dataValidator = DataValidatorFactory.getValidator(null);
        IDPDataValidator idpDataValidator = (IDPDataValidator)dataValidator;
        System.assertEquals(null, idpDataValidator, 'Handling null values');
    }
}