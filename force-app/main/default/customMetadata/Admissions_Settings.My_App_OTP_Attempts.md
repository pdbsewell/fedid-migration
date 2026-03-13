<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>My.App OTP Attempts</label>
    <protected>false</protected>
    <values>
        <field>Admission_Calendar__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Configs__c</field>
        <value xsi:type="xsd:string">{
&quot;ipRateLimitEnabled&quot;: true,
&quot;ipRateLimitKey&quot;:&quot;perIP&quot;,
&quot;ipRateLimitMessage&quot;: &quot;This operation cannot be performed due to security reasons. Please try again later&quot;,
&quot;otpAttemptAllowed&quot;: 5,
&quot;otpttlInSeconds&quot;: 900,
&quot;otpMessage&quot;: &quot;Maximum OTP attempts reached&quot;,
&quot;otpAttemptMessage&quot;: &quot;You have exceeded the maximum number of verification code requests. For security reasons, you cannot request more verification codes. Please try again later&quot;
}</value>
    </values>
    <values>
        <field>Messages__c</field>
        <value xsi:type="xsd:string">Maximum OTP attempts reached. Please try again later</value>
    </values>
    <values>
        <field>Status__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Teaching_Period_Calendar__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Type__c</field>
        <value xsi:type="xsd:string">Maintenance</value>
    </values>
</CustomMetadata>
