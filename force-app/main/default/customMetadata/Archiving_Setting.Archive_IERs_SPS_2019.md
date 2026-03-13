<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Archive IERs SPS 2019</label>
    <protected>false</protected>
    <values>
        <field>Fields_to_query__c</field>
        <value xsi:type="xsd:string">Id, Ready_to_Archive__c</value>
    </values>
    <values>
        <field>Filter_Criteria_Long__c</field>
        <value xsi:type="xsd:string">CreatedDate &lt; 2020-01-01T00:00:00.000+1100 AND CreatedDate &gt; 2018-12-31T00:00:00.000+1100  And Ready_to_Archive__c = false  LIMIT 49999</value>
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
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>No_of_years_to_purge__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Object_Name__c</field>
        <value xsi:type="xsd:string">et4ae5__IndividualEmailResult__c</value>
    </values>
    <values>
        <field>Record_Type__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Status__c</field>
        <value xsi:nil="true"/>
    </values>
</CustomMetadata>
