unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  IniEx2, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
//    Button1Click(nil);
end;

procedure TForm1.Button1Click(Sender: TObject);
var INI:TIni;
    i1,i2:Integer;
    lLeft,lTop:Integer;
    s:string;
    sDir :string;
begin
    sDir := ExtractFileDir(Application.ExeName);
    INI := TIni.Create(sDir+'\test.ini');

    if INI.LoadFile then begin
        MessageBox(Handle,'Load Done.','title',MB_OK);
    end else begin
        MessageBox(Handle,PChar('Load Failed.'#13#10
                               +INI.ErrorMsg),'title',MB_OK or MB_ICONHAND);
        exit;
    end;

    lLeft := 123;
    lTop := -5;
    s := 'bla-bla-bla "=)))"';

    i1 := INI.Sections.IndexOfSection('Section1');
    if i1=-1 then i1 := INI.Sections.Add('Section1');
    if i1>=0 then begin
        INI.Sections[i1].Keys.Add('Left',@lLeft,l_VT_INTEGER);
        INI.Sections[i1].Keys.Add('Top',@lTop,l_VT_INTEGER);
        i2 := INI.Sections[i1].Sections.IndexOfSection('Name');
        if i2=-1 then i2 := INI.Sections[i1].Sections.Add('Name');
        if i2>=0 then begin
            INI.Sections[i1].Sections[i2].Keys.Add('Name',Pointer(s),l_VT_STRING);
        end;
        self.Color := INI.Sections[i1].Keys.GetInteger('Color',clBtnShadow);
    end;
    self.Caption := INI.GetStringOfPath('Section1\Name','Comment','[error]');

    INI.FileName := sDir+'\test_saved.ini';
    INI.FileComment := 'This is very important data!'#13#10+
                       'Don''t edit this file!';
    if INI.SaveFile then
        MessageBox(Handle,'Save Done.','title',MB_OK)
    else
        MessageBox(Handle,'Save Failed.','title',MB_OK or MB_ICONHAND);

    INI.Free;
end;

end.
