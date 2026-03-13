<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>MFA Enforcement</label>
    <protected>false</protected>
    <values>
        <field>DataType__c</field>
        <value xsi:type="xsd:string">JSON</value>
    </values>
    <values>
        <field>Feature__c</field>
        <value xsi:type="xsd:string">USER_DEFAULT_PERMISSIONS</value>
    </values>
    <values>
        <field>Is_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Key__c</field>
        <value xsi:type="xsd:string">UDPmfa</value>
    </values>
    <values>
        <field>Priority_Order__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Value__c</field>
        <value xsi:type="xsd:string">{
&quot;Permission_Type&quot;: &quot;Permission Set&quot;,
&quot;Permissions&quot;: &quot;Auth_Enforce_MFA&quot;
}</value>
    </values>
</CustomMetadata>
