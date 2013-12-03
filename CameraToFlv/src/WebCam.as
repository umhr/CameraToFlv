package  
{
	
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.ActivityEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.SampleDataEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Video;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author umhr
	 */
	public class WebCam extends Sprite 
	{
		private var _video:Video;
		private var _flvEncoderManager:FlvEncoderManager;
		private var _isActivity:Boolean;
		private var _soundBuffer:ByteArray;
		private var _bitmapData:BitmapData;
		private var _frameRate:int = 15;
		private var _seconds:int = 5;
		private var _width:int = 320;
		private var _height:int = 240;
		private var _date:Date;
		private var _pushButton:PushButton;
		public function WebCam() 
		{
			init();
		}
		private function init():void 
		{
			if (stage) onInit();
			else addEventListener(Event.ADDED_TO_STAGE, onInit);
		}

		private function onInit(event:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onInit);
			// entry point
			
			_bitmapData = new BitmapData(_width, _height, false, 0xFF000000);
			
			var camera:Camera = Camera.getCamera();
			_microphone = new Microphone();
			//カメラの存在を確認
			if (camera) {
				camera.setMode(_width, _height, _frameRate);
				_video = new Video();
				_video.attachCamera(camera);
				addChild(_video);
				_label = new Label(this, 8, 8, "0");
				camera.addEventListener(ActivityEvent.ACTIVITY, camera_activity);
				
				if(_microphone){
					_microphone = Microphone.getMicrophone();
					_microphone.setSilenceLevel(0);
					_microphone.rate = 44;
					
					_soundBuffer = new ByteArray();
				}else {
					trace("マイクが見つかりませんでした。");
				}
			} else {
				trace("カメラが見つかりませんでした。");
			}
			
			addUI();
		}
		private var _label:Label;
		private var _microphone:Microphone;
		private function addUI():void 
		{
			_pushButton = new PushButton(this, (320 - 150) * 0.5, 110, "Rec Start", onStart);
			_pushButton.width = 150;
		}
		
		private function camera_activity(e:ActivityEvent):void 
		{
			if (_isActivity) {
				return;
			}
			_isActivity = true;
			_flvEncoderManager = new FlvEncoderManager(_frameRate, _width, _height);
			_flvEncoderManager.addEventListener(Event.CHANGE, flvEncoderManager_change);
			_flvEncoderManager.addEventListener(Event.COMPLETE, flvEncoderManager_complete);
		}
		
		private function flvEncoderManager_change(e:Event):void 
		{
			_pushButton.label = "Encoding:" + (_flvEncoderManager.totalFrame-_flvEncoderManager.currentFrame) +" / " + _flvEncoderManager.totalFrame;
		}
		
		private function flvEncoderManager_complete(e:Event):void 
		{
			_pushButton.label = "Save flv file";
		}
		
		private function onStart(e:MouseEvent):void 
		{
			if (_isActivity) {
				if (_pushButton.label == "Rec Start") {
					_pushButton.y = 248;
					_date = new Date();
					_flvEncoderManager.start();
					if(_microphone){
						_microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, microphone_sampleData);
					}else{
						addEventListener(Event.ENTER_FRAME, enterFrame);
					}
					_pushButton.label = "Rec Stop";
				}else if (_pushButton.label == "Rec Stop") {
					if(_microphone){
						_microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, microphone_sampleData);
					}else{
						removeEventListener(Event.ENTER_FRAME, enterFrame);
					}
					_flvEncoderManager.stop();
				}else if(_pushButton.label == "Save flv file"){
					_flvEncoderManager.save();
					_pushButton.label = "Rec Start";
				}
			}
		}
		
		private function microphone_sampleData(e:SampleDataEvent):void 
		{
			addBitmapData(e.data);
		}
		
		private function enterFrame(e:Event):void 
		{
			addBitmapData();
		}
		
		private function addBitmapData(soundBuffer:ByteArray = null):void {
			var time:int = new Date().time - _date.time;
			_label.text = String(Math.floor(time / 60000)) + ":" + Math.floor(time / 1000) + "." + time;
			
			_bitmapData.draw(_video);
			_bitmapData.draw(_label);
			_flvEncoderManager.addBitmapData(_bitmapData, soundBuffer);
			
		}
		
	}
	
}