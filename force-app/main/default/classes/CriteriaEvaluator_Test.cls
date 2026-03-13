@isTest(isParallel=true)
public with sharing class CriteriaEvaluator_Test {
    @isTest
    static void test_isMeetingCriteria(){
        System.assert(true == CriteriaEvaluator.isMeetingCriteria(new Opportunity(Amount = 40000), 'Amount', '40000','equals'));
        System.assert(true == CriteriaEvaluator.isMeetingCriteria(new Opportunity(Amount = 40000), 'Amount', '50000','not equals'));
        System.assert(true == CriteriaEvaluator.isMeetingCriteria(new Opportunity(Amount = 50000), 'Amount', '40000','greater'));
        System.assert(true == CriteriaEvaluator.isMeetingCriteria(new Opportunity(Amount = 50000), 'Amount', '40000','greater or equals'));
        System.assert(true == CriteriaEvaluator.isMeetingCriteria(new Opportunity(Amount = 30000), 'Amount', '40000','less'));
        System.assert(true == CriteriaEvaluator.isMeetingCriteria(new Opportunity(Amount = 30000), 'Amount', '40000','less or equals'));
        System.assert(true == CriteriaEvaluator.isMeetingCriteria(new Opportunity(Name = 'World'), 'Name', 'World,Hello,Foo','contains'));
    }
    @isTest 
    static void test_isequals(){
        System.assert(false == CriteriaEvaluator.isequals(Date.today(), String.valueOf(Date.today().addDays(-5))));
        System.assert(false == CriteriaEvaluator.isequals(Datetime.now(), String.valueOf(Datetime.now().addDays(-5))));
        System.assert(true == CriteriaEvaluator.isequals(Integer.valueOf(1), String.valueOf('1')));
        System.assert(true == CriteriaEvaluator.isequals(Double.valueOf(1.5), String.valueOf('1.5')));
        System.assert(true == CriteriaEvaluator.isequals((Decimal)1.5, String.valueOf('1.5')));
        System.assert(true == CriteriaEvaluator.isequals(true, String.valueOf('true')));
        System.assert(true == CriteriaEvaluator.isequals('hello', 'hello'));
    }
    @isTest 
    static void test_isnotequals(){
        System.assert(true == CriteriaEvaluator.isnotequals(Date.today(), String.valueOf(Date.today().addDays(-5))));
        System.assert(true == CriteriaEvaluator.isnotequals(Datetime.now(), String.valueOf(Datetime.now().addDays(-5))));
        System.assert(false == CriteriaEvaluator.isnotequals(Integer.valueOf(1), String.valueOf('1')));
        System.assert(false == CriteriaEvaluator.isnotequals(Double.valueOf(1.5), String.valueOf('1.5')));
        System.assert(false == CriteriaEvaluator.isnotequals((Decimal)1.5, String.valueOf('1.5')));
        System.assert(false == CriteriaEvaluator.isnotequals(true, String.valueOf('true')));
        System.assert(true == CriteriaEvaluator.isnotequals('hello', 'world'));
    }

    @isTest 
    static void test_issmallerthan(){
        System.assert(false == CriteriaEvaluator.issmallerthan(Date.today(), String.valueOf(Date.today().addDays(-5))));
        System.assert(false == CriteriaEvaluator.issmallerthan(Datetime.now(), String.valueOf(Datetime.now().addDays(-5))));
        System.assert(true == CriteriaEvaluator.issmallerthan(Integer.valueOf(1), String.valueOf('2')));
        System.assert(false == CriteriaEvaluator.issmallerthan(Double.valueOf(2), String.valueOf('1.5')));
        System.assert(false == CriteriaEvaluator.issmallerthan((Decimal)2, String.valueOf('1.5')));
    }

    @isTest 
    static void test_issmallerorequalsthan(){
        System.assert(false == CriteriaEvaluator.issmallerorequalsthan(Date.today(), String.valueOf(Date.today().addDays(-5))));
        System.assert(false == CriteriaEvaluator.issmallerorequalsthan(Datetime.now(), String.valueOf(Datetime.now().addDays(-5))));
        System.assert(true == CriteriaEvaluator.issmallerorequalsthan(Integer.valueOf(1), String.valueOf('2')));
        System.assert(false == CriteriaEvaluator.issmallerorequalsthan(Double.valueOf(2), String.valueOf('1.5')));
        System.assert(false == CriteriaEvaluator.issmallerorequalsthan((Decimal)2, String.valueOf('1.5')));
    }

    @isTest 
    static void test_isgreaterthan(){
        System.assert(true == CriteriaEvaluator.isgreaterthan(Date.today(), String.valueOf(Date.today().addDays(-5))));
        System.assert(true == CriteriaEvaluator.isgreaterthan(Datetime.now(), String.valueOf(Datetime.now().addDays(-5))));
        System.assert(false == CriteriaEvaluator.isgreaterthan(Integer.valueOf(1), String.valueOf('2')));
        System.assert(true == CriteriaEvaluator.isgreaterthan(Double.valueOf(2), String.valueOf('1.5')));
        System.assert(true == CriteriaEvaluator.isgreaterthan((Decimal)2, String.valueOf('1.5')));
    }

    @isTest 
    static void test_isgreaterorequalsthan(){
        System.assert(true == CriteriaEvaluator.isgreaterorequalsthan(Date.today(), String.valueOf(Date.today().addDays(-5))));
        System.assert(true == CriteriaEvaluator.isgreaterorequalsthan(Datetime.now(), String.valueOf(Datetime.now().addDays(-5))));
        System.assert(false == CriteriaEvaluator.isgreaterorequalsthan(Integer.valueOf(1), String.valueOf('2')));
        System.assert(true == CriteriaEvaluator.isgreaterorequalsthan(Double.valueOf(2), String.valueOf('1.5')));
        System.assert(true == CriteriaEvaluator.isgreaterorequalsthan((Decimal)2, String.valueOf('1.5')));
    }

    @isTest
    static void test_parseDate(){
        System.assert(CriteriaEvaluator.parseDate('TODAY|y+2') != null);
        System.assert(CriteriaEvaluator.parseDate('TODAY|m-2') != null);
        System.assert(CriteriaEvaluator.parseDate('THIS_WEEK|d-2') != null);
        System.assert(CriteriaEvaluator.parseDate('THIS_MONTH|m+2') != null);
        System.assert(CriteriaEvaluator.parseDate('HELLO|m+2') == null);
        System.assert(CriteriaEvaluator.parseDate('TODAY|X+2') == null);
    }

    @isTest
    static void test_parseDatetime(){
        System.assert(CriteriaEvaluator.parseDatetime('NOW|y+2') != null);
        System.assert(CriteriaEvaluator.parseDatetime('NOW|m-2') != null);
        System.assert(CriteriaEvaluator.parseDatetime('NOW|d-2') != null);
        System.assert(CriteriaEvaluator.parseDatetime('NOW|H+2') != null);
        System.assert(CriteriaEvaluator.parseDatetime('NOW|M+2') != null);
        System.assert(CriteriaEvaluator.parseDatetime('HELLO|m+2') == null);
        System.assert(CriteriaEvaluator.parseDatetime('NOW|X+2') == null);
    }
}