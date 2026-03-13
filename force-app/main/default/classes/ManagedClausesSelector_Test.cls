/**
 * @File Name          : ManagedClausesSelectorTest.cls
 * @Description        : Managed Clause selector class
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : Offer
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 12/17/2019, 10:43:27 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    12/17/2019   jasmin.rudio@monash.edu     Initial Version
**/
@isTest(isParallel=true)
public with sharing class ManagedClausesSelector_Test {
    @isTest static void selectById() {
        List<APXT_Redlining__Managed_Clause__c> clauses = new ManagedClausesSelector().selectById(new Set<Id>());
        System.assertEquals(new List<APXT_Redlining__Managed_Clause__c>(), clauses,
                            'Expected empty list of clauses as Id list is empty');
    }
    @isTest static void selectByQuoteId() { 
        List<APXT_Redlining__Managed_Clause__c> clauses = new ManagedClausesSelector(false).selectByQuoteId(new Set<String>());
        System.assertEquals(new List<APXT_Redlining__Managed_Clause__c>(), clauses,
                            'Expected empty list of clauses as Id list is empty');
    }
    @isTest static void selectByQuoteLineLocation() { 
        List<APXT_Redlining__Managed_Clause__c> clauses = new ManagedClausesSelector().selectByQuoteLineLocation(new Set<String>(),'Australia');
        System.assertEquals(new List<APXT_Redlining__Managed_Clause__c>(), clauses,
                            'Expected empty list of clauses as Id list is empty');
    }
}