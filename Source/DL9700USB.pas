unit DL9700USB;

interface

const
  DL9700USB_DllName = 'DL9700USB.dll'; // Version 1.2

function AutoOpenComPort(var Port: longint; var ComAdr: byte; Baud: byte; var FrmHandle: longint): longint; stdcall; external DL9700USB_DllName;

// function OpenComPort(Port: longint; var ComAdr: byte; Baud: byte; var FrmHandle: longint): longint; stdcall; external DL9700USB_DllName;

// function CloseComPort(): longint; stdcall; external DL9700USB_DllName;

function CloseSpecComPort(FrmHandle: longint): longint; stdcall; external DL9700USB_DllName;

function GetReaderInformation(var ComAdr: byte; VersionInfo: pchar; var ReaderType: byte; TrType: pchar; var dmaxfre, dminfre, powerdBm: byte; var ScanTime: byte; FrmHandle: longint): longInt; stdcall; external DL9700USB_DllName;

// EPCC1-G2
function Inventory_G2(var ComAdr: byte; AdrTID, LenTID, TIDFlag: byte; EPClenandEPC: pchar; var Totallen: longint; var CardNum: longint; FrmHandle: longint): longint; stdcall; external DL9700USB_DllName;

function WriteEPC_G2(var ComAdr; Password: pchar; WriteEPC: pchar; WriteEPClen: byte; var errorcode: longint; FrmHandle: longint): longint; stdcall; external DL9700USB_DllName;

implementation

end.
