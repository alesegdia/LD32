
import luxe.Input;

import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.Interactor;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.constraint.PivotJoint;

import luxe.AppConfig;
import luxe.physics.nape.DebugDraw;
import luxe.Vector;
import luxe.Color;
import luxe.Sprite;
import luxe.components.sprite.SpriteAnimation;
import luxe.tilemaps.Tilemap;
import luxe.tilemaps.Isometric;
import luxe.tilemaps.Ortho;
import luxe.importers.tiled.TiledMap;
import luxe.importers.tiled.TiledObjectGroup;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.callbacks.InteractionCallback;
import nape.callbacks.CbType;
import nape.callbacks.CbEvent;
import nape.dynamics.InteractionFilter;
import luxe.Text;

import phoenix.Texture;
import phoenix.geometry.CircleGeometry;

class Entity {
	var texture : Texture;
	public var isPlayer = false;
	public var sprite : Sprite;
	public var body : Body;
	public var isDead = false;

	public function update() {
		this.sprite.transform.pos.set_xy(this.body.position.x, this.body.position.y);
		this.sprite.rotation_z = luxe.utils.Maths.degrees(this.body.rotation);
	}

	public function destroy() {
		this.sprite.destroy();
		Luxe.physics.nape.space.bodies.remove(this.body);
		//EntityFactory.world.debugDraw.remove(this.body);
	}
}

class CollisionLayers {
	public static var PLAYER = new CbType();
	public static var PROJECTILE = new CbType();
	public static var WALL = new CbType();
	public static var ENEMY = new CbType();
	public static var PICKUP = new CbType();
}

class CollisionFilters {
	public static var PLAYER = new InteractionFilter( 		 1, ~(2) );
	public static var PROJECTILE = new InteractionFilter( 	 2, ~(1|16) );
	public static var WALL = new InteractionFilter( 	 	 4, ~(0) );
	public static var ENEMY = new InteractionFilter( 	 	 8, ~(16) );
	public static var PICKUP = new InteractionFilter( 	 	 16, ~(8|2) );
}

class Textures {
	public static var PROJECTILE100;
	public static var PROJECTILE200;
	public static var PROJECTILE500;
	public static var PICKUP100;
	public static var PICKUP200;
	public static var PICKUP500;
	public static var PICKUPCC;
	public static var ENEMY;
	public static var HAPPY;
	public static var MONEYEXPLO;
	public static function Prepare()
	{
		PICKUP100 = Luxe.loadTexture("assets/moneyStack100.png");
		PICKUP200 = Luxe.loadTexture("assets/moneyStack200.png");
		PICKUP500 = Luxe.loadTexture("assets/moneyStack500.png");
		PICKUPCC = Luxe.loadTexture("assets/creditCard.png");
		PROJECTILE100 = Luxe.loadTexture("assets/projectile100.png");
		PROJECTILE200 = Luxe.loadTexture("assets/projectile200.png");
		PROJECTILE500 = Luxe.loadTexture("assets/projectile500.png");
		ENEMY = Luxe.loadTexture("assets/test-enemy.png");
		HAPPY = Luxe.loadTexture("assets/happyBubble.png");
		MONEYEXPLO = Luxe.loadTexture("assets/moneyExplosion.png");
	}
}

class GameWorld {
	public var entities : Array<Entity> = new Array<Entity>();
	public var debugDraw : DebugDraw;
	public function new()
	{
	}
	public function AddEntity( entity : Entity ) {
		this.entities.push(entity);
		entity.body.userData.entity = entity;
		//this.debugDraw.add(entity.body);
	}
	public function Step() {
		for( entity in entities )
		{
			entity.update();
		}
		var toClear:Array<Entity> = new Array<Entity>();
		for( entity in entities )
		{
			if( entity.isDead )
			{
				entity.destroy();
				toClear.push(entity);
			}
		}
		for( i in 0 ... toClear.length )
		{
			entities.remove(toClear[i]);
		}
	}
	public function Clear(removePlayer) {
		for( entity in entities )
		{
			if( !removePlayer && entity.isPlayer ) {}
			else entity.destroy();
		}
		while( entities.length > 0 )
		{
			entities.pop();
		}
	}
}

class EntityFactory {
	static public var world : GameWorld;

	static public function SpawnPlayer() {
		var player = new Player();
		world.AddEntity(player);
		return player;
	}

	static public function SpawnMoneyExplosion(x,y) {
		var texture = Luxe.loadTexture('assets/moneyExplosion.png');
		texture.onload = function(t) {
			var sprite = new Sprite({
				texture: t,
				pos: new Vector(x,y),
				size: new Vector(32,64)
			});
			var animJson = '{
				"explo" : {
					"frame_size" : { "x":"32", "y":"64" },
						"frameset" : [ "1-4" ],
						"loop" : "false",
						"speed" : "12",
						"filter_type" : "nearest"
				}}';
			var anim = new SpriteAnimation({ name: "exploanim" });
			sprite.add(anim);
			anim.add_from_json(animJson);
			anim.restart();
			haxe.Timer.delay(function() {sprite.destroy();}, 1000);
			luxe.tween.Actuate.tween(sprite.color, 1, {a:0});
		};
	}

	static public function SpawnProjectile(x,y, vel:Vector, moneyPerShot:Int, flip:Bool) {
		var vy : Float = 0;
		if( vel.y > 0 ) vy = 0.5;
		else if( vel.y < 0 ) vy = -0.5;
		var proj = new Projectile(new Vector(x,y), vel.x, 0, moneyPerShot, flip);
		world.AddEntity(proj);
		return proj;
	}

	static public function SpawnEnemy(x, y) {
		var enemy = new Enemy(x, y);
		world.AddEntity(enemy);
		return enemy;
	}

	static public function Spawn100EPickup(x, y) {
		var pickup = new Pickup(x,y,Textures.PICKUP100,function(player){
			player.moneyPerShot = 100;
			player.inUseWeapon.destroy();
			player.inUseWeapon = new Sprite({
				texture: Textures.PICKUP100,
				uv: new luxe.Rectangle(0,0,32,32),
				size: new Vector(32,32),
				pos: new Vector(20,20)
			});
		});
		world.AddEntity(pickup);
		return pickup;
	}

	static public function Spawn200EPickup(x, y) {
		var pickup = new Pickup(x,y,Textures.PICKUP200,function(player){
			player.moneyPerShot = 200;
			player.inUseWeapon.destroy();
			player.inUseWeapon = new Sprite({
				texture: Textures.PICKUP200,
				uv: new luxe.Rectangle(0,0,32,32),
				size: new Vector(32,32),
				pos: new Vector(20,20)
			});
		});
		world.AddEntity(pickup);
		return pickup;
	}

	static public function Spawn500EPickup(x, y) {
		var pickup = new Pickup(x,y,Textures.PICKUP500,function(player){
			player.moneyPerShot = 500;
			player.inUseWeapon.destroy();
			player.inUseWeapon = new Sprite({
				texture: Textures.PICKUP500,
				uv: new luxe.Rectangle(0,0,32,32),
				size: new Vector(32,32),
				pos: new Vector(20,20)
			});
		});
		world.AddEntity(pickup);
		return pickup;
	}

	static public function SpawnCreditCardPickup(x, y) {
		var pickup = new Pickup(x,y,Textures.PICKUPCC, function(player){
			player.gotCreditCard = true;
			player.inUseWeapon.destroy();
			player.inUseWeapon = new Sprite({
				texture: Textures.PICKUPCC,
				uv: new luxe.Rectangle(0,0,32,32),
				size: new Vector(32,32),
				pos: new Vector(20,20)
			});
		});
		world.AddEntity(pickup);
		return pickup;
	}

}

enum DoorType {
	LEFT; RIGHT; UP; DOWN;
}

class Door extends Entity {

	var isOpened : Bool;
	var doorType : DoorType;

	public function new(x:Float,y:Float) {
		sprite = new Sprite({
			texture: Luxe.loadTexture("assets/test-door.png"),
			uv: new luxe.Rectangle(0,0,32,32),
			size: new Vector(32,32),
			pos: new Vector(x+16,y+16)
		});
		body = new Body(BodyType.STATIC);
		body.shapes.add(new Polygon(Polygon.rect(x, y, 32, 32)));
		body.space = Luxe.physics.nape.space;
		body.cbTypes.add(CollisionLayers.WALL);
		body.setShapeFilters(CollisionFilters.WALL);
	}

	public function Open() {
		isOpened = true;
		sprite.uv.x = 32;
		body.space = null;
	}

	public function Close() {
		isOpened = false;
		sprite.uv.x = 0;
		body.space = Luxe.physics.nape.space;
	}

}

class Player extends Entity {

	public static var position : Vec2 = new Vec2(0,0);
	public static var damageDealt : Int = 0;
	public var money : Int = 1000000;
	var lastFacing : Vector;
	var facing : Vector = new Vector(1,0);
	var nextShot = 0.0;
	var shotRate = 0.4;
	var speed = 200;
	public var moneyPerShot = 100;
	public var leftCreditCard : Float = haxe.Timer.stamp();
	public var gotCreditCard : Bool = false;

	public var inUseWeapon : Sprite;
	var text : Text;

	public var anim : SpriteAnimation = new SpriteAnimation({ name: 'anim' });

	public function new() {
		isPlayer = true;
		texture = Luxe.loadTexture('assets/player-walk.png');
		sprite = new Sprite({
			name: "player",
			   texture: texture,
			   pos: Luxe.screen.mid,
			   size: new Vector(32,64),

		});

		sprite.add(anim);
		sprite.flipx = true;
		var animJson = '{
			"thiefWalk" : {
				"frame_size" : { "x":"32", "y":"64" },
					"frameset" : [ "1-4" ],
					"loop" : "true",
					"speed" : "12",
					"filter_type" : "nearest"
			},
			"thiefStand" : {
				"frame_size" : { "x":"32", "y":"64" },
					"frameset" : [ "2" ],
					"loop" : "true",
					"speed" : "12",
					"filter_type" : "nearest"
			}
		}';
		anim.add_from_json(animJson);
		anim.animation = "thiefWalk";
		anim.play();

		body = new Body(BodyType.DYNAMIC);
		body.shapes.add(new Circle(16));
		body.position.setxy(200,200);
		body.space = Luxe.physics.nape.space;
		body.cbTypes.add(CollisionLayers.PLAYER);
		body.setShapeFilters(CollisionFilters.PLAYER);

		Luxe.input.bind_key("left", Key.left);
		Luxe.input.bind_key("right", Key.right);
		Luxe.input.bind_key("up", Key.up);
		Luxe.input.bind_key("down", Key.down);
		Luxe.input.bind_key("shoot", Key.key_z);

		// GUI
    	text = new Text({
			pos: new Vector(48,4),
			point_size: 20,
			text: "0€"
		});
		inUseWeapon = new Sprite({
			texture: Textures.PICKUP500,
			uv: new luxe.Rectangle(0,0,32,32),
			size: new Vector(32,32),
			pos: new Vector(20,20)
		});
	}

	override public function update() {

		if( gotCreditCard ) {
			leftCreditCard = haxe.Timer.stamp() + 5.0;
			gotCreditCard = false;
		}
		if( haxe.Timer.stamp() > this.leftCreditCard ) {
			this.shotRate = 0.4;
		} else {
			this.shotRate = 0.05;
		}
    	text.text = money + "€";
    	var doShot = Luxe.input.inputdown("shoot");

		lastFacing = facing;
    	var left:Float = 0;
    	var up:Float = 0;
		if( doShot ) speed = 100;
		else speed = 200;
    	if( Luxe.input.inputdown("up") ) {
    		this.body.velocity.y = -speed * 0.7;
    		up = -0.2;
		} else if( Luxe.input.inputdown("down") ) {
			this.body.velocity.y = speed * 0.7;
    		up = 0.2;
		} else this.body.velocity.y = 0;

		if( Luxe.input.inputdown("left") ) {
			this.body.velocity.x = -speed;
			left = -1;
			if( !doShot ) sprite.flipx = true;
		} else if( Luxe.input.inputdown("right") ) {
			this.body.velocity.x = speed;
			left = 1;
			if( !doShot ) sprite.flipx = false;
		} else this.body.velocity.x = 0;

		if( left == 0 && up == 0 )
		{
			if( anim.animation != "thiefStand" ) {
				anim.animation = "thiefStand";
			}
		}
		else
		{
			if( anim.animation != "thiefWalk" ) {
				anim.animation = "thiefWalk";
			}
			if( !doShot )
			{
				if( left == 0 || facing.x == 0 ) facing.x = lastFacing.x;
				else facing.x = left;
				facing.y = up;
			}
		}

		if( doShot ) {
			if( haxe.Timer.stamp() > this.nextShot ) {
				if( haxe.Timer.stamp() > this.leftCreditCard ) this.money -= this.moneyPerShot;
				this.nextShot = haxe.Timer.stamp() + this.shotRate;
				EntityFactory.SpawnProjectile(this.body.position.x, this.body.position.y, facing, moneyPerShot, sprite.flipx);
			}
		}

		if( Player.damageDealt != 0 ) {
			this.money -= Player.damageDealt;
			Player.damageDealt = 0;
			sprite.color.r = 0;
			sprite.color.b = 0;
			luxe.tween.Actuate.tween(sprite.color, 0.3, {r:1, b:1});
		}
		this.body.rotation = 0;
		super.update();
		Player.position.x = this.body.position.x;
		Player.position.y = this.body.position.y;
	}
}

class Enemy extends Entity {

	var facing : Vector = new Vector(0,0);
	var health : Int = 1000;
	var attackRate : Float = 0.5;
	var attackPower : Int = 10000;
	var nextAttack : Float = haxe.Timer.stamp();
	public static var numEnemiesActive : Int = 0;

	var happySprite : Sprite;

	public function new( x, y ) {
		Enemy.numEnemiesActive = 0;
		texture = Textures.ENEMY;
		sprite = new Sprite({
			texture: texture,
			pos: new Vector(x,y),
			size: new Vector(32,32)
		});

		happySprite = new Sprite({
			texture: Textures.HAPPY,
			pos: new Vector(0,0),
			size: new Vector(32,32)
		});
		happySprite.visible = false;

		happySprite.parent = sprite;

		body = new Body(BodyType.DYNAMIC);
		body.shapes.add(new Circle(16));
		body.position.setxy(x,y);
		body.space = Luxe.physics.nape.space;
		body.cbTypes.add(CollisionLayers.ENEMY);
		body.setShapeFilters(CollisionFilters.ENEMY);

	}

	var speedx = 150;
	var speedy = 120;
	var finalVelocity : Vec2 = new Vec2(0,0);
	override public function update() {
		this.body.rotation = 0;

		if( health > 0 ) {
			var ray = nape.geom.Ray.fromSegment(body.position, Player.position);
			ray.maxDistance = 500;
			var rayResult = Luxe.physics.nape.space.rayCast(ray);
			var playerInSight = false;
			if( rayResult != null ) {
				if( rayResult.shape.filter == CollisionFilters.PLAYER ) {
					playerInSight = true;
				}
			}
			if( playerInSight ) {
				finalVelocity.x = this.body.position.x - Player.position.x;
				finalVelocity.y = this.body.position.y - Player.position.y;
				this.body.velocity = finalVelocity.normalise();
				this.body.velocity.x = -this.body.velocity.x * speedx;
				this.body.velocity.y = -this.body.velocity.y * speedy;
			} else {
				this.body.velocity.x = 0;
				this.body.velocity.y = 0;
			}

			var playerNear = false;
			ray = nape.geom.Ray.fromSegment(body.position, Player.position);
			ray.maxDistance = 40;
			rayResult = Luxe.physics.nape.space.rayCast(ray);
			if( rayResult != null ) {
				if( rayResult.shape.filter == CollisionFilters.PLAYER ) {
					playerNear = true;
				}
			}
			if( playerNear && nextAttack < haxe.Timer.stamp() ) {
				Player.damageDealt += attackPower;
				nextAttack = haxe.Timer.stamp() + attackRate;
				EntityFactory.SpawnMoneyExplosion(Player.position.x, Player.position.y);
			}
		}
		else
		{
			body.velocity.x *= 0.95;
			body.velocity.y *= 0.95;
			happySprite.visible = true;
		}

		super.update();
	}
}

class Pickup extends Entity {

	public var cb : Player -> Void;
	public function new( x, y, tex : Texture, cb : Player -> Void ) {
		texture = tex;
		sprite = new Sprite({
			texture: texture,
			pos: new Vector(x,y),
			size: new Vector(32,32)
		});

		body = new Body(BodyType.DYNAMIC);
		body.shapes.add(new Circle(16));
		body.position.setxy(x,y);
		body.space = Luxe.physics.nape.space;
		body.cbTypes.add(CollisionLayers.PICKUP);
		body.setShapeFilters(CollisionFilters.PICKUP);
		this.cb = cb;
	}

}

class Projectile extends Entity {

	var projectileSpeed = 500;
	public var power:Int;

	public function new( pos : Vector, velx : Float, vely : Float, moneyPerShot:Int, flip:Bool ) {
		if( moneyPerShot == 100 ) texture = Textures.PROJECTILE100;
		if( moneyPerShot == 200 ) texture = Textures.PROJECTILE200;
		if( moneyPerShot == 500 ) texture = Textures.PROJECTILE500;
		power = moneyPerShot;
		sprite = new Sprite({
			   texture: texture,
			   pos: pos,
			   size: new Vector(32,32),
		});
		sprite.flipx = flip;
		body = new Body(BodyType.DYNAMIC);
		body.shapes.add(new Polygon(Polygon.rect(-2,-2,8,4)));
		body.position.setxy(pos.x, pos.y);
		body.space = Luxe.physics.nape.space;
		body.cbTypes.add(CollisionLayers.PROJECTILE);
		body.setShapeFilters(CollisionFilters.PROJECTILE);
		body.velocity.x = velx * projectileSpeed;
		body.velocity.y = vely * projectileSpeed;
	}

	override public function update() {
		super.update();
	}
}
