{
��Ԫ����: uJxdFileUploadManage
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com  jxd524@gmail.com
˵    ��:
��ʼʱ��: 2011-04-12
�޸�ʱ��: 2011-04-12 (����޸�ʱ��)
��˵��  :
    �����ļ��ϴ���P2P���ݴ��䣬P2S���ݴ���
    �����ķ�ʽ�������ݵĴ��䣬
        �����յ����󷽵�Ҫ��ʱ�����ʺϵķ�ʽ��Ӧ�Է���

    ���� TUploadManageInfo ��Ϣ 

}
unit uJxdFileUploadManage;

interface

uses
  Windows, ExtCtrls, uJxdHashCalc, uJxdDataStruct, uJxdDataStream, uJxdUdpSynchroBasic, uJxdFileSegmentStream, uJxdFileShareManage, uJxdCmdDefine
  {$IFDEF ServerManage}
  //����Ƿ�����
  , uJxdMemoryManage
  {$ELSE}
  //����ǿͻ���
  , uJxdDownTaskManage
  {$ENDIF};

type
  PUploadManageInfo = ^TUploadManageInfo;
  TUploadManageInfo = record
    FFileStream: TxdP2SPFileStreamBasic;
    FLastActiveTime: Cardinal;
    FFileShareInfo: PFileShareInfo;
    FCount: Integer;
  end;
  TxdFileUploadManage = class
  public
    constructor Create(AUdp: TxdUdpSynchroBasic; AFileShareManage: TxdFileShareManage; const AMaxUploadTask: Integer = 10000);
    destructor  Destroy; override;

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
    FCurFindWebHash: TxdHash;
    FFindManageInfo: PUploadManageInfo;
    {$IFDEF ServerManage}
    FManageMem: TxdFixedMemoryManager;
    {$ENDIF}
    FManageList: THashArrayEx;
    FManageLock: TRTLCriticalSection;
    FUdp: TxdUdpSynchroBasic;
    FShareManage: TxdFileShareManage;
    FCurCheckTime: Cardinal;
    FCheckTimer: TTimer;
    procedure DoErrorInfo(const AInfo: string);
    procedure DoloopToFreeAllTask(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean);
    procedure DoLoopToFreeSpaceTask(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean);
    procedure DoLoopToFindInfoByWebHash(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean);
    
    function  GetFileUploadMem: PUploadManageInfo;
    procedure FreeFileUploadMem(Ap: PUploadManageInfo);

    function  SearchManage(const AHashStyle: THashStyle; const AHash: TxdHash): PUploadManageInfo;
    procedure ReleaseSearchInfo(const Ap: PUploadManageInfo); inline;

    procedure DoTimerToFreeSpaceTask(Sender: TObject);
  private
    FMaxSpaceTime: Cardinal;
    {$IFNDEF ServerManage}
    FDownManage: TxdDownTaskManage;
    {$ENDIF}
    function GetCurShareCount: Integer; 
  public
    property CurShareCount: Integer read GetCurShareCount;
    property MaxSpaceTime: Cardinal read FMaxSpaceTime write FMaxSpaceTime; //������ʱ�䣬������ʱ���Լ�ɾ���ڴ�
    {$IFNDEF ServerManage}
    property DownManage: TxdDownTaskManage read FDownManage write FDownManage;
    {$ENDIF}
  end;

const
  CtUploadManageInfoSize = SizeOf(TUploadManageInfo);

implementation

{ TxdFileUploadManage }

constructor TxdFileUploadManage.Create(AUdp: TxdUdpSynchroBasic; AFileShareManage: TxdFileShareManage; const AMaxUploadTask: Integer);
begin
  FMaxSpaceTime := 1000 * 60 * 10;
  InitializeCriticalSection( FManageLock );
  FUdp := AUdp;
  FShareManage := AFileShareManage;
  FManageList := THashArrayEx.Create;
  FManageList.HashTableCount := 1313;
  FManageList.MaxHashNodeCount := AMaxUploadTask;
  FManageList.Active := True;

  {$IFDEF ServerManage}
  FManageMem := TxdFixedMemoryManager.Create(CtUploadManageInfoSize, AMaxUploadTask);
  {$ENDIF}

  FCheckTimer := TTimer.Create(nil);
  FCheckTimer.Interval := FMaxSpaceTime;
  FCheckTimer.OnTimer := DoTimerToFreeSpaceTask;
  FCheckTimer.Enabled := True;
end;

destructor TxdFileUploadManage.Destroy;
begin
  FCheckTimer.Enabled := False;
  FCheckTimer.Free;
  FManageList.Loop( DoloopToFreeAllTask );
  FManageList.Free;
  {$IFDEF ServerManage}
  FManageMem.Free;
  {$ENDIF}
  DeleteCriticalSection( FManageLock );
  inherited;
end;

procedure TxdFileUploadManage.DoErrorInfo(const AInfo: string);
begin
  OutputDebugString( PChar(AInfo) );
end;

procedure TxdFileUploadManage.DoHandleCmd_QueryFileInfo(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdQueryFileInfo;
  p: PUploadManageInfo;
  oSendStream: TxdStaticMemory_512Byte;
  ReplySign: TReplySign;
begin
  if ABufLen <> CtCmdQueryFileInfoSize then
  begin
    DoErrorInfo( '��ѯ�ļ���Ϣ����Ȳ���ȷ: CtCmd_QueryFileInfo' );
    Exit;
  end;
  pCmd := PCmdQueryFileInfo(ABuffer);
  p := SearchManage( pCmd^.FHashStyle, TxdHash(pCmd^.FHash) );
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
        oSendStream.WriteInt64( p^.FFileShareInfo^.FFileSize );
        oSendStream.WriteCardinal( p^.FFileShareInfo^.FSegmentSize );
        if pCmd^.FHashStyle = hsWebHash then
          oSendStream.WriteLong( p^.FFileShareInfo^.FFileHash, CtHashSize );
      end;
      FUdp.SendBuffer( AIP, APort, oSendStream.Memory, oSendStream.Position );
    finally
      oSendStream.Free;
    end;
  finally
    ReleaseSearchInfo( p );
  end;
end;

procedure TxdFileUploadManage.DoHandleCmd_QueryFileProgress(const AIP: Cardinal; const APort: Word; const ABuffer: PAnsiChar; const ABufLen: Cardinal;
  const AIssynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdQueryFileProgressInfo;
  p: PUploadManageInfo;
  oSendStream: TxdStaticMemory_512Byte;
  ReplySign: TReplySign;
begin
  if ABufLen <> CtCmdQueryFileProgressInfoSize then
  begin
    DoErrorInfo( 'QueryFileProgress ����Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdQueryFileProgressInfo(ABuffer);
  p := SearchManage( pCmd^.FHashStyle, TxdHash(pCmd^.FHash) );
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
        oSendStream.WriteByte( Byte(0) ); //��ʾ���ļ��Ѿ����
      FUdp.SendBuffer( AIP, APort, oSendStream.Memory, oSendStream.Position );
    finally
      oSendStream.Free;
    end;
  finally
    ReleaseSearchInfo( p );
  end;
end;

procedure TxdFileUploadManage.DoHandleCmd_GetFileSegmentHash(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
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
  p := FShareManage.FindShareInfoByFileHash( TxdHash(pCmd^.FHash) );
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
end;

procedure TxdFileUploadManage.DoHandleCmd_RequestFileData(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pCmd: PCmdRequestFileDataInfo;
  p: PUploadManageInfo;
  stream: TxdP2SPFileStreamBasic;
  oSendStream: TxdStaticMemory_16K;
  i: Integer;
  buf: PChar;
  nSize: Integer;
  bWait: Boolean;
begin
  if ABufLen < CtCmdRequestFileDataInfoSize then
  begin
    DoErrorInfo( '������������Ȳ���ȷ' );
    Exit;
  end;
  pCmd := PCmdRequestFileDataInfo(ABuffer);
  oSendStream := TxdStaticMemory_16K.Create;
  p := SearchManage( pCmd^.FHashStyle, TxdHash(pCmd^.FHash) );
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
            oSendStream.WriteLong(pCmd^.FHash, 16);
            oSendStream.WriteByte(Byte(rsSuccess));
            oSendStream.WriteInteger(pCmd^.FRequestInfo[i].FSegmentIndex);
            oSendStream.WriteWord(pCmd^.FRequestInfo[i].FBlockIndex);
            oSendStream.WriteWord(nSize);
            oSendStream.WriteLong(buf^, nSize);

            bWait := False;
            while FUdp.CombiMaxBufferCount - FUdp.RecvCombiCount < 8 do
            begin
              Sleep( 100 );
              bWait := True;
            end;

            while oSendStream.Position <> FUdp.SendBuffer(AIP, APort, oSendStream.Memory, oSendStream.Position) do
            begin
              Sleep( 100 );
              bWait := True;
            end;
            if bWait then
              Sleep( 10 );
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
    ReleaseSearchInfo( p );
  end;
end;

procedure TxdFileUploadManage.DoLoopToFindInfoByWebHash(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel, AFindNext: Boolean);
var
  p: PUploadManageInfo;
begin
  p := pData;
  AFindNext := not HashCompare( p^.FFileShareInfo^.FWebHash, FCurFindWebHash );
  if not AFindNext then
    FFindManageInfo := p;
end;

procedure TxdFileUploadManage.DoloopToFreeAllTask(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel, AFindNext: Boolean);
begin
  FreeFileUploadMem( pData );
  ADel := True;
end;

procedure TxdFileUploadManage.DoLoopToFreeSpaceTask(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel, AFindNext: Boolean);
var
  p: PUploadManageInfo;
begin
  p := pData;
  AFindNext := True;
  ADel := (FCurCheckTime > p^.FLastActiveTime) and (FCurCheckTime - p^.FLastActiveTime > MaxSpaceTime);
  if ADel then
    FreeFileUploadMem( p );
end;

procedure TxdFileUploadManage.DoTimerToFreeSpaceTask(Sender: TObject);
begin
  FCheckTimer.Enabled := False;

  EnterCriticalSection( FManageLock );
  try
    FCurCheckTime := GetTickCount;
    FManageList.Loop( DoLoopToFreeSpaceTask );
  finally
    LeaveCriticalSection( FManageLock );
  end;

  FCheckTimer.Enabled := True;
end;

procedure TxdFileUploadManage.FreeFileUploadMem(Ap: PUploadManageInfo);
var
  bOK: Boolean;
begin
  FillChar( Ap^, CtUploadManageInfoSize, 0 );
  {$IFDEF ServerManage}
  bOK := FManageMem.FreeMem(Ap);
  {$ELSE}
  bOK := False;
  {$ENDIF}
  if not bOK then
    FreeMem( Ap, CtUploadManageInfoSize );
end;

function TxdFileUploadManage.GetCurShareCount: Integer;
begin
  if Assigned(FManageList) then
    Result := FManageList.Count
  else
    Result := 0;
end;

function TxdFileUploadManage.GetFileUploadMem: PUploadManageInfo;
begin
  Result := nil;
  {$IFDEF ServerManage}
  FManageMem.GetMem(Pointer(Result));
  {$ENDIF}
  if not Assigned(Result) then
  begin
    GetMem( Pointer(Result), CtUploadManageInfoSize );
    FillChar( Result^, CtUploadManageInfoSize, 0 );
  end;
end;

procedure TxdFileUploadManage.ReleaseSearchInfo(const Ap: PUploadManageInfo);
begin
  if Assigned(Ap) then
    InterlockedDecrement( Ap^.FCount );
end;

function TxdFileUploadManage.SearchManage(const AHashStyle: THashStyle; const AHash: TxdHash): PUploadManageInfo;
var
  nID: Cardinal;
  pNode: PHashNode;
  pShare: PFileShareInfo;
  p: PUploadManageInfo;
  bFind: Boolean;
  {$IFNDEF ServerManage}
  pTaskInfo: PTaskManageInfo;
  {$ENDIF}
begin
  bFind := False;
  Result := nil;
  EnterCriticalSection( FManageLock );
  try
    if AHashStyle = hsFileHash then
    begin
      //�����ļ�HASH
      nID := HashToID(AHash);
      pNode := FManageList.FindBegin(nID);
      while Assigned(pNode) do
      begin
        p := pNode^.NodeData;
        if HashCompare(p^.FFileStream.FileHash, AHash) then
        begin
          bFind := True;
          Result := p;
          InterlockedIncrement( Result^.FCount );
          Break;
        end;
        pNode := FManageList.FindNext( pNode );
      end;
    end
    else
    begin
      //����WEB HASH
      FCurFindWebHash := AHash;
      FFindManageInfo := nil;
      FManageList.Loop( DoLoopToFindInfoByWebHash );
      bFind := Assigned(FFindManageInfo);
      if bFind then
      begin
        Result := FFindManageInfo;
        InterlockedIncrement( Result^.FCount );
      end;
    end;

    if not bFind then
    begin
      if AHashStyle = hsFileHash then
        pShare := FShareManage.FindShareInfoByFileHash(AHash)
      else
        pShare := FShareManage.FindShareInfoByWebHash(AHash);
      if Assigned(pShare) then
      begin
        nID := HashToID(pShare^.FFileHash);
        p := GetFileUploadMem;
        p^.FFileStream := StreamManage.CreateFileStream( pShare^.FFileName, pShare^.FFileHash, pShare^.FSegmentSize );;
        p^.FFileShareInfo := pShare;
        p^.FCount := 1;
        FManageList.Add( nID, p );
        Result := p;
      end
      else
      begin
        //
        {$IFNDEF ServerManage}
        if Assigned(DownManage) then
        begin
          pTaskInfo := DownManage.FindTaskInfo( AHashStyle, AHash );
          try
            if Assigned(pTaskInfo) then
            begin
        
            end;
          finally
            DownManage.ReleaseFindInfo( pTaskInfo );
          end;
        end;
        {$ENDIF}  
      end;       
    end;
    if Assigned(Result) then
      Result^.FLastActiveTime := GetTickCount;
  finally
    FManageList.FindEnd;
    LeaveCriticalSection( FManageLock );
  end;
end;

end.
