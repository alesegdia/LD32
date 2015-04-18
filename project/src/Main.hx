
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
import Entity.Player;
import Entity.Projectile;
import Entity.GameWorld;
import Entity.EntityFactory;
import Entity.CollisionLayers;

class Main extends luxe.Game {

	public var tilemap : TiledMap;
	public var tileBatcher : phoenix.Batcher;
	var entityBatcher : phoenix.Batcher;
	var player : Player;
	var interactionListener : InteractionListener;
	var proj : Projectile;
	var gameWorld : GameWorld;
	var drawer : DebugDraw;

	public function playerToWall( collision: InteractionCallback ):Void {
		trace("HEY!");
	}

    override function ready() {
		drawer = new DebugDraw();
		gameWorld = new GameWorld();
		EntityFactory.world = gameWorld;
		gameWorld.debugDraw = drawer;
    	Luxe.physics.nape.debugdraw = gameWorld.debugDraw;
		Luxe.renderer.clear_color = new Color().rgb(0xaf663a);

    	player = EntityFactory.SpawnPlayer();

		interactionListener = new nape.callbacks.InteractionListener(
				CbEvent.BEGIN,
				InteractionType.COLLISION,
				CollisionLayers.WALL,
				CollisionLayers.PLAYER,
				playerToWall);
		Luxe.physics.nape.space.listeners.add(interactionListener);
		Luxe.physics.nape.space.gravity.x = 0;
		Luxe.physics.nape.space.gravity.y = 0;

		var that = this;
		tileBatcher = Luxe.renderer.create_batcher({ layer: 0 });
		entityBatcher = Luxe.renderer.create_batcher({ layer: 2 });
		Luxe.loadText('assets/test-map.json', function(res) {
			tilemap = new TiledMap({ tiled_file_data: res.text, format: 'json', pos: new Vector(0,0) });
			tilemap.display({ batcher: tileBatcher, scale:1, grid:false, filter:FilterType.nearest });

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
						b.cbTypes.add(CollisionLayers.WALL);
						EntityFactory.world.debugDraw.add(b);
					}
					strmap += themap[i][j];
				}
				strmap += "\n";
			}
			trace(strmap);
		});

		EntityFactory.SpawnProjectile(100,100);
    } //ready

    override function onkeyup( e:KeyEvent ) {

        if(e.keycode == Key.escape) {
            Luxe.shutdown();
        }

    } //onkeyup

    override function update(dt:Float) {
    	gameWorld.Step();
    } //update


} //Main
