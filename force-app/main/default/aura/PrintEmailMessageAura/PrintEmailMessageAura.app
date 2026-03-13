<!--
 - Created by tom on 27/11/2024.
 -->

<aura:application>
    <aura:attribute name="emailMessage" type="Object"/>
    <aura:attribute name="recordId" type="String"/>
    <aura:attribute name="isLoaded" type="Boolean" default="false"/>
    <aura:attribute name="emailMetadata" type="List"/>
    <aura:handler name="init" value="{!this}" action="{!c.doInit}"/>

    <force:recordData aura:id="recordLoader"
                      recordId="{!v.recordId}"
                      fields="Id,FromAddress,ToAddress,CcAddress,BccAddress,Subject,CreatedDate,HtmlBody"
                      targetFields="{!v.emailMessage}"
                      recordUpdated="{!c.handleRecordUpdated}"
    />

    <div class="no-print-area">
        <div class="buttons">
            <lightning:button
                    variant="brand"
                    label="Print"
                    onclick="{!c.handlePrintClick}"
                    class="slds-m-bottom_medium"/>
            <lightning:button
                    variant="brand"
                    label="Close"
                    onclick="{!c.handleCloseClick}"
                    class="slds-m-bottom_medium"/>
            </div>
    </div>

    <div class="print-area">

        <table class="email-metadata">
            <aura:iteration items="{!v.emailMetadata}" var="field">
                <tr>
                    <td class="meta-label">{!field.label}</td>
                    <td class="meta-value">{!field.value}</td>
                </tr>
            </aura:iteration>
        </table>

        <hr/>

        <div class="printable-email" aura:id="printArea">
            <!-- Email content will be injected here -->
        </div>
    </div>
</aura:application>