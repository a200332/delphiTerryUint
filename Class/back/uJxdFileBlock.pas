{
��Ԫ����: uJxdFileBlock
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ���ļ����зֿ鴦�����Էֿ�����������,���ض����ļ����ͽ������Ż����أ���֤ý�岥���ٶ�
��ʼʱ��: 2010-10-26
�޸�ʱ��: 2011-01-10 (����޸�)

    �ֿ��ļ���Ҫ�ṩ��������ʹ�ã���һ�ǣ����ز��֣��ڶ��ǣ����Ų��֣�Ϊ�������м�Ŧ��
    
    �ֿ鷽ʽ��
        ˳��ֿ飨��ͷ�µ�β��

    ���̰߳�ȫ

    �ֿ��ļ���¼���
    �汾��(2)
    �ļ���С(8)
    �ֿ��С(4)
    �ֿ�����(4)
    [ TSegmentBlockInfo1 ]
    [ TSegmentBlockInfo2 ]...
}

unit uJxdFileBlock;

interface

uses
  Windows, Classes, SysUtils, uJxdDataStream, uJxdMemoryManage;

type
  TSegmentState = ( ssEmpty, ssWaitReply, ssComplete );
  PSegmentBlockInfo = ^TSegmentBlockInfo;
  TSegmentBlockInfo = record
  private
    FBeginPosition: Int64;    //�ֿ����ļ��е�λ��
    FIndex: Cardinal;         //�ֿ����
    FSegmentSize: Cardinal;   //�˷ֿ�Ĵ�С
    FActiveTime: Cardinal;    //�������ʱ��
    FSegmentState: TSegmentState;      //�˷ֿ��Ƿ��Ѿ����
  public
    property BeginPosition: Int64 read FBeginPosition;
    property Index: Cardinal read FIndex;
    property SegmentSize: Cardinal read FSegmentSize;
    property ActiveTime: Cardinal read FActiveTime;
    property SegmentState: TSegmentState read FSegmentState;
  end;
  
  TxdFileBlock = class
  {$M+}
  public
    //AFileName: �����ļ���ȫ·����AFileSize: �ļ���С; AFileSize: ��Ҫ�ֿ���ļ���С;
    constructor Create(const AFileName: string; const AFileSize: Int64; const ABlockSize: Cardinal);
    destructor  Destroy; override;

    //��ʼ�����������ز���
    function  InitPrioritySegment(const ABeginPos: Int64; const ASize: Cardinal): Boolean; //�ɶ�ε���
    procedure CheckPriorityPosition(const APercent: Double); //����ʱ�϶���Ҫ���ô˺��������п��ٲ���
    
    function  GetSegmentInfo: PSegmentBlockInfo;            //��ȡ�ʺϵ�����λ��
    function  CompleteSegmentHandle(const APosition: Int64; const ASize: Cardinal): Boolean; //������غ����

    function  CheckCanRead(const APosition: Int64; const ASize: Cardinal): Boolean; //�ж�ָ��λ���Ƿ�ɶ�
    function  CheckPriorityFinished: Boolean; //��������λ���Ƿ���������ɣ����֮��ſɲ���ý���ļ�

    function DestFileSize: Int64;
    function SegmentCount: Integer;
    function SegmentBlockSize: Cardinal;
    function SegmentItem(const AIndex: Integer): PSegmentBlockInfo;
  private
    FSegmentBlockList: TList;
    FInitPrioritySegmentList: TList;
    FRunningPrioritySegmentList: TList;
    FWaitReplySegmentList: TList;

    FFileSize: Int64;
    FLock: TRTLCriticalSection;
    FBlockSize: Cardinal;
    FFileName: string;
    FFileCompleted: Boolean;
    FCurEmptyIndex: Integer;
    FPriorityIndex: Integer; //��ǰ��Ҫ������� ����ʱ�϶�����

    FSegmentManage: TxdFixedMemoryManager;
    FOnCompleted: TNotifyEvent;
    FFinishedByteCount: Int64;
    procedure LockSegment(const ALock: Boolean);
    procedure InitSegmentBlockInfo;
    procedure LoadFromFile;
    procedure SaveToFile;
    procedure ClearList;
    procedure DoCompleted;    //�ļ��ֿ鴦�����
    procedure AddToList(const AList: TList; const AData: Pointer);
    function  DeleteFormList(const AList: TList; const AData: Pointer): Boolean;
  published
    property FinishedByteCount: Int64 read FFinishedByteCount;
    property IsFileCompleted: Boolean read FFileCompleted;
    property OnCompleted: TNotifyEvent read FOnCompleted write FOnCompleted;
  end;
  {$M-}

implementation

const
  CtSegmentVersion: Word = 1000;
  CtSegmentBlockInfoSize = SizeOf(TSegmentBlockInfo);

{ TxdFileBlcok }

procedure TxdFileBlock.AddToList(const AList: TList; const AData: Pointer);
begin
  if AList.IndexOf(AData) = -1 then
    AList.Add( AData );
end;

function TxdFileBlock.CheckCanRead(const APosition: Int64; const ASize: Cardinal): Boolean;
var
  i, nIndex, nCount: Integer;
  p: PSegmentBlockInfo;
begin
  nIndex := APosition div FBlockSize;
  nCount := (APosition + ASize + FBlockSize - 1) div FBlockSize;
  Result := True;
  LockSegment( True );
  try
    for i := nIndex to nCount - 1 do
    begin
      p := FSegmentBlockList[i];
      if p^.FSegmentState <> ssComplete then
      begin
        Result := False;
        AddToList( FRunningPrioritySegmentList, p );
      end;
    end;
  finally
    LockSegment( False );
  end;
end;

function TxdFileBlock.CheckPriorityFinished: Boolean;
begin
  Result := not Assigned( FInitPrioritySegmentList );
end;

procedure TxdFileBlock.ClearList;
var
  i: Integer;
  p: PSegmentBlockInfo;
begin
  if Assigned(FSegmentBlockList) and Assigned(FSegmentManage) then
  begin
    for i := 0 to FSegmentBlockList.Count - 1 do
    begin
      p := FSegmentBlockList[i];
      FSegmentManage.FreeMem( p );
    end;
    FSegmentBlockList.Clear;
  end;
end;

function TxdFileBlock.CompleteSegmentHandle(const APosition: Int64; const ASize: Cardinal): Boolean;
var
  nIndex: Integer;
  p: PSegmentBlockInfo;
begin
  Result := False;
  nIndex := APosition div FBlockSize;
  LockSegment( True );
  try
    p := SegmentItem( nIndex );
    if Assigned(p) then
    begin
      if (p^.FBeginPosition = APosition) and (p^.FSegmentSize = ASize) and (p^.FSegmentState <> ssComplete) then
      begin
        p^.FSegmentState := ssComplete;
        FFinishedByteCount := FFinishedByteCount + ASize;
        Result := True;
        DeleteFormList( FWaitReplySegmentList, p );
        DeleteFormList( FRunningPrioritySegmentList, p );
        if Assigned(FInitPrioritySegmentList) then
        begin
          if DeleteFormList(FInitPrioritySegmentList, p) then
          begin
            if FInitPrioritySegmentList.Count = 0 then
              FreeAndNil( FInitPrioritySegmentList );
          end;
        end;
          
        while nIndex = FCurEmptyIndex do
        begin
          Inc( FCurEmptyIndex );
          p := SegmentItem( nIndex + 1 );
          if Assigned(p) and (p^.FSegmentState = ssComplete) then
            Inc( nIndex );
        end;
        if FCurEmptyIndex = FSegmentBlockList.Count then
          DoCompleted;
      end;
    end;
  finally
    LockSegment( False );
  end;
end;

constructor TxdFileBlock.Create(const AFileName: string; const AFileSize: Int64; const ABlockSize: Cardinal);
begin
  InitializeCriticalSection( FLock );
  FFileName := AFileName;
  FFileSize := AFileSize;
  FBlockSize := ABlockSize;
  FSegmentManage := nil;
  FSegmentBlockList := nil;
  FInitPrioritySegmentList := nil;
  FFileCompleted := False;
  FPriorityIndex := 0;
  FFinishedByteCount := 0;
  FWaitReplySegmentList := TList.Create;
  FRunningPrioritySegmentList := TList.Create;
  if FileExists(AFileName) then
    LoadFromFile
  else
    InitSegmentBlockInfo;
end;

function TxdFileBlock.DeleteFormList(const AList: TList; const AData: Pointer): Boolean;
var
  nIndex: Integer;
begin
  nIndex := AList.IndexOf( AData );
  Result := nIndex <> -1;
  if Result then
    AList.Delete( nIndex );
end;

function TxdFileBlock.DestFileSize: Int64;
begin
  Result := FFileSize;
end;

destructor TxdFileBlock.Destroy;
begin
  if not FFileCompleted then
    SaveToFile;
  FreeAndNil( FSegmentBlockList );
  FreeAndNil( FSegmentManage );
  FreeAndNil( FInitPrioritySegmentList );
  FreeAndNil( FWaitReplySegmentList );
  FreeAndNil( FRunningPrioritySegmentList );
  DeleteCriticalSection( FLock );
  inherited;
end;

procedure TxdFileBlock.DoCompleted;
begin
  FFileCompleted := True;
  if FileExists(FFileName) then
    DeleteFile( FFileName );
  if Assigned(OnCompleted) then
    OnCompleted( Self );
end;

function TxdFileBlock.GetSegmentInfo: PSegmentBlockInfo;
  function GetSegmentFormList(const AList: TList; const ABeginIndex: Integer = 0): PSegmentBlockInfo;
  var
    i: Integer;
    p: PSegmentBlockInfo;
  begin
    Result := nil;
    for i := ABeginIndex to AList.Count - 1 do
    begin
      p := AList[i];
      if p^.FSegmentState = ssEmpty then
      begin
        p^.FActiveTime := GetTickCount;
        p^.FSegmentState := ssWaitReply;
        Result := p;
        FWaitReplySegmentList.Add( p );
        Break;
      end;
    end;
  end;
var
  i: Integer;
  p: PSegmentBlockInfo;
begin
  LockSegment( True );
  try
    //��һ����
    if Assigned(FInitPrioritySegmentList) then
    begin
      Result := GetSegmentFormList( FInitPrioritySegmentList );
      if Assigned(Result) then Exit;
    end;

    //�ڶ�����
    Result := GetSegmentFormList( FRunningPrioritySegmentList );
    if Assigned(Result) then Exit;
    
    
    //��������
    for i := FPriorityIndex to FSegmentBlockList.Count - 1 do
    begin
      p := FSegmentBlockList[i];
      if p^.FSegmentState = ssEmpty then
      begin
        p^.FActiveTime := GetTickCount;
        p^.FSegmentState := ssWaitReply;
        Result := p;
        Exit;
      end;
    end;
    //ƽ��
    Result := GetSegmentFormList( FSegmentBlockList, FCurEmptyIndex );
  finally
    LockSegment( False );
  end;
end;

function TxdFileBlock.InitPrioritySegment(const ABeginPos: Int64; const ASize: Cardinal): Boolean;
var
  i, nCount: Integer;
begin
  Result := (ABeginPos >= 0) and (ABeginPos + ASize <= FFileSize );
  if Result then
  begin
    if not Assigned(FInitPrioritySegmentList) then
      FInitPrioritySegmentList := TList.Create;
    nCount := (ABeginPos + ASize) div FBlockSize;
    for i := ABeginPos div FBlockSize to nCount do
      AddToList( FInitPrioritySegmentList, FSegmentBlockList[i] );
  end;
end;

procedure TxdFileBlock.InitSegmentBlockInfo;
var
  i, nSegmentCount: Integer;
  p: PSegmentBlockInfo;
  nFileSize: Int64;
begin
  if FFileSize = -1 then
    raise Exception.Create( 'file sie is -1' );
  nSegmentCount := (FFileSize + FBlockSize - 1) div FBlockSize;

  FreeAndNil( FSegmentManage );
  FreeAndNil( FSegmentBlockList );

  FSegmentManage := TxdFixedMemoryManager.Create( CtSegmentBlockInfoSize, nSegmentCount );
  FSegmentBlockList := TList.Create;
  nFileSize := FFileSize;
  FCurEmptyIndex := 0;
  for i := 0 to nSegmentCount - 1 do
  begin
    FSegmentManage.GetMem( Pointer(p) );
    p^.FIndex := i;
    p^.FBeginPosition := p^.FIndex * FBlockSize;
    p^.FSegmentState := ssEmpty;
    p^.FActiveTime := 0;
    if nFileSize > FBlockSize then
      p^.FSegmentSize := FBlockSize
    else
      p^.FSegmentSize := nFileSize;
    FSegmentBlockList.Add( p );
    Dec( nFileSize, p^.FSegmentSize );
  end;
end;

procedure TxdFileBlock.LoadFromFile;
{
�ֿ��ļ���¼���
    �汾��(2)
    �ļ���С(8)
    �ֿ��С(4)
    �ֿ�����(4)
    [ TSegmentBlockInfo1 ]
    [ TSegmentBlockInfo2 ]...
}
const
  CtConfigFileHeadSize = 18;
var
  Stream: TxdFileStream;
  nSegmentSize: Cardinal;
  i, nSegmentCount, nIndex: Integer;
  p: PSegmentBlockInfo;
  nSize: Int64;
begin
  ClearList;
  Stream := TxdFileStream.Create( FFileName, fmOpenRead );
  try
    with Stream do
    begin
      Position := 0;
      if (Size <= CtConfigFileHeadSize) or
         (ReadWord <> CtSegmentVersion) then
      begin
        //�����ļ�������ļ��汾���Ի��ļ���С����ͬ
        InitSegmentBlockInfo;
        Exit;
      end;
      nSize := ReadInt64;
      if FFileSize <= 0 then
        FFileSize := nSize
      else if FFileSize <> nSize then
      begin
        InitSegmentBlockInfo;
        Exit;
      end;
      nSegmentSize := ReadCardinal;
      nSegmentCount := ReadInteger;
      if Size <> (CtConfigFileHeadSize + CtSegmentBlockInfoSize * nSegmentCount) then
      begin
        //�����ļ�����
        InitSegmentBlockInfo;
        Exit;
      end;
      if Assigned(FSegmentManage) and
         ( (FSegmentManage.Count <> Cardinal(nSegmentCount)) or
           (FSegmentManage.BlockSize <> CtSegmentBlockInfoSize) ) then
      begin
        FreeAndNil( FSegmentManage );
      end;
      if not Assigned(FSegmentManage) then
        FSegmentManage := TxdFixedMemoryManager.Create( CtSegmentBlockInfoSize, nSegmentCount );
      if not Assigned(FSegmentBlockList) then
        FSegmentBlockList := TList.Create;
      FBlockSize := nSegmentSize;
      FCurEmptyIndex := MaxInt;
      FFileCompleted := True;
      FFinishedByteCount := 0;
      for i := 0 to nSegmentCount - 1 do
      begin
        FSegmentManage.GetMem( Pointer(p) );
        ReadLong( p^, CtSegmentBlockInfoSize );
        p^.FActiveTime := 0;
        nIndex := FSegmentBlockList.Add( p );
        if p^.FSegmentState = ssComplete then
          FFinishedByteCount := FFinishedByteCount + p^.FSegmentSize
        else
          p^.FSegmentState := ssEmpty;
          
        if p^.FSegmentState = ssEmpty then
        begin
          if nIndex < FCurEmptyIndex then
            FCurEmptyIndex := nIndex;
          FFileCompleted := False;
        end;

      end;
    end;
  finally
    Stream.Free;
  end;
end;

procedure TxdFileBlock.LockSegment(const ALock: Boolean);
begin
  if ALock then
    EnterCriticalSection( FLock )
  else
    LeaveCriticalSection( FLock );
end;

procedure TxdFileBlock.SaveToFile;
var
  Stream: TxdFileStream;
  i, nCount: Integer;
  p: PSegmentBlockInfo;
begin
  Stream := TxdFileStream.Create( FFileName, fmCreate );
  try
    with Stream do
    begin
      WriteWord( CtSegmentVersion );
      WriteInt64( FFileSize );
      WriteCardinal( FBlockSize );
      nCount := FSegmentBlockList.Count;
      WriteInteger( nCount );
      for i := 0 to nCount - 1 do
      begin
        p := FSegmentBlockList[i];
        if p^.FSegmentState <> ssComplete then
          p^.FSegmentState := ssEmpty;
        WriteLong( p^, CtSegmentBlockInfoSize );
      end;
    end;
  finally
    Stream.Free;
  end;
end;

function TxdFileBlock.SegmentBlockSize: Cardinal;
begin
  Result := FBlockSize;
end;

function TxdFileBlock.SegmentCount: Integer;
begin
  if Assigned(FSegmentBlockList) then
    Result := FSegmentBlockList.Count
  else
    Result := 0;
end;

function TxdFileBlock.SegmentItem(const AIndex: Integer): PSegmentBlockInfo;
begin
  Result := nil;
  if Assigned(FSegmentBlockList) and (AIndex >= 0) and (AIndex < FSegmentBlockList.Count) then
    Result := FSegmentBlockList[AIndex];  
end;

procedure TxdFileBlock.CheckPriorityPosition(const APercent: Double);
begin
  FPriorityIndex := Round( APercent * FSegmentBlockList.Count );
  if FPriorityIndex < 0 then
  begin
    OutputDebugString( 'eror' );
    FPriorityIndex := 0;
  end
  else if FPriorityIndex >= FSegmentBlockList.Count then
  begin
    OutputDebugString( 'eror' );
    FPriorityIndex := FSegmentBlockList.Count - 1;
  end;
end;

end.
