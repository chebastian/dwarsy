package  
{
	import flash.automation.Configuration;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.net.sendToURL;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
	import mx.core.FlexApplicationBootstrap;
	import org.flixel.FlxG;
	import org.flixel.*;
	import LevelMap;
	import Cell;
	import LevelDoor;
	import Pickup;
	import Door;
	import org.flixel.FlxGroup;
	
	/**
	 * ...
	 * @author Sebastian Ferngren
	 */
	public class CellRoom extends Cell
	{
		var mMap:LevelMap;
		var mCollisionMap:LevelMap;
		
		var mDoneLoading:Boolean;
		var mExits:Array;
		var mGroupEnemies:FlxGroup;
		var mGameObjects:FlxGroup;
		var mWallSwitches:FlxGroup;
		var mRaisableWalls:FlxGroup;
		var mSolidObjects:FlxGroup;
		
		var mWallNotifier:WallNotifier;
		
		var mDataTiles:String;
		var mDataCollision:String;
		var mXmlRoomData:XML;
		var mRoomId:String;
		var mRoomFilePath:String;
		var mMapIndex:Point;
		var mEmpty:Boolean;
		var mDebugString:FlxText;
		var mClearedEvents:Array;
		var mPickups:FlxGroup;
		
		static var FILE_EMPTY_ROOM:String = "../media/levels/level_1/empty.xml";
		
		public static var 	BOUNDS_UP:uint = 0;
		public static var 	BOUNDS_RIGHT:uint = 1;
		public static var 	BOUNDS_DOWN:uint = 2;
		public static var 	BOUNDS_LEFT:uint = 3;
		public static var 	BOUNDS_NONE:uint = 4;
		
		public static const EVT_ENEMY_CLEARED:int = 0;
		public static const EVT_BUTTON_PRESSED:int = 1;
		public static const EVT_TREASURE_OPENED:int = 2;
		public static const EVT_ROOM_CLEARED:int = 3;
		public static const EVT_NUM:int = 4;
		
		public static var 	LEVEL_TILE_W = 32;
		public static var 	LEVEL_TILE_H = 32;
		public static var 	LEVEL_TILE_NUMX = 17;
		public static var 	LEVEL_TILE_NUMY = 13;
		protected var 		LEVEL_LEFT = 0;
		protected var 		LEVEL_RIGHT = 32 + (LEVEL_TILE_W* LEVEL_TILE_NUMX);
		protected var 		LEVEL_TOP = 0;
		protected var 		LEVEL_BOTTOM = 32 + (LEVEL_TILE_H * LEVEL_TILE_NUMY);
		protected var 		LEVEL_BUFFER_W = 8;
		protected var 		LEVEL_BUFFER_H = 8;
		
		
		public function CellRoom(game:PlayState, id:uint,path:String) 
		{
			super(new Point(0,0),game);
			mGame = game;
			mDoneLoading = false;
			mRoomFilePath = path;
			mUniqueId = id;
			
			mMap = new LevelMap();
			mExits = new Array();
			mGroupEnemies = new FlxGroup();
			mXmlRoomData = new XML();
			mMapIndex = new Point();
			mClearedEvents = new Array(EVT_NUM);
			mPickups = new FlxGroup();
			mGameObjects = new FlxGroup();
			mWallNotifier = new WallNotifier(mGame,mGameObjects);
			mWallSwitches = new FlxGroup();
			mRaisableWalls = new FlxGroup();
			mSolidObjects = new FlxGroup();
			
			mEmpty = path.toUpperCase == FILE_EMPTY_ROOM.toUpperCase;
		}
		
		public static function NullRoom():CellRoom
		{
			var room:CellRoom = new CellRoom(null, null, FILE_EMPTY_ROOM);
			return room;
		}
		
		override public function  OnEnter():void
		{
			LoadLevel(mRoomFilePath);
			SetRoomGoals();
			mGame.LAYER_ENEMY.add(mGameObjects);
			mGame.LAYER_ITEM.add(mRaisableWalls);
			mGame.LAYER_ITEM.add(mWallSwitches);
			
			mGame.LAYER_ITEM.add(mPickups);
			bindSwitches();
			
			mSolidObjects.add(mRaisableWalls);
			mSolidObjects.add(mWallSwitches);
			//mMap.AddLayersToStage(mGame);
		}
		
		public function bindSwitches():void 
		{
			mWallNotifier = new WallNotifier(mGame,mRaisableWalls);

			for each(var doorSwitch:WallSwitch in mWallSwitches.members)
			{
				doorSwitch.addNotifier(mWallNotifier);
				doorSwitch.setOpen(mGame.ActiveLevel().getGlobalSwitchState());
			}
			for each(var wall:RaisableWall in mRaisableWalls.members)
			{
				wall.setOpen(mGame.ActiveLevel().getGlobalSwitchState());
			}
		}
			
		protected function SetRoomGoals():void 
		{
			if (mGroupEnemies.length > 0)
			{
				if(!EventIsCleared(EVT_ROOM_CLEARED))
					SetEventStatus(EVT_ENEMY_CLEARED, false);
			}
		}
		
		public function SetEventStatus(event:uint, b:Boolean):Boolean
		{
			if (event < 0 || event >= mClearedEvents.length)
				return false;
			
			mClearedEvents[event] = b;
			
			return true;
		}
		
		public function EventIsCleared(event:uint):Boolean
		{
			if (event < 0 || event >= mClearedEvents.length)
				return false;
				
			return mClearedEvents[event];
		}
		
				
		override public function OnExit():void
		{
			ClearLevel();
		}
		
		public function ClearLevel():void
		{	
			if (mMap.exists)
			{
				mMap.kill();
				mMap.exists = false;
				mMap = new LevelMap();
			}
				
			if (mGroupEnemies.exists)
			{
				mGroupEnemies.kill();
				mGroupEnemies.exists = false;
				mGroupEnemies = new FlxGroup();
			}
			
			if(mPickups.exists)
			{
				mPickups.kill();
				mPickups.exists = false;
				mPickups = new FlxGroup();
			}
			
			
			while (mExits.length > 0)
			{
				var door:Door = mExits.pop();
				door.kill();
				door.exists = false;
			}
			mSolidObjects.clear();
			
			clearLayersUsed();
		}
		
		protected function clearLayersUsed():void 
		{
			mGame.LAYER_BKG.clear();
			mGame.LAYER_BKG1.clear();
			mGame.LAYER_ENEMY.clear();
			mGame.LAYER_ITEM.clear();
			mGame.LAYER_FRONT.clear();
		}
	
		
		override public function update():void 
		{
			super.update();
			
			FlxG.collide(mGroupEnemies, mMap);
			
			handlePlayerHitSwitch(mGame.ActivePlayer());
			ProcessRoomGoals();
		}
		
		protected function ProcessRoomGoals():void
		{
			if (EventIsCleared(EVT_ENEMY_CLEARED) == false && EventIsCleared(EVT_ROOM_CLEARED) == false)
			{
				if (mGroupEnemies.countDead() >= mGroupEnemies.length)
				{
					SetEventStatus(EVT_ENEMY_CLEARED, true);
					OnEnemiesCleared();
				}
			}
		}
		
		public function OnEnemiesCleared():void
		{
			var b:Boolean = false;
			SetEventStatus(EVT_ROOM_CLEARED, true);
			
			for (var i:uint = 0; i < mPickups.length; i++)
			{
				mPickups.members[i].Activate();
				mGame.LAYER_ITEM.add(mPickups.members[i]);
			}
		}
		
		public function HandlePlayerEnemyCollision(player:PlayerCharacter):void
		{
			for (var i:uint = 0; i < mGroupEnemies.length; i++)
			{
				var enemy:Enemy = mGroupEnemies.members[i];
				player.OnHitCharacter(enemy);
				enemy.OnHitCharacter(player);
			}
		}
		
		public function handlePlayerWallCollision(player:PlayerCharacter):void
		{
			if (FlxG.collide(player, mSolidObjects))
			{
				
			}
		}
		
		public function handlePlayerHitSwitch(player:PlayerCharacter):void 
		{
			for each(var sw:WallSwitch in mWallSwitches.members)
			{
				if(player.Attacking())
					sw.onHit(player);
			}
		}
		
		public function PlayerReachExit(player:Character):uint
		{
			if (player.x > LEVEL_RIGHT + LEVEL_BUFFER_W)
				return BOUNDS_RIGHT;
			else if (player.x < -LEVEL_BUFFER_W)
				return BOUNDS_LEFT;
			else if (player.y < 0)
				return BOUNDS_UP;
			else if (player.y > LEVEL_BOTTOM + LEVEL_BUFFER_H)
				return BOUNDS_DOWN;
				
			return BOUNDS_NONE;
		}
		
		public function HandlePlayerExit(player:Character, bound:uint):void 
		{
			//var bound:uint = PlayerReachExit(player);
				
			if (bound == BOUNDS_RIGHT)
			{
				player.x = LEVEL_LEFT + LEVEL_BUFFER_W;
			}
			else if (bound == BOUNDS_LEFT)
			{
				player.x = LEVEL_RIGHT - LEVEL_BUFFER_W;
			}
			else if (bound == BOUNDS_UP)
			{
				player.y = LEVEL_BOTTOM - LEVEL_BUFFER_H;
			}
			else if (bound == BOUNDS_DOWN)
			{
				player.y = LEVEL_TOP;
			}
		}
		
		public function LoadLevel(name:String)
		{
			mDoneLoading = false;
			mRoomId = name;
			var xmlLoader:URLLoader = new URLLoader();
			var xmlData:XML = new XML();
			
			
			xmlLoader.addEventListener(Event.COMPLETE, OnLoadXml);
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, onFileNotFound);
			xmlLoader.load(new URLRequest(name));
		}
		
		private function onFileNotFound(e:IOErrorEvent):void
		{
			trace(e.text);
			var j:Boolean = false;
			
			j = true;
		}
		
		public function OnLoadXml(e:Event):void 
		{
			var xmlData:XML = new XML(e.target.data);
			mXmlRoomData = xmlData;
			var xmlList:XMLList = xmlData.data;
			
			ParseLevelLayers(xmlList);
			
			ParseExitsFromXml(xmlData.exits.exit);
			
			ParseEnemiesFromXml(xmlData.enemies.enemy);
			
			ParseTreasuresFromXml(xmlData.treasures.treasure);
			
			mMap.LoadLevel(mDataTiles);
			
			LEVEL_TILE_NUMX = mMap.widthInTiles-2;
			LEVEL_TILE_NUMY = mMap.heightInTiles-1;
			LEVEL_RIGHT = (LEVEL_TILE_W* LEVEL_TILE_NUMX);
			LEVEL_BOTTOM = (LEVEL_TILE_H * LEVEL_TILE_NUMY);
			
			//mGame.LAYER_BKG.add(mMap);
			
			mMap.AddLayersToStage(mGame);
			
			mDoneLoading = true;
		}
		
		public function ParseLevelLayers(Ldata:XMLList):void {
			var layers:Array = new Array();
			
			for each(var node in Ldata)
			{
				var attributes:XMLList = node.attributes();
				var tiles:String = "";
				var colTiles:String = "";
				var newLevel:LevelMap = new LevelMap();
				for each(var atr in attributes)
				{
					if (atr.name() == "tiles")
					{
						tiles = atr;
						newLevel.LoadLevel(tiles, 1);
						mDataTiles = tiles;
					}
					else if (atr.name() == "colData")
					{
						colTiles = atr;
						newLevel.LoadCollision(colTiles, 1);
						mMap.LoadCollision(colTiles, 1);
					}
				}
				
				//mGame.LAYER_BKG.add(newLevel);
				//layers.push(newLevel);
				mMap.AddLayer(tiles);
			}
		}
		
		public function ParseTilesFromXml(tiles:XMLList):void
		{
			for each(var attribute in tiles)
			{
				if (attribute.name() == "tiles")
				{
					mDataTiles = attribute;
				}
				else if (attribute.name() == "colData")
				{
					mDataCollision = attribute;
					mMap.LoadCollision(mDataCollision);
				}
			}
			
		}
		public function ParseExitsFromXml(list:XMLList):void 
		{
			mExits = new Array();
			for each(var node in list)
			{
				var exitAttributes:XMLList = node.attributes();
				var id:String;
				var pos:Point = new Point();
				
				for each(var attribute in exitAttributes)
				{
					if (attribute.name() == "id")
					{
						id = attribute;
					}
					
					else if (attribute.name() == "posX")
					{
						pos.x = parseInt(attribute);
					}
					else if (attribute.name() == "posY")
					{
						pos.y = parseInt(attribute);
					}
				}
				
				AddLockedTile(true, id, pos);
				//OLD CODE
				/*var door:LevelDoor = new LevelDoor(new Point(), new Point(), file, open);
				door.SetId(id);
				mExits.push(door);*/
			}
		}
		
		public function AddLockedTile(locked:Boolean, id:String, pos:Point):void
		{
			var door:Door = new Door(mGame, id, pos, true);
			mExits.push(door);
		}
		
		public function ParseEnemiesFromXml(enemies:XMLList):void
		{
			
			if (mGroupEnemies != null)
			{
				mGroupEnemies.exists = false;
			}
			
			mGroupEnemies = new FlxGroup();
			
			if (EventIsCleared(EVT_ROOM_CLEARED))
				return;
			
			for each(var enemy in enemies)
			{
				var enemyAttr:XMLList = enemy.attributes();
				var enemyId:String = "0";
				var enemyType:String = "normal";
				var enemyPos:Point = new Point();
				for each(var attribute in enemyAttr)
				{
					if (attribute.name() == "id")
					{
						enemyId = attribute;
					}
					
					else if (attribute.name() == "type")
					{
						enemyType = attribute;
					}
					
					else if (attribute.name() == "posX")
					{
						enemyPos.x = parseInt(attribute);
					}
					else if (attribute.name() == "posY")
					{
						enemyPos.y = parseInt(attribute);
					}
				}
				
				var createdEnemy:EnemySlime = new EnemySlime(mGame, enemyPos);
				mGame.LAYER_ENEMY.add(createdEnemy);
				
				mGroupEnemies.add(createdEnemy);
			}
		}
		
		public function addEnemyToRoom(enemy:Enemy)
		{
			mGame.LAYER_ENEMY.add(enemy);
			mGroupEnemies.add(enemy);
		}
		
		protected function ParseTreasuresFromXml(node:XMLList):Boolean
		{
			for each(var treasure in node)
			{
				var atrNode:XMLList = treasure.attributes();
				var id:String = new String();
				var evt:String= new String();
				var item:String = new String();
				var pos:Point = new Point();
				
				for each(var attribute in atrNode)
				{
					if (attribute.name() == "id")
					{
						id = attribute;
					}
					else if (attribute.name() == "evt")
					{
						evt = attribute;
					}
					else if (attribute.name() == "item")
					{
						item = attribute;
					}
					else if (attribute.name() == "posX")
					{
						pos.x = parseFloat(attribute) * LEVEL_TILE_W;
					}
					else if (attribute.name() == "posY")
					{
						pos.y = parseFloat(attribute) * LEVEL_TILE_H;
					}
				}
				
				AddItemToRoom(id + mUniqueId, item, pos);
			}
			
			return true;
		}
		
		protected function AddItemToRoom(id:String, item:String, pos:Point):void
		{
			var pickup:Pickup = new Pickup(mGame, id,item, pos, null);
			mPickups.add(pickup);
			if (!mGame.PlayerHasItem(pickup) && EventIsCleared(EVT_ROOM_CLEARED))
			{
				pickup.Activate();
				mGame.LAYER_ITEM.add(pickup);
			}
		}
		
		public function OnCompleteLoad(e:Event):void
		{
			mMap.LoadLevel(e.target.data);
			mGame.LAYER_BKG.add(mMap);
			mDoneLoading = true;
		}
		
		public function Enemies():FlxGroup
		{
			return mGroupEnemies;
		}
		
		public function MapCollisionData():FlxTilemap
		{
			if (mMap.CollisionmapLoaded)
				return mMap.mCollisionMap;
				
			return mMap;
		}
		
		public function MapIndex():Point
		{
			return mMapIndex;
		}
		
		public function EmptyRoom():Boolean
		{
			return mEmpty;
		}
		
		public function SetMapIndex(pos:Point):void
		{
			mMapIndex = pos;
		}
		
		public function RoomIsCleared():Boolean
		{
			return EventIsCleared(EVT_ROOM_CLEARED);
		}
		
		public function AddGameObjects(obj:GameObject):void
		{
			mGameObjects.add(obj);
		}
		
		public function addWallSwitch(s:WallSwitch):void {
			mWallSwitches.add(s);
		}
		
		public function addRaisableWall(r:RaisableWall):void {
			mRaisableWalls.add(r);
		}
		
		public function setId(id:uint):void
		{
			mUniqueId = id;
		}
		
		public function setTileDataPath(path:String):void
		{
			mRoomFilePath = path;
		}
		
		public function testSwitch():void {
			for each(var wallS:WallSwitch in mWallSwitches.members) {
				wallS.onHit(mGame.ActivePlayer());
			}
		}
			
		public function getRandomTile():FlxTileblock {
			return mMap.GetRandomFloorTile();
		}
		
		public function reloadRoom():void {
			this.LoadLevel(mRoomFilePath);
		}
	}

}