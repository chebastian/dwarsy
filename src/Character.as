package  
{
	/**
	 * ...
	 * @author Sebastian Ferngren
	 */
	
	 import CharacterStates.IdleState;
	 import CharacterStates.WanderState;
	 import flash.display.ShaderParameter;
	 import flash.events.ProgressEvent;
	 import flash.geom.Point;
	 import GameObject;
	public class Character extends GameObject
	{
		
		static var Animation_Idle:String = "idle";
		static var Animation_WalkLeft:String = "walkLeft";
		static var Animation_WalkRight:String = "walkRight";
		static var Animation_WalkUp:String = "walkUp";
		static var Animation_WalkDown:String = "walkDown";
		
		var mCurrentAnimation:String;
		
		var WALK_SPEED:uint = 150;
		public var mGame:PlayState;
		var mWandering:Boolean;
		var mHeading:Point;
		var mIsAttacking:Boolean;
		
		var mState:CharacterState;
		var mAnimationFrameRate:uint;
		
		var mHitCharCooldown:Number;
		var mStrength:Number;
		var mHealth:Number;
		
		var mWeaponHitbox:GameObject;
		var mHitBox:GameObject;
		
		var mHitBoxPosOffset:Point;
		var mHitBoxSizeOffset:Point;
		
		var srcWH:Point;
		
		public function Character(game:PlayState, _x:Number, _y:Number) 
		{
			mGame = game;
			//mAABBOffset = new Point(0, 10);
			//mAABBHeightOffset = -10;
			super(_x, _y, null);
			mAABBOffset = new Point(0, 16);
			mAABBHeightOffset = -16;
			
			maxVelocity.y = WALK_SPEED;
			maxVelocity.x = WALK_SPEED;
			mWandering = false;
			mHeading = new Point(0, 0);
			mIsAttacking = false;
			mAnimationFrameRate = 10;
			srcWH = new Point(32, 32);
			Init();
		}
		
		override public function Init():void 
		{
			InitAnimations();
			mState = new IdleState(0, this);
			mStrength = 1.0;
			mHealth = 100.0;
			
			mWeaponHitbox = new GameObject(x, y, null);
			mHitBox = new GameObject(x, y, null);
			mHitBoxPosOffset = new Point(0, 0);
			mHitBoxSizeOffset = new Point(0, 0);
		}
		
		public function InitAnimations():void
		{
			loadGraphic(GameResources.Anim_LinkWalkDown, true, false, srcWH.x, srcWH.y, false);
			addAnimation(Animation_Idle,[0],mAnimationFrameRate);
			addAnimation(Animation_WalkLeft,[0,1,2,3,4,5,6],mAnimationFrameRate);
			addAnimation(Animation_WalkDown,[0,1,2,3,4,5,6,7],mAnimationFrameRate);
			addAnimation(Animation_WalkUp,[0,1,2,3,4,5,6,7],mAnimationFrameRate);
			addAnimation(Animation_WalkRight, [0, 1, 2, 3, 4, 5, 6], mAnimationFrameRate);
			
			mCurrentAnimation = "";
			ChangeAnimation(Animation_Idle, GameResources.Anim_LinkWalkDown);
		}
		
		public function ChangeState(state:CharacterState)
		{
			if(mState != null)
				mState.OnExit();
			
			mState = null;
			mState = state;
			mState.OnEnter();
		}
		
		public function IsInState(state:int):Boolean
		{
			if (state == mState.StateId())
			{
				return true;
			}
			
			return false;
		}
		
		override public function Move(dir:Point, dist:Number):void 
		{
			velocity.x = dir.x * dist;
			velocity.y = dir.y * dist;
			
			mHeading = dir;
		}
		public function ChangeAnimation(name:String, img:Class = null):void
		{
			if(IsPlayingAnimation(name))
				return;
			
			if(img != null)
			{
				loadGraphic(img,true,false,srcWH.x,srcWH.y);
			}
			
			play(name);
			mCurrentAnimation = name;
		}
		
		public function IsPlayingAnimation(name:String):Boolean
		{
			if(mCurrentAnimation.toLocaleLowerCase() == name.toLocaleLowerCase())
				return true;
			
			return false;
		}
		
		override public function update():void 
		{
			super.update();
			mState.OnUpdate();
			UpdateHitbox();
		}
		
		public function UpdateHitbox():void 
		{
			//
			//Update players hitbox, used for receiving damage
			//
			mHitBox.x = x + mHitBoxPosOffset.x;
			mHitBox.y = y + mHitBoxPosOffset.y;
			mHitBox.width = width + mHitBoxSizeOffset.x;
			mHitBox.height = height + mHitBoxSizeOffset.y;
			
			//Update players attackHitBox, used for dealing damage
			//this box will be moved around depending on players heading
			var hitDist:Number = 0.0;
			mWeaponHitbox.x = x + mHeading.x * hitDist;
			mWeaponHitbox.y = y + mHeading.y * hitDist;
			mWeaponHitbox.width = width;
			mWeaponHitbox.height = height;
		}
		
		public function TurnRight()
		{
			var xdir:Number = -mHeading.y;
			mHeading.y = mHeading.x;
			mHeading.x = xdir;
		}
		
		public function TurnInDir(dir:Point)
		{
			mHeading.x += dir.x;
			mHeading.y += dir.y;
			mHeading.normalize(1.0);
		}
		
		public function WalkInDir(dir:Point)
		{
			mHeading.x = dir.x;
			mHeading.y = dir.y;
			velocity.x = mHeading.x * WALK_SPEED;
			velocity.y = mHeading.y * WALK_SPEED;
		}
		
		public function Wander(dir:Point, speed:Number)
		{
			velocity.x = WALK_SPEED * dir.x;
			velocity.y = WALK_SPEED * dir.y;
			mHeading.x = dir.x;
			mHeading.y = dir.y;
			
			mWandering = true;
		}
		
		//
		// Called when character hits another character
		// ex: When player hits character, receive dmg or do dmg depending on state
		//
		public function OnHitCharacter(char:Character):void
		{
			if (char.Attacking())
			{
				
			}
		}
		
		public function HeadForCharacter(char:Character):void 
		{
				var dir:Point = new Point(char.x - x, char.y - y);
				var len:Number = dir.length;
				dir.normalize(1);
				mHeading = dir;
		}
		
		public function IsFacingCharacter(char:Character):Boolean
		{
			var dir:Point = new Point(x, y);
			dir.x = x - char.x;
			dir.y = y - char.y;
			dir.normalize(1.0);
			
			if (dir.x < 0 && mHeading.x > 0)
				return true;
			else if (dir.x > 0 && mHeading.x < 0)
				return true;
			else if (dir.y < 0 && mHeading.y > 0)
				return true;
			else if (dir.y > 0 && mHeading.y < 0)
				return true;
			
			return false;
		}
		
		public function JustHitWall():Boolean
		{
			return justTouched(LEFT | RIGHT | DOWN | UP);
		}
		
		public function Heading():Point
		{
			return mHeading;
		}
		
		public function HitBox():GameObject
		{
			return mHitBox;
		}
		
		public function WeaponHitBox():GameObject
		{
			return mWeaponHitbox;
		}
		
		public function SetSpeed(speed:Number):void
		{
			WALK_SPEED = speed;
		}
		public function Speed():Number
		{
			return WALK_SPEED;
		}
		
		public function Attacking():Boolean
		{
			return IsInState(CharacterState.ATTACK_STATE);
		}
		
		public function Strength():Number
		{
			return mStrength;
		}
	}

}