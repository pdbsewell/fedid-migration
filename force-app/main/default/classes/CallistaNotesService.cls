/**
 * @author       Jitender Padda
 * @date         Dec.2024
 * @description  Service class for Callista Notes
 *               Does callouts to Callista for Person / ACAI notes
 */
public with sharing class CallistaNotesService {
    public class CallistaNotesException extends Exception {
    }

    public static final String LOG_TAG = 'Callista Notes';

    public static final List<String> PUSH_PERSON_NOTE_TYPES = new List<String>{ 'INTPAYMENT' };
    public static final List<String> PUSH_ACAI_NOTE_TYPES = new List<String>{ 'STDY-GRNT' };

    public static final List<String> ASSESSMENT_ACAI_NOTE_TYPES = new List<String>{
        'STDY-GRNT',
        'SCHOLARSHP',
        'VTAC-IN-CR',
        'VTAC-RMRKS',
        'VTAC-IN-RM'
    };
    public static final List<String> ASSESSMENT_PERSON_NOTE_TYPES = new List<String>{
        'AUTHINFO',
        'CENTRAL',
        'CREDIT',
        'DOM-APPL',
        'ESOS',
        'FACULTY',
        'FEE-REFUND',
        'FEES UNIT',
        'INTPAYMENT',
        'MI-APPL',
        'QL-SUMMARY'
    };

    /**
     * @description does a GET request to the personNotes endpoint
     * @param       personId Callista Person Id
     * @return      PersonNote wrapper
     */
    public static PersonNote getCallistaPersonNotes(String personId) {
        HttpResponse response = new Http().send(createGETRequest(personId, 'personNotes'));

        PersonNote personNotesResult = new PersonNote();
        personNotesResult.notes = new List<Note>();

        if (response.getStatusCode() == 200) {
            personNotesResult = (PersonNote) System.JSON.deserialize(response.getBody(), PersonNote.class);
        } else
            throw new CallistaNotesException(response.getBody());

        return personNotesResult;
    }

    /**
     * @description does a POST request to the personNotes endpoint
     * @param       personId Callista Person Id
     * @param       requestBody json request for personNotes
     * @return      reference id from Callista
     */
    public static String postCallistaPersonNotes(String personId, String requestBody) {
        HttpResponse response = new Http().send(createPOSTRequest(personId, 'personNotes', requestBody));

        if (response.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) System.JSON.deserializeUntyped(response.getBody());
            return String.valueOf(responseMap.get('id'));
        } else
            throw new CallistaNotesException(response.getBody());
    }

    /**
     * @description does a GET request to the acaiNotes endpoint
     * @param       personId Callista Person Id
     * @return      ACAINote wrapper
     */
    public static ACAINote getCallistaACAINotes(String personId) {
        HttpResponse response = new Http().send(createGETRequest(personId, 'acaiNotes'));

        ACAINote acaiNotesResult = new ACAINote();
        acaiNotesResult.acaiNotes = new List<Note>();

        if (response.getStatusCode() == 200) {
            acaiNotesResult = (ACAINote) System.JSON.deserialize(response.getBody(), ACAINote.class);
        } else
            throw new CallistaNotesException(response.getBody());

        return acaiNotesResult;
    }

    /**
     * @description does a POST request to the acaiNotes endpoint
     * @param       personId Callista Person Id
     * @param       requestBody json request for acaiNotes
     * @return      reference id from Callista
     */
    public static String postCallistaACAINotes(String personId, String requestBody) {
        HttpResponse response = new Http().send(createPOSTRequest(personId, 'acaiNotes', requestBody));

        if (response.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) System.JSON.deserializeUntyped(response.getBody());
            return String.valueOf(responseMap.get('referenceNumber'));
        } else
            throw new CallistaNotesException(response.getBody());
    }

    /**
     * @description filters ACAI Notes based on the Callista ADM Unique key
     * @param  acaiNotesResult ACAINote wrapper
     * @param  acp             ACP to filter ACAI Notes for
     * @return                 filtered ACAI Notes for the ACP
     */
    public static ACAINote filterACAINotesForACP(ACAINote acaiNotesResult, Application_Course_Preference__c acp) {
        ACAINote newAcaiNotesResult = new ACAINote();
        newAcaiNotesResult.acaiNotes = new List<Note>();

        for (Note acaiNote : acaiNotesResult.acaiNotes) {
            if (acaiNote.admissionApplicationId == acp.Callista_Unique_Key_ADM__c) {
                newAcaiNotesResult.acaiNotes.add(acaiNote);
            }
        }
        return newAcaiNotesResult;
    }

    private static HTTPRequest createGETRequest(String personId, String urlSlug) {
        return createRequest(personId, 'GET', urlSlug);
    }

    private static HTTPRequest createPOSTRequest(String personId, String urlSlug, String requestBody) {
        HTTPRequest request = createRequest(personId, 'POST', urlSlug);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(requestBody);

        return request;
    }

    private static HTTPRequest createRequest(String personId, String method, String urlSlug) {
        HTTPRequest request = new HTTPRequest();
        request.setEndpoint('callout:SMSServices_Mix_API/la/student-services/v2/students/' + personId + '/' + urlSlug);
        request.setTimeout(1000 * 20);
        request.setHeader('client_id', '{!$Credential.UserName}');
        request.setHeader('client_secret', '{!$Credential.Password}');
        request.setMethod(method);

        return request;
    }

    public class PersonNote {
        public List<Note> notes;
    }

    public class ACAINote {
        public List<Note> acaiNotes;
    }

    public class Note implements Comparable {
        public String type;
        public String admissionApplicationId;
        public String note; // used only in personNotes POST
        public String noteType;
        public String typeDescription;
        public String updateBy;
        public String updateOn;
        public String text;
        public String portalApplicationID;
        public Decimal admissionApplNumber; // used only in acaiNotes POST
        public String courseCode; // used only in acaiNotes POST
        public Decimal sequenceNumber; // used only in acaiNotes POST

        public Integer compareTo(Object otherNoteObj) {
            Note otherNote = (Note) otherNoteObj;

            DateTime otherNoteUpdateOn = DateTime.valueOf(otherNote.updateOn.replace('T', ' '));
            DateTime thisNoteUpdateOn = DateTime.valueOf(this.updateOn.replace('T', ' '));

            // sort by desc
            if (otherNoteUpdateOn > thisNoteUpdateOn) {
                return 1;
            } else if (otherNoteUpdateOn < thisNoteUpdateOn) {
                return -1;
            } else
                return 0;
        }
    }
}