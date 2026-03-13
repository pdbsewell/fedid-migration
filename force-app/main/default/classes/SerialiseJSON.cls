public class SerialiseJSON {
    
    @InvocableMethod(label='Convert ackAPS event to string' category='Text')
    public static List<String> convertRecord (List<ackAPS__e> aEvent) {
        List<String> cr = new list<String>();
        cr.add (json.serializePretty (aEvent[0]));
        return cr;
    }
}