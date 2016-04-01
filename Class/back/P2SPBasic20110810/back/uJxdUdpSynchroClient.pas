unit uJxdUdpSynchroClient;

interface

uses
  Windows, SysUtils, Forms,
  uJxdUdpIoHandle, uJxdUdpSynchroBasic, uJxdDataStruct, uJxdDataStream;

type
  TSynchroResult = (srSuccess{�ɹ�}, srSystemBuffer{ϵͳ��̬�����ڴ棬�ⲿҪ����ReleaseSynchroRecvBuffer},
                    srNoEnoughSynchroID{ͬ��ID������}, srFail{ʧ��});
  //ͬ����Ϣ�� �����յ�ͬ������ʱ����Ҫȥ�жϣ���IP��PORT��SynchroID������ͬʱ����Ϊͬһͬ������
  PSynchroPackageInfo = ^TSynchroPackageInfo;
  TSynchroPackageInfo = record
    FSynchroID: Word;              //ͬ��ID
    FSendPort: Word;               //���Ͷ˿�
    FSendIP: Cardinal;             //����IP
    FSendBufLen: Integer;          //��Ҫ�������ݵĳ���
    FSendCount: Integer;           //�Ѿ����͵Ĵ���
    FRecvLen: Integer;             //�ⲿָ�����ڽ������ݵĳ���
    FRecvLenEx: Integer;           //ϵͳ��̬������ڴ��С
    FRecvFinished: Boolean;        //ָ���Ƿ��Ѿ����յ�ָ��ͬ����
    FSendBuffer: PAnsiChar;        //��Ҫ���͵�����  ��̬���룬�Ѿ�����ͬ������
    FRecvBuffer: PAnsiChar;        //���յ������� ���ɴ���ָ������ָ�����ڴ治���������ʱ����ϵͳ��̬����
    FRecvBufferEx: PAnsiChar;      //ϵͳ��̬����
  end;

  TxdUdpSynchroClient = class(TxdUdpSynchroBasic)
  public
    constructor Create; override;
    //�ͷ�ͬ�������ص��ڴ�
    procedure ReleaseSynchroRecvBuffer(ARecvBuffer: PAnsiChar);

    //����ͬ������
    //ASendBuffer���ݰ���ǰ�����Ԥ���ĸ��ֽ�.
    //ASendBuffer����Ԥ�����ĸ��ֽں���Ҫ���͵����ݳ���
    //ARecvBuffer: ���ջ��棬����ָ����������ϵͳ��̬���롣
    //ARecvLen: ���ARecvBufferʹ��
    //AllowReSendCount: ��������ط�����
    //ATimeoutSpace: ÿ�η��ͺ󣬵ȴ�ʱ�䳬�����趨�����ʾ����, ��λ������
    //AProMsg: �ڵȴ��У��Ƿ����Application.ProccessMessage.��������̣߳���ΪTrue. �����߳�����ΪFalse
    function SendSynchroBuffer(const AIP: Cardinal; const APort: Word; const ASendBuffer: PAnsiChar;
      const ASendBufLen: Integer; var ARecvBuffer: PAnsiChar; var ARecvLen: Integer; AProMsg: Boolean = True;
      AllowReSendCount: Integer = 3; const ATimeoutSpace: Cardinal = 2000): TSynchroResult;
  protected
    function  DoBeforOpenUDP: Boolean; override;  //��ʼ��UDPǰ; True: �����ʼ��; False: �������ʼ��
    procedure DoAfterCloseUDP; override; //UDP�ر�֮��
    procedure OnCommonRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); override;

    {����ֻ��Ҫ������麯������Ч��ͬ�������Ѿ���������, �����ʱ����ͬ��������������һ�ͻ��˷�������}
    procedure DoHandleRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
      const AIsSynchroCmd: Boolean; const ASynchroID: Word); virtual;
  private
    FSynchroIdManage: TWordIdManage;
    FSynchroLock: TRTLCriticalSection;
    FSynchroList: THashArrayEx;
    procedure ClearSynchroList;
  private
    FSynchroHashTableCount: Integer;
    FSynchroHashNodeCount: Integer;
    FReSendSynchroPackageCount: Integer;
    FReRecvsynchroPackageCount: Integer;
    FSendSynchroPackageFailCount: Integer;
    FDropRecvOverdueSynchroPackageCount: Integer;
    procedure SetSynchroHashTableCount(const Value: Integer);
    procedure SetSynchroHashNodeCount(const Value: Integer);
  published
    property ReRecvSynchroPackageCount: Integer read FReRecvsynchroPackageCount;//�ظ����յ���ͬͬ��������
    property ReSendSynchroPackageCount: Integer read FReSendSynchroPackageCount; //�ط�ͬ��������
    property SendSynchroPackageFailCount: Integer read FSendSynchroPackageFailCount; //����ͬ����ʧ�ܴ���
    property DropRecvOverdueSynchroPackageCount: Integer read FDropRecvOverdueSynchroPackageCount; //�������ڰ�����
    property SynchroHashTableCount: Integer read FSynchroHashTableCount write SetSynchroHashTableCount;
    property SynchroHashNodeCount: Integer read FSynchroHashNodeCount write SetSynchroHashNodeCount; 
  end;

implementation

const
  CtSynchroPackageInfoSize = SizeOf( TSynchroPackageInfo );

{ TxdUdpSynchroClient }

procedure TxdUdpSynchroClient.ClearSynchroList;
begin

end;

constructor TxdUdpSynchroClient.Create;
begin
  inherited;
  FSynchroHashTableCount := 131;
  FSynchroHashNodeCount := 512;
end;

procedure TxdUdpSynchroClient.DoAfterCloseUDP;
begin
  inherited;
  ClearSynchroList;
  FreeAndNil( FSynchroList );
  FreeAndNil( FSynchroIdManage );
  DeleteCriticalSection( FSynchroLock );
end;

function TxdUdpSynchroClient.DoBeforOpenUDP: Boolean;
begin
  Result := inherited DoBeforOpenUDP;
  if Result then
  begin
    try
      InitializeCriticalSection( FSynchroLock );
      FSynchroIdManage := TWordIdManage.Create;
      FSynchroList := THashArrayEx.Create;
      with FSynchroList do
      begin
        HashTableCount := SynchroHashTableCount;
        MaxHashNodeCount := SynchroHashNodeCount;
        Active := True;
      end;
      FReSendSynchroPackageCount := 0;
      FReRecvsynchroPackageCount := 0;
      FSendSynchroPackageFailCount := 0;
      FDropRecvOverdueSynchroPackageCount := 0;
    except
      Result := False;
    end;
  end;
end;

procedure TxdUdpSynchroClient.DoHandleRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Cardinal;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
begin

end;

procedure TxdUdpSynchroClient.OnCommonRecvBuffer(const AIP: Cardinal; const APort: Word; const ABuffer: pAnsiChar; const ABufLen: Integer;
  const AIsSynchroCmd: Boolean; const ASynchroID: Word);
var
  pNode: PHashNode;
  bFind: Boolean;
  pSynchro: PSynchroPackageInfo;
begin
  bFind := False;
  if AIsSynchroCmd then
  begin
    //������Ҫ��ͬ����
    pSynchro := nil;
    EnterCriticalSection( FSynchroLock );
    pNode := FSynchroList.FindBegin( ASynchroID );
    try
      while Assigned(pNode) do
      begin
        pSynchro := PSynchroPackageInfo( pNode^.NodeData );
        if Assigned(pSynchro) and (pSynchro^.FSynchroID = ASynchroID) and (pSynchro^.FSendIP = AIP)
          and (pSynchro^.FSendPort = APort) then
        begin
          bFind := True;
          Break;
        end;
        pNode := FSynchroList.FindNext( pNode );
      end;
      if bFind then
      begin
        if not pSynchro^.FRecvFinished then
        begin
          if Assigned(pSynchro^.FRecvBuffer) and (pSynchro^.FRecvLen >= ABufLen) then
          begin
            Move( ABuffer^, pSynchro^.FRecvBuffer^, ABufLen );
            pSynchro^.FRecvLen := ABufLen;
            pSynchro^.FRecvFinished := True;
          end
          else
          begin
            GetMem( pSynchro^.FRecvBufferEx, ABufLen );
            Move( ABuffer^, pSynchro^.FRecvBufferEx^, ABufLen );
            pSynchro^.FRecvLenEx := ABufLen;
            pSynchro^.FRecvFinished := True;
          end;
        end
        else
          InterlockedIncrement( FReRecvsynchroPackageCount );
      end;
    finally
      FSynchroList.FindEnd;
      LeaveCriticalSection( FSynchroLock );
    end;
  end;
  if not bFind then
    DoHandleRecvBuffer( AIP, APort, ABuffer, ABufLen, AIsSynchroCmd, ASynchroID );
end;

procedure TxdUdpSynchroClient.ReleaseSynchroRecvBuffer(ARecvBuffer: PAnsiChar);
begin
  if Assigned(ARecvBuffer) then
    FreeMem( ARecvBuffer );
end;

function TxdUdpSynchroClient.SendSynchroBuffer(const AIP: Cardinal; const APort: Word; const ASendBuffer: PAnsiChar; const ASendBufLen: Integer;
  var ARecvBuffer: PAnsiChar; var ARecvLen: Integer; AProMsg: Boolean; AllowReSendCount: Integer; const ATimeoutSpace: Cardinal): TSynchroResult;
var
  SynchroInfo: TSynchroPackageInfo;
  i, nCount: Integer;
  pNode: PHashNode;
  pSynchro: PSynchroPackageInfo;
  nTemp: Cardinal;
begin
  Result := srFail;
  FillChar( SynchroInfo, CtSynchroPackageInfoSize, 0 );
  //����ID
  if not FSynchroIdManage.GetWordID(SynchroInfo.FSynchroID) then
  begin
    DoErrorInfo( '�޷�����ͬ��ID�����ܽ���ͬ�����ķ���' );
    Result := srNoEnoughSynchroID;
    Exit;
  end;

  nCount := AllowReSendCount;
  if nCount <= 0 then
    nCount := 3;

  //��ʼ������
  SynchroInfo.FSendPort := APort;
  SynchroInfo.FSendIP := AIP;
  SynchroInfo.FRecvFinished := False;
  SynchroInfo.FSendBufLen := ASendBufLen;
  SynchroInfo.FSendBuffer := ASendBuffer;
  AddSynchroSign( SynchroInfo.FSendBuffer, SynchroInfo.FSynchroID );
  if Assigned(ARecvBuffer) and (ARecvLen > 0) then
  begin
    SynchroInfo.FRecvBuffer := ARecvBuffer;
    SynchroInfo.FRecvLen := ARecvLen;
  end;

 //��ӵ��б�
  EnterCriticalSection( FSynchroLock );
  try
    if not FSynchroList.Add(SynchroInfo.FSynchroID, @SynchroInfo) then
    begin
      FSynchroIdManage.ReclaimWordID( SynchroInfo.FSynchroID );
      Result := srFail;
      DoErrorInfo( '�޷���ӵ�ͬ��HASH����' );
      Exit;
    end;
  finally
    LeaveCriticalSection( FSynchroLock );
  end;

  //��ʼ����
  for i := 0 to nCount - 1 do
  begin
    nTemp := GetTickCount;
    if SendBuffer(SynchroInfo.FSendIP, SynchroInfo.FSendPort, SynchroInfo.FSendBuffer, SynchroInfo.FSendBufLen) <> SynchroInfo.FSendBufLen then
    begin
      DoErrorInfo( '�޷���������' );
      Break;
    end;
    //�ȴ�����,��ʹ���ں��¼�֪ͨ��ֻҪ�򵥵���ѯ�ʷ�ʽ�Ϳ�
    while not SynchroInfo.FRecvFinished do
    begin
      Sleep(10);
      if AProMsg then
        Application.ProcessMessages;
      if SynchroInfo.FRecvFinished then Break; //��ɣ��˳�
      if GetTickCount - nTemp > ATimeoutSpace then Break; //��ʱ���ط�
    end;
    if SynchroInfo.FRecvFinished then
      Break
    else if i <> nCount - 1 then
      InterlockedIncrement( FReSendSynchroPackageCount );
  end;


  //��Hash����ɾ��
  EnterCriticalSection( FSynchroLock );
  pNode := FSynchroList.FindBegin( SynchroInfo.FSynchroID );
  try
    while Assigned(pNode) do
    begin
      pSynchro := PSynchroPackageInfo( pNode^.NodeData );
      if Assigned(pSynchro) and (pSynchro^.FSynchroID = SynchroInfo.FSynchroID) and (pSynchro^.FSendIP = AIP)
        and (pSynchro^.FSendPort = APort) then
      begin
        FSynchroList.FindDelete( pNode );
        Break;
      end;
      pNode := FSynchroList.FindNext( pNode );
    end;
  finally
    FSynchroList.FindEnd;
    LeaveCriticalSection( FSynchroLock );
  end;

  //�ͷ�ID
  FSynchroIdManage.ReclaimWordID( SynchroInfo.FSynchroID );

  //�ж�����
  if SynchroInfo.FRecvFinished then
  begin
    //���յ�����
    if Assigned(SynchroInfo.FRecvBuffer) and (SynchroInfo.FRecvLen > 0) then
    begin
      ARecvBuffer := SynchroInfo.FRecvBuffer;
      ARecvLen := SynchroInfo.FRecvLen;
      Result := srSuccess
    end
    else
    begin
      ARecvBuffer := SynchroInfo.FRecvBufferEx;
      ARecvLen := SynchroInfo.FRecvLenEx;
      Result := srSystemBuffer;
    end;
  end
  else
    InterlockedIncrement( FSendSynchroPackageFailCount );
end;

procedure TxdUdpSynchroClient.SetSynchroHashNodeCount(const Value: Integer);
begin
  if not Active then
    FSynchroHashNodeCount := Value;
end;

procedure TxdUdpSynchroClient.SetSynchroHashTableCount(const Value: Integer);
begin
  if not Active then
    FSynchroHashTableCount := Value;
end;

end.
