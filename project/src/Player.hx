
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

class Player {

	var texPlayer : Texture;
	public var sprite : Sprite;
	public var body : Body;

	public function new() {}

	public function Prepare( playerCollision : CbType ) {
		texPlayer = Luxe.loadTexture('assets/test-player.png');
		sprite = new Sprite({
			name: "player",
			texture: texPlayer,
			pos: Luxe.screen.mid,
			size: new Vector(32,32)
		});

		body = new Body(BodyType.DYNAMIC);
		body.shapes.add(new Circle(16));
		body.position.setxy(200,200);
		body.space = Luxe.physics.nape.space;
		body.cbTypes.add(playerCollision);

		Luxe.input.bind_key("left", Key.left);
		Luxe.input.bind_key("right", Key.right);
		Luxe.input.bind_key("up", Key.up);
		Luxe.input.bind_key("down", Key.down);
	}

	public function update() {
    	var speed = 100;

    	if( Luxe.input.inputdown("up") ) this.body.velocity.y = -speed;
    	else if( Luxe.input.inputdown("down") ) this.body.velocity.y = speed;
    	else this.body.velocity.y = 0;

    	if( Luxe.input.inputdown("left") ) this.body.velocity.x = -speed;
    	else if( Luxe.input.inputdown("right") ) this.body.velocity.x = speed;
    	else this.body.velocity.x = 0;

		this.sprite.transform.pos.set_xy(this.body.position.x, this.body.position.y);
	}
}

