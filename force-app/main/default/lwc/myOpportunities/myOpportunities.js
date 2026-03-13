import { LightningElement, track } from 'lwc';
//importing the Chart library from Static resources
import chartjs from '@salesforce/resourceUrl/ChartJS'; 
import getRelatedOpportunities from '@salesforce/apex/OpportunitiesCommonController.getRelatedOpportunities';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class MyOpportunities extends LightningElement {
    chartjsInitialized = false;
    chartConfiguration;
    renderedCallback(){
        if(!this.chartjsInitialized){
            this.loadScripts();
        }
    }
    loadScripts(){
        Promise.all([
            loadScript(this,chartjs)
        ]).then(() =>{
            this.chartjsInitialized = true;
            this.renderOnScreen();
        }).catch(error =>{
            this.dispatchEvent(
                new ShowToastEvent({
                    title : 'Error loading ChartJS',
                    message : error.message,
                    variant : 'error',
                }),
            );
        });
    }
    renderOnScreen(){
        if(this.chartjsInitialized) {
            const ctx = this.template.querySelector('canvas.barChart').getContext('2d'); 
            this.chart = new window.Chart(ctx, this.chartConfiguration);
        }
    }
    connectedCallback(){
        getRelatedOpportunities() 
            .then(result => {
                if(result){
                    let chartAmtData = []; 
                    let chartLabel = [];
                    let backgroundColor = [];
                    result.forEach(opp => {
                        chartAmtData.push(opp.data);
                        chartLabel.push(opp.labels);
                        backgroundColor.push(opp.backgroundColor);
                    });
                    this.chartConfiguration = {
                        type: 'bar',
                        data: {
                            datasets: [{
                                    label: '', 
                                    backgroundColor: backgroundColor,
                                    data: chartAmtData
                                }],
                            labels: chartLabel,
                        },
                        options: {
                            responsive: true,
                            legend: {
                                display: false
                            },
                            scales: {
                                    yAxes: [{
                                        ticks: {
                                            beginAtZero: true
                                        }
                                    }],
                                    xAxes: [{
                                        ticks: {
                                            autoSkip: false,
											maxRotation: 45,
                                            minRotation: 45
										}
                                    }]
                            }
                        },
                    };
                    this.renderOnScreen();
                }
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title : 'ERROR',
                        message : 'An Error has occurred',
                        variant : 'error',
                    }),
                )
                this.isLoading = false;
            });
    }
}