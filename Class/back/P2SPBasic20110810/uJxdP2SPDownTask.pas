{
��Ԫ����: uJxdP2SPDownTask
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com  jxd524@gmail.com
˵    ��:
��ʼʱ��: 2011-04-11
�޸�ʱ��: 2011-05-06 (����޸�ʱ��)
��˵��  :

    ������������Ĺ�������P2P���أ�HTTP���أ�FTP���صĹ����ļ��ֶ����ط�ʽ
        ��������Ҫ��������Ϣ���ⲿ�ṩ���๦��ֻ��Ҫ���ݲ������к���ĵ��ȣ�����

����ѡ��
    ExclusionP2P: ��ʹ��P2P����, ֻʹ��HTTP
}

unit uJxdP2SPDownTask;

interface

uses
  Windows, Classes, SysUtils, uJxdHashCalc, uJxdDataStream, uJxdFileSegmentStream, uJxdCmdDefine, uJxdUdpSynchroBasic, uJxdServerManage,
  idHttp, IdComponent;

{$I JxdUdpOpt.inc}

type
  //����ֿ������, ÿ����������ʱ���á�
  TRequestBlockManage = class
  public
    constructor Create;
    destructor  Destroy; override;

    procedure Clear;
    procedure AddRequestBlock(const ASegIndex, ABlockIndex: Integer);
    procedure FinishedBlock(const ASegIndex, ABlockIndex: Integer);
  private
    FRequestBlockCount,
    FRequestCount,
    FFinishedCount: Integer;
    FBlocks: array of Cardinal;
    FLastRequestTime: Cardinal;
    function  CalcID(const ASegIndex, ABlockIndex: Integer): Cardinal; inline;
  public
    property LastRequestTime: Cardinal read FLastRequestTime;
    property RequestCount: Integer read FRequestCount; //����ֿ�����
    property FinishedCount: Integer read FFinishedCount; //��ɷֿ�����
  end;

  {$IFNDEF ExclusionP2P}
  {P2PԴ��Ϣ�ṹ}
  TSourceState = (ssUnkown, ssChecking, ssSuccess);
  PP2PSource = ^TP2PSource;
  TP2PSource = record
    FIP: Cardinal; //P2P�û�ID
    FPort: Word; //P2P�û��˿�
    FState: TSourceState; //P2P״̬
    FServerSource: Boolean; //�Ƿ��Ƿ���Դ��������Դ��ʾ��Դ�Դ��ļ�ӵ���������ݣ�������Ҫ��ʱ��ѯ��Դ�ķֶ���Ϣ  
    FLastCheckStateTime: Cardinal;
    FTimeoutCount: Integer; //��ʱ�������������ݺ��޽��յ�����ʱʹ��
    FRequestBlockManage: TRequestBlockManage; //����ֿ������
    FSegTableState: TxdSegmentStateTable; //P2P�û������ļ��ֶ���Ϣ��
    FTotalRecvByteCount: Integer; //�ܹ����յ������ݳ���
  end;
  {$ENDIF}

  {HttpԴ��Ϣ�ṹ}
  PHttpSource = ^THttpSource;
  THttpSource = record
    FUrl: string;
    FReferUrl: string;
    FCookies: string;
    FTotalRecvByteCount: Integer;
  end;
  {$M+}
  TxdP2SPDownTask = class                               
  public
    constructor Create;
    destructor  Destroy; override;
    //��ʼ��������Ϣ
    function  SetFileInfo(const ASaveFileName: string; const AFileHash: TxdHash; const AWebHash: TxdHash): Boolean;
    function  SetSegmentTable(const ATable: TxdFileSegmentTable): Boolean;
    procedure SaveAs(const ANewFileName: string); //������ɺ�ı�
    procedure CheckFileStream; //

    {P2P�ļ�����}
  {$IFNDEF ExclusionP2P}
    function  SetUdp(AUdp: TxdUdpSynchroBasic): Boolean;
    //P2PԴ
    procedure AddP2PSource(const AIP: Cardinal; const APort: Word; const AServerSource: Boolean; const AState: TSourceState = ssUnkown; const ATotalByteCount: Integer = -1);
    function  IsExistsSource(const AIP: Cardinal; const APort: Word): Boolean; overload;
    function  GetP2PSourceInfo(var AInfo: TAryServerInfo): Integer; overload;
    function  GetP2PSourceInfo(const AIndex: Integer; AInfo: PP2PSource): Boolean; overload;
    procedure DeleteP2PSource(const AIP: Cardinal; const APort: Word);

    //�������ݽӿ�
    procedure DoRecvReplyQueryFileInfo(const AIP: Cardinal; const APort: Word; const ACmd: PCmdReplyQueryFileInfo);
    procedure DoCmdReply_QueryFileProgress(const AIP: Cardinal; const APort: Word; const ACmd: PCmdReplyQueryFileProgressInfo);
    procedure DoRecvFileData(const AIP: Cardinal; const APort: Word; const ABuf: PByte; const ABufLen: Integer);
    procedure DoRecvFileSegmentHash(const AIP: Cardinal; const APort: Word; const ABuf: PByte; const ABufLen: Integer);
  {$ENDIF}

    {Http�ļ�����}
    procedure AddHttpSource(const AUrl, ARefer, ACookies: string; const ATotalByteCount: Integer = -1);
    function  IsExistsSource(const AUrl: string): Boolean; overload;
    function  GetHttpSourceInfo(const AIndex: Integer; AInfo: PHttpSource): Boolean;

    //ִ�����غ���
    procedure DoExcuteDownTask; //�˺������ⲿ���ϵ���
  private
  {$IFNDEF ExclusionP2P}
    FUdp: TxdUdpSynchroBasic;
    FP2PLastUsedIndex: Integer;
    FP2PSourceList: TThreadList;
    //�ֶ�HASH��֤��Ϣ
    FCheckSegmentHashing: Boolean;
    FCheckSegmentHashSize: Cardinal;
    FRecvSegmentHash: array of TxdHash;
  {$ENDIF}

    FFileStream: TxdFileSegmentStream;  //�ļ���
    FSegmentTable: TxdFileSegmentTable; //�ļ��ֶα�

    FHttpLastUsedIndex: Integer;
    FHttpGettingFileSize: Boolean;
    FHttpSourceList: TThreadList;
    FHttpThreadList: TList;

    FLastExcuteTime: Cardinal; //���ִ��ʱ��
    FLastCheckSegmentTableTime: Cardinal; //���ֶα���ʱ��

    FLastCalcSpeekTime: Cardinal;
    FCalcRecvByte: Integer;


    FIsEmptyWebHash: Boolean;

    FSaveAsFileName: string;

    FLasCheckSegmentHashTime: Cardinal;
    FLockCalcWebHash: TRTLCriticalSection;

    procedure ClearList(const AList: TThreadList);
    procedure ClearHttpThread;

    procedure ActiveDownTask;
    procedure UnActiveDownTask;

    procedure CalcWebHash;    
    procedure DoErrorInfo(const AInfo: string);

  {$IFNDEF ExclusionP2P}
    function  GetHashCheckSegmentPeer: PP2PSource;
    procedure DoInvalidP2PSource(Ap: PP2PSource); //֪ͨ��Ч��P2PԴ
    procedure FreeP2PSourceMem(var p: PP2PSource); //�ͷ�P2PԴռ���ڴ�
    procedure ResetP2PSourceStat;

    function  GetFileInfoByP2P(p: PP2PSource): Boolean; //��ָ���û���ȡ�ļ���Ϣ
    function  GetMaxBlockCount(p: PP2PSource): Integer; //�����P2P�ֿ�����
    function  IsCanGetMostNeedBlock(p: PP2PSource): Boolean; //�Ƿ�����������Ҫ�ֿ�

    procedure DoCheckSegmentHash(Ap: PP2PSource);
    procedure DoCompareSegmentHash;

    //����ִ�к���
    procedure DownFileDataByP2P;
  {$ENDIF}

    //����ִ�к���
    procedure CheckHttpDownThreadControl;
    procedure DownFileDataByHttp;
    procedure DoThreadToGetFileSizeByHttp;

    //���Ƽ��
    function  DoCheckTaskSuccess: Boolean;
    procedure DoCheckTaskSpeed;  //���������ܵ������ٶ�
    procedure DoCheckSegmentTable; //����ֶα����Ѿ���ʱ����Ϣ
    procedure DoCheckFileSegmentInfo(const AFileSize: Int64; const ASegmentSize: Integer);

    //Hash ����
    procedure DoDownSuccess;
    procedure RelationSegmentTableEvent;
    //�¼�����
    procedure DoCompletedSegment(const ASegIndex: Integer); //ĳһ�ֶ��������
{$IFNDEF ExclusionP2P}
  private
    FMaxP2PSource: Integer;
    FMaxSearchCount: Integer;
    FMaxRequestBlockCount: Integer;
    FCheckP2PDownProgressSpaceTime: Cardinal;
    function  GetCurP2PSourceCount: Integer;
    procedure SetMaxP2PSource(const Value: Integer);
    procedure SetMaxSearchCount(const Value: Integer);
    procedure SetMaxRequestBlockCount(const Value: Integer);
{$ENDIF}
  private
    FActive: Boolean;
    FFileName: string;
    FFileSize: Int64;
    FFileHash: TxdHash;
    FFileSegmentSize: Integer;
    FSpeekLimit: Integer;
    FCurSpeek: Integer;
    FWebHash: TxdHash;
    FFinished: Boolean;
    FHttpThreadCount: Integer;
    FTaskName: string;
    procedure SetActive(const Value: Boolean);
    procedure SetSpeekLimit(const Value: Integer);
    procedure SetHttpThreadCount(const Value: Integer);
    function  GetCurHttpThreadCount: Integer;
    function  GetHttpSourceCount: Integer;
    function  GetFileStreamID: Integer;
  published
    property Active: Boolean read FActive write SetActive; //�Ƿ�������
    property Finished: Boolean read FFinished; //�����Ƿ����
    property TaskName: string read FTaskName write FTaskName; //��������
    property FileName: string read FFileName; //�ļ�����
    property SaveAsFileName: string read FSaveAsFileName; //�ļ�������ɺ��������
    property FileSize: Int64 read FFileSize; //�ļ���С
    property FileHash: TxdHash read FFileHash; //�ֿ�HASH
    property WebHash: TxdHash read FWebHash; //Web HASH
    property FileSegmentSize: Integer read FFileSegmentSize; //�ļ��ֶδ�С
    property SegmentTable: TxdFileSegmentTable read FSegmentTable; //�ļ��ֶα�, ���ͷ�ʱ�ͷŴ˱�
    property FileStreamID: Integer read GetFileStreamID;

    property SpeekLimit: Integer read FSpeekLimit write SetSpeekLimit; //�ٶ����� ��λ��KB/S
    property CurSpeek: Integer read FCurSpeek; //��ǰ�ٶ� ��λ��B/MS

  {$IFNDEF ExclusionP2P}
    {P2PԴ}
    property CurP2PSourceCount: Integer read GetCurP2PSourceCount;
    property MaxP2PSource: Integer read FMaxP2PSource write SetMaxP2PSource; //���P2PԴ(�����ļ�������Դ)
    property MaxSearchCount: Integer read FMaxSearchCount write SetMaxSearchCount; //�����������
    property MaxRequestBlockCount: Integer read FMaxRequestBlockCount write SetMaxRequestBlockCount;  //P2P�����������ֿ�����, �ֿ��С��TxdFileSegmentTableָ��
    property CheckP2PDownProgressSpaceTime: Cardinal read FCheckP2PDownProgressSpaceTime write FCheckP2PDownProgressSpaceTime;//����P2P���ؽ���
  {$ENDIF}

    {HttpԴ}
    property CurHttpSourceCount: Integer read GetHttpSourceCount;

    property CurHttpThreadCount: Integer read GetCurHttpThreadCount; //��ǰHTTP����ʹ���߳�����
    property HttpThreadCount: Integer read FHttpThreadCount write SetHttpThreadCount; //Http�����߳�����
  end;
  {$M-}
  
implementation

uses
  uJxdThread, uSocketSub, uConversion;

const
  {$IFNDEF ExclusionP2P}
  CtP2PSourceSize = SizeOf(TP2PSource);
  {$ENDIF}
  CtHttpSourceSize = SizeOf(THttpSource);
  CtTimeOutTimeSpace = 2000;
  CtMaxTimeoutCount = 10;
  CtMinSpaceTime = 5;

{ TxdP2SPDownTask }

procedure TxdP2SPDownTask.ActiveDownTask;
begin
  try

    CheckFileStream;
    ClearHttpThread;

    InitializeCriticalSection( FLockCalcWebHash );
    {$IFNDEF ExclusionP2P}
    FP2PLastUsedIndex := -1;
    FCheckSegmentHashing := False;
    {$ENDIF}

    FCalcRecvByte := 0;
    FLastCheckSegmentTableTime := 0;
    FLastExcuteTime := 0;
    FLastCalcSpeekTime := 0;
    FHttpGettingFileSize := False;
    FLasCheckSegmentHashTime := 0;
    FActive := True;

//    OutputDebugString( PChar(HashToStr(FFileHash)) );
  except
    FActive := False;
    UnActiveDownTask;
  end;
end;

procedure TxdP2SPDownTask.AddHttpSource(const AUrl, ARefer, ACookies: string; const ATotalByteCount: Integer);
var
  p: PHttpSource;
  lt: TList;
  i: Integer;
  bFind: Boolean;
begin
  if AUrl = '' then Exit;
  bFind := False;
  lt := FHttpSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if CompareText(AUrl, p^.FUrl) = 0 then
      begin
        bFind := True;
        Break;
      end;
    end;
    if not bFind then
    begin
      New( p );
      p^.FUrl := AUrl;
      p^.FReferUrl := ARefer;
      p^.FCookies := ACookies;
      if ATotalByteCount > 0 then
        p^.FTotalRecvByteCount := ATotalByteCount;
      lt.Add( p );
    end;
  finally
    FHttpSourceList.UnlockList;
  end;
end;

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.AddP2PSource(const AIP: Cardinal; const APort: Word; const AServerSource: Boolean; const AState: TSourceState; const ATotalByteCount: Integer);
var
  p: PP2PSource;
  bFind: Boolean;
  lt: TList;
  i: Integer;
begin
  bFind := False;
  lt := FP2PSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if (p^.FIP = AIP) and (p^.FPort = APort) then
      begin
        if ATotalByteCount > 0 then
          p^.FTotalRecvByteCount := ATotalByteCount;
        p^.FState := AState;
        bFind := True;
        Break;
      end;
    end;
    if not bFind then
    begin
      New( p );
      FillChar( p^, CtP2PSourceSize, 0 );
      p^.FIP := AIP;
      p^.FState := AState;
      p^.FPort := APort;
      p^.FServerSource := AServerSource;
      p^.FRequestBlockManage := TRequestBlockManage.Create;
      if ATotalByteCount > 0 then
        p^.FTotalRecvByteCount := ATotalByteCount;
      lt.Add( p );
    end;
  finally
    FP2PSourceList.UnlockList;
  end;
end;
{$ENDIF}

procedure TxdP2SPDownTask.CalcWebHash;
var
  bCanCalc: Boolean;
begin
  if Active and FIsEmptyWebHash then
  begin
    EnterCriticalSection( FLockCalcWebHash );
    try
      if Active and FIsEmptyWebHash then
      begin
        case FSegmentTable.SegmentCount of
          1: bCanCalc := (PSegmentInfo(FSegmentTable.SegmentList[0])^.FSegmentState = ssCompleted);
          2: bCanCalc := (PSegmentInfo(FSegmentTable.SegmentList[0])^.FSegmentState = ssCompleted) and
                         (PSegmentInfo(FSegmentTable.SegmentList[1])^.FSegmentState = ssCompleted);
          else
             bCanCalc := (PSegmentInfo(FSegmentTable.SegmentList[0])^.FSegmentState = ssCompleted) and
                      (PSegmentInfo(FSegmentTable.SegmentList[FSegmentTable.SegmentCount div 2])^.FSegmentState = ssCompleted) and
                      (PSegmentInfo(FSegmentTable.SegmentList[FSegmentTable.SegmentCount - 1])^.FSegmentState = ssCompleted);
        end;
        if bCanCalc then
          CalcFileWebHash( FFileStream, FWebHash, nil )
        else
          Exit;
        FIsEmptyWebHash := HashCompare( FWebHash, CtEmptyHash );
        if not FIsEmptyWebHash then
        begin
          OutputDebugString( PChar(HashToStr(FWebHash)) );
        end
        else
          OutputDebugString( 'WEB HASH ֵ Ϊ��' );
      end;
    finally
      LeaveCriticalSection( FLockCalcWebHash );
    end;
  end;
end;

procedure TxdP2SPDownTask.CheckFileStream;
begin
  if Assigned(FSegmentTable) and not Assigned(FFileStream) then
  begin
    FFileStream := StreamManage.CreateFileStream(FFileName, FSegmentTable);
    FFileStream.SetFileHash( FFileHash );
    FFileStream.RenameFileName := FSaveAsFileName;

//    FSegmentTable.AddPriorityDownInfo( 0 );
//    FSegmentTable.AddPriorityDownInfo( 1 );
//    FSegmentTable.AddPriorityDownInfo( FSegmentTable.SegmentCount - 1 );
//    FSegmentTable.AddPriorityDownInfo( FSegmentTable.FileSize - 1024, 1024 );
  end;
end;

procedure TxdP2SPDownTask.CheckHttpDownThreadControl;
var
  i, nCount: Integer;
  obj: TThreadCheck;
begin
  nCount := FHttpSourceList.LockList.Count;
  FHttpSourceList.UnlockList;
  if nCount = 0 then Exit;
  if not Assigned(FSegmentTable) and not FHttpGettingFileSize then
  begin
    FHttpGettingFileSize := True;
    RunningByThread( DoThreadToGetFileSizeByHttp );
    Exit;
  end;
  nCount := HttpThreadCount - FHttpThreadList.Count;
  for i := 0 to nCount - 1 do
  begin
    obj := TThreadCheck.Create( DownFileDataByHttp, 1 );
    FHttpThreadList.Add( obj );
  end;
end;

procedure TxdP2SPDownTask.ClearHttpThread;
var
  i: Integer;
  obj: TThreadCheck;
begin
  for i := 0 to FHttpThreadList.Count - 1 do
  begin
    obj := FHttpThreadList[i];
    obj.Free;
  end;
  FHttpThreadList.Clear;
end;

procedure TxdP2SPDownTask.ClearList(const AList: TThreadList);
var
  i: Integer;
  lt: TList;
begin
  lt := AList.LockList;
  try
    for i := 0 to lt.Count - 1 do
      Dispose( lt[i] );
    lt.Clear;
  finally
    AList.UnlockList;
  end;
end;

constructor TxdP2SPDownTask.Create;
begin
  FActive := False;
  {$IFNDEF ExclusionP2P}
  FMaxRequestBlockCount := 8;
  FMaxP2PSource := 10;
  FMaxSearchCount := 5;
  FCheckP2PDownProgressSpaceTime := 60 * 1000 * 2;
  FP2PSourceList := TThreadList.Create;
  {$ENDIF}
  FLastCalcSpeekTime := 0;
  FCalcRecvByte := 0;
  FIsEmptyWebHash := True;
  FFinished := False;
  FHttpThreadCount := 1;
  FHttpSourceList := TThreadList.Create;
  FHttpThreadList := TList.Create;
end;

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.DeleteP2PSource(const AIP: Cardinal; const APort: Word);
var
  p: PP2PSource;
  i: Integer;
  lt: TList;
begin
  lt := FP2PSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if (p^.FIP = AIP) and (p^.FPort = APort) then
      begin
        lt.Delete( i );
        FreeP2PSourceMem( p );
        Break;
      end;
    end;
  finally
    FP2PSourceList.UnlockList;
  end;
end;
{$ENDIF}

destructor TxdP2SPDownTask.Destroy;
{$IFNDEF ExclusionP2P}
var
  i: Integer;
  p: PP2PSource;
  lt: TList;
{$ENDIF}
begin
  Active := False;
  {$IFNDEF ExclusionP2P}
  lt := FP2PSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      FreeP2PSourceMem( p );
    end;
  finally
    FP2PSourceList.UnlockList;
  end;
  FreeAndNil( FP2PSourceList );
  {$ENDIF}

  ClearList( FHttpSourceList );
  FreeAndNil( FHttpSourceList );
  ClearHttpThread;
  FreeAndNil( FHttpThreadList );
//  FreeAndNil( FSegmentTable );
  inherited;
end;

procedure TxdP2SPDownTask.DoCheckFileSegmentInfo(const AFileSize: Int64; const ASegmentSize: Integer);
begin
  if not Assigned(FSegmentTable) then
  begin
    FSegmentTable := TxdFileSegmentTable.Create( AFileSize, [], ASegmentSize );
    FFileSize := FSegmentTable.FileSize;
    FFileSegmentSize := FSegmentTable.SegmentSize;
    RelationSegmentTableEvent;
  end
  else if FSegmentTable.FileSize <> AFileSize then
  begin
    if FSegmentTable.IsEmpty then
    begin
      FSegmentTable.Free;
      FSegmentTable := TxdFileSegmentTable.Create( AFileSize, [], ASegmentSize );
      FFileSize := FSegmentTable.FileSize;
      FFileSegmentSize := FSegmentTable.SegmentSize;
      RelationSegmentTableEvent;
    end;
  end;
  if Active then CheckFileStream;
end;

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.DoCheckSegmentHash(Ap: PP2PSource);
var
  cmd: TCmdGetFileSegmentHashInfo;
begin
  if GetTickCount - FLasCheckSegmentHashTime >= 5000 then
  begin
    if not Assigned(Ap) then
      Ap := GetHashCheckSegmentPeer;
    if not Assigned(Ap) then Exit;
    FUdp.AddCmdHead( @Cmd, CtCmd_GetFileSegmentHash );
    Move( FFileHash, cmd.FHash, CtHashSize );
    FLasCheckSegmentHashTime := GetTickCount;
    FUdp.SendBuffer( Ap^.FIP, Ap^.FPort, @Cmd, CtCmdGetFileSegmentHashInfoSize );
  end;
end;
{$ENDIF}

procedure TxdP2SPDownTask.DoCheckSegmentTable;
begin
  if FLastCheckSegmentTableTime = 0 then
    FLastCheckSegmentTableTime := FLastExcuteTime;
  if FLastExcuteTime - FLastCheckSegmentTableTime > FSegmentTable.BlockMaxWaitTime then
  begin
    //��鳬ʱ
    FSegmentTable.CheckDownReplyWaitTime;
    FLastCheckSegmentTableTime := GetTickCount;
  end;
end;

procedure TxdP2SPDownTask.DoCheckTaskSpeed;
var
  nTemp: Cardinal;
begin
  if FLastCalcSpeekTime = 0 then
    FLastCalcSpeekTime := GetTickCount
  else
  begin
    nTemp := GetTickCount;
    if nTemp - FLastCalcSpeekTime > 1000 then
    begin
      FCurSpeek := FCalcRecvByte div Integer(nTemp - FLastCalcSpeekTime);
      OutputDebugString( PChar('�����ٶȣ�' + FormatSpeek(FCurSpeek)) );
      FLastCalcSpeekTime := GetTickCount;
      InterlockedExchange( FCalcRecvByte, 0 );
    end;
  end;
end;

function TxdP2SPDownTask.DoCheckTaskSuccess: Boolean;
begin
  //�ļ��������
  Result := FSegmentTable.IsCompleted;
  if Result then
  begin
    //���ļ�HASH����ʾ������HTTP����
    if (HashCompare(CtEmptyHash, FFileHash)) or ((FLasCheckSegmentHashTime = 0) and HashCompare(FFileStream.CalcFileHash(nil), FFileHash)) then
    begin
      //�ļ����سɹ�
      DoDownSuccess;
    end
    else
    begin
      OutputDebugString( 'Hash ��֤ʧ��' );
      //һ�����������Ҫ�õ��ֶ�HASH��֤��
      {$IFNDEF ExclusionP2P}
      if FCheckSegmentHashing then
      begin
        //��������ֶ���Ϣ
        DoCompareSegmentHash;
      end
      else
      begin
        //����ֶ�HASH
        DoCheckSegmentHash(nil);
      end;
      {$ELSE}
      //
      {$ENDIF}
    end;
  end;
end;

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.DoCmdReply_QueryFileProgress(const AIP: Cardinal; const APort: Word; const ACmd: PCmdReplyQueryFileProgressInfo);
var
  i: Integer;
  lt: TList;
  p: PP2PSource;
begin
  lt := FP2PSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if (p^.FIP = AIP) and (p^.FPort = APort) then
      begin
        //�����ѯ������Ϣ��������Դ����Ҳû����֤�ɹ�����ɾ��������Դ
        if (ACmd^.FReplySign <> rsSuccess) and (p^.FState <> ssSuccess) then
        begin
          lt.Delete( i );
          FreeP2PSourceMem( p );
          Break;
        end;

        if ACmd^.FReplySign = rsSuccess then
        begin
          if ACmd^.FTableLen <= 0 then
          begin
            //��ʾ����Դ�Ѿ�ӵ������������
            if Assigned(p^.FSegTableState) then
              FreeAndNil( p^.FSegTableState );
            p^.FServerSource := True; //
          end
          else
          begin
            if Assigned(FSegmentTable) then 
            begin
              if not Assigned(p^.FSegTableState) then
                p^.FSegTableState := TxdSegmentStateTable.Create;
              p^.FSegTableState.MakeByMem( FSegmentTable.SegmentCount, PByte(ACmd^.FTableBuffer[0]), ACmd^.FTableLen );
            end;
          end;
        end;
        p^.FLastCheckStateTime := GetTickCount;
        Break;
      end;
    end;
  finally
    FP2PSourceList.UnlockList;
  end;
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.DoCompareSegmentHash;
var
  i, j, nCount, nSegIndex: Integer;
  aryCalcSegHash: array of TxdHash;
  buf: PByte;
  nReadSize: Integer;
  bRedown: Boolean;
begin  
  FCheckSegmentHashing := False;
  FLasCheckSegmentHashTime := 0;
  bRedown := False;

  nCount := Length(FRecvSegmentHash);
  if nCount = 0 then Exit;
  SetLength( aryCalcSegHash, nCount );
  GetMem( buf, FCheckSegmentHashSize );
  try
    for i := 0 to nCount - 1 do
    begin
      if i = nCount - 1 then
        nReadSize := FFileSize - Cardinal(i) * FCheckSegmentHashSize
      else
        nReadSize := FCheckSegmentHashSize;
      FFileStream.ReadBuffer(Cardinal(i) * FCheckSegmentHashSize, nReadSize, buf);
      aryCalcSegHash[i] := HashBuffer( buf, nReadSize );
    end;
  finally
    FreeMem( buf, FCheckSegmentHashSize );
  end;

  for i := 0 to nCount - 1 do
  begin
    if not HashCompare(aryCalcSegHash[i], FRecvSegmentHash[i]) then
    begin
      bRedown := True;
//      OutputDebugString( PChar('Hash ����ͬ: ' + IntToStr(i)) );
      nSegIndex := (Cardinal(i) * FCheckSegmentHashSize + FSegmentTable.SegmentSize - 1) div FSegmentTable.SegmentSize;
      for j := nSegIndex to nSegIndex + Integer((FCheckSegmentHashSize + FSegmentTable.SegmentSize - 1) div FSegmentTable.SegmentSize) do
        FSegmentTable.ResetSegment( j );
    end;
  end;

  if bRedown and not FIsEmptyWebHash then
  begin
    //���¼���WEB HASH
    FIsEmptyWebHash := True;
    FWebHash := CtEmptyHash;
  end;
end;
{$ENDIF}

procedure TxdP2SPDownTask.DoCompletedSegment(const ASegIndex: Integer);
begin
  if (ASegIndex = 0) or (ASegIndex = FSegmentTable.SegmentCount - 1) or (ASegIndex = FSegmentTable.SegmentCount div 2) then
    CalcWebHash;
end;

procedure TxdP2SPDownTask.DoDownSuccess;
begin
  ClearHttpThread;
  if HashCompare(CtEmptyHash, FFileHash) then
    FFileHash := FFileStream.CalcFileHash(nil);
  FFinished := True;
  if Assigned(FFileStream) then
  begin
    FFileStream.CompletedFile;
    StreamManage.ReleaseFileStream( FFileStream );
    FFileStream := nil;
  end;

  OutputDebugString( '�ļ����سɹ�' );
  OutputDebugString( PChar('web Hash: ' + HashToStr(FWebHash)) );
  OutputDebugString( PChar('File Hash: ' + HashToStr(FFileHash)) );
end;

procedure TxdP2SPDownTask.DoErrorInfo(const AInfo: string);
begin
  OutputDebugString( PChar(AInfo) );
end;

procedure TxdP2SPDownTask.DoExcuteDownTask;
var
  dwTime: Cardinal;
begin
  if not Active then Exit;
  dwTime := GetTickCount;
//  if (dwTime > FLastExcuteTime) and (dwTime - FLastExcuteTime < CtMinSpaceTime) then Exit;
  FLastExcuteTime := dwTime;
  CheckHttpDownThreadControl;
  {$IFNDEF ExclusionP2P}
  DownFileDataByP2P;
  {$ENDIF}
  if not Assigned(FSegmentTable) then Exit;
  if DoCheckTaskSuccess then Exit;
  DoCheckTaskSpeed;  //�����ٶ�
  DoCheckSegmentTable; //��鳬ʱ
end;


{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.DoInvalidP2PSource(Ap: PP2PSource);
begin
  OutputDebugString( PChar('��Ч������Դ��' + IpToStr(Ap^.FIP, Ap^.FPort)) );
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.DoRecvFileData(const AIP: Cardinal; const APort: Word; const ABuf: PByte; const ABufLen: Integer);
var
  pCmd: PCmdReplyRequestFileInfo;
  nPos: Int64;
  nSize: Cardinal;
  i: Integer;
  lt: TList;
  p: PP2PSource;
begin
  if not FActive then
  begin
    OutputDebugString( '������ֹͣ��ֱ�Ӷ�������' );
    Exit;
  end;
  if ABufLen < CtMinPackageLen + CtHashSize + 1 then
  begin
    DoErrorInfo( '���յ���P2P�ļ��������ݳ��Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdReplyRequestFileInfo(ABuf);
  if pCmd^.FReplySign <> rsSuccess then
  begin
    DoErrorInfo( '���󲻵�ָ����P2P����' );
    Exit;
  end;
  if not FSegmentTable.GetBlockSize(pCmd^.FSegmentIndex, pCmd^.FBlockIndex, nPos, nSize) then
  begin
    DoErrorInfo( '���յ���P2P���ݵķֶλ�ֿ���Ų���ȷ' );
    Exit;
  end;
  if nSize <> pCmd^.FBufferLen then
  begin
    DoErrorInfo( '���յ���P2P�ļ����ݵĳ����뱾�ؼ���Ĳ�һ��' );
    Exit;
  end;
  
  //����
  lt := FP2PSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if (p^.FIP = AIP) and (p^.FPort = APort) then
      begin
        p^.FRequestBlockManage.FinishedBlock( pCmd^.FSegmentIndex, pCmd^.FBlockIndex );
        Inc( p^.FTotalRecvByteCount, pCmd^.FBufferLen );
        Break;
      end;
    end;
  finally
    FP2PSourceList.UnlockList;
  end;

  //д���ļ�
  FFileStream.WriteBlockBuffer( pCmd^.FSegmentIndex, pCmd^.FBlockIndex, @pCmd^.FBuffer, pCmd^.FBufferLen );
  InterlockedExchangeAdd( FCalcRecvByte, pCmd^.FBufferLen );
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.DoRecvFileSegmentHash(const AIP: Cardinal; const APort: Word; const ABuf: PByte; const ABufLen: Integer);
var
  pCmd: PCmdReplyGetFileSegmentHashInfo;
  i, nCount: Integer;
begin
  if ABufLen < CtCmdReplyGetFileSegmentHashInfoSize then
  begin
    DoErrorInfo( '���յ��ķֶ�HASH��֤��Ϣ����' );
    Exit;
  end;
  pCmd := PCmdReplyGetFileSegmentHashInfo( ABuf );
  FCheckSegmentHashSize := pCmd^.FHashCheckSegmentSize;
  if (FCheckSegmentHashSize = 0) or (FCheckSegmentHashSize > FFileSize) then
  begin
    DoErrorInfo( '���յ���HASH����ֶβ���ȷ' );
    Exit;
  end;
  nCount := (FFileSize + FCheckSegmentHashSize - 1) div FCheckSegmentHashSize;
  SetLength( FRecvSegmentHash, nCount );
  for i := 0 to nCount - 1 do
    Move( pCmd^.FSegmentHashs[i * CtHashSize], FRecvSegmentHash[i], CtHashSize );
  FCheckSegmentHashing := True;
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.DoRecvReplyQueryFileInfo(const AIP: Cardinal; const APort: Word; const ACmd: PCmdReplyQueryFileInfo);
var
  md: TxdHash;
  i: Integer;
  lt: TList;
  p: PP2PSource;
begin
  if ACmd^.FHashStyle = hsWebHash then
    md := TxdHash(ACmd^.FFileHash)
  else
    md := TxdHash(ACmd^.FHash);

  lt := FP2PSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if (p^.FIP = AIP) and (p^.FPort = APort) then
      begin
        if ACmd^.FReplySign <> rsSuccess then
        begin
          lt.Delete( i );
          FreeP2PSourceMem( p );
          Break;
        end;

        //����Ϊ�ɹ�, ����Ƿ�����Դ��ֱ���������ݣ������ѯ����Դ����
        if p^.FState <> ssSuccess then p^.FState := ssSuccess;

        DoCheckFileSegmentInfo( ACmd^.FFileSize, ACmd^.FFileSegmentSize );
        if HashCompare(FFileHash, CtEmptyHash) then
          FFileHash := md;
        p^.FLastCheckStateTime := GetTickCount;

        Break;
      end;
    end;
  finally
    FP2PSourceList.UnlockList;
  end;
end;
{$ENDIF}

procedure TxdP2SPDownTask.DoThreadToGetFileSizeByHttp;
  function  GetFileSizeByHttp(const AURL: string): Int64;
  var
    http: TIdHTTP;
  begin
    http := TIdHTTP.Create( nil );
    try
      http.Head( AURL );
      Result := http.Response.ContentLength;
      http.Disconnect;
      http.Free;
    except
      Result := 0;
      http.Free;
    end;
  end;
var
  p: PHttpSource;
  lt: TList;
  nSize: Int64;
begin
  lt := FHttpSourceList.LockList;
  try
    if lt.Count = 0 then
    begin
      FHttpGettingFileSize := False;
      Exit;
    end;
    p := lt[0];
  finally
    FHttpSourceList.UnlockList;
  end;
  nSize := GetFileSizeByHttp( p^.FUrl );
  if nSize = 0 then
  begin
    DoErrorInfo( '�޷��õ��ļ�����' );
    Exit;
  end;
  DoCheckFileSegmentInfo( nSize, FFileSegmentSize );
  if Assigned(FSegmentTable) then
  begin
    //�����ؼ���WEB HASH ����Ҫ������
    FSegmentTable.AddPriorityDownInfo( 0 );
    FSegmentTable.AddPriorityDownInfo( FSegmentTable.SegmentCount div 2 );
    FSegmentTable.AddPriorityDownInfo( FSegmentTable.SegmentCount - 1 );
  end;
  FHttpGettingFileSize := False;
end;

procedure TxdP2SPDownTask.DownFileDataByHttp;
var
  nSegIndex, nBlockIndex: Integer;
  http: TIdHTTP;
  nPos: Int64;
  nSize: Cardinal;
  p: PHttpSource;
  lt: TList;
  ms: TMemoryStream;
  bGetSegBuffer: Boolean;
begin
  lt := FHttpSourceList.LockList;
  try
    if lt.Count = 0 then Exit;
    FHttpLastUsedIndex := (FHttpLastUsedIndex + 1) mod lt.Count;
    p := lt[FHttpLastUsedIndex];
  finally
    FHttpSourceList.UnlockList;
  end;

  nPos := 0;
  nSize := 0;
  if not FSegmentTable.GetEmptySegment(nSegIndex, True) then
  begin
    if not FSegmentTable.GetEmptyBlock(nSegIndex, nBlockIndex, True) then Exit;
    FSegmentTable.GetBlockSize( nSegIndex, nBlockIndex, nPos, nSize );
    bGetSegBuffer := False;
  end
  else
  begin
    FSegmentTable.GetSegmentSize( nSegIndex, nPos, nSize );
    bGetSegBuffer := True;
  end;
  if nSize = 0 then Exit;

  http := TIdHTTP.Create( nil );
  ms := TMemoryStream.Create;
  try
    ms.Size := nSize;
    ms.Position := 0;
    with http do
    begin
      Request.Clear;
      Request.Referer := p^.FReferUrl;
      Request.ContentRangeStart := nPos;
      Request.ContentRangeEnd := nPos + nSize - 1;
      xdCookies := p^.FCookies;
    end;

    try
      http.Get( p^.FUrl, ms );
    except
      //ʧ��
    end;

    if (Cardinal(http.Response.ContentLength) = nSize) and (ms.Position = nSize) then
    begin
      InterlockedExchangeAdd( FCalcRecvByte, nSize );
      InterlockedExchangeAdd( p^.FTotalRecvByteCount, nSize );
      if bGetSegBuffer then
        FFileStream.WriteSegmentBuffer( nSegIndex, ms.Memory, nSize )
      else
        FFileStream.WriteBlockBuffer( nSegIndex, nBlockIndex, ms.Memory, nSize );
    end;
  finally
    FreeAndNil( ms );
    FreeAndNil( http );
  end;
end;


{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.DownFileDataByP2P;
var
  i, nCount: Integer;
  p: PP2PSource;
  lt: TList;
  oSendStream: TxdStaticMemory_2K;
  nCountPos, nRequestCount: Integer;
  bOK, bGetMostNeedBlock: Boolean;
  nSegIndex, nBlockIndex, nLen: Integer;

  nBlockSize: Cardinal;
  nBeginPos: Int64;
begin
  p := nil;
  lt := FP2PSourceList.LockList;
  try
    bOK := False;

    for i := lt.Count - 1 downto 0 do
    begin
      FP2PLastUsedIndex := (FP2PLastUsedIndex + 1) mod lt.Count;
      p := lt[FP2PLastUsedIndex];
      if p^.FState = ssSuccess then
      begin
        //�Ѿ���֤�ɹ�������Դ
        if p^.FServerSource then
        begin
          //����Ƿ�����Դ
          if Assigned(p^.FRequestBlockManage) and (GetTickCount - p^.FRequestBlockManage.LastRequestTime >= CtMinSpaceTime) then
          begin
            bOK := True;
            Break;
          end;
        end
        else
        begin
          //�����P2P����Դ, ÿ��һ��ʱ������һ�ζԷ����ļ�����
          if GetTickCount - p^.FLastCheckStateTime >= FCheckP2PDownProgressSpaceTime then
          begin
            oSendStream := TxdStaticMemory_2K.Create;
            try
              FUdp.AddCmdHead( oSendStream, CtCmd_QueryFileProgress );
              if not HashCompare(FFileHash, CtEmptyHash) then
              begin
                oSendStream.WriteByte( Byte(hsFileHash) );
                oSendStream.WriteLong( FFileHash, CtHashSize );
              end
              else
              begin
                oSendStream.WriteByte( Byte(hsWebHash) );
                oSendStream.WriteLong( FWebHash, CtHashSize );
              end;
              FUdp.SendBuffer( p^.FIP, p^.FPort, oSendStream.Memory, oSendStream.Position );
            finally
              oSendStream.Free;
            end;
            p^.FLastCheckStateTime := GetTickCount;
          end;
          bOK := True;
          Break;
        end;
      end
      else
      begin
        //��û�м����������Դ
        if not GetFileInfoByP2P(p) then
        begin
          //������Դ��ʱ����Ҫɾ��
          lt.Delete( FP2PLastUsedIndex );
          DoInvalidP2PSource( p );
          FreeP2PSourceMem( p );
        end;
      end;
    end; //end for i := lt.Count - 1 downto 0 do

    //��Է���������
    if not bOK then Exit;
    if not Assigned(FSegmentTable) then Exit;

    nCount := GetMaxBlockCount( p );
    if nCount <= 0 then Exit;
    bGetMostNeedBlock := IsCanGetMostNeedBlock(p);

    oSendStream := TxdStaticMemory_2K.Create;
    try
      FUdp.AddCmdHead(oSendStream, CtCmd_RequestFileData);
      if not HashCompare(FFileHash, CtEmptyHash) then
      begin
        oSendStream.WriteByte( Byte(hsFileHash) );
        oSendStream.WriteLong(FFileHash, CtHashSize);
      end
      else if not HashCompare(FWebHash, CtEmptyHash) then
      begin
        oSendStream.WriteByte( Byte(hsWebHash) );
        oSendStream.WriteLong(FWebHash, CtHashSize);
      end
      else
      begin
        OutputDebugString( 'HASH Ϊ�գ��޷�����P2P����' );
        Exit;
      end;

      nCountPos := oSendStream.Position; //��λ����Ҫ��¼��ǰ�����зֶηֿ������
      oSendStream.Position := oSendStream.Position + 2;
      nRequestCount := 0;
      for i := 0 to nCount - 1 do
      begin
        if bGetMostNeedBlock then
          bOK := FSegmentTable.GetEmptyBlock(nSegIndex, nBlockIndex, True)
        else
          bOK := FSegmentTable.GetP2PEmptyBlockInfo(nSegIndex, nBlockIndex, False, p^.FSegTableState);

        bOK := bOK and FSegmentTable.GetBlockSize(nSegIndex, nBlockIndex, nBeginPos, nBlockSize);
        if not bOK then Continue;

        //�ɹ���ȡ�ֶ���ֿ���Ϣ��������ָ������Դ��������
        Inc(nRequestCount);
        oSendStream.WriteInteger(nSegIndex);
        oSendStream.WriteWord(nBlockIndex);

        //�������õ�ǰ����ֿ���Ϣ��
        if p^.FRequestBlockManage.FinishedCount > 0 then
          p^.FRequestBlockManage.Clear;
        p^.FRequestBlockManage.AddRequestBlock( nSegIndex, nBlockIndex );

        if nRequestCount >= CtMaxRequestFileBlockCount then
        begin
          nLen := oSendStream.Position;
          oSendStream.Position := nCountPos;
          oSendStream.WriteWord( Word(nRequestCount) );
          //OutputDebugString( Pchar(Format( '��%s����%d������', [IpToStr(p^.FIP, p^.FPort), nRequestCount])) );
          FUdp.SendBuffer(p^.FIP, p^.FPort, oSendStream.Memory, nLen);

          //�������ð�
          oSendStream.Clear;
          FUdp.AddCmdHead(oSendStream, CtCmd_RequestFileData);
          if not HashCompare(FFileHash, CtEmptyHash) then
          begin
            oSendStream.WriteByte( Byte(hsFileHash) );
            oSendStream.WriteLong(FFileHash, CtHashSize);
          end
          else
          begin
            oSendStream.WriteByte( Byte(hsWebHash) );
            oSendStream.WriteLong(FWebHash, CtHashSize);
          end;
          nCountPos := oSendStream.Position; //��λ����Ҫ��¼��ǰ�����зֶηֿ������
          oSendStream.Position := oSendStream.Position + 2;
          nRequestCount := 0;
        end;
      end;

      if nRequestCount > 0 then
      begin
        nLen := oSendStream.Position;
        oSendStream.Position := nCountPos;
        oSendStream.WriteWord( Word(nRequestCount) );
  //                OutputDebugString( Pchar(Format( '��%s����%d������', [IpToStr(p^.FIP, p^.FPort), nRequestCount])) );
        FUdp.SendBuffer(p^.FIP, p^.FPort, oSendStream.Memory, nLen);
      end;
    finally
      oSendStream.Free;
    end;
  finally
    FP2PSourceList.UnlockList;
  end;

  if not bOK or not Assigned(FSegmentTable) then
    GetFileInfoByP2P( p )
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.FreeP2PSourceMem(var p: PP2PSource);
begin
  if Assigned(p) then
  begin
    if Assigned(p^.FRequestBlockManage) then
      p^.FRequestBlockManage.Free;
    if Assigned(p^.FSegTableState) then
      p^.FSegTableState.Free;
    Dispose( p );
    p := nil;
  end;
end;
{$ENDIF}

function TxdP2SPDownTask.GetCurHttpThreadCount: Integer;
begin
  Result := FHttpThreadList.Count;
end;

{$IFNDEF ExclusionP2P}
function TxdP2SPDownTask.GetCurP2PSourceCount: Integer;
begin
  Result := FP2PSourceList.LockList.Count;
  FP2PSourceList.UnlockList;
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
function TxdP2SPDownTask.GetFileInfoByP2P(p: PP2PSource): Boolean;

  //���� CtCmdFileExistsInfoSize �����ȡ�ļ���Ϣ
  procedure SendCheckFileCmd;
  var
    cmd: TCmdQueryFileInfo;
  begin
    FUdp.AddCmdHead( @Cmd, CtCmd_QueryFileInfo );
    if not HashCompare(FileHash, CtEmptyHash) then
    begin
      cmd.FHashStyle := hsFileHash;
      Move( FileHash, Cmd.FHash, CtHashSize );
    end
    else if not HashCompare(WebHash, CtEmptyHash) then
    begin
      cmd.FHashStyle := hsWebHash;
      Move( WebHash, Cmd.FHash, CtHashSize );
    end
    else
      Exit;
    p^.FState := ssChecking;
    p^.FLastCheckStateTime := GetTickCount;
    Inc( p^.FTimeoutCount );
    FUdp.SendBuffer( p^.FIP, p^.FPort, PAnsiChar(@cmd), CtCmdQueryFileInfoSize );
  end;

const
  CtReTryTimeSpace = 1000 * 5;
begin
  Result := True;
  if not Assigned(p) then Exit;
  case p^.FState of
    ssUnkown: SendCheckFileCmd;
    ssChecking:
    begin
      if p^.FTimeoutCount > 10 then
      begin
        Result := False;
      end
      else if GetTickCount - p^.FLastCheckStateTime >= CtReTryTimeSpace then
        SendCheckFileCmd;
    end;
  end;
end;
{$ENDIF}

function TxdP2SPDownTask.GetFileStreamID: Integer;
begin
  if Assigned(FFileStream) then
    Result := FFileStream.StreamID
  else
    Result := -1;
end;

{$IFNDEF ExclusionP2P}
function TxdP2SPDownTask.GetHashCheckSegmentPeer: PP2PSource;
var
  i: Integer;
  lt: TList;
begin
  Result := nil;
  lt := FP2PSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
      Result := lt[i];
  finally
    FP2PSourceList.UnlockList;
  end;
end;
{$ENDIF}

function TxdP2SPDownTask.GetHttpSourceCount: Integer;
begin
  Result := FHttpSourceList.LockList.Count;
  FHttpSourceList.UnlockList;
end;

function TxdP2SPDownTask.GetHttpSourceInfo(const AIndex: Integer; AInfo: PHttpSource): Boolean;
var
  p: PHttpSource;
  lt: TList;
begin
  Result := False;
  lt := FHttpSourceList.LockList;
  try
    if (AIndex >= 0) and (AIndex < lt.Count) then
    begin
      p := lt[AIndex];
      AInfo^.FUrl := p^.FUrl;
      AInfo^.FReferUrl := p^.FReferUrl;
      AInfo^.FCookies := p^.FCookies;
      AInfo^.FTotalRecvByteCount := p^.FTotalRecvByteCount;
    end;
  finally
    FHttpSourceList.UnlockList;
  end;
end;

{$IFNDEF ExclusionP2P}
function TxdP2SPDownTask.GetMaxBlockCount(p: PP2PSource): Integer;
begin
  if p^.FRequestBlockManage.RequestCount = 0 then
    Result := 1
  else
  begin
    if p^.FRequestBlockManage.RequestCount < p^.FRequestBlockManage.FinishedCount then
      Result := p^.FRequestBlockManage.FinishedCount
    else
      Result := p^.FRequestBlockManage.FinishedCount + 1;
  end;
  
//  Result := CtMaxRequestFileBlockCount;
//  OutputDebugString( PChar( '����ֿ�������' + IntToStr(Result)) );
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
function TxdP2SPDownTask.GetP2PSourceInfo(const AIndex: Integer; AInfo: PP2PSource): Boolean;
var
  p: PP2PSource;
  lt: TList;
begin
  lt := FP2PSourceList.LockList;
  try
    Result := (AIndex >= 0) and (AIndex < lt.Count);
    if Result then
    begin
      p := lt[AIndex];
      Move( p^, AInfo^, CtP2PSourceSize );
    end;
  finally
    FP2PSourceList.UnlockList;
  end;
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
function TxdP2SPDownTask.GetP2PSourceInfo(var AInfo: TAryServerInfo): Integer;
var
  lt: TList;
  i, j, nCount: Integer;
  p: PP2PSource;
  bAdd: Boolean;
begin
  nCount := Length( AInfo );
  Result := 0;
  lt := FP2PSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      bAdd := True;
      for j := 0 to nCount - 1 do
      begin
        if (p^.FIP = AInfo[j].FServerIP) and (p^.FPort = AInfo[j].FServerPort) then
        begin
          bAdd := False;
          Break;
        end;
      end;
      if bAdd then
      begin
        SetLength( AInfo, nCount + Result + 1 );
        AInfo[nCount + Result].FServerStyle := srvFileShare;
        AInfo[nCount + Result].FServerID := 0;
        AInfo[nCount + Result].FServerIP := p^.FIP;
        AInfo[nCount + Result].FServerPort := p^.FPort;
        AInfo[nCount + Result].FTag := 0;
        Inc( Result );
      end;
    end;
  finally
    FP2PSourceList.UnlockList;
  end;
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
function TxdP2SPDownTask.IsCanGetMostNeedBlock(p: PP2PSource): Boolean;
begin
  Result := p^.FServerSource;
//  Result := True;
end;
{$ENDIF}

function TxdP2SPDownTask.IsExistsSource(const AUrl: string): Boolean;
var
  p: PHttpSource;
  lt: TList;
  i: Integer;
begin
  Result := False;
  if AUrl = '' then Exit;
  lt := FHttpSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if CompareText(AUrl, p^.FUrl) = 0 then
      begin
        Result := True;
        Break;
      end;
    end;
  finally
    FHttpSourceList.UnlockList;
  end;
end;

{$IFNDEF ExclusionP2P}
function TxdP2SPDownTask.IsExistsSource(const AIP: Cardinal; const APort: Word): Boolean;
var
  p: PP2PSource;
  lt: TList;
  i: Integer;
begin
  Result := False;
  lt := FP2PSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      if (p^.FIP = AIP) and (p^.FPort = APort) then
      begin
        Result := True;
        Break;
      end;
    end;
  finally
    FP2PSourceList.UnlockList;
  end;
end;
{$ENDIF}

procedure TxdP2SPDownTask.RelationSegmentTableEvent;
begin
  if Assigned(FSegmentTable) then
  begin
    FSegmentTable.OnSegmentCompleted := DoCompletedSegment;
  end;
end;

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.ResetP2PSourceStat;
var
  p: PP2PSource;
  lt: TList;
  i: Integer;
begin
  lt := FP2PSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
    begin
      p := lt[i];
      p^.FRequestBlockManage.Clear;
      p^.FTimeoutCount := 0;
    end;
  finally
    FP2PSourceList.UnlockList;
  end;
end;
{$ENDIF}

procedure TxdP2SPDownTask.SaveAs(const ANewFileName: string);
begin
  FSaveAsFileName := ANewFileName;
  if Assigned(FFileStream) then
    FFileStream.RenameFileName := FSaveAsFileName;
end;

procedure TxdP2SPDownTask.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
      ActiveDownTask
    else
      UnActiveDownTask;
  end;
end;

function TxdP2SPDownTask.SetFileInfo(const ASaveFileName: string; const AFileHash: TxdHash; const AWebHash: TxdHash): Boolean;
var
  strDir: string;
begin
  Result := False;
  if not Active then
  begin
    strDir := ExtractFilePath(ASaveFileName);
    if not DirectoryExists(strDir) then
      if not ForceDirectories(strDir) then Exit;
    FFileName := ASaveFileName;
    FFileHash := AFileHash;
    FWebHash := AWebHash;
    FIsEmptyWebHash := HashCompare( FWebHash, CtEmptyHash );
  end;
end;

procedure TxdP2SPDownTask.SetHttpThreadCount(const Value: Integer);
begin
  if (Value <> FHttpThreadCount) and (Value > 0) then
    FHttpThreadCount := Value;                         
end;

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.SetMaxP2PSource(const Value: Integer);
begin
  if (FMaxP2PSource <> Value) and (Value > 0) then
    FMaxP2PSource := Value;
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.SetMaxRequestBlockCount(const Value: Integer);
begin
  if (FMaxRequestBlockCount <> Value) and (Value > 0) and (Value <= CtMaxRequestFileBlockCount) then
    FMaxRequestBlockCount := Value;
end;
{$ENDIF}

{$IFNDEF ExclusionP2P}
procedure TxdP2SPDownTask.SetMaxSearchCount(const Value: Integer);
begin
  if (FMaxSearchCount <> Value) and (Value > 0) then
    FMaxSearchCount := Value;
end;
{$ENDIF}

function TxdP2SPDownTask.SetSegmentTable(const ATable: TxdFileSegmentTable): Boolean;
begin
  Result := (not Active) and Assigned(ATable);
  if Result then
  begin
    FSegmentTable := ATable;
    FFileSize := FSegmentTable.FileSize;
    FFileSegmentSize := FSegmentTable.SegmentSize;
    RelationSegmentTableEvent;
  end;
end;

procedure TxdP2SPDownTask.SetSpeekLimit(const Value: Integer);
begin
  if FSpeekLimit <> Value then
    FSpeekLimit := Value;
end;

{$IFNDEF ExclusionP2P}
function TxdP2SPDownTask.SetUdp(AUdp: TxdUdpSynchroBasic): Boolean;
begin
  Result := not Active and Assigned(AUdp);
  if Result then
    FUdp := AUdp;
end;
{$ENDIF}

procedure TxdP2SPDownTask.UnActiveDownTask;
begin
  FActive := False;
  ClearHttpThread;
  DeleteCriticalSection( FLockCalcWebHash );
  if Assigned(FFileStream) then
  begin
    FFileStream.FlushStream;
    StreamManage.ReleaseFileStream( FFileStream );
    FFileStream := nil;
  end;
  {$IFNDEF ExclusionP2P}
  ResetP2PSourceStat;
  {$ENDIF}
  FCurSpeek := 0;
end;

{ TRequestBlockManage }

procedure TRequestBlockManage.AddRequestBlock(const ASegIndex, ABlockIndex: Integer);
begin
  FRequestBlockCount := Length(FBlocks);
  SetLength( FBlocks, FRequestBlockCount + 1 );
  FBlocks[FRequestBlockCount] := CalcID( ASegIndex, ABlockIndex );
  Inc( FRequestCount );
  Inc( FRequestBlockCount );
  FLastRequestTime := GetTickCount; 
end;

function TRequestBlockManage.CalcID(const ASegIndex, ABlockIndex: Integer): Cardinal;
begin
  Result := ASegIndex * 10000 + ABlockIndex;
end;

procedure TRequestBlockManage.Clear;
begin
  SetLength( FBlocks, 0 );
  FRequestBlockCount := 0;
  FRequestCount := 0;
  FFinishedCount := 0;
  FLastRequestTime := 0;
end;

constructor TRequestBlockManage.Create;
begin
  Clear;
end;

destructor TRequestBlockManage.Destroy;
begin
  Clear;
  inherited;
end;

procedure TRequestBlockManage.FinishedBlock(const ASegIndex, ABlockIndex: Integer);
var
  i: Integer;
  nID: Cardinal;
begin
  nID := CalcID(ASegIndex, ABlockIndex);
  for i := 0 to FRequestBlockCount - 1 do
  begin
    if FBlocks[i] = nID then
    begin
      FBlocks[i] := MAXDWORD;
      Inc( FFinishedCount );
      Break;
    end;
  end;
end;

end.
