
import luxe.Input;

import nape.geom.Vec2;
import nape.phys.Body;
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

enum Facing {
	LEFT; RIGHT; UP; DOWN;
}

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
		EntityFactory.world.debugDraw.remove(this.body);
	}
}

class CollisionLayers {
	public static var PLAYER = new CbType();
	public static var PROJECTILE = new CbType();
	public static var WALL = new CbType();
}

class CollisionFilters {
	public static var PLAYER = new InteractionFilter( 		 1, ~(2) );
	public static var PROJECTILE = new InteractionFilter( 	 2, ~(1) );
	public static var WALL = new InteractionFilter( 	 	 4, ~(0) );
}

class GameWorld {
	var entities : Array<Entity> = new Array<Entity>();
	public var debugDraw : DebugDraw;
	public function new()
	{
	}
	public function AddEntity( entity : Entity ) {
		this.entities.push(entity);
		entity.body.userData.entity = entity;
		this.debugDraw.add(entity.body);
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
}

class EntityFactory {
	static public var world : GameWorld;

	static public function SpawnPlayer() {
		var player = new Player();
		player.Prepare();
		world.AddEntity(player);
		return player;
	}

	static public function SpawnProjectile(x,y, facing:Facing) {
		var proj = new Projectile();
		proj.Prepare(new Vector(x,y), facing);
		world.AddEntity(proj);
		return proj;
	}
}

class Player extends Entity {

	public function new() {}
	var facing : Facing = Facing.LEFT;
	var nextShot = 0.0;
	var shotRate = 0.4;

	public function Prepare() {
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
    	var speed = 100;
    	if( Luxe.input.inputdown("up") ) {
    		this.body.velocity.y = -speed;
    		this.facing = Facing.UP;
		} else if( Luxe.input.inputdown("down") ) {
			this.body.velocity.y = speed;
    		this.facing = Facing.DOWN;
		} else this.body.velocity.y = 0;

    	if( Luxe.input.inputdown("left") ) {
    		this.body.velocity.x = -speed;
    		this.facing = Facing.LEFT;
		} else if( Luxe.input.inputdown("right") ) {
			this.body.velocity.x = speed;
    		this.facing = Facing.RIGHT;
		} else this.body.velocity.x = 0;

		if( Luxe.input.inputdown("shoot") ) {
			if( haxe.Timer.stamp() > this.nextShot ) {
				this.nextShot = haxe.Timer.stamp() + this.shotRate;
				EntityFactory.SpawnProjectile(this.body.position.x, this.body.position.y, facing);
			}
		}

		super.update();
	}
}

class Projectile extends Entity {

	var projectileSpeed = 500;

	public function new() {}

	public function Prepare( pos : Vector, facing : Facing ) {
		texture = Luxe.loadTexture('assets/test-dollar.png');
		sprite = new Sprite({
			name: "dollar",
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
		switch( facing ) {
		case Facing.LEFT: body.velocity.x = -projectileSpeed;
		case Facing.RIGHT: body.velocity.x = projectileSpeed;
		case Facing.UP: body.velocity.y = -projectileSpeed; body.rotation = luxe.utils.Maths.radians(90);
		case Facing.DOWN: body.velocity.y = projectileSpeed; body.rotation = luxe.utils.Maths.radians(90);
		}
	}

	override public function update() {
		super.update();
	}
}
