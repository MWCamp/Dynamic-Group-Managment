/*******************************************************************************************************************************
 *  
 *  @Author         Mike Camp 
 *  @Date Created   08/26/2016
 *  @Description    Extends the standard controller for the Dynamic Group Rule object to be used by the Dynamic Group Management
 * 
 *******************************************************************************************************************************/
/*
CHANGE LOG
	08/26/2016 MCAMP     - initial version
	09/30/2016 MCAMP     - Added Profile Based Rules
*/
public with sharing class DGM_Rule_EXT {

	public Map<ID,PermissionSet> permissionSetMap{get;set;}
	public Map<ID,Group> groupMap{get;set;}
	public Map<ID,Profile> profileMap{get;set;}
	public Map<ID, String> RTMap{get;set;}
	public Boolean showProfile{get;set;}
	public Boolean showProfileError{get;set;}
	public Boolean showPS{get;set;}
	public Boolean showPSError{get;set;}
	public Boolean showGeneralError{get;set;}
	public Boolean showRecordType{get;set;}
	
	public final Dynamic_Group_Rule__c DGRule;
	public ID startingRT;

	/********************************************************************************************************************/
	/* 
	* @Method       VF_PC_DGM_Admin_EXT (constructor)
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  gets the current record and gets the valid groups and permission sets from the DGM service
	* @param        ApexPages.StandardController stdController the standard controller for a Dynamic Group Rule
	* @return       Void
	*/
	public DGM_Rule_EXT(ApexPages.StandardController stdController) {
		showProfile = false;
		showProfileError = false;
		showGeneralError = false;
		showPS = false;
		showPSError = false;
		showRecordType = true;

		Map<String, String> parameters = System.currentPageReference().getParameters();
		RTMap = DGMService.getRecordTypeMap();
//RT Only = {RecordType=012d0000001YZWj, id=a01d000000l96gC, retURL=/a01d000000l96gC, sfdc.override=1}
//Edit {_CONFIRMATIONTOKEN=VmpFPSxNakF4TmkweE1DMHdNbFF4TkRvMU5EbzFOUzR6T0RSYSxNUkZlVlQ0TmsxNDhRc3QwNWZfeTAyLE1HSmpaV0pr, common.udd.actions.ActionsUtilORIG_URI=/a01d000000l96gC/e, id=a01d000000l96gC, retURL=/a01d000000l96gC, scontrolCaching=1, sfdc.override=1}
//New {RecordType=012d0000001YZWj, ent=01Id0000001clA7, retURL=/a01/o, save_new=1, sfdc.override=1}
		this.DGRule = (Dynamic_Group_Rule__c)stdController.getRecord();
		startingRT = DGRule.RecordTypeId;

		if(parameters.containsKey('RecordType')){
			DGRule.RecordTypeId = parameters.get('RecordType');
		}

		checkPageState();
		permissionSetMap = DGMService.getPermissionSetMap();
		groupMap = DGMService.getGroupMap();
		profileMap = DGMService.getProfileMap();
	}

	/********************************************************************************************************************/
	/* 
	* @Method       VF_PC_DGM_Admin_EXT (constructor)
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  gets the valid groups and permission sets from the DGM service
	* @param        void
	* @return       Void
	*/
	public DGM_Rule_EXT() {
		showProfile = false;
		showPS = false;
		showRecordType = true;

		permissionSetMap = DGMService.getPermissionSetMap();
		groupMap = DGMService.getGroupMap();
		profileMap = DGMService.getProfileMap();
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getRTOptions
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Gets the RecordTypes in for a selectOption list
	* @param        Void
	* @return       List<SelectOption> a select list of the permission sets
	*/
	public List<SelectOption> getRTOptions(){
		list<SelectOption> SOList = new list<SelectOption>();

		for (Id thisID: RTMap.keySet()) {
			if(RTMap.get(thisId) != 'Master'){
				SOList.add(new selectOption(thisID,RTMap.get(thisId)));
			}
		}
		SOList = SortOptionList(SOList);
		SOList.add(0,new selectOption('','Choose One'));
		return SOList;
	}
	/********************************************************************************************************************/
	/* 
	* @Method       getPSOptions
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Gets the permission sets in for a selectOption list
	* @param        Void
	* @return       List<SelectOption> a select list of the permission sets
	*/
	public List<SelectOption> getPSOptions(){
		list<SelectOption> SOList = new list<SelectOption>();
		PermissionSet thisObj = new PermissionSet();

		for (Id thisID: permissionSetMap.keySet()) {
			thisObj = permissionSetMap.get(thisId);
			SOList.add(new selectOption(thisObj.Id,thisObj.label));
		}
		SOList = SortOptionList(SOList);
		SOList.add(0,new selectOption('','Choose One'));
		return SOList;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getProfileSOptions
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Gets the permission sets in for a selectOption list
	* @param        Void
	* @return       List<SelectOption> a select list of the permission sets
	*/
	public List<SelectOption> getProfileOptions(){
		list<SelectOption> SOList = new list<SelectOption>();
		Profile thisObj = new Profile();

		for (Id thisID: ProfileMap.keySet()) {
			thisObj = ProfileMap.get(thisId);
			SOList.add(new selectOption(thisObj.Id,thisObj.Name));
		}
		SOList = SortOptionList(SOList);
		SOList.add(0,new selectOption('','Choose One'));
		return SOList;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getGroupOptions
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Gets the groups in for a selectOption list
	* @param        Void
	* @return       List<SelectOption> a select list of the permission sets
	*/
	public List<SelectOption> getGroupOptions(){
		list<SelectOption> SOList = new list<SelectOption>();
		Group thisObj = new Group();

		for (Id thisID: groupMap.keySet()) {
			thisObj = groupMap.get(thisId);
			SOList.add(new selectOption(thisObj.Id,thisObj.Name));
		}
		SOList = SortOptionList(SOList);
		SOList.add(0,new selectOption('','Choose One'));
		return SOList;
	}

	// ** Begin Page Actions ********************************************************************************
	/********************************************************************************************************************/
	/* 
	* @Method       onchangePS
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Updates the Permission Set Name based on the selected permission set
	* @param        Void
	* @return       PageReference this returns null
	*/
	public PageReference onchangePS() {
		//update PS Name
		if(String.isNotBlank(DGRule.Permission_Set_ID__c)) {
			DGRule.Permission_Set_Name__c = permissionSetMap.get(DGRule.Permission_Set_ID__c).Label;
		} else {
			DGRule.Permission_Set_Name__c = '';

		}
		return null;
	}
	/********************************************************************************************************************/
	/* 
	* @Method       onchangeRecordType
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Updates the Permission Set Name based on the selected permission set
	* @param        Void
	* @return       PageReference this returns null
	*/
	public PageReference onchangeRecordType() {
		checkPageState();
		return null;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       onchangePS
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Updates the Permission Set Name based on the selected permission set
	* @param        Void
	* @return       PageReference this returns null
	*/
	public PageReference onchangeProfile() {
		//update PS Name
		if(String.isNotBlank(DGRule.Profile_ID__c)) {
			DGRule.Profile_Name__c = profileMap.get(DGRule.Profile_ID__c).Name;
		} else {
			DGRule.Profile_Name__c = '';
		}
		return null;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       onchangeGroup
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Updates the Group Name based on the selected group set
	* @param        Void
	* @return       PageReference this returns null
	*/
	public PageReference onchangeGroup() {
		//update PS Name
		if(String.isNotBlank(DGRule.Group_ID__c)) {
			DGRule.Group_Name__c = groupMap.get(DGRule.Group_ID__c).name;
		} else {
			DGRule.Group_Name__c = '';

		}
		return null;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       doSave
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Give the ability to have Save
	*               
	* @param        Void
	* @return       
	*/
	public Pagereference doSave()
	{
		showPSError = false;
		showProfileError = false;
		showGeneralError = false;
		try{
			upsert DGRule;
		} catch(Exception e) {
			string fieldName = getExceptionField(e.getMessage());
System.debug('DEBUG: fieldname=' + fieldname);
			if(fieldName == 'Permission_Set_ID__c') {
				showPSError = true;
System.debug('DEBUG: showPSError=' + showPSError);
			} else if(fieldName == 'Profile_ID__c') {
				showProfileError = true;
System.debug('DEBUG: showProfileError=' + showProfileError);
			} else {
				showGeneralError = true;
System.debug('DEBUG: showGeneralError=' + showGeneralError);
			}
		}
System.debug('DEBUG: showProfileError=' + showProfileError);
System.debug('DEBUG: showPSError=' + showPSError);
System.debug('DEBUG: showGeneralError=' + showGeneralError);
		
		return null;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       doSaveAndNew
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Give the ability to have Save and New on a custom VF Page
	*               Based off of LaceySnr example http://stackoverflow.com/questions/8921414/how-to-implement-save-new-functionality-in-a-visualforce-page
	* @param        Void
	* @return       PageReference page to create a new record after saving current
	*/
	public Pagereference doSaveAndNew()
	{
		upsert DGRule;
		string NewDGRulePR = '/' + ('' + DGRule.get('Id')).subString(0, 3) + '/e?';
		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Info, NewDGRulePR));
		return new Pagereference(NewDGRulePR);
	}
	// ** End Page Actions *********************************************************************************

	// ** Begin Private Methods ****************************************************************************
	/********************************************************************************************************************/
	/* 
	* @Method       sortOptionList
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Sorting a list of SelectOptions by Label
	*               from: Jason Hartfield http://improveit360.blogspot.com/2010/09/implementing-quicksort-to-sort-list-of.html
	* @param        List<SelectOption> ListToSort a list of select options to sort
	* @return       Void
	*/
	private List<SelectOption> sortOptionList(List<SelectOption> ListToSort)
	{
		if(ListToSort == null || ListToSort.size() <= 1)
			return ListToSort;
			
		List<SelectOption> Less = new List<SelectOption>();
		List<SelectOption> Greater = new List<SelectOption>();
		integer pivot = ListToSort.size() / 2;
		  
		// save the pivot and remove it from the list
		SelectOption pivotValue = ListToSort[pivot];
		ListToSort.remove(pivot);
		
		for(SelectOption x : ListToSort)
		{
			if(x.getLabel() <= pivotValue.getLabel())
				Less.add(x);
			else if(x.getLabel() > pivotValue.getLabel()) Greater.add(x);   
		}
		List<SelectOption> returnList = new List<SelectOption> ();
		returnList.addAll(SortOptionList(Less));
		returnList.add(pivotValue);
		returnList.addAll(SortOptionList(Greater));
		return returnList; 
	}  

	/********************************************************************************************************************/
	/* 
	* @Method       checkPageState
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  
	*               
	* @param        
	* @return       Void
	*/
	private void checkPageState()
	{
		String recordTypeName = 'Master';
		if(DGRule.RecordTypeId != null){
			recordTypeName = RTMap.get(DGRule.RecordTypeId);
		}

		if(recordTypeName == 'Permission Set Based'){
				showPS = true;
				showProfile = false;
				showRecordType = false;
		} else if (recordTypeName == 'Profile Based') {
				showPS = false;
				showProfile = true;
				showRecordType = false;
		} else if (recordTypeName == 'Master') {
				showPS = false;
				showProfile = false;
				showRecordType = true;
		} else {
				//put error here
		}
		if(showRecordType == false && (startingRT == null||DGRule.Id == null)){
			showRecordType = true;
		}
	}  
	/********************************************************************************************************************/
	/* 
	* @Method       getExceptionField
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  
	*               
	* @param        string eMessage
	* @return       string
	*/
	private string getExceptionField(string eMessage)
	{
		string fieldName = eMessage.substringAfterLast('[').replace(']','');
		return fieldName;
	}
	// ** End Private Methods ******************************************************************************
}