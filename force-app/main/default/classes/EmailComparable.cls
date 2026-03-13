/**
 * @description       : Comparable class for Address records. Used for sorting with the "most likely" primary first.
 * @author            : Nick Guia
 * @group             : Person 360
 * @last modified on  : 11-09-2023
 * @last modified by  : Nick Guia
 * @see               : https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/287244919/Contact+Point+Comparable+Sorting
**/
public inherited sharing class EmailComparable extends ContactPointComparable {

    public EmailComparable(Email__c rec) {
        super(rec);
    }

    // no deviating rules from base implementation yet
}