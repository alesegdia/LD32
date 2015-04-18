
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

import phoenix.Texture;
import phoenix.geometry.CircleGeometry;

class Player {

	var texTorso : Texture;
	var sprTorso : Sprite;

	public function new() {}

	public function Prepare() {
		texTorso = Luxe.loadTexture('assets/evoswonie-torso.png');
		sprTorso = new Sprite({
			name: "player",
			texture: texTorso,
			pos: Luxe.screen.mid,
			size: new Vector(106,64)
		});
	}

}

class Main extends luxe.Game {

	public var tilemap : TiledMap;
	var batcher : phoenix.Batcher;
	var player : Player;
	public var drawer : DebugDraw;

    override function ready() {
    	player = new Player();
    	player.Prepare();
    	drawer = new DebugDraw();
    	Luxe.physics.nape.debugdraw = drawer;

		Luxe.renderer.clear_color = new Color().rgb(0xaf663a);
		var that = this;
		//batcher = Luxe.renderer.create_batcher({ : 
		Luxe.loadText('assets/test-airplat-floorplat.tmx', function(res) {
			that.tilemap = new TiledMap({ tiled_file_data: res.text, format: 'tmx', pos: new Vector(0,0) });
			that.tilemap.display({ scale:2, grid:false, filter:FilterType.nearest });

			var themap:Array<Array<Int>> = new Array<Array<Int>>();
			for( tilearray in that.tilemap.layers.get("collisionLayer").tiles )
			{
				var col:Array<Int> = new Array<Int>();
				for( tile in tilearray )
				{
					trace(tile);
					if( tile.id == 0 ) col.push(0);
					else col.push(1);
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
						that.drawer.add(b);
					}
					strmap += themap[i][j];
				}
				strmap += "\n";
			}
			trace(strmap);
		});

		//var collisionLayer = tilemap.layers.get("collisionLayer");

    } //ready

    override function onkeyup( e:KeyEvent ) {

        if(e.keycode == Key.escape) {
            Luxe.shutdown();
        }

    } //onkeyup

    override function update(dt:Float) {

    } //update


} //Main
