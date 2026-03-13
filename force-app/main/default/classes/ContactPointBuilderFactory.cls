/**
 * @author Nick Guia
 * @date 07-09-2020
 * @group Person 360
 * @description responsible for building Contact Point records
 **/
public virtual class ContactPointBuilderFactory {

    protected Id contactId;
    protected SObject sObj;

    public ContactPointBuilderFactory(Id conId, SObject sObjRec) {
        this.contactId = conId;
        this.sObj = sObjRec;
    }

    public ContactPointBuilderFactory(SObject sObjRec) {
        this.sObj = sObjRec;
    }

    /**
    * @description generates a Builder instance of the Contact Point
    * @param contactId : Parent Contact of the Contact Point SObject
    * @param sObj : Contact Point SObject to be built
    * @return BaseContactPointBuilder 
    **/
    public BaseContactPointBuilder createContactPoint() {
        BaseContactPointBuilder builder;
        switch on this.sObj {
            when Address__c a {
                builder = new AddressContactPointBuilder(this.contactId);
            }
            when Email__c e {
                builder = new EmailContactPointBuilder(this.contactId);
            }
            when Phone__c p {
                builder = new PhoneContactPointBuilder(this.contactId);
            }
            when Social__c s {
                builder = new SocialContactPointBuilder(this.contactId);
            }
            when Name__c  n {
                builder = new NameContactPointBuilder(this.contactId);
            }
            when else {
                System.debug(LoggingLevel.ERROR, 'Unsupported SObjectType for Contact Point Builder : ' + sObj);
            }
        }
        return builder;
    }
    
    /**
     * @description : abstract class for Contact Point Builders
     */
    public abstract class BaseContactPointBuilder {
        protected SObject contactPoint;

        public SObject getContactPoint() {
            return this.contactPoint;
        }
    }

    /**
     * @description Builder class for Address Contact Point
     */
    public class AddressContactPointBuilder extends BaseContactPointBuilder {

        private AddressContactPointBuilder(Id contactId) {
            this.contactPoint = new Address__c(Contact__c = contactId);
        }

        //start building

        public AddressContactPointBuilder withClassification(String attr) {
            this.contactPoint.put('Classification__c', attr);
            return this;
        }

        public AddressContactPointBuilder withStreetName(String attr) {
            this.contactPoint.put('Street_Name__c', attr);
            return this;
        }

        public AddressContactPointBuilder withCity(String attr) {
            this.contactPoint.put('City__c', attr);
            return this;
        }

        public AddressContactPointBuilder withCountry(String attr) {
            this.contactPoint.put('Country2__c', attr);
            return this;
        }

        public AddressContactPointBuilder withState(String attr) {
            this.contactPoint.put('State__c', attr);
            return this;
        }

        public AddressContactPointBuilder withPostCode(String attr) {
            this.contactPoint.put('Post_code__c', attr);
            return this;
        }

        public AddressContactPointBuilder withType(String attr) {
            this.contactPoint.put('Type__c', attr);
            return this;
        }

        public AddressContactPointBuilder withChannel(Id attr) {
            this.contactPoint.put('Channel__c', attr);
            return this;
        }

        public AddressContactPointBuilder withSource(String attr) {
            this.contactPoint.put('Source__c', attr);
            return this;
        }

        public void buildHash() {
            new AddressTriggerHandler.PopulateHash().process(this.contactPoint);
        }
    }

    /**
     * @description Builder class for Email Contact Point
     */
    public class EmailContactPointBuilder extends BaseContactPointBuilder {

        private EmailContactPointBuilder(Id contactId) {
            this.contactPoint = new Email__c(Contact__c = contactId);
        }

        //start building

        public EmailContactPointBuilder withClassification(String attr) {
            this.contactPoint.put('Classification__c', attr);
            return this;
        }

        public EmailContactPointBuilder withEmailId(String attr) {
            this.contactPoint.put('Name', attr);
            return this;
        }

        public EmailContactPointBuilder withChannel(Id attr) {
            this.contactPoint.put('Channel__c', attr);
            return this;
        }

        public EmailContactPointBuilder withSource(String attr) {
            this.contactPoint.put('Source__c', attr);
            return this;
        }

        public void buildHash() {
            new EmailTriggerHandler.PopulateHash().process(this.contactPoint);
        }
    }

    /**
     * @description Builder class for Phone Contact Point
     */
    public class PhoneContactPointBuilder extends BaseContactPointBuilder {

        private PhoneContactPointBuilder(Id contactId) {
            this.contactPoint = new Phone__c(Contact__c = contactId);
        }

        //start building

        public PhoneContactPointBuilder withClassification(String attr) {
            this.contactPoint.put('Classification__c', attr);
            return this;
        }

        public PhoneContactPointBuilder withPhoneNumber(String attr) {
            this.contactPoint.put('Name', attr);
            return this;
        }

        public PhoneContactPointBuilder withType(String attr) {
            this.contactPoint.put('Type__c', attr);
            return this;
        }

        public PhoneContactPointBuilder withChannel(Id attr) {
            this.contactPoint.put('Channel__c', attr);
            return this;
        }

        public PhoneContactPointBuilder withSource(String attr) {
            this.contactPoint.put('Source__c', attr);
            return this;
        }

        public void buildHash() {
            new PhoneTriggerHandler.PopulateHash().process(this.contactPoint);
        }
    }

    /**
     * @description Builder class for Social Contact Point
     */
    public class SocialContactPointBuilder extends BaseContactPointBuilder {

        private SocialContactPointBuilder(Id contactId) {
            this.contactPoint = new Social__c(Contact__c = contactId);
        }

        //start building

        public SocialContactPointBuilder withClassification(String attr) {
            this.contactPoint.put('Classification__c', attr);
            return this;
        }

        public SocialContactPointBuilder withName(String attr) {
            this.contactPoint.put('Name', attr);
            return this;
        }

        public SocialContactPointBuilder withType(String attr) {
            this.contactPoint.put('Type__c', attr);
            return this;
        }

        public SocialContactPointBuilder withUrl(String attr) {
            this.contactPoint.put('Url__c', attr);
            return this;
        }

        public SocialContactPointBuilder withSource(String attr) {
            this.contactPoint.put('Source__c', attr);
            return this;
        }

        public void buildHash() {
            new SocialTriggerHandler.PopulateHash().process(this.contactPoint);
        }
    }

    /**
     * @description Builder class for Name Contact Point
     */
    public class NameContactPointBuilder extends BaseContactPointBuilder {

        private NameContactPointBuilder(Id contactId) {
            this.contactPoint = new Name__c(Contact__c = contactId);
        }

        //start building

        public NameContactPointBuilder withSalutation(String attr) {
            this.contactPoint.put('Salutation__c', attr);
            return this;
        }

        public NameContactPointBuilder withName(String firstName, String middleName, String lastName) {
            this.contactPoint.put('First_Name__c', firstName);
            this.contactPoint.put('Middle_Name__c', middleName);
            this.contactPoint.put('Last_Name__c', lastName);
            return this;
        }

        public NameContactPointBuilder withName(String firstName, String lastName) {
            this.contactPoint.put('First_Name__c', firstName);
            this.contactPoint.put('Last_Name__c', lastName);
            return this;
        }

        public NameContactPointBuilder withSuffix(String attr) {
            this.contactPoint.put('Suffix__c', attr);
            return this;
        }

        public NameContactPointBuilder withType(String attr) {
            this.contactPoint.put('Type__c', attr);
            return this;
        }

        public NameContactPointBuilder withSource(String attr) {
            this.contactPoint.put('Source__c', attr);
            return this;
        }

        public void buildHash() {
            new NameTriggerHandler.PopulateHash().process(this.contactPoint);
        }
    }
}