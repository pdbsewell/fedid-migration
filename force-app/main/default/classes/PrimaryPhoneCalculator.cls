/**
 * @description       : For calculating the Primary Phone record
 * @date              : 28-07-2023
 * @group             : Person 360
 * @author            : Nick Guia
 * @last modified on  : 23-08-2023
 * @last modified by  : Nick Guia
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/289931356/Contact+Point+Primary+Calculator
 * TODO : we must work towards implementing the same rules on PrimaryAddressCalculator to utilise Callista_rollup_rank__c
**/
public inherited sharing class PrimaryPhoneCalculator extends PrimaryContactPointCalculator {

    public PrimaryPhoneCalculator(List<Phone__c> records, Boolean isStudent) {
        super(records, isStudent);
    }

    /**
    * @description instantiate the concrete implementation of phone sorting
    * @author Nick Guia | 11-09-2023 
    **/
    protected override ContactPointComparable createContactPointComparable(SObject contactPoint) {
        return new PhoneComparable((Phone__c) contactPoint);
    }

    /**
    * @description checks if there are any user-overriden primary
    * @author Nick Guia | 28-07-2023 
    **/
    protected override void maybeSetPrimaryByPrioritisedAttributes() {
        for(Phone__c phoneRec : (List<Phone__c>) super.contactPoints) {
             // CONDITION 1 : if there is any "user override" primary, re-tag it as primary
            if(phoneRec.Primary_set_by__c == 'user') {
                setPrimary(phoneRec);
                super.isPrimarySetByUser = true;
                break;
            }
        }
    }

    /**
    * @description rules for calculating a primary phone.
    * @author Nick Guia | 28-07-2023 
    **/
    protected override void calculatePrimary() {
        // CONDITION 2 : if no primary overrides, grab the first record and mark it as primary
        if(!super.isPrimarySetByUser) {
            setPrimary(super.contactPoints[0]);
        }
    }
}