<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Offers</label>
    <protected>false</protected>
    <values>
        <field>Email_Blurb__c</field>
        <value xsi:type="xsd:string">&lt;b&gt;You need to co-sign an offer for {{applicantName}}&lt;/b&gt;&lt;br/&gt;&lt;br/&gt;Dear [[RecipientName]],&lt;br/&gt;&lt;br/&gt;You have been nominated as a guardian on behalf of &lt;b&gt;{{applicantName}}&lt;/b&gt; to co-sign their offer to study at Monash University.&lt;br/&gt;&lt;br/&gt;We would be proud to have them study with us, but your signature is required before they can start. Your signature is required by &lt;b&gt;{{expiryDate}}&lt;/b&gt;.&lt;br/&gt;&lt;br/&gt;If you see anything you would like to change or had any questions about this offer, please contact us at &lt;a href=&quot;mailto:{{contactUsEmailAddress}}&quot;&gt;here&lt;/a&gt; and quote the reference offer ID &lt;b&gt;{{quoteNumber}}&lt;/b&gt;</value>
    </values>
    <values>
        <field>Email_Subject__c</field>
        <value xsi:type="xsd:string">Sign Monash University offer</value>
    </values>
    <values>
        <field>Reminder_Delay__c</field>
        <value xsi:type="xsd:double">3.0</value>
    </values>
    <values>
        <field>Reminder_Enabled__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Reminder_Frequency__c</field>
        <value xsi:type="xsd:double">3.0</value>
    </values>
</CustomMetadata>
