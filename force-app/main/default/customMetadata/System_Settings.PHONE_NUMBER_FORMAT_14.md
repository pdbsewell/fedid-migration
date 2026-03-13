<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>USA &amp; Canada +1</label>
    <protected>false</protected>
    <values>
        <field>DataType__c</field>
        <value xsi:type="xsd:string">JSON</value>
    </values>
    <values>
        <field>Feature__c</field>
        <value xsi:type="xsd:string">PHONE_NUMBER_FORMAT</value>
    </values>
    <values>
        <field>Is_Active__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>Key__c</field>
        <value xsi:type="xsd:string">PNFNANP</value>
    </values>
    <values>
        <field>Priority_Order__c</field>
        <value xsi:type="xsd:double">150.0</value>
    </values>
    <values>
        <field>Value__c</field>
        <value xsi:type="xsd:string">{
&quot;Country_Name&quot;: &quot;USA&quot;,
&quot;Country_Code&quot;: &quot;+1&quot;,
&quot;RegEx&quot;: &quot;^(?=.{10,})^((?:\\+|00|\\+00)?1)(0?[2-9])([0-8]\\d[2-9]\\d{6})$&quot;,
&quot;Comment&quot;:&quot;Disabled as these numbers match Chinese mobile numbers that are missing a country code&quot;
}</value>
    </values>
</CustomMetadata>
