{
��Ԫ����: uJxdP2SPDownTask
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com  jxd524@gmail.com
˵    ��:
��ʼʱ��: 2011-04-11
�޸�ʱ��: 2011-04-19 (����޸�ʱ��)
��˵��  :

    ������������Ĺ�������P2P���أ�HTTP���أ�FTP���صĹ����ļ��ֶ����ط�ʽ
        ��������Ҫ��������Ϣ���ⲿ�ṩ���๦��ֻ��Ҫ���ݲ������к���ĵ��ȣ�����
}
unit uJxdP2SPDownTask;

interface

uses
  Windows, Classes, SysUtils, MD4, uJxdDataStream, uJxdFileSegmentStream, uJxdCmdDefine, uJxdUdpSynchroBasic, uJxdServerManage;

type
  {P2PԴ��Ϣ�ṹ}
  PP2PSource = ^TP2PSource;
  TP2PSource = record //P2PԴ���ⲿ��������ά��
    FUserID: Cardinal; //P2PԴID
    FUserIP: Cardinal; //P2P�û�ID
    FUserPort: Word; //P2P�û��˿�
    FSendByte: Cardinal; //�������ݵĴ�С���ļ����ݴ�С��
    FSendTime: Cardinal; //��������ʱ��
    FRecvByte: Cardinal; //���յ�����������ָ�ļ����ݴ�С��
    FRecvTime: Cardinal; //�������ݺ��һ�ν���ʱ��
    FSendBlockCount: Integer; //�ϴ�����ķֿ�����
    FTimeoutCount: Integer; //��ʱ�������������ݺ��޽��յ�����ʱʹ��
    FSegTableState: TxdSegmentStateTable; //P2P�û������ļ��ֶ���Ϣ��
  end;
  {$M+}
  TxdP2SPDownTask = class
  public
    constructor Create;
    destructor  Destroy; override;
    //��ʼ��������Ϣ
    function  SetFileInfo(const ASaveFileName: string; const AFileHash: TMD4Digest): Boolean;
    function  SetSegmentTable(const ATable: TxdFileSegmentTable): Boolean;
    function  SetUdp(AUdp: TxdUdpSynchroBasic): Boolean;
    procedure SaveAs(const ANewFileName: string); //������ɺ�ı�
    //���P2PԴ
    procedure AddP2PSource(const AUserID: Cardinal; const AIP: Cardinal; const APort: Word);
    //�������ݽӿ�
    procedure DoRecvFileData(const AIP: Cardinal; const APort: Word; const ABuf: PByte; const ABufLen: Integer);
    procedure DoRecvFileSegmentHash(const AIP: Cardinal; const APort: Word; const ABuf: PByte; const ABufLen: Integer);
    //ִ�����غ���
    procedure DoExcuteDownTask;
  private
    FUdp: TxdUdpSynchroBasic;
    FFileStream: TxdFileSegmentStream;
    FSegmentTable: TxdFileSegmentTable;
    FP2PSourceList: TThreadList;
    FCtrlEvent: Cardinal;

    FLastCalcSpeekTime: Cardinal;
    FCalcRecvByte: Integer;
    FLastCheckTime: Cardinal;

    FSaveAsFileName: string;

    //�ֶ�HASH��֤��Ϣ
    FCheckSegmentHashing: Boolean;
    FLasCheckSegmentHashTime: Cardinal;
    FCheckSegmentHashSize: Cardinal;
    FRecvSegmentHash: array of TMD4Digest;

    procedure ActiveDownTask;
    procedure UnActiveDownTask;

    procedure ClearP2PSource;
    procedure DoErrorInfo(const AInfo: string);
    function  GetHashCheckSegmentPeer: PP2PSource;
    procedure DoInvalidP2PSource(Ap: PP2PSource); //��γ�ʱ��P2PԴ

    procedure DoDownSuccess;
    procedure DoCheckSegmentHash(Ap: PP2PSource);
    procedure DoCompareSegmentHash;

    //�̺߳���
    procedure DoThreadControlP2SPDown;
    procedure CheckP2PSource(const ACurTime: Cardinal);

    procedure CalcTaskSpeek; //���������ܵ������ٶ�
    function  GetMaxBlockCount(p: PP2PSource): Integer; //�����P2P�ֿ�����
    function  IsCanGetMostNeedBlock(p: PP2PSource): Boolean; //�Ƿ�����������Ҫ�ֿ�
  private
    FActive: Boolean;
    FFileName: string;
    FFileSize: Int64;
    FFileHash: TMD4Digest;
    FFileSegmentSize: Integer;
    FMaxRequestBlockCount: Integer;
    FCurThreadCount: Integer;
    FSpeekLimit: Integer;
    FCurSpeek: Integer;
    FMaxP2PSource: Integer;
    FMaxSearchCount: Integer;
    procedure SetActive(const Value: Boolean);
    procedure SetMaxRequestBlockCount(const Value: Integer);
    procedure SetSpeekLimit(const Value: Integer);
    procedure SetMaxP2PSource(const Value: Integer);
    procedure SetMaxSearchCount(const Value: Integer);
  published
    property Active: Boolean read FActive write SetActive; //�Ƿ�������
    property FileName: string read FFileName; //�ļ�����
    property FileSize: Int64 read FFileSize; //�ļ���С
    property FileHash: TMD4Digest read FFileHash; //�ֿ�HASH
    property FileSegmentSize: Integer read FFileSegmentSize; //�ļ��ֶδ�С
    property SegmentTable: TxdFileSegmentTable read FSegmentTable; //�ļ��ֶα�
    property CurThreadCount: Integer read FCurThreadCount; //��ǰʹ���߳�����
    property MaxRequestBlockCount: Integer read FMaxRequestBlockCount write SetMaxRequestBlockCount;  //P2P�����������ֿ�����, �ֿ��С��TxdFileSegmentTableָ��
    property SpeekLimit: Integer read FSpeekLimit write SetSpeekLimit; //�ٶ����� ��λ��KB/S
    property CurSpeek: Integer read FCurSpeek; //��ǰ�ٶ� ��λ��KB/S
    property MaxP2PSource: Integer read FMaxP2PSource write SetMaxP2PSource; //���P2PԴ(�����ļ�������Դ)
    property MaxSearchCount: Integer read FMaxSearchCount write SetMaxSearchCount; //�����������
  end;
  {$M-}
  
implementation

uses
  uJxdThread;

{ TxdP2SPDownTask }

procedure TxdP2SPDownTask.ActiveDownTask;
begin
  try
    FFileStream := StreamManage.CreateFileStream(FFileName, FSegmentTable);
    if not Assigned(FFileStream) then Exit;

    FFileStream.SetFileHash( FFileHash );
    FFileStream.RenameFileName := FSaveAsFileName;
    
    FCurThreadCount := 0;
    FCalcRecvByte := 0;
    FLasCheckSegmentHashTime := 0;
    FLastCheckTime := 0;
    FCheckSegmentHashing := False;

    FCtrlEvent := CreateEvent(nil, False, False, nil);
    RunningByThread( DoThreadControlP2SPDown );
    
    FActive := True;
  except
    FActive := False;
    UnActiveDownTask;
  end;
end;

procedure TxdP2SPDownTask.AddP2PSource(const AUserID, AIP: Cardinal; const APort: Word);
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
      if (p^.FUserIP = AIP) and (p^.FUserPort = APort) then
      begin
        bFind := True;
        p^.FUserID := AUserID;
        p^.FRecvTime := 0;
        p^.FSendTime := 0;
        Break;
      end;
    end;
    if not bFind then
    begin
      New( p );
      p^.FUserID := AUserID;
      p^.FUserIP := AIP;
      p^.FUserPort := APort;
      p^.FRecvByte := 0;
      p^.FSendByte := 0;
      p^.FRecvTime := 0;
      p^.FSendTime := 0;
      lt.Add( p );
    end;
  finally
    FP2PSourceList.UnlockList;
  end;
end;

procedure TxdP2SPDownTask.CalcTaskSpeek;
var
  nTemp: Cardinal;
begin
  if FCalcRecvByte = 0 then
    FLastCalcSpeekTime := GetTickCount
  else
  begin
    nTemp := GetTickCount;
    if nTemp - FLastCalcSpeekTime > 1000 then
    begin
      FCurSpeek := Round( (FCalcRecvByte / 1024) / ((nTemp - FLastCalcSpeekTime) * 1000) );
      FLastCalcSpeekTime := nTemp;
      InterlockedExchange( FCalcRecvByte, 0 );
    end;
  end;
end;

procedure TxdP2SPDownTask.CheckP2PSource(const ACurTime: Cardinal);
begin

end;

procedure TxdP2SPDownTask.ClearP2PSource;
var
  i: Integer;
  lt: TList;
begin
  lt := FP2PSourceList.LockList;
  try
    for i := 0 to lt.Count - 1 do
      Dispose( lt[i] );
    lt.Clear;
  finally
    FP2PSourceList.UnlockList;
  end;
end;

constructor TxdP2SPDownTask.Create;
begin
  FActive := False;
  FMaxRequestBlockCount := 8;
  FCurThreadCount := 0;
  FLastCalcSpeekTime := 0;
  FCalcRecvByte := 0;
  FMaxP2PSource := 10;
  FMaxSearchCount := 5;
  FP2PSourceList := TThreadList.Create;
end;

destructor TxdP2SPDownTask.Destroy;
begin
  Active := False;
  ClearP2PSource;
  FP2PSourceList.Free;
  inherited;
end;

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
    Move( FFileHash, cmd.FFileHash, CMD4Size );
    FLasCheckSegmentHashTime := GetTickCount;
    FUdp.SendBuffer( Ap^.FUserIP, Ap^.FUserPort, @Cmd, CtCmdGetFileSegmentHashInfoSize );
  end;
end;

procedure TxdP2SPDownTask.DoCompareSegmentHash;
var
  i, j, nCount, nSegIndex: Integer;
  aryCalcSegHash: array of TMD4Digest;
  buf: PByte;
  nReadSize: Integer;
begin
  FCheckSegmentHashing := False;
  FLasCheckSegmentHashTime := 0;

  nCount := Length(FRecvSegmentHash);
  if nCount = 0 then Exit;
  GetMem( buf, FCheckSegmentHashSize );
  try
    for i := 0 to nCount - 1 do
    begin
      if i = nCount - 1 then
        nReadSize := FFileSize - Cardinal(i) * FCheckSegmentHashSize
      else
        nReadSize := FCheckSegmentHashSize;
      FFileStream.ReadBuffer(Cardinal(i) * FCheckSegmentHashSize, nReadSize, buf);
      aryCalcSegHash[i] := MD4Buffer( buf^, nReadSize );
    end;
  finally
    FreeMem( buf, FCheckSegmentHashSize );
  end;

  for i := 0 to nCount - 1 do
  begin
    if not MD4DigestCompare(aryCalcSegHash[i], FRecvSegmentHash[i]) then
    begin
      nSegIndex := (Cardinal(i) * FCheckSegmentHashSize + FSegmentTable.SegmentSize - 1) div FSegmentTable.SegmentSize;
      for j := nSegIndex to nSegIndex + Integer((FCheckSegmentHashSize + FSegmentTable.SegmentSize - 1) div FSegmentTable.SegmentSize) do
        FSegmentTable.ResetSegment( j );
    end;
  end;
end;

procedure TxdP2SPDownTask.DoDownSuccess;
begin
  OutputDebugString( '�ļ����سɹ�' );
  StreamManage.ReleaseFileStream( FFileStream );
end;

procedure TxdP2SPDownTask.DoErrorInfo(const AInfo: string);
begin
  OutputDebugString( PChar(AInfo) );
end;

procedure TxdP2SPDownTask.DoExcuteDownTask;
var
  i, nCurIndex, nCount: Integer;
  p: PP2PSource;
  lt: TList;
  oSendStream: TxdStaticMemory_2K;
  nCountPos, nRequestCount: Integer;
  bOK, bGetMostNeedBlock: Boolean;
  nSegIndex, nBlockIndex, nLen, nBlockSize: Integer;
  dwCurTime: Cardinal;
begin
  dwCurTime := GetTickCount;
  if FLastCheckTime = 0 then
    FLastCheckTime := dwCurTime;
    
  if GetTickCount - FLastCheckTime > FSegmentTable.MaxWaitTime then
  begin
    //��鳬ʱ
    FSegmentTable.CheckDownReplyWaitTime;
    FLastCheckTime := GetTickCount;
  end;
  CalcTaskSpeek;

  oSendStream := TxdStaticMemory_2K.Create;
  try

      
      //�����û���������ķֿ�����
      lt := FP2PSourceList.LockList;
      try
        p := lt[nCurIndex];
        bGetMostNeedBlock := IsCanGetMostNeedBlock(p);
        nCount := GetMaxBlockCount( p );
        nCurIndex := (nCurIndex + 1) mod lt.Count;
      finally
        FP2PSourceList.UnlockList;
      end;
      //��װ���ݰ�
      nLen := 0;
      if (nCount > 0) and (nCount <= CtMaxRequestFileBlockCount) then
      begin
        oSendStream.Clear;
        FUdp.AddCmdHead(oSendStream, CtCmd_RequestFileData);
        oSendStream.WriteLong(FFileHash, CMD4Size);
        nCountPos := oSendStream.Position;
        oSendStream.Position := oSendStream.Position + 2;
        nRequestCount := 0;
        for i := 0 to nCount - 1 do
        begin
          if bGetMostNeedBlock then
            bOK := FSegmentTable.GetNeedMostBlockInfo(nSegIndex, nBlockIndex)
          else
            bOK := FSegmentTable.GetP2PBlockInfo(nSegIndex, nBlockIndex, p^.FSegTableState);
          if bOK then
          begin
            if FSegmentTable.GetBlockSize(nSegIndex, nBlockIndex, nBlockSize) then
            begin
              Inc(nLen, nBlockSize);
              Inc(nRequestCount);
              oSendStream.WriteInteger(nSegIndex);
              oSendStream.WriteWord(nBlockIndex);
            end;
          end;
        end;
        if nRequestCount > 0 then
        begin
          p^.FSendTime := GetTickCount;
          p^.FSendByte := nLen;
          p^.FSendBlockCount := nRequestCount;

          nLen := oSendStream.Position;
          oSendStream.Position := nCountPos;
          oSendStream.WriteWord( Word(nRequestCount) );
          OutputDebugString( Pchar('���ͳ��ȣ�' + IntToStr(nLen)) );
          FUdp.SendBuffer(p^.FUserIP, p^.FUserPort, oSendStream.Memory, nLen);
        end
        else
        begin
          p^.FSendTime := 0;
          p^.FSendByte := 0;
          p^.FSendBlockCount := 0;
        end;
      end;

      if FSegmentTable.IsCompleted then
      begin
        if (FLasCheckSegmentHashTime = 0) and MD4DigestCompare( FFileStream.CalcFileHash(nil), FFileHash ) then
        begin
          //�ļ����سɹ�
          DoDownSuccess;
          Break;
        end
        else
        begin
          //һ�����������Ҫ�õ��ֶ�HASH��֤��
          if FCheckSegmentHashing then
          begin
            //��������ֶ���Ϣ
            DoCompareSegmentHash;
          end
          else
            DoCheckSegmentHash(nil);
        end;
      end;
  finally
    oSendStream.Free;
  end;
end;


procedure TxdP2SPDownTask.DoInvalidP2PSource(Ap: PP2PSource);
begin

end;

procedure TxdP2SPDownTask.DoRecvFileData(const AIP: Cardinal; const APort: Word; const ABuf: PByte; const ABufLen: Integer);
var
  pCmd: PCmdReplyRequestFileInfo;
  nPos: Int64;
  nSize: Cardinal;
  i: Integer;
  lt: TList;
  p: PP2PSource;
begin
  if ABufLen < CtMinPackageLen + CMD4Size + 1 then
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
      if (p^.FUserIP = AIP) and (p^.FUserPort = APort) then
      begin
        p^.FRecvByte := p^.FRecvByte + pCmd^.FBufferLen;
        p^.FRecvTime := GetTickCount;
        Break;
      end;
    end;
  finally
    FP2PSourceList.UnlockList;
  end;
  //д���ļ�
  FFileStream.WriteBlockBuffer( pCmd^.FSegmentIndex, pCmd^.FBlockIndex, @pCmd^.FBuffer, pCmd^.FBufferLen );
end;

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
    Move( pCmd^.FSegmentHashs[i], FRecvSegmentHash[i], CMD4Size );
  FCheckSegmentHashing := True;
end;

procedure TxdP2SPDownTask.DoThreadControlP2SPDown;
var
  i, nCurIndex, nCount: Integer;
  p: PP2PSource;
  lt: TList;
  nWaitTime: Cardinal;
  oSendStream: TxdStaticMemory_2K;
  nCountPos, nRequestCount: Integer;
  bOK, bGetMostNeedBlock: Boolean;
  nSegIndex, nBlockIndex, nLen, nBlockSize: Integer;
  nLastCheckTime: Cardinal;
begin
  InterlockedIncrement( FCurThreadCount );
  nWaitTime := 100;
  nCurIndex := 0;
  nLastCheckTime := GetTickCount;
  oSendStream := TxdStaticMemory_2K.Create;
  try
    while Active do
    begin
      if GetTickCount - nLastCheckTime > FSegmentTable.MaxWaitTime then
      begin
        //��鳬ʱ
        FSegmentTable.CheckDownReplyWaitTime;
        nLastCheckTime := GetTickCount;
      end;
      CalcTaskSpeek;
      
      //�����û���������ķֿ�����
      lt := FP2PSourceList.LockList;
      try
        p := lt[nCurIndex];
        bGetMostNeedBlock := IsCanGetMostNeedBlock(p);
        nCount := GetMaxBlockCount( p );
        nCurIndex := (nCurIndex + 1) mod lt.Count;
      finally
        FP2PSourceList.UnlockList;
      end;
      //��װ���ݰ�
      nLen := 0;
      if (nCount > 0) and (nCount <= CtMaxRequestFileBlockCount) then
      begin
        oSendStream.Clear;
        FUdp.AddCmdHead(oSendStream, CtCmd_RequestFileData);
        oSendStream.WriteLong(FFileHash, CMD4Size);
        nCountPos := oSendStream.Position;
        oSendStream.Position := oSendStream.Position + 2;
        nRequestCount := 0;
        for i := 0 to nCount - 1 do
        begin
          if bGetMostNeedBlock then
            bOK := FSegmentTable.GetNeedMostBlockInfo(nSegIndex, nBlockIndex)
          else
            bOK := FSegmentTable.GetP2PBlockInfo(nSegIndex, nBlockIndex, p^.FSegTableState);
          if bOK then
          begin
            if FSegmentTable.GetBlockSize(nSegIndex, nBlockIndex, nBlockSize) then
            begin
              Inc(nLen, nBlockSize);
              Inc(nRequestCount);
              oSendStream.WriteInteger(nSegIndex);
              oSendStream.WriteWord(nBlockIndex);
            end;
          end;
        end;
        if nRequestCount > 0 then
        begin
          p^.FSendTime := GetTickCount;
          p^.FSendByte := nLen;
          p^.FSendBlockCount := nRequestCount;

          nLen := oSendStream.Position;
          oSendStream.Position := nCountPos;
          oSendStream.WriteWord( Word(nRequestCount) );
          OutputDebugString( Pchar('���ͳ��ȣ�' + IntToStr(nLen)) );
          FUdp.SendBuffer(p^.FUserIP, p^.FUserPort, oSendStream.Memory, nLen);
        end
        else
        begin
          p^.FSendTime := 0;
          p^.FSendByte := 0;
          p^.FSendBlockCount := 0;
        end;
      end;

      if FSegmentTable.IsCompleted then
      begin
        if (FLasCheckSegmentHashTime = 0) and MD4DigestCompare( FFileStream.CalcFileHash(nil), FFileHash ) then
        begin
          //�ļ����سɹ�
          DoDownSuccess;
          Break;
        end
        else
        begin
          //һ�����������Ҫ�õ��ֶ�HASH��֤��
          if FCheckSegmentHashing then
          begin
            //��������ֶ���Ϣ
            DoCompareSegmentHash;
          end
          else
            DoCheckSegmentHash(nil);
        end;
      end;

      WaitForSingleObject( FCtrlEvent, nWaitTime );
    end;
  finally
    oSendStream.Free;
    InterlockedDecrement( FCurThreadCount );
  end;
end;

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

function TxdP2SPDownTask.GetMaxBlockCount(p: PP2PSource): Integer;
const
  CtTimeOutTimeSpace = 2000;
  CtMaxTimeoutCount = 10;
var
  nSpeed1, nSpeed2: Integer;
  nTimeSpace: Cardinal;
  nCurTime: Cardinal;
begin
  //P2P�����ٶȿ��ƺ������ھ����У��������㷨��ɵ������ٶȴ��Ϊ1M/S��
  //��ʱ��Ҫ���ͷ�����ϰ����ݴﵽ����3500��
//  Result := 3;
//  Exit;

  Result := 0;
  if p^.FSendByte = 0 then
    Result := 1
  else
  begin
    nCurTime := GetTickCount;
    if p^.FRecvByte = 0 then
    begin
      //�Ѿ��������ݣ����Է���û�з��͹���, �������2�뻹û�н��յ����ݣ�����Ϊ��ʱ
      if nCurTime - p^.FSendTime > CtTimeOutTimeSpace then
      begin
        if p^.FTimeoutCount > CtMaxTimeoutCount then
        begin
          DoInvalidP2PSource( p );
          Result := 0;
        end
        else
        begin
          Inc( p^.FTimeoutCount );
          Result := 1;
        end;
      end;
    end
    else
    begin
      //�Ѿ����յ����ݿ�
      nTimeSpace := nCurTime - p^.FSendTime;
      if nTimeSpace = 0 then nTimeSpace := 1;
      nSpeed1 := p^.FSendByte div nTimeSpace;

      nTimeSpace := p^.FRecvTime - p^.FSendTime;
      if nTimeSpace = 0 then nTimeSpace := 1;
      nSpeed2 := p^.FRecvByte div nTimeSpace;
      
      if nSpeed2 >= nSpeed1 then
      begin
        //����ٶ�
        if p^.FTimeoutCount = 0 then
          Result := p^.FSendBlockCount + 1
        else
        begin
          Result := nSpeed2 * 100 div CtBlockSize;
          if Result > p^.FSendBlockCount then
            Result := p^.FSendBlockCount + 1
          else if Result < p^.FSendBlockCount then
            Result := p^.FSendBlockCount - 1;
        end;
          
        p^.FTimeoutCount := 0;
        if Result <= 0 then
          Result := 1
        else if Result > CtMaxRequestFileBlockCount then
          Result := p^.FSendBlockCount + 1;
      end
      else
      begin
        //�ٶȴﲻ��Ԥ��
        if (p^.FTimeoutCount < CtMaxTimeoutCount) and ((nCurTime - p^.FSendTime) < CtTimeOutTimeSpace) then
        begin
          //��ͣ����
          Result := 0;
          Inc( p^.FTimeoutCount );
        end
        else
        begin
          p^.FTimeoutCount := 0;
          Result := (Cardinal(nSpeed2) * nTimeSpace + CtMaxRequestPackageSize - 1) div CtMaxRequestPackageSize;
          if Result <= 0 then
            Result := 1
          else if Result > p^.FSendBlockCount then
            Result := p^.FSendBlockCount + 1;
        end;
      end;
    end;
  end;
  if Result > 0 then
  begin
    p^.FRecvByte := 0;
    p^.FRecvTime := 0;
  end;
end;

function TxdP2SPDownTask.IsCanGetMostNeedBlock(p: PP2PSource): Boolean;
begin
  Result := True;
end;

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

function TxdP2SPDownTask.SetFileInfo(const ASaveFileName: string; const AFileHash: TMD4Digest): Boolean;
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
  end;
end;

procedure TxdP2SPDownTask.SetMaxP2PSource(const Value: Integer);
begin
  if (FMaxP2PSource <> Value) and (Value > 0) then
    FMaxP2PSource := Value;
end;

procedure TxdP2SPDownTask.SetMaxRequestBlockCount(const Value: Integer);
begin
  if (FMaxRequestBlockCount <> Value) and (Value > 0) and (Value <= CtMaxRequestFileBlockCount) then
    FMaxRequestBlockCount := Value;
end;

procedure TxdP2SPDownTask.SetMaxSearchCount(const Value: Integer);
begin
  if (FMaxSearchCount <> Value) and (Value > 0) then
    FMaxSearchCount := Value;
end;

function TxdP2SPDownTask.SetSegmentTable(const ATable: TxdFileSegmentTable): Boolean;
begin
  Result := (not Active) and Assigned(ATable);
  if Result then
  begin
    FSegmentTable := ATable;
    FFileSize := FSegmentTable.FileSize;
    FFileSegmentSize := FSegmentTable.SegmentSize;
  end;
end;

procedure TxdP2SPDownTask.SetSpeekLimit(const Value: Integer);
begin
  if FSpeekLimit <> Value then
    FSpeekLimit := Value;
end;

function TxdP2SPDownTask.SetUdp(AUdp: TxdUdpSynchroBasic): Boolean;
begin
  Result := not Active and Assigned(AUdp);
  if Result then
    FUdp := AUdp;
end;

procedure TxdP2SPDownTask.UnActiveDownTask;
begin
  FActive := False;
  if FCtrlEvent <> 0 then
    SetEvent( FCtrlEvent );
  while FCurThreadCount > 0 do
    Sleep( 10 );
  if FCtrlEvent <> 0 then
    CloseHandle( FCtrlEvent );
  FCtrlEvent := 0;
  if Assigned(FFileStream) then
    StreamManage.ReleaseFileStream( FFileStream );
end;

end.
