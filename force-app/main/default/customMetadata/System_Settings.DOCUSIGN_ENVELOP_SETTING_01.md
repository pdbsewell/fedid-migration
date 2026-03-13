<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>DOCUSIGN ENVELOP SETTING 01</label>
    <protected>true</protected>
    <values>
        <field>DataType__c</field>
        <value xsi:type="xsd:string">JSON</value>
    </values>
    <values>
        <field>Feature__c</field>
        <value xsi:type="xsd:string">DOCUSIGN_ENVELOP_SETTING</value>
    </values>
    <values>
        <field>Is_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Key__c</field>
        <value xsi:type="xsd:string">Offers</value>
    </values>
    <values>
        <field>Priority_Order__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Value__c</field>
        <value xsi:type="xsd:string">{
&quot;key&quot;:&quot;Offers&quot;,
&quot;emailSubject&quot;:&quot;Sign Monash University offer&quot;,
&quot;emailBlurb&quot;:&quot;&lt;b&gt;You need to co-sign an offer for {{applicantName}}&lt;/b&gt;&lt;br/&gt;&lt;br/&gt;Dear [[RecipientName]],&lt;br/&gt;&lt;br/&gt;You have been nominated as a guardian on behalf of &lt;b&gt;{{applicantName}}&lt;/b&gt; to co-sign their offer to study at Monash University.&lt;br/&gt;&lt;br/&gt;We would be proud to have them study with us, but your signature is required before they can start. Your signature is required by &lt;b&gt;{{expiryDate}}&lt;/b&gt;.&lt;br/&gt;&lt;br/&gt;If you see anything you would like to change or had any questions about this offer, please contact us at &lt;a href=\&quot;mailto:{{contactUsEmailAddress}}\&quot;&gt;here&lt;/a&gt; and quote the reference offer ID &lt;b&gt;{{quoteNumber}}&lt;/b&gt;&quot;,
&quot;reminderEnabled&quot;:true,
&quot;reminderDelay&quot;:&quot;3&quot;,
&quot;reminderFrequency&quot;:&quot;3&quot;
}</value>
    </values>
</CustomMetadata>
