/**
 * @author smen0015
 * @date 21 Sep 2019 at 11:39:40 am
 * @group Integration
 * @revision Trent De Laney - 29/11/2019 - Updated class names to be single rather than plural
 * @description Captures the ACP Response from the callout
 */
public class ObdACPResponse {

    public List<Application> applications{get;set;}

    public class Application {
        public List<CoursePreference> coursePreferences;
        public Integer admissionApplNumber;
    }
    public class CoursePreference {
        public List<CoursePreferenceInstance> coursePreferenceInstances;
        public String courseCode;
    }

    public class CoursePreferenceInstance {
        public Integer sequenceNumber;
    }
}