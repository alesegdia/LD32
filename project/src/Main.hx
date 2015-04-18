
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
import luxe.tilemaps.Tilemap.TileLayer;

import phoenix.Texture;
import phoenix.geometry.CircleGeometry;
import Entity.Player;
import Entity.Projectile;
import Entity.GameWorld;
import Entity.EntityFactory;
import Entity.CollisionLayers;
import Entity.CollisionFilters;
import Entity.Textures;

class Main extends luxe.Game {

	public var tilemap : TiledMap;
	public var tileBatcher : phoenix.Batcher;
	var entityBatcher : phoenix.Batcher;
	var player : Player;
	var proj : Projectile;
	var gameWorld : GameWorld;
	var drawer : DebugDraw;
	var doorList : Array<Vector> = new Array<Vector>();
	var enemySpawnList : Array<Vector> = new Array<Vector>();
	var pickupSpawnList : Array<Vector> = new Array<Vector>();

	public function projToWall( collision: InteractionCallback ):Void {
		collision.int1.userData.entity.isDead = true;
	}

	public function AddInteractionListener( type1 : CbType, type2 : CbType, cb : InteractionCallback -> Void )
	{
		var il = new nape.callbacks.InteractionListener(
				CbEvent.BEGIN,
				InteractionType.COLLISION,
				type1, type2, cb);
		Luxe.physics.nape.space.listeners.add(il);
	}

	public function TiledLayerToMatrix( tiledLayer : TileLayer ) {
		var themap:Array<Array<Int>> = new Array<Array<Int>>();
		for( tilearray in tiledLayer.tiles )
		{
			var col:Array<Int> = new Array<Int>();
			for( tile in tilearray )
			{
				col.push(tile.id);
			}
			themap.push(col);
		}
		return themap;
	}


	public function GetNonEmptyTiles( tiledLayer : TileLayer ) {
		var map = TiledLayerToMatrix( tiledLayer );
		var tiles : Array<Vector> = new Array<Vector>();
		for( i in 0 ... map.length ) {
			for( j in 0 ... map[i].length ) {
				if( map[i][j] != 0 ) {
					tiles.push(new Vector(j, i));
				}
			}
		};
		return tiles;
	}

	public function RandomRange( a, b ) {
		return (b-a) * Math.random() + a;
	}

	public function SpawnRandomEnemy() {
		var n:Int = Math.round(RandomRange(0, enemySpawnList.length));
		trace(enemySpawnList);
		var e = enemySpawnList[n];
		EntityFactory.SpawnEnemy(e.x*32+16, e.y*32+16);
	}

	public function SpawnRandomPickup() {
		var n:Int = Math.round(RandomRange(0, pickupSpawnList.length));
		var e = pickupSpawnList[n];
		EntityFactory.Spawn100EPickup(e.x*32+16, e.y*32+16);
	}

	public function DebugLayer( layer : TileLayer ) {
		var themap = TiledLayerToMatrix(layer);
		var str = "";
		for( i in 0 ... themap.length ) {
			for( j in 0 ... themap[i].length ) {
				str += themap[i];
			}
			str += "\n";
		}
		trace(str);
	}

	public function RegenScene() {
		gameWorld.Clear();
		SpawnRandomEnemy();
		SpawnRandomPickup();
    	player = EntityFactory.SpawnPlayer();
	}

    override function ready() {
    	Textures.Prepare();
		drawer = new DebugDraw();
		gameWorld = new GameWorld();
		EntityFactory.world = gameWorld;
		//gameWorld.debugDraw = drawer;
    	//Luxe.physics.nape.debugdraw = gameWorld.debugDraw;
		Luxe.renderer.clear_color = new Color().rgb(0xaf663a);

    	EntityFactory.SpawnEnemy(300,300);
    	EntityFactory.Spawn100EPickup(400,400);

		AddInteractionListener( CollisionLayers.PROJECTILE, CollisionLayers.WALL, projToWall );
		AddInteractionListener( CollisionLayers.PICKUP, CollisionLayers.PLAYER, function(collision:InteractionCallback) {
			collision.int1.userData.entity.isDead = true;
		});

		Luxe.physics.nape.space.gravity.x = 0;
		Luxe.physics.nape.space.gravity.y = 0;

		var that = this;
		tileBatcher = Luxe.renderer.create_batcher({ layer: 0 });
		entityBatcher = Luxe.renderer.create_batcher({ layer: 2 });
		Luxe.loadText('assets/test-map.json', function(res) {
			tilemap = new TiledMap({ tiled_file_data: res.text, format: 'json', pos: new Vector(0,0) });
			tilemap.display({ batcher: tileBatcher, scale:1, grid:false, filter:FilterType.nearest });
			var themap = that.TiledLayerToMatrix(that.tilemap.layers.get("collisionLayer"));
			for( i in 0 ... themap.length ) {
				for( j in 0 ... themap[i].length ) {
					if( themap[i][j] != 0 ) {
						var b = new Body(BodyType.STATIC);
						b.shapes.add(new Polygon(Polygon.rect(j*32, i*32, 32, 32)));
						b.space = Luxe.physics.nape.space;
						b.cbTypes.add(CollisionLayers.WALL);
						b.setShapeFilters(CollisionFilters.WALL);
						//EntityFactory.world.debugDraw.add(b);
					}}}

			DebugLayer(that.tilemap.layers.get("enemySpawnLayer"));
			doorList = GetNonEmptyTiles(that.tilemap.layers.get("doorLayer"));
			enemySpawnList = GetNonEmptyTiles(that.tilemap.layers.get("enemySpawnLayer"));
			pickupSpawnList = GetNonEmptyTiles(that.tilemap.layers.get("pickupSpawnLayer"));
			that.RegenScene();
		});

    } //ready

    override function onkeyup( e:KeyEvent ) {

        if(e.keycode == Key.escape) {
            Luxe.shutdown();
        }
        if( e.keycode == Key.key_k) {
			RegenScene();
		}

    } //onkeyup

    override function update(dt:Float) {
    	gameWorld.Step();
    } //update


} //Main
