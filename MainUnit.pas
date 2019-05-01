//---------------------------------------------------------------------------
// This software is Copyright (c) 2013-2016 Push for Time
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Push for Time Products
// and is subject to that software license agreement.
//---------------------------------------------------------------------------

unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExtCtrls, jpeg, StdCtrls, ComCtrls, Buttons, IniFiles;

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Help1: TMenuItem;
    AboutTagProgrammer1: TMenuItem;
    //--------------------
    Image1: TImage;
    Timer1: TTimer;
    Timer2: TTimer;
    PopupMenu1: TPopupMenu;
    ClearAll1: TMenuItem;
    Remove1: TMenuItem;
    Bevel1: TBevel;
    //--------------------
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Serial: TComboBox;
    Label2: TLabel;
    Baudrate: TComboBox;
    Label3: TLabel;
    ReaderAddress: TEdit;
    Connect: TSpeedButton;
    Disconnect: TSpeedButton;
    //--------------------
    Scrolling_Lists: TCheckBox;
    System_Beep: TCheckBox;
    //--------------------
    TabControl1: TTabControl;
    //--------------------
    Panel1: TPanel;
    ListView1: TListView;
    TID: TCheckBox;
    Label5: TLabel;
    TID_StartAddress: TEdit;
    Label6: TLabel;
    TID_Length: TEdit;
    Read: TSpeedButton;
    //--------------------
    Panel2: TPanel;
    ListView2: TListView;
    Image2: TImage;
    BibNumber: TMemo;
    Auto_Increment: TCheckBox;
    Write: TSpeedButton;
    Auto_Write: TCheckBox;
    Label4: TLabel;
    WriteInterval: TComboBox;
    //--------------------
    Panel3: TPanel;
    procedure getCharStr(s: string; cStr: pchar);
    procedure WaitFor(Milliseconds: integer);
    //--------------------
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Exit1Click(Sender: TObject);
    procedure AboutTagProgrammer1Click(Sender: TObject);
    //--------------------
    procedure ConnectClick(Sender: TObject);
    procedure DisconnectClick(Sender: TObject);
    //--------------------
    procedure Scrolling_ListsClick(Sender: TObject);
    procedure System_BeepClick(Sender: TObject);
    //--------------------
    procedure TabControl1Change(Sender: TObject);
    //--------------------
    procedure Timer1Timer(Sender: TObject);
    procedure TIDClick(Sender: TObject);
    procedure TID_StartAddressKeyPress(Sender: TObject; var Key: Char);
    procedure TID_LengthKeyPress(Sender: TObject; var Key: Char);
    procedure ReaderAddressKeyPress(Sender: TObject; var Key: Char);
    procedure ReadClick(Sender: TObject);
    //--------------------
    procedure Timer2Timer(Sender: TObject);
    procedure BibNumberClick(Sender: TObject);
    procedure BibNumberExit(Sender: TObject);
    procedure BibNumberKeyPress(Sender: TObject; var Key: Char);
    procedure WriteClick(Sender: TObject);
    procedure Auto_WriteClick(Sender: TObject);
    procedure WriteIntervalChange(Sender: TObject);
    //--------------------
    procedure ClearAll1Click(Sender: TObject);
    procedure Remove1Click(Sender: TObject);
  private
    { Private declarations }
    ComAdr: byte;
    Baud: byte;
    OpenComIndex: integer;
    ComIsOpen: boolean;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  ConfigFile: TIniFile;
  CmdRet: longint;
  errorcode: longint;
  FrmHandle: longint;

implementation

uses
  DL9700USB, AboutUnit;

{$R *.dfm}

function FindListViewItem(LV: TListView; const sBibNumber: string; Column: integer): TListItem;
var
  i: integer;
  Found: boolean;
begin
  Assert(Assigned(LV));
  Assert((LV.ViewStyle = vsReport) or (Column = 0));
  Assert(sBibNumber <> '');

  for i := 0 to LV.Items.Count - 1 do
  begin
    Result := LV.Items[i];

    if Column = 0 then
      Found := AnsiCompareText(Result.Caption, sBibNumber) = 0
    else if Column > 0 then
      Found := AnsiCompareText(Result.SubItems[Column - 1], sBibNumber) = 0
    else
      Found := False;
    if Found then
      Exit;
  end;

  Result := nil;
end;

function AddLeadingZeroes(const aNumber, Length: integer): string;
begin
  Result := SysUtils.Format('%.*d', [Length, aNumber]);
end;

function getStr(pStr: pchar; len: integer): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to len - 1 do
    Result := Result + (pStr + i)^;
end;

function getHexStr(sBinStr: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to Length(sBinStr) do
    Result := Result + IntToHex(Ord(sBinStr[i]), 2);
end;

procedure TForm1.getCharStr(s: string; cStr: pchar);
var
  i: integer;
begin
  try
    for i := 0 to Length(s) div 2 - 1 do
      (cStr + i)^ := Char(StrToInt('$' + Copy(s, i * 2 + 1, 2)));
  except
  end;
end;

procedure TForm1.WaitFor(Milliseconds: integer);
var
  Tick: dword;
  Event: THandle;
begin
  Event := CreateEvent(nil, False, False, nil);
  try
    Tick := GetTickCount + dword(Milliseconds);
    while (Milliseconds > 0) and (MsgWaitForMultipleObjects(1, Event, False, Milliseconds, QS_ALLINPUT) <> WAIT_TIMEOUT) do
    begin
      Application.ProcessMessages;
      Milliseconds := Tick - GetTickCount;
    end;
  finally
    CloseHandle(Event);
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Terminate;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.Caption := 'Tag Programmer by Push for Time' + ' v' + AboutForm.GetAppVersionStr;

  ConfigFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'Config.ini');

  if ConfigFile.ReadString('General', 'TabIndex', '') = '0' then
  begin
    TabControl1.TabIndex := 0;
    Panel1.Visible := True;
    Panel2.Visible := False;
  end
  else if ConfigFile.ReadString('General', 'TabIndex', '') = '1' then
  begin
    TabControl1.TabIndex := 1;
    Panel1.Visible := False;
    Panel2.Visible := True;
  end;

  if ConfigFile.ReadString('General', 'ScrollingLists', '') = '1' then
  begin
    Scrolling_Lists.Checked := True;
  end
  else if ConfigFile.ReadString('General', 'ScrollingLists', '') = '0' then
  begin
    Scrolling_Lists.Checked := False;
  end;

  if ConfigFile.ReadString('General', 'SystemBeep', '') = '1' then
  begin
    System_Beep.Checked := True;
  end
  else if ConfigFile.ReadString('General', 'SystemBeep', '') = '0' then
  begin
    System_Beep.Checked := False;
  end;

  // Port, Baud (Speed), Reader Address
  Serial.ItemIndex := 0;
  Baudrate.ItemIndex := 3;
  ReaderAddress.Text := 'FF';

  // Connect, Disconnect
  Connect.Enabled := True;
  Disconnect.Enabled := False;

  // TID Start Address, Length
  TID_StartAddress.Text := '02';
  TID_Length.Text := '04';

  // D_Read Tag(s)
  ListView1.Enabled := False;
  TID.Enabled := False;
  Read.Enabled := False;

  // D_Write Tag(s)
  ListView2.Enabled := False;
  BibNumber.Enabled := False;
  Auto_Increment.Enabled := False;
  Write.Enabled := False;
  Auto_Write.Enabled := False;

  // Bib Number
  BibNumber.Clear;
  BibNumber.Text := '1234';
  BibNumber.Font.Color := clSilver;

  // Write Interval
  WriteInterval.ItemIndex := 2;

  // Toast
  Panel3.Visible := False;
  Panel3.Caption := '...';

  // Default
  errorcode := -1;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F2 then
    WriteClick(Self);
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.AboutTagProgrammer1Click(Sender: TObject);
begin
  AboutForm.ShowModal;
end;

procedure TForm1.ConnectClick(Sender: TObject);
var
  Port: longint;
  VersionInfo, TrType: array[0..2] of Char;
  OpenResult, ReaderType, ScanTime, dmaxfre, dminfre, powerdBm: byte;
begin
  // Toast
  Panel3.Visible := True;
  Panel3.Caption := 'Please Wait';

  WaitFor(1000); // 1 Second

  // Convert reader address from string to integer
  ComAdr := StrToInt('$' + ReaderAddress.Text);

  // Baudrate
  Baud := Baudrate.ItemIndex;
  if Baud > 2 then
    Baud := Baud + 2;

  // Auto Connect Reader
  OpenResult := AutoOpenComPort(Port, ComAdr, Baud, FrmHandle);
  OpenComIndex := FrmHandle;

  if OpenResult = 0 then
  begin
    if (CmdRet = $35) or (CmdRet = $30) then
    begin
      // Toast
      Panel3.Visible := False;
      Panel3.Caption := '...';
      MessageBox(0, 'Serial communication port is already opened!', 'Tag Programmer', MB_ICONERROR or MB_OK);
      Exit;
    end;
  end;

  if (OpenComIndex <> -1) and (OpenResult <> $35) and (OpenResult <> $30)
    then
  begin
    ComIsOpen := True;

    // Reader Info
    GetReaderInformation(ComAdr, @VersionInfo, ReaderType, @TrType, dmaxfre, dminfre, powerdBm, ScanTime, FrmHandle);

    if not (ReaderType = $08) then
    begin
      // Toast
      Panel3.Visible := False;
      Panel3.Caption := '...';
      MessageBox(0, 'Device not supported.', 'Tag Programmer', MB_ICONERROR or MB_OK);
      Exit;
    end;
  end;

  if (OpenComIndex = -1) and (OpenResult = $30) then
  begin
    // Toast
    Panel3.Visible := False;
    Panel3.Caption := '...';
    MessageBox(0, 'Error opening serial communication port!', 'Tag Programmer', MB_ICONERROR or MB_OK);
    Exit;
  end;

  // Connected
  Serial.Enabled := False;
  Baudrate.Enabled := False;
  ReaderAddress.Enabled := False;
  // ..
  Connect.Enabled := False;
  Disconnect.Enabled := True;
  Connect.Caption := 'Connected';
  Disconnect.Caption := 'Disconnect';

  // E_Read Tag(s)
  ListView1.Enabled := True;
  TID.Enabled := True;
  Read.Enabled := True;

  // E_Write Tag(s)
  ListView2.Enabled := True;
  BibNumber.Enabled := True;
  Auto_Increment.Enabled := True;
  Write.Enabled := True;
  Auto_Write.Enabled := True;

  // Toast
  Panel3.Visible := False;
  Panel3.Caption := '...';
end;

procedure TForm1.DisconnectClick(Sender: TObject);
begin
  // Disconnect Reader
  CloseSpecComPort(OpenComIndex);

  // Disconnected
  Serial.Enabled := True;
  Baudrate.Enabled := True;
  ReaderAddress.Enabled := True;
  // ..
  Connect.Enabled := True;
  Disconnect.Enabled := False;
  Connect.Caption := 'Connect';
  Disconnect.Caption := 'Disconnected';

  // D_Read Tag(s)
  ListView1.Enabled := False;
  TID.Enabled := False;
  Read.Enabled := False;

  // D_Write Tag(s)
  ListView2.Enabled := False;
  BibNumber.Enabled := False;
  Auto_Increment.Enabled := False;
  Write.Enabled := False;
  Auto_Write.Enabled := False;

  if Auto_Write.Checked = True then
  begin
    Timer1.Enabled := False;
    Auto_write.Checked := False;
  end;
end;

procedure TForm1.Scrolling_ListsClick(Sender: TObject);
begin
  if Scrolling_Lists.Checked = True then
  begin
    ConfigFile.WriteString('General', 'ScrollingLists', '1');
  end
  else if Scrolling_Lists.Checked = False then
  begin
    ConfigFile.WriteString('General', 'ScrollingLists', '0');
  end;
end;

procedure TForm1.System_BeepClick(Sender: TObject);
begin
  if System_Beep.Checked = True then
  begin
    ConfigFile.WriteString('General', 'SystemBeep', '1');
  end
  else if System_Beep.Checked = False then
  begin
    ConfigFile.WriteString('General', 'SystemBeep', '0');
  end;
end;

procedure TForm1.TabControl1Change(Sender: TObject);
begin
  if TabControl1.TabIndex = 0 then
  begin
    ConfigFile.WriteString('General', 'TabIndex', '0');
    Panel1.Visible := True;
    Panel2.Visible := False;
  end
  else if TabControl1.TabIndex = 1 then
  begin
    ConfigFile.WriteString('General', 'TabIndex', '1');
    Panel1.Visible := False;
    Panel2.Visible := True;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
// ChangeSubItem1
  procedure ChangeSubItem1(aListItem: TListItem; subItemIndex: integer; ItemText: string);
  begin
    if aListItem.SubItems[subItemIndex] = ItemText then
    begin
      if (aListItem.SubItems[2] = '99999') or (aListItem.SubItems[2] = '') then
        aListItem.SubItems[2] := '0'
      else
      begin
        aListItem.SubItems[2] := IntToStr(StrToInt(aListItem.SubItems[2]) + 1);
        Exit;
      end;
    end;
    aListItem.SubItems[2] := '1';
    aListItem.SubItems[subItemIndex] := ItemText;
  end;
  // ChangeSubItem2
  procedure ChangeSubItem2(aListItem: TListItem; subItemIndex: integer; ItemText: string);
  begin
    if aListItem.SubItems[subItemIndex] = ItemText then
      Exit;
    aListItem.SubItems[subItemIndex] := ItemText;
  end;
var
  EPClenandEPC: array[0..5000] of Char;
  m, i: integer;
  EPClen, Totallen: integer;
  CardIndex: integer;
  CardNum: longint;
  AdrTID, LenTID, TIDFlag: byte;
  tEPC, sEPC: string;
  sBibNumber: string;
  IsOnListView: boolean;
  aListItem: TListItem;
begin
  // Initialize
  aListItem := nil;

  // TID
  if TID.Checked then
  begin
    AdrTID := StrToInt('$' + Trim(TID_StartAddress.Text));
    LenTID := StrToInt('$' + Trim(TID_Length.Text));
    TIDFlag := 1;
  end
  else
  begin
    AdrTID := 0;
    LenTID := 0;
    TIDFlag := 0;
  end;

  CmdRet := Inventory_G2(ComAdr, AdrTID, LenTID, TIDFlag, @EPClenandEPC, Totallen, CardNum, FrmHandle);

  if (CmdRet = $01) or (CmdRet = $02) or (CmdRet = $03) or (CmdRet = $04) or (CmdRet = $FB) then
  begin
    // temp EPC
    tEPC := getStr(EPClenandEPC, Totallen);
    begin
      m := 1;
      for CardIndex := 1 to CardNum do
      begin
        EPClen := Ord(tEPC[m]) + 1;

        // EPC
        sEPC := Copy(tEPC, m, EPClen);
        m := m + EPClen;

        if Length(sEPC) <> EPClen then
          Continue;

        // Bib Number or TID
        sBibNumber := getHexStr(sEPC);
        IsOnListView := False;

        for i := 1 to ListView1.Items.Count do
        begin
          if Copy(sBibNumber, 3, Length(sBibNumber)) = (ListView1.Items[i - 1]).SubItems[0] then
          begin
            aListItem := ListView1.Items[i - 1];
            IsOnListView := True;
          end;
        end;

        if (not IsOnListView) then
        begin
          aListItem := ListView1.Items.Add;
          aListItem.Caption := IntToStr(aListItem.Index + 1); // No.
          aListItem.SubItems.Add(''); // Bib Number or TID
          aListItem.SubItems.Add(''); // Length
          aListItem.SubItems.Add(''); // Read Time(s)

          aListItem := ListView1.Items[ListView1.Items.Count - 1];

          if Scrolling_Lists.Checked = True then
          begin
            aListItem.MakeVisible(False);
          end;

          if System_Beep.Checked = True then
          begin
            Beep;
          end;

          // ChangeSubItem2
          ChangeSubItem2(aListItem, 1, IntToHex(Ord(sEPC[1]), 2));
        end;
        // ChangeSubItem1
        ChangeSubItem1(aListItem, 0, Copy(sBibNumber, 3, Length(sBibNumber) - 2));
      end;
    end;
  end;
end;

procedure TForm1.TIDClick(Sender: TObject);
begin
  if TID.Checked then
  begin
    ListView1.Columns[1].Caption := 'TID';
    ListView1.Columns[1].Width := 200;
    TID_StartAddress.Enabled := True;
    TID_Length.Enabled := True;
  end
  else
  begin
    ListView1.Columns[1].Caption := 'Bib Number';
    ListView1.Columns[1].Width := 100;
    TID_StartAddress.Enabled := False;
    TID_Length.Enabled := False;
  end;
end;

procedure TForm1.TID_StartAddressKeyPress(Sender: TObject; var Key: Char);
var L: boolean;
begin
  L := (Key < #8) or (Key > #8) and (Key < #48) or (Key > #57) and (Key < #65) or (Key > #70) and (Key < #97) or (Key > #102);
  if l then Key := #0;
  if ((Key > #96) and (Key < #103)) then Key := char(Ord(Key) - 32);
end;

procedure TForm1.TID_LengthKeyPress(Sender: TObject; var Key: Char);
var L: boolean;
begin
  L := (Key < #8) or (Key > #8) and (Key < #48) or (Key > #57) and (Key < #65) or (Key > #70) and (Key < #97) or (Key > #102);
  if l then Key := #0;
  if ((Key > #96) and (Key < #103)) then Key := char(Ord(Key) - 32);
end;

procedure TForm1.ReaderAddressKeyPress(Sender: TObject; var Key: Char);
var L: boolean;
begin
  L := (Key < #8) or (Key > #8) and (Key < #48) or (Key > #57) and (Key < #65) or (Key > #70) and (Key < #97) or (Key > #102);
  if l then Key := #0;
  if ((Key > #96) and (Key < #103)) then Key := char(Ord(Key) - 32);
end;

procedure TForm1.ReadClick(Sender: TObject);
begin
  if Read.Caption = 'Read' then
  begin
    Timer1.Enabled := True;
    Read.Caption := 'Stop';
  end
  else if Read.Caption = 'Stop' then
  begin
    Timer1.Enabled := False;
    Read.Caption := 'Read';
  end;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  WriteClick(Self);
end;

procedure TForm1.BibNumberClick(Sender: TObject);
begin
  if BibNumber.Text = '1234' then
  begin
    BibNumber.Clear;
    BibNumber.Font.Color := clBlack;
  end;
end;

procedure TForm1.BibNumberExit(Sender: TObject);
begin
  if Length(BibNumber.Text) = 0 then
  begin
    BibNumber.Text := '1234';
    BibNumber.Font.Color := clSilver;
  end;
end;

procedure TForm1.BibNumberKeyPress(Sender: TObject; var Key: Char);
begin
  if (not (Key in ['0'..'9', #8])) then
    Key := #0;
end;

procedure TForm1.WriteClick(Sender: TObject);
var
  WriteEPC: array[0..100] of char;
  WriteEPClen: byte;
  Password: array[0..4] of Char;
  sBibNumber: string;
  iBibNumber: longint;
  fListItem: TListItem;
begin
  // if Input is empty, result is 0
  if (BibNumber.Font.Color = clSilver) or (Length(BibNumber.Text) = 0) then
  begin
    MessageBox(0, 'Bib number should have at least one digit (0-9).', 'Tag Programmer', MB_ICONERROR or MB_OK);
    Exit;
  end;

  // 4-digit and below
  if Length(BibNumber.Text) < 5 then
  begin
    sBibNumber := AddLeadingZeroes(StrToInt(BibNumber.Text), 4);
  end;

  // 5-digit up to 8-digit
  if Length(BibNumber.Text) = 5 then
  begin
    sBibNumber := AddLeadingZeroes(StrToInt(BibNumber.Text), 8);
  end;

  // 6-digit
  if Length(BibNumber.Text) = 6 then
  begin
    sBibNumber := AddLeadingZeroes(StrToInt(BibNumber.Text), 8);
  end;

  // 7-digit
  if Length(BibNumber.Text) = 7 then
  begin
    sBibNumber := AddLeadingZeroes(StrToInt(BibNumber.Text), 8);
  end;

  // 8-digit
  if Length(BibNumber.Text) = 8 then
  begin
    sBibNumber := BibNumber.Text;
  end;

  fListItem := FindListViewItem(ListView2, sBibNumber, 1);

  if fListItem <> nil then
  begin
    WriteEPClen := Length(sBibNumber) div 2;

    getCharStr(sBibNumber, WriteEPC);
    getCharStr('00000000', Password);

    CmdRet := WriteEPC_G2(ComAdr, @Password, @WriteEPC, WriteEPClen, errorcode, FrmHandle);

    if CmdRet = 0 then
    begin
      // Write Time(s);
      ListView2.Items[fListItem.Index].SubItems[2] := IntToStr(StrToInt(ListView2.Items.Item[fListItem.Index].SubItems[2]) + 1);
    end;
  end
  else
  begin
    WriteEPClen := Length(sBibNumber) div 2;

    getCharStr(sBibNumber, WriteEPC);
    getCharStr('00000000', Password);

    CmdRet := WriteEPC_G2(ComAdr, @Password, @WriteEPC, WriteEPClen, errorcode, FrmHandle);

    if CmdRet = 0 then
    begin
      if Auto_Increment.Checked then
      begin
        iBibNumber := StrToInt(sBibNumber);
        Inc(iBibNumber); // Increment

        // Update Bib Number
        BibNumber.Text := IntToStr(iBibNumber);
      end;
      with ListView2.Items.Add do
      begin
        Caption := IntToStr(ListView2.Items.Count); // No.
        SubItems.Add(sBibNumber); // Bib Number
        // Leading number is fixed and always 0
        // Count sBibNumber then divide to 2
        SubItems.Add('0' + IntToStr(Length(sBibNumber) div 2)); // Length
        SubItems.Add('1'); // Write Time(s);

        if Scrolling_Lists.Checked = True then
        begin
          MakeVisible(False);
        end;

        if System_Beep.Checked = True then
        begin
          Beep;
        end;
      end;
    end;
  end;
end;

procedure TForm1.Auto_WriteClick(Sender: TObject);
begin
  if Timer2.Enabled = False then
  begin
    Timer2.Enabled := True;
    Write.Enabled := False;
    WriteInterval.Enabled := True;
  end
  else
  begin
    Timer2.Enabled := False;
    Write.Enabled := True;
    WriteInterval.Enabled := False;
  end;
end;

procedure TForm1.WriteIntervalChange(Sender: TObject);
begin
  // Write Interval
  case WriteInterval.ItemIndex of
    0:
      Timer2.Interval := 1000; // 1 Second
    1:
      Timer2.Interval := 2000; // 2 Seconds
    2:
      Timer2.Interval := 3000; // 3 Seconds
    3:
      Timer2.Interval := 4000; // 4 Seconds
    4:
      Timer2.Interval := 5000; // 5 Seconds
  end;
end;

procedure TForm1.ClearAll1Click(Sender: TObject);
var
  buttonSelected: integer;
begin
  if TabControl1.TabIndex = 0 then
  begin
    if ListView1.Items.Count = 0 then
    begin
      Exit;
    end;

    buttonSelected := MessageDlg('Read Tag(s): Are you sure you want to permanently Clear All the lists?', mtConfirmation, [mbYes, mbNo], 0);

    if buttonSelected = mrYes then
    begin
      ListView1.Clear;
    end;
  end
  else if TabControl1.TabIndex = 1 then
  begin
    if ListView2.Items.Count = 0 then
    begin
      Exit;
    end;

    buttonSelected := MessageDlg('Write Tag(s): Are you sure you want to permanently Clear All the lists?', mtConfirmation, [mbYes, mbNo], 0);

    if buttonSelected = mrYes then
    begin
      ListView2.Clear;
    end;
  end;
end;

procedure TForm1.Remove1Click(Sender: TObject);
var
  buttonSelected: integer;
begin
  if TabControl1.TabIndex = 0 then
  begin
    if ListView1.Items.Count = 0 then
    begin
      Exit;
    end;

    buttonSelected := MessageDlg('Are you sure you want to permanently remove Bib Number: ' + ListView1.Items.Item[ListView1.ItemIndex].SubItems[0] + ' from read tag(s) lists?', mtConfirmation, [mbYes, mbNo], 0);

    if buttonSelected = mrYes then
    begin
      ListView1.Selected.Delete;
    end;
  end
  else if TabControl1.TabIndex = 1 then
  begin
    if ListView2.Items.Count = 0 then
    begin
      Exit;
    end;

    buttonSelected := MessageDlg('Are you sure you want to permanently remove Bib Number: ' + ListView2.Items.Item[ListView2.ItemIndex].SubItems[0] + ' from write tag(s) lists?', mtConfirmation, [mbYes, mbNo], 0);

    if buttonSelected = mrYes then
    begin
      ListView2.Selected.Delete;
    end;
  end;
end;

end.
