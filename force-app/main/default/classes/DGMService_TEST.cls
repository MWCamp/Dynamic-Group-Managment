/*******************************************************************************************************************************
 *  
 *  @Author         Mike Camp 
 *  @Date Created   08/26/2016
 *  @Description    Test Class for Dynamic Group Managment
 *  @Covers         DGMService, DGM_Update_BAT, DGM_User_CONT_EXT, DGM_Rule_EXT
 * 
 *******************************************************************************************************************************/
/*
CHANGE LOG
	08/26/2016 MCAMP     - initial version
*/
// Add testing for Profile based rules
@isTest
public class DGMService_TEST {

	//private static list<String> DGMTestPS = new list<String>{'DGM_Test_PS1','DGM_Test_PS2','DGM_Test_PS3'};
	private static list<Dynamic_Group_Rule__c> DGMRules = new list<Dynamic_Group_Rule__c>();
	private static list<user> UserList = new list<user>();
	private static list<PermissionSet> PSList = new list<PermissionSet>();
	private static list<Group> groupList = new list<Group>();
	private static Map<ID, String> RTMap = DGMService.getRecordTypeMap();

	/********************************************************************************************************************/
	/* 
	* @Method       testSVC
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Tests SVC_DGMService
	* @param        Void
	* @return       Void
	*/
	static testmethod void testSVC() {
		prepRules();
		UserList = prepUsers(3);
		addPSToUser(0,0);
		addPSToUser(1,0);
		addPSToUser(1,1);
		addPSToUser(2,1);
		addPSToUser(2,2);
		list<GroupMember> preUser2Groups = [Select Id, UserOrGroupId, GroupId From GroupMember where UserOrGroupId = :userList.get(2).Id];
		Test.startTest();
			DGMService.updateGroups(userList.get(0).Id);
			list<GroupMember> user0Groups = [Select Id, UserOrGroupId, GroupId From GroupMember where UserOrGroupId = :userList.get(0).Id];
			removePSfromUser(0,0);
			DGMService.updateGroups();
			list<GroupMember> user0Groups2 = [Select Id, UserOrGroupId, GroupId From GroupMember where UserOrGroupId = :userList.get(0).Id];
			list<GroupMember> user1Groups = [Select Id, UserOrGroupId, GroupId From GroupMember where UserOrGroupId = :userList.get(1).Id];
			list<GroupMember> user2Groups = [Select Id, UserOrGroupId, GroupId From GroupMember where UserOrGroupId = :userList.get(2).Id];
			removePSfromUser(1,1);
			removePSfromUser(2,1);
			removePSfromUser(2,2);
			DGMService.updateGroups();
		Test.stopTest();
		list<GroupMember> user1Groups2 = [Select Id, UserOrGroupId, GroupId From GroupMember where UserOrGroupId = :userList.get(1).Id];
		list<GroupMember> user2Groups2 = [Select Id, UserOrGroupId, GroupId From GroupMember where UserOrGroupId = :userList.get(2).Id];

		// User 0 
		System.assertEquals(1,user0Groups.size(),'SVC:User0: Did not set only one group member');
		System.assertEquals(groupList.get(0).Id,user0Groups.get(0).GroupId,'SVC:User0: User did not get set corectly in group membership');

		System.assertEquals(0,user0Groups2.size(),'SVC:User0: Did not get removed from groups');

		// User 1 
		System.assertEquals(2,user1Groups.size(),'SVC:User1: Did not set two one group member');
		List<Id> user1GroupIds = new List<Id> {groupList.get(0).Id,groupList.get(1).Id};
		System.assert(groupsCorrect(user1Groups, user1GroupIds),'SVC:User1: User did not get set corectly in group membership');

		System.assertEquals(1,user1Groups2.size(),'SVC:User1: Group did not get removed');
		List<Id> user1GroupIds2 = new List<Id> {groupList.get(0).Id};
		System.assert(groupsCorrect(user1Groups2, user1GroupIds2),'SVC:User1: Correct group did not remain');

		// User 2 
		System.assertEquals(3,user2Groups.size(),'SVC:User2: Did not set threee group member');
		List<Id> user2GroupIds = new List<Id> {groupList.get(0).Id,groupList.get(1).Id,groupList.get(2).Id};
		System.assert(groupsCorrect(user2Groups, user2GroupIds),'SVC:User2: User did not get corect group memberships');

		System.assertEquals(1,user2Groups2.size(),'SVC:User2: Groups did not get removed');
		List<Id> user2GroupIds2 = new List<Id> {groupList.get(2).Id};
		System.assert(groupsCorrect(user2Groups2, user2GroupIds2),'SVC:User2: The correct group did not remain');
	}

	/********************************************************************************************************************/
	/* 
	* @Method       testBatch
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Tests DGM_Update_BAT
	* @param        Void
	* @return       Void
	*/
	static testmethod void testBatch() {
		prepRules();
		UserList = prepUsers(1);
		addPSToUser(0,0);
		Test.startTest();
			DGM_Update_BAT tested = new DGM_Update_BAT();
			Database.BatchableContext ctx = null;
			String preStartQuery = tested.query;
			tested.start(ctx);
			String startQuery = tested.query;
			list<user> thisUserList = database.query(tested.query);
			tested.execute(ctx, thisUserList);
			tested.finish(ctx);
		Test.stopTest();
		System.assertEquals(null, preStartQuery, 'Bat: PreStart Query is not null');
		System.assertEquals(DGMService.userQuery, StartQuery, 'Bat: Start Query did not get set to userQuery in SVC_DGMService');
		list<GroupMember> user0Groups = [Select Id, UserOrGroupId, GroupId From GroupMember where GroupId in :groupList];
		System.assertEquals(1,user0Groups.size(),'Bat:user0: Did not set only one group member');
		System.assertEquals(userList.get(0).Id,user0Groups.get(0).UserOrGroupId,'Bat:user0: User did not get set corectly in group membership');
		System.assertEquals(groupList.get(0).Id,user0Groups.get(0).GroupId,'Bat:user0: User did not get set corectly in group membership');
	}

	/********************************************************************************************************************/
	/* 
	* @Method       testUserDGMExtension
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Tests DGM_User_CONT_EXT
	* @param        Void
	* @return       Void
	*/
	static testmethod void testUserDGMExtension() {
		prepRules();
		UserList = prepUsers(4);
		addPSToUser(0,0);

		//get the page
		PageReference pageRef = Page.DGM_User_Update;
		//Set as current page
		Test.setCurrentPage(pageRef);    
		Test.startTest();
			// test empty constructor
			ApexPages.StandardController sc = new ApexPages.StandardController(UserList.get(0));
			DGM_User_EXT ext = new DGM_User_EXT();
			ext = new DGM_User_EXT(sc);
			ext.updateGroups();
		Test.stopTest();
		list<GroupMember> user0Groups = [Select Id, UserOrGroupId, GroupId From GroupMember where GroupId in :groupList];
		System.assertEquals(1,user0Groups.size(),'UserDGMEXT:user0: Did not set only one group member');
		System.assertEquals(userList.get(0).Id,user0Groups.get(0).UserOrGroupId,'UserDGMEXT:user0: User did not get set corectly in group membership');
		System.assertEquals(groupList.get(0).Id,user0Groups.get(0).GroupId,'UserDGMEXT:user0: User did not get set corectly in group membership');
	}
	
	/********************************************************************************************************************/
	/* 
	* @Method       testDGREditExtension
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Tests DGM_Rule_EXT
	* @param        Void
	* @return       Void
	*/
	static testmethod void testDGREditExtension() {
		prepRules();

		//get the page
		PageReference pageRef = Page.DGM_Rule_Edit
;
		//Set as current page
		Test.setCurrentPage(pageRef);    
		Test.startTest();
			// test empty constructor
			ApexPages.StandardController sc = new ApexPages.StandardController(DGMRules.get(0));
			DGM_Rule_EXT ext = new DGM_Rule_EXT();
			ext = new DGM_Rule_EXT(sc);
			// get select Options
			List<SelectOption> groupOptions = ext.getGroupOptions();
			Map<ID,Group> groupMap = ext.groupMap;
			List<SelectOption> PSOptions = ext.getPSOptions();
			Map<ID,PermissionSet> permissionSetMap = ext.permissionSetMap;

			// get permisson set name
			ext.DGRule.Permission_Set_ID__c = null;
			ext.onchangePS();
			String PSetName = ext.DGRule.Permission_Set_Name__c;
			ext.DGRule.Permission_Set_ID__c = PSList.get(1).Id;
			ext.onchangePS();
			String PSetName2 = ext.DGRule.Permission_Set_Name__c;

			// get group name
			ext.DGRule.Group_ID__c = null;
			ext.onchangeGroup();
			String groupName = ext.DGRule.Group_Name__c;
			ext.DGRule.Group_ID__c = groupList.get(1).Id;
			ext.onchangeGroup();
			String groupName2 = ext.DGRule.Group_Name__c;

			//doSaveAndNew();
			ext.DGRule.Active__c = false;
			ext.DGRule.Remove_on_no_Link__c = false;
			ext.doSaveAndNew();

		Test.stopTest();
		System.assert(optionsCorrect(groupOptions, groupMap.keySet()),'DGREdit:GroupOtions: Group options did not get set correctly');
		System.assert(optionsCorrect(PSOptions, permissionSetMap.keySet()),'DGREdit:PSOptionsSVC: Permission Set options did not get set correctly');
		System.assertEquals('',PSetName,'DGREdit:PS Name: Permission Set Name did not get cleared');
		System.assertEquals(PSList.get(1).Label,PSetName2,'DGREdit:PS Name: Permission Set Name did not set correctly');
		System.assertEquals('',groupName,'DGREdit:Group Name: Group Name did not get cleared');
		System.assertEquals(groupList.get(1).Name,groupName2,'DGREdit:Group Name: Group Name did not set correctly');
	}
	
	// ** Begin Private Methods ****************************************************************************
	/********************************************************************************************************************/
	/* 
	* @Method       prepUsers
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Creates test users 
	* @param        Integer userCount how many users to create
	* @return       List<User> List of the users created
	*/
	private static List<User> prepUsers(Integer userCount) {

		String orgId = UserInfo.getOrganizationId();
		UserRole testRole = [ select id from userrole where ParentRoleId ='' ];
		Profile testProf = [ select id from profile where UserType = 'Standard' and Name = 'Standard User' ];

		List<User> testUsers = new List<User>();
		User thisUser = new User();

		for (Integer indx = 0; indx < userCount; indx++) {
			thisUser = new User();

			String uniqueName = getUniqueUserName(orgId);
			//create users
			thisUser.Username= uniqueName + '@test' + orgId + '.org';
			thisUser.Email = uniqueName + '@test' + orgId + '.org';
			thisUser.Lastname = 'user' +indx;
			thisUser.Firstname = 'test';
			thisUser.Alias = uniqueName.substring(18, 23);
			thisUser.CommunityNickname = 'Test'+indx;

			thisUser.UserRoleId = testRole.Id;
			thisUser.ProfileId = testProf.ID;

			//thisUser.CurrencyIsoCode = 'USD';
			thisUser.TimeZoneSidKey = 'GMT';
			thisUser.LocaleSidKey = 'en_US';
			thisUser.EmailEncodingKey = 'ISO-8859-1';
			thisUser.LanguageLocaleKey = 'en_US';
			thisUser.UserPermissionsMobileUser = false;
			testUsers.add(thisUser);
		}
		insert testUsers;   
		return testUsers;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       prepRules
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Removes all group and permision sets from users and then creates some DGM rules
	* @param        Void
	* @return       Void
	*/
	private static void prepRules() {
		// get list of groups
		list<Group> delGroupList = (List<Group>)database.query(DGMService.groupQuery);
		// get current group membership
		list<GroupMember> delGroupMembers = [Select Id, UserOrGroupId, GroupId From GroupMember where GroupId in :delGroupList];

		User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
			// Remove all group members 
			delete delGroupMembers;
			//Create permission sets
			UserLicense SFFull = [Select Name, Id From UserLicense where Name = 'Salesforce' ];
			PSList = new list<PermissionSet>{new PermissionSet(Label = 'TestPS 1',name = 'TestPS_1')
											,new PermissionSet(Label = 'TestPS 2',name = 'TestPS_2')
											,new PermissionSet(Label = 'TestPS 3',name = 'TestPS_3')};
			insert PSList;
		
			//Create groups
			groupList = new list<Group>{new Group(DeveloperName = 'DGM_Group_1',Name = 'DGM Group 1',DoesIncludeBosses=false)
									,new Group(DeveloperName = 'DGM_Group_2',Name = 'DGM Group 2',DoesIncludeBosses=false)
									,new Group(DeveloperName = 'DGM_Group_3',Name = 'DGM Group 3',DoesIncludeBosses=false)};
			insert groupList;

			//Greate rules
			DGMRules = new list<Dynamic_Group_Rule__c>{
									new Dynamic_Group_Rule__c(Permission_Set_ID__c=PSList.get(0).Id,Group_ID__c=groupList.get(0).Id,Remove_on_no_Link__c=true,Active__c=true)
									,new Dynamic_Group_Rule__c(Permission_Set_ID__c=PSList.get(1).Id,Group_ID__c=groupList.get(0).Id,Remove_on_no_Link__c=true,Active__c=true)
									,new Dynamic_Group_Rule__c(Permission_Set_ID__c=PSList.get(1).Id,Group_ID__c=groupList.get(1).Id,Remove_on_no_Link__c=true,Active__c=true)
									,new Dynamic_Group_Rule__c(Permission_Set_ID__c=PSList.get(2).Id,Group_ID__c=groupList.get(0).Id,Remove_on_no_Link__c=true,Active__c=false)
									,new Dynamic_Group_Rule__c(Permission_Set_ID__c=PSList.get(2).Id,Group_ID__c=groupList.get(1).Id,Remove_on_no_Link__c=true,Active__c=true)
									,new Dynamic_Group_Rule__c(Permission_Set_ID__c=PSList.get(2).Id,Group_ID__c=groupList.get(2).Id,Remove_on_no_Link__c=false,Active__c=true)
								};
			insert DGMRules;
		}
	}
	
	/********************************************************************************************************************/
	/* 
	* @Method       getUniqueUserName
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  gets a unique name for creatin users
	*               code based on Viasur http://salesforce.stackexchange.com/questions/40675/create-multiple-users-in-apex-test-coverage
	* @param        String orgID the Id of this org
	* @return       String a unique name including OrgIs + timestamp + random number
	*/
	private static String getUniqueUserName(String orgID) {
		String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
		Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
		return orgId + dateString + randomInt;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       addPSToUser
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  adds a user to a permision set
	* @param        Integer userIndx index of user on UserList
	* @param        Integer PSIndx index of permission set on PSList to be added to user
	* @return       Void
	*/
	private static Void addPSToUser(Integer userIndx,Integer PSIndx) {
		PermissionSetAssignment PSAssignment = new PermissionSetAssignment(
				PermissionSetId = PSList.get(PSIndx).Id,
				AssigneeId = UserList.get(userIndx).Id);
		insert PSAssignment;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       removePSfromUser
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  removes a user from a permision set
	* @param        Integer userIndx index of user on UserList
	* @param        Integer PSIndx index of permission set on PSList to be removed from user
	* @return       Void
	*/
	private static Void removePSfromUser(Integer userIndx,Integer PSIndx) {
		PermissionSetAssignment PSAssignment = [Select Id from PermissionSetAssignment
						where PermissionSetId = :PSList.get(PSIndx).Id and AssigneeId = :UserList.get(userIndx).Id];
		delete PSAssignment;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       groupsCorrect
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Checks to see if list of group ids are in the list of groupmember
	* @param        list<GroupMember> list of groupmember records for user
	* @param        list<Id> groupIds list of group Ids the user should be in
	* @return       Boolean id all the groups are in the groupmembers
	*/
	private static Boolean groupsCorrect(list<GroupMember> groupMs, list<Id> groupIds){
		Boolean groupsOK = false;
		for(Id thisGroupID : groupIds){
			groupsOK = false;
			for(GroupMember thisMember :groupMs) {
				if(thisMember.GroupId == thisGroupID){
					groupsOK = true;
					break;
				}
			}
			if (!groupsOK){
				break;
			}
		}
		return groupsOK;
	}
	/********************************************************************************************************************/
	/* 
	* @Method       optionsCorrect
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Checks to see if list of selectOptions have same number and all Id's are in SelectOption List
	* @param        list<SelectOption> list of SelectOptions
	* @param        set<Id> list of Id's that should be in the select options 
	* @return       Boolean id all the Id's are in the SelectOptions
	*/
	private static Boolean optionsCorrect(List<SelectOption> optionsList, set<Id> sourceIds){
		Boolean optionsOK = false;
		if(optionsList.Size() - 1  == sourceIds.size()){
			for(Id thisId : sourceIds){
				optionsOK = false;
				for(SelectOption thisOption :optionsList) {
					if(thisOption.getValue() != ''){
						if((Id)thisOption.getValue() == thisId){
							optionsOK = true;
							break;
						}
					}
				}
				if (!optionsOK){
					break;
				}
			}
		}
		return optionsOK;
	}
	// ** End Private Methods ******************************************************************************
}