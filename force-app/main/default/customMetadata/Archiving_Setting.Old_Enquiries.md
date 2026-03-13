<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Old Enquiries</label>
    <protected>false</protected>
    <values>
        <field>Fields_to_query__c</field>
        <value xsi:type="xsd:string">Id, Archive_Date__c, Purge_Date__c, ClosedDate</value>
    </values>
    <values>
        <field>Filter_Criteria_Long__c</field>
        <value xsi:type="xsd:string">RecordType.Name = &apos;Standard Enquiry&apos; and ClosedDate &lt; 2014-01-01T00:00:00.000+1100 and Status = &apos;Solved&apos;</value>
    </values>
    <values>
        <field>Filter_criteria__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>IsActive__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>No_of_years_to_archive__c</field>
        <value xsi:type="xsd:double">7.0</value>
    </values>
    <values>
        <field>No_of_years_to_purge__c</field>
        <value xsi:type="xsd:double">7.0</value>
    </values>
    <values>
        <field>Object_Name__c</field>
        <value xsi:type="xsd:string">Case</value>
    </values>
    <values>
        <field>Record_Type__c</field>
        <value xsi:type="xsd:string">Standard Enquiry</value>
    </values>
    <values>
        <field>Status__c</field>
        <value xsi:type="xsd:string">Solved</value>
    </values>
</CustomMetadata>
