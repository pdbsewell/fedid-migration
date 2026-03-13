/**
 * @author : [Babyshark]
 * @description : Test Data Factory for all the necessary objecr creation related to Abroad Outbound
 * @group : Abroad Outbound
 * @date : 16/05/2024
 * @rev
 * 
 */ 

@IsTest
public with sharing class AOTestDataFactory {
    /** BEGIN Program Creation */
    public static AO_Program__c createProgram(boolean doInsert){
        AO_Program__c objP = new AO_Program__c(
            Name='Global Study Test 01',
            AO_Description__c = 'Global study tours',
            AO_Form_Deadline_Date__c = Date.Today().addDays(5),
            AO_Program_Location__c ='Malaysia',
            AO_Program_Type__c = 'Global Study Tours (GST)',
            AO_Program_Year__c = String.valueOf(Date.Today().year()),
            End_Date__c = Date.Today().addDays(7),
            Start_Date__c = Date.Today(),
            Terms__c = 'Sem 1 & Sem 2'
        );
        return createProgram(objP, doInsert);
    }
    public static AO_Program__c createProgram(AO_Program__c objP, boolean doInsert){
        if(doInsert){
            insert objP;
        }
        return objP;
    }
    /** END Program Creation */

    /** BEGIN Form Creation */
    public static AO_Form__c createForm(boolean doInsert){
        AO_Form__c objF = new AO_Form__c(
            Name='Form Test 01',
            AO_Form_Display_Name__c = 'Form Test 01',
            AO_Form_Description__c = 'test Description',
            AO_Active__c = true,
            Columns__c = 1
        );
        return createForm(objF, doInsert);
    }

    public static AO_Form__c createForm(AO_Form__c objForm, boolean doInsert){
        if(doInsert){
            insert objForm;
        }
        return objForm;
    }
    /** END Form Creation */

    /** BEGIN Form Creation */
    public static void createFormElement(AO_Form__c testForm){
        // Create Element Definitions
        AO_Question_Library__c qlib01 = new AO_Question_Library__c(
            Name = 'Test Text Question',
            AO_Type__c = 'Text',
            AO_Default_Value__c = 'Default Value',
            AO_Help_Text__c = 'Help Text',
            AO_Question__c = 'Enter Your Text Answer',
            AO_Prefill_Value_Object__c = 'Contact',
            AO_Prefill_Value_Field__c = 'Preferred_Name__c'
        );
        AO_Question_Library__c qlib02 = new AO_Question_Library__c(
            Name = 'Test Number Question',
            AO_Type__c = 'Number',
            AO_Default_Value__c = '2',
            AO_Help_Text__c = 'Help Text',
            AO_Question__c = 'Enter Your Number Answer'
        );
        AO_Question_Library__c qlib03 = new AO_Question_Library__c(
            Name = 'Test Picklist Question',
            AO_Type__c = 'Picklist',
            AO_Default_Value__c = '3',
            AO_Help_Text__c = 'Help Text',
            AO_Picklist_Values__c = 'Test 1 \n Test 2',
            AO_Question__c = 'Enter Your Picklist Answer'
        );
        insert new AO_Question_Library__c[] {qlib01, qlib02, qlib03};

        // Create Form Elements
        AO_Form_Element__c elemSection = new AO_Form_Element__c(
            AO_Type__c = 'Section',
            Label__c = 'Section #1',
            Form__c = testForm.Id,
            Section_Columns__c = 2
        );
        insert elemSection;
        AO_Form_Element__c elem01 = new AO_Form_Element__c(
            AO_Type__c = 'Data',
            Form__c = testForm.Id,
            Parent_Element__c = elemSection.Id,
            Element_Definition__c = qlib01.Id
        );
        AO_Form_Element__c elemSpacer = new AO_Form_Element__c(
            AO_Type__c = 'Spacer',
            Form__c = testForm.Id,
            Parent_Element__c = elemSection.Id
        );
        // elem02 has a label override
        AO_Form_Element__c elem02 = new AO_Form_Element__c(
            Form__c = testForm.Id,
            AO_Type__c = 'Data',
            Label__c = 'FE Defined Label',
            Element_Definition__c = qlib02.Id
        );
        // elem03 has a label override
        AO_Form_Element__c elem03 = new AO_Form_Element__c(
            Form__c = testForm.Id,
            AO_Type__c = 'Data',
            Label__c = 'FE Defined Label',
            Element_Definition__c = qlib03.Id
        );
        insert new AO_Form_Element__c[] {elem01, elemSpacer, elem02, elem03};
        
    }

    /** END Form Creation */

    /** BEGIN Form Program Map Creation */
    public static AO_Program_Form_Map__c createFormMap(Id formId, Id programId, String seq, boolean doInsert){
        AO_Program_Form_Map__c formMap = new AO_Program_Form_Map__c(
            AO_Form__c = formId, 
            AO_Program__c = programId,
            AO_Sequence__c = seq != null ? seq : 'Primary',
            AO_Enable_On_Condition__c = seq == 'Subsequent' ?'Successful':null
        );
        if(doInsert){
            insert formMap;
        }
        return formMap;
    }

    /** END Form Program Map Creation */

    /**BEGIN Setup Program Forms */
    public static void setupForms(){
        AO_Program__c program = createProgram(true);
        
        AO_Form__c form = createForm(true);
        //AO_Program_Form_Map__c formMap = createFormMap(form.Id, program.Id, 'Primary', true);
        createFormMap(form.Id, program.Id, 'Primary', true);

        AO_Form__c subForm = new AO_Form__c(Name='Sub Form', AO_Form_Display_Name__c = 'Sub Form Test 01',
        AO_Form_Description__c = 'test Description 2',
        AO_Active__c = true,
        Columns__c = 1);
        AO_Form__c form2 = createForm(subForm, true);
        

       	//AO_Program_Form_Map__c formMap2 = createFormMap(form2.Id, program.Id, 'Subsequent', true);
       	createFormMap(form2.Id, program.Id, 'Subsequent', true);
        createFormElement(form);
    }
    /**END Setup Program Forms */

    /**BEGIN Question Library Creation*/
    public static AO_Question_Library__c createQuestionLibrary(boolean doInsert){
        AO_Question_Library__c qlib01 = new AO_Question_Library__c(
            Name = 'Test Text Question',
            AO_Type__c = 'Text',
            AO_Default_Value__c = 'Default Value',
            AO_Help_Text__c = 'Help Text',
            AO_Question__c = 'Enter Your Text Answer',
            AO_Prefill_Value_Object__c = 'Contact',
            AO_Prefill_Value_Field__c = 'Preferred_Name__c'
        );
        return createQuestionLibrary(qlib01, doInsert);
    }    
    public static AO_Question_Library__c createQuestionLibrary(AO_Question_Library__c objQ, boolean doInsert){
        if(doInsert){
            insert objQ;
        }
        return objQ;
    }
    /** END Question Library Creation */

}