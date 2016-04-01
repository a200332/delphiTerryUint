{
��Ԫ����: uJxdDataStruct
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ���ݽṹ����
��ʼʱ��: 2009-02-09
�޸�ʱ��: 2010-09-15 (����޸�)
ע������: ���̰߳�ȫ
��Ҫ��  :  THashArrayBasic, THashArray

THashArrayBasic: �����ڴ�, ���� HashTable��HashNodeMem ���๲ͬ��Ҫ�ķ���
  -- THashArray: �������ݣ�ID�ǲ����ظ���
  -- THashArrayEx: ID�ǿ��ظ���
    THashArray
      key1 --> item1 --> item2 --> ...
      key2 --> item1 --> item2 --> ...
       .
       .
       .
}
unit uJxdDataStruct;

interface
uses
  Windows, SysUtils, uJxdMemoryManage;

type
  PHashNode = ^THashNode;
  THashNode = record
  private
    FID: Cardinal;
    FData: Pointer;
    FNext: pHashNode;
  public
    property NodeID: Cardinal read FID;
    property NodeData: Pointer read FData;
    property Next: PHashNode read FNext;
  end;
  TOnLoopNode = procedure(Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean) of object;
  TOnLoopNodeEx = procedure(const AParamNode: Pointer; Sender: TObject; const AID: Cardinal; pData: Pointer; var ADel: Boolean; var AFindNext: Boolean) of object;
{$M+}
  THashArrayBasic = class
  public
    constructor Create; virtual;
    destructor  Destroy; override;

    {ѭ������}
    procedure Loop(const ALoopCallBack: TOnLoopNode); overload;
    procedure Loop(const ALoopCallBack: TOnLoopNodeEx; const AParamNode: Pointer); overload;
  protected
    FFirstNodeIndex: Integer;
    FHashTable: array of pHashNode;
    FHashNodeMem: TxdFixedMemoryManager;
    function  ActiveHashArray: Boolean; virtual;
    procedure UnActiveHashArray; virtual;
    procedure CheckFirstNodeIndex(const ACompIndex: Integer); inline;
  private
    FActive: Boolean;
    FHashTableCount: Cardinal;
    FMaxHashNodeCount: Cardinal;
    procedure SetActive(const Value: Boolean);
    procedure SetHashTableCount(const Value: Cardinal);
    procedure SetMaxHashNodeCount(const Value: Cardinal);
    function  GetCount: Integer;
  published
    property Active: Boolean read FActive write SetActive;
    property HashTableCount: Cardinal read FHashTableCount write SetHashTableCount; //Hash��, �Զ�����趨ֵ���������
    property MaxHashNodeCount: Cardinal read FMaxHashNodeCount write SetMaxHashNodeCount; //Hash�ڵ���
    property Count: Integer read GetCount; //��ǰ�洢����
  end;

  THashArray = class(THashArrayBasic)
  public
    {��ӽڵ�}
    function Add(const AID: Cardinal; const AData: Pointer): Boolean;
    {����ָ���ڵ㣬��ָ���Ƿ�ɾ��}
    function Find(const AID: Cardinal; var Ap: Pointer; const AIsDel: Boolean): Boolean;
  protected
    function IDToIndex(const AID: Cardinal): Integer; inline;
  end;

  THashArrayEx = class(THashArrayBasic)
  public
    constructor Create; override;
    {��ӽڵ�}
    function  Add(const AID: Cardinal; const AData: Pointer): Boolean;
    {����ָ���ڵ� Find�ຯ����ƥ����� FindBegin FindEnd ��Ҫ��Ӧ����}
    function  FindBegin(const AID: Cardinal): PHashNode; //���ص�һ��ID��ͬ�Ľڵ�
    function  FindNext(const pNode: PHashNode): PHashNode; //������һ����pNode��ID��ͬ�Ľڵ�
    procedure FindDelete(const ANode: PHashNode); //ɾ��ָ���Ľڵ�
    procedure FindEnd;
  protected
    function IDToIndex(const AID: Cardinal): Integer; inline;
  private
    FFindIndex: Integer;
    FFindPreNode: PHashNode;
  end;
{$M-}

implementation

{ THashArray }
const
  CtNodeSize = SizeOf(THashNode);

function THashArray.Add(const AID: Cardinal; const AData: Pointer): Boolean;
var
  pNode, pParentNode: pHashNode;
  nIndex: Integer;
begin
  Result := False;
  if not Active then
  begin
    OutputDebugString( 'Do not Active' );
    Exit;
  end;
  nIndex := IDToIndex(AID);
  pParentNode := FHashTable[nIndex];
  if Assigned(pParentNode) then
  begin
    while True do
    begin
      if pParentNode^.FID = AID then
      begin
        //�����Ѿ�����ָ��ID, ֱ���˳�
        OutputDebugString( 'ID is Exists' );
        Exit;
      end;
      if Assigned(pParentNode^.FNext) then
        pParentNode := pParentNode^.FNext
      else
        Break;
    end;
  end;
  if not FHashNodeMem.GetMem(Pointer(pNode)) then
  begin
    OutputDebugString( 'Do not Get Memory' );
    Exit;
  end;
  pNode^.FID := AID;
  pNode^.FData := AData;
  pNode^.FNext := nil;
  if Assigned(pParentNode) then
    pParentNode^.FNext := pNode
  else
    FHashTable[nIndex] := pNode;

  CheckFirstNodeIndex( nIndex );
  Result := True;
end;

function THashArray.Find(const AID: Cardinal; var Ap: Pointer; const AIsDel: Boolean): Boolean;
var
  pNode, pParent: pHashNode;
  nIndex: Integer;
begin
  Result := False;
  Ap := nil;
  if not Active then
  begin
    OutputDebugString( 'Do not active' );
    Exit;
  end;
  nIndex := IDToIndex(AID);
  pNode := FHashTable[nIndex];
  pParent := nil;
  if Assigned(pNode) then
  begin
    while True do
    begin
      if pNode^.FID = AID then
      begin
        Result := True;
        Ap := pNode^.FData;
        if AIsDel then
        begin
          if Assigned(pParent) then
            pParent^.FNext := pNode^.FNext
          else
            FHashTable[nIndex] := pNode^.FNext;
          FHashNodeMem.FreeMem( pNode );
        end;
        Break;
      end;
      pParent := pNode;
      if Assigned(pNode^.FNext) then
        pNode := pNode^.FNext
      else
        Break;
    end;
  end;
end;

function THashArray.IDToIndex(const AID: Cardinal): Integer;
begin
  Result := AID mod FHashTableCount;
end;

{ THashArrayBasic }

function THashArrayBasic.ActiveHashArray: Boolean;
begin
  try
    SetLength(FHashTable, FHashTableCount);
    FHashNodeMem := TxdFixedMemoryManager.Create(CtNodeSize, FMaxHashNodeCount);
    FFirstNodeIndex := FHashTableCount - 1;
    Result := True;
  except
    if FHashTable <> nil then
    begin
      SetLength(FHashTable, 0);
      FHashTable := nil;
    end;
    if FHashNodeMem <> nil then
      FreeAndNil(FHashNodeMem);
    Result := False;
  end;
end;

procedure THashArrayBasic.CheckFirstNodeIndex(const ACompIndex: Integer);
begin
  if FFirstNodeIndex > ACompIndex then
    FFirstNodeIndex := ACompIndex;
end;

constructor THashArrayBasic.Create;
begin
  FHashTableCount := 131313;
  FMaxHashNodeCount := 1024 * 512;
  FHashNodeMem := nil;
  FHashTable := nil;
  FActive := False;
  FFirstNodeIndex := FHashTableCount - 1;
end;

destructor THashArrayBasic.Destroy;
begin
  Active := False;
  inherited;
end;

function THashArrayBasic.GetCount: Integer;
begin
  if Active then
    Result := FHashNodeMem.Capacity - FHashNodeMem.Count
  else
    Result := 0;
end;

procedure THashArrayBasic.Loop(const ALoopCallBack: TOnLoopNodeEx; const AParamNode: Pointer);
var
  pNode, pParent: pHashNode;
  i, nCount, nAryLen: Integer;
  bDel, bContinue: Boolean;
begin
  if not Active then
  begin
    OutputDebugString( 'Do not Active' );
    Exit;
  end;

  nCount := Count;
  if nCount = 0 then Exit;
  nAryLen := Length(FHashTable);
  for i := FFirstNodeIndex to nAryLen - 1 do
  begin
    if nCount = 0 then Exit;
    bContinue := True;
    pParent := nil;
    pNode := FHashTable[i];
    while (pNode <> nil) and bContinue do
    begin
      if nCount = 0 then Exit;
      bDel := False;
      bContinue := True;
      ALoopCallBack(AParamNode, Self, pNode^.FID, pNode^.FData, bDel, bContinue);
      Dec( nCount );
      if bDel then
      begin
        if pParent = nil then
        begin
          FHashTable[i] := pNode^.FNext;
          FHashNodeMem.FreeMem(pNode);
          pNode := FHashTable[i];
        end
        else
        begin
          pParent^.FNext := pNode^.FNext;
          FHashNodeMem.FreeMem(pNode);
          pNode := pParent^.FNext;
        end;
      end
      else
      begin
        pParent := pNode;
        pNode := pNode^.FNext;
      end;
    end;
  end;
end;

procedure THashArrayBasic.Loop(const ALoopCallBack: TOnLoopNode);
var
  pNode, pParent: pHashNode;
  i, nCount, nAryLen: Integer;
  bDel, bContinue: Boolean;
begin
  if not Active then
  begin
    OutputDebugString( 'Do not Active' );
    Exit;
  end;

  nCount := Count;
  if nCount = 0 then Exit;
  nAryLen := Length(FHashTable);
  for i := FFirstNodeIndex to nAryLen - 1 do
  begin
    if nCount = 0 then Exit;
    bContinue := True;
    pParent := nil;
    pNode := FHashTable[i];
    while (pNode <> nil) and bContinue do
    begin
      if nCount = 0 then Exit;
      bDel := False;
      bContinue := True;
      ALoopCallBack(Self, pNode^.FID, pNode^.FData, bDel, bContinue);
      Dec( nCount );
      if bDel then
      begin
        if pParent = nil then
        begin
          FHashTable[i] := pNode^.FNext;
          FHashNodeMem.FreeMem(pNode);
          pNode := FHashTable[i];
        end
        else
        begin
          pParent^.FNext := pNode^.FNext;
          FHashNodeMem.FreeMem(pNode);
          pNode := pParent^.FNext;
        end;
      end
      else
      begin
        pParent := pNode;
        pNode := pNode^.FNext;
      end;
    end;
  end;
end;

procedure THashArrayBasic.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
      FActive := ActiveHashArray
    else
    begin
      FActive := Value;
      UnActiveHashArray;
    end;
  end;
end;

procedure THashArrayBasic.SetHashTableCount(const Value: Cardinal);
begin
  if not Active then
  begin
    FHashTableCount := Value;
    FFirstNodeIndex := FHashTableCount - 1;
  end;
end;

procedure THashArrayBasic.SetMaxHashNodeCount(const Value: Cardinal);
begin
  if not Active then
    FMaxHashNodeCount := Value;
end;

procedure THashArrayBasic.UnActiveHashArray;
begin
  try
    SetLength(FHashTable, 0);
    FreeAndNil(FHashNodeMem);
  except
  end;
end;

{ THashArrayEx }

function THashArrayEx.Add(const AID: Cardinal; const AData: Pointer): Boolean;
var
  pNode, pParentNode: pHashNode;
  nIndex: Integer;
begin
  Result := False;
  if not Active then
  begin
    OutputDebugString( 'Do not Active' );
    Exit;
  end;
  nIndex := IDToIndex(AID);
  pParentNode := FHashTable[nIndex];
  if not FHashNodeMem.GetMem(Pointer(pNode)) then
  begin
    OutputDebugString( 'Do not Get Memory' );
    Exit;
  end;
  pNode^.FID := AID;
  pNode^.FData := AData;
  pNode^.FNext := nil;
  
  if Assigned(pParentNode) then
  begin
    while Assigned(pParentNode^.FNext) do
      pParentNode := pParentNode^.FNext;
  end;

  if Assigned(pParentNode) then
    pParentNode^.FNext := pNode
  else
    FHashTable[nIndex] := pNode;
  CheckFirstNodeIndex( nIndex );
  Result := True;
end;

constructor THashArrayEx.Create;
begin
  inherited;
  FFindIndex := -1;
end;

function THashArrayEx.FindBegin(const AID: Cardinal): PHashNode;
var
  p: PHashNode;
begin
  Result := nil;
  if FFindIndex <> -1 then
  begin
    OutputDebugString( 'Must call FindEnd first' );
    Exit;
  end;
  FFindIndex := IDToIndex( AID );
  FFindPreNode := FHashTable[FFindIndex];
  p := FFindPreNode;
  while Assigned(p) do
  begin
    if p^.FID = AID then
    begin
      Result := p;
      Break;
    end;
    FFindPreNode := p;
    p := p^.FNext;
  end;
end;

procedure THashArrayEx.FindDelete(const ANode: PHashNode);
var
  nIndex: Integer;
begin
  if not Assigned(ANode) then Exit;
  if (FFindIndex = -1) or (not Assigned(FFindPreNode)) then
  begin
    OutputDebugString( 'Must call FindEnd first' );
    Exit;
  end;
  nIndex := IDToIndex( ANode^.FID );
  if nIndex <> FFindIndex then
  begin
    OutputDebugString( 'No the same find, call FindEnd and FindBegin first' );
    Exit;
  end;
  //ɾ����ʼ
  if FFindPreNode = ANode then
  begin
    //��һ���ڵ�
    FHashTable[FFindIndex] := FFindPreNode^.FNext;
  end
  else
  begin
    //�����ڵ�
    FFindPreNode^.FNext := ANode^.FNext;
  end;
  FHashNodeMem.FreeMem( ANode );
end;

procedure THashArrayEx.FindEnd;
begin
  FFindIndex := -1;
end;

function THashArrayEx.FindNext(const pNode: PHashNode): PHashNode;
var
  p: PHashNode;
begin
  Result := nil;
  if not Assigned(pNode) then Exit;
  p := pNode^.FNext;
  FFindPreNode := pNode;
  while Assigned(p) do
  begin
    if p^.FID = pNode^.FID then
    begin
      Result := p;
      Break;
    end;
    FFindPreNode := p;
    p := p^.FNext;
  end;
end;

function THashArrayEx.IDToIndex(const AID: Cardinal): Integer;
begin
  Result := AID mod FHashTableCount;
end;

end.

