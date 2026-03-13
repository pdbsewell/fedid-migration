/**
 * @author       Sravani Naramsetti
 * @date         Sept.2024
 * @description  Checks if the tap is enabled for the Course or not
 */
public class AssessmentTapService {
    /**
     * @description     Get TapValue for the given course
     * @author          Sravani Naramsetti | Sept.2024
     * @param           flowInputs
     **/
    public static Boolean getTapValue(Map<String, Object> flowInputs) {
        Feature_Switch__c fs = Feature_Switch__c.getInstance();

        Boolean isTapEnabled = fs.Assessment_Tap_Default__c;

        if (fs.Assessment_Tap_Controller__c) {
            Flow.Interview.AL_Assessment_Tap flow = new Flow.Interview.AL_Assessment_Tap(flowInputs);
            flow.start();

            isTapEnabled = (Boolean) flow.getvariableValue('TapEnabled');
        }
        return isTapEnabled;
    }
}