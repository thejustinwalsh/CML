package  {
    import flash.display.NativeMenu; 
    import flash.display.NativeMenuItem; 
    import flash.display.NativeWindow; 
    import flash.display.MovieClip;
	import flash.display.StageScaleMode;
    import flash.events.Event; 
    import flash.filesystem.File; 
	import flash.net.FileFilter;
    import flash.desktop.NativeApplication;
    import fl.controls.TextArea;
    import flash.filesystem.FileStream;
    import flash.filesystem.FileMode;
	
	import org.si.cml.BMLParser;
	import flash.display.StageAlign;
    
	
	public class BML2CML extends MovieClip {
		
		private var fileMenu:NativeMenuItem;
		private var bmlText:TextArea;
		private var cmlText:TextArea;
		
		public function BML2CML()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(Event.RESIZE, onResize);
			
			bmlText = new TextArea();
			addChild(bmlText);
			
			cmlText = new TextArea();
			addChild(cmlText);
			
			onResize(null);
			
            if (NativeWindow.supportsMenu) { 
                stage.nativeWindow.menu = new NativeMenu(); 
                fileMenu = stage.nativeWindow.menu.addItem(new NativeMenuItem("File")); 
                fileMenu.submenu = createFileMenu();
            }
		}
		
		function onResize(event:Event):void {
			bmlText.width = stage.stageWidth / 2;
			bmlText.height = stage.stageHeight;
			
			cmlText.x = bmlText.width;
			cmlText.width = stage.stageWidth / 2;
			cmlText.height = stage.stageHeight;
		}
		
		 public function createFileMenu():NativeMenu { 
            var fileMenu:NativeMenu = new NativeMenu(); 
            var newCommand:NativeMenuItem = fileMenu.addItem(new NativeMenuItem("Open...")); 
            newCommand.addEventListener(Event.SELECT, openCommand);
             
            return fileMenu; 
        }
		
		private function openCommand(event:Event):void {
			var fileToOpen:File = new File();
			var txtFilter:FileFilter = new FileFilter("BulletML", "*.bml;*.xml");
			
            try
			{
				fileToOpen.browseForOpen("Open", [txtFilter]);
				fileToOpen.addEventListener(Event.SELECT, fileSelected);
			}
			catch (e:Error) {}
        }
		
		function fileSelected(event:Event):void 
		{
			var stream:FileStream = new FileStream();
			stream.open(event.target as File, FileMode.READ);
			var fileData:String = stream.readUTFBytes(stream.bytesAvailable);
			bmlText.text = fileData.split("\r").join("");
			cmlText.text = BMLParser.translate(XML(fileData));
		}
	}
	
}
