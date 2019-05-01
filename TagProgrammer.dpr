program TagProgrammer;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {Form1},
  AboutUnit in 'AboutUnit.pas' {AboutForm},
  DL9700USB in 'Source\DL9700USB.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Tag Programmer by Push for Time';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TAboutForm, AboutForm);
  Application.Run;
end.
