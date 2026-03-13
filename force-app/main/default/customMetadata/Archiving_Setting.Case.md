<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Case Standard Enquiry - Monash Connect</label>
    <protected>false</protected>
    <values>
        <field>Fields_to_query__c</field>
        <value xsi:type="xsd:string">Id, Archive_Date__c, Purge_Date__c, ClosedDate, Ready_to_Archive__c</value>
    </values>
    <values>
        <field>Filter_Criteria_Long__c</field>
        <value xsi:type="xsd:string">RecordType.Name = &apos;Standard Enquiry&apos; and Status = &apos;Solved&apos; and Archive_Date__c = null and Purge_Date__c = null</value>
    </values>
    <values>
        <field>Filter_criteria__c</field>
        <value xsi:type="xsd:string">RecordType.Name = &apos;Standard Enquiry&apos; and Status = &apos;Solved&apos; and Archive_Date__c = null and Purge_Date__c = null and Enquiry_Owner_Role__c LIKE &apos;Monash Connect%&apos; AND ClosedDate &lt; 2016-10-01T00:00:00.000+1100 LIMIT 50000</value>
    </values>
    <values>
        <field>IsActive__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>No_of_years_to_archive__c</field>
        <value xsi:type="xsd:double">4.0</value>
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
        <value xsi:type="xsd:string">Standard</value>
    </values>
    <values>
        <field>Status__c</field>
        <value xsi:type="xsd:string">Solved</value>
    </values>
</CustomMetadata>
