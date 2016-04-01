{
��Ԫ����: uJxdClientUpShareManage
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com  jxd524@gmail.com
˵    ��: ����ִ��P2P���أ������ͷŻ��洦��������Ϣ�ı���������
��ʼʱ��: 2011-09-14
�޸�ʱ��: 2011-09-14 (����޸�ʱ��)
��˵��  :
    �����ļ��ϴ����ϴ���Ϣ����һ��ʱ���޶�������ɾ�����ϴ������ɱ�����
    ����˳������ -> StreamManage -> FileShareManage
    ��������ҵ�������ת����������Ҫ�Ľṹ��
}
unit uJxdClientUpShareManage;

interface

uses
  Windows, SysUtils, Classes, uJxdUdpDefine, uJxdHashCalc, uJxdDataStream, uJxdUdpSynchroBasic, 
  uJxdThread, uJxdServerManage, uJxdUdpCommonClient, uJxdFileSegmentStream, uJxdFileShareManage;

type
  PUpShareInfo = ^TUpShareInfo;
  TUpShareInfo = record
    FFileStream: TxdP2SPFileStreamBasic;
    FLastActiveTime: Cardinal;
    FRefCount: Integer;
    FUpSize: Integer;
  end;
  
  TxdClientUpShareManage = class
  public
    constructor Create;
    destructor  Destroy; override; 

    function  GetUpShareInfo(const AIndex: Integer): PUpShareInfo;
    procedure ReleaseUpShareInfo(const Ap: PUpShareInfo);
  private
    FLock: TRTLCriticalSection;
    FTaskList: TList;
    FAutoDeleteThread: TThreadCheck;
    FUpShareSize: Integer;

    procedure LockManage; inline;
    procedure UnlockManage; inline;

    {�ͷŹ�����Ϣ}
    procedure FreeUpShareInfo(const Ap: PUpShareInfo); inline;

    {�����ϴ�������Ϣ��FindUpShareInfo��ReleaseUpShareInfo ��Ҫ���ʹ��}
    function  FindUpShareInfo(const AHashStyle: THashStyle; const AHash: TxdHash): PUpShareInfo;
    

    {������ʾ��Ϣ}
    procedure DoErrorInfo(const AInfo: string);

    {�߳��Զ�ɾ����ʱ����Ӧ�ϴ���Ϣ}
    procedure DoThreadToDeleteTimeoutUpShare;        
  private
    {������ϴ������¼�}
    procedure DoHandleUpShareCmdEvent(const ACmd: Word; const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
                                      const AIsSynchroCmd: Boolean; const ASynchroID: Word);
    //��ѯ�ļ���Ϣ����
    procedure DoHandleCmd_QueryFileInfo(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word);
    //��ѯ�ļ����ȣ��ڷ������ˣ�ֱ�ӷ���ȫ���Ѿ���ɣ�
    procedure DoHandleCmd_QueryFileProgress(const AIP: Cardinal; const APort: Word; const ABuffer: PAnsiChar; const ABufLen: Cardinal;
      const AIssynchroCmd: Boolean; const ASynchroID: Word);
    //�����ļ���������
    procedure DoHandleCmd_RequestFileData(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word);
    //��ȡ�ļ�HASH��Ϣ����
    procedure DoHandleCmd_GetFileSegmentHash(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word);
  private
    FUDP: TxdUdpCommonClient;
    FMaxUpTaskCount: Integer;
    FFileShareManage: TxdFileShareManage;
    FMaxUnActiveTime: Cardinal;
    procedure SetUDP(const Value: TxdUdpCommonClient);
    procedure SetMaxUpTaskCount(const Value: Integer);
    procedure SetMaxUnActiveTime(const Value: Cardinal);
    function  GetCurUpShareCount: Integer; inline;
  public
    {�ⲿ������}
    property UDP: TxdUdpCommonClient read FUDP write SetUDP;
    property FileShareManage: TxdFileShareManage read FFileShareManage write FFileShareManage; 

    {����}
    property MaxUpTaskCount: Integer read FMaxUpTaskCount write SetMaxUpTaskCount; //���ͬʱ�ϴ���������
    property MaxUnActiveTime: Cardinal read FMaxUnActiveTime write SetMaxUnActiveTime; //����޶���ʱ��

    {ֻ������}
    property CurUpShareCount: Integer read GetCurUpShareCount; //��ǰ��������
    property CurUpShareSize: Integer read FUpShareSize; //�ϴ�����
  end;

implementation

const
  CtMinUpTaskCount = 3;

{ TxdClientUpShareManage }

constructor TxdClientUpShareManage.Create;
begin
  FMaxUpTaskCount := 10;
  FMaxUnActiveTime := 60 * 1000;
  FAutoDeleteThread := nil;
  FUpShareSize := 0;
  FTaskList := TList.Create;  
  InitializeCriticalSection( FLock );
end;

function TxdClientUpShareManage.GetCurUpShareCount: Integer;
begin
  Result := FTaskList.Count;
end;

function TxdClientUpShareManage.GetUpShareInfo(const AIndex: Integer): PUpShareInfo;
begin
  Result := nil;
  LockManage;
  try
    if (AIndex < 0) or (AIndex >= FTaskList.Count) then Exit;
    Result := FTaskList[AIndex];
    Inc( Result^.FRefCount );
  finally
    UnlockManage;
  end;
end;

destructor TxdClientUpShareManage.Destroy;
var
  i: Integer;
begin  
  LockManage;
  try
    for i := 0 to FTaskList.Count - 1 do
      FreeUpShareInfo( FTaskList[i] );
    FTaskList.Clear;
  finally
    UnlockManage;
  end;
  //FTaskList.Count = 0 ʱ�����Զ��ͷ� FAutoDeleteThread
  while Assigned(FAutoDeleteThread) do
  begin
    FAutoDeleteThread.ActiveToCheck;
    Sleep( 10 );
  end;
  
  FTaskList.Free;
  DeleteCriticalSection( FLock );
  inherited;
end;

procedure TxdClientUpShareManage.DoErrorInfo(const AInfo: string);
begin
  OutputDebugString( PChar(AInfo) );
end;

procedure TxdClientUpShareManage.DoHandleCmd_GetFileSegmentHash(const AIP: Cardinal; const APort: Word;
  const ABuffer: pAnsiChar; const ABufLen: Cardinal; const AIsSynchroCmd: Boolean; const ASynchroID: Word);
begin

end;

procedure TxdClientUpShareManage.DoHandleCmd_QueryFileInfo(const AIP: Cardinal; const APort: Word;
  const ABuffer: pAnsiChar; const ABufLen: Cardinal; const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdQueryFileInfo;
  p: PUpShareInfo;
  oSendStream: TxdStaticMemory_512Byte;
  ReplySign: TReplySign;
begin
  if ABufLen <> CtCmdQueryFileInfoSize then
  begin
    DoErrorInfo( '��ѯ�ļ���Ϣ����Ȳ���ȷ: CtCmd_QueryFileInfo' );
    Exit;
  end;
  pCmd := PCmdQueryFileInfo(ABuffer);
  p := FindUpShareInfo( pCmd^.FHashStyle, TxdHash(pCmd^.FHash) );
  try
    if Assigned(p) then
    begin
      if p^.FFileStream is TxdLocalFileStream then      
        ReplySign := rsSuccess
      else
      begin
        if (p^.FFileStream as TxdFileSegmentStream).SegmentTable.IsCompleted then
          ReplySign := rsSuccess
        else
          ReplySign := rsPart;
      end;
    end
    else
      ReplySign := rsNotFind;

    oSendStream := TxdStaticMemory_512Byte.Create;
    try
      if AIsSynchroCmd then
        FUdp.AddSynchroSign( oSendStream, ASynchroID );
      FUdp.AddCmdHead( oSendStream, CtCmdReply_QueryFileInfo );
      oSendStream.WriteByte( Byte(pCmd^.FHashStyle) );
      oSendStream.WriteLong( pCmd^.FHash, CtHashSize );
      oSendStream.WriteByte( Byte(ReplySign) );
      if ReplySign <> rsNotFind then
      begin
        oSendStream.WriteInt64( p^.FFileStream.FileSize );
        oSendStream.WriteCardinal( p^.FFileStream.SegmentSize );
        if pCmd^.FHashStyle = hsWebHash then
          oSendStream.WriteLong( p^.FFileStream.FileHash, CtHashSize );
      end;
      FUdp.SendBuffer( AIP, APort, oSendStream.Memory, oSendStream.Position );
    finally
      oSendStream.Free;
    end;
  finally
    ReleaseUpShareInfo( p );
  end;
end;

procedure TxdClientUpShareManage.DoHandleCmd_QueryFileProgress(const AIP: Cardinal; const APort: Word;
  const ABuffer: PAnsiChar; const ABufLen: Cardinal; const AIssynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdQueryFileProgressInfo;
  p: PUpShareInfo;
  oSendStream: TxdStaticMemory_512Byte;
  ReplySign: TReplySign;
  table: TxdSegmentStateTable;
begin
  if ABufLen <> CtCmdQueryFileProgressInfoSize then
  begin
    DoErrorInfo( 'QueryFileProgress ����Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdQueryFileProgressInfo(ABuffer);
  p := FindUpShareInfo( pCmd^.FHashStyle, TxdHash(pCmd^.FHash) );
  try
    table := nil;
    if Assigned(p) then
    begin
      ReplySign := rsSuccess;
      if p^.FFileStream is TxdLocalFileStream then
        table := nil
      else
        table := (p^.FFileStream as TxdFileSegmentStream).SegmentTable.SegmentStateTable;
    end
    else
      ReplySign := rsNotFind;

    oSendStream := TxdStaticMemory_512Byte.Create;
    try
      if AIsSynchroCmd then
        FUdp.AddSynchroSign( oSendStream, ASynchroID );
      FUdp.AddCmdHead( oSendStream, CtCmdReply_QueryFileProgress );
      oSendStream.WriteByte( Byte(pCmd^.FHashStyle) );
      oSendStream.WriteLong( pCmd^.FHash, CtHashSize );
      oSendStream.WriteByte( Byte(ReplySign) );
      if ReplySign = rsSuccess then
      begin
        if Assigned(table) then
        begin
          oSendStream.WriteInteger( table.BitMemLen );
          oSendStream.WriteLong( PChar(table.BitMem)^, table.BitMemLen );
        end
        else
          oSendStream.WriteInteger( 0 ); //��ʾ���ļ��Ѿ����        
      end;
      FUdp.SendBuffer( AIP, APort, oSendStream.Memory, oSendStream.Position );
    finally
      oSendStream.Free;
    end;
  finally
    ReleaseUpShareInfo( p );
  end;
end;

procedure TxdClientUpShareManage.DoHandleCmd_RequestFileData(const AIP: Cardinal; const APort: Word;
  const ABuffer: pAnsiChar; const ABufLen: Cardinal; const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdRequestFileDataInfo;
  p: PUpShareInfo;
  stream: TxdP2SPFileStreamBasic;
  oSendStream: TxdStaticMemory_16K;
  i: Integer;
  buf: PChar;
  nSize, nSendByteCount: Integer;
begin
  if ABufLen < CtCmdRequestFileDataInfoSize then
  begin
    DoErrorInfo( '������������Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdRequestFileDataInfo(ABuffer);
  oSendStream := TxdStaticMemory_16K.Create;
  p := FindUpShareInfo( pCmd^.FHashStyle, TxdHash(pCmd^.FHash) );
  try
    if not Assigned(p) then Exit;
    stream := p^.FFileStream;
    if Assigned(stream) then
    begin
      //���ҳɹ�
      GetMem( buf, stream.SegmentSize );
      try
        for i := 0 to pCmd^.FRequestCount - 1 do
        begin
          if stream.ReadBlockBuffer(pCmd^.FRequestInfo[i].FSegmentIndex, pCmd^.FRequestInfo[i].FBlockIndex, PByte(buf), nSize) then
          begin
            oSendStream.Clear;
            FUdp.AddCmdHead( oSendStream, CtCmdReply_RequestFileData );
            oSendStream.WriteByte(Byte(pCmd^.FHashStyle));
            oSendStream.WriteLong(pCmd^.FHash, 16);
            oSendStream.WriteByte(Byte(rsSuccess));
            oSendStream.WriteInteger(pCmd^.FRequestInfo[i].FSegmentIndex);
            oSendStream.WriteWord(pCmd^.FRequestInfo[i].FBlockIndex);
            oSendStream.WriteWord(nSize);
            oSendStream.WriteLong(buf^, nSize);

            nSendByteCount := FUdp.SendBuffer(AIP, APort, oSendStream.Memory, oSendStream.Position);
            if nSendByteCount = -1 then Continue;  //����ʧ�ܣ�ֱ�ӷ���һ��������������ϵͳ���治�㣬������Զ��ط�
            InterlockedExchangeAdd( FUpShareSize, nSendByteCount ); 
            Inc( p^.FUpSize, nSendByteCount );
          end
          else
          begin
            DoErrorInfo( '�޷���ȡ����Ϣ: ' );
          end;
        end;
      finally
        FreeMem( buf );
      end;
    end
    else
    begin
      //���Ҳ���ָ���ļ�
      FUdp.AddCmdHead( oSendStream, CtCmdReply_RequestFileData );
      oSendStream.WriteLong(pCmd^.FHash, 16);
      oSendStream.WriteByte(Byte(rsNotFind));
      FUdp.SendBuffer( AIP, APort, oSendStream.Memory, oSendStream.Position );
    end;
  finally
    oSendStream.Free;
    ReleaseUpShareInfo( p );
  end;
end;

procedure TxdClientUpShareManage.DoHandleUpShareCmdEvent(const ACmd: Word; const AIP: Cardinal; const APort: Word;
  const ABuffer: pAnsiChar; const ABufLen: Cardinal; const AIsSynchroCmd: Boolean; const ASynchroID: Word);
begin
  case ACmd of
    CtCmd_QueryFileInfo:      DoHandleCmd_QueryFileInfo( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_QueryFileProgress:  DoHandleCmd_QueryFileProgress( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_RequestFileData:    DoHandleCmd_RequestFileData( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_GetFileSegmentHash: DoHandleCmd_GetFileSegmentHash( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
  end;
end;

procedure TxdClientUpShareManage.DoThreadToDeleteTimeoutUpShare;
var
  i: Integer;
  p: PUpShareInfo;
  dwTime: Cardinal;
begin
  dwTime := GetTickCount;
  
  LockManage;
  try
    for i := FTaskList.Count - 1 downto 0 do
    begin
      p := FTaskList[i];
      if (p^.FRefCount <= 0) and (p^.FLastActiveTime + MaxUnActiveTime > dwTime) then
      begin
        FreeUpShareInfo( p );
        FTaskList.Delete( i );
      end;
    end;     
  finally
    UnlockManage;
  end;

  if FTaskList.Count = 0 then
  begin
    FAutoDeleteThread.AutoFreeSelf;
    FAutoDeleteThread := nil;
  end;
end;

function TxdClientUpShareManage.FindUpShareInfo(const AHashStyle: THashStyle; const AHash: TxdHash): PUpShareInfo;
var
  i: Integer;
  p: PUpShareInfo;
  pFileShare: PFileShareInfo;
  bOK: Boolean;
  stream: TxdP2SPFileStreamBasic;
begin
  Result := nil;
  
  LockManage;
  try
    bOK := False;
    p := nil;
    for i := 0 to FTaskList.Count - 1 do
    begin
      p := FTaskList[i];
      if AHashStyle = hsFileHash then
      begin
        if HashCompare(p^.FFileStream.FileHash, AHash) then
        begin
          bOK := True;
          Break;
        end;
      end
      else
      begin
        if HashCompare(p^.FFileStream.WebHash, AHash) then
        begin
          bOK := True;
          Break;
        end;
      end;
    end;

    //û�в��ҵ�ʱ
    if not bOK then
    begin
      if FTaskList.Count >= FMaxUpTaskCount then Exit;     
      
      //��ʼ������
      stream := StreamManage.QueryFileStream( AHashStyle, AHash );
      if not Assigned(stream) and Assigned(FFileShareManage) then
      begin
        //�ӹ���������в���
        FFileShareManage.LockShareManage;
        try
          if AHashStyle = hsFileHash then
            pFileShare := FFileShareManage.FindShareInfoByFileHash( AHash )
          else
            pFileShare := FFileShareManage.FindShareInfoByWebHash( AHash );

          if Assigned(pFileShare) then
          begin
            stream := StreamManage.CreateFileStream( pFileShare^.FFileName, pFileShare^.FFileHash, pFileShare^.FSegmentSize);
            if Assigned(stream) then
              stream.WebHash := pFileShare^.FWebHash;
          end;
        finally
          FFileShareManage.UnLockShareManage;
        end;
      end;
      //�����ҽ���

      if Assigned(stream) then
      begin
        New( p );
        p^.FFileStream := stream;
        p^.FRefCount := 0;
        p^.FUpSize := 0;
        bOK := True;
        FTaskList.Add( p );
      end;
    end; //End if not bOK then

    if bOK then
    begin
      Inc( p^.FRefCount );
      p^.FLastActiveTime := GetTickCount;
      Result := p;
    end;   
  finally
    UnlockManage;
  end;
end;

procedure TxdClientUpShareManage.FreeUpShareInfo(const Ap: PUpShareInfo);
begin
  if Assigned(Ap) then
  begin
    StreamManage.ReleaseFileStream( Ap^.FFileStream );
    Dispose( Ap );
  end; 
end;

procedure TxdClientUpShareManage.LockManage;
begin
  EnterCriticalSection( FLock );
end;

procedure TxdClientUpShareManage.ReleaseUpShareInfo(const Ap: PUpShareInfo);
begin
  if not Assigned(Ap) then Exit;
  LockManage;
  try
    Dec( Ap^.FRefCount );
    Ap^.FLastActiveTime := GetTickCount;

    if Ap^.FRefCount <= 0 then
    begin
      if not Assigned(FAutoDeleteThread) then
        FAutoDeleteThread := TThreadCheck.Create( DoThreadToDeleteTimeoutUpShare, FMaxUnActiveTime + 100 );
    end;
  finally
    UnlockManage;
  end;
end;

procedure TxdClientUpShareManage.SetMaxUnActiveTime(const Value: Cardinal);
begin
  if (Value <> FMaxUnActiveTime) and (Value > 1000 * 60) then
    FMaxUnActiveTime := Value;
end;

procedure TxdClientUpShareManage.SetMaxUpTaskCount(const Value: Integer);
begin
  if (Value >= CtMinUpTaskCount) and (FMaxUpTaskCount <> Value) then
    FMaxUpTaskCount := Value;
end;

procedure TxdClientUpShareManage.SetUDP(const Value: TxdUdpCommonClient);
begin
  FUDP := Value;
  if Assigned(FUDP) then
    FUDP.OnUpShareCmdEvent := DoHandleUpShareCmdEvent;
end;

procedure TxdClientUpShareManage.UnlockManage;
begin
  LeaveCriticalSection( FLock );
end;

end.
