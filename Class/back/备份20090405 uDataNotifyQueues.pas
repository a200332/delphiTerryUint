{
��Ԫ����: uDataNotifyQueues
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ��ӽڵ�,�����̻߳�ʱ�ӵķ�ʽ����֪ͨ
��ʼʱ��: 2009-1-15
�޸�ʱ��: 2009-1-21 (����޸�)
��Ҫ��  : TCheckThread  TSimpleNotify TMulitNotify �Լ���Ϊ������ڵ� TNotifyClass
}

unit uDataNotifyQueues;

interface
uses uQueues, Classes, SysUtils, Windows, Forms;

type
  TCheckThread = class(TThread)
  private
    FWaitEvent: Cardinal;
    FClose: Boolean;
    FSpaceTime: Cardinal;
    FNotify: TNotifyEvent;
    FActive: Boolean;
    procedure SetActive(const Value: Boolean);
    procedure SetSpaceTime(const Value: Cardinal);
  protected
    procedure Execute; override;
  public
    constructor Create(ANotifyEvent: TNotifyEvent);
    destructor Destroy; override;
    property SpaceTime: Cardinal read FSpaceTime write SetSpaceTime;
    property Active: Boolean read FActive write SetActive;
  end;

  //��֪ͨ��ʽ, ����ָ�� -> ������� -> �̴߳Ӷ�����ȡ������ -> ֪ͨ�ⲿ
  TOnSimpleNotifyEvent = procedure(Sender: TObject; ANotifyPointer: Pointer) of object;
  TSimpleNotify = class
  private
    FActive: Boolean;
    FMaxNodeCount: Cardinal;

    FThreadArray: array of TCheckThread;
    FThreadCount: Word;
    FSpaceTime: Cardinal;
    FOnSimpleNotifyEvent: TOnSimpleNotifyEvent;

    procedure OpenNotifyClass;
    procedure CloseNotifyClass;

    procedure DoThreadRun(Sender: TObject);
    procedure SetActive(const Value: Boolean);
    procedure SetThreadCount(const Value: Word);
    procedure SetMaxNodeCount(const Value: Cardinal);
    procedure SetSpaceTime(const Value: Cardinal);
  protected
    FQueue: TPointerQueue;
    procedure DoNotify; virtual;
    procedure BeforOpenNotify; virtual;
    procedure AfterCloseNotify; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    
    function Add(p: Pointer): Boolean;

    property MaxNodeCount: Cardinal read FMaxNodeCount write SetMaxNodeCount;     //�����������
    property ThreadCount: Word read FThreadCount write SetThreadCount;            //�����߳���.
    property SpaceTime: Cardinal read FSpaceTime write SetSpaceTime;              //ÿ�� SpaceTime ����һ��DoNotify;
    property Active: Boolean read FActive write SetActive;
    property OnSimpleNotifyEvent: TOnSimpleNotifyEvent read FOnSimpleNotifyEvent write FOnSimpleNotifyEvent;
  end;

  //ʹ������������ķ�ʽ����ӽڵ�.
  {
     i       v
    [0] -> Node1 -> Node2 ...
    [1] -> Node1 -> Node2 ...
    [2] -> Node1 -> Node2 ...
    [3] -> Node1 -> Node2 ...
    ...
    i := IndexKey mod FHashTableCount - 1;  ����õ���������λ��
    v :=  (IndexKey = Node1^.FIndexKey) and (ContentKey = Node1^.FContentKey): ��ʱ�ڵ�λ��
    �� IndexKey �� ContentKey ��ͬ��ΪͬһԪ��. ��ͻ����ʱ,ʹ�õ�����
  }
  pHashNode = ^THashNode;
  THashNode = record
    FIndexKey: Cardinal;       //����
    FCount: Byte;              //����������
    FCurCount: Byte;           //��ǰ�ѽ��յ��İ�����
    FContentKey: Word;         //��������
    FLastActiveTime: Cardinal; //���ʱ��;
    FNext: pHashNode;          //Hash��ͻ
    FDataArray: array[0..0] of Pointer;
  end;

  // ADataArray ���� HashNode �Ķ��巽ʽ,���һ��Ϊ 0..0 ������.������Ҫ�� const ������ 
  TOnNotify = function(Sender: TObject; const ADataArray: array of Pointer; ALen: Integer): Boolean of object;
  TMulitNotify = class
  private

    FHashTable: array of pHashNode;
    FHashTableCount: Cardinal;

    FHashNodeMem: TStaticMemoryManager;
    FMaxHashNodeCount: Cardinal;
    FHashNodeSize: Word;
    FPeenDataMaxCount: Byte;
    FActive: Boolean;

    FLockMem: TRTLCriticalSection;

    FNotifyQueue: TSimpleNotify;
    FNotifyThreadSpaceTime: Cardinal;
    FNotifyThreadCount: Word;
    FOnNotifyOK: TOnNotify;
    FCheckSpaceTime: Cardinal;
    FMaxWaitTime: Cardinal;     //֪ͨ�ⲿ��Ϣ�Ѵ������

    FCheckThread: TCheckThread;
    FIsCheckThread: Boolean;
    FOnNotifyHandleFail: TOnNotify;

    procedure OpenNotifyClass;
    procedure CloseNotifyClass;

    procedure DeleteNodePos(const AIndex: Cardinal; const pParentNode, pDelNode: pHashNode); inline; //��pDelNode�ӱ��а���
    procedure FreeHashNode(p: pHashNode);

    procedure DoPackageOK(const AIndex: Cardinal; const pParentNode, pNode: pHashNode);
    procedure DoCheckPackage(Sender: TObject); //ѭ������Ƿ�����Ч������,
    procedure DoHandleIOSuccess(Sender: TObject; ANotifyPointer: Pointer); overload;     //FNotifyQueue �¼�

    procedure SetActive(const Value: Boolean);
    procedure SetHashTableCount(const Value: Cardinal);
    procedure SetMaxHashNodeCount(const Value: Cardinal);
    procedure SetPeenDataMaxCount(const Value: Byte);
    procedure SetNotifyThreadCount(const Value: Word);
    procedure SetNotifyThreadSpaceTime(const Value: Cardinal);
    procedure SetChectSpaceTime(const Value: Cardinal);
    procedure SetMaxWaitTime(const Value: Cardinal);
    procedure SetIsCheckThread(const Value: Boolean);
  public
    constructor Create;
    destructor Destroy; override;

    //0: ��ȷ
    //1: �������Index����ȷ( UserID ���� )
    //2: �ڴ治��( ���벻��HashNode )
    //3: ������
    //4: ANodeIndex ��������
    function Add(const AIndexKey: Cardinal; const AContentKey: Word; const ANodeCount, ANodeIndex: Byte; pNode: Pointer): Integer;

    property Active: Boolean read FActive write SetActive;
    //��ʹ���ڴ����
    property HashTableCount: Cardinal read FHashTableCount write SetHashTableCount;
    property MaxHashNodeCount: Cardinal read FMaxHashNodeCount write SetMaxHashNodeCount;
    property PeenDataMaxCount: Byte read FPeenDataMaxCount write SetPeenDataMaxCount;
    //����֪ͨ�ⲿ,��Ϣ�Ѵ���õ�����
    property NotifyThreadCount: Word read FNotifyThreadCount write SetNotifyThreadCount; // 0: ʹ��ʱ��; > 0: ʹ���߳�
    property NotifyThreadSpaceTime: Cardinal read FNotifyThreadSpaceTime write SetNotifyThreadSpaceTime;
    //����߳�ʹ��
    property CheckThread: Boolean read FIsCheckThread write SetIsCheckThread;
    property MaxWaitTime: Cardinal read FMaxWaitTime write SetMaxWaitTime;  //��ȴ��ְ�����ʱ��, ��λ: ����
    property CheckSpaceTime: Cardinal read FCheckSpaceTime write SetChectSpaceTime; //���UDP���Ƿ���Ч�ļ��ʱ��
    //֪ͨ�ⲿ�¼�
    property OnNotifyHandleOK: TOnNotify read FOnNotifyOK write FOnNotifyOK;  //�������֮����ô��¼�
    property OnNotifyHandleFail: TOnNotify read FOnNotifyHandleFail write FOnNotifyHandleFail; //��ʱ; ����True: ɾ���ڵ�. ����: ����ʱ��
  end;

  {
    ��ϰ����չ�����
  }
//  pCombiInfo = ^TCombiInfo;
//  TCombiInfo = record
//    FCombiID: Word;
//    FTryCount: Byte;
//    FPackageCount: Byte;
//    FCurPackageCount: Byte;
//    FLastActiveTime: Cardinal;
//    FPackages: array[0..0] of Pointer;
//  end;
//  TCombiPackageManage = class
//  private
//    FCombiMem: TStaticMemoryManager;
//  public
//    constructor Create;
//    destructor Destroy; override;
//  end;

implementation


{ TNotifyClass }

function TSimpleNotify.Add(p: Pointer): Boolean;
begin
  Result := FQueue.InsertNode( p );
end;

procedure TSimpleNotify.AfterCloseNotify;
begin

end;

procedure TSimpleNotify.BeforOpenNotify;
begin
  if not Assigned(OnSimpleNotifyEvent) then
    raise Exception.Create( 'OnSimpleNotifyEvent �¼�û��ע��!' );
end;

procedure TSimpleNotify.CloseNotifyClass;
var
  i: Integer;
begin
  if Active then
  begin
    for i := Low(FThreadArray) to High(FThreadArray) do
      FThreadArray[i].Free;
    SetLength( FThreadArray, 0 );
    FreeAndNil( FQueue );
    AfterCloseNotify;
  end;
end;

constructor TSimpleNotify.Create;
begin
  FQueue := nil;
  FMaxNodeCount := 512;
  FThreadCount := 1;
  FSpaceTime := 10;
  SetLength(FThreadArray, 0);
  FActive := False;
end;

destructor TSimpleNotify.Destroy;
begin
  Active := False;
  inherited;
end;

procedure TSimpleNotify.DoNotify;
var
  p: Pointer;
begin
  while FQueue.GetFirstNode(p) do
    OnSimpleNotifyEvent( Self,p );
end;

procedure TSimpleNotify.DoThreadRun(Sender: TObject);
begin
  DoNotify;
end;

procedure TSimpleNotify.OpenNotifyClass;
var
  i: Integer;
begin
  if not Active then
  begin
    BeforOpenNotify;
    FQueue := TPointerQueue.Create( MaxNodeCount );
    SetLength( FThreadArray, ThreadCount );
    for i := Low(FThreadArray) to High(FThreadArray) do
    begin
      FThreadArray[i] := TCheckThread.Create( DoThreadRun );
      FThreadArray[i].SpaceTime := SpaceTime;
      FThreadArray[i].Active := True;
    end
  end;
end;

procedure TSimpleNotify.SetActive(const Value: Boolean);
begin
  if (FActive <> Value) then
  begin
    if Value then
      OpenNotifyClass
    else
      CloseNotifyClass;
    FActive := Value;
  end;
end;

procedure TSimpleNotify.SetMaxNodeCount(const Value: Cardinal);
begin
  if (not Active) and (FMaxNodeCount <> Value) and (Value <> 0) then
    FMaxNodeCount := Value;
end;

procedure TSimpleNotify.SetSpaceTime(const Value: Cardinal);
begin
  if (FSpaceTime <> Value) then
    FSpaceTime := Value;
end;

procedure TSimpleNotify.SetThreadCount(const Value: Word);
begin
  if (not Active) and (Value >= 1) and (FThreadCount <> Value) then
    FThreadCount := Value;
end;


{ TCheckThread }

constructor TCheckThread.Create(ANotifyEvent: TNotifyEvent);
begin
  FSpaceTime := 500;
  FClose := False;
  FActive := False;
  FNotify := ANotifyEvent;
  if not Assigned(FNotify) then
    raise Exception.Create( '����̵߳� NotifyEvent ����Ϊnil' );
  FWaitEvent := CreateEvent( nil, False, False, '' );
  inherited Create(False);
end;

destructor TCheckThread.Destroy;
begin
  Active := False;
  SetEvent( FWaitEvent );
  while not FClose do
    Sleep(10);
  CloseHandle( FWaitEvent );
  inherited;
end;

procedure TCheckThread.Execute;
var
  nState: Cardinal;
begin
  while True do
  begin
    nState := WaitForSingleObject( FWaitEvent, SpaceTime );
    if FClose then Exit;
    if (WAIT_TIMEOUT = nState) and Active then
      FNotify( Self )
    else if WAIT_OBJECT_0 = nState then
    begin
      FClose := True;
      Exit;
    end;
  end;
end;

procedure TCheckThread.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
  end;
end;

procedure TCheckThread.SetSpaceTime(const Value: Cardinal);
begin
  if FSpaceTime <> Value then
    FSpaceTime := Value;
end;

{ TMulitNotify }

constructor TMulitNotify.Create;
begin
  FHashTableCount := 1024 * 2;
  FMaxHashNodeCount := 512;
  FPeenDataMaxCount := 8;
  FHashNodeSize := SizeOf( THashNode ) + (FPeenDataMaxCount - 1) * 4;
  //���ʹ�ò���
  FIsCheckThread := True;
  FCheckSpaceTime := 15 * 1000; //ÿ15����һ��
  FMaxWaitTime := 5 * 1000; //��Ч�ȴ�ʱ��
end;

procedure TMulitNotify.DeleteNodePos(const AIndex: Cardinal; const pParentNode, pDelNode: pHashNode);
begin
  if pParentNode = nil then
    FHashTable[AIndex] := pDelNode^.FNext
  else if pParentNode = pDelNode then
  begin
    if FHashTable[AIndex] = pDelNode then
      FHashTable[AIndex] := nil;
  end
  else
    pParentNode.FNext := pDelNode.FNext;
end;

destructor TMulitNotify.Destroy;
begin
  Active := False;
  inherited;
end;

procedure TMulitNotify.DoCheckPackage(Sender: TObject);
var
  i: Integer;
  pParent, pCur, pNext: pHashNode;
  dwNow: Cardinal;
begin
  dwNow := GetTickCount;
  for i := 0 to FHashTableCount - 1 do
  begin
    pCur := FHashTable[i];
    while pCur <> nil do
    begin
      pParent := pCur;
      pNext := pCur.FNext;
      if (dwNow > pCur^.FLastActiveTime) and (dwNow - pCur^.FLastActiveTime >= MaxWaitTime) then
      begin
        EnterCriticalSection( FLockMem );
        try
          dwNow := GetTickCount;
          if (dwNow > pCur^.FLastActiveTime) and (dwNow - pCur^.FLastActiveTime >= MaxWaitTime) then
          begin
            if OnNotifyHandleFail( Self, pCur^.FDataArray, FPeenDataMaxCount ) then
            begin
              DeleteNodePos( i, pParent, pCur );
              FreeHashNode( pCur );
            end
            else
              pCur^.FLastActiveTime := GetTickCount;
          end;
        finally
          LeaveCriticalSection( FLockMem );
        end;
      end;
      pCur := pNext;
    end;
  end;
end;

procedure TMulitNotify.DoHandleIOSuccess(Sender: TObject; ANotifyPointer: Pointer);
var
  p: pHashNode;
begin
  p := ANotifyPointer;
  OnNotifyHandleOK( Self, p^.FDataArray, FPeenDataMaxCount );
  FHashNodeMem.FreeMem( p );
end;

procedure TMulitNotify.DoPackageOK(const AIndex: Cardinal; const pParentNode, pNode: pHashNode);
begin
  DeleteNodePos( AIndex, pParentNode, pNode );
  FNotifyQueue.Add( pNode );
end;

procedure TMulitNotify.FreeHashNode(p: pHashNode);
begin
  FillChar( p, FHashNodeSize, 0 );
  FHashNodeMem.FreeMem( p );
end;

procedure TMulitNotify.OpenNotifyClass;
begin
  if not Assigned(OnNotifyHandleOK) then
    raise Exception.Create( '��ע�� OnNotifyOK �¼�' );
  if not Assigned(OnNotifyHandleFail) then
    raise Exception.Create( '��ע�� OnNotifyHandleFail �¼�' );
  InitializeCriticalSection( FLockMem );
  SetLength( FHashTable, FHashTableCount );
  FreeAndNil( FHashNodeMem );
  FreeAndNil( FNotifyQueue );
  FreeAndNil( FCheckThread );
  FHashNodeMem := TStaticMemoryManager.Create( FHashNodeSize, FMaxHashNodeCount );

  FNotifyQueue := TSimpleNotify.Create;
  with FNotifyQueue do
  begin
    ThreadCount := NotifyThreadCount;
    SpaceTime := NotifyThreadSpaceTime;
    OnSimpleNotifyEvent := DoHandleIOSuccess;
    Active := True;
  end;

  if CheckThread then
  begin
    FCheckThread := TCheckThread.Create( DoCheckPackage );
    FCheckThread.SpaceTime := CheckSpaceTime;
    FCheckThread.Active := True;
  end;
end;

function TMulitNotify.Add(const AIndexKey: Cardinal; const AContentKey: Word; const ANodeCount, ANodeIndex: Byte; pNode: Pointer): Integer;
var
  nIndex: Cardinal;
  pParent, p: pHashNode;
  bFind: Boolean;
  function GetNewNodeAndInit: pHashNode;
  begin
    Result := nil;
    if FHashNodeMem.GetMem(Pointer(Result)) then
    begin
      with Result^ do
      begin
        FIndexKey := AIndexKey;
        FCount := ANodeCount;
        FCurCount := 1;
        FContentKey := AContentKey;
        FLastActiveTime := GetTickCount;
        FDataArray[ANodeIndex] := pNode;
        FNext := nil;
      end;
    end;
  end;
  procedure CheckPackage(pNode: pHashNode);
  begin
    if pNode^.FCount = pNode^.FCurCount then
      DoPackageOK( nIndex, pParent, pNode );
  end;
begin
//0: ��ȷ
//1: �������Index����ȷ( UserID ���� )
//2: �ڴ治��( ���벻��HashNode )
//3: ������
//4: ANodeIndex ��������
  if ANodeIndex >= FPeenDataMaxCount then
  begin
    Result := 4;
    Exit;
  end;
  nIndex := AIndexKey mod (FHashTableCount - 1);
  if nIndex >= FHashTableCount then
  begin
    Result := 1;
    Exit;
  end;
  EnterCriticalSection( FLockMem );
  try
    p := FHashTable[nIndex];
    bFind := False;
    pParent :=  nil;
    while p <> nil do
    begin
      pParent := p;
      if (p^.FIndexKey = AIndexKey) and
         (p^.FContentKey = AContentKey) then
      begin
        bFind := True;
        Break;
      end;
      p := p^.FNext;
    end;

    if not bFind then //����ڵ�
    begin
      p := GetNewNodeAndInit;
      if p = nil then
      begin
        Result := 2;
        Exit;
      end;
      if pParent = nil then
        FHashTable[nIndex] := p
      else
        pParent^.FNext := p;
      CheckPackage( p );
    end
    else //���½ڵ�
    begin
      if (p^.FCount <> ANodeCount) then //��������Ҫһ��
      begin
        Result := 3;
        Exit;
      end;
      p^.FLastActiveTime := GetTickCount;
      if p^.FDataArray[ANodeIndex] = nil then
      begin
        p^.FDataArray[ANodeIndex] := pNode;
        Inc( p^.FCurCount );
      end;
      CheckPackage( p );
    end;
  finally
    LeaveCriticalSection( FLockMem );
  end;
  Result := 0;
end;

procedure TMulitNotify.CloseNotifyClass;
begin
  FreeAndNil( FCheckThread );
  FreeAndNil( FNotifyQueue );
  SetLength( FHashTable, 0 );
  FreeAndNil( FHashNodeMem );
  DeleteCriticalSection( FLockMem );
end;

procedure TMulitNotify.SetActive(const Value: Boolean);
begin
  if (FActive <> Value) then
  begin
    if Value then
      OpenNotifyClass
    else
      CloseNotifyClass;
    FActive := Value;
  end;
end;

procedure TMulitNotify.SetChectSpaceTime(const Value: Cardinal);
begin
  if (not Active) and (FCheckSpaceTime <> Value) then
    FCheckSpaceTime := Value;
end;

procedure TMulitNotify.SetHashTableCount(const Value: Cardinal);
begin
  if (not Active) and (FHashTableCount <> Value) then
    FHashTableCount := Value;
end;

procedure TMulitNotify.SetIsCheckThread(const Value: Boolean);
begin
  if (not Active) and (FIsCheckThread <> Value) then
    FIsCheckThread := Value;
end;

procedure TMulitNotify.SetMaxHashNodeCount(const Value: Cardinal);
begin
  if (not Active) and (Value <> FMaxHashNodeCount) then
    FMaxHashNodeCount := Value;
end;

procedure TMulitNotify.SetMaxWaitTime(const Value: Cardinal);
begin
  if (not Active) and (Value <> FMaxWaitTime) then
    FMaxWaitTime := Value;
end;

procedure TMulitNotify.SetNotifyThreadCount(const Value: Word);
begin
  if (not Active) and (FNotifyThreadCount <> Value) then
    FNotifyThreadCount := Value;
end;

procedure TMulitNotify.SetNotifyThreadSpaceTime(const Value: Cardinal);
begin
  if (not Active) and (FNotifyThreadSpaceTime <> Value) then
    FNotifyThreadSpaceTime := Value;
end;

procedure TMulitNotify.SetPeenDataMaxCount(const Value: Byte);
begin
  if (not Active) and (Value <> FPeenDataMaxCount) then
  begin
    FPeenDataMaxCount := Value;
    FHashNodeSize := SizeOf( THashNode ) + (FPeenDataMaxCount - 1) * 4;
  end;
end;

end.
