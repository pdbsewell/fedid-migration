/**
 * @description       : For calculating the Primary Name record
 * @date              : 28-07-2023
 * @group             : Person 360
 * @author            : Nick Guia
 * @last modified on  : 23-08-2023
 * @last modified by  : Nick Guia
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/289931356/Contact+Point+Primary+Calculator
 * TODO : we must work towards implementing the same rules on PrimaryAddressCalculator to utilise Callista_rollup_rank__c
**/
public inherited sharing class PrimaryNameCalculator extends PrimaryContactPointCalculator {

    // TODO : Person360Helper.SortableContactPoint is the legacy implementation of Name sorting.
    // this can be moved to extend ContactPointComparable and keep all abstraction in the
    // within the parent class for centralisation similar to other contact point primary calculators
    
    public PrimaryNameCalculator(List<Name__c> records, Boolean isStudent) {
        super(records, isStudent);
        // since Name has its own sorting implementation, default this to always be false for now
        // NameServices.findPrimary will be doing the sorting instead
        shouldSortContactPoints(false);
    }

    /**
    * @description Name doesn't have its own Comparable class (yet)
    * @author Nick Guia | 11-09-2023 
    **/
    protected override ContactPointComparable createContactPointComparable(SObject contactPoint) {
        return null;
    }

    /**
    * @description checks if there are any user-overriden primary
    * @author Nick Guia | 22-08-2023
    **/
    protected override void maybeSetPrimaryByPrioritisedAttributes() {

        for(Name__c nameRec : (List<Name__c>) super.contactPoints) {
            // CONDITION 1 : if there is any "user override" primary, re-tag it as primary
            if(nameRec.Primary_set_by__c == 'user') {
                setPrimary(nameRec);
                super.isPrimarySetByUser = true;
                break;
            }
        }
    }

    /**
    * @description rules for calculating a primary name.
    * @author Nick Guia | 22-08-2023
    **/
    protected override void calculatePrimary() {
        if(!super.isPrimarySetByUser) {
            Name__c newPrimary = NameServices.findPrimary((List<Name__c>) super.contactPoints, super.isStudent);
            setPrimary(newPrimary);
        }
    }
}