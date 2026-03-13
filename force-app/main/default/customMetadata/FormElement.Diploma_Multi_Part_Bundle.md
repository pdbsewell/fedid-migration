<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Diploma Multi-Part Bundle</label>
    <protected>false</protected>
    <values>
        <field>API_Name__c</field>
        <value xsi:type="xsd:string">BUNDIP</value>
    </values>
    <values>
        <field>Component_Name__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Description__c</field>
        <value xsi:type="xsd:string">&lt;br/&gt;
&lt;div class=&quot;slds-form&quot;&gt;
&lt;h1 class=&quot;course-header&quot;&gt;#COURSE_HEADER#&lt;/h1&gt;
&lt;div class=&quot;offer-title&quot;&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot;&gt;
&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-01&quot;&gt;&lt;h1 class=&quot;sub-title&quot;&gt;Monash College Pty Ltd Offer&lt;/h1&gt;
&lt;div class=&quot;slds-form-element__control header-date&quot;&gt;
&lt;span id=&quot;form-element-01&quot;&gt;
&lt;p&gt;&lt;span class=&quot;gray-label&quot;&gt;Start Date:&lt;/span&gt; &lt;span style=&quot;padding-left: 20px;&quot;&gt;#START_DATE#&lt;/span&gt;&lt;/p&gt;
&lt;p&gt;&lt;span class=&quot;gray-label&quot;&gt;End Date:&lt;/span&gt; &lt;span style=&quot;padding-left: 28px;&quot;&gt;#END_DATE#&lt;/span&gt;&lt;/p&gt;
&lt;/span&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;hr/&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot;&gt;
&lt;div class=&quot;label-div&quot;&gt;&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-01&quot;&gt;&lt;span class=&quot;gray-label&quot;&gt;Course Name&lt;/span&gt;&lt;/div&gt;
&lt;div class=&quot;slds-form-element__control form-content&quot;&gt;
&lt;span id=&quot;form-element-01&quot;&gt;&lt;b&gt;#COURSE_TITLE# Part #PRIMARY_SUB_FAMILY# #COURSE_CODE# &lt;br/&gt;
#COURSE_TITLE# Part #OPTION_SUB_FAMILY#
&lt;/b&gt;&lt;/span&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot;&gt;
&lt;div class=&quot;label-div&quot;&gt;&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-11&quot;&gt;&lt;span class=&quot;gray-label&quot;&gt;CRICOS Course Code&lt;/span&gt;&lt;/label&gt;&lt;/div&gt;
&lt;div class=&quot;slds-form-element__control form-content&quot;&gt;
&lt;span id=&quot;form-element-11&quot;&gt;#CRICOS_CODE#&lt;/span&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot;&gt;
&lt;div class=&quot;label-div&quot;&gt;&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-02&quot;&gt;&lt;span class=&quot;gray-label&quot;&gt;Campus&lt;/span&gt;&lt;/div&gt;
&lt;div class=&quot;slds-form-element__control form-content&quot;&gt;
&lt;span id=&quot;form-element-02&quot;&gt;#LOCATION#&lt;/span&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot;&gt;
&lt;div class=&quot;label-div&quot;&gt;&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-03&quot;&gt;&lt;span class=&quot;gray-label&quot;&gt;Course Duration&lt;/span&gt;&lt;/div&gt;
&lt;div class=&quot;slds-form-element__control form-content&quot;&gt;
&lt;span id=&quot;form-element-03&quot;&gt;
&lt;span style=&quot;display: #NO_RPL_STYLE#&quot;&gt;
#DURATION_FT# (No credits granted)
&lt;/span&gt;
&lt;span style=&quot;display: #WITH_RPL_STYLE#&quot;&gt;
#COURSE_DURATION# with credit exemptions. Note, the course duration without the credit exemptions is #DURATION_FT#
&lt;/span&gt;
&lt;/span&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot;&gt;
&lt;div class=&quot;label-div&quot;&gt;&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-04&quot;&gt;&lt;span class=&quot;gray-label&quot;&gt;Credit points required to complete this course&lt;/span&gt;&lt;/div&gt;
&lt;div class=&quot;slds-form-element__control form-content long-label&quot;&gt;
&lt;span id=&quot;form-element-04&quot;&gt;
&lt;span style=&quot;display: #NO_RPL_STYLE#&quot;&gt;
#BUNDLE_CREDIT_POINTS_UPDATED# credit points are required to complete this course (No credits granted)
&lt;/span&gt;
&lt;span style=&quot;display: #WITH_RPL_STYLE#&quot;&gt;
#BUNDLE_CREDIT_POINTS_UPDATED# credit points are required to complete this course &lt;br/&gt;
Note the credit points required to complete this course without credit exemptions is #BUNDLE_CREDIT_POINTS# credit points.
&lt;/span&gt;
&lt;/span&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot;&gt;
&lt;div class=&quot;label-div&quot;&gt;&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-03&quot;&gt;&lt;span class=&quot;gray-label&quot;&gt;Mode of Study&lt;/span&gt;&lt;/div&gt;
&lt;div class=&quot;slds-form-element__control form-content &quot;&gt;
&lt;span id=&quot;form-element-03&quot;&gt;#MODE_OF_STUDY# Please refer to Monash College course information at https://www.monash.edu/study/courses/find-a-course for more information concerning modes of study&lt;/span&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot;&gt;
&lt;div class=&quot;label-div&quot;&gt;&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-04&quot;&gt;&lt;span class=&quot;gray-label&quot;&gt;Non-Tuition Fees&lt;/span&gt;&lt;/div&gt;
&lt;div class=&quot;slds-form-element__control form-content&quot;&gt;
&lt;span id=&quot;form-element-04&quot;&gt;
In some circumstances additional non-tuition fees may apply. Please refer to the Non-Tuition Fees Table which lists administrative charges that apply in certain situations which can be found here: https://www.monash.edu/students/admin/fees/other-costs/miscellaneous-fees &lt;br/&gt;&lt;br/&gt;
Further non-tuition fees may be listed in the link found here: https://www.monash.edu/students/admin/fees/other-costs/study If you require further information contact Monash Connect on 03 9902 6011 or https://www.monash.edu/students/support/connect
&lt;/span&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;hr/&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot;&gt;
&lt;div class=&quot;label-div&quot;&gt;&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-05&quot;&gt;&lt;span class=&quot;gray-label&quot;&gt;CONDITIONS&lt;/span&gt;&lt;/div&gt;
&lt;div class=&quot;slds-form-element__control form-content&quot;&gt;
&lt;span id=&quot;form-element-05&quot;&gt;#OFFER_CONDITION#&lt;/span&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot; style=&quot;display:#NOTES_DISPLAY#&quot;&gt;
&lt;div class=&quot;label-div&quot;&gt;&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-06&quot;&gt;&lt;span class=&quot;gray-label&quot;&gt;PLEASE NOTE&lt;/span&gt;&lt;/div&gt;
&lt;div class=&quot;slds-form-element__control form-content&quot;&gt;
&lt;span id=&quot;form-element-06&quot;&gt;
#CLAUSE_NOTES#
&lt;/span&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;div class=&quot;rectangle&quot;&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot;&gt;
&lt;div class=&quot;label-div&quot;&gt;&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-07&quot;&gt;Tuition Fee&lt;/div&gt;
&lt;div class=&quot;slds-form-element__control form-content&quot;&gt;
&lt;span id=&quot;form-element-07&quot;&gt;
A$ #TOTAL_TUITION_FEE# Part #PRIMARY_SUB_FAMILY# &lt;br/&gt;
#OPTION_ANNUAL_TUITION_FEE# Part #OPTION_SUB_FAMILY#
&lt;/span&gt;
&lt;/div&gt;
&lt;/div&gt;
&lt;hr/&gt;
&lt;div class=&quot;slds-form-element slds-form-element_horizontal&quot;&gt;
&lt;div class=&quot;label-div&quot;&gt;&lt;label class=&quot;slds-form-element__label&quot; for=&quot;form-element-08&quot;&gt;Estimated total tuition fee payable to complete this course&lt;/div&gt;
&lt;div class=&quot;slds-form-element__control form-content total-tuition-long-label&quot;&gt;
&lt;span id=&quot;form-element-08&quot;&gt;
&lt;span style=&quot;display: #NO_RPL_STYLE#&quot;&gt;
A$ #BUNDLE_TOTAL_TUITION_FEE# &lt;br/&gt;&lt;br/&gt; (No credits granted)
&lt;/span&gt;
&lt;span style=&quot;display: #WITH_RPL_STYLE#&quot;&gt;
A$ #BUNDLE_NET_TOTAL_TUITION_FEE# &lt;br/&gt;&lt;br/&gt;
(Note the estimated total tuition fee without exemptions is A$ #BUNDLE_TOTAL_TUITION_FEE#)
&lt;/span&gt;
&lt;/span&gt;
&lt;/div&gt;
&lt;hr/&gt;
&lt;/div&gt;
&lt;/div&gt;</value>
    </values>
    <values>
        <field>Display_Type__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Form_Page__c</field>
        <value xsi:type="xsd:string">OfferForm_OfferDetails</value>
    </values>
    <values>
        <field>Label__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Parent_Element__c</field>
        <value xsi:type="xsd:string">offer-details-1</value>
    </values>
    <values>
        <field>Sort_Order__c</field>
        <value xsi:type="xsd:double">4.0</value>
    </values>
</CustomMetadata>
