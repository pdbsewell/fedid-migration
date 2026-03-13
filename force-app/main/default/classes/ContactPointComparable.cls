/**
 * @description       : Comparable class for sorting Contact Point Object survivorship.
 *                      This can be used for sorting Contact Point records stored in an ordered data type (List).
 *                      e.g. Primary calculations are heavily reliant on List ordering
 * @date              : 28-07-2023
 * @group             : Person 360
 * @author            : Nick Guia
 * @last modified on  : 01-08-2023
 * @last modified by  : Nick Guia
 * @revision
 *  01-08-2023  Nick Guia   - updated pattern to enable chaining on subclasses and override with less rules if requried
 *  11-09-2023  Nick Guia   - updated from virtual to abstract > created a concrete implementation of EmailComparable for legibility and more comprehensive class structure
**/
public abstract inherited sharing class ContactPointComparable implements Comparable {

    public final SObject compareFrom;

    public ContactPointComparable(SObject contactPoint) {

        // first do a null check
        if(contactPoint == null) {
            throw new ContactPointComparableException('Invalid null argument on constructor');
        }

        this.compareFrom = contactPoint;
    }

    /**
    * @description first compare with start date, then created date, last resort is channel
    * @author Nick Guia | 28-07-2023 
    * @param Object compareObj 
    * @return Integer 
    *   -1 – The current value is greater than the compared value
    *   0 –  The current value is equal to the compared value
    *   1 –  The current value is less than the compared value
    * @throws ContactPointComparableException
    **/
    public Integer compareTo(Object compareObj) {
        
        ContactPointComparable newComparable =  (ContactPointComparable) compareObj;
        SObject compareWith = newComparable.compareFrom;

        /**
         * Chaining of rule evaluation. If an additional rule is needed by a
         * different implementation, override rule 3 and chain the additional rule(s)
         */
        return runRuleChain(this.compareFrom, compareWith); 
    }

    /**
    * @description main method to start the execution of rule chaining. This enables
    *   each specific rule to be overriden by subclasses
    * @author Nick Guia | 01-08-2023 
    * @param SObject compareFrom 
    * @param SObject compareWith 
    * @return Integer 
    **/
    @TestVisible
    private Integer runRuleChain(SObject compareFrom, SObject compareWith) {
        return rule1(compareFrom, compareWith);
    }

    /**
    * @description RULE 1 : compare by start date - latest start date wins
    * @author Nick Guia | 31-07-2023 
    * @param SObject compareFrom 
    * @param SObject compareWith 
    * @return Integer 
    **/
    @TestVisible
    protected virtual Integer rule1(SObject compareFrom, SObject compareWith) {
        Integer eval = 0; // null safe
        eval = compareDateTime(
            (Datetime) compareFrom.get('Start_Date__c'), 
            (Datetime) compareWith.get('Start_Date__c'),
            true
        );
        if(eval == 0) return rule2(compareFrom, compareWith); // chain
        return eval;
    }

    /**
    * @description RULE 2 : if start dates are the same, compare by Created Date
    * @author Nick Guia | 31-07-2023 
    * @param SObject compareFrom 
    * @param SObject compareWith 
    * @return Integer 
    **/
    @TestVisible
    protected virtual Integer rule2(SObject compareFrom, SObject compareWith) {
        Integer eval = 0; // null safe
        eval = compareDateTime(
            (Datetime) compareFrom.get('CreatedDate'), 
            (Datetime) compareWith.get('CreatedDate'),
            false
        );
        if(eval == 0) return rule3(compareFrom, compareWith); // chain
        return eval;
    }

    /**
    * @description RULE 3 : if created dates are the same, compare by channels
    * @author Nick Guia | 31-07-2023 
    * @param SObject compareFrom 
    * @param SObject compareWith 
    * @return Integer 
    **/
    @TestVisible
    protected virtual Integer rule3(SObject compareFrom, SObject compareWith) {
        return compareNull(
            compareFrom.get('Channel__c'),
            compareWith.get('Channel__c')
        );
    }


    /**
    * @description compares two datetimes
    * @author Nick Guia | 31-07-2023 
    * @param DateTime compareFromDt 
    * @param DateTime compareWithDt 
    * @param Boolean compareNull : if set to true, will also run null checks. Only recommended as false for non-nullable fields such as created date
    * @return Integer 
    *   -1 if 1st parameter is greater than the 2nd parameter
    *   1  if 1st parameter is less than the 2nd parameter
    *   0  if none applies
    **/
    @TestVisible
    private Integer compareDateTime(DateTime compareFromDt, DateTime compareWithDt, Boolean compareNull) {
        Integer val = 0;

        if(compareNull) {
            val = compareNull(compareFromDt, compareWithDt);
        }

        if(val == 0) {
            if(compareFromDt > compareWithDt) return -1;
            if(compareFromDt < compareWithDt) return 1;
        }

        return 0;
    }

    /**
    * @description compare two objects via null checks
    * @author Nick Guia | 31-07-2023 
    * @param Object compareFromFieldVal 
    * @param Object compareWithFieldVal 
    * @return Integer
    *   -1 if 1st parameter is not null and 2nd parameter is null
    *   1  if 1st parameter is null and 2nd parameter is not null
    *   0  if none applies
    **/
    @TestVisible
    private Integer compareNull(Object compareFromFieldVal, Object compareWithFieldVal) {
        if(compareFromFieldVal != null && compareWithFieldVal == null) return -1;
        if(compareFromFieldVal == null && compareWithFieldVal != null) return 1;
        return 0;
    }

    public class ContactPointComparableException extends Exception { }
}