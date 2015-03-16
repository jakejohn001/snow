package snow.platform.web.assets;

import snow.assets.Assets;
import snow.assets.AssetSystem;
import snow.types.Types;

import snow.io.typedarray.*;

import snow.platform.web.assets.tga.TGA;
import snow.platform.web.assets.psd.PSD;

import snow.Log.log;
import snow.Log._debug;
import snow.Log._verbose;
import snow.Log._verboser;

#if snow_web


    #if snow_audio_howlerjs
        import snow.platform.web.audio.howlerjs.Howl;
    #end //snow_audio_howlerjs

    @:noCompletion
    @:log_as('assets')
    class AssetSystem extends AssetSystemBinding {

        public function new( _manager:Assets ) {
            manager = _manager;
        }

        override public function exists( _id:String, ?_strict:Bool=true ) : Bool {

            var listed = manager.listed(_id);

            return listed;

        } //exists

        //images

            function nearest_power_of_two(_value:Int) {

                _value--;

                _value |= _value >> 1;
                _value |= _value >> 2;
                _value |= _value >> 4;
                _value |= _value >> 8;
                _value |= _value >> 16;

                _value++;

                return _value;

            } //nearest_power_of_two

            override public function image_load_info( _path:String, ?_components:Int = 4, ?_onload:?ImageInfo->Void ) : ImageInfo {

                var ext : String = haxe.io.Path.extension(_path);

                switch(ext) {
                    default:
                        return image_load_info_generic(_path, _components, _onload);
                    case "tga":
                        return image_load_info_tga(_path, _components, _onload);
                    case "psd":
                        return image_load_info_psd(_path, _components, _onload);
                }

                return null;

            } //image_load_info

                /** Let the browser handle this detail */
            function image_load_info_generic( _path:String, ?_components:Int=4, ?_onload:?ImageInfo->Void ) : ImageInfo {

                //Create an image element to load the image source
                var image : js.html.ImageElement = js.Browser.document.createImageElement();
                var info : ImageInfo = null;

                image.onload = function(a) {

                    var width_pot = nearest_power_of_two(image.width);
                    var height_pot = nearest_power_of_two(image.height);
                    var image_bytes = POT_Uint8Array_from_image(image.width, image.height, width_pot, height_pot, image);

                    info = {
                        id : _path,
                        bpp : 4,
                        width : image.width,
                        height : image.height,
                        width_actual : width_pot,
                        height_actual : height_pot,
                        bpp_source : 4,
                        data : image_bytes
                    };

                        //cleanup
                    image_bytes = null;

                        //append the listener
                    if(_onload != null) {
                        _onload( info );
                    }

                } //image.onload

                    //source comes after the onload being set, for race conditions
                image.src = _path;

                return info;

            } //image_load_info_generic

            function image_load_info_tga( _path:String, ?_components:Int=4, ?_onload:?ImageInfo->Void ) : ImageInfo {

                var info : ImageInfo = null;

                    // snow.utils.ByteArray.readFile(_path, { async:true }, function(data:snow.utils.ByteArray) {

                    var load = manager.lib.io.data_load( _path, { binary:false });
                    load.then(function(uint:Uint8Array) {

                        var image = new TGA();
                            image.load( uint );

                        var width_pot = nearest_power_of_two(image.header.width);
                        var height_pot = nearest_power_of_two(image.header.height);
                        var image_bytes = POT_Uint8Array_from_image(image.header.width, image.header.height, width_pot, height_pot, image.getCanvas());

                            //todo: bpp?

                        info = {
                            id : _path,
                            bpp : 4,
                            width : image.header.width,
                            height : image.header.height,
                            width_actual : width_pot,
                            height_actual : height_pot,
                            bpp_source : 4,
                            data : image_bytes
                        };

                            //cleanup
                        image_bytes = null;

                        if(_onload != null) {
                            _onload( info );
                        }

                    }).catchError(function(e){

                        if(_onload != null) {
                            _onload( info );
                        }

                    });


                return info;

            } //image_load_info_tga

            function POT_Uint8Array_from_image(_width:Int, _height:Int, _width_pot:Int, _height_pot:Int, _source:js.html.Element) : Uint8Array {

                var tmp_canvas = js.Browser.document.createCanvasElement();

                    tmp_canvas.width = _width_pot;
                    tmp_canvas.height = _height_pot;

                var tmp_context = tmp_canvas.getContext2d();

                    tmp_context.clearRect( 0,0, tmp_canvas.width, tmp_canvas.height );
                    tmp_context.drawImage( cast _source, 0, 0, _width, _height );

                var image_bytes = null;

                try {

                    image_bytes = tmp_context.getImageData( 0, 0, tmp_canvas.width, tmp_canvas.height );

                } catch(e:Dynamic) {

                    var tips = '- textures served from file:/// throw security errors\n';
                        tips += '- textures served over http:// work for cross origin byte requests';

                    log(tips);
                    throw e;

                } //catch

                    //cleanup
                tmp_canvas = null; tmp_context = null;

                return new Uint8Array(image_bytes.data);

            } //POT_Uint8Array_from_image

            function image_load_info_psd(_path:String, ?_components:Int=4, ?_onload:?ImageInfo->Void ) : ImageInfo {

                var info : ImageInfo = null;

                    var image = new PSD();

                    image.open(_path, function(psdimage){

                        var png_then = function(png_image) {

                            var width_pot = nearest_power_of_two(psdimage.header.width);
                            var height_pot = nearest_power_of_two(psdimage.header.height);
                            var image_bytes = POT_Uint8Array_from_image(psdimage.header.width, psdimage.header.height, width_pot, height_pot, png_image);

                            info = {
                                id : _path,
                                bpp : 4,
                                width : psdimage.header.width,
                                height : psdimage.header.height,
                                width_actual : width_pot,
                                height_actual : height_pot,
                                bpp_source : 4,
                                data : image_bytes
                            };

                                //cleanup
                            image_bytes = null;

                                //append the listener
                            if(_onload != null) {
                                _onload( info );
                            }

                        }

                        untyped psdimage.image.toPng().then(png_then);

                    });

                return info;

            } //image_load_info_psd

        override public function image_info_from_bytes( _path:String, _bytes:Uint8Array, ?_components:Int = 4 ) : ImageInfo {

            #if !snow_no_format_png

                if(_bytes == null) {
                    log("invalid bytes passed to image_info_from_bytes " + _path);
                    return null;
                }

                    //Then we need it to be a BytesInput haxe.io.Input
                var _raw_bytes = _bytes.toBytes();
                    //now a byte input for format.png
                var byte_input = new haxe.io.BytesInput(_raw_bytes, 0, _raw_bytes.length);
                    //get the raw data
                var png_data = new snow.utils.format.png.Reader(byte_input).read();
                    //Extract the bytes from the png reader
                var png_bytes = snow.utils.format.png.Tools.extract32(png_data);
                    //And the header information for infomation
                var png_header = snow.utils.format.png.Tools.getHeader(png_data);

                return {
                    id : _path,
                    bpp : _components,
                    width : png_header.width,
                    height : png_header.height,
                    width_actual : png_header.width,
                    height_actual : png_header.height,
                    bpp_source : png_header.colbits,
                    data : new Uint8Array(cast png_bytes.getData())
                }
            #else

                return null;

            #end

        } //image_info_from_bytes

        override public function audio_load_info( _path:String, ?_format:AudioFormatType, ?_load:Bool = true, ?_onload:?AudioInfo->Void ) : AudioInfo {

            var info : AudioInfo = {
                format:_format,
                id:_path, handle:null, data:null
            };

            info.handle = new Howl({
                urls: [_path],
                    //this seems to not work as intended
                    //when skipping sounds. :todo : test on server
                // buffer : !_load,
                onend : function() {
                    manager.lib.audio.platform._on_end(info.handle);
                },
                onload : function(){
                    if(_onload != null) {
                        _onload(info);
                    }
                }
            });

            return info;

        } //audio_load_info

    } //AssetSystem

#end //snow_web