# Demo: Async Apex Triggers and Change Data Capture for Opportunity Contact Roles

This application is a demo of using Change Data Capture and Async Apex Triggers to build a shadow Opportunity Contact Role table. This enables Roll-Up Summary Fields on the Opportunity object against the shadow table, offering near-real-time rollups of Opportunity Contact Role data.

Turn on Change Data Capture for `OpportunityContactRole` before trying the app. Make sure to add the Opportunity Roll-Up Summary Field to a page layout, or use queries like

    SELECT Id, Role__c, Opportunity__c, Contact__c, Opportunity_Contact_Role_Id__c, Opportunity__r.Count_Of_Opportunity_Contact_Roles__c 
    FROM Shadow_Opportunity_Contact_Role__c

to evaluate data.