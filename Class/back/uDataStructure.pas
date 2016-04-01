{
��Ԫ����: uDataStructure
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ���ݽṹ����
��ʼʱ��: 2009-02-09
�޸�ʱ��: 2010-09-15 (����޸�)
ע������: ���̰߳�ȫ
��Ҫ��  :  THashArray

    THashArray
      key1 --> item1 --> item2 --> ...
      key2 --> item1 --> item2 --> ...
       .
       .
       .
UniquelyID�� ID�Ƿ���Ψһ�ģ����ΪTRUE�������е�����Ԫ��ID���ǲ���ͬ�ġ�

}

unit uDataStructure;

interface

uses
  Windows, SysUtils, uQueues;

type
  pHashNode = ^THashNode;
  THashNode = record
    FID: Cardinal;
    FData: Pointer;
    FNext: pHashNode;
  end;
const CtNodeSize = SizeOf(THashNode);

type
  TOnFindNode = procedure(Sender: TObject; const AParam, pData: Pointer; var ADel: Boolean; var AFindNext: Boolean) of object;
  TOnLoopNode = procedure(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean) of object;
  {$M+}
  THashArray = class
  public
    constructor Create; virtual;
    destructor  Destroy; override;

    {Add: ��ӽڵ�}
    function  Add(const AID: Cardinal; const AData: Pointer): Boolean;
    //UniquelyID = Falseʱ��Ӧ�����ô�Find���������ص�����IDΪ����ֵ�����нڵ�;
    //Result��ʾ�����ûص������Ĵ���; -1˵��û���ҵ�ָ��ID�Ľڵ�
    function  Find(const AID: Cardinal; const AFindCallBack: TOnFindNode; const AParamPointer: Pointer): Integer; overload;
    //UniquelyID = Tureʱ����������Find�������ɡ�����ֻ���ص�һ��IDΪ���õĽڵ�
    function  Find(const AID: Cardinal; var Ap: Pointer; const AIsDel: Boolean): Boolean; overload;
    //
    procedure Loop(const ALoopCallBack: TOnLoopNode);
  private
    FActive: Boolean;
    FHashTable: array of pHashNode;
    FHashTableCount: Cardinal;
    FHashNodeMem: TStaticMemoryManager;
    FMaxHashNodeCount: Cardinal;
    FCount: Cardinal;
    FTag: Cardinal;
    FUniquelyID: Boolean;
    FLastErrorCode: Integer;
    FLastErrorText: string;

    procedure ActiveHashArray;
    procedure UnActiveHashArray;
    function  IDToIndex(const AID: Cardinal): Integer;
    procedure DoNoActiveError;
    procedure DoNoGetMem;
    procedure DoExsitsIDError;
    procedure DoNotFindNode;
    
    procedure SetHashTableCount(const Value: Cardinal);
    procedure SetMaxHashNodeCount(const Value: Cardinal);
    procedure SetActive(const Value: Boolean);
    procedure SetAllowClash(const Value: Boolean);
  published
    property Active: Boolean read FActive write SetActive;
    property UniquelyID: Boolean read FUniquelyID write SetAllowClash;  //ID�Ƿ�Ψһ
    property Count: Cardinal read FCount;
    property HashTableCount: Cardinal read FHashTableCount write SetHashTableCount;
    property MaxHashNodeCount: Cardinal read FMaxHashNodeCount write SetMaxHashNodeCount;
    property Tag: Cardinal read FTag write FTag;
    property LastErrorCode: Integer read FLastErrorCode;
    property LastErrorText: string read FLastErrorText;
  end;
  {$M-}

  { ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ��Ź�����                               TIndexManage
    ��Ź���. 0 ~ 127

  } ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  TByteIndexManage = class
  private
    FByteList: array of Byte;
    FHead: Byte;
    FTail: Byte;
    FCount: Byte;
    FCapacity: Byte;
    FLock: TRTLCriticalSection;
    function  IsCanReclaim(const AIndex: Byte): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function  GetIndex(var AIndex: Byte): Boolean;
    procedure ReclaimIndex(const AIndex: Byte);
    property  Count: Byte read FCount;
  end;

  { ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ��Ź�����                               TIndexManage
    ��Ź���. 0 ~ MAXDOWRD

  } ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  TDwordIndexManage = class
  private
    FCardinalList: array of Cardinal;
    FHead: Cardinal;
    FTail: Cardinal;
    FCount: Cardinal;
    FCapacity: Cardinal;
    FLock: TRTLCriticalSection;
    function  IsCanReclaim(const AIndex: Cardinal): Boolean;
  public
    constructor Create(const AMaxCount: Cardinal; const ABeginPos: Cardinal = 1000);
    destructor Destroy; override;
    function  GetIndex(var AIndex: Cardinal): Boolean;
    procedure ReclaimIndex(const AIndex: Cardinal);
    property  Count: Cardinal read FCount;
  end;
implementation

{ TIndexManage }

constructor TByteIndexManage.Create;
var
  i: Byte;
begin
  FCapacity := 128;
  SetLength( FByteList, FCapacity );
  FHead := 0;
  FTail := 0;
  InitializeCriticalSection( FLock );
  for i := 1 to FCapacity do
    FByteList[i - 1] := i;
  FCount := FCapacity;
end;

destructor TByteIndexManage.Destroy;
begin
  SetLength( FByteList, 0 );
  DeleteCriticalSection( FLock );
  inherited;
end;

function TByteIndexManage.GetIndex(var AIndex: Byte): Boolean;
begin
  Result := False;
  EnterCriticalSection( FLock );
  try
    if FCount = 0 then Exit;
    AIndex := FByteList[ FHead ];
    FHead := ( FHead + 1 ) mod FCapacity;
    Dec( FCount );
    Result := True;
  finally
    LeaveCriticalSection( FLock );
  end;
end;

function TByteIndexManage.IsCanReclaim(const AIndex: Byte): Boolean;
var
  i: Byte;
begin
  Result := False;
  if FCount = FCapacity then Exit;
  i := FTail;
  while i <> FHead do
  begin
    if FByteList[i] = AIndex then
    begin
      Result := True;
      Break;
    end;
    i := (i + 1) mod FCapacity;
  end;
end;

procedure TByteIndexManage.ReclaimIndex(const AIndex: Byte);
begin
  EnterCriticalSection(FLock);
  try
    if FCount >= FCapacity then Exit;
    if IsCanReclaim(AIndex) then
    begin
      FByteList[FTail] := AIndex;
      FTail := (FTail + 1) mod FCapacity;
      Inc(FCount);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;


{ THashArray }

procedure THashArray.ActiveHashArray;
begin
  try
    SetLength( FHashTable, FHashTableCount );
    FHashNodeMem := TStaticMemoryManager.Create( CtNodeSize, FMaxHashNodeCount );
    FCount := 0;
    FLastErrorCode := 0;
    FLastErrorText := '';
    FActive := True;
  except
    if FHashTable <> nil then
    begin
      SetLength( FHashTable, 0 );
      FHashTable := nil;
    end;
    if FHashNodeMem <> nil then
      FreeAndNil( FHashNodeMem );
  end;
end;

function THashArray.Add(const AID: Cardinal; const AData: Pointer): Boolean;
var
  pNode, pClashNode: pHashNode;
  nIndex: Integer;
begin
  Result := False;
  if not Active then
  begin
    DoNoActiveError;
    Exit;
  end;
  nIndex := IDToIndex( AID );
  pNode := FHashTable[ nIndex ];
  if pNode = nil then
  begin
    if not FHashNodeMem.GetMem( Pointer(pNode) ) then
    begin
      DoNoGetMem;
      Exit;
    end;
    pNode^.FID := AID;
    pNode^.FData := AData;
    pNode^.FNext := nil;
    FHashTable[ nIndex ] := pNode;
  end
  else
  begin
    if UniquelyID then
    begin
      //IDΨһʱ��ȷ��Ҫ����Ľڵ㲻�������õ�ID
      while pNode <> nil do
      begin
        if pNode^.FID = AID then
        begin
          DoExsitsIDError;
          Exit;
        end;
        if pNode^.FNext = nil then
          Break
        else
          pNode := pNode^.FNext;
      end;
    end
    else
    begin
      while pNode^.FNext <> nil do
        pNode := pNode^.FNext;
    end;

    if not FHashNodeMem.GetMem( Pointer(pClashNode) ) then
    begin
      DoNoGetMem;
      Exit;
    end;
    pClashNode^.FID := AID;
    pClashNode^.FData := AData;
    pClashNode^.FNext := nil;
    pNode^.FNext := pClashNode;
  end;
  Result := True;
  Inc( FCount );
end;

constructor THashArray.Create;
begin
  FActive := False;
  FHashTableCount := 8 * 1024;
  FMaxHashNodeCount := 16 * 1024;
  FUniquelyID := True;
  FCount := 0;
  FHashNodeMem := nil;
  FHashTable := nil;
end;

destructor THashArray.Destroy;
begin
  Active := False;
  inherited;
end;

procedure THashArray.DoExsitsIDError;
begin
  FLastErrorCode := 3;
  FLastErrorText := 'ָ����ID�Ѿ����ڹ�ϣ����';
end;

procedure THashArray.DoNoActiveError;
begin
  FLastErrorCode := 1;
  FLastErrorText := '��Ҫ�ȼ���HashArray�������ʹ��( Active Ϊ False)';
end;

procedure THashArray.DoNoGetMem;
begin
  FLastErrorCode := 2;
  FLastErrorText := '�޷���������Ҫ���ڴ棬��ǰ�����ڴ��Ϊ: ' + IntToStr( FHashNodeMem.SpaceCount );
end;

procedure THashArray.DoNotFindNode;
begin
  FLastErrorCode := 4;
  FLastErrorText := '�Ҳ���ָ��ID�Ľڵ�';
end;

function THashArray.Find(const AID: Cardinal; var Ap: Pointer; const AIsDel: Boolean): Boolean;
var
  pNode, pParent: pHashNode;
  nIndex: Integer;
begin
  Result := False;
  if not Active then
  begin
    DoNoActiveError;
    Exit;
  end;
  nIndex := IDToIndex( AID );
  pNode := FHashTable[ nIndex ];
  pParent := nil;
  while pNode <> nil do
  begin
    if pNode^.FID = AID then
    begin
      Result := True;
      Break;
    end;
    pParent := pNode;
    pNode := pNode^.FNext;
  end;
  if not Result then
  begin
    DoNotFindNode;
    Exit;
  end;

  Ap := pNode^.FData;
  if AIsDel then
  begin
    if pParent = nil then
      FHashTable[ nIndex ] := pNode^.FNext
    else
      pParent^.FNext := pNode^.FNext;
    FHashNodeMem.FreeMem( pNode );
    Dec( FCount );
  end;
end;

function THashArray.Find(const AID: Cardinal; const AFindCallBack: TOnFindNode; const AParamPointer: Pointer): Integer;
var
  pNode, pParent: pHashNode;
  nIndex: Integer;
  bDel, bContinue: Boolean;
begin
  Result := -1;
  if not Active then
  begin
    DoNoActiveError;
    Exit;
  end;
  nIndex := IDToIndex( AID );
  pNode := FHashTable[ nIndex ];
  bContinue := True;
  pParent := nil;
  while bContinue and (pNode <> nil) do
  begin
    bDel := False;
    bContinue := True;

    if pNode^.FID = AID then
    begin
      AFindCallBack( Self, AParamPointer, pNode^.FData, bDel, bContinue );
      Inc( Result );
      if bDel then
      begin
        if pParent = nil then
        begin
          FHashTable[ nIndex ] := pNode^.FNext;
          FHashNodeMem.FreeMem( pNode );
          pNode := FHashTable[ nIndex ];
        end
        else
        begin
          pParent^.FNext := pNode^.FNext;
          FHashNodeMem.FreeMem( pNode );
          pNode := pParent^.FNext;
        end;
        Dec( FCount );
        Continue;
      end;
    end;
    pParent := pNode;
    pNode := pNode^.FNext;
  end;
end;

function THashArray.IDToIndex(const AID: Cardinal): Integer;
begin
  Result := AID mod (FHashTableCount - 1);
end;

procedure THashArray.Loop(const ALoopCallBack: TOnLoopNode);
var
  pNode, pParent: pHashNode;
  i: Integer;
  bDel, bContinue: Boolean;
begin
  if not Active then
  begin
    DoNoActiveError;
    Exit;
  end;

  for i := Low(FHashTable) to High(FHashTable) do
  begin
    bContinue := True;
    pParent := nil;
    pNode := FHashTable[i];
    while (pNode <> nil) and bContinue do
    begin
      bDel := False;
      bContinue := True;
      ALoopCallBack( Self, pNode^.FID, pNode^.FData, bDel, bContinue );
      if bDel then
      begin
        if pParent = nil then
        begin
          FHashTable[ i ] := pNode^.FNext;
          FHashNodeMem.FreeMem( pNode );
          pNode := FHashTable[ i ];
        end
        else
        begin
          pParent^.FNext := pNode^.FNext;
          FHashNodeMem.FreeMem( pNode );
          pNode := pParent^.FNext;
        end;
        Dec( FCount );
      end
      else
      begin
        pParent := pNode;
        pNode := pNode^.FNext;
      end;
    end;
  end;
end;

procedure THashArray.SetActive(const Value: Boolean);
begin
  if (FActive <> Value) then
  begin
    if Value then
      ActiveHashArray
    else
      UnActiveHashArray;
  end;
end;

procedure THashArray.SetAllowClash(const Value: Boolean);
begin
  if (not Active) and (FUniquelyID <> Value) then
    FUniquelyID := Value;
end;

procedure THashArray.SetHashTableCount(const Value: Cardinal);
begin
  if (not Active) and (FHashTableCount <> Value) then
    FHashTableCount := Value;
end;

procedure THashArray.SetMaxHashNodeCount(const Value: Cardinal);
begin
  if (not Active) and (Value <> FMaxHashNodeCount) then
    FMaxHashNodeCount := Value;
end;

procedure THashArray.UnActiveHashArray;
begin
  try
    FActive := False;
    SetLength( FHashTable, 0 );
    FreeAndNil( FHashNodeMem );
    FCount := 0;
  except
  end;
end;

{ TDwordIndexManage }

constructor TDwordIndexManage.Create(const AMaxCount: Cardinal; const ABeginPos: Cardinal);
var
  i: Cardinal;
begin
  FCapacity := AMaxCount;
  SetLength( FCardinalList, FCapacity );
  FHead := 0;
  FTail := 0;
  InitializeCriticalSection( FLock );
  for i := 0 to FCapacity - 1 do
    FCardinalList[i] := ABeginPos + i;
  FCount := FCapacity;
end;

destructor TDwordIndexManage.Destroy;
begin
  SetLength( FCardinalList, 0 );
  DeleteCriticalSection( FLock );
  inherited;
end;

function TDwordIndexManage.GetIndex(var AIndex: Cardinal): Boolean;
begin
  Result := False;
  EnterCriticalSection( FLock );
  try
    if FCount = 0 then Exit;
    AIndex := FCardinalList[ FHead ];
    FHead := ( FHead + 1 ) mod FCapacity;
    Dec( FCount );
    Result := True;
  finally
    LeaveCriticalSection( FLock );
  end;
end;

function TDwordIndexManage.IsCanReclaim(const AIndex: Cardinal): Boolean;
var
  i: Cardinal;
begin
  Result := False;
  if FCount = FCapacity then Exit;
  i := FTail;
  while i <> FHead do
  begin
    if FCardinalList[i] = AIndex then
    begin
      Result := True;
      Break;
    end;
    i := (i + 1) mod FCapacity;
  end;
end;

procedure TDwordIndexManage.ReclaimIndex(const AIndex: Cardinal);
begin
  EnterCriticalSection(FLock);
  try
    if FCount >= FCapacity then Exit;
    if IsCanReclaim(AIndex) then
    begin
      FCardinalList[FTail] := AIndex;
      FTail := (FTail + 1) mod FCapacity;
      Inc(FCount);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

end.
