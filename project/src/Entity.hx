
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

import phoenix.Texture;
import phoenix.geometry.CircleGeometry;

class Entity {
	var texture : Texture;
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
	public static var PROJECTILE;
	public static var PICKUP;
	public static var ENEMY;
	public static function Prepare()
	{
		PICKUP = Luxe.loadTexture("assets/test-money-pickup.png");
		PROJECTILE = Luxe.loadTexture("assets/test-dollar.png");
		ENEMY = Luxe.loadTexture("assets/test-enemy.png");
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
	public function Clear() {
		for( entity in entities )
		{
			entity.destroy();
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

	static public function SpawnProjectile(x,y, vel:Vector) {
		var proj = new Projectile(new Vector(x,y), vel);
		world.AddEntity(proj);
		return proj;
	}

	static public function SpawnEnemy(x, y) {
		var enemy = new Enemy(x, y);
		world.AddEntity(enemy);
		return enemy;
	}

	static public function Spawn100EPickup(x, y) {
		var pickup = new Pickup(x,y,Textures.PICKUP,function(player){
			player.money += 100;
		});
		world.AddEntity(pickup);
		return pickup;
	}
}

class Door extends Entity {

	var isOpened : Bool;

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

	public var money : Int;
	var lastFacing : Vector;
	var facing : Vector = new Vector(1,0);
	var nextShot = 0.0;
	var shotRate = 0.4;
	var speed = 200;

	public function new() {
		texture = Luxe.loadTexture('assets/test-player.png');
		sprite = new Sprite({
			name: "player",
			texture: texture,
			pos: Luxe.screen.mid,
			size: new Vector(32,32)
		});

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
	}

	override public function update() {
		lastFacing = facing;
    	var left:Float = 0;
    	var up:Float = 0;
    	if( Luxe.input.inputdown("up") ) {
    		this.body.velocity.y = -speed;
    		up = -1;
		} else if( Luxe.input.inputdown("down") ) {
			this.body.velocity.y = speed;
    		up = 1;
		} else this.body.velocity.y = 0;

    	if( Luxe.input.inputdown("left") ) {
    		this.body.velocity.x = -speed;
    		left = -1;
		} else if( Luxe.input.inputdown("right") ) {
			this.body.velocity.x = speed;
			left = 1;
		} else this.body.velocity.x = 0;

		if( left == 0 && up == 0 )
		{
		}
		else
		{
			facing.x = left;
			facing.y = up;
		}

		if( Luxe.input.inputdown("shoot") ) {
			if( haxe.Timer.stamp() > this.nextShot ) {
				this.nextShot = haxe.Timer.stamp() + this.shotRate;
				EntityFactory.SpawnProjectile(this.body.position.x, this.body.position.y, facing);
			}
		}

		this.body.rotation = 0;
		super.update();
	}
}

class Enemy extends Entity {

	var facing : Vector = new Vector(0,0);

	public function new( x, y ) {
		texture = Textures.ENEMY;
		sprite = new Sprite({
			name: "enemy",
			texture: texture,
			pos: new Vector(x,y),
			size: new Vector(32,32)
		});

		body = new Body(BodyType.DYNAMIC);
		body.shapes.add(new Circle(16));
		body.position.setxy(x,y);
		body.space = Luxe.physics.nape.space;
		body.cbTypes.add(CollisionLayers.ENEMY);
		body.setShapeFilters(CollisionFilters.ENEMY);

	}

	override public function update() {
		this.body.rotation = 0;
		super.update();
	}
}

class Pickup extends Entity {

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
	}

}

class Projectile extends Entity {

	var projectileSpeed = 500;

	public function new( pos : Vector, vel : Vector ) {
		texture = Textures.PROJECTILE;
		sprite = new Sprite({
			   texture: texture,
			   pos: pos,
			   size: new Vector(8,4),
		});
		body = new Body(BodyType.DYNAMIC);
		body.shapes.add(new Polygon(Polygon.rect(-2,-2,8,4)));
		body.position.setxy(pos.x, pos.y);
		body.space = Luxe.physics.nape.space;
		body.cbTypes.add(CollisionLayers.PROJECTILE);
		body.setShapeFilters(CollisionFilters.PROJECTILE);
		body.velocity.x = vel.x * projectileSpeed;
		body.velocity.y = vel.y * projectileSpeed;
	}

	override public function update() {
		super.update();
	}
}
