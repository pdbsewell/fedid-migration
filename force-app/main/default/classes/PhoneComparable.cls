/**
 * @description       : Comparable class for Phone records. Used for sorting with the "most likely" primary first.
 * @author            : Nick Guia
 * @group             : Person 360
 * @last modified on  : 01-08-2023
 * @last modified by  : Nick Guia
 * @see               : https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/287244919/Contact+Point+Comparable+Sorting
**/
public inherited sharing class PhoneComparable extends ContactPointComparable {

    public PhoneComparable(Phone__c rec) {
        super(rec);
    }

    /**
    * @description Compare the phone types, mobile is prioritised when possible,
    *   otherwise, landline, otherwise equal
    * @author Nick Guia | 31-07-2023 
    * @param Object compareObj 
    * @return Integer 
    **/
    public override Integer rule3(SObject compareFrom, SObject compareWith) {
        String compareFromType = (String) compareFrom.get('Type__c');
        String compareWithType = (String) compareWith.get('Type__c');

        if(compareFromType != compareWithType) {
            if(compareFromType.equalsIgnoreCase('mobile')) return -1;
            if(compareWithType.equalsIgnoreCase('mobile')) return 1;
            
            if(compareFromType.equalsIgnoreCase('Landline')) return -1;
            if(compareWithType.equalsIgnoreCase('Landline')) return 1;
            // if anything else, return equal
        }
        return 0;
    }
}