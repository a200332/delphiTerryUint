unit uJxdSystemFolder;

interface
uses
  Windows, SysUtils, ShlObj;//, uDebugInfo;

type
  TxdSysFolder = class
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Reset;
    function ParserFile(const AFileName: string): Boolean;
    function Count: Integer;
    function Title(const AIndex: Integer): string;
    function Item(const AIndex: Integer): string; overload;
    function Item(const ATitle: string): string; overload;
  private
    FCurFolder: IShellFolder2;
    FCurPath: WideString;
  end;

implementation

{ TxdSysFolder }

type
  TAttInfo = record
    Index: Integer;
    Title: string;
    Info: string;
  end;
var
  _FileAtt: array[0..39] of TAttInfo = (
     (Index:  0; Title: '����'; Info: ''),
     (Index:  1; Title: '��С'; Info: ''),
     (Index:  2; Title: '����'; Info: ''),
     (Index:  3; Title: '�޸�����'; Info: ''),
     (Index:  4; Title: '��������'; Info: ''),
     (Index:  5; Title: '��������'; Info: ''),
     (Index:  6; Title: '����'; Info: ''),
     (Index:  7; Title: '״̬'; Info: ''),
     (Index:  8; Title: '������'; Info: ''),
     (Index:  9; Title: '����'; Info: ''),
     (Index: 10; Title: '����'; Info: ''),
     (Index: 11; Title: '����'; Info: ''),
     (Index: 12; Title: '���'; Info: ''),
     (Index: 13; Title: 'ҳ��'; Info: ''),
     (Index: 14; Title: '��ע'; Info: ''),
     (Index: 15; Title: '��Ȩ'; Info: ''),
     (Index: 16; Title: '������'; Info: ''),
     (Index: 17; Title: '��Ƭ����'; Info: ''),
     (Index: 18; Title: '������'; Info: ''),
     (Index: 19; Title: '��Ŀ����'; Info: ''),
     (Index: 20; Title: '����'; Info: ''),
     (Index: 21; Title: '����ʱ��'; Info: ''),
     (Index: 22; Title: 'λ��'; Info: ''),
     (Index: 23; Title: '�ܱ���'; Info: ''),
     (Index: 24; Title: '��Ӱ���ͺ�'; Info: ''),
     (Index: 25; Title: '��Ƭ��������'; Info: ''),
     (Index: 26; Title: '�ߴ�'; Info: ''),
     (Index: 27; Title: '���'; Info: ''),
     (Index: 28; Title: '�߶�'; Info: ''),
     (Index: 29; Title: '����'; Info: ''),
     (Index: 30; Title: '��Ŀ����'; Info: ''),
     (Index: 31; Title: 'δ֪'; Info: ''),
     (Index: 32; Title: '��Ƶ������С'; Info: ''),
     (Index: 33; Title: '��Ƶ��������'; Info: ''),
     (Index: 34; Title: 'Ƶ��'; Info: ''),
     (Index: 35; Title: '��˾'; Info: ''),
     (Index: 36; Title: '����'; Info: ''),
     (Index: 37; Title: '�ļ��汾'; Info: ''),
     (Index: 38; Title: '��Ʒ����'; Info: ''),
     (Index: 39; Title: '��Ʒ�汾'; Info: ''));

function TxdSysFolder.Count: Integer;
begin
  Result := Length(_FileAtt);
end;

constructor TxdSysFolder.Create;
begin
  Reset;
//  FFileAttInfo := ( [] );
end;

destructor TxdSysFolder.Destroy;
begin
  FCurFolder := nil;
  inherited;
end;

function TxdSysFolder.Item(const ATitle: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(_FileAtt) do
  begin
    if CompareText(ATitle, _FileAtt[i].Title) = 0 then
    begin
      Result := _FileAtt[i].Info;
      Break;
    end;
  end;
end;

function TxdSysFolder.Item(const AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex <= High(_FileAtt)) then
    Result := _FileAtt[AIndex].Info
  else
    Result := '';
end;

function TxdSysFolder.ParserFile(const AFileName: string): Boolean;
var
  strPath, strName: WideString;
  nEatch, nAttri: Cardinal;
  ppIDL: PItemIDList;
  phf: IShellFolder2;
  i: Integer;
  dts: TShellDetails;
begin
   Result := False;
  if not FileExists(AFileName) then Exit;
  strPath := ExtractFilePath( AFileName );
  strName := ExtractFileName( AFileName );
  if CompareText(strPath, FCurPath) <> 0 then
  begin
    Reset;
    if Failed(FCurFolder.ParseDisplayName( 0, nil, PWideChar(strPath), nEatch, ppIDL, nAttri )) then Exit;
    if Failed(FCurFolder.BindToObject( ppidl, nil, IID_IShellFolder2, phf )) then Exit;
    FCurFolder := nil;
    FCurFolder := phf;
    phf := nil;
    FCurPath := strPath;
  end;

  if Failed(FCurFolder.ParseDisplayName( 0, nil, PWideChar(strName), nEatch, ppIDL, nAttri)) then Exit;

  for i := Low(_FileAtt) to High(_FileAtt) do //�����ֵδ����֤��΢����վ�������������д�˸�34,�ҿ������ã������������ˡ�
  begin
    ZeroMemory( @dts, SizeOf(TShellDetails) );

    if Succeeded(FCurFolder.GetDetailsOf(ppidl, i, dts)) then
    begin

      if dts.str.uType = 0 then
        _FileAtt[i].Info := String(dts.str.pOleStr)
      else if dts.str.uType = 1 then
        _FileAtt[i].Info := 'error'
      else if dts.str.uType = 2 then
      begin
        if dts.str.uOffset = 0 then
          _FileAtt[i].Info := ''
        else
          _FileAtt[i].Info := IntToStr(dts.str.uOffset)
      end
      else if dts.str.uType = 3 then
        _FileAtt[i].Info := string(dts.str.cStr)
      else
        _FileAtt[i].Info := 'error';
    end;
  end;
  
//  for i := 0 to 100 do
//  begin
//    ZeroMemory( @psd, SizeOf(TShellDetails) );
//    ZeroMemory( @psd1, SizeOf(TShellDetails) );
//
//    if Succeeded(FCurFolder.GetDetailsOf(ppidl, i, psd)) then
//    begin
//      if Succeeded(FCurFolder.GetDetailsOf(nil, i, psd1)) then
//      begin
//        case psd1.str.uType of
//          0:
//          begin
//            str := psd1.str.pOleStr;
//            if str = '' then
//              str := 'xxxx';
//          end;
//          1: str := 're';
//          2: str := IntToStr(psd1.str.uOffset);
//          3:
//          begin
//            str := psd1.str.cStr[0];
//          end
//          else
//            str := 'Unknow';
//        end;
//      end
//      else
//        str := 'error';
//
//      str := IntToStr( i ) + ' ' + str;
//
//
//      if psd.str.uType = 0 then
//        str := str + ':' + String(psd.str.pOleStr)
//      else if psd.str.uType = 1 then
//        str := 'error'
//      else if psd.str.uType = 2 then
//        str := str + ':' +IntToStr(psd.str.uOffset)
//      else if psd.str.uType = 3 then
//        str := str + ':' +string(psd.str.cStr)
//      else
//        str := 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
//
//      _Log( str );
//    end;
//  end;
  Result := True;
end;

procedure TxdSysFolder.Reset;
var
  phf: IShellFolder;
begin
  FCurFolder := nil;
  SHGetDesktopFolder( phf );
  phf.QueryInterface( IID_IShellFolder2, FCurFolder );
  phf := nil;
  FCurPath := '';
end;

function TxdSysFolder.Title(const AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex <= High(_FileAtt)) then
    Result := _FileAtt[AIndex].Title
  else
    Result := '';
end;

end.
