
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

	var texTorso : Texture;
	public var sprite : Sprite;

	public function new() {}

	public function Prepare() {
		texTorso = Luxe.loadTexture('assets/test-player.png');
		sprite = new Sprite({
			name: "player",
			texture: texTorso,
			pos: Luxe.screen.mid,
			size: new Vector(32,32)
		});
	}

}

class Main extends luxe.Game {

	public var tilemap : TiledMap;
	public var tileBatcher : phoenix.Batcher;
	var entityBatcher : phoenix.Batcher;
	var player : Player;
	public var drawer : DebugDraw;
	var playerBody : Body;
	var interactionListener : InteractionListener;
	var playerCollision : CbType = new CbType();
	var wallCollision : CbType = new CbType();

	public function playerToWall( collision: InteractionCallback ):Void {
		trace("HEY!");
	}

    override function ready() {
    	drawer = new DebugDraw();
    	Luxe.physics.nape.debugdraw = drawer;
		Luxe.renderer.clear_color = new Color().rgb(0xaf663a);
		interactionListener = new nape.callbacks.InteractionListener(
				CbEvent.BEGIN,
				InteractionType.COLLISION,
				wallCollision,
				playerCollision,
				playerToWall);
		Luxe.physics.nape.space.listeners.add(interactionListener);
		var that = this;
		tileBatcher = Luxe.renderer.create_batcher({ layer: 0 });
		entityBatcher = Luxe.renderer.create_batcher({ layer: 2 });
		Luxe.loadText('assets/test-map.json', function(res) {
			that.tilemap = new TiledMap({ tiled_file_data: res.text, format: 'json', pos: new Vector(0,0) });
			that.tilemap.display({ batcher: that.tileBatcher, scale:1, grid:false, filter:FilterType.nearest });

			var themap:Array<Array<Int>> = new Array<Array<Int>>();
			for( tilearray in that.tilemap.layers.get("baseLayer").tiles )
			{
				var col:Array<Int> = new Array<Int>();
				for( tile in tilearray )
				{
					if( tile.id == 1 ) col.push(1);
					else col.push(0);
				}
				themap.push(col);
			}
			var strmap:String = "";
			for( i in 0 ... themap.length )
			{
				for( j in 0 ... themap[i].length )
				{
					if( themap[i][j] != 0 )
					{
						var b = new Body(BodyType.STATIC);
						b.shapes.add(new Polygon(Polygon.rect(j*32, i*32, 32, 32)));
						b.space = Luxe.physics.nape.space;
						b.cbTypes.add(wallCollision);
						that.drawer.add(b);
					}
					strmap += themap[i][j];
				}
				strmap += "\n";
			}
			trace(strmap);
		});

    	player = new Player();
    	player.Prepare();

		playerBody = new Body(BodyType.DYNAMIC);
		playerBody.shapes.add(new Circle(16));
		playerBody.position.setxy(200,200);
		playerBody.space = Luxe.physics.nape.space;
		playerBody.cbTypes.add(playerCollision);
		drawer.add(playerBody);
		Luxe.physics.nape.space.gravity.x = 0;
		Luxe.physics.nape.space.gravity.y = 0;
		//var collisionLayer = tilemap.layers.get("collisionLayer");

    } //ready

    override function onkeyup( e:KeyEvent ) {

        if(e.keycode == Key.escape) {
            Luxe.shutdown();
        }

        switch(e.keycode)
		{
			case Key.up: up=false;
			case Key.down: down=false;
			case Key.left: left=false;
			case Key.right: right=false;
		}

    } //onkeyup

	var left: Bool;
	var right: Bool;
	var up: Bool;
	var down: Bool;
    override function onkeydown( e:KeyEvent ) {

        switch(e.keycode)
		{
			case Key.up: up=true;
			case Key.down: down=true;
			case Key.left: left=true;
			case Key.right: right=true;
		}


    } //onkeydown

    override function update(dt:Float) {
    	var speed = 100;

    	if( up ) playerBody.velocity.y = -speed;
    	else if( down ) playerBody.velocity.y = speed;
    	else playerBody.velocity.y = 0;

    	if( left ) playerBody.velocity.x = -speed;
    	else if( right ) playerBody.velocity.x = speed;
    	else playerBody.velocity.x = 0;
		player.sprite.transform.pos.set_xy(playerBody.position.x, playerBody.position.y);
    } //update


} //Main
