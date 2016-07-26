//ɨ��ָ��·��
unit uJxdScanDisk;

interface
uses
  Windows, SysUtils, Classes, StrUtils, uJxdThread;

type
  TOnScanResultEvent = procedure(Sender: TObject; const APath: string; const AInfo: TSearchRec) of object;
  
  TxdScanDisk = class
  public
    constructor Create;
    destructor  Destroy; override;

    function ScanDisk(ASaveFileNameList: TStrings = nil): Boolean;
  private
    FFilesList: TStrings;
    FScaning: Boolean;
    FScanPaths: TStringList;
    FScanByThread: Boolean;
    FAbort: PBoolean;
    FScanDepth: Integer;
    FOnScanResultEvent: TOnScanResultEvent;
    FScanFileExt: string;
    FOnScanFinished: TNotifyEvent;

    procedure DoScanDisk;
    function  IsScanPath(const APath: string): Boolean;
    procedure DoScanResult(const APath: string; const AInfo: TSearchRec);
    procedure SetScanByThread(const Value: Boolean);
    procedure SetScanDepth(const Value: Integer);
    procedure SetScanFileExt(const Value: string);
  public
    property Abort: PBoolean read FAbort write FAbort;
    property Scaning: Boolean read FScaning;
    property ScanByThread: Boolean read FScanByThread write SetScanByThread;
    property ScanFileExt: string read FScanFileExt write SetScanFileExt; //ɨ���ļ���չ�����ձ�ʾɨ�����У�����ʹ�� Pos ���ж�; *.mp3;*.wmv;
    property ScanPath: TStringList read FScanPaths;   //��ʼɨ��·��
    property ScanDepth: Integer read FScanDepth write SetScanDepth; //ɨ����ȣ��ļ�����ȣ�<=0��ʾɨ���������ļ���)

    property OnScanFinished: TNotifyEvent read FOnScanFinished write FOnScanFinished; 
    property OnScanResultEvent: TOnScanResultEvent read FOnScanResultEvent write FOnScanResultEvent;
  end;

implementation

{ TxdScanDisk }

constructor TxdScanDisk.Create;
begin
  FScaning := False;
  FScanByThread := True;
  FScanPaths := TStringList.Create;
  FScanDepth := -1;
  New( FAbort );
  FAbort^ := False;
end;

destructor TxdScanDisk.Destroy;
begin
  while Scaning do
    FAbort^ := True;
  Dispose( FAbort );
  FScanPaths.Free;
  inherited;
end;

procedure TxdScanDisk.DoScanDisk;
  procedure ScanPath(const APath: string; ACurDepth: Integer);
  var
    SearchRec: TSearchRec;
  begin
    if (FScanDepth > 0) and (ACurDepth >= FScanDepth) then Exit;    
    if not IsScanPath(APath) then Exit;
    if FindFirst(APath + '*', faAnyFile, SearchRec) <> 0 then Exit;
    try
      repeat
        if FAbort^ then Break;
        if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
          Continue;

        if (SearchRec.Attr and faDirectory) = faDirectory then
        begin
          //�ļ���
          ScanPath( APath + SearchRec.Name + '\', ACurDepth + 1 );
        end
        else
        begin
          //�ļ�
          DoScanResult( APath, SearchRec );
        end;
      until ( FindNext(SearchRec) <> 0 );
    finally
      FindClose( SearchRec );
    end;
  end;
var
  i: Integer;
begin
  FScaning := True;
  try
    for i := 0 to FScanPaths.Count - 1 do
    begin
      if FAbort^ then Break;
      ScanPath( IncludeTrailingPathDelimiter(FScanPaths[i]), 0 );
    end;
  finally
    FScaning := False;
  end;
  if Assigned(OnScanFinished) then
    OnScanFinished( Self );
end;

procedure TxdScanDisk.DoScanResult(const APath: string; const AInfo: TSearchRec);
var
  ext: string;
  bNotify: Boolean;
begin
  bNotify := True;
  if (FScanFileExt <> '') then
  begin
    ext := ExtractFileExt( AInfo.Name );
    if PosEx( LowerCase(ext), FScanFileExt ) <= 0 then
      bNotify := False;
  end;

  if bNotify then
  begin
    if Assigned(FFilesList) then
      FFilesList.Add( APath + AInfo.Name );
    if Assigned(OnScanResultEvent) then
      OnScanResultEvent( Self, APath, AInfo );
  end;
end;

function TxdScanDisk.IsScanPath(const APath: string): Boolean;
begin
  Result := True;
end;

function TxdScanDisk.ScanDisk(ASaveFileNameList: TStrings): Boolean;
begin
  Result := not FScaning and (FScanPaths.Count <> 0);
  if Result then
  begin
    FFilesList := ASaveFileNameList;
    FAbort^ := False;
    if ScanByThread then
      RunningByThread( DoScanDisk )
    else
      DoScanDisk;
  end;
end;

procedure TxdScanDisk.SetScanByThread(const Value: Boolean);
begin
  if not FScaning and (FScanByThread <> Value) then
    FScanByThread := Value;
end;

procedure TxdScanDisk.SetScanDepth(const Value: Integer);
begin
  if not FScaning and (FScanDepth <> Value) then
    FScanDepth := Value;
end;

procedure TxdScanDisk.SetScanFileExt(const Value: string);
begin
  if not FScaning then
    FScanFileExt := LowerCase( Value );
end;

end.
