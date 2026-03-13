/**
 * @description       : Runs a primary calculation to multiple type of contact points(Email, Phone, Address)
 * @date              : 28-07-2023
 * @group             : Person 360
 * @author            : Nick Guia
 * @last modified on  : 23-08-2023
 * @last modified by  : Nick Guia
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/289931356/Contact+Point+Primary+Calculator
**/
public inherited sharing class CalculatePrimaryContactPointService {

    public CalculatePrimaryContactPointService() {}

    /**
    * @description run a primary calculation for each contact point provided in the parameters
    * @author Nick Guia | 31-07-2023 
    * @return Output
    **/
    public Output calculate(Input param) {
        if(param == null) {
            throw new CalculatePrimaryContactPointServiceException('Invalid null parameter');
        }
        Output returnParam = new Output();

        // store primaries
        returnParam.primaryAddress = calculatePrimaryAddress(param);
        returnParam.primaryPhone = calculatePrimaryPhone(param);
        returnParam.primaryEmail = calculatePrimaryEmail(param);
        returnParam.primaryName = calculatePrimaryName(param);

        // re-store the input address list (processed) incase client needs it
        returnParam.addressList = param.addressList;
        returnParam.phoneList = param.phoneList;
        returnParam.emailList = param.emailList;
        returnParam.nameList = param.nameList;

        // return base class so client can opt to commit whenever
        returnParam.bc = param.bc;

        return returnParam;
    }

    /**
    * @description calculate primary address
    * @author Nick Guia | 31-07-2023 
    * @param Parameters param 
    * @return Address__c : the new primary
    **/
    public Address__c calculatePrimaryAddress(Input param) {

        Address__c primary;

        if(param.addressList != null && !param.addressList.isEmpty()) {
            primary = (Address__c) calculatePrimary(new PrimaryAddressCalculator(param.addressList, param.isStudent), param);
        }
        return primary;
    }

    /**
    * @description calculate primary phone
    * @author Nick Guia | 31-07-2023 
    * @param Parameters param 
    * @return Phone__c : the new primary
    **/
    public Phone__c calculatePrimaryPhone(Input param) {

        Phone__c primary;

        if(param.phoneList != null && !param.phoneList.isEmpty()) {
            primary = (Phone__c) calculatePrimary(new PrimaryPhoneCalculator(param.phoneList, param.isStudent), param);
        }
        return primary;
    }

    /**
    * @description calculate primary email
    * @author Nick Guia | 31-07-2023 
    * @param Parameters param 
    * @return Email__c : the new primary
    **/
    public Email__c calculatePrimaryEmail(Input param) {

        Email__c primary;

        if(param.emailList != null && !param.emailList.isEmpty()) {
            primary = (Email__c) calculatePrimary(new PrimaryEmailCalculator(param.emailList, param.isStudent), param);
        }
        return primary;
    }

    /**
    * @description calculate primary email
    * @author Nick Guia | 23-08-2023 
    * @param Parameters param 
    * @return Name__c : the new primary
    **/
    public Name__c calculatePrimaryName(Input param) {
        
        Name__c primary;

        if(param.nameList != null && !param.nameList.isEmpty()) {
            primary = (Name__c) calculatePrimary(new PrimaryNameCalculator(param.nameList, param.isStudent), param);
        }
        return primary;
    }

    /**
    * @description runs the common steps the calculate the new primary contact point.
    *   The calculator must be instantiated with the concrete instance by the calling method
    * @author Nick Guia | 23-08-2023 
    * @param PrimaryContactPointCalculator calculator 
    * @param Input param 
    * @return SObject 
    **/
    @TestVisible
    private SObject calculatePrimary(PrimaryContactPointCalculator calculator, Input param) {
        calculator.shouldSortContactPoints(param.shouldSort);
        calculator.setBaseClass(param.bc);
        calculator.execute();
        return calculator.getPrimary();
    }

    public class Input extends Payload {
        // required
        public Boolean isStudent { get; private set; } 
        // if set to true, runs the Comparable classes to sort the contact points first before evaluating the primary
        public Boolean shouldSort { get; set; } 

        public Input(Boolean isStudent) {
            this.isStudent = isStudent; // required
            this.shouldSort = false; // default
        }
    }

    public class Output extends Payload { 
        public Address__c primaryAddress { get; set; }
        public Phone__c primaryPhone { get; set; }
        public Email__c primaryEmail { get; set; }
        public Name__c primaryName { get; set; }
    }

    @TestVisible
    private abstract class Payload {
        public List<Address__c> addressList { get; set; }
        public List<Phone__c> phoneList { get; set; }
        public List<Email__c> emailList { get; set; }
        public List<Name__c> nameList { get; set; }
        public BaseClass bc { get; set; }
    }

    public class CalculatePrimaryContactPointServiceException extends Exception { }
}