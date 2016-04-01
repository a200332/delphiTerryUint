unit JxdUDPServer;

interface

uses
  Windows, Messages, Winsock2, SysUtils, Classes, uQueues, JxdUDP,
  JxdCmdConst, JxdEncrypt, Forms, JxdTypes, uCmdStream, JxdProxy;

const
  ServerMaxSerialID = 999999;

type

  TJxdUDPServer = class;

  TPPUDPServerOldReadEvent = procedure(Sender: TObject; ABuffer: PChar; ABufferLength: Integer;
    APeerIP: TInAddr; APeerPort: WORD;const ALSH:string; var AReturnText: string) of object;

  TPPUDPServerNewReadEvent = procedure(Sender: TObject; ABuffer: PChar; ABufferLength: Integer;
    APeerIP: TInAddr; APeerPort: WORD;const AGUID: TPPGUID; AReturnBuffer: PChar; var AReturnLength: Integer) of object;

  TPPUDPServerFTPDataEvent = procedure(Sender: TObject; ABuffer: PChar; ABufferLength: Integer;
    APeerIP: TInAddr; APeerPort: WORD) of object;

  TPPUDPServerErrorEvent = procedure(Sender: TObject; const AErrorMessage: string) of object;


  TPPUDPServerWorkThread = class(TThread)
  private
    FOwner: TJxdUDPServer;
    FCmdStream: TCmdStream;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TJxdUDPServer);
    destructor Destroy; override;
    property CmdStream: TCmdStream read FCmdStream;
  end;

  TJxdUDPServer = class(TComponent)
  private
    FActive: Boolean;
    FAutoIncPort: Boolean;
    FDefaultPort: WORD;
    FPPUDP: TJxdUDP;
    FBufferQueue: TPointerQueue;
    FMemoryManager: TStaticMemoryManager;
    FWorkThread: array of TPPUDPServerWorkThread;
    FWorkThreadCount: Integer;
    FActiveThreadCount: Integer;
    FMaxBufferCount: Integer;

    FSerialID: Integer;
    FUserID: DWORD;
    FSendBytes: Cardinal;
    FRecvBytes: Cardinal;
    //--���������ܵ��ϴ��������ٶ�
    FLastTick: Cardinal;
    FLastRecv: Integer;
    FLastSend: Integer;
    FSendSpeed: Integer;
    FRecvSpeed: Integer;
    FDropPackCount: Cardinal;

    FReplyList: array[1..ServerMaxSerialID] of TReplyData;
    FReplyLock: TRTLCriticalSection;
    FProxySettings: TProxySettings;

    FEditUDPRecvBagLock: TRTLCriticalSection;
    FUDPBagRecvList: TList;
    //-------------�¼�-------------
    FOnPPUDPServerOldExecute: TPPUDPServerOldReadEvent;
    FOnPPUDPServerNewExecute: TPPUDPServerNewReadEvent;
    FOnPPUDPServerOldFTPDate: TPPUDPServerFTPDataEvent;
    FOnPPUDPServerNewFTPDate: TPPUDPServerFTPDataEvent;
    FOnPPUDPServerError: TPPUDPServerErrorEvent;

    //------------------------------
    function CheckRecvFinish(AGUID: TPPGUID; var AMsg: string;
      ATotalPart, ACurrPart: Integer): Boolean;

    procedure SetProxySettings(const Value: TProxySettings);
    procedure PPUDPRead(Sender: TObject;const PeerInfo: TPeerAddr);
    procedure PPUDPError(Sender: TObject; const AErrorMessage: string);

    function GetFreeQueueCount: Integer;
    function GetBufferQueueCount: Integer;//�ȴ����� ��
    procedure SetWorkThreadCount(const Value: Integer);
    procedure SetDefaultPort(const Value: Word);
    procedure SetActive(const Value: Boolean);
    procedure OpenUDPServer;
    procedure CloseUDPServer;
    procedure WorkThreadExecute(Sender: TObject);
    procedure UDPServerExecute(Sender: TObject; ABuffer: PChar; ABufferLength: Integer;
      APeerIP: TInAddr; APeerPort: WORD);
    function NewSendWait(AHost: TInAddr; APort: WORD; ABuffer: PChar; ABufferLength: Integer;
      AReplyBuffer: PChar; var AReplyLength: Integer; ALSH: Int64 = 0; ATimeout: Integer = 2000; AEncrypt: Boolean = False): Boolean;
    function OldSendWait(AHost: TInAddr; APort: WORD; ABuffer: PChar; ABufferLength: Integer;
      AReplyBuffer: PChar; var AReplyLength: Integer; ALSH: string = ''; ATimeout: Integer = 2000; AEncrypt: Boolean = False): Boolean;
  protected
    procedure DoUDPServerNewRead(Sender: TObject; ABuffer: PChar;var ABufferLength: Integer;
      ATotalPart, ACurrPart: Byte; APeerIP: TInAddr; APeerPort: WORD; AGUID: TPPGUID);
    procedure DoUDPServerOldRead(Sender: TObject; ABuffer: PChar;var ABufferLength: Integer;
      ATotalPart, ACurrPart: Byte; APeerIP: TInAddr; APeerPort: WORD;const AGUID: TPPGUID);
    procedure DoUDPServerNewFTPData(Sender: TObject; ABuffer: PChar; ABufferLength: Integer;
      APeerIP: TInAddr; APeerPort: WORD);
    procedure DoUDPServerOldFTPData(Sender: TObject; ABuffer: PChar; ABufferLength: Integer;
      APeerIP: TInAddr; APeerPort: WORD);
    procedure DoUDPServerError(const AErrorMessage: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function TestProxy(const AHost:string;APort:Word;const AUserName:string;const AUserPass:string):Boolean;
    function SendBuffer(AHost: TInAddr; APort: WORD;var ABuffer; ABufferLength: Integer): Boolean; overload;
    function SendBuffer(AHost: string; APort: WORD;var ABuffer; ABufferLength: Integer): Boolean; overload;
    //--------------�ⲿ���õ�������Э�����ݷ��ͺ���
    function NewSend(AHost: TInAddr; APort: WORD; ABuffer: PChar; ABufferLength: Integer; ALSH: Int64 = 0): Boolean; overload;
    function NewSend(AHost: TInAddr; APort: WORD; ABuffer: PChar; ABufferLength: Integer;
      AReplyBuffer: PChar; var AReplyLength: Integer; ALSH: Int64 = 0; ATimeout: Integer = 2000): Boolean; overload;
    //--------------�ⲿ���õ�������Э�����ݷ��ͺ���
    function OldSend(AHost: TInAddr; APort: WORD; ABuffer: PChar; ABufferLength: Integer;
      ALSH: string = ''; AEncrypt: Boolean = False): Boolean; overload;
    function OldSend(AHost: TInAddr; APort: WORD; ABuffer: PChar; ABufferLength: Integer;
      AReplyBuffer: PChar; var AReplyLength: Integer; ALSH: string = ''; ATimeout: Integer = 2000; AEncrypt: Boolean = False): Boolean; overload;
    //------------------
    property BufferQueueCount: Integer read GetBufferQueueCount;
    property FreeQueueCount: Integer read GetFreeQueueCount;
    property ActiveThreadCount: Integer read FActiveThreadCount;
    property SendBytes: Cardinal read FSendBytes write FSendBytes;
    property RecvBytes: Cardinal read FRecvBytes write FRecvBytes;
    property SendSpeed: Integer read FSendSpeed;
    property RecvSpeed: Integer read FRecvSpeed;
    property DropPackCount:Cardinal read FDropPackCount write FDropPackCount;
    property OnPPUDPServerNewFTPDate: TPPUDPServerFTPDataEvent read FOnPPUDPServerNewFTPDate write FOnPPUDPServerNewFTPDate;

    property PPUDP:TJxdUDP read FPPUDP write FPPUDP;
  published
    property UserID: Cardinal read FUserID write FUserID default 888888888;
    property Active: Boolean read FActive write SetActive default False;
    property AutoIncPort:Boolean read FAutoIncPort write FAutoIncPort default False;
    property ProxySettings: TProxySettings read FProxySettings write SetProxySettings;
    property DefaultPort: Word read FDefaultPort write SetDefaultPort default 10000;
    property MaxBufferCount: Integer read FMaxBufferCount write FMaxBufferCount default 4096;
    property WorkThreadCount: Integer read FWorkThreadCount write SetWorkThreadCount default 100;

    property OnPPUDPServerOldExecute: TPPUDPServerOldReadEvent read FOnPPUDPServerOldExecute write FOnPPUDPServerOldExecute;
    property OnPPUDPServerNewExecute: TPPUDPServerNewReadEvent read FOnPPUDPServerNewExecute write FOnPPUDPServerNewExecute;
    property OnPPUDPServerOldFTPDate: TPPUDPServerFTPDataEvent read FOnPPUDPServerOldFTPDate write FOnPPUDPServerOldFTPDate;
    property OnPPUDPServerError: TPPUDPServerErrorEvent read FOnPPUDPServerError write FOnPPUDPServerError;
  end;

  function GetNewLSH(AUserID: Integer; var ASerialID: Integer): Int64;



implementation

var
  GLSH: Integer = 1;

function GetOldLSH(AUserID: Integer; var ASerialID: Integer): string;
var
  I: DWORD;
begin
  I := InterlockedIncrement(GLSH) - 1;
  SetLength(Result, 8);
  PInteger(@Result[1])^ := AUserID;
  ASerialID := I mod (ServerMaxSerialID+1); //1-9999��ˮ��
  PInteger(@Result[5])^ := ASerialID;
end;

function GetOldLSHEx(AUserID: Integer; ASerialID: Integer): string;
begin
  SetLength(Result, 8);
  PInteger(@Result[1])^ := AUserID;
  PInteger(@Result[5])^ := ASerialID;
end;

function GetOldSerialID(const ALSH: string): Integer;
begin
  Result := -1;
  if Length(ALSH) <> 8 then
    Exit;
  Result := PInteger(@ALSH[5])^;
end;

function GetNewLSH(AUserID: Integer; var ASerialID: Integer): Int64;
var
  I: DWORD;
  LI: TULargeInteger;
begin
  I := InterlockedIncrement(GLSH) - 1;
  LI.LowPart := AUserID;
  LI.HighPart := I mod (ServerMaxSerialID+1);
  ASerialID := LI.HighPart;
  Result := LI.QuadPart;
end;

function GetNewSerialID(ALSH: Int64): Integer;
var
  LI: TULargeInteger;
begin
  LI.QuadPart := ALSH;
  Result := LI.LowPart;
end;

function AddFourHead(str: string): string;
begin
  Result := '0000' + str;
  PInteger(@Result[1])^ := Length(str);
end;

{ TPPUDPServerWorkThread }

constructor TPPUDPServerWorkThread.Create(AOwner: TJxdUDPServer);
begin
  FOwner := AOwner;
  FCmdStream := TCmdStream.Create;
  inherited Create(False);
end;

destructor TPPUDPServerWorkThread.Destroy;
begin
  FCmdStream.Free;
  inherited;
end;

procedure TPPUDPServerWorkThread.Execute;
begin
  inherited;
  while not Terminated do
  begin
    try
      FOwner.WorkThreadExecute(Self);
    except
      on E: Exception do
        FOwner.DoUDPServerError('TWorkThread.Execute');
    end;
  end;
end;

{ TPPUDPServer }

procedure TJxdUDPServer.CloseUDPServer;
var
  I: Integer;
  AUDPBag: TJxdUDPBag;
begin
  if not FActive then
    Exit;
  FActive := False;
  try
    //1,�رչ����߳�
    for I := 0 to FWorkThreadCount - 1 do //�ȹرմ����߳�
      FWorkThread[I].Terminate;
    SetLength(FWorkThread, 0);
    //2,�ر�UDP   
    FPPUDP.OnUDPRead := nil;
    FPPUDP.Active := False;
    FreeAndNil(FPPUDP);
    //3,�����������ݽṹ
    FreeAndNil(FBufferQueue);
    FreeAndNil(FMemoryManager);
    for i := FUDPBagRecvList.Count - 1 downto 0  do
    begin
      AUDPBag := TJxdUDPBag(FUDPBagRecvList.Items[i]);
      if AUDPBag <> nil then
        AUDPBag.Free;
    end;
    FreeAndNil(FUDPBagRecvList);
  except
    on E: Exception do
      DoUDPServerError(Format(SException, ['TPPUDPServer.CloseUDPServer',
        E.ClassName, E.Message]));
  end;
  FSendSpeed := 0;
  FRecvSpeed := 0;
end;

constructor TJxdUDPServer.Create(AOwner: TComponent);
begin
  inherited;
  FAutoIncPort := False;

  FUserID := 888888888;
  FMaxBufferCount := 4096;
  FDefaultPort := 10000;

  FSerialID := 0;
  FSendBytes := 0;
  FRecvBytes := 0;
  FActive := False;
  FWorkThreadCount := 100;
  FProxySettings := TProxySettings.Create;
  InitializeCriticalSection(FReplyLock);
  InitializeCriticalSection(FEditUDPRecvBagLock);
end;

destructor TJxdUDPServer.Destroy;
begin
  CloseUDPServer;
  FProxySettings.Free;
  DeleteCriticalSection(FReplyLock);
  DeleteCriticalSection(FEditUDPRecvBagLock);
  inherited;
end;

procedure TJxdUDPServer.DoUDPServerError(const AErrorMessage: string);
begin
  if Assigned(FOnPPUDPServerError) then
    FOnPPUDPServerError(Self, AErrorMessage);
end;

procedure TJxdUDPServer.DoUDPServerNewFTPData(Sender: TObject; ABuffer: PChar;
  ABufferLength: Integer; APeerIP: TInAddr; APeerPort: WORD);
begin
  if Assigned(FOnPPUDPServerNewFTPDate) then
  try
    FOnPPUDPServerNewFTPDate(Sender, ABuffer, ABufferLength, APeerIP, APeerPort);
  except
    on E: Exception do
      DoUDPServerError(Format(SException, ['DoUDPServerNewFTPData',
        E.ClassName, E.Message]));
  end;
end;

procedure TJxdUDPServer.DoUDPServerOldFTPData(Sender: TObject; ABuffer: PChar;
  ABufferLength: Integer; APeerIP: TInAddr; APeerPort: WORD);
begin
  if Assigned(FOnPPUDPServerOldFTPDate) then
  try
    FOnPPUDPServerOldFTPDate(Sender, ABuffer, ABufferLength, APeerIP, APeerPort);
  except
    on E: Exception do
      DoUDPServerError(Format(SException, ['DoUDPServerOldFTPData',
        E.ClassName, E.Message]));
  end;
end;

function TJxdUDPServer.CheckRecvFinish(AGUID: TPPGUID; var AMsg: string;
  ATotalPart, ACurrPart: Integer): Boolean;
var
  bFind: Boolean;
  i: Integer;
  APPUDPBag: TJxdUDPBag;
begin
  bFind := False;
  Result := False;
  EnterCriticalSection(FEditUDPRecvBagLock);
  try
    for i := FUDPBagRecvList.Count - 1 downto 0 do
    begin
      APPUDPBag := TJxdUDPBag(FUDPBagRecvList[i]);
      if (GetTickCount - APPUDPBag.LastRecvTime) > 20000 then //����20s�ģ���Ϊ��ʱ
      begin
        FUDPBagRecvList.Delete(i);
        FreeAndNil(APPUDPBag);
        Continue;
      end;
      if APPUDPBag.NewLSH = AGUID.GUID then
      begin
        bFind := True;
        APPUDPBag.LastRecvTime := GetTickCount;
        APPUDPBag.RecvABag(AMsg, ACurrPart);
        if APPUDPBag.RecvFinish then
        begin
          AMsg := APPUDPBag.RecvText;
          FUDPBagRecvList.Delete(i);
          FreeAndNil(APPUDPBag);
          Result := True;
          Break;
        end
        else begin //��û�������,�ȴ���һ�ν���
          Exit;
        end;
      end;
    end; //end for
    if not bFind then
    begin //û�ҵ�,������һ����ȥ
      APPUDPBag := TJxdUDPBag.Create(ATotalPart);
      APPUDPBag.LastRecvTime := GetTickCount;
      APPUDPBag.NewLSH := AGUID.GUID;
      APPUDPBag.RecvABag(AMsg, ACurrPart);
      FUDPBagRecvList.Add(APPUDPBag);
    end;
  finally
    LeaveCriticalSection(FEditUDPRecvBagLock);
  end;
end;

procedure TJxdUDPServer.DoUDPServerNewRead(Sender: TObject; ABuffer: PChar;
  var ABufferLength: Integer; ATotalPart, ACurrPart: Byte;
  APeerIP: TInAddr; APeerPort: WORD; AGUID: TPPGUID);
var
  ReplyLength: Integer;
  ReplyBuffer: array[0..32 * UDPMTU - 1] of Char; //�����32K������
  Msg: string;
begin    //ABuffer�Ѿ������յİ�������
  ReplyLength := 0;
  if ATotalPart > 1 then
  begin //�Ƿ������һ�������İ�
    SetString(Msg, ABuffer, ABufferLength);
    if not CheckRecvFinish(AGUID, Msg, ATotalPart, ACurrPart) then
      Exit;
    ABufferLength := Length(Msg);
    Move(Msg[1],ABuffer^,ABufferLength);
    Msg := '';
  end;
  if (AGUID.UserID = FUserID) and (AGUID.UserID <> 999999996) then
  begin //���Ƿ�Ϊ�Լ��ȴ�����Ϣ
    if (AGUID.SerialID >= 1) and (AGUID.SerialID <= ServerMaxSerialID) then
    begin
      EnterCriticalSection(FReplyLock);
      try
        if FReplyList[AGUID.SerialID].Buffer <> nil then
        begin
          Move(ABuffer^, FReplyList[AGUID.SerialID].Buffer^, ABufferLength);
          FReplyList[AGUID.SerialID].BufferLength := ABufferLength;
        end;
      finally
        LeaveCriticalSection(FReplyLock);
      end;
    end;
  end
  else
  begin
    if Assigned(FOnPPUDPServerNewExecute) then
    try
      FOnPPUDPServerNewExecute(Sender, ABuffer, ABufferLength, APeerIP, APeerPort,AGUID, @ReplyBuffer, ReplyLength);
    except
      on E: Exception do
        DoUDPServerError('DoUDPServerNewRead');
    end;
    if ReplyLength > 0 then
    try
      NewSend(APeerIP, APeerPort, @ReplyBuffer, ReplyLength, AGUID.GUID);
    except
      on E: Exception do
        DoUDPServerError('NewSend');
    end;
  end;
end;

procedure TJxdUDPServer.DoUDPServerOldRead(Sender: TObject; ABuffer: PChar;
  var ABufferLength: Integer; ATotalPart, ACurrPart: Byte; APeerIP: TInAddr;
  APeerPort: WORD;const AGUID: TPPGUID);
var
  ReturnText: string;
  alen: Integer;
  Msg:String;
  aSerialID:Integer;
  aUserID:Integer;
  aLSH:string;
begin  //ABuffer�Ѿ������յİ�������
  ReturnText := '';
  if ATotalPart > 1 then
  begin //�Ƿ������һ�������İ�
    SetString(Msg, ABuffer, ABufferLength);
    if not CheckRecvFinish(AGUID, Msg, ATotalPart, ACurrPart) then
      Exit;
    ABufferLength := Length(Msg);
    Move(Msg[1],ABuffer^,ABufferLength);
    Msg := '';
  end;
  aUserID := AGUID.UserID;
  aSerialID := AGUID.SerialID;
  if Cardinal(aUserID) = FUserID then
  begin //���Ƿ�Ϊ�Լ��ȴ�����Ϣ
    if (aSerialID >= 1) and (aSerialID <= ServerMaxSerialID) then
    begin
      EnterCriticalSection(FReplyLock);
      try
        if FReplyList[aSerialID].Buffer <> nil then
        begin
          Move(ABuffer^, FReplyList[aSerialID].Buffer^, ABufferLength);
          FReplyList[aSerialID].BufferLength := ABufferLength;
        end;
      finally
        LeaveCriticalSection(FReplyLock);
      end;
    end;
  end
  else
  begin
    aLSH:= GetOldLSHEx(aUserID, aSerialID);
    if Assigned(FOnPPUDPServerOldExecute) then
    try
      FOnPPUDPServerOldExecute(Sender, ABuffer, ABufferLength, APeerIP, APeerPort,aLSH, ReturnText);
    except
      on E: Exception do
      begin
        DoUDPServerError('DoUDPServerOldRead');
        Exit;
      end;
    end;
    if ReturnText <> '' then
    try
      alen := Length(ReturnText);
      OldSend(APeerIP, APeerPort, @ReturnText[1], alen, aLSH);
    except
      on E: Exception do
        DoUDPServerError('DoUDPServerOldRead');
    end;
  end;
end;

function TJxdUDPServer.GetBufferQueueCount: Integer;
begin
  Result := FBufferQueue.Count;
end;

function TJxdUDPServer.GetFreeQueueCount: Integer;
begin
  Result := FMemoryManager.FreeSpace;
end;

function TJxdUDPServer.NewSend(AHost: TInAddr; APort: WORD; ABuffer: PChar;
  ABufferLength: Integer; AReplyBuffer: PChar; var AReplyLength: Integer;
  ALSH: Int64; ATimeout: Integer): Boolean;
begin
  Result := NewSendWait(AHost, APort, ABuffer, ABufferLength, AReplyBuffer, AReplyLength,
    ALSH, ATimeout);
end;

function TJxdUDPServer.NewSend(AHost: TInAddr; APort: WORD; ABuffer: PChar;
  ABufferLength: Integer; ALSH: Int64): Boolean;
var
  MTU: Integer;
  Buf: array[0..UDPMTU - 1] of Byte;
  P: PChar;
  CRCCode: WORD;
  I: Integer;
  BlockCount: Integer;
  Offset: Integer;
  Size: Integer;
  SerialID: Integer;
begin
  Result := False;
  if not FActive or (ABuffer = nil) or (ABufferLength < 1) then
    Exit;
  MTU := UDPMTU - 13; //13���ֽڵ�ͷ
  if ALSH = 0 then
    ALSH := GetNewLSH(FUserID, SerialID);
  if ABufferLength <= MTU then
  begin //����������ͷ�Ժ�ֱ�ӷ���
    P := @Buf;
    P[0] := Chr(CNewProtocolFlag); //Э��汾
    PInt64(@P[3])^ := ALSH; //��ˮ����
    P[11] := #1; //�����ܸ���
    P[12] := #1; //�������
    Move(ABuffer^, P[13], ABufferLength);
    CRCCode := NewEncode(@P[3], ABufferLength + 10); //�������ݣ�ͬʱ�������16λ��CRC
    PWORD(@P[1])^ := CRCCode; //2,3���ֽ�λCRC��
    Result := SendBuffer(AHost, APort, P^, ABufferLength + 13);
    Inc(FSendBytes, ABufferLength + 13);
  end
  else begin //��������зָ�
    BlockCount := (ABufferLength + MTU - 1) div MTU;
    if BlockCount >= 255 then
    begin
      DoUDPServerError(Format('���ݷ��͵ĳ���̫��: ABufferLength=%d', [ABufferLength]));
      Exit;
    end;
    P := @Buf;
    P[0] := Chr(CNewProtocolFlag);
    Offset := 0;
    for I := 0 to BlockCount - 1 do
    begin
      PInt64(@P[3])^ := ALSH; //һ��Ҫ��ѭ���������¸�ֵ�����ⱻ�����ƻ�
      P[11] := Chr(BlockCount); //�����ܸ���
      P[12] := Chr(I + 1);  //�������
      Size := MTU;
      if Size > ABufferLength - Offset then
        Size := ABufferLength - Offset;
      Move(PChar(Integer(ABuffer) + Offset)^, P[13], Size);
      CRCCode := NewEncode(@P[3], Size + 10);
      PWORD(@P[1])^ := CRCCode; //2,3���ֽ�λCRC16��
      Result := SendBuffer(AHost, APort, P^, Size + 13);
      Inc(FSendBytes, Size + 13);
      Inc(Offset, Size);
      if not Result then
        Exit;
    end;
  end;
end;

function TJxdUDPServer.OldSend(AHost: TInAddr; APort: WORD; ABuffer: PChar;
  ABufferLength: Integer; AReplyBuffer: PChar; var AReplyLength: Integer;
  ALSH: string; ATimeout: Integer; AEncrypt: Boolean): Boolean;
begin
  Result := OldSendWait(AHost, APort, ABuffer, ABufferLength, AReplyBuffer, AReplyLength,
    ALSH, ATimeout, AEncrypt);
end;

function TJxdUDPServer.OldSendWait(AHost: TInAddr; APort: WORD; ABuffer: PChar;
  ABufferLength: Integer; AReplyBuffer: PChar; var AReplyLength: Integer;
  ALSH: string; ATimeout: Integer; AEncrypt: Boolean): Boolean;
var
  T: Cardinal;
  SerialID: Integer;
begin
  Result := False;
  if AReplyBuffer = nil then
    Exit;
  AReplyLength := 0;
  if ALSH = '' then
    ALSH := GetOldLSH(FUserID, SerialID)
  else
  begin
    SerialID := GetOldSerialID(ALSH);
  end;
  if (SerialID < 1) or (SerialID > ServerMaxSerialID) then
    Exit;
  FReplyList[SerialID].BufferLength := 0;
  FReplyList[SerialID].Buffer := AReplyBuffer;

  if not OldSend(AHost, APort, ABuffer, ABufferLength, ALSH,AEncrypt) then
    Exit;

  T := GetTickCount + DWORD(ATimeout);
  while FActive and not Result do
  begin
    Sleep(50);
    Result := FReplyList[SerialID].BufferLength > 0;
    if Result then
    begin
      EnterCriticalSection(FReplyLock);
      try
        AReplyLength := FReplyList[SerialID].BufferLength;
        FReplyList[SerialID].Buffer := nil;
        FReplyList[SerialID].BufferLength := 0;
      finally
        LeaveCriticalSection(FReplyLock);
      end;
      Exit;
    end
    else if T < GetTickCount then
      Break;
    Application.ProcessMessages;
  end;
  if not Result then
  begin
    EnterCriticalSection(FReplyLock);
    try
      FReplyList[SerialID].BufferLength := 0;
      FReplyList[SerialID].Buffer := nil;
    finally
      LeaveCriticalSection(FReplyLock);
    end;
  end;
end;

function TJxdUDPServer.OldSend(AHost: TInAddr; APort: WORD; ABuffer: PChar;
  ABufferLength: Integer; ALSH: string; AEncrypt: Boolean): Boolean;
const
  VOneTimeLen = 1200;
  function CodeStr(ASendStr: string): string;
  begin
    Result := ASendStr;
    if AEncrypt then
      Result := '9' + OldEncode(ASendStr);
  end;
var
  aMsg, aHead, aTemp, aSendStr, aBagHead: string;
  ABufLength, BlockCount, i: Integer;
  ABuf: string;
  len: Integer;
  SerialID: Integer;
begin
  Result := False;
  SetString(ABuf, ABuffer, ABufferLength);
  if ABuf = '' then Exit;
  try
    ABufLength := Length(ABuf);
    if ALSH = '' then
      ALsh := GetOldLSH(FUserID, SerialID);
    if ABufLength <= VOneTimeLen then
    begin //���Ƚ�С,����ֱ�ӷ���
      aSendStr := '0' + ALsh + '0' + //��ˮ��Ϊ��λ,0��ʾΪ������һ����
        AddFourHead(ABuf);
      Len := Length(aSendStr); ////�����õ�
      if Len = 0 then Exit; ///
      aSendStr := CodeStr(aSendStr);
      Len := Length(aSendStr); ///
      if Len = 0 then Exit; ///
      SendBuffer(AHost, APort, aSendStr[1], Length(aSendStr));
      Inc(FSendBytes,Length(aSendStr));
    end
    else begin
      aMsg := ABuf;
      ABufLength := Length(aMsg);
      BlockCount := (ABufLength + VOneTimeLen - 1) div VOneTimeLen;
      aTemp := '/' + IntToStr(BlockCount); //�õ��� /4 ֮����ַ���
      for i := 0 to BlockCount - 1 do
      begin
        aBagHead := IntToStr(i + 1) + aTemp;
        aHead := ALsh + IntToStr(Length(aBagHead)) + aBagHead;

        //�ó����͵�����
        aSendStr := Copy(aMsg, 1, VOneTimeLen);
        aMsg := Copy(aMsg, VOneTimeLen + 1, Length(aMsg) - VOneTimeLen);

        aSendStr := '0' + aHead + AddFourHead(aSendStr);
        //����
        aSendStr := CodeStr(aSendStr);
        SendBuffer(AHost, APort, aSendStr[1], Length(aSendStr));
        Inc(FSendBytes,Length(aSendStr));
      end; //end for
    end;
  except
  end;
  ABuf := '';
  Result := True;
end;

procedure TJxdUDPServer.OpenUDPServer;
var
  I: Integer;
begin
  if FActive then
    Exit;
  FSendBytes := 0;
  FRecvBytes := 0;
  FLastSend := 0;
  FLastRecv := 0;
  FSendSpeed := 0;
  FRecvSpeed := 0;
  FDropPackCount :=0;
  FLastTick := GetTickCount;

  //1,��UDP
  try
    FPPUDP := TJxdUDP.Create(nil);
    FPPUDP.AutoIncPort := FAutoIncPort;
    FPPUDP.DefaultPort := FDefaultPort;
    FPPUDP.ProxySettings := FProxySettings;
    FPPUDP.Active := True;
    FDefaultPort := FPPUDP.DefaultPort;
  except
    on E: Exception do
    begin
      FPPUDP.Free;
      DoUDPServerError(Format(SException, ['FPPUDP.Active',
        E.ClassName, E.Message]));
      Exit;
    end;
  end;
  FPPUDP.OnUDPRead := PPUDPRead;
  FPPUDP.OnUDPError := PPUDPError;

  //2,�������ݽṹ
  try
    FBufferQueue := TPointerQueue.Create(FMaxBufferCount);
    FMemoryManager := TStaticMemoryManager.Create(FPPUDP.BufferSize + 8, FMaxBufferCount);
    FUDPBagRecvList := TList.Create;
  except
    on E: Exception do
    begin
      DoUDPServerError(Format(SException, ['TPPUDPServer.OpenUDPServer',
        E.ClassName, E.Message]));
      Exit;
    end;
  end;

  //3,���������߳�
  //FWorkThreadCount := 1; ///�õ��߳������� ������ʱע����һ��
  SetLength(FWorkThread, FWorkThreadCount);
  for I := 0 to FWorkThreadCount - 1 do
    FWorkThread[I] := TPPUDPServerWorkThread.Create(Self);
  FActive := True;
end;

procedure TJxdUDPServer.PPUDPError(Sender: TObject; const AErrorMessage: string);
begin
  DoUDPServerError('PPUDPError:' + AErrorMessage);
end;

procedure TJxdUDPServer.PPUDPRead(Sender: TObject;const PeerInfo: TPeerAddr);
var
  Buffer: PChar;
  TempBuffer: array[0..4095] of Char;
  BufferLength: Integer;
  SockAddr: TSockAddr;
begin
  FPPUDP.RecvBuf(TempBuffer, BufferLength, SockAddr);
  if (BufferLength <= 0)  then
    Exit;
  if not FMemoryManager.GetMem(Pointer(Buffer)) then
  begin
    DoUDPServerError('GetMem faild!');
    Inc(FDropPackCount);
    Exit;
  end;
  PDWORD(Buffer)^ := SockAddr.sin_addr.S_addr;
  PWORD(@Buffer[4])^ := ntohs(SockAddr.sin_port);
  PWORD(@Buffer[6])^ := BufferLength;
  Move(TempBuffer, Buffer[8], BufferLength);
  if not FBufferQueue.InsertNode(Pointer(Buffer)) then
  begin
    if not FMemoryManager.FreeMem(Pointer(Buffer)) then
      DoUDPServerError('FreeMem error');
    DoUDPServerError('InsertNode faild!');
    Inc(FDropPackCount);
    Exit;
  end;
  Inc(FRecvBytes, BufferLength);
end;


function TJxdUDPServer.SendBuffer(AHost: TInAddr; APort: WORD;var ABuffer;
  ABufferLength: Integer): Boolean;
begin
  Result := False;
  if (AHost.S_addr = 0) or not FActive then
    Exit;
  Result := FPPUDP.SendBuf(AHost, APort,ABuffer, ABufferLength);
end;

function TJxdUDPServer.SendBuffer(AHost: string; APort: WORD;var ABuffer;
  ABufferLength: Integer): Boolean;
var
  InAddr: TInAddr;
begin
  InAddr.S_addr := inet_addr(PChar(AHost));
  Result := SendBuffer(InAddr, APort, ABuffer, ABufferLength);
end;

function TJxdUDPServer.NewSendWait(AHost: TInAddr;
  APort: WORD; ABuffer: PChar; ABufferLength: Integer; AReplyBuffer: PChar;
  var AReplyLength: Integer; ALSH: Int64; ATimeout: Integer;
  AEncrypt: Boolean): Boolean;
var
  T: Cardinal;
  SerialID: Integer;
begin
  Result := False;
  if AReplyBuffer = nil then
    Exit;
  AReplyLength := 0;
  if ALSH = 0 then
    ALSH := GetNewLSH(FUserID, SerialID)
  else
  begin
    SerialId := GetNewSerialID(ALSH);
  end;
  if (SerialID < 1) or (SerialID > ServerMaxSerialID) then
    Exit;
  FReplyList[SerialID].BufferLength := 0;
  FReplyList[SerialID].Buffer := AReplyBuffer;

  if not NewSend(AHost, APort, ABuffer, ABufferLength, ALSH) then
    Exit;

  T := GetTickCount + DWORD(ATimeout);
  while FActive and not Result do
  begin
    Sleep(50);
    Result := FReplyList[SerialID].BufferLength > 0;
    if Result then
    begin
      EnterCriticalSection(FReplyLock);
      try
        AReplyLength := FReplyList[SerialID].BufferLength;
        FReplyList[SerialID].Buffer := nil;
        FReplyList[SerialID].BufferLength := 0;
      finally
        LeaveCriticalSection(FReplyLock);
      end;
      Exit;
    end
    else if T < GetTickCount then
      Break;
    Application.ProcessMessages;
  end;
  if not Result then
  begin
    EnterCriticalSection(FReplyLock);
    try
      FReplyList[SerialID].BufferLength := 0;
      FReplyList[SerialID].Buffer := nil;
    finally
      LeaveCriticalSection(FReplyLock);
    end;
  end;
end;

procedure TJxdUDPServer.SetActive(const Value: Boolean);
begin
  if not (csDesigning in ComponentState) then
  begin
    if Value then
      OpenUDPServer
    else
      CloseUDPServer;
  end
  else begin
    FActive := Value;
  end;
end;

procedure TJxdUDPServer.SetDefaultPort(const Value: Word);
begin
  if not FActive then
    FDefaultPort := Value;
end;

procedure TJxdUDPServer.SetProxySettings(const Value: TProxySettings);
begin
  FProxySettings.Assign(Value);
  if Assigned(FPPUDP) then
    FPPUDP.ProxySettings := Value;
end;

procedure TJxdUDPServer.SetWorkThreadCount(const Value: Integer);
begin
  if (Value > 0) and (Value < 1000) and not FActive then
    FWorkThreadCount := Value;
end;

function TJxdUDPServer.TestProxy(const AHost: string; APort: Word;
  const AUserName, AUserPass: string): Boolean;
begin
  Result := FPPUDP.TestProxy(AHost,APort,AUserName,AUserPass);
end;

procedure TJxdUDPServer.UDPServerExecute(Sender: TObject; ABuffer: PChar;
  ABufferLength: Integer; APeerIP: TInAddr; APeerPort: WORD);
var
  FlagHead: Byte;
  TotalPart, Currpart: Integer;
  CRCCodeA, CRCCodeB: WORD;
  NewGUID: TPPGUID;
  Buffer: PChar;
  BufferLength: Integer;
  Len, P: Byte;
  Temp, S1, S2: string;
  CRC1, CRC2: DWORD;
  ARecvStr: string;
label StartHere;
begin
  if ABufferLength < 10 then
    Exit;
  FlagHead := Byte(ABuffer[0]);
  case FlagHead of
    CNewProtocolFlag: //��Э��
      begin
        CRCCodeA := PWORD(@ABuffer[1])^;
        CRCCodeB := NewDecode(@ABuffer[3], ABufferLength - 3);
        if CRCCodeA <> CRCCodeB then
          Exit;
        NewGUID.GUID := PInt64(@ABuffer[3])^;
        TotalPart := Ord(ABuffer[11]);
        CurrPart := Ord(ABuffer[12]);
        Buffer := @ABuffer[13];
        BufferLength := ABufferLength - 13;
        DoUDPServerNewRead(Sender, Buffer, BufferLength, TotalPart, CurrPart, APeerIP, APeerPort, NewGUID);
      end;
    CMSG_Data: //�ļ����͵����ݽӿ�
      begin
        DOUDPServerOldFTPData(Sender, ABuffer, ABufferLength, APeerIP, APeerPort);
      end;
    CMSG_NEWDATA:
      begin
        CRC1 := PDWORD(@ABuffer[1])^;
        CRC2 := CalcCRC32(@ABuffer[5], ABufferLength - 5);
        if CRC1 = CRC2 then
          DOUDPServerNewFTPData(Sender, @ABuffer[5], ABufferLength - 5, APeerIP, APeerPort);
      end;
    CCodStr:
      begin
        //ȥ����һ���ֽ�'9'
        SetString(ARecvStr, PChar(@ABuffer[1]), ABufferLength - 1);
        ARecvStr := OldDecode(ARecvStr);
        ABufferLength := Length(ARecvStr);
        Move(ARecvStr[1],ABuffer^,ABufferLength);
        //StrPCopy(ABuffer, ARecvStr);
        ARecvStr := '';
        goto StartHere;
      end;
    CMSG_Str:
      begin
        //����'0'
        StartHere:
        NewGUID.GUID := PInt64(@ABuffer[1])^;
        Len := Ord(ABuffer[9]);
        Dec(Len, $30); //��һ���ֽ��ַ���ת����Ϊ����
        if Len = 0 then
        begin
          CurrPart := 1;
          TotalPart := 1;
          BufferLength := PInteger(@ABuffer[10])^;
          if (BufferLength < 0) or (BufferLength > FPPUDP.BufferSize ) then
            Exit;
          Buffer := @ABuffer[14];
        end
        else begin
          SetString(Temp, PChar(@ABuffer[10]), Len);
          P := Pos('/', Temp);
          if P < 1 then
            Exit;
          S1 := Copy(Temp, 1, P - 1);
          S2 := Copy(Temp, P + 1, Len - P);
          Currpart := StrToIntDef(S1, 0);
          TotalPart := StrToIntDef(S2, 0);
          if (CurrPart > TotalPart) or (CurrPart < 1) or (TotalPart > 32) then
            Exit;
          BufferLength := PInteger(@ABuffer[10 + Len])^;
          Buffer := @ABuffer[14 + Len];
        end;
        DoUDPServerOldRead(Sender, Buffer, BufferLength, TotalPart, CurrPart, APeerIP, APeerPort, NewGUID);
      end;
  end;
end;

procedure TJxdUDPServer.WorkThreadExecute(Sender: TObject);
var
  Buffer: PChar;
  PeerIP: TInAddr;
  PeerPort: WORD;
  BufferLength: Integer;
  CurTick, TempTick: Cardinal;
begin
  if FBufferQueue = nil then
    Exit;
  CurTick := GetTickCount;
  if CurTick > FLastTick + 2000 then
  begin
    TempTick := InterlockedExchange(Integer(FLastTick), CurTick);
    TempTick := CurTick - TempTick;
    if TempTick > 1000 then
    begin
      FSendSpeed := FLastSend div Integer(TempTick div 1000);
      FRecvSpeed := FLastRecv div Integer(TempTick div 1000);
      FLastSend := 0;
      FLastRecv := 0;
    end;
  end;
  if not FBufferQueue.GetFirstNode(Pointer(Buffer)) or (Buffer = nil) then
  begin
    Sleep(2);
    Exit;
  end;

  Inc(FActiveThreadCount);
  PeerIP.S_addr := PDWORD(Buffer)^;
  PeerPort := PWORD(@Buffer[4])^;
  BufferLength := PWORD(@Buffer[6])^;
  try
    UDPServerExecute(Sender, @Buffer[8], BufferLength, PeerIP, PeerPort);
  finally
    if not FMemoryManager.FreeMem(Pointer(Buffer)) then
      DoUDPServerError('FreeMem error');
  end;
  Dec(FActiveThreadCount);
end;

end.

