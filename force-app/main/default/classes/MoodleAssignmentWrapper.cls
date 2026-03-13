/**
 * @description       : Wrapper Class for Moodle Assignment Extension Data Items
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @last modified on  : 2021-07-02
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date           Author              Modification
 * 1.0   2021-07-02 - Angelo Rivera - Initial Creation
 * 2.0	 17-08-2025	- Sachin Shetty	- Added Constructor
**/

public with sharing class MoodleAssignmentWrapper {

    public Datetime newDueDate;
    
    // Default constructor
    public MoodleAssignmentWrapper() {
        this.newDueDate = null;
    }
}