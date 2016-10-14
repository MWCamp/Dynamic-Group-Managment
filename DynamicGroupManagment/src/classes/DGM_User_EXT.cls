/*******************************************************************************************************************************
 *  
 *  @Author         Mike Camp 
 *  @Date Created   08/26/2016
 *  @Description    Extends the standard controller for the User standard object to be used by the Dynamic Group Management
 * 
 *******************************************************************************************************************************/
/*
CHANGE LOG
    08/26/2016 MCAMP     - initial version
	09/30/2016 MCAMP     - Added Profile Based Rules
*/
public without sharing class DGM_User_EXT {
    private final user myUser;

    /********************************************************************************************************************/
    /* 
    * @Method       VF_PC_User_DGM_EXT (constructor)
    * @Author       MCAMP
    * @date         08/26/2016
    * @description  gets the current users record
    * @param        ApexPages.StandardController stdController the standard controller for a User
    * @return       Void
    */
    public DGM_User_EXT(ApexPages.StandardController stdController) {
        this.myUser = (User)stdController.getRecord();
    }
    /********************************************************************************************************************/
    /* 
    * @Method       VF_PC_User_DGM_EXT (constructor)
    * @Author       MCAMP
    * @date         08/26/2016
    * @description  
    * @param        void
    * @return       Void
    */
    public DGM_User_EXT() {
    }

    // ** Begin Page Actions ********************************************************************************
    /********************************************************************************************************************/
    /* 
    * @Method       updateGroups
    * @Author       MCAMP
    * @date         08/26/2016
    * @description  Used to manage users groupmembership based on permisiionsets
    * @param        void
    * @return       Void
    */
    public void updateGroups() {
        DGMService.updateGroups(myUser.Id);
    }
    // ** End Page Actions *********************************************************************************

    // ** Begin Private Methods ****************************************************************************
    // ** End Private Methods ******************************************************************************
}