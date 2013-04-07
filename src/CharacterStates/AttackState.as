package CharacterStates 
{
	import flash.display.Sprite;
	import flash.geom.Point;
	/**
	 * ...
	 * @author ...
	 */
	public class AttackState extends CharacterState 
	{
		var mAttackCountDown:Number;
		
		public function AttackState(char:Character) 
		{
			
			super(ATTACK_STATE, char);
			
			mAttackCountDown = 0.5;
			mCharacter.ChangeAnimation("idle", null);
			
			mId = ATTACK_STATE;
			
			mCharacter.ChangeAnimation("attack",null);
		}
		
		override public function OnEnter():void 
		{
			super.OnEnter();
			mCharacter.ChangeAnimation("attack", null);
		}
		
		override public function OnExit():void 
		{
			super.OnExit();
		}
		
		override public function OnUpdate():void 
		{
			super.OnUpdate();
			mCharacter.StopMoving();
			if (mStateTimer >= 0.2)
			{
				mCharacter.ChangeState(new IdleState(0, mCharacter));
			}
			trace("ATTACKING");
		}
		
		public function AttackInDirection(dir:Point):void
		{
			var sz:Number = 20;
			var len:Number = 10;
			var attackObj:GameObject = new GameObject(mCharacter.x, mCharacter.y,null);
		}
	}

}