
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

import phoenix.Texture;
import phoenix.geometry.CircleGeometry;

class Entity {
	var texture : Texture;
	public var sprite : Sprite;
	public var body : Body;

	public function update() {
		this.sprite.transform.pos.set_xy(this.body.position.x, this.body.position.y);
		this.sprite.rotation_z = luxe.utils.Maths.degrees(this.body.rotation);
	}
}

class CollisionLayers {
	public static var PLAYER = new CbType();
	public static var PROJECTILE = new CbType();
	public static var WALL = new CbType();
}

class GameWorld {
	var entities : Array<Entity> = new Array<Entity>();
	public var debugDraw : DebugDraw;
	public function new()
	{
	}
	public function AddEntity( entity : Entity ) {
		this.entities.push(entity);
		this.debugDraw.add(entity.body);
	}
	public function Step() {
		for( entity in entities )
		{
			entity.update();
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

	static public function SpawnProjectile(x,y) {
		var proj = new Projectile();
		proj.Prepare(new Vector(x,y));
		world.AddEntity(proj);
		return proj;
	}
}

class Player extends Entity {

	public function new() {}

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

		Luxe.input.bind_key("left", Key.left);
		Luxe.input.bind_key("right", Key.right);
		Luxe.input.bind_key("up", Key.up);
		Luxe.input.bind_key("down", Key.down);
	}

	override public function update() {
    	var speed = 100;

    	if( Luxe.input.inputdown("up") ) this.body.velocity.y = -speed;
    	else if( Luxe.input.inputdown("down") ) this.body.velocity.y = speed;
    	else this.body.velocity.y = 0;

    	if( Luxe.input.inputdown("left") ) this.body.velocity.x = -speed;
    	else if( Luxe.input.inputdown("right") ) this.body.velocity.x = speed;
    	else this.body.velocity.x = 0;

		super.update();
	}
}

class Projectile extends Entity {

	public function new() {}

	public function Prepare( pos : Vector ) {
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
	}

	override public function update() {
		super.update();
	}
}
