/*******************************************************************************************************************************
 *  
 *  @Author         Mike Camp 
 *  @Date Created   08/26/2016
 *  @Description    Service Class for Dynamic Group Management
 * 
 *******************************************************************************************************************************/
/*
CHANGE LOG
	08/26/2016 MCAMP     - initial version
	09/30/2016 MCAMP     - Added Profile Based Rules
*/
// TODO: create method to deactivate rule and remove users from groups if needed
// TODO: figure out inactive users
// TODO: figure out getUsers() profile exceptions

public without sharing class DGMService {
	public static String userQuery = 'Select ID,IsActive from User where UserType != \'CsnOnly\'';
	public static String permissionSetQuery = 'SELECT Id,Label FROM PermissionSet where IsOwnedByProfile = false'; 
	public static String profileQuery = 'SELECT Id,Name FROM Profile where UserType != \'CsnOnly\''; 
	public static String groupQuery = 'SELECT Id,Name FROM Group WHERE Type = \'Regular\''; 
	/********************************************************************************************************************/
	/* 
	* @Method       updateGroups
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Updates the group membership for list of users
	* @param        list<Id> userIDs list of user Ids to update
	* @return       Void
	*/
	public static void updateGroups(set<Id> userIDs){
		//TODO: pass in rule to check

		//get list of active DGMs
		list<Dynamic_Group_Rule__c> DGRules = getDGRules();
		//get map of userId's with list of PSs
		map<Id,map<Id,sObject>> usersPSs = getPSByIds(userIDs);
		//get map of userId's with list of Groups
		map<Id,map<Id,sObject>> usersGroups = getGroupsByIds(userIDs);
		//get map of userId's with profile
		map<Id,User> usersProfile = new map<Id,User> ([Select Id, ProfileId from User where Id in :userIDs]);
		//Get Record Type names
		Map<ID, String> RTMap = getRecordTypeMap();
		//map of groups user is supposed to be in
		map<Id,set<Id>> userAuthGroup = new map<Id,set<Id>>();
		//map of groups user should be removed from
		map<Id,set<Id>> userDelGroup = new map<Id,set<Id>>();


		String recordTypeName = '';
		//loop over DGMs
		for (Dynamic_Group_Rule__c thisDGR : DGRules) {
			recordTypeName = '';
			if(thisDGR.RecordTypeId != null){
				recordTypeName = RTMap.get(thisDGR.RecordTypeId);
			}

			//loop over users
			for (Id thisID : userIDs){
				if(recordTypeName == 'Permission Set Based'){
					//check PermissionSets
					if(usersPSs.containsKey(thisID) && usersPSs.get(thisID).containsKey(thisDGR.Permission_Set_ID__c)){
						//add to groups authorized
						userAuthGroup = addGroup(userAuthGroup,thisId,thisDGR.Group_ID__c);
					} else if(thisDGR.Remove_on_no_Link__c && usersGroups.containsKey(thisId) && usersGroups.get(thisId).containsKey(thisDGR.Group_ID__c)) {
						//add to groups not authorized
						userDelGroup = addGroup(userDelGroup,thisId,thisDGR.Group_ID__c);
					}
				} else if (recordTypeName == 'Profile Based') {
					//check profile
					if(usersProfile.get(thisID).ProfileId == thisDGR.Profile_Id__c){
						userAuthGroup = addGroup(userAuthGroup,thisId,thisDGR.Group_ID__c);
					} else if(thisDGR.Remove_on_no_Link__c && usersGroups.containsKey(thisId) && usersGroups.get(thisId).containsKey(thisDGR.Group_ID__c)) {
						//add to groups not authorized
						userDelGroup = addGroup(userDelGroup,thisId,thisDGR.Group_ID__c);
					}
				}
			}
		}

		//build list of group Additions
		list<GroupMember> addGMs = new list<GroupMember>();
		//build list of group subtractions
		list<GroupMember> removeGMs = new list<GroupMember>();

		for (Id thisID : userIDs){
			if(userAuthGroup.containsKey(thisID)){
				//loop over authorized Groups
				for(Id thisGroup: userAuthGroup.get(thisID)){
					//If user does not have group
					if(!usersGroups.containsKey(thisId) || !usersGroups.get(thisId).containsKey(thisGroup)){
						//add to group
						addGMs.add(new GroupMember(UserOrGroupId = thisID, GroupId = thisGroup));
					}
				}
			}
			if(userDelGroup.containsKey(thisID)){
				//loop over authorized Groups
				for(Id thisGroup: userDelGroup.get(thisID)){
					//If user has group and is not authorized by another rule
					if(usersGroups.get(thisId).containsKey(thisGroup) && !(userAuthGroup.containsKey(thisID) && userAuthGroup.get(thisID).contains(thisGroup))) {
						//remove group
						removeGMs.add(new GroupMember(Id = (Id)usersGroups.get(thisId).get(thisGroup).Id));
					}
				}
			}
		}

		//Add new group memberships
		if(addGMs.size() > 0){
			insert dedupeGM(addGMs);
		}
		//remove group memberships 
		if(removeGMs.size() > 0){
			delete dedupeGM(removeGMs);
		}
	}

	/********************************************************************************************************************/
	/* 
	* @Method       updateGroups
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Updates the group membership for a user
	* @param        Id userID user to check PS vs Groups
	* @return       Void
	*/
	public static void updateGroups(Id userID){
		set<Id> userIDs =  new set<Id> {userID};
		updateGroups(userIDs);

	}

	/********************************************************************************************************************/
	/* 
	* @Method       updateGroups
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Updates the group membership for all users
	* @param        Void
	* @return       Void
	*/
	public static void updateGroups(){
		set<Id> userIDs = getUsers(); 
		updateGroups(userIDs);
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getPermissionSetMap
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  map<Id,PermissionSet>
	* @param        Gets a map of permission sets
	* @return       Void
	*/
	public static map<Id,PermissionSet> getPermissionSetMap(){
		map<Id,PermissionSet> PSMap= new map<Id,PermissionSet>((List<PermissionSet>)database.query(permissionSetQuery)); 
		return PSMap;
	}

   /********************************************************************************************************************/
	/* 
	* @Method       getProfileMap
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  map<Id,Profile>
	* @param        Gets a map of Profiles
	* @return       Void
	*/
	public static map<Id,Profile> getProfileMap(){
		map<Id,Profile> PMap= new map<Id,Profile>((List<Profile>)database.query(profileQuery)); 
		return PMap;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getGroupMap
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  gets a map of the regular groups
	* @param        Void
	* @return       map<Id,Group>
	*/
	public static map<Id,Group> getGroupMap(){
		map<Id,Group> GroupMap= new map<Id,Group>((List<Group>)database.query(groupQuery)); 
		return GroupMap;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getRecordTypeMap
	* @Author       MCAMP
	* @date         
	* @description  gets a map of the RecordTypes
	* @param        Void
	* @return       map<Id,String>
	*/
	public static map<Id,string> getRecordTypeMap(){
		Map<ID, String> newMap = new Map<ID, String>();
		Map<ID, Schema.RecordTypeInfo> thisMap = Dynamic_Group_Rule__c.sObjectType.getDescribe().getRecordTypeInfosById();
		for(String thisRt: thisMap.keySet()){
			newMap.put(thisMap.get(thisRt).getRecordTypeId(), thisMap.get(thisRt).getName());
		}
		return newMap;
	}


	// ** Begin private methods *****************************************************************************
	/********************************************************************************************************************/
	/* 
	* @Method       addGroup
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Adds a group Id to a set baed on user Id
	* @param        Map<Id,Set<Id>> mapIn the map of userIds with list of GroupIds to be updated
	* @param        Id userId user Id to add/update in map
	* @param        Id groupId group Id to add to user
	* @return       Map<Id,Set<Id>>
	*/
	private static Map<Id,Set<Id>> addGroup(Map<Id,Set<Id>> mapIn,Id userId,Id groupId) {
		Map<Id,Set<Id>> thisMap = mapIn;
		Set<Id> thisSet = new Set<Id>();
		//if user set already exist, get it
		if(thisMap.containsKey(userId)){
			thisSet = thisMap.get(userId);
		}
		//Add the new groupId
		thisSet.add(groupId);
		//Add to Map
		thisMap.put(userId,thisSet);

		return thisMap;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getDGRules
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Gets a list of the Active Dynamic Group Rules
	* @param        Void
	* @return       list<Dynamic_Group_Rule__c> all active rules
	*/
	private static list<Dynamic_Group_Rule__c> getDGRules(){
		list<Dynamic_Group_Rule__c> DGRules = [Select ID,Group_ID__c,Permission_Set_ID__c,Remove_on_no_Link__c,RecordTypeId,Profile_Id__c from Dynamic_Group_Rule__c where Active__c = true];
		return DGRules;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getGroupsByIds
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Gets a map<groupId,Groupmembership> in a map by user ID
	* @param        list<Id> userIDs list of userId's to get
	* @return       map<Id,map<Id,sObject>> a map of group memberships by groupID in a map by userID
	*/
	private static Map<Id,Map<Id,sObject>> getGroupsByIds(set<Id> userIDs){
		// get Map of permissionset assignments by user
		map<Id,map<Id,sObject>> usersGroups = getMapOtherIDByOtherID([Select Id, UserOrGroupId, GroupId From GroupMember where UserOrGroupId in :UserIDs],'UserOrGroupId', 'GroupId');
		return usersGroups;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getPSByIds
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Gets a map<permisionsetId,PermissionsetAssignment> in a map by user ID
	* @param        list<Id> userIDs list of userId's to get
	* @return       map<Id,map<Id,sObject>> a map of permissionset Assignments by permisionsetId in a map by userID
	*/
	private static map<Id,map<Id,sObject>> getPSByIds(set<Id> userIDs){
		// get Map of permissionset assignments by user
		map<Id,map<Id,sObject>> usersPSs = getMapOtherIDByOtherID([Select Id, PermissionSetId, AssigneeId From PermissionSetAssignment WHERE AssigneeId in :UserIDs],'AssigneeId','PermissionSetId');
		return usersPSs;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getUsers
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Gets a list of userIDs to check
	* @param        Boolean allProfiles includes all profiles
	* @return       list<Id> list of userIds, not skipping any profiles
	*/
	private static set<Id> getUsers(Boolean allProfiles){
		//if not allProfiles  (not implemented yet)
			//get list of profiles to skip
		map<Id,User> userMap = new map<Id,User> ((List<User>)database.query(userQuery));

		return new set<Id>(userMap.keySet());
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getUsers
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Gets a list of userIDs to check
	* @param        Void
	* @return       list<Id> list of userIds, not skipping any profiles
	*/
	private static set<Id> getUsers(){
		return getUsers(False);
	}

	/********************************************************************************************************************/
	/* 
	* @Method       getMapOtherIDByOtherID
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  
	* @description  Return a Map of the List of Ids keyed on alternate ID field(lookup)
	* @param        List<sObjects> listIn list of sObjects
	* @param        String mapIDField name of ID field to use as Map key
	* @param        String listIDField name of ID field to use as list
	* @return       map<Id,map<Id,SObject>> map of a sObject in a map by anoter ID field 
	*/
	private static map<Id,map<Id,SObject>> getMapOtherIDByOtherID(List<sObject> listIn,String mapIDField,String listIDField ) {
		map<Id,map<Id,SObject>> returnMap = new map<Id,map<Id,SObject>>(); 
		map<Id,SObject> itemMap = new map<Id,SObject>();
		Id thisID;
		for (SObject thisItem : listIn){
			thisID = String.valueOf(thisItem.get(mapIDField));
			if (returnMap.containsKey(thisID)){
				itemMap = returnMap.get(thisID);
			} else {
				itemMap = new map<Id,SObject>();
			}
			itemMap.put(String.valueOf(thisItem.get(listIDField)),thisItem);
			returnMap.put(thisID,itemMap);
		}

		return returnMap;
	}

	/********************************************************************************************************************/
	/* 
	* @Method       dedupeGM
	* @Author       MCAMP
	* @date         08/26/2016
	* @description  Return a deduped list of group members
	* @param        List<GroupMember> listIn list of GroupMembers
	* @return       List<GroupMember> list of GroupMembers
	*/
	private static list<GroupMember> dedupeGM(list<GroupMember> listIn){
		set<GroupMember> tempSet = new Set<GroupMember>();
		list<GroupMember> returnList = new list<GroupMember>();
		tempSet.addAll(listIn);
		returnList.addAll(tempSet);
		return returnList;
	}
	// ** End private methods *******************************************************************************

}