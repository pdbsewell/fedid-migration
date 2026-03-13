/**
 * Created by trentdelaney on 2019-08-27.
 */

import {LightningElement, track, api} from 'lwc';
import searchOffering from '@salesforce/apex/CourseOfferingCC.searchCourseOffering';
import getApplicationACPs from "@salesforce/apex/CourseOfferingCC.getApplicationACPs";
import addACPs from "@salesforce/apex/CourseOfferingCC.addACPs";
import seedComponent from "@salesforce/apex/CourseOfferingCC.seedComponent";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class AcpToolkit extends LightningElement {
    //Values
    @track courseCode;
    @track courseName;
    @track attendanceMode;
    @track location;
    @track active = true;

    //Seed Data
    @track courseCodes;
    @track attendanceModes;
    @track courseNames;
    @track locations;

    @track tabId;

    //Loading spinner
    @track spinner = false;


    //Course offering listing
    @track acps;
    @track modalOpen;

    //Course Offering selections
    @track selectedCourseOfferings = [];
    @track options;
    @track courseArray = [];

    @track courseOfferings = [];

    //Application ID
    @api recordId;

    connectedCallback(){

        seedComponent().then(result => {
            this.options = result;
            console.log(result)

            //Set the options
            this.courseCodes = this.mapListToPicklist(result.Course_Code__c);
            this.courseNames = this.mapListToPicklist(result.Course_Title__c);
            this.attendanceModes = this.mapListToPicklist(result.Attendance_Mode__c);
            this.locations = this.mapListToPicklist(result.Location_Description__c);
        }).catch(err => {
            console.log(err);
        });

        getApplicationACPs({recordId: this.recordId}).then(result => {
            console.log("ACP Logging");
            console.log(result);
            this.acps = result;

        }).catch(err => {
            console.error(err);
        })
    }

    mapListToPicklist(list){
        return list.map(function(element) {
            return {value : element, label : element}
        })
    }

    searchCourseOffering(){

        let payload = {
            courseCode : this.courseCode,
            courseName : this.courseName,
            location : this.location,
            attendanceMode : this.modeOfAttendance
        };
        if(this.courseCode===undefined && this.courseName ==undefined){
            this.dispatchEvent(
                     new ShowToastEvent({
                         title: 'Course Code or Course Name Required',
                         message: 'Please enter either Course code or Course Name.',
                         variant: 'warning'
                     }),
            );
        }else{
            searchOffering({newSearch : JSON.stringify(payload)}).then(results => {
                        this.courseOfferings = results;
                    })
            .catch(err => {
                 console.log(err);
               })
        }
    }

    addCourseOffering(event){
        if(this.selectedCourseOfferings.indexOf(event.target.value) > -1){
            this.selectedCourseOfferings.splice(this.selectedCourseOfferings.indexOf(event.target.value), 1);
        }else{

            this.selectedCourseOfferings.push(event.target.value);
        }

    }

    addACPFromCourseOffering(){

      console.log('^^^^^^'+this.selectedCourseOfferings);
       this.spinner = true;
          addACPs({appId : this.recordId, selectedOfferings : JSON.stringify(this.selectedCourseOfferings)}).then(results => {
              console.log(results);
              this.spinner = false;
              this.dispatchEvent(
                 new ShowToastEvent({
                     title: 'ACP added',
                     message: 'The selected ACP(s) are successfully added to the Application.',
                     variant: 'success'
                 }),
              );
          }).catch(err => {
                  console.error(err);
                  this.spinner = false;
          })
    }

    closeModal(){
        this.modalOpen = false;
    }

    openModal(){
        this.modalOpen = true;
    }

    setCourseName(event){
        this.courseName = event.target.value;
        console.log('coursename=='+this.courseName);
    }

    setCourseCode(event){
        this.courseCode = event.target.value;
        console.log('course code=='+this.courseCode);
    }



    setAttendanceMode(event){
        console.log('mode ofattend=='+this.modeOfAttendance);
        this.modeOfAttendance = event.target.value;
    }

    setLocation(event){

        this.location = event.target.value;
        console.log('location=='+this.location);
    }
}