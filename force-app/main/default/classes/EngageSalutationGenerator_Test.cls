/**
 * @description       : 
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 02-05-2022
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(isParallel=true)
public class EngageSalutationGenerator_Test {
    @testSetup
    public static void setupData() {
        List<Account> accountDataList = new List<Account>();
        Account acc1 = new Account(Name='Account 1');
        accountDataList.add(acc1);
        Account acc2 = new Account(Name='Account 2');
        accountDataList.add(acc2);
        Account acc3 = new Account(Name='Account 3');
        accountDataList.add(acc3);
        Account acc4 = new Account(Name='Account 4');
        accountDataList.add(acc4);
        Account acc5 = new Account(Name='Account 5');
        accountDataList.add(acc5);
        Account acc6 = new Account(Name='Account 6');
        accountDataList.add(acc6);
        Account acc7 = new Account(Name='Account 7');
        accountDataList.add(acc7);
        insert accountDataList;

        List<Contact> contactDataList = new List<Contact>();
        Contact con1 = new Contact(LastName='Smith', FirstName='John', AccountId=acc1.Id);
        contactDataList.add(con1);
        Contact con2 = new Contact(LastName='Doe', FirstName='Jane', AccountId=acc1.Id);
        contactDataList.add(con2);
        Contact con3 = new Contact(LastName='Test', FirstName='NoPrefixSuffixContact', AccountId=acc1.Id);
        contactDataList.add(con3);
        Contact con4 = new Contact(LastName='Test', FirstName='NoPrefixSuffixSpouse', AccountId=acc1.Id);
        contactDataList.add(con4);
        Contact con5 = new Contact(LastName='Test', FirstName='NoPrefixSuffixPrimaryContact', AccountId=acc2.Id);
        contactDataList.add(con5);
        Contact con6 = new Contact(LastName='Test', FirstName='NoPrefixSuffixPrimarySpouse', AccountId=acc3.Id);
        contactDataList.add(con6);
        Contact con7 = new Contact(LastName='Test1', FirstName='NoPrefixSuffixContact', AccountId=acc1.Id);
        contactDataList.add(con7);
        Contact con8 = new Contact(LastName='Test1', FirstName='NoPrefixSuffixSpouse', AccountId=acc1.Id);
        contactDataList.add(con8);
        Contact con9 = new Contact(LastName='Test1', FirstName='NoPrefixSuffixPrimaryContact', AccountId=acc4.Id);
        contactDataList.add(con9);
        Contact con10 = new Contact(LastName='Test1', FirstName='NoPrefixSuffixPrimarySpouse', AccountId=acc5.Id);
        contactDataList.add(con10);
        Contact con11 = new Contact(LastName='Smith', FirstName='JohnPrimary', AccountId=acc6.Id);
        contactDataList.add(con11);
        Contact con12 = new Contact(LastName='Doe', FirstName='JanePrimary', AccountId=acc7.Id);
        contactDataList.add(con12);
        insert contactDataList;

        List<Name__c> nameDataList = new List<Name__c>();
        Name__c name1 = new Name__c(First_Name__c = 'John',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Smith',
							        Middle_Name__c = 'Jacob',
							        Prefix__c = 'Dr.',
							        Suffix__c = 'Jr',
							        Salutation__c = 'Mr',
                                    Contact__c=con1.Id);
        nameDataList.add(name1);
        Name__c name2 = new Name__c(First_Name__c = 'Jane',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Doe',
							        Middle_Name__c = '',
							        Prefix__c = 'Ms.',
							        Suffix__c = '',
							        Salutation__c = 'Ms',
                                    Contact__c=con2.Id);
        nameDataList.add(name2);
        Name__c name3 = new Name__c(First_Name__c = 'NoPrefixSuffixContact',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Test',
							        Middle_Name__c = '',
							        Prefix__c = '',
							        Suffix__c = '',
							        Salutation__c = '',
                                    Contact__c=con3.Id);
        nameDataList.add(name3);
        Name__c name4 = new Name__c(First_Name__c = 'NoPrefixSuffixSpouse',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Test',
							        Middle_Name__c = '',
							        Prefix__c = '',
							        Suffix__c = '',
							        Salutation__c = '',
                                    Contact__c=con4.Id);
        nameDataList.add(name4);
        Name__c name5 = new Name__c(First_Name__c = 'NoPrefixSuffixPrimaryContact',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Test',
							        Middle_Name__c = '',
							        Prefix__c = '',
							        Suffix__c = '',
							        Salutation__c = '',
                                    Contact__c=con5.Id);
        nameDataList.add(name5);
        Name__c name6 = new Name__c(First_Name__c = 'NoPrefixSuffixPrimarySpouse',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Test',
							        Middle_Name__c = '',
							        Prefix__c = '',
							        Suffix__c = '',
							        Salutation__c = '',
                                    Contact__c=con6.Id);
        nameDataList.add(name6);
        Name__c name7 = new Name__c(First_Name__c = 'NoPrefixSuffixContact',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Test1',
							        Middle_Name__c = '',
							        Prefix__c = '',
							        Suffix__c = '',
							        Salutation__c = '',
                                    Contact__c=con7.Id);
        nameDataList.add(name7);
        Name__c name8 = new Name__c(First_Name__c = 'NoPrefixSuffixSpouse',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Test1',
							        Middle_Name__c = '',
							        Prefix__c = '',
							        Suffix__c = '',
							        Salutation__c = '',
                                    Contact__c=con8.Id);
        nameDataList.add(name8);
        Name__c name9 = new Name__c(First_Name__c = 'NoPrefixSuffixPrimaryContact',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Test1',
							        Middle_Name__c = '',
							        Prefix__c = '',
							        Suffix__c = '',
							        Salutation__c = '',
                                    Contact__c=con9.Id);
        nameDataList.add(name9);
        Name__c name10 = new Name__c(First_Name__c = 'NoPrefixSuffixPrimarySpouse',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Test1',
							        Middle_Name__c = '',
							        Prefix__c = '',
							        Suffix__c = '',
							        Salutation__c = '',
                                    Contact__c=con10.Id);
        nameDataList.add(name10);
        Name__c name11 = new Name__c(First_Name__c = 'JohnPrimary',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Smith',
							        Middle_Name__c = 'Jacob',
							        Prefix__c = 'Dr.',
							        Suffix__c = 'Jr',
							        Salutation__c = 'Mr',
                                    Contact__c=con11.Id);
        nameDataList.add(name11);
        Name__c name12 = new Name__c(First_Name__c = 'JanePrimary',
							        Is_Primary__c = true,
							        Is_Active__c = true,
							        Last_Name__c = 'Doe',
							        Middle_Name__c = '',
							        Prefix__c = 'Ms.',
							        Suffix__c = '',
							        Salutation__c = 'Ms',
                                    Contact__c=con12.Id);
        nameDataList.add(name12);
        insert nameDataList;

        List<Account> accountsToUpdateList = new List<Account>();
        acc2.Ucinn_ascendv2__Primary_Contact__c = con5.id;
        accountsToUpdateList.add(acc2);
        acc3.Ucinn_ascendv2__Primary_Contact__c = con6.id;
        accountsToUpdateList.add(acc3);
        acc4.Ucinn_ascendv2__Primary_Contact__c = con9.id;
        accountsToUpdateList.add(acc4);
        acc5.Ucinn_ascendv2__Primary_Contact__c = con10.id;
        accountsToUpdateList.add(acc5);
        acc6.Ucinn_ascendv2__Primary_Contact__c = con11.id;
        accountsToUpdateList.add(acc6);
        acc7.Ucinn_ascendv2__Primary_Contact__c = con12.id;
        accountsToUpdateList.add(acc7);
        update accountsToUpdateList;

        List<Ucinn_ascendv2__Salutation_Correction_Mapping__c> salutationCorrectionMappingList = new List<Ucinn_ascendv2__Salutation_Correction_Mapping__c>();
        Ucinn_ascendv2__Salutation_Correction_Mapping__c scm1 = new Ucinn_ascendv2__Salutation_Correction_Mapping__c(Name='Doctor Suffix Replacement',
                                                                                                                     ucinn_ascendv2__Prefixes__c='Dr.',
                                                                                                                     ucinn_ascendv2__Prefix_Replaces_Prof_Designation__c=true,
                                                                                                                     ucinn_ascendv2__Professional_Designations__c='DC;DDS;MD;PhD');
        salutationCorrectionMappingList.add(scm1);
        Ucinn_ascendv2__Salutation_Correction_Mapping__c scm2 = new Ucinn_ascendv2__Salutation_Correction_Mapping__c(Name='Judge Suffix Replacement',
                                                                                                                     ucinn_ascendv2__Prefixes__c='Judge;The Honorable',
                                                                                                                     ucinn_ascendv2__Prefix_Replaces_Prof_Designation__c=true,
                                                                                                                     ucinn_ascendv2__Professional_Designations__c='JD;Esq.');
        salutationCorrectionMappingList.add(scm2);
        insert salutationCorrectionMappingList;
    }

    @isTest
    public static void testMethod1(){
        Contact con1, spouse1;
        Contact con2, spouse2;
        Contact con3, spouse3;
        Contact con4, spouse4;
        Contact con5, spouse5;
        Contact con6, spouse6;

        List<Contact> contactList = [SELECT Id, Name, Account.Ucinn_ascendv2__Primary_Contact__c, Ucinn_ascendv2__Is_Recognition_Name_Overridden__c, 
                                     Ucinn_ascendv2__Salutation_Preference__c, Ucinn_ascendv2__Recognition_Name__c,
                                     (SELECT First_Name__c, preferred_first_name__c, Is_Primary__c, Is_Active__c, Last_Name__c, Middle_Name__c, Prefix__c, Suffix__c, Salutation__c, Contact__c FROM Names__r)
                                    FROM Contact];
        for(Contact eachContact : contactList){
            if(eachContact.Name=='John Smith'){
                con1=eachContact;
            }
            else if(eachContact.Name=='Jane Doe'){
                spouse1=eachContact;
            }
            else if(eachContact.Name=='NoPrefixSuffixContact Test'){
                con2=eachContact;
            }
            else if(eachContact.Name=='NoPrefixSuffixSpouse Test'){
                spouse2=eachContact;
            }
            else if(eachContact.Name=='NoPrefixSuffixPrimaryContact Test'){
                con3=eachContact;
            }
            else if(eachContact.Name=='NoPrefixSuffixPrimarySpouse Test'){
                spouse3=eachContact;
            }
            else if(eachContact.Name=='NoPrefixSuffixContact Test1'){
                con4=eachContact;
            }
            else if(eachContact.Name=='NoPrefixSuffixSpouse Test1'){
                spouse4=eachContact;
            }
            else if(eachContact.Name=='NoPrefixSuffixPrimaryContact Test1'){
                con5=eachContact;
            }
            else if(eachContact.Name=='NoPrefixSuffixPrimarySpouse Test1'){
                spouse5=eachContact;
            }
            else if(eachContact.Name=='JohnPrimary Smith'){
                con6=eachContact;
            }
            else if(eachContact.Name=='JanePrimary Doe'){
                spouse6=eachContact;
            }
        }

        // Has a professional designation or last name IS NOT the same
        EngageSalutationHelper.ContactPair contactPair1 = new EngageSalutationHelper.ContactPair(con1, spouse1);
        EngageSalutationGenerator esg1 = new EngageSalutationGenerator(contactPair1);
        EngageSalutationHelper.ContactPair contactPair1a = esg1.generateNewSalutations();

        // no prefix, no suffix, same last name
        EngageSalutationHelper.ContactPair contactPair2 = new EngageSalutationHelper.ContactPair(con2, spouse2);
        EngageSalutationGenerator esg2 = new EngageSalutationGenerator(contactPair2);
        EngageSalutationHelper.ContactPair contactPair2a = esg2.generateNewSalutations();

        //no prefix, no suffix, same last name, contact is primary
        EngageSalutationHelper.ContactPair contactPair3 = new EngageSalutationHelper.ContactPair(con3, spouse2);
        EngageSalutationGenerator esg3 = new EngageSalutationGenerator(contactPair3);
        EngageSalutationHelper.ContactPair contactPair3a = esg3.generateNewSalutations();

        //no prefix, no suffix, same last name, spouse is primary
        EngageSalutationHelper.ContactPair contactPair4 = new EngageSalutationHelper.ContactPair(con2, spouse3);
        EngageSalutationGenerator esg4 = new EngageSalutationGenerator(contactPair4);
        EngageSalutationHelper.ContactPair contactPair4a = esg4.generateNewSalutations();
    
        // no prefix, no suffix, different last name
        EngageSalutationHelper.ContactPair contactPair5 = new EngageSalutationHelper.ContactPair(con4, spouse2);
        EngageSalutationGenerator esg5 = new EngageSalutationGenerator(contactPair5);
        EngageSalutationHelper.ContactPair contactPair5a = esg5.generateNewSalutations();

        //no prefix, no suffix, different last name, contact is primary
        EngageSalutationHelper.ContactPair contactPair6 = new EngageSalutationHelper.ContactPair(con5, spouse2);
        EngageSalutationGenerator esg6 = new EngageSalutationGenerator(contactPair6);
        EngageSalutationHelper.ContactPair contactPair6a = esg6.generateNewSalutations();

        //no prefix, no suffix, different last name, spouse is primary
        EngageSalutationHelper.ContactPair contactPair7 = new EngageSalutationHelper.ContactPair(con2, spouse5);
        EngageSalutationGenerator esg7 = new EngageSalutationGenerator(contactPair7);
        EngageSalutationHelper.ContactPair contactPair7a = esg7.generateNewSalutations();

        // Has a professional designation or last name IS NOT the same, contact is primary
        EngageSalutationHelper.ContactPair contactPair8 = new EngageSalutationHelper.ContactPair(con6, spouse1);
        EngageSalutationGenerator esg8 = new EngageSalutationGenerator(contactPair8);
        EngageSalutationHelper.ContactPair contactPair8a = esg8.generateNewSalutations();
    
        // Has a professional designation or last name IS NOT the same, spouse is primary
        EngageSalutationHelper.ContactPair contactPair9 = new EngageSalutationHelper.ContactPair(con1, spouse6);
        EngageSalutationGenerator esg9 = new EngageSalutationGenerator(contactPair9);
        EngageSalutationHelper.ContactPair contactPair9a = esg9.generateNewSalutations();
    }
}