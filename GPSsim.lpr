program GPSsim;

{$mode objfpc}{$H+}

{ Example 08 File Handling                                                     }
{                                                                              }
{  This example demonstrates just a few basic functions of file handling which }
{  is a major topic in itself.                                                 }
{                                                                              }
{  For more information on all of the available file function see the Ultibo   }
{  Wiki or the Free Pascal user guide.                                         }
{                                                                              }
{  To compile the example select Run, Compile (or Run, Build) from the menu.   }
{                                                                              }
{  Once compiled copy the kernel.img file to an SD card along with the firmware}
{  files and use it to boot your Raspberry Pi.                                 }
{                                                                              }
{  Raspberry Pi A/B/A+/B+/Zero version                                         }
{   What's the difference? See Project, Project Options, Config and Target.    }

{Declare some units used by this example.}
uses
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  Console,
  Framebuffer,
  BCM2836,
  SysUtils,
  serial,
  Classes,     {Include the common classes}
  FileSystem,  {Include the file system core and interfaces}
  FATFS,       {Include the FAT file system driver}
  MMC,         {Include the MMC/SD core to access our SD card}
  BCM2709;     {And also include the MMC/SD driver for the Raspberry Pi}

{A window handle plus a couple of others.}
var
 Count:Longword;
 Filename:String;
 SearchRec:TSearchRec;
 StringList:TStringList;
 FileStream:TFileStream;
 WindowHandle:TWindowHandle;
 Characters:String;
 linecount:Longword;

begin
 {Create our window}
 WindowHandle:=ConsoleWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_FULL,True);

 {Output the message}
 ConsoleWindowWriteLn(WindowHandle,'Welcome to GPS simulator and log playback');
 ConsoleWindowWriteLn(WindowHandle,'');

 // The last 2 parameters allow setting the size of the transmit and receive buffers,
 // passing 0 means use the default size.}
 if SerialOpen(9600,SERIAL_DATA_8BIT,SERIAL_STOP_1BIT,SERIAL_PARITY_NONE,SERIAL_FLOW_NONE,0,0) = ERROR_SUCCESS then
  begin

   {Opened successfully, display a message}
   ConsoleWindowWriteLn(WindowHandle,'Serial device opened');
   end;


 {We may need to wait a couple of seconds for any drive to be ready}
 ConsoleWindowWriteLn(WindowHandle,'Waiting for drive C:\');
 while not DirectoryExists('C:\') do
  begin
   {Sleep for a second}
   Sleep(1000);
  end;
 ConsoleWindowWriteLn(WindowHandle,'C:\ drive is ready');
 ConsoleWindowWriteLn(WindowHandle,'');

 {First let's list the contents of the SD card. We can guess that it will be C:\
  drive because we didn't include the USB host driver.}
 ConsoleWindowWriteLn(WindowHandle,'Contents of drive C:\logs\');

 {To list the contents we need to use FindFirst/FindNext, start with FindFirst}
 if FindFirst('C:\logs\*.*',faAnyFile,SearchRec) = 0 then
  begin
   {If FindFirst succeeds it will return 0 and we can proceed with the search}
   repeat
    {Print the file found to the screen}
    ConsoleWindowWriteLn(WindowHandle,'Filename is ' + SearchRec.Name + ' - Size is ' + IntToStr(SearchRec.Size) + ' - Time is ' + DateTimeToStr(FileDateToDateTime(SearchRec.Time)));

   {We keep calling FindNext until there are no more files to find}
   until FindNext(SearchRec) <> 0;
  end;

 {After any call to FindFirst, you must call FindClose or else memory will be leaked}
 FindClose(SearchRec);
 ConsoleWindowWriteLn(WindowHandle,'');

 //first log file
 Filename:='C:\logs\gps_0.txt';

 {We should check if the file exists first before trying to create it}

 try

  ConsoleWindowWriteLn(WindowHandle,'Opening the file ' + Filename);
  try
   FileStream:=TFileStream.Create(Filename,fmOpenReadWrite);

   {Recreate our string list}
   StringList:=TStringList.Create;

   {And use LoadFromStream to read it}
   ConsoleWindowWriteLn(WindowHandle,'Loading the TStringList from the file');
   StringList.LoadFromStream(FileStream);

   {Iterate the strings and print them to the screen}
   ConsoleWindowWriteLn(WindowHandle,'The contents of the file are:');
   for Count:=0 to StringList.Count - 1 do
    begin
     ConsoleWindowWriteLn(WindowHandle,StringList.Strings[Count]);
     //uartstr := StringList.Strings[Count] + Chr(13) + Chr(10);
     linecount := 0;
     Characters := StringList.Strings[Count] + Chr(13) + Chr(10);
     SerialWrite(PChar(Characters), Length(Characters), linecount);
     ConsoleWindowWriteLn(WindowHandle,'uart buffer size is ' + IntToStr(Length(Characters)));

     sleep(1000);
    end;

   {Close the file and free the string list again}
   ConsoleWindowWriteLn(WindowHandle,'Closing the file');
   ConsoleWindowWriteLn(WindowHandle,'');
   FileStream.Free;
   StringList.Free;


  except
   {TFileStream couldn't open the file}
   ConsoleWindowWriteLn(WindowHandle,'Failed to open the file ' + Filename);
  end;
 except
  {Something went wrong creating the file}
  ConsoleWindowWriteLn(WindowHandle,'Failed to create the file ' + Filename);
 end;

 {Halt the thread}
 ThreadHalt(0);
end.

