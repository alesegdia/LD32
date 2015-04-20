
import luxe.Input;

import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.constraint.PivotJoint;

import luxe.AppConfig;
import luxe.Parcel;
import luxe.ParcelProgress;
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
import phoenix.Camera;
import phoenix.geometry.CircleGeometry;
import Entity.Player;
import Entity.Enemy;
import Entity.Door;
import Entity.Pickup;
import Entity.Projectile;
import Entity.GameWorld;
import Entity.EntityFactory;
import Entity.CollisionLayers;
import Entity.CollisionFilters;
import Entity.Textures;
import Entity.Cajero;

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

	var upDoorTiles : Array<Door> = new Array<Door>();
	var downDoorTiles : Array<Door> = new Array<Door>();
	var leftDoorTiles : Array<Door> = new Array<Door>();
	var rightDoorTiles : Array<Door> = new Array<Door>();

	var camera : Camera;

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
		var n:Int = Math.round(RandomRange(0, enemySpawnList.length-1));
		var e = enemySpawnList[n];
		EntityFactory.SpawnEnemy(e.x*32+16, e.y*32+16);
	}

	public function SpawnRandomPickup() {
		var n:Int = Math.round(RandomRange(0, pickupSpawnList.length-1));
		var e = pickupSpawnList[n];
		var r = Math.random();
		if( r < 0.5 ) EntityFactory.Spawn100EPickup(e.x*32+16, e.y*32+16);
		else if( r < 0.75 ) EntityFactory.Spawn200EPickup(e.x*32+16, e.y*32+16);
		else if( r < 0.9 ) EntityFactory.Spawn500EPickup(e.x*32+16, e.y*32+16);
		else EntityFactory.SpawnCreditCardPickup(e.x*32+16, e.y*32+16);
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

	public function OpenDoors( doors : Array<Door> ) {
		for( i in 0 ... doors.length ) {
			doors[i].Open();
		}
	}
	public function CloseDoors( doors : Array<Door> ) {
		for( i in 0 ... doors.length ) {
			doors[i].Close();
		}
	}

	public function CloseAllDoors() {
		CloseDoors(rightDoorTiles);
		CloseDoors(leftDoorTiles);
		CloseDoors(upDoorTiles);
		CloseDoors(downDoorTiles);
		doorsClosed = true;
	}

	public function OpenAllDoors() {
		doorsClosed = false;
		OpenDoors(rightDoorTiles);
		OpenDoors(leftDoorTiles);
		OpenDoors(upDoorTiles);
		OpenDoors(downDoorTiles);
	}

	var cajeroComing:Bool = false;
	public function RegenScene( createPlayer : Bool ) {
		wasOpened = false;
		cajero.Hide();
		cajeroComing = false;
		gameWorld.Clear(createPlayer);
		Enemy.numEnemiesActive = 0;
		SpawnRandomEnemy();
		if( Math.random() < 0.70 ) SpawnRandomPickup();
    	if( createPlayer )
		{
			player = EntityFactory.SpawnPlayer();
			currentRoom = 0;
		} else {
			gameWorld.AddEntity(player);
			currentRoom += 1;
		}
	}

	var indicators : Array<Dynamic> = new Array<Dynamic>();
	public function DispatchIndicators() {
		for( i in 0 ... indicators.length ) {
			EntityFactory.SpawnIndicator(indicators[i].entity.body.position.x, indicators[i].entity.body.position.y, indicators[i].text);
		}
		while( indicators.length > 0 ) {
			indicators.pop();
		}
	}

	var currentRoom : Int = 0;
    override function ready() {
		tileBatcher = Luxe.renderer.create_batcher({ layer: 0 });
		entityBatcher = Luxe.renderer.create_batcher({ layer: 2 });
		Entity.batcher = entityBatcher;

		AddInteractionListener( CollisionLayers.PROJECTILE, CollisionLayers.WALL, projToWall );
		AddInteractionListener( CollisionLayers.PROJECTILE, CollisionLayers.ENEMY, function(collision:InteractionCallback){
			var proj = cast(collision.int1.userData.entity);
			var enem = cast(collision.int2.userData.entity);
			EntityFactory.SpawnIndicator(collision.int1.castBody.position.x, collision.int1.castBody.position.y, cast(proj.power,Int));
			enem.sprite.color.r = 0;
			enem.sprite.color.b = 0;
			luxe.tween.Actuate.tween(enem.sprite.color, 0.3, {r:1, b:1});
			proj.isDead = true;
			shakeAmount += 10;
			if( enem.health > 0 ) {
				enem.health = enem.health - proj.power;
				if( enem.health <= 0 ) {
					Enemy.numEnemiesActive -= 1;
				}
			}
		});
		AddInteractionListener( CollisionLayers.PICKUP, CollisionLayers.PLAYER, function(collision:InteractionCallback) {
			collision.int1.userData.entity.isDead = true;
			(cast(collision.int1.userData.entity, Pickup)).cb(player);
		});

		Luxe.physics.nape.space.gravity.x = 0;
		Luxe.physics.nape.space.gravity.y = 0;
		Luxe.loadJSON('assets/parcel.json', function(json_asset) {

			var preload = new Parcel();
			preload.from_json(json_asset.json);
			new ParcelProgress({
				parcel: preload,
				background: new Color(1,0.5,0.25,1),
				oncomplete: function(_) {

					Textures.Prepare();
					drawer = new DebugDraw();
					gameWorld = new GameWorld();
					EntityFactory.world = gameWorld;
					//gameWorld.debugDraw = drawer;
					//Luxe.physics.nape.debugdraw = gameWorld.debugDraw;
					Luxe.renderer.clear_color = new Color().rgb(0xaf663a);

					camera = new Camera();
					tileBatcher.view = camera;
					entityBatcher.view = camera;
					Luxe.renderer.add_batch(tileBatcher);
					Luxe.renderer.add_batch(entityBatcher);

					var that = this;
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
						trace(doorList.length);
						for( i in 0 ... doorList.length ) {
							var v = doorList[i];
							if( v.x == 0 && v.y != 0 ) leftDoorTiles.push(new Door(v.x*32, v.y*32));
							else if( v.x == that.tilemap.width-1 ) rightDoorTiles.push(new Door(v.x*32, v.y*32));
							else if( v.y != 0 && v.x != that.tilemap.width ) upDoorTiles.push(new Door(v.x*32, v.y*32));
							else downDoorTiles.push( new Door(v.x*32, v.y*32) );
						}
						enemySpawnList = GetNonEmptyTiles(that.tilemap.layers.get("enemySpawnLayer"));
						pickupSpawnList = GetNonEmptyTiles(that.tilemap.layers.get("pickupSpawnLayer"));
						that.RegenScene(true);
						CloseAllDoors();
						okgo = true;
					});
					cajero = new Cajero(320,320);
					//gameWorld.AddEntity(cajero);
					trace("FINISH LOAD!");
				}});

			preload.load();
		});

    } //ready

	var okgo = false;
	function CheckWarp() {
		if( !doorsClosed ) {
			var dist = luxe.Vector.Subtract(rightDoorTiles[0].sprite.transform.pos, player.sprite.transform.pos).length;
			if( dist < 10 ) {
				RegenScene(false);
				trace(leftDoorTiles[0].body.position);
				player.body.position.x = 40;
				player.body.position.y = Luxe.screen.h/2;
				CloseAllDoors();
			} else {
			dist = luxe.Vector.Subtract(rightDoorTiles[1].sprite.transform.pos, player.sprite.transform.pos).length;
			if( dist < 10 ) {
				RegenScene(false);
				trace(leftDoorTiles[0].body.position);
				player.body.position.x = 40;
				player.body.position.y = Luxe.screen.h/2;
				CloseAllDoors();
			}
			}

			dist = luxe.Vector.Subtract(leftDoorTiles[0].sprite.transform.pos, player.sprite.transform.pos).length;
			if( dist < 32 ) {
				RegenScene(false);
				player.body.position.x = tilemap.width*32 - 40;
				player.body.position.y = Luxe.screen.h/2;
				CloseAllDoors();
			} else {
			dist = luxe.Vector.Subtract(leftDoorTiles[1].sprite.transform.pos, player.sprite.transform.pos).length;
			if( dist < 32 ) {
				RegenScene(false);
				player.body.position.x = tilemap.width*32 - 40;
				player.body.position.y = Luxe.screen.h/2;
				CloseAllDoors();
			}
			}

			dist = luxe.Vector.Subtract(upDoorTiles[0].sprite.transform.pos, player.sprite.transform.pos).length;
			if( dist < 32) {
				RegenScene(false);
				player.body.position.x = tilemap.width*32/2;
				player.body.position.y = 54;
				CloseAllDoors();
			} else {
			dist = luxe.Vector.Subtract(upDoorTiles[1].sprite.transform.pos, player.sprite.transform.pos).length;
			if( dist < 32 ) {
				RegenScene(false);
				player.body.position.x = tilemap.width*32/2;
				player.body.position.y = 54;
				CloseAllDoors();
			}
			}

			dist = luxe.Vector.Subtract(downDoorTiles[0].sprite.transform.pos, player.sprite.transform.pos).length;
			if( dist < 32 ) {
				RegenScene(false);
				player.body.position.x = tilemap.width*32/2;
				player.body.position.y = Luxe.screen.h - 54;
				CloseAllDoors();
			} else {
			dist = luxe.Vector.Subtract(downDoorTiles[1].sprite.transform.pos, player.sprite.transform.pos).length;
			if( dist < 32 ) {
				RegenScene(false);
				player.body.position.x = tilemap.width*32/2;
				player.body.position.y = Luxe.screen.h - 54;
				CloseAllDoors();
			}
			}
		}
	}

	var doorsClosed = true;
    override function onkeyup( e:KeyEvent ) {

        if(e.keycode == Key.escape) {
            Luxe.shutdown();
        }
        if( e.keycode == Key.key_k) {
			RegenScene(false);
		}
        if( e.keycode == Key.key_j) {
        	doorsClosed = !doorsClosed;
        	if( !doorsClosed ) {
        		OpenAllDoors();
			} else {
				CloseAllDoors();
			}
		}
		if( e.keycode == Key.key_p) {
			SpawnRandomEnemy();
		}

    } //onkeyup

	var cajero:Cajero;
	var wasOpened:Bool = false;
	var shakeAmount:Float = 10;

	function ShakeCam(howMuch:Float) {
		camera.pos.x = (Math.random()-0.5) * 2 * howMuch;
		camera.pos.y = (Math.random()-0.5) * 2 * howMuch;
	}

    override function update(dt:Float) {
		if( okgo ){
			ShakeCam(shakeAmount);
			shakeAmount *= 0.90;
			gameWorld.Step();
			CheckWarp();
			if( Enemy.numEnemiesActive == 0 ) {
				if(!cajero.sprite.visible)
				{
					if(!cajeroComing) {
						cajeroComing = true;
						haxe.Timer.delay(function() { shakeAmount += 300; cajero.Show(); } ,2000);
					}
				}
				OpenAllDoors();
				trace("OPEN!");
				var dist = nape.geom.Vec2.distance(new Vec2(320,320), Player.position);
				trace(dist);
				if( dist < 64 && Luxe.input.inputdown("open") && !wasOpened ) {
					wasOpened = true;
					cajero.Open();
				}
			}
		}
    } //update


} //Main
