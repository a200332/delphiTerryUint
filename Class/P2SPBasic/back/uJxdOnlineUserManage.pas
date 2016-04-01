unit uJxdOnlineUserManage;

interface

uses
  Windows, Classes, SysUtils, uJxdDataStruct, uJxdMemoryManage, uJxdThread, uJxdDataStream,
  uJxdCmdDefine;

type
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///                         TServerHashList
  ///
  ///  ���̰߳�ȫ
  ///
  ///  ���������߹���ʹ�õ����ݽṹ
  ///
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  TServerHashList = class(THashArray)
  public
    //�����ȡN�������û�����Ϣ, ����ȡ���û�����
    function GetRandomUserInfo(const AExceptionID: Cardinal; AStream: TxdMemoryHandle): Integer;
  end;

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///                         TRegisterManage
  ///
  ///  �̰߳�ȫ
  ///  �û���Ҫ��ID��1000��ʼ��1000���ڵı���
  ///  �ṩע�����ֱ�ӵ��� GetNewUserID �ɻ�ȡһ���µ��û�ID
  ///
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  {$M+}
  TRegisterManage = class
  public
    constructor Create(const AMinUserID: Cardinal = CtMinUserID);
    destructor  Destroy; override;
    function GetNewUserID: Cardinal; inline;
  private
    FUserID: Cardinal;
    FLock: TRTLCriticalSection;
  published
    property UserID: Cardinal read FUserID;
  end;
  {$M-}
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  ///                         TOnlineUserManage
  ///
  ///  �̰߳�ȫ
  ///  �����û�������
  ///  �ṩע�����ֱ�ӵ��� GetNewUserID �ɻ�ȡһ���µ��û�ID
  ///
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  POnlineUserInfo = ^TOnlineUserInfo;
  TOnlineUserInfo = record
    FUserID: Cardinal;                 //�û�ID
    FPublicIP, FLocalIP: Cardinal;   //�û�IP��Ϣ
    FPublicPort, FLocalPort: Word;   //�û��˿���Ϣ
    FClientVersion: Word;              //�ͻ��˰汾��
    FTimeoutCount: Word;               //�û���ʱ����
    FLoginTime: Cardinal;              //��¼ʱ��
    FLastActiveTime: Cardinal;         //���ʱ��, ���յ����ݵ����ʱ��
    FSaftSign: Cardinal;               //��ȫ�� 
    FClientHash: array[0..15] of Byte; //�ͻ���HASH
    FData: Pointer;                    //������Ϣ���ɴ���ָ����ָ���ڴ�Ϊ�ⲿ���룬�ͷ�
  end;

  TAddUserResult = (auSuccess, auIDExists, auNoEnoughMem); //����û�ʱ����ֵ
  TDeleteUserResult = (duSuccess, duNotFindUser, duErrorSafeSign);//ɾ���û�ʱ����ֵ
  TOptResult = (orSuccess, orNotExistsID, orNotFindUser, orError); //�������ؽ��
  TOnUser = procedure(const ApUserInfo: POnlineUserInfo) of object; 
  {$M+}
  TOnlineUserManage = class
  public
    constructor Create;
    destructor  Destroy; override;

    function  AddOnlineUser(const AUserID, APublicIP, ALocalIP: Cardinal; const APublicPort, ALocalPort, AClientVersion: Word;
      const AClientHash: array of Byte; var ASaftSize: Cardinal): TAddUserResult; //��������û�
    function  ActiveOnlineUser(const AUserID: Cardinal): Boolean; //�޸��û����ʱ��
    function  DeleteOnlineUser(const AUserID, ASaftSign: Cardinal): TDeleteUserResult; //ɾ�������û�
    function  GetRandomUserInfo(const AExceptionID: Cardinal; AStream: TxdMemoryHandle): Integer; //�����ȡ�����û�
    function  GetOnlineUserInfo(var AUserAInfo, AUserBInfo: TUserNetInfo): TOptResult; //��ȡָ���û���Ϣ�����Ҹ���A�û���ʱ��
  private
    FCheckEvent: Cardinal;
    FCheckTime: Cardinal;
    FCheckThreadCount: Integer;
    procedure ActiveManage;
    procedure UnActiveManage;
    procedure LockOnline; inline;
    procedure UnLockOnline; inline;
    {�߳�ִ�к���}
    procedure DoThreadToCheck;
    procedure DoThreadCheckOnlinActiveTime(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean);
  private
    FOnlineList: TServerHashList;
    FOnlineMem: TxdFixedMemoryManager;
    FOnlineLock: TRTLCriticalSection;
    FMaxOnlineCount: Integer;
    FActive: Boolean;
    FOnAddUser: TOnUser;
    FOnDeleteUser: TOnUser;
    FMaxIdleTime: Cardinal;
    FCheckSpaceTime: Cardinal;
    FTimeoutUserCount: Integer;
    procedure SetMaxOnlineCount(const Value: Integer);
    procedure SetActive(const Value: Boolean);
    function GetCount: Integer;
    procedure SetMaxIdleTime(const Value: Cardinal);
    procedure SetCheckSpaceTime(const Value: Cardinal);
  published
    property Active: Boolean read FActive write SetActive;
    property MaxOnlineCount: Integer read FMaxOnlineCount write SetMaxOnlineCount; //���������������
    property CheckSpaceTime: Cardinal read FCheckSpaceTime write SetCheckSpaceTime; //�����
    property MaxIdleTime: Cardinal read FMaxIdleTime write SetMaxIdleTime; //������ʱ�䣬������ֵ�����Զ�ɾ���û�

    property TimeoutUserCount: Integer read FTimeoutUserCount; //��ʱ�û�����
    property Count: Integer read GetCount; //��ǰ��������

    property OnAddUser: TOnUser read FOnAddUser write FOnAddUser; //�����һ�����û�ʱ��������״̬������
    property OnDeleteUser: TOnUser read FOnDeleteUser write FOnDeleteUser; //��ɾ��һ���û�ʱ��������״̬������
  end;
  {$M-}
implementation

const
  CtOnlineUserInfoSize = SizeOf(TOnlineUserInfo);

{ TRegisterManage }

constructor TRegisterManage.Create(const AMinUserID: Cardinal);
begin
  InitializeCriticalSection( FLock );
  FUserID := AMinUserID;
end;

destructor TRegisterManage.Destroy;
begin
  DeleteCriticalSection( FLock );
  inherited;
end;

function TRegisterManage.GetNewUserID: Cardinal;
begin
  EnterCriticalSection( FLock );
  try
    FUserID := FUserID + 1;
    Result := FUserID;
  finally
    LeaveCriticalSection( FLock );
  end;
end;

{ TOnlineUserManage }

procedure TOnlineUserManage.ActiveManage;
begin
  try
    InitializeCriticalSection( FOnlineLock );
    FOnlineList := TServerHashList.Create;
    with FOnlineList do
    begin
      HashTableCount := 131313;
      MaxHashNodeCount := FMaxOnlineCount;
      Active := True;
    end;
    FOnlineMem := TxdFixedMemoryManager.Create( CtOnlineUserInfoSize, MaxOnlineCount );
    FCheckEvent := CreateEvent( nil, False, False, nil );
    FActive := True;
    FCheckThreadCount := 0;
    FTimeoutUserCount := 0;
    RunningByThread( DoThreadToCheck );
  except
    UnActiveManage;
  end;
end;

function TOnlineUserManage.ActiveOnlineUser(const AUserID: Cardinal): Boolean;
var
  p: POnlineUserInfo;
  bExists: Boolean;
begin
  LockOnline;
  try
    bExists := FOnlineList.Find( AUserID, Pointer(p), False );
    if bExists then
    begin
      Result := True;
      p^.FLastActiveTime := GetTickCount;
      p^.FTimeoutCount := 0;
    end
    else
      Result := False;
  finally
    UnLockOnline;
  end;
end;

function TOnlineUserManage.AddOnlineUser(const AUserID, APublicIP, ALocalIP: Cardinal; const APublicPort,
  ALocalPort, AClientVersion: Word; const AClientHash: array of Byte; var ASaftSize: Cardinal): TAddUserResult;
var
  p: POnlineUserInfo;
  bExists: Boolean;
begin
  LockOnline;
  try
    bExists := FOnlineList.Find( AUserID, Pointer(p), False );
    if bExists then
    begin
      //���ظ���¼��������Ϊ����ԭ��,�����Ϣ��ͬ����ֱ�Ӹ��»ʱ��
      if (p^.FPublicIP = APublicIP) and (p^.FLocalIP = ALocalIP) and
         (p^.FPublicPort = APublicPort) and (p^.FLocalPort = APublicPort) and
         (AClientVersion = p^.FClientVersion) and CompareMem( @AClientHash, @p^.FClientHash, 16) then
      begin
        p^.FLastActiveTime := GetTickCount;
        ASaftSize := p^.FSaftSign;
        Result := auSuccess;
        Exit;
      end;
      
      Result := auIDExists;
      Exit;
    end;
    if not FOnlineMem.GetMem(Pointer(p)) then
    begin
      Result := auNoEnoughMem;
      Exit;
    end;
    p^.FUserID := AUserID;
    p^.FPublicIP := APublicIP;
    p^.FPublicPort := APublicPort;
    p^.FLocalIP := ALocalIP;
    p^.FLocalPort := ALocalPort;
    p^.FClientVersion := AClientVersion;
    p^.FSaftSign := Random( MaxLongint ) * Round( Random * 131313131 );
    Move( AClientHash[0], p^.FClientHash[0], 16 );
    p^.FData := nil;
    
    if Assigned(OnAddUser) then
      OnAddUser( p );

    p^.FLoginTime := GetTickCount;
    p^.FLastActiveTime := p^.FLoginTime;
    p^.FTimeoutCount := 0;
    FOnlineList.Add( AUserID, p );
    Result := auSuccess;
    ASaftSize := p^.FSaftSign;
  finally
    UnLockOnline;
  end;
end;

constructor TOnlineUserManage.Create;
begin
  FActive := False;
  FMaxOnlineCount := 500000;
  FMaxIdleTime := 60 * 1000;
  FCheckSpaceTime := 70 * 1000;
end;

function TOnlineUserManage.DeleteOnlineUser(const AUserID, ASaftSign: Cardinal): TDeleteUserResult;
var
  p: POnlineUserInfo;
  bExists: Boolean;
begin
  Result := duNotFindUser;
  LockOnline;
  try
    bExists := FOnlineList.Find( AUserID, Pointer(p), False );
    if bExists then
    begin
      if p^.FSaftSign = ASaftSign then
      begin
        FOnlineList.Find( AUserID, Pointer(p), True );
        if Assigned(OnDeleteUser) then
          OnDeleteUser( p );
        FOnlineMem.FreeMem( p );
        Result := duSuccess;
      end
      else
        Result := duErrorSafeSign;
    end;
  finally
    UnLockOnline;
  end;
end;

destructor TOnlineUserManage.Destroy;
begin
  Active := False;
  inherited;
end;

procedure TOnlineUserManage.DoThreadCheckOnlinActiveTime(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel, AFindNext: Boolean);
var
  p: POnlineUserInfo;
begin
  if not Active then
  begin
    AFindNext := False;
    Exit;
  end;
  p := pData;
  if (FCheckTime > p^.FLastActiveTime) and (FCheckTime - p^.FLastActiveTime > FMaxIdleTime) then
  begin
    ADel := True;
    if Assigned(OnDeleteUser) then
      OnDeleteUser( p );
    FOnlineMem.FreeMem( p );
    InterlockedIncrement( FTimeoutUserCount );
  end;
end;

procedure TOnlineUserManage.DoThreadToCheck;
begin
  InterlockedIncrement( FCheckThreadCount );
  try
    while Active do
    begin
      WaitForSingleObject( FCheckEvent, FCheckSpaceTime );
      if not Active then Break;
      if FOnlineList.Count > 0 then
      begin
        LockOnline;
        try
          FCheckTime := GetTickCount;
          FOnlineList.Loop( DoThreadCheckOnlinActiveTime );
        finally
          UnLockOnline;
        end;
      end;
    end;
  finally
    InterlockedDecrement( FCheckThreadCount );
  end;
end;

function TOnlineUserManage.GetRandomUserInfo(const AExceptionID: Cardinal; AStream: TxdMemoryHandle): Integer;
var
  p: POnlineUserInfo;
  bExists: Boolean;
begin
  Result := 0;
  LockOnline;
  try
    bExists := FOnlineList.Find( AExceptionID, Pointer(p), False );
    if bExists then
    begin
      Result := FOnlineList.GetRandomUserInfo( AExceptionID, AStream );
      p^.FLastActiveTime := GetTickCount;
      p^.FTimeoutCount := 0;
    end
  finally
    UnLockOnline;
  end;
end;

function TOnlineUserManage.GetCount: Integer;
begin
  if Active then
    Result := FOnlineList.Count
  else
    Result := 0;
end;

function TOnlineUserManage.GetOnlineUserInfo(var AUserAInfo, AUserBInfo: TUserNetInfo): TOptResult;
var
  p1, p2: POnlineUserInfo;
begin
  LockOnline;
  try
    if FOnlineList.Find(AUserAInfo.FUserID, Pointer(p1), False) then
    begin
      if FOnlineList.Find(AUserBInfo.FUserID, Pointer(p2), False) then
      begin
        AUserAInfo.FPublicIP := p1^.FPublicIP;
        AUserAInfo.FLocalIP := p1^.FLocalIP;
        AUserAInfo.FPublicPort := p1^.FPublicPort;
        AUserAInfo.FLocalPort := p1^.FLocalPort;

        AUserBInfo.FPublicIP := p2^.FPublicIP;
        AUserBInfo.FLocalIP := p2^.FLocalIP;
        AUserBInfo.FPublicPort := p2^.FPublicPort;
        AUserBInfo.FLocalPort := p2^.FLocalPort;
        Result := orSuccess;
      end
      else
        Result := orNotFindUser;
      p1^.FLastActiveTime := GetTickCount;
    end
    else
      Result := orNotExistsID;
  finally
    UnLockOnline;
  end;
end;

procedure TOnlineUserManage.LockOnline;
begin
  EnterCriticalSection( FOnlineLock );
end;

procedure TOnlineUserManage.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
      ActiveManage
    else
      UnActiveManage;
  end;
end;

procedure TOnlineUserManage.SetCheckSpaceTime(const Value: Cardinal);
begin
  FCheckSpaceTime := Value;
end;

procedure TOnlineUserManage.SetMaxIdleTime(const Value: Cardinal);
begin
  FMaxIdleTime := Value;
end;

procedure TOnlineUserManage.SetMaxOnlineCount(const Value: Integer);
begin
  if not Active and (FMaxOnlineCount <> Value) and (Value > 0) then
    FMaxOnlineCount := Value;
end;

procedure TOnlineUserManage.UnActiveManage;
begin
  FActive := False;
  SetEvent( FCheckEvent );
  while FCheckThreadCount > 0 do
  begin
    Sleep( 10 );
    SetEvent( FCheckEvent );
  end;
  CloseHandle( FCheckEvent );
  FreeAndNil( FOnlineList );
  FreeAndNil( FOnlineMem );
  DeleteCriticalSection( FOnlineLock );
end;

procedure TOnlineUserManage.UnLockOnline;
begin
  LeaveCriticalSection( FOnlineLock );
end;

{ TServerHashList }

function TServerHashList.GetRandomUserInfo(const AExceptionID: Cardinal; AStream: TxdMemoryHandle): Integer;
var
  aTempV: array[0..CtMaxSearchRandomUserCount - 1] of Integer; //�������Ҫ��λ��λ��
  i, nMaxCount, nFirstIndex, nCurNodeCount, nIndex, nTempValue, nWriteToStreamCount: Integer;
  pNode: pHashNode;
  p: POnlineUserInfo;
  bDown: Boolean;

  //
  function IsOkRow(const AValue: Integer): Boolean;
  var
    k: Integer;
  begin
    Result := True;
    for k := 0 to nIndex - 1 do
    begin
      if AValue = aTempV[k] then
      begin
        Result := False;
        Break;
      end;
    end;
  end;

  //�жϵ�ǰ�ҵ����û��Ƿ�д������
  function IsOkUser: Boolean;
  var
    k: Integer;
  begin
    Result := False;
    for k := 0 to nMaxCount - 1 do
    begin
      if nIndex = aTempV[k] then
      begin
        Result := True;
        Break;
      end;
    end;
  end;

  //���û���Ϣд������
  procedure WriteInfoToStream(Ap: POnlineUserInfo);
  begin
    with AStream do
    begin
      WriteCardinal( Ap^.FUserID );
      WriteCardinal( Ap^.FPublicIP );
      WriteCardinal( Ap^.FLocalIP );
      WriteWord( ap^.FPublicPort );
      WriteWord( Ap^.FLocalPort );
    end;
    Inc( nWriteToStreamCount );
    Inc( Result );
  end;

  //�ж��Ƿ�Ҫд������
  procedure CheckToWriteStream;
  begin
    pNode := FHashTable[i];
    while Assigned(pNode) do
    begin
      if IsOkUser then
      begin
        p := pNode^.NodeData;
        if p^.FUserID <> AExceptionID then
          WriteInfoToStream( p );
      end;
      Inc( nIndex );
      pNode := pNode^.Next;
    end;
  end;


begin
  Result := 0;
  //�������Ҫ���ص�����
  nMaxCount := Random( CtMaxSearchRandomUserCount );
  if nMaxCount < CtMinSearchRandomUserCount then
    nMaxCount := CtMinSearchRandomUserCount;

  nCurNodeCount := Count;

  if nMaxCount >= nCurNodeCount + 1 then
  begin
    //����������Ҫ�����Сʱ, �����ش�ʱ���������û�(��ȥAExceptionID)
    nMaxCount := nCurNodeCount;
    //begin for
    for i := FFirstNodeIndex to HashTableCount - 1 do
    begin
      if nMaxCount = 0 then Break;
      pNode := FHashTable[i];
      while  Assigned(pNode) do
      begin
        p := pNode^.NodeData;
        if p^.FUserID <> AExceptionID then
          WriteInfoToStream( p );
        Dec(nMaxCount);
        pNode := pNode^.Next;
      end;
    end;
    //end for
  end
  else
  begin
    //���߶�����������ʱ, �����λJ���������U������D���������ȡN��ֵv1,v2,v3 ���� v: [0..Count)
    //ȷ��V���ظ�, ����һ��i���� i = v ʱ������ v��ID <> AExceptionID ʱ����ID��д�����С�
    nIndex := 0;
    for i := 0 to nMaxCount - 1 do
    begin
      nTempValue := Random( nCurNodeCount );
      while not IsOkRow(nTempValue) do
        nTempValue := Random( nCurNodeCount );
      aTempV[i] := nTempValue;
      Inc( nIndex );
    end;

    nFirstIndex := Random(HashTableCount);
    if nFirstIndex < FFirstNodeIndex then
      nFirstIndex := FFirstNodeIndex;
    nWriteToStreamCount := 0;
    nIndex := 0;
    bDown := Random(100) > 50;
    //��λ����Ҫ����
    if bDown then
    begin
      for i := nFirstIndex to HashTableCount - 1 do
        CheckToWriteStream;
      if nWriteToStreamCount < nMaxCount then
      begin
        for i := nFirstIndex - 1 downto 0 do
          CheckToWriteStream;
      end;
    end
    else
    begin
      for i := nFirstIndex downto 0 do
        CheckToWriteStream;
      if nWriteToStreamCount < nMaxCount then
      begin
        for i := nFirstIndex + 1 to HashTableCount - 1 do
          CheckToWriteStream;
      end;
    end;
  end;
end;

initialization
  Randomize;

end.
