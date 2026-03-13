public with sharing class PAG_PersonaModels {
    public class PersonaEvent {
        public String messageType;
        public String producer;
        public String version;
        public Subject subject;
        public Persona persona;
        public Datetime occurredAt;
        public Datetime recordedAt;
        public State state;
        public String enrichment;
        public Authority authority;
        public String sequence;
        public String idempotencyKey;
        public String correlationId;
    }
    public class Subject { public String sor; public String sorPersonId; public String moid; }
    public class Persona { public String type; public String subType; public String context; public String origin;}
    public class State { public String value; public Datetime startDate; public Datetime endDate; public String reason; public String ruleId; }
    public class Authority { public String owner; public Boolean authoritative; }

    public static Boolean isValidType(String t){ return new Set<String>{'Applicant','Student'}.contains(t); }
    public static Boolean isValidSubType(String s){ return s==null || new Set<String>{'cw','hdr','short', 'micro','nonaw','online'}.contains(s); }
    public static Boolean isValidApplicantState(String s){ return new Set<String>{'preApp','inProgress', 'offered','accepted','deferred','closed'}.contains(s); }
    public static Boolean isValidStudentState(String s){ return new Set<String>{'active','leave','suspended','ended'}.contains(s); }
}