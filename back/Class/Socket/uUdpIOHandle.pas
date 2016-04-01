{
��Ԫ����: uUdpIOHandle
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: UDP���Ĵ�����.
��ʼʱ��: 2009-1-20
�޸�ʱ��: 2009-2-5 (����޸�)
��    ��: ����UDP��ͷ��Ϣ,������,��ϰ�.CRC�ӽ���;
          ������ʹ��ɢ�мӵ�����;
          ����֪ͨ��ʽ��ʹ���߳�֪ͨ
          �ṩ���ͻ��˷���ͬ�����첽�����.������ʹ���첽��������
���õ�Ԫ:
          uDataNotifyQueues:
            ����ģʽ: TSimpleNotify
            ���ģʽ: TMulitNotify

UDP ��ͷ(TUdpHeader)����
�ֽ�˳��	       ����	           ˵��
0	         UDPЭ��汾	    �����Ժ�����Э��
1	         ��������	        1:��Ϊ������. <= 0: ����. > 1: ���
2	         �˰������	     >=0
3	         �Ƿ�Ϊͬ����     1: �첽 asynchronism, 0: ͬ�� synchronization
4,5        ��ˮ��	         �����������ģʽ, ͬһ������ˮ������ͬ��
6,7 	     UDP������	       �����ݰ�����
8~11       �û�ID	          �ͻ��˵�Ψһ��ʶ
12~15	     UDP���ݵ�CRC	   Ҫ��������(ԭUDP������)��CRC32��
16~20      ʱ���           ��¼�˰����ɵ�ʱ���־,�����ͬ����.�˱�־���뷵�� 

ͬ�������ص�:
    �ظ�����ˮ�ź�ʱ�����ͬ
}

unit uUdpIOHandle;

interface
uses uBasicUDP, uQueues, Winsock2, Windows, SysUtils, Encrypt, uDataNotifyQueues, Classes, uConversion;

const
  CtUdpHeaderLength = 20;
  CtUdpDataLength = 1280;
  CtUdpPackageSize = CtUdpHeaderLength + CtUdpDataLength;
  CtMaxCombinationCount = 8; //�����Ҫ���,��ְ��������Ϊ CtMaxCombinationCount ��

type
  //��ͷ CtUdpHeaderLength
  pUdpHeader = ^TUdpHeader;
  TUdpHeader = packed record
    case Boolean of
      True:
      (
        FUdpHead: array[0..CtUdpHeaderLength - 1] of Byte;
      );
      False:
      (
        FUdpVer: Byte;         //UDPЭ��汾��
        FBagCount: Byte;       //���ĸ���,����Ƕ�����,��Ϊ 1; >1: ��ϰ�; ����: ����
        FBagSerial: Byte;      //�������.�� 0 ��ʼ;
        FIsAsynch: Byte;       //ͬ�����첽�� 1: �첽; 0: ͬ��
        FSerialNum: Word;      //��ˮ��
        FPackageSize: Word;    //UDP������ĳ���  Header + Data
        FUserID: Cardinal;     //�û�ID; ID �� 1000 ��ʼ
        FCrc32Code: Cardinal;  //UDP���ݵ�CRC32��
        FTimeStamp: Cardinal;  //ʱ���; ͬ��: ���ط��͹�����ʱ���; ���򴴽��µ�ʱ���
      );
  end;

  //UDP�����
  pUdpPackage = ^TUdpPackage;
  TUdpPackage = record
    case Boolean of
      True:
      (
        FUdpPackageContent: array[0..CtUdpPackageSize - 1] of Byte;
      );
      False:
      (
        FUdpHeader: TUdpHeader;
        FUdpData: array[0..CtUdpDataLength - 1] of Byte;
      );
  end;

  //UDP��ȫ����Ϣ
  pUdpPackageInfo = ^TUdpPackageInfo;
  TUdpPackageInfo = record
    FSockIp: Cardinal;
    FSockPort: Word;
    FUdpLength: Word;   //���յ������ݳ���, ������ͷ��
    FUdpPackage: TUdpPackage;
  end;

  //���յ�����
  pRecvInfo = ^TRecvInfo;
  TRecvInfo = record
     FIP: Cardinal;
     FPort: Word;
     FIsAsynch: Byte;
     FSerialNum: Word;
     FUserID: Cardinal;
     FTimeStamp: Cardinal;
     FBufferLength: Cardinal;
     FBuffer: Pointer;
  end;

  {$M+}
  TUdpIOHandle = class(TBasicUDP)
  private
    FMaxUdpPackageCount: Word;
    FUdpPackageMem: TStaticMemoryManager;
    FSingleQueue: TSimpleNotify; //�˶��еİ��ѱ�ȷ��ÿһ�����Ƕ�����,������
    FMulitQueue: TMulitNotify;  //�˶��еİ���Ҫ�ɶ�������

    FSpThreadCount: Word;
    FSpMaxNodeCount: Cardinal;
    FSpQuerySpaceTime: Cardinal;
    FMtHashTableCount: Cardinal;
    FMtMaxHashNodeCount: Cardinal;
    FMtThreadCount: Word;
    FMtQuerySpaceTime: Cardinal;
    FMtCheckThread: Boolean;
    FMtMaxWaitTime: Cardinal;
    FMtCheckSpaceTime: Cardinal;
    FMtEnable: Boolean;


    procedure InitStatVar; //��ʼ��ͳ�Ʊ���
    procedure HandlePackage(const AlpUdpPackage: pUdpPackageInfo);
    procedure FreeUdpPackage(const p: pUdpPackageInfo); inline;

    procedure SetMaxUdpPageCount(const Value: Word);
    procedure SetSinglePackageThreadCount(const Value: Word);
    procedure SetSpMaxNodeCount(const Value: Cardinal);
    procedure SetSpQuerySpaceTime(const Value: Cardinal);
    procedure SetMtHashTableCount(const Value: Cardinal);
    procedure SetMtMaxHashNodeCount(const Value: Cardinal);
    procedure SetMtThreadCount(const Value: Word);
    procedure SetMtQuerySpaceTime(const Value: Cardinal);
    procedure SetMtCheckThread(const Value: Boolean);
    procedure SetMtMaxWaitTime(const Value: Cardinal);
    procedure SetMtCheckSpaceTime(const Value: Cardinal);
    procedure SetMtEnable(const Value: Boolean);
  protected
    //ͳ������
    FRecvUdpPackageErrorCount: Integer;
    FShortagePackageCount: Integer;
    FErrorPackageCount: Integer;
    FTotalPackageCount: Integer;
    
    FUserID: Cardinal;  //�û�ID, ���������
    FCurSerialNum: Word;
    FSerialNumLock: TRTLCriticalSection;
    function  GetSerialNum: Word; virtual; //������ˮ��, ���������ʵ��
    procedure ReclaimErrorPackageMem(const AlpUdpPackage: pUdpPackageInfo; const strErrorInfo: PAnsiChar);

    function  _SendBuffer(AIP: Cardinal; AHostShortPort: word; var ABuffer; const ABufferLen: Integer;
                          const AIsAsynch: Boolean; const ASerialNum: Word; const ATimeStamp: Cardinal): Integer;

    procedure DoRecvBuffer; override;   //���̵߳���
    function  DoBeforOpenUDP: Boolean; override;  //��ʼ��UDPǰ; True: �����ʼ��; False: �������ʼ��
    procedure DoAfterCloseUDP; override; //UDP�ر�֮��

    //���ݰ��������
    procedure DoHandleSinglPackage(Sender: TObject; ANotifyPointer: Pointer); virtual;//����ÿһ��������UDP��
    function  DoMultiPackageHandleOK(Sender: TObject; const ADataArray: array of Pointer; ALen: Integer): Boolean; virtual;//������������
    function  DoMultiPackageHandleFail(Sender: TObject; const ADataArray: array of Pointer; ALen: Integer): Boolean; virtual;//�������ʧ��

    procedure OnRecvBuffer(ARecvInfo: TRecvInfo); virtual;
  public
    constructor Create; override;
    destructor Destroy; override;

    //����
    function  SendBuffer(const AIP: Cardinal; AHostShortPort: word; var ABuffer; const ABufferLen: Integer;
                         const AIsAsynch: Boolean; ASerialNum: Word = 0; ATimeStamp: Cardinal = 0): Integer;
    //�첽����
    function  SendBufferByAnsy(const AIP: Cardinal; AHostShortPort: word; ABuffer: Pointer; const ABufferLen: Integer;
                               ASerialNum: Word = 0): Integer; inline;
    //ͬ������
    function  SendBufferBySync(const AIP: Cardinal; AHostShortPort: word; ABuffer: Pointer; const ABufferLen: Integer;
                               ASerialNum: Word = 0; ATimeStamp: Cardinal = 0): Integer; inline;
  published
    property MaxUdpPackageCount: Word read FMaxUdpPackageCount write SetMaxUdpPageCount default 512; //�������UDP����

    //������ʹ�ö����������
    property SinglePackageThreadCount: Word read FSpThreadCount write SetSinglePackageThreadCount; //�����������߳���; 0: ʹ��ʱ��
    property SinglePackageMaxNodeCount: Cardinal read FSpMaxNodeCount write SetSpMaxNodeCount; //���нڵ���
    property SinglePackageQuerySpaceTime: Cardinal read FSpQuerySpaceTime write SetSpQuerySpaceTime; //��ѯ���ʱ��
    //��ϰ�ʹ�ö��в���
    property MulitPackageEnable: Boolean read FMtEnable write SetMtEnable; //�Ƿ�֧�ֶ��
    property MulitPackageHashTableCount: Cardinal read FMtHashTableCount write SetMtHashTableCount; //HASHͰ����
    property MulitPackageMaxHashNodeCount: Cardinal read FMtMaxHashNodeCount write SetMtMaxHashNodeCount; //���Hash�����
    property MulitPackageThreadCount: Word read FMtThreadCount write SetMtThreadCount; //���������֪ͨ�߳��� 0: ʹ��ʱ��; > 0: ʹ���߳�
    property MulitPackageQuerySpaceTime: Cardinal read FMtQuerySpaceTime write SetMtQuerySpaceTime;//֪ͨ�ⲿ�̲߳�ѯʱ��
    property MulitPackageCheckThread: Boolean read FMtCheckThread write SetMtCheckThread;
    property MulitPackageCheckSpaceTime: Cardinal read FMtCheckSpaceTime write SetMtCheckSpaceTime; //����̼߳��ʱ��
    property MulitPackageMaxWaitTime: Cardinal read FMtMaxWaitTime write SetMtMaxWaitTime; //����еķְ��ʱ����
    //����ͳ��
    property TotalPackageCount: Integer read FTotalPackageCount;                //��������
    property RecvUdpPackageErrorCount: Integer read FRecvUdpPackageErrorCount;  //�������ݰ�ʧ�ܼ�¼
    property ShortagePackageCount: Integer read FShortagePackageCount;           //�����ڴ治��������İ�������
    property ErrorPackageCount: Integer read FErrorPackageCount;                 //���ڰ����������붪��������
  end;
  {$M-}

procedure FreeObject(var obj);

implementation

const
  CtCurVer = 1; //��ǰ�汾��
  CtUdpInfoSize = SizeOf(TUdpPackageInfo);
  CtErrorVer = 'Э����ʹ�ð汾�Ų���ȷ,�����Ӧ�ó���!';

{ TUdpIOHandle }

constructor TUdpIOHandle.Create;
begin
  inherited;
  FMaxUdpPackageCount := 512;
  FUdpPackageMem := nil;

  FUserID := 0;
  FCurSerialNum := 0;

  FSingleQueue := nil;
  FSpThreadCount := 1;
  FSpMaxNodeCount := 128;
  FSpQuerySpaceTime := 300;

  FMulitQueue := nil;
  FMtEnable := True;
  FMtHashTableCount := 1024 * 4;
  FMtMaxHashNodeCount := 64;
  FMtThreadCount := 1;
  FMtQuerySpaceTime := 300;
  FMtCheckThread := True;
  FMtMaxWaitTime := 5 * 1000;
  FMtCheckSpaceTime := 3 * 1000;

  InitStatVar;
  InitializeCriticalSection( FSerialNumLock );
end;

destructor TUdpIOHandle.Destroy;
begin
  DeleteCriticalSection( FSerialNumLock );
  inherited;
end;

function TUdpIOHandle.DoBeforOpenUDP: Boolean;
begin
  InitStatVar;
  //UDP����
  FUdpPackageMem := TStaticMemoryManager.Create( CtUdpInfoSize, MaxUdpPackageCount );
  //������ʹ�ö���
  FSingleQueue := TSimpleNotify.Create;
  with FSingleQueue do
  begin
    MaxNodeCount := SinglePackageMaxNodeCount;
    OnSimpleNotifyEvent := DoHandleSinglPackage;
    ThreadCount := SinglePackageThreadCount;
    SpaceTime := SinglePackageQuerySpaceTime;
    Active := True;
  end;

  //������ʹ�ö���
//  MulitPackageCheckThread := False;
  if MulitPackageEnable then
  begin
    FMulitQueue := TMulitNotify.Create;
    with FMulitQueue do
    begin
      HashTableCount := MulitPackageHashTableCount;
      MaxHashNodeCount := MulitPackageMaxHashNodeCount;
      PeenDataMaxCount := CtMaxCombinationCount;
      NotifyThreadCount := MulitPackageThreadCount;
      NotifyThreadSpaceTime := MulitPackageQuerySpaceTime;
      CheckThread := MulitPackageCheckThread;
      MaxWaitTime := MulitPackageMaxWaitTime;
      CheckSpaceTime := MulitPackageCheckSpaceTime;
      OnNotifyHandleOK := DoMultiPackageHandleOK;
      OnNotifyHandleFail := DoMultiPackageHandleFail;
      Active := True;
    end;
  end;
  Result := True;
end;

procedure TUdpIOHandle.DoAfterCloseUDP;
begin
  inherited;
  FreeObject( FUdpPackageMem );
  FreeObject( FSingleQueue );
  FreeObject( FMulitQueue );
end;

procedure TUdpIOHandle.DoHandleSinglPackage(Sender: TObject; ANotifyPointer: Pointer);
var
  p: pUdpPackageInfo;
  RecvInfo: TRecvInfo;
begin
  p := ANotifyPointer;
  try
    RecvInfo.FIP := p^.FSockIp;
    RecvInfo.FPort := p^.FSockPort;
    RecvInfo.FIsAsynch := p^.FUdpPackage.FUdpHeader.FIsAsynch;
    RecvInfo.FSerialNum := p^.FUdpPackage.FUdpHeader.FSerialNum;
    RecvInfo.FUserID := p^.FUdpPackage.FUdpHeader.FUserID;
    RecvInfo.FTimeStamp := p^.FUdpPackage.FUdpHeader.FTimeStamp;
    RecvInfo.FBufferLength := p^.FUdpLength - CtUdpHeaderLength;
    RecvInfo.FBuffer := @p^.FUdpPackage.FUdpData;
    OnRecvBuffer( RecvInfo );
  finally
    FreeUdpPackage( p );
  end;
end;

function TUdpIOHandle.DoMultiPackageHandleFail(Sender: TObject; const ADataArray: array of Pointer; ALen: Integer): Boolean;
var
  i: Integer;
  p: pUdpPackageInfo;
begin
  for i := 0 to ALen - 1 do
  begin
    p := ADataArray[i];
    if p <> nil then
      ReclaimErrorPackageMem( p, PAnsiChar(Format('�ְ�����, IP: %d, Port: %d',[p^.FSockIp, p^.FSockPort] )) )
  end;
  Result := True;
end;

function TUdpIOHandle.DoMultiPackageHandleOK(Sender: TObject; const ADataArray: array of Pointer; ALen: Integer): Boolean;
var
  Buffer: array[0..CtUdpDataLength * CtMaxCombinationCount - 1] of Byte;
  i, nTmpLen, nTotalByteCount: Integer;
  p: pUdpPackageInfo;
  RecvInfo: TRecvInfo;
begin
  Result := True;
  nTotalByteCount := 0;

  p := ADataArray[0];
  RecvInfo.FIP := p^.FSockIp;
  RecvInfo.FPort := p^.FSockPort;
  RecvInfo.FIsAsynch := p^.FUdpPackage.FUdpHeader.FIsAsynch;
  RecvInfo.FSerialNum := p^.FUdpPackage.FUdpHeader.FSerialNum;
  RecvInfo.FUserID := p^.FUdpPackage.FUdpHeader.FUserID;
  RecvInfo.FTimeStamp := p^.FUdpPackage.FUdpHeader.FTimeStamp;

  for i := 0 to ALen - 1 do
  begin
    p := ADataArray[i];
    nTmpLen := p^.FUdpLength - CtUdpHeaderLength;
    Move( p^.FUdpPackage.FUdpData[0], Buffer[nTotalByteCount], nTmpLen );
    Inc( nTotalByteCount, nTmpLen );
    FreeUdpPackage( p );
  end;

  RecvInfo.FBufferLength := nTotalByteCount;
  RecvInfo.FBuffer := @Buffer;
  OnRecvBuffer( RecvInfo );
end;

procedure TUdpIOHandle.FreeUdpPackage(const p: pUdpPackageInfo);
begin
  FillChar( p^, CtUdpPackageSize, 0 ); //
  FUdpPackageMem.FreeMem( p )
end;

function TUdpIOHandle.GetSerialNum: Word;
begin
  EnterCriticalSection( FSerialNumLock );
  try
    FCurSerialNum := FCurSerialNum mod 65535 + 1;
  finally
    LeaveCriticalSection( FSerialNumLock );
  end;
  Result := FCurSerialNum;
end;

procedure TUdpIOHandle.DoRecvBuffer;
var
  lpBag: pUdpPackageInfo;
  UdpInfo: TUdpPackageInfo;
  Addr: TSockAddr;
  nLen: Integer;
begin
  InterlockedIncrement(FTotalPackageCount);
  if not __RecvBuffer(UdpInfo.FUdpPackage.FUdpPackageContent, nLen, Addr) then
  begin
    InterlockedIncrement( FRecvUdpPackageErrorCount );
    DoErrorInfo( PChar(Format('����UDP����Ϣ����: %d', [WSAGetLastError])) );
    Exit;
  end;
  if not FUdpPackageMem.GetMem( Pointer(lpBag) ) then
  begin
    InterlockedIncrement( FShortagePackageCount );
    DoErrorInfo( 'UDP������,�޷���ȡ�ڴ�,������UDP��' );
    Exit;
  end;
  lpBag^.FSockIp := Addr.sin_addr.S_addr;
  lpBag^.FSockPort := htons(Addr.sin_port);
  lpBag^.FUdpLength := nLen;
  Move( UdpInfo.FUdpPackage.FUdpPackageContent, lpBag^.FUdpPackage.FUdpPackageContent, nLen );
  HandlePackage( lpBag );
end;

procedure TUdpIOHandle.HandlePackage(const AlpUdpPackage: pUdpPackageInfo);
var
  pHeader: pUdpHeader;
  nDataLen, nMtResult: Integer;
begin
  pHeader := @AlpUdpPackage^.FUdpPackage.FUdpHeader;
  if pHeader^.FUdpVer <> CtCurVer then
  begin
    ReclaimErrorPackageMem( AlpUdpPackage, CtErrorVer );
    Exit;
  end;

  //�����: �����ж�
  if pHeader^.FPackageSize <> AlpUdpPackage^.FUdpLength then
  begin
    ReclaimErrorPackageMem( AlpUdpPackage, '����ʶ��������յ����Ȳ�һ��!' );
    Exit;
  end;
  //�����: CRC����
  nDataLen := AlpUdpPackage^.FUdpLength - CtUdpHeaderLength;
  if nDataLen <= 0 then
  begin
    FreeUdpPackage( AlpUdpPackage );
    Exit;
  end;
  if not DecodeBuffer( pHeader^.FCrc32Code, @AlpUdpPackage^.FUdpPackage.FUdpData, nDataLen ) then
  begin
    ReclaimErrorPackageMem( AlpUdpPackage, 'CRC32 ����ʧ��' );
    Exit;
  end;


  if 1 = pHeader^.FBagCount then //������
  begin
    if 0 <> pHeader^.FBagSerial then
    begin
      ReclaimErrorPackageMem( AlpUdpPackage, '����������Ų���ȷ!' );
      Exit;
    end;
    FSingleQueue.Add( AlpUdpPackage );
  end
  else if 1 < pHeader^.FBagCount then //��ϰ�
  begin
    if MulitPackageEnable then
    begin
      nMtResult := FMulitQueue.Add( pHeader^.FUserID, pHeader^.FSerialNum, pHeader^.FBagCount, pHeader^.FBagSerial, AlpUdpPackage );
      if nMtResult <> 0 then
      begin
        ReclaimErrorPackageMem( AlpUdpPackage, PAnsiChar(Format('�����������: %d', [nMtResult])) );
      end;
    end
    else
      ReclaimErrorPackageMem( AlpUdpPackage, '��֧����ϰ���ʽ��UDP����' );
  end
  else
  begin
    ReclaimErrorPackageMem( AlpUdpPackage, 'UDP��ͷ����' );
    Exit;
  end;
end;

procedure TUdpIOHandle.InitStatVar;
begin
  FRecvUdpPackageErrorCount := 0;
  FShortagePackageCount := 0;
  FErrorPackageCount := 0;
  FTotalPackageCount := 0;
end;

procedure TUdpIOHandle.OnRecvBuffer(ARecvInfo: TRecvInfo);
begin
//  OutputDebugString( Pchar( Format('�յ�������: %d', [ABufferLen])) );
//  OutputDebugString( PChar(@ABuffer) );
end;

procedure TUdpIOHandle.ReclaimErrorPackageMem(const AlpUdpPackage: pUdpPackageInfo; const strErrorInfo: PAnsiChar);
begin
  FreeUdpPackage( AlpUdpPackage );
  InterlockedIncrement( FErrorPackageCount );
  if strErrorInfo <> nil then
    DoErrorInfo( strErrorInfo );
end;

function TUdpIOHandle.SendBuffer(const AIP: Cardinal; AHostShortPort: word; var ABuffer; const ABufferLen: Integer;
  const AIsAsynch: Boolean; ASerialNum: Word; ATimeStamp: Cardinal): Integer;
begin
  if ASerialNum = 0 then
    ASerialNum := GetSerialNum;
  if ATimeStamp = 0 then
    ATimeStamp := GetTimeStamp;
  Result := _SendBuffer( AIP, AHostShortPort, ABuffer, ABufferLen, AIsAsynch, ASerialNum, ATimeStamp );
end;

function TUdpIOHandle.SendBufferByAnsy(const AIP: Cardinal; AHostShortPort: word; ABuffer: Pointer; const ABufferLen: Integer;
  ASerialNum: Word): Integer;
begin
  Result := SendBuffer( AIP, AHostShortPort, ABuffer, ABufferLen, True, ASerialNum, 0 );
end;

function TUdpIOHandle.SendBufferBySync(const AIP: Cardinal; AHostShortPort: word; ABuffer: Pointer; const ABufferLen: Integer;
  ASerialNum: Word; ATimeStamp: Cardinal): Integer;
begin
  Result := SendBuffer( AIP, AHostShortPort, ABuffer, ABufferLen, False, ASerialNum, ATimeStamp );
end;

procedure TUdpIOHandle.SetMaxUdpPageCount(const Value: Word);
begin
  if (not Active) and (FMaxUdpPackageCount <> Value) then
    FMaxUdpPackageCount := Value;
end;


procedure TUdpIOHandle.SetMtCheckSpaceTime(const Value: Cardinal);
begin
  if (not Active) and (FMtCheckSpaceTime <> Value) then
    FMtCheckSpaceTime := Value;
end;

procedure TUdpIOHandle.SetMtCheckThread(const Value: Boolean);
begin
  if (not Active) and (FMtCheckThread <> Value) then
    FMtCheckThread := Value;
end;

procedure TUdpIOHandle.SetMtEnable(const Value: Boolean);
begin
  if (not Active) and (FMtEnable <> Value) then
    FMtEnable := Value;
end;

procedure TUdpIOHandle.SetMtHashTableCount(const Value: Cardinal);
begin
  if (not Active) and (FMtHashTableCount <> Value) then
    FMtHashTableCount := Value;
end;

procedure TUdpIOHandle.SetMtMaxHashNodeCount(const Value: Cardinal);
begin
  if (not Active) and (FMtHashTableCount <> Value) then
    FMtMaxHashNodeCount := Value;
end;

procedure TUdpIOHandle.SetMtMaxWaitTime(const Value: Cardinal);
begin
  if (not Active) and (FMtMaxWaitTime <> Value) then
    FMtMaxWaitTime := Value;
end;

procedure TUdpIOHandle.SetMtQuerySpaceTime(const Value: Cardinal);
begin
  if (not Active) and (FMtQuerySpaceTime <> Value) then
    FMtQuerySpaceTime := Value;
end;

procedure TUdpIOHandle.SetMtThreadCount(const Value: Word);
begin
  if (not Active) and (FMtThreadCount <> Value) then
    FMtThreadCount := Value;
end;

procedure TUdpIOHandle.SetSinglePackageThreadCount(const Value: Word);
begin
  if (not Active) and (SinglePackageThreadCount <> Value) then
    FSpThreadCount := Value;
end;

procedure TUdpIOHandle.SetSpMaxNodeCount(const Value: Cardinal);
begin
  if (not Active) and (FSpMaxNodeCount <> Value) then
    FSpMaxNodeCount := Value;
end;

procedure TUdpIOHandle.SetSpQuerySpaceTime(const Value: Cardinal);
begin
  if (not Active) and (FSpQuerySpaceTime <> Value) then
    FSpQuerySpaceTime := Value;
end;

function TUdpIOHandle._SendBuffer(AIP: Cardinal; AHostShortPort: word; var ABuffer; const ABufferLen: Integer; const AIsAsynch: Boolean;
  const ASerialNum: Word; const ATimeStamp: Cardinal): Integer;
var
  UdpPackage: TUdpPackage;
  i, nBagCount: Byte;
  p: PAnsiChar;
  nLen: Integer;
begin
  Result := 0;
  if ABufferLen > CtUdpDataLength * CtMaxCombinationCount then
  begin
    DoErrorInfo( PChar( Format('�������ݲ��ܳ��� %d �ֽ�(%dK)', [CtUdpDataLength * CtMaxCombinationCount, ConverByte(CtUdpDataLength * CtMaxCombinationCount) ]) ) );
    Exit;
  end;

  nBagCount := ABufferLen div CtUdpDataLength + 1;
  if nBagCount > 1 then
  begin
    nLen := CtUdpDataLength;
  end
  else
  begin
    nLen := ABufferLen;
  end;

  FillChar( UdpPackage.FUdpPackageContent, CtUdpPackageSize, 0 );
  UdpPackage.FUdpHeader.FUserID := FUserID;
  with UdpPackage.FUdpHeader do
  begin
    FUdpVer := CtCurVer;
    FBagCount := nBagCount;
    FSerialNum := ASerialNum;
    FIsAsynch := Byte(AIsAsynch);
    FTimeStamp := ATimeStamp;
  end;

  p := PAnsiChar( ABuffer );
  for i := 0 to nBagCount - 1 do
  begin
    Move( p^, UdpPackage.FUdpData[0], nLen );
    UdpPackage.FUdpHeader.FPackageSize := nLen + CtUdpHeaderLength;
    UdpPackage.FUdpHeader.FBagSerial := i;
    UdpPackage.FUdpHeader.FCrc32Code := EncodeBuffer( @UdpPackage.FUdpData, nLen );
    Result := Result + __SendBuffer( AIP, AHostShortPort, UdpPackage.FUdpPackageContent, UdpPackage.FUdpHeader.FPackageSize ) - CtUdpHeaderLength;
    p := p + nLen;
    if i = (nBagCount - 2) then
      nLen := ABufferLen - CtUdpDataLength * (nBagCount - 1);
  end;
end;

procedure FreeObject(var obj);
var
  Temp: TObject;
begin
  Temp := TObject(Obj);
  if Assigned( Temp) then
  begin
    Pointer(Obj) := nil;
    Temp.Free;
  end;
end;

end.
