package  
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import leelib.util.flvEncoder.ByteArrayFlvEncoder;
	import leelib.util.flvEncoder.FlvEncoder;
	/**
	 * ...
	 * @author umhr
	 */
	public class FlvEncoderManager extends EventDispatcher
	{
		
		private var _baFlvEncoder:ByteArrayFlvEncoder;
		private var _nullAudio:ByteArray = new ByteArray();
		private var _bitmapDataList:Array/*BitmapData*/;
		private var _audioChunkList:Array/*ByteArray*/;
		private var _timer:Timer = new Timer(30, 0);
		private var _totalFrame:int;
		public function FlvEncoderManager(framerate:int, width:int, height:int) 
		{
			init(framerate, width, height);
		}
		
		private function init(framerate:int, width:int, height:int):void {
			_baFlvEncoder = new ByteArrayFlvEncoder(framerate);
			_baFlvEncoder.setVideoProperties(width, height);
			_baFlvEncoder.setAudioProperties(FlvEncoder.SAMPLERATE_44KHZ);
			_nullAudio.length = _baFlvEncoder.audioFrameSize;
		}
		
		public function addBitmapData(bitmapData:BitmapData, audioChunk:ByteArray = null):void {
			if (audioChunk == null) {
				audioChunk = _nullAudio;
			}
			_bitmapDataList.push(bitmapData.clone());
			
			audioChunk.position = 0;
			// ByteArrayのclone
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeObject(audioChunk);
			byteArray.position = 0;
			_audioChunkList.push(byteArray);
			
		}
		
		public function start():void {
			_bitmapDataList = [];
			_audioChunkList = [];
			_baFlvEncoder.start();
		}
		
		public function stop():void {
			_totalFrame = _bitmapDataList.length;
			
			_timer.addEventListener(TimerEvent.TIMER, timer_timer);
			_timer.start();
		}
		
		private function timer_timer(e:TimerEvent):void 
		{
			if (_bitmapDataList.length > 0) {
				addFrme();
				dispatchEvent(new Event(Event.CHANGE));
			}else {
				_baFlvEncoder.updateDurationMetadata();
				_timer.removeEventListener(TimerEvent.TIMER, timer_timer);
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		private function addFrme():void {
			var n:int = _bitmapDataList.length;
			n = Math.min(n, 5);
			for (var i:int = 0; i < n; i++) 
			{
				_baFlvEncoder.addFrame(_bitmapDataList.shift(), _audioChunkList.shift());
			}
		}
		
		public function save():void {
			
			var fileRef:FileReference = new FileReference();
			fileRef.save(_baFlvEncoder.byteArray, "webcame.flv");			
			
			// cleanup
			_baFlvEncoder.byteArray.clear();
		}
		
		public function get currentFrame():int {
			return _bitmapDataList.length;
		}
		public function get totalFrame():int {
			return _totalFrame;
		}
		
	}

}