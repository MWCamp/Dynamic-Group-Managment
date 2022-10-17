/*******************************************************************************************************************************
 *  
 *  @Author         Mike Camp 
 *  @Date Created   08/22/2016
 *  @Description    Checks all users for group membership
 * 
 * system.schedule('Update Group Membership1', '0 0 * * * ?', new DGM_Update_BAT());
 * system.schedule('Update Group Membership2', '0 15 * * * ?', new DGM_Update_BAT());
 * system.schedule('Update Group Membership3', '0 30 * * * ?', new DGM_Update_BAT());
 * system.schedule('Update Group Membership4', '0 45 * * * ?', new DGM_Update_BAT());
 *******************************************************************************************************************************/
/*
CHANGE LOG
    08/22/2016 MCAMP     - initial version
    09/30/2016 MCAMP     - Added Profile Based Rules
*/
global class DGM_Update_BAT implements Database.Batchable<sObject>, Schedulable {
    
    global String query;
    
    global DGM_Update_BAT() {
        
    }
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new DGM_Update_BAT(), 100);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (query == null){
            query = DGMService.userQuery;
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        set<Id> updateList = new set<Id>();
        for(sObject thisUser : scope){
            updateList.add(thisUser.Id);
        }
        DGMService.updateGroups(updateList);
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
}