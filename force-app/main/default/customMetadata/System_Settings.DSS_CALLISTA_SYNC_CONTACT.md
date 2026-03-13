<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>DSS CALLISTA SYNC CONTACT</label>
    <protected>false</protected>
    <values>
        <field>DataType__c</field>
        <value xsi:type="xsd:string">String</value>
    </values>
    <values>
        <field>Feature__c</field>
        <value xsi:type="xsd:string">DSS_CALLISTA_BATCH_SETTINGS</value>
    </values>
    <values>
        <field>Is_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Key__c</field>
        <value xsi:type="xsd:string">CONTACT</value>
    </values>
    <values>
        <field>Priority_Order__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Value__c</field>
        <value xsi:type="xsd:string">{
&quot;querySELECT&quot; : &quot;id,person_id__c,dss_registered__c&quot;,
&quot;queryFROM&quot; : &quot;Contact&quot;,
&quot;queryWHERE&quot; : &quot;dss_registered__c = TRUE AND person_id__c != null&quot;,
&quot;maxRecords&quot; : &quot;10000&quot;,
&quot;personIdField&quot; : &quot;person_id__c&quot;,
&quot;fieldMapping&quot; : {&quot;officerResponsible&quot; : &quot;dss_officer__c&quot;}
}</value>
    </values>
</CustomMetadata>
