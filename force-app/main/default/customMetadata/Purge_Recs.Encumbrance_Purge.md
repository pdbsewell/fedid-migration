<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Encumbrance Purge</label>
    <protected>false</protected>
    <values>
        <field>Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>BatchSize__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Filter_By_Date__c</field>
        <value xsi:type="xsd:string">CreatedDate</value>
    </values>
    <values>
        <field>Filter_Criteria__c</field>
        <value xsi:type="xsd:string">Deleted_In_Source__c= true</value>
    </values>
    <values>
        <field>Limit__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Object__c</field>
        <value xsi:type="xsd:string">Encumbrance__c</value>
    </values>
    <values>
        <field>Older_than__c</field>
        <value xsi:type="xsd:double">0.0</value>
    </values>
    <values>
        <field>Order_By__c</field>
        <value xsi:nil="true"/>
    </values>
</CustomMetadata>
