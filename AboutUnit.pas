unit AboutUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, StdCtrls, Buttons, ShellApi;

type
  TAboutForm = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Bevel1: TBevel;
    SpeedButton1: TSpeedButton;
    Label5: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Label4Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function GetAppVersionStr: string;
  end;

type
  TBytes = array of Byte;

var
  AboutForm: TAboutForm;

implementation

{$R *.dfm}

function TAboutForm.GetAppVersionStr: string;
var
  Exe: string;
  Size, Handle: dword;
  Buffer: TBytes;
  FixedPtr: PVSFixedFileInfo;
begin
  Exe := ParamStr(0);
  Size := GetFileVersionInfoSize(PChar(Exe), Handle);

  if Size = 0 then
    RaiseLastOSError;
  SetLength(Buffer, Size);

  if not GetFileVersionInfo(PChar(Exe), Handle, Size, Buffer) then
    RaiseLastOSError;

  if not VerQueryValue(Buffer, '\', Pointer(FixedPtr), Size) then
    RaiseLastOSError;

  Result := Format('%d.%d.%d.%d',
    [LongRec(FixedPtr.dwFileVersionMS).Hi, // Major
    LongRec(FixedPtr.dwFileVersionMS).Lo, // Minor
    LongRec(FixedPtr.dwFileVersionLS).Hi, // Release
    LongRec(FixedPtr.dwFileVersionLS).Lo]) // Build
end;

procedure TAboutForm.FormCreate(Sender: TObject);
begin
  AboutForm.Caption := 'About Tag Programmer';

  Label2.Caption := 'Version ' + GetAppVersionStr;
end;

procedure TAboutForm.Label4Click(Sender: TObject);
begin
  ShellExecute(self.WindowHandle, 'open', 'http://www.pushfortime.com', nil, nil, SW_SHOWNORMAL);
end;

procedure TAboutForm.SpeedButton1Click(Sender: TObject);
begin
  AboutForm.Close;
end;

end.
