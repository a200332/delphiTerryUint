unit uJxdHttpDownTask;

interface

uses
  Windows, Classes, SysUtils, Forms, uJxdThread, uJxdDataStream, idHttp, IdComponent,
  uJxdFileBlock, uJxdAsyncFileStream, MD4, uConversion;

type
  THttpSourceState = (hsNew, hsChecked);
  PHttpSourceInfo = ^THttpSourceInfo;
  THttpSourceInfo = record
    FURL: string[255];
    FReferURL: string[255];
    FState: THttpSourceState;
    FSpeed: Cardinal; //��ֵԽ���ٶ�Խ��
    FUsedCount: Integer; //��ǰ��������
  end;

  THttpDownState = (hdNull, hdBeginning, hdCheckParam, hdTransmiting, hdCheckFile, hdStopped, hdComplete, hdInvalidTask);
  TxdHttpDownTask = class
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetDownFileInfo(const AFileName: string; const AFileBlockSize: Cardinal = 0; const AFileSize: Int64 = 0);
    function AddHttpSource(const AURL: string; const AReferURL: string = ''): Boolean;

    function FindHttpSource(const AURL: string): Boolean;
    function HttpSourceCount: Integer;
    function HttpSourceItem(const AIndex: Integer; var AURL, ARefer: string): Boolean;
  private
    FTaskState: THttpDownState;
    FFileStream: TxdAsyncFileStream;
    FHttpSourceList: TList;
    FActiveHttpThreadCount: Integer;
    FStatLock: TRTLCriticalSection;
    FDownByteCount: Int64; //ƽ���ٶ���Ҫ
    FDownTime: Cardinal; //ƽ���ٶ���Ҫ
    FCurByteCount: Int64; //��ʱ�ٶ���Ҫ
    FCurTime: Cardinal; //��ʱ�ٶ���Ҫ
    FCurSpeed: string; //��ʱ�ٶ�

    procedure ActiveDownTask;
    procedure UnActiveDownTask;

    function CreateStream: Boolean;
    function CheckUrl(const AOnlyCheckMainUrl: Boolean): Boolean;
    function GetFileSizeByHttp(const AURL: string): Int64;
    function GetUrlFileHash(const AFileSize: Int64; const AUrl, AReferUrl: string; var AHash: TMD4Digest): Boolean;
    procedure AddDownByteCount(const AByteCount: Integer);
    procedure DoErrorInfo(const AInfo: string);
    procedure DoDownFinished;
    procedure DoDownFail;

    //�߳̿�ʼ����
    procedure DoThreadActive;
    //ʹ��HTTP��ʽ����
    procedure DoThreadHttpDown;
    //���HTTPԴ����Ч��
    procedure DoThreadCheckHttpSource;

    function DoGetURL(var AURL, AReferURL: string): Boolean;
    function DoGetDownInfo(var APosition: Int64; var ADataLen: Cardinal): Boolean;
    procedure DoHttpWorkBegin(Sender: TObject; AWorkMode: TWorkMode; const AWorkCountMax: Int64);
    procedure DoHttpWork(Sender: TObject; AWorkMode: TWorkMode; const AWorkCount: Int64);
    procedure DoHttpWorkEnd(Sender: TObject; AWorkMode: TWorkMode);
  private
    FActive: Boolean;
    FFileName: string;
    FFileSize: Int64;
    FFileBlockSize: Cardinal;
    FHttpThreadCount: Integer;
    FTag: Cardinal;
    FOnDownSuccess: TNotifyEvent;
    FOnDownFail: TNotifyEvent;
    FHttpMaxTryCount: Integer;
    FWaitCompleteActive: Boolean;
    FFileHash: TMD4Digest;
    FOnActiveToDownFile: TNotifyEvent;
    procedure SetActive(const Value: Boolean);
    procedure SetHttpThreadCount(const Value: Integer);
    procedure SetHttpMaxTryCount(const Value: Integer);
    function GetFileStreamID: Cardinal;
    function GetAverageSpeed: string;
    function GetCurrentSpeed: string;
    function GetFinishedSize: Int64;
  public
    property Active: Boolean read FActive write SetActive;
    property WaitCompleteActive: Boolean read FWaitCompleteActive write FWaitCompleteActive;

    property AverageSpeed: string read GetAverageSpeed;
    property CurrentSpeed: string read GetCurrentSpeed;
    property FinishedSize: Int64 read GetFinishedSize;
    property FileName: string read FFileName;
    property FileSize: Int64 read FFileSize;
    property FileStreamID: Cardinal read GetFileStreamID;
    property ActiveHttpThreadCount: Integer read FActiveHttpThreadCount;

    property HttpThreadCount: Integer read FHttpThreadCount write SetHttpThreadCount;
    property HttpMaxTryCount: Integer read FHttpMaxTryCount write SetHttpMaxTryCount;
    property Tag: Cardinal read FTag write FTag;

    property OnActiveToDownFile: TNotifyEvent read FOnActiveToDownFile write FOnActiveToDownFile;
    property OnDownSuccess: TNotifyEvent read FOnDownSuccess write FOnDownSuccess;
    property OnDownFail: TNotifyEvent read FOnDownFail write FOnDownFail;
  end;

implementation

{ TxdHttpDownTask }

procedure TxdHttpDownTask.ActiveDownTask;
begin
  if FTaskState <> hdNull then
    Exit;
  FTaskState := hdBeginning;
  FActive := True;
  RunningByThread(DoThreadActive);
  if WaitCompleteActive then
  begin
    while FTaskState in [hdBeginning, hdCheckParam] do
    begin
      Sleep(10);
      Application.ProcessMessages;
    end;
  end;
end;

procedure TxdHttpDownTask.AddDownByteCount(const AByteCount: Integer);
begin
  EnterCriticalSection(FStatLock);
  try
    FDownByteCount := FDownByteCount + AByteCount;
  finally
    LeaveCriticalSection(FStatLock);
  end;
end;

function TxdHttpDownTask.AddHttpSource(const AURL, AReferURL: string): Boolean;
var
  p: PHttpSourceInfo;
begin
  Result := FindHttpSource(AURL);
  if Result then
  begin
    Result := False;
    Exit;
  end;
  New(p);
  p^.FURL := AURL;
  p^.FReferURL := AReferURL;
  p^.FState := hsNew;
  FHttpSourceList.Add(p);
  Result := True;
  if Active then
    RunningByThread(DoThreadCheckHttpSource);
end;

function TxdHttpDownTask.CreateStream: Boolean;
var
  strURL, strRefer: string;
begin
  Result := False;
  FFileStream := nil;
  //���߳̿�ʼ���������ж�Ҫ�����ļ��������Ϣ���Ƿ���Ҫ������֤
  if not FileExists(FFileName) then
  begin
    //�ļ�������ʱ
    if FFileSize = 0 then
    begin
      if DoGetURL(strURL, strRefer) then
        FFileSize := GetFileSizeByHttp(strURL);
    end;
    if FFileSize = 0 then
      Exit;
    Result := CreateFileStream(FFileName, FFileSize, FFileBlockSize, FFileStream);
  end
  else
  begin
    //�ϵ�����, ���������ļ��Ŀɶϵ����أ�������������
    Result := CreateFileStream(FFileName, FFileSize, FFileBlockSize, FFileStream);

    if not Result then
    begin
      if FFileSize = 0 then
      begin
        if DoGetURL(strURL, strRefer) then
          FFileSize := GetFileSizeByHttp(strURL);
      end;
      if FFileSize = 0 then
        Exit;
      Result := CreateFileStream(FFileName, FFileSize, FFileBlockSize, FFileStream);
    end
    else
    begin
      FFileSize := FFileStream.Size;
    end;
  end;
end;

function TxdHttpDownTask.CheckUrl(const AOnlyCheckMainUrl: Boolean): Boolean;
var
  i, nIndex, nCount: Integer;
  p: PHttpSourceInfo;
  nSize: Int64;
  md: TMD4Digest;
begin
  if FHttpSourceList.Count = 1 then
  begin
    Result := True;
    Exit;
  end;
  Result := FHttpSourceList.Count > 0;
  if not Result then
    Exit;
  if AOnlyCheckMainUrl then
  begin
    nIndex := 0;
    nCount := 1;
  end
  else
  begin
    nIndex := 1;
    nCount := FHttpSourceList.Count;
  end;
  for i := nCount - 1 downto nIndex do
  begin
    p := FHttpSourceList[i];
    if p^.FState = hsNew then
    begin
      p^.FSpeed := GetTickCount;
      nSize := GetFileSizeByHttp(p^.FURL);
      if nSize = 0 then
      begin
        Dispose(p);
        FHttpSourceList.Delete(i);
        Continue;
      end;
      if FFileSize <= 0 then
        FFileSize := nSize;
      if FFileSize <> nSize then
      begin
        Dispose(p);
        FHttpSourceList.Delete(i);
        Continue;
      end;
      if not GetUrlFileHash(nSize, p^.FURL, p^.FReferURL, md) then
      begin
        Dispose(p);
        FHttpSourceList.Delete(i);
        Continue;
      end;
      if MD4DigestCompare(FFileHash, CEmptyMD4) then
        FFileHash := md;
      if not MD4DigestCompare(md, FFileHash) then
      begin
        Dispose(p);
        FHttpSourceList.Delete(i);
        Continue;
      end;
      p^.FState := hsChecked;
      p^.FUsedCount := 0;
      p^.FSpeed := GetTickCount - p^.FSpeed;
    end;
  end;
  Result := FHttpSourceList.Count > 0;
end;

constructor TxdHttpDownTask.Create;
begin
  InitializeCriticalSection(FStatLock);
  FFileStream := nil;
  FFileName := '';
  FHttpSourceList := TList.Create;
  FHttpThreadCount := 1;
  FHttpMaxTryCount := 10;
  FFileBlockSize := 1024 * 4;
  WaitCompleteActive := False;
  FTaskState := hdNull;
  FFileHash := CEmptyMD4;
end;

destructor TxdHttpDownTask.Destroy;
var
  i: Integer;
begin
  Active := False;
  for i := 0 to FHttpSourceList.Count - 1 do
    Dispose(PHttpSourceInfo(FHttpSourceList[i]));
  FHttpSourceList.Free;
  DeleteCriticalSection(FStatLock);
  inherited;
end;

procedure TxdHttpDownTask.DoDownFail;
begin
  if Assigned(OnDownFail) then
    OnDownFail(Self);
  if Assigned(FFileStream) then
  begin
    ReleaseFileStream(FFileStream);
    FFileStream := nil;
  end;
  FTaskState := hdInvalidTask;
end;

procedure TxdHttpDownTask.DoDownFinished;
begin
  if Assigned(FFileStream) and FFileStream.IsFileCompleted then
  begin
    FTaskState := hdComplete;
    OutputDebugString('�ļ��������');
    if Assigned(OnDownSuccess) then
      OnDownSuccess(Self);
  end
  else
  begin
    OutputDebugString('�ļ�δ�������');
    FTaskState := hdStopped;
  end;

  if Assigned(FFileStream) then
  begin
    ReleaseFileStream(FFileStream);
    FFileStream := nil;
  end;
  FTaskState := hdNull;
end;

procedure TxdHttpDownTask.DoErrorInfo(const AInfo: string);
begin
//  Dbg( AInfo );
end;

function TxdHttpDownTask.DoGetDownInfo(var APosition: Int64; var ADataLen: Cardinal): Boolean;
var
  p: PSegmentBlockInfo;
begin
  Result := False;
  if Assigned(FFileStream) then
  begin
    p := FFileStream.GetEmptySegmentInfo;
    Result := p <> nil;
    if Result then
    begin
      APosition := p^.BeginPosition;
      ADataLen := p^.SegmentSize;
    end;
  end;
end;

function TxdHttpDownTask.DoGetURL(var AURL, AReferURL: string): Boolean;
var
  i, nIndex, nCount: Integer;
  p: PHttpSourceInfo;
begin
  Result := FHttpSourceList.Count > 0;
  if not Result then
    Exit;

  if FTaskState = hdCheckParam then
  begin
    p := FHttpSourceList[0];
    AURL := p^.FURL;
    AReferURL := p^.FReferURL;
  end
  else
  begin
    nIndex := 0;
    nCount := MaxInt;
    for i := 0 to FHttpSourceList.Count - 1 do
    begin
      p := FHttpSourceList[i];
      if p^.FState = hsChecked then
      begin
        if p^.FUsedCount < nCount then
        begin
          nCount := p^.FUsedCount;
          nIndex := i;
        end;
      end;
    end;
    p := FHttpSourceList[nIndex];
    Inc(p^.FUsedCount);
    AURL := p^.FURL;
    AReferURL := p^.FReferURL;
  end;
end;

procedure TxdHttpDownTask.DoHttpWork(Sender: TObject; AWorkMode: TWorkMode; const AWorkCount: Int64);
begin
  EnterCriticalSection(FStatLock);
  try
    FCurByteCount := FCurByteCount + AWorkCount - (Sender as TIdHttp).Tag;
    (Sender as TIdHttp).Tag := AWorkCount;
//    Sleep( 100 );
  finally
    LeaveCriticalSection(FStatLock);
  end;
end;

procedure TxdHttpDownTask.DoHttpWorkBegin(Sender: TObject; AWorkMode: TWorkMode; const AWorkCountMax: Int64);
begin
  (Sender as TIdHTTP).Tag := 0;
end;

procedure TxdHttpDownTask.DoHttpWorkEnd(Sender: TObject; AWorkMode: TWorkMode);
begin

end;

procedure TxdHttpDownTask.DoThreadActive;
var
  i: Integer;
begin
  FActiveHttpThreadCount := 0;
  FTaskState := hdCheckParam;
  FActive := True;
  FDownByteCount := 0;
  FDownTime := GetTickCount;
  FCurByteCount := 0;
  FCurTime := 0;
  if not CheckUrl(True) or not CreateStream then
  begin
    FActiveHttpThreadCount := 0;
    FActive := False;
    DoDownFail;
    Exit;
  end;
  //��ʼ����
  if Assigned(OnActiveToDownFile) then
    OnActiveToDownFile(Self);
  if FHttpSourceList.Count > 1 then
    RunningByThread(DoThreadCheckHttpSource);

  FTaskState := hdTransmiting;
  for i := 0 to HttpThreadCount - 2 do
    RunningByThread(DoThreadHttpDown);
  DoThreadHttpDown;
end;

procedure TxdHttpDownTask.DoThreadCheckHttpSource;
begin
  CheckUrl(False);
end;

procedure TxdHttpDownTask.DoThreadHttpDown;
var
  http: TIdHTTP;
  ms: TMemoryStream;
  strURL, strRefer: string;
  nDataLen: Cardinal;
  nPosition: Int64;
  bOK: Boolean;
  nMaxTryCount: Integer;
  procedure CreateHttpObject;
  begin
    if Assigned(http) then
    begin
      FreeAndNil(http);
    end;
    http := TIdHTTP.Create(nil);
    with http do
    begin
      Tag := 0;
      HandleRedirects := True;
      OnWorkBegin := DoHttpWorkBegin;
      OnWork := DoHttpWork;
      OnWorkEnd := DoHttpWorkEnd;
    end;
  end;
begin
  if not Assigned(FFileStream) then
    Exit;
  InterlockedIncrement(FActiveHttpThreadCount);
  http := nil;
  nMaxTryCount := FHttpMaxTryCount;
  CreateHttpObject;
  ms := TMemoryStream.Create;
  try
    ms.Size := FFileStream.BlockSize;
    bOK := True;
    while True do
    begin
      if not DoGetURL(strURL, strRefer) then
      begin
        DoErrorInfo('�޿���HTTPԴ');
        Break;
      end;

      if not DoGetDownInfo(nPosition, nDataLen) then
        Break;

      with http do
      begin
        Request.Clear;
        Request.Referer := strRefer;
        Request.ContentRangeStart := nPosition;
        Request.ContentRangeEnd := nPosition + nDataLen - 1;
      end;

      try
        ms.Position := 0;
        if not FActive then
          Break;
        http.Get(strURL, ms);
//        Sleep( 100 );
        if http.Response.ContentLength = FFileStream.Size then
        begin
          //ĳЩ��֧�ֶϵ����صķ�����
          nPosition := 0;
          while FFileStream.Size - nPosition > 0 do
          begin
            nDataLen := FFileStream.BlockSize;
            if nDataLen > FFileStream.Size - nPosition then
              nDataLen := FFileStream.Size - nPosition;
            FFileStream.WriteBuffer(PByte(Integer(ms.Memory) + nPosition), nPosition, nDataLen);
            nPosition := nPosition + nDataLen;
          end;
          Break;
        end;

        bOK := (Cardinal(http.Response.ContentLength) = nDataLen) and (ms.Position = nDataLen);
        if bOk then
        begin
          AddDownByteCount(nDataLen);
          FFileStream.WriteBuffer(ms.Memory, nPosition, nDataLen);
          nMaxTryCount := FHttpMaxTryCount;
        end;
        if not FActive then
          Break;
      except
        bOk := False;
      end;
      if not bOK then
      begin
        DoErrorInfo('Http get error');
        Dec(nMaxTryCount);
        if nMaxTryCount <= 0 then
        begin
          DoErrorInfo('���糬ʱ');
          Break;
        end;
        CreateHttpObject;
        Sleep(100);
      end;

    end;
  finally
    FreeAndNil(ms);
    FreeAndNil(http);
  end;
  InterlockedDecrement(FActiveHttpThreadCount);
  if FActiveHttpThreadCount = 0 then
  begin
    DoDownFinished;
    FActive := False;
  end;
end;

function TxdHttpDownTask.FindHttpSource(const AURL: string): Boolean;
var
  i: Integer;
  p: PHttpSourceInfo;
begin
  Result := False;
  for i := 0 to FHttpSourceList.Count - 1 do
  begin
    p := FHttpSourceList[i];
    if CompareText(AURL, p^.FURL) = 0 then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TxdHttpDownTask.GetAverageSpeed: string;
begin
  if (not Active) or (FTaskState <> hdTransmiting) then
  begin
    Result := '0.00 KB/S';
    Exit;
  end;
  Result := FormatSpeek(FDownByteCount, GetTickCount - FDownTime);
end;

function TxdHttpDownTask.GetCurrentSpeed: string;
var
  dwTime: Cardinal;
  nSize: Int64;
begin
  if (not Active) or (FTaskState <> hdTransmiting) then
  begin
    Result := '0.00 KB/S';
    Exit;
  end;
  if FCurTime = 0 then
  begin
    Result := GetAverageSpeed;
    FCurSpeed := Result;
    FCurTime := GetTickCount;
  end
  else
  begin
    dwTime := GetTickCount;
    if dwTime - FCurTime < 1000 then
    begin
      Result := FCurSpeed;
      Exit;
    end;
    EnterCriticalSection(FStatLock);
    nSize := FCurByteCount;
    FCurByteCount := 0;
    dwTime := GetTickCount - FCurTime;
    LeaveCriticalSection(FStatLock);

    Result := FormatSpeek(nSize, dwTime);
    FCurSpeed := Result;
    FCurTime := GetTickCount;
  end;
end;

function TxdHttpDownTask.GetFileSizeByHttp(const AURL: string): Int64;
var
  http: TIdHTTP;
begin
  http := TIdHTTP.Create(nil);
  try
    http.Head(AURL);
    Result := http.Response.ContentLength;
    http.Disconnect;
    http.Free;
  except
    Result := 0;
    http.Free;
  end;
end;

function TxdHttpDownTask.GetFileStreamID: Cardinal;
begin
  if Assigned(FFileStream) then
    Result := FFileStream.StreamID
  else
    Result := 0;
end;

function TxdHttpDownTask.GetFinishedSize: Int64;
begin
  if Assigned(FFileStream) then
    Result := FFileStream.FinishedByteCount
  else
    Result := 0;
end;

function TxdHttpDownTask.GetUrlFileHash(const AFileSize: Int64; const AUrl, AReferUrl: string;
  var AHash: TMD4Digest): Boolean;
var
  http: TIdHTTP;
  ms: TMemoryStream;
  nSize: Integer;
const
  CtK = 1024;
begin
  Result := False;
  nSize := 4 * CtK;
  http := TIdHTTP.Create(nil);
  ms := TMemoryStream.Create;
  try
    ms.Size := nSize;
    ms.Position := 0;
    http.Request.Referer := AReferUrl;

    //ͷ   1K
    //β   1K
    //�м� 2K
    http.Request.ContentRangeStart := 0;
    http.Request.ContentRangeEnd := CtK - 1;
    try
      http.Get(AUrl, ms);
    except
      DoErrorInfo(Format('Can not get data to calc hash which url is "%s", and rangeStart: %d, rangeEnd: %d. FileSize: %d',
        [AUrl, http.Request.ContentRangeStart, http.Request.ContentRangeEnd, AFileSize]));
      Exit;
    end;

    http.Request.ContentRangeStart := AFileSize - CtK;
    http.Request.ContentRangeEnd := http.Request.ContentRangeStart + CtK - 1;
    try
      http.Get(AUrl, ms);
    except
      DoErrorInfo(Format('Can not get data to calc hash which url is "%s", and rangeStart: %d, rangeEnd: %d. FileSize: %d',
        [AUrl, http.Request.ContentRangeStart, http.Request.ContentRangeEnd, AFileSize]));
      Exit;
    end;

    http.Request.ContentRangeStart := (AFileSize - 2 * CtK) div 2;
    http.Request.ContentRangeEnd := http.Request.ContentRangeStart + 2 * CtK - 1;
    try
      http.Get(AUrl, ms);
    except
      DoErrorInfo(Format('Can not get data to calc hash which url is "%s", and rangeStart: %d, rangeEnd: %d. FileSize: %d',
        [AUrl, http.Request.ContentRangeStart, http.Request.ContentRangeEnd, AFileSize]));
      Exit;
    end;

    MD4Stream(ms, AHash);
    Result := True;
  finally
    FreeAndNil(http);
    FreeAndNil(ms);
  end;
end;

function TxdHttpDownTask.HttpSourceCount: Integer;
begin
  Result := FHttpSourceList.Count;
end;

function TxdHttpDownTask.HttpSourceItem(const AIndex: Integer; var AURL, ARefer: string): Boolean;
var
  p: PHttpSourceInfo;
begin
  Result := (AIndex >= 0) and (AIndex < FHttpSourceList.Count);
  if Result then
  begin
    p := FHttpSourceList[AIndex];
    AURL := p^.FURL;
    ARefer := p^.FReferURL;
  end;
end;

procedure TxdHttpDownTask.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
      ActiveDownTask
    else
      UnActiveDownTask;
  end;
end;

procedure TxdHttpDownTask.SetDownFileInfo(const AFileName: string; const AFileBlockSize: Cardinal; const AFileSize: Int64);
begin
  if Active then
    Exit;
  FFileName := AFileName;
  FFileSize := AFileSize;
  if AFileBlockSize <> 0 then
    FFileBlockSize := AFileBlockSize;
end;

procedure TxdHttpDownTask.SetHttpMaxTryCount(const Value: Integer);
begin
  if (FHttpMaxTryCount <> Value) and (Value > 0) then
    FHttpMaxTryCount := Value;
end;

procedure TxdHttpDownTask.SetHttpThreadCount(const Value: Integer);
begin
  if (not Active) and (FHttpThreadCount <> Value) then
    FHttpThreadCount := Value;
end;

procedure TxdHttpDownTask.UnActiveDownTask;
begin
  try
    FActive := False;
    while WaitCompleteActive and (FActiveHttpThreadCount > 0) do
    begin
      Sleep(10);
      Application.ProcessMessages;
    end;
  except
  end;
end;

end.

