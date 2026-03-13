/**
 * @description       : Comparable class for Address records. Used for sorting with the "most likely" primary first.
 *                      Only evaluates rule 1 (Start date) and rule 2 (Created date). If equal, rule 3 evaluates to 0
 * @author            : Nick Guia
 * @group             : Person 360
 * @last modified on  : 03-08-2023
 * @last modified by  : Nick Guia
 * @see               : https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/287244919/Contact+Point+Comparable+Sorting
**/
public inherited sharing class AddressComparable extends ContactPointComparable {

    public AddressComparable(Address__c rec) {
        super(rec);
    }

    /**
    * @description we don't need to compare by Channel. If it reaches to this, return equal
    * @author Nick Guia | 03-08-2023 
    * @param SObject compareFrom 
    * @param SObject compareWith 
    * @return Integer 
    **/
    public override Integer rule3(SObject compareFrom, SObject compareWith) {
        return 0;
    }
}