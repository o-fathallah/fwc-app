import { LightningElement, api } from 'lwc';
import runBatch from '@salesforce/apex/RunMockBatchController.runBatch';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RunMockBatchAction extends LightningElement {
    @api recordId; // Current Tournament__c record Id

    connectedCallback() {
        // As soon as the component loads, call the Apex method
        this.runBatchNow();
    }

    runBatchNow() {
        runBatch({ recordId: this.recordId })
            .then(result => {
                this.showToast('Batch Status', result, 'success');
                this.closeQuickAction();
            })
            .catch(error => {
                let message = error.body ? error.body.message : error.message;
                this.showToast('Batch Error', message, 'error');
                this.closeQuickAction();
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    closeQuickAction() {
        // This event closes the quick action modal
        this.dispatchEvent(new CustomEvent('close'));
    }
}
