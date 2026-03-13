<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Case Standard Enquiry - Faculty</label>
    <protected>false</protected>
    <values>
        <field>Fields_to_query__c</field>
        <value xsi:type="xsd:string">Id, Archive_Date__c, Purge_Date__c, ClosedDate</value>
    </values>
    <values>
        <field>Filter_Criteria_Long__c</field>
        <value xsi:type="xsd:string">RecordType.Name = &apos;Standard Enquiry&apos; AND Status = &apos;Solved&apos; AND ClosedDate &lt; 2017-10-01T00:00:00.000+1100 AND (Enquiry_Owner_Role__c = &apos;Art, Design and Architecture&apos; OR Enquiry_Owner_Role__c = &apos;Arts&apos; OR Enquiry_Owner_Role__c = &apos;Biomedical Science&apos; OR Enquiry_Owner_Role__c = &apos;Business and Economics&apos; OR Enquiry_Owner_Role__c = &apos;Education&apos; OR Enquiry_Owner_Role__c = &apos;Engineering&apos; OR Enquiry_Owner_Role__c = &apos;Faculty&apos; OR Enquiry_Owner_Role__c = &apos;Faculty - Training&apos; OR Enquiry_Owner_Role__c = &apos;Law&apos; OR Enquiry_Owner_Role__c = &apos;Law (PG)&apos; OR Enquiry_Owner_Role__c = &apos;Law (UG)&apos; OR Enquiry_Owner_Role__c = &apos;Medicine, Nursing and Health Sciences&apos; OR Enquiry_Owner_Role__c = &apos;Nursing &amp; Midwifery&apos; OR Enquiry_Owner_Role__c = &apos;Science (UG)&apos; OR Enquiry_Owner_Role__c = &apos;Pharmacy and Pharmaceutical Sciences&apos; OR Enquiry_Owner_Role__c = &apos;Primary and Allied Health Care&apos;OR Enquiry_Owner_Role__c = &apos;Arts - Future Student&apos; OR Enquiry_Owner_Role__c = &apos;Education - Future Student&apos; OR Enquiry_Owner_Role__c = &apos;Law Future Student (UG)&apos; OR Enquiry_Owner_Role__c = &apos;Law Future Student (PG)&apos; OR Enquiry_Owner_Role__c = &apos;Nursing and Midwifery - Future Student&apos; OR Enquiry_Owner_Role__c = &apos;Primary Health - Future Student&apos;) LIMIT 50000</value>
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
        <value xsi:type="xsd:double">4.0</value>
    </values>
    <values>
        <field>No_of_years_to_purge__c</field>
        <value xsi:type="xsd:double">7.0</value>
    </values>
    <values>
        <field>Object_Name__c</field>
        <value xsi:type="xsd:string">Case</value>
    </values>
    <values>
        <field>Record_Type__c</field>
        <value xsi:type="xsd:string">Standard</value>
    </values>
    <values>
        <field>Status__c</field>
        <value xsi:type="xsd:string">Solved</value>
    </values>
</CustomMetadata>
