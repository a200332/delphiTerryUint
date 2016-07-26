{
��Ԫ����: uJxdUdpFileServer
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com  jxd524@gmail.com
˵    ��: ��װ�����ͬ��������
��ʼʱ��: 2011-09-19
�޸�ʱ��: 2011-09-19 (����޸�ʱ��)
��˵��  :
   ���������ļ����������
   Ϊ�������ṩ����, ���ݴ� TxdFileShareManage �����л�ȡ
}
unit uJxdServerUpShareManage;

interface

uses
  Windows, ExtCtrls, uJxdHashCalc, uJxdDataStruct, uJxdDataStream, uJxdUdpSynchroBasic, uJxdFileSegmentStream, 
  uJxdFileShareManage, uJxdUdpDefine, uJxdMemoryManage, uJxdUdpFileServer, uJxdThread;

type
  PUpShareInfo = ^TUpShareInfo;
  TUpShareInfo = record
    FFileStream: TxdP2SPFileStreamBasic;
    FLastActiveTime: Cardinal;
    FRefCount: Integer;
  end;
  
  TxdServerUpShareManage = class
  public
    constructor Create(const AMaxShareCount: Integer = 1000; const AHashTable: Integer = 1313); 
    destructor  Destroy; override;

    procedure LoopShareInfo(ALoop: TOnLoopNode);
  private  
    {������}  
    FShareMemory: TxdFixedMemoryManager;
    FShareList: THashArrayEx;
    FLock: TRTLCriticalSection;   
    FCheckThread: TThreadCheck; 

    {��������}
    FLastQueryUpShareInfo: PUpShareInfo;
    FCurQueryWebHash: TxdHash;
    FCurQueryResult: Boolean;
    FCurCheckTime: Cardinal;

    procedure LockManage; inline;
    procedure UnLockManage; inline;

    {ɾ����ʱ�������߳�}
    procedure DoThreadToCheckUnActiveTime;
    procedure DoThreadLoopToDeleteTimeout(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean);
    
    {��ShareList����ز���}
    procedure DoLoopToFindInfoByWebHash(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean);
    procedure DoLoopToDeleteAllItem(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean);

    {֪ͨ}
    procedure DoMaxShareFile;
    procedure DoErrorInfo(const AInfo: string);

    {�����ϴ�������Ϣ}
    function  FindUpShareInfo(const AHashStyle: THashStyle; const AHash: TxdHash): PUpShareInfo;
    procedure ReleaseShareInfo(const Ap: PUpShareInfo);
    
    {������ϴ������¼�}
    procedure DoHandleShareCmdEvent(const ACmd: Word; const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
                                      const AIsSynchroCmd: Boolean; const ASynchroID: Word);
    {��������}
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
    FUDP: TxdUdpFileServer;
    FFileShareManage: TxdFileShareManage;
    FUpShareMaxUnActiveTime: Cardinal;
    FUpShareSize: Integer;
    procedure SetUDP(const Value: TxdUdpFileServer);
    function  GetMaxShareCount: Integer;
    procedure SetUpShareMaxUnActiveTime(const Value: Cardinal);
    function  GetCurUpShareCount: Integer;
  public
    {���ⲿ���ö���}
    property Udp: TxdUdpFileServer read FUDP write SetUDP;
    property FileShareManage: TxdFileShareManage read FFileShareManage write FFileShareManage;

    property CurUpShareCount: Integer read GetCurUpShareCount; //��ǰ�ϴ�����
    property CurUpShareSize: Integer read FUpShareSize; //��ǰ�Ѿ�������Ϣ��С
    property MaxShareCount: Integer read GetMaxShareCount; //���������
    property UpShareMaxUnActiveTime: Cardinal read FUpShareMaxUnActiveTime write SetUpShareMaxUnActiveTime; //���������ʱ��
  end;

implementation

const
  CtUpShareInfoSize = SizeOf(TUpShareInfo);

{ TxdServerFileShareManage }

constructor TxdServerUpShareManage.Create(const AMaxShareCount: Integer; const AHashTable: Integer);
var
  nCount, nHashTableCount: Integer;
begin
  FLastQueryUpShareInfo := nil;
  FUpShareMaxUnActiveTime := 60 * 1000;
  if AMaxShareCount > 0 then
    nCount := AMaxShareCount
  else
    nCount := 1000;
  if AHashTable > 0 then
    nHashTableCount := AHashTable
  else
    nHashTableCount := 1313;
  
  FShareMemory := TxdFixedMemoryManager.Create( CtUpShareInfoSize, nCount );
  FShareList := THashArrayEx.Create;
  with FShareList do
  begin
    HashTableCount := nHashTableCount;
    MaxHashNodeCount := nCount;
    Active := True;
  end;
  
  InitializeCriticalSection( FLock );

  FCheckThread := TThreadCheck.Create( DoThreadToCheckUnActiveTime, FUpShareMaxUnActiveTime );
end;

destructor TxdServerUpShareManage.Destroy;
begin
  LockManage;
  try
    FShareList.Loop( DoLoopToDeleteAllItem );    
  finally
    UnLockManage;
  end;
  FCheckThread.Free;
  FShareMemory.Free;
  DeleteCriticalSection( FLock );
  inherited;
end;

procedure TxdServerUpShareManage.DoErrorInfo(const AInfo: string);
begin
  OutputDebugString( PChar(AInfo) );
end;

procedure TxdServerUpShareManage.DoHandleCmd_GetFileSegmentHash(const AIP: Cardinal; const APort: Word;
  const ABuffer: pAnsiChar; const ABufLen: Cardinal; const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdGetFileSegmentHashInfo;
  p: PFileShareInfo;
  oSendStream: TxdStaticMemory_2K;
  i: Integer;
begin
  if ABufLen <> CtCmdGetFileSegmentHashInfoSize then
  begin
    DoErrorInfo( 'GetFileSegmentHash ����Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdGetFileSegmentHashInfo(ABuffer);

  if not Assigned(FFileShareManage) then Exit;

  FFileShareManage.LockShareManage;
  try
    p := FFileShareManage.FindShareInfoByFileHash( TxdHash(pCmd^.FHash) );
    if not Assigned(p) then Exit;
    oSendStream := TxdStaticMemory_2K.Create;
    try
      if AIsSynchroCmd then
        FUdp.AddSynchroSign( oSendStream, ASynchroID );
      FUdp.AddCmdHead( oSendStream, CtCmdReply_GetFileSegmentHash );
      oSendStream.WriteLong( pCmd^.FHash[0], CtHashSize );
      oSendStream.WriteCardinal( p^.FHashCheckSegmentSize );
      for i := 0 to p^.FHashCheckSegmentCount - 1 do
        oSendStream.WriteLong( p^.FHashCheckTable[i].v[0], CtHashSize );
      FUdp.SendBuffer( AIP, APort, oSendStream.Memory, oSendStream.Position );
    finally
      oSendStream.Free;
    end;
  finally
    FFileShareManage.UnLockShareManage;
  end;
  
end;

procedure TxdServerUpShareManage.DoHandleCmd_QueryFileInfo(const AIP: Cardinal; const APort: Word;
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
      ReplySign := rsSuccess
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
      if ReplySign = rsSuccess then
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
    ReleaseShareInfo( p );
  end;
end;

procedure TxdServerUpShareManage.DoHandleCmd_QueryFileProgress(const AIP: Cardinal; const APort: Word;
  const ABuffer: PAnsiChar; const ABufLen: Cardinal; const AIssynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdQueryFileProgressInfo;
  p: PUpShareInfo;
  oSendStream: TxdStaticMemory_512Byte;
  ReplySign: TReplySign;
begin
  if ABufLen <> CtCmdQueryFileProgressInfoSize then
  begin
    DoErrorInfo( 'QueryFileProgress ����Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdQueryFileProgressInfo(ABuffer);
  p := FindUpShareInfo( pCmd^.FHashStyle, TxdHash(pCmd^.FHash) );
  try
    if Assigned(p) then
      ReplySign := rsSuccess
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
        oSendStream.WriteByte( Byte(0) ); //��ʾ���ļ��Ѿ����
      FUdp.SendBuffer( AIP, APort, oSendStream.Memory, oSendStream.Position );
    finally
      oSendStream.Free;
    end;
  finally
    ReleaseShareInfo( p );
  end;
end;

procedure TxdServerUpShareManage.DoHandleCmd_RequestFileData(const AIP: Cardinal; const APort: Word;
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
    ReleaseShareInfo( p );
  end;
end;

procedure TxdServerUpShareManage.DoHandleShareCmdEvent(const ACmd: Word; const AIP: Cardinal; const APort: Word;
  const ABuffer: pAnsiChar; const ABufLen: Cardinal; const AIsSynchroCmd: Boolean; const ASynchroID: Word);
begin
  case ACmd of
    CtCmd_RequestFileData:     DoHandleCmd_RequestFileData( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_QueryFileInfo:       DoHandleCmd_QueryFileInfo( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_QueryFileProgress:   DoHandleCmd_QueryFileProgress( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
    CtCmd_GetFileSegmentHash:  DoHandleCmd_GetFileSegmentHash( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
  end;
end;

procedure TxdServerUpShareManage.DoLoopToDeleteAllItem(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel,
  AFindNext: Boolean);
var
  p: PUpShareInfo;
begin
  p := pData;
  StreamManage.ReleaseFileStream( p^.FFileStream );
  Dispose( p );
  ADel := True;
end;

procedure TxdServerUpShareManage.DoLoopToFindInfoByWebHash(Sender: TObject; const AID: Cardinal; pData: Pointer;
  var ADel, AFindNext: Boolean);
var
  p: PUpShareInfo;
begin
  p := pData;
  AFindNext := not HashCompare( p^.FFileStream.WebHash, FCurQueryWebHash );
  if not AFindNext then //���ҳɹ�  
    FLastQueryUpShareInfo := p;
end;


procedure TxdServerUpShareManage.DoMaxShareFile;
begin
  OutputDebugString( '���������Ѿ��ﵽ���ֵ���޷�����������ṩ' );
end;

procedure TxdServerUpShareManage.DoThreadLoopToDeleteTimeout(Sender: TObject; const AID: Cardinal; pData: Pointer;
  var ADel, AFindNext: Boolean);
var
  p: PUpShareInfo;
begin
  p := pData;
  if (p^.FRefCount <= 0) and (p^.FLastActiveTime + FUpShareMaxUnActiveTime >= FCurCheckTime) then
  begin
    ADel := True;
    if p = FLastQueryUpShareInfo then
      FLastQueryUpShareInfo := nil;
    StreamManage.ReleaseFileStream( p^.FFileStream );
  end;
end;


procedure TxdServerUpShareManage.DoThreadToCheckUnActiveTime;
begin
  LockManage;
  try
    FCurCheckTime := GetTickCount;
    FShareList.Loop( DoThreadLoopToDeleteTimeout );
  finally
    UnLockManage;
  end;
end;

function TxdServerUpShareManage.FindUpShareInfo(const AHashStyle: THashStyle; const AHash: TxdHash): PUpShareInfo;
var
  p: PUpShareInfo;
  pNode: PHashNode;
  bFind: Boolean;
  pShare: PFileShareInfo;
begin
  bFind := False;
  Result := nil;
  LockManage;
  try
    //�ж����һ�β�ѯ�Ƿ���ͬһ������
    if Assigned(FLastQueryUpShareInfo) then
    begin
      if AHashStyle = hsFileHash then
        bFind := HashCompare(AHash, FLastQueryUpShareInfo^.FFileStream.FileHash )
      else
        bFind := HashCompare(AHash, FLastQueryUpShareInfo^.FFileStream.WebHash );
    end;

    if not bFind then
    begin
      //�ڱ����б��н���HASH��ѯ����ѯ������Ϣ�����ļ���������в�ѯ
      
      //ʹ��FileHash���в�ѯ
      if AHashStyle = hsFileHash then
      begin
        pNode := FShareList.FindBegin( HashToID(AHash) );
        try
          while Assigned(pNode) do
          begin
            p := pNode^.NodeData;
            if HashCompare(p^.FFileStream.FileHash, AHash) then
            begin
              bFind := True;
              FLastQueryUpShareInfo := p;
              Break;
            end;
            pNode := FShareList.FindNext( pNode );
          end;
        finally
          FShareList.FindEnd;
        end;
      end
      else
      begin
        //ʹ��WebHash���в�ѯ
        FCurQueryWebHash := AHash;
        FCurQueryResult := False;
        FShareList.Loop( DoLoopToFindInfoByWebHash );
        bFind := FCurQueryResult;
      end;
      //�����������

      //���ļ���������в�ѯ
      if not bFind and Assigned(FFileShareManage) then
      begin        
        FFileShareManage.LockShareManage;
        try
          if AHashStyle = hsFileHash then          
            pShare := FFileShareManage.FindShareInfoByFileHash( AHash )
          else
            pShare := FFileShareManage.FindShareInfoByWebHash( AHash );

          if Assigned(pShare) then
          begin
            New( p );
            p^.FFileStream := StreamManage.CreateFileStream( pShare^.FFileName, pShare^.FFileHash, pShare^.FSegmentSize );
            if not Assigned(p^.FFileStream) then
            begin
              Dispose( p );
              Exit;
            end;
            p^.FFileStream.WebHash := pShare^.FWebHash;
            p^.FRefCount := 0;
            
            if not FShareList.Add( HashToID(p^.FFileStream.FileHash), p ) then
            begin
              DoMaxShareFile;
              StreamManage.ReleaseFileStream( p^.FFileStream );
              Dispose( p );
              Exit;
            end;

            FLastQueryUpShareInfo := p;
            bFind := True;
          end;
        finally
          FFileShareManage.UnLockShareManage;
        end;              
      end;
      //�����ļ����������      
    end;


    if bFind then
    begin
      Result := FLastQueryUpShareInfo;
      Result^.FLastActiveTime := GetTickCount;
      Inc( Result^.FRefCount );
    end;
  finally
    UnLockManage;
  end;
end;

function TxdServerUpShareManage.GetCurUpShareCount: Integer;
begin
  if Assigned(FShareList) then
    Result := FShareList.Count
  else
    Result := 0;
end;

function TxdServerUpShareManage.GetMaxShareCount: Integer;
begin
  if Assigned(FShareMemory) then
    Result := FShareMemory.Capacity
  else
    Result := 0;
end;

procedure TxdServerUpShareManage.LockManage;
begin
  EnterCriticalSection( FLock );
end;

procedure TxdServerUpShareManage.LoopShareInfo(ALoop: TOnLoopNode);
begin
  LockManage;
  try
    FShareList.Loop( ALoop );
  finally
    UnLockManage;
  end;
end;

procedure TxdServerUpShareManage.ReleaseShareInfo(const Ap: PUpShareInfo);
begin
  if Assigned(Ap) then
  begin
    LockManage;
    try
      Dec( Ap^.FRefCount );
      Ap^.FLastActiveTime := GetTickCount;
    finally
      UnLockManage;
    end;
  end;
end;

procedure TxdServerUpShareManage.SetUDP(const Value: TxdUdpFileServer);
begin
  FUDP := Value;
  if Assigned(FUDP) then
    FUDP.OnFileShareCmdEvent := DoHandleShareCmdEvent;
end;

procedure TxdServerUpShareManage.SetUpShareMaxUnActiveTime(const Value: Cardinal);
begin
  if FUpShareMaxUnActiveTime <> Value then
  begin
    FUpShareMaxUnActiveTime := Value;
    if FUpShareMaxUnActiveTime > 15 * 60 * 1000 then
    begin
      if Assigned(FCheckThread) then
        FCheckThread.SpaceTime := FUpShareMaxUnActiveTime div 2
    end
    else
    begin
      if Assigned(FCheckThread) then
        FCheckThread.SpaceTime := FUpShareMaxUnActiveTime div 3;
    end;
  end;
end;

procedure TxdServerUpShareManage.UnLockManage;
begin
  LeaveCriticalSection( FLock );
end;

end.
