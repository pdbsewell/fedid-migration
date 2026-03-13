/**
 * @author Tom Gangemi
 * @date Feb.2023
 *
 * @revision
 *     2023-02 - Tom Gangemi - SA-2115 - DoI Owner Mapping
 *     2023-03 - Tom Gangemi - SA-2148 - Use Authcate and return email
 **/
public with sharing class DOIServices {

    @InvocableMethod(label='DoI - Get Subject Matter Owner' description='Returns the ID of a queue or User for given Subject Matter')
    public static List<Result> getOwnerForSubjectMatter(List<String> subjectMatters) {
        Map<String,DoI_Subject_Owner_Mapping__c> mappingBySubject = new Map<String,DoI_Subject_Owner_Mapping__c>();
        DoI_Subject_Owner_Mapping__c[] mappings = [
            SELECT Subject_Matter__c, Queue_Name__c, Staff_Authcate__c FROM DoI_Subject_Owner_Mapping__c
            WHERE Subject_Matter__c IN :subjectMatters
        ];
        for(DoI_Subject_Owner_Mapping__c som :mappings) {
            mappingBySubject.put(som.Subject_Matter__c.toLowerCase(), som);
        }

        // create collections for each type of owner
        Set<String> authcates = new Set<String>();
        Set<String> queueNames = new Set<String>();
        for(String sm :subjectMatters) {
            DoI_Subject_Owner_Mapping__c m = mappingBySubject.get(sm.toLowerCase());

            if(String.isNotBlank(m.Staff_Authcate__c))
                authcates.add(m.Staff_Authcate__c);
            else if(String.isNotBlank(m.Queue_Name__c))
                queueNames.add(m.Queue_Name__c);

        }

        // collect User by FederationIdentifier
        Map<String,User> usersByAuthcate = new Map<String,User>();
        if(authcates.size() > 0) {
            for(User u :[SELECT Email, FederationIdentifier FROM User WHERE FederationIdentifier IN :authcates]) {
                usersByAuthcate.put(u.FederationIdentifier.toLowerCase(), u);
            }
        }

        // collect Queue by DeveloperName
        Map<String,Group> queuesByName = new Map<String,Group>();
        if(queueNames.size() > 0) {
            for(Group q :[SELECT Email, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueNames]) {
                queuesByName.put(q.DeveloperName.toLowerCase(), q);
            }
        }

        // match subject matters with owner IDs and create return data
        Result[] results = new Result[0];
        for(String sm :subjectMatters) {
            Result r = new Result();

            DoI_Subject_Owner_Mapping__c mapping = mappingBySubject.get(sm.toLowerCase());

            if(String.isNotBlank(mapping.Staff_Authcate__c)) {
                User u = usersByAuthcate.get(mapping.Staff_Authcate__c.toLowerCase());
                r.ownerId = u.Id;
                r.ownerEmail = u.Email;
                r.ownerName = mapping.Staff_Authcate__c;
            } else if(String.isNotBlank(mapping.Queue_Name__c)) {
                Group g = queuesByName.get(mapping.Queue_Name__c.toLowerCase());
                r.ownerId = g.Id;
                r.ownerEmail = g.Email;
                r.ownerName = mapping.Queue_Name__c;
            }

            results.add(r);
        }
        return results;
    }

    public class Result {
        @InvocableVariable(label='Id of Owner' required=true)
        public Id ownerId;
        @InvocableVariable(label='Name of Owner' required=true)
        public String ownerName;
        @InvocableVariable(label='Email of Owner')
        public String ownerEmail;
    }
}