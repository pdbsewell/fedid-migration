<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>CallistaFeeWaiverNotAvailable</label>
    <protected>false</protected>
    <values>
        <field>Admission_Calendar__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Configs__c</field>
        <value xsi:type="xsd:string">{
    &quot;myAppPaymentOptions&quot;: [
        {
            &quot;label&quot;: &quot;Credit Card&quot;,
            &quot;value&quot;: &quot;Credit Card&quot;,
            &quot;isDisabled&quot;: false
        },
        {
            &quot;label&quot;: &quot;Convera (Previously Western Union)&quot;,
            &quot;value&quot;: &quot;Western Union&quot;,
            &quot;isDisabled&quot;: false
        },
        {
            &quot;label&quot;: &quot;Application Processing Fee Waiver Code&quot;,
            &quot;value&quot;: &quot;Application Fee Waiver Code&quot;,
            &quot;isDisabled&quot;: true
        }
    ]
}</value>
    </values>
    <values>
        <field>Messages__c</field>
        <value xsi:type="xsd:string">{
    &quot;feeWaiverMessaging&quot;: &quot;&lt;b&gt;PLEASE BE ADVISED:&lt;/b&gt; The fee waiver code payment option is temporarily unavailable due to system maintenance.
&lt;br&gt;If you wish to use the Fee Waiver Code, please save your application and return to submit it once maintenance is complete.&quot;
}</value>
    </values>
    <values>
        <field>Status__c</field>
        <value xsi:type="xsd:string">Online</value>
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
