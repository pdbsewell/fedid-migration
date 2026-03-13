/**
 * @description       : For calculating the Primary Address record
 * @date              : 28-07-2023
 * @group             : Person 360
 * @author            : Nick Guia
 * @last modified on  : 22-08-2023
 * @last modified by  : Nick Guia
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/289931356/Contact+Point+Primary+Calculator
**/
public inherited sharing class PrimaryAddressCalculator extends PrimaryContactPointCalculator {


    public PrimaryAddressCalculator(List<Address__c> records, Boolean isStudent) {
        super(records, isStudent);
    }

    /**
    * @description instantiate the concrete implementation of Address sorting
    * @author Nick Guia | 11-09-2023 
    **/
    protected override ContactPointComparable createContactPointComparable(SObject contactPoint) {
        return new AddressComparable((Address__c) contactPoint);
    }

    /**
    * @description checks if there are any user-overriden primary
    * @author Nick Guia | 28-07-2023 
    **/
    protected override void maybeSetPrimaryByPrioritisedAttributes() {

        for(Address__c address : (List<Address__c>) super.contactPoints) {
            // CONDITION 1 : if there is any "user override" primary, re-tag it as primary
            if(address.Primary_set_by__c == 'user') {
                setPrimary(address);
                super.isPrimarySetByUser = true;
                break;
            }

            /**
             * Assume that we should always sort by roll up rank without the client class indicating the "shouldSort()" option.
             * This is because this rule supersedes student records and we also anticipate that queries don't always "ORDER BY" callista rank,
             * but typically with dates
             */
            addRollupRankSortableList(address);
        }
    }

    /**
    * @description rules for calculating a primary address.
    * @author Nick Guia | 28-07-2023 
    **/
    protected override void calculatePrimary() {

        if(!super.isPrimarySetByUser) {
            
            Address__c primary;

            if(super.isStudent) {
                // CONDITION 2 : if a student, mark the first callista address as primary
                primary = (Address__c) super.getHighestRollupRank();
            }

            if(primary == null) {
                // CONDITION 3 : if not a student OR without a callista address, pick the latest
                primary = (Address__c) super.contactPoints[0];
            }
            
            setPrimary(primary);
        }
    }
}