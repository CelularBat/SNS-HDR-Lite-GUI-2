unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,LCLType , Types,Process;

type

  TFileInfo = record
    FullPath , ShortPath : String;
  end;
  TFileList = array of TFileInfo;

  { TForm1 }

  TForm1 = class(TForm)
    BtnAdd: TButton;
    BtnDel: TButton;
    BtnWykonaj: TButton;
    BtnExe: TButton;
    BtnDelAll: TButton;
    BtnOutputFolder: TButton;
    CBWyrownanie: TCheckBox;
    CBDuszki: TCheckBox;
    CBPanorama: TCheckBox;
    CBKonwersja: TCheckBox;
    CBLuminacja: TCheckBox;
    CBPromtLock: TCheckBox;
    CheckGroup1: TCheckGroup;
    DropListaProfil: TComboBox;
    DropListaFormat: TComboBox;
    EditOutputFolder: TEdit;
    EditBinaryPath: TEdit;
    EditCommand: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    ListBox1: TListBox;
    OpenDialog1: TOpenDialog;
    OpenDialog2: TOpenDialog;
    Panel1: TPanel;
    RadioGroupRozmiar: TRadioGroup;
    SelectDirectoryDialog1: TSelectDirectoryDialog;

    procedure BtnAddClick(Sender: TObject);
    procedure BtnDelAllClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure BtnExeClick(Sender: TObject);
    procedure BtnOutputFolderClick(Sender: TObject);
    procedure BtnWykonajClick(Sender: TObject);
    procedure CBPromtLockChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure ListBox1DrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);


    procedure PanelOnChange(Sender: TObject);
    function GetAllParams():String;
    procedure UpdatePhotoList();
    function DetectSNSBinary():String;

    function ExecuteBinary():Boolean;

  private

  public
    g_Photos : TFileList;
    g_Photos_cmd_string : String;

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.ListBox1DrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  aColor: TColor;                       //Background color
begin
  if (Index mod 2 = 0)                  //Index tells which item it is
    then aColor:=$EFEFEF                //every second item gets white as the background color
    else aColor:=$EEEEFF;               //every second item gets pink background color
  if odSelected in State then aColor:=$0000FF;  //If item is selected, then red as background color
  ListBox1.Canvas.Brush.Color:=aColor;  //Set background color
  ListBox1.Canvas.FillRect(ARect);      //Draw a filled rectangle

  ListBox1.Canvas.Font.Bold:=True;      //Set the font to "bold"
  ListBox1.Canvas.TextRect(ARect, 2, ARect.Top+2, ListBox1.Items[Index]);  //Draw Itemtext
end;


function TForm1.DetectSNSBinary():String;
var  ExePath, ExeDir ,tryPath: string;
begin
  ExePath := ParamStr(0);
  ExeDir := ExtractFilePath(ExePath);
  tryPath := ExeDir+'SNS-HDR.exe';
  if FileExists(tryPath) then
   begin
        Result := tryPath;
   end else
       Result := '';

end;

procedure TForm1.FormCreate(Sender: TObject);
var i :integer;
var temp:tcontrol;
var t:string;
begin
  for i := 0 to Panel1.ControlCount - 1 do
  begin
     temp := Panel1.Controls[i];
     t := temp.ClassName;
     case t of
     'TCheckBox':
        TCheckBox(temp).OnChange := @PanelOnChange;
      'TComboBox':
        TComboBox(temp).OnChange := @PanelOnChange;
      'TRadioGroup':
        TRadioGroup(temp).OnClick := @PanelOnChange;
      'TListBox':
        TListBox(temp).OnClick := @PanelOnChange;
      'TCheckGroup':
        TCheckGroup(temp).OnClick := @PanelOnChange;
     end;
  end;

  // Autocheck if binary is inside folder
  t := DetectSNSBinary();
  if length(t) < 2 then
  begin
      btnExe.Font.Color := clRed;
      btnExe.Font.Style := [fsBold];
      btnWykonaj.Enabled:=False;
  end
  else begin
       EditBinaryPath.Text := t;
       btnExe.Font.Color := clDefault;
       btnExe.Font.Style := [];
       btnWykonaj.Enabled:=True;
  end;

  g_Photos := [];
end;

procedure TForm1.UpdatePhotoList();
var i:integer;
begin
  g_Photos_cmd_string := '';

  if (ListBox1.Count > 0) then  ListBox1.Clear();
  for i:=0 to length(g_Photos)-1 do
  begin

        ListBox1.Items.Add(g_Photos[i].ShortPath);
        g_Photos_cmd_string := g_Photos_cmd_string + ' "' + g_Photos[i].FullPath+'"';
  end;

  PanelOnChange(self);

end;

procedure TForm1.BtnAddClick(Sender: TObject);
var i :integer;
var temp :TFileInfo;
var tempList :TFileList;
begin
    if OpenDialog1.execute then
     begin
          for i:=0 to OpenDialog1.Files.Count-1 do
          begin
             temp.FullPath := OpenDialog1.Files[i];
             temp.ShortPath:= ExtractFileName(temp.FullPath);
             insert(temp,tempList,length(tempList)); //insert at the end of table
          end;

          g_Photos := Concat(g_Photos,tempList);


          if ( ( Length (EditOutputFolder.Text) < 2 ) and (OpenDialog1.Files.Count > 0) ) then
          begin
              EditOutputFolder.Text := Copy(ExtractFilePath(temp.FullPath), 1, Length(ExtractFilePath(temp.FullPath)) - 1) ;
              //remove '/' on the end
          end;

          UpdatePhotoList();
     end;
end;

procedure TForm1.BtnDelAllClick(Sender: TObject);
begin
  SetLength(g_Photos,0);
  UpdatePhotoList();
end;

procedure TForm1.BtnDelClick(Sender: TObject);
var i : integer;
begin
     for i:=ListBox1.Items.Count - 1 downto 0 do
     begin
        if ListBox1.Selected[i] then
           delete(g_Photos,i,1);
     end;
     UpdatePhotoList();
end;

procedure TForm1.BtnExeClick(Sender: TObject);
begin
     if OpenDialog2.execute then
     begin
          if FileExists(OpenDialog2.FileName) then
          begin
          EditBinaryPath.Text := OpenDialog2.FileName;
             btnExe.Font.Color := clDefault;
             btnExe.Font.Style := [];
             btnWykonaj.Enabled:=True;
          end;

     end;

end;

procedure TForm1.BtnOutputFolderClick(Sender: TObject);
begin
  if SelectDirectoryDialog1.Execute then
  begin
          EditOutputFolder.Text:= SelectDirectoryDialog1.FileName;
          PanelOnChange(self);
  end;
end;


function TForm1.GetAllParams():String;
var rozmiar,opcje,preset,format,srgb,outputName,rozszerzenie,opcje_nazwa_pliku : String;
begin
   rozmiar := '-x'+ IntToStr( RadioGroupRozmiar.ItemIndex + 1);
   opcje:=' ';
   opcje_nazwa_pliku:='';
   if (not CBWyrownanie.Checked) then opcje:=opcje+'-da ' else opcje_nazwa_pliku := opcje_nazwa_pliku+'W ';
   if (not CBDuszki.Checked) then opcje:=opcje+'-dd ' else opcje_nazwa_pliku := opcje_nazwa_pliku+'uD ';
   if (not CBLuminacja.Checked) then opcje:=opcje+'-dal ' else opcje_nazwa_pliku := opcje_nazwa_pliku+'AL ';
   if (CBPanorama.Checked) then
   begin
        opcje:=opcje+'-pm ';
        opcje_nazwa_pliku := opcje_nazwa_pliku+'Pn ';
   end;

   preset := '-'+DropListaProfil.Items[ DropListaProfil.ItemIndex ]+' ';
   format := '-'+DropListaFormat.Items[ DropListaFormat.ItemIndex ]+' ';
   if (CBKonwersja.Checked) then srgb := '-srgb ';
   if (ListBox1.Count > 0) then
   begin
        case DropListaFormat.ItemIndex of
             0:  rozszerzenie := '.jpg';
             1,2: rozszerzenie := '.tiff';
        end;
        outputName := '-o' + ' "'+ EditOutputFolder.Text+'\'
                   + ListBox1.Items[0] + Concat(preset,opcje_nazwa_pliku,rozmiar)+rozszerzenie+'"';
   end;
   Result := Concat(rozmiar,opcje,preset,format,srgb, outputName);


end;

 procedure TForm1.PanelOnChange(Sender: TObject);
 var params : string;
begin

      params := GetAllParams();
      EditCommand.Text := params + g_Photos_cmd_string ;

end;

function TForm1.ExecuteBinary():boolean;
var _Proc : TProcess;
begin
     _Proc := TProcess.Create(nil);
     _Proc.Executable := EditBinaryPath.Text;
     _Proc.Parameters.Add(EditCommand.Text);
     _Proc.Options := [];
     _Proc.ShowWindow:=swoShowNoActivate;
     _Proc.Execute;
end;

 procedure TForm1.BtnWykonajClick(Sender: TObject);
 begin
     if (ListBox1.Count > 0) then
        ExecuteBinary();
 end;

procedure TForm1.CBPromtLockChange(Sender: TObject);
begin
  EditCommand.Enabled := CBPromtLock.Checked;
end;


end.

