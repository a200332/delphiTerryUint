{
��Ԫ����: uJxdFileBlock
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ���ļ����зֿ鴦�����Էֿ�����������,���ض����ļ����ͽ������Ż����أ���֤ý�岥���ٶ�
��ʼʱ��: 2010-10-26
�޸�ʱ��: 2010-10-27 (����޸�)

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
  Windows, Classes, SysUtils, uJxdDataStream, uJxdMemoryManage, uJxdPlayerConsts;

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

    function  GetSegmentInfo: PSegmentBlockInfo;            //��ȡ�ʺϵ�����λ��
    function  CompleteSegmentHandle(const APosition: Int64; const ASize: Cardinal): Boolean; //������غ����
    function  CheckCanRead(const APosition: Int64; const ASize: Cardinal): Boolean; //�ж�ָ��λ���Ƿ�ɶ�
    function  CheckPriorityFinished: Boolean; //��������λ���Ƿ���������ɣ����֮��ſɲ���ý���ļ�
    procedure SetMainDownPosition(const APercent: Double); //����ʱ�϶���Ҫ���ô˺��������п��ٲ���

    function IsFirst: Boolean;
    function DestFileSize: Int64;

    function SegmentCount: Integer;
    function SegmentBlockSize: Cardinal;
    function SegmentItem(const AIndex: Integer): PSegmentBlockInfo;
  private
    FIsFirst: Boolean;
    FMusicStyle: TMusicStyle;
    FFileSize: Int64;
    FLock: TRTLCriticalSection;
    FBlockSize: Cardinal;
    FFileName: string;
    FFileCompleted: Boolean;
    FEmptyListIndex, FEmptyLastListIndex: Integer;
    FMainDownIndex: Integer; //��ǰ��Ҫ������� ����ʱ�϶�����
    FSegmentBlockList: TList;
    FSegmentManage: TxdFixedMemoryManager;
    FMainPrioritySegments: array of Integer;   //�������������  �ɳ���д�̶�
    FSecondPrioritySegments: array of Integer; //������ ������ʱ���ȴ���
    FOnCompleted: TNotifyEvent;
    procedure LockSegment(const ALock: Boolean);
    procedure InitSegmentBlockInfo;
    procedure LoadFromFile;
    procedure SaveToFile;
    procedure ClearList;
    procedure DoCompleted;    //�ļ��ֿ鴦�����
    procedure InitWMVFileBlock;
    procedure InitMpegFileBlock;
    procedure SetMusicStyle(const Value: TMusicStyle);
    function  GetPrioritySegmentIndex(const APrioritys: array of Integer): PSegmentBlockInfo;
  published
    property IsFileCompleted: Boolean read FFileCompleted;
    property MusicStyle: TMusicStyle read FMusicStyle write SetMusicStyle;
    property OnCompleted: TNotifyEvent read FOnCompleted write FOnCompleted;
  end;
  {$M-}

implementation

const
  CtSegmentVersion: Word = 1000;
  CtSegmentBlockInfoSize = SizeOf(TSegmentBlockInfo);

{ TxdFileBlcok }

function TxdFileBlock.CheckCanRead(const APosition: Int64; const ASize: Cardinal): Boolean;
var
  i, nIndex, nCount, j: Integer;
  p: PSegmentBlockInfo;
  bAdd: Boolean;
begin
  nIndex := APosition div FBlockSize;
  nCount := (APosition + ASize + FBlockSize - 1) div FBlockSize;
  Result := True;
  LockSegment( True );
  try
    for i := nIndex to nCount - 1 do
    begin
      p := SegmentItem( i );
      if p = nil then
      begin
        Dbg( 'TxdFileBlock.CheckCanRead Error, i: %d', [i] );
        Continue;
      end;
      if p^.FSegmentState <> ssComplete then
      begin
        Result := False;
        bAdd := True;

        //��ӵ��ڶ����ȼ���������
        for j := Low(FSecondPrioritySegments) to High(FSecondPrioritySegments) do
        begin
          if FSecondPrioritySegments[j] = i then
          begin
            bAdd := False;
            Break;
          end;
        end;
        if bAdd then
        begin
          SetLength( FSecondPrioritySegments, Length(FSecondPrioritySegments) + 1 );
          FSecondPrioritySegments[ Length(FSecondPrioritySegments) - 1 ] := i;
        end;
      end;
    end;
  finally
    LockSegment( False );
  end;
end;

function TxdFileBlock.CheckPriorityFinished: Boolean;
var
  i: Integer;
  p: PSegmentBlockInfo;
begin
  Result := True;
  for i := Low(FMainPrioritySegments) to High(FMainPrioritySegments) do
  begin
    p := SegmentItem( FMainPrioritySegments[i] );
    if p^.FSegmentState <> ssComplete then
    begin
      Result := False;
      Break;
    end;
  end;
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
  function ReleasePrioritySegmentIndex(var APriority: array of Integer): Boolean;
  var
    i: Integer;
    nCount: Integer;
  begin
    Result := False;
    nCount := High(APriority);
    for i := Low(APriority) to nCount do
    begin
      if APriority[i] = nIndex then
      begin
        if i < nCount then
          Move( APriority[i + 1], APriority[i], (nCount - i) * 4 );
        Result := True;
        Break;
      end;
    end;
  end;
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
        Result := True;

        if ReleasePrioritySegmentIndex(FMainPrioritySegments) then
          SetLength( FMainPrioritySegments, Length(FMainPrioritySegments) - 1 )
        else if ReleasePrioritySegmentIndex(FSecondPrioritySegments) then
          SetLength( FSecondPrioritySegments, Length(FSecondPrioritySegments) - 1 );
        while nIndex = FEmptyListIndex do
        begin
          Inc( FEmptyListIndex );
          p := SegmentItem( nIndex + 1 );
          if Assigned(p) and (p^.FSegmentState = ssComplete) then
            Inc( nIndex );
        end;
        if FEmptyListIndex = FSegmentBlockList.Count then
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
  FFileCompleted := False;
  FMusicStyle := msNULL;
  FIsFirst := True;
  FMainDownIndex := 0;
  if FileExists(AFileName) then
    LoadFromFile
  else
    InitSegmentBlockInfo;
  InitWMVFileBlock;
  MusicStyle := GetFileMusicStyle( AFileName );
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

function TxdFileBlock.GetPrioritySegmentIndex(const APrioritys: array of Integer): PSegmentBlockInfo;
var
  i: Integer;
  p: PSegmentBlockInfo;
begin
  Result := nil;
  for i := Low(APrioritys) to High(APrioritys) do
  begin
    p := SegmentItem( APrioritys[i] );
    if Assigned(p) and (p^.FSegmentState = ssEmpty) then
    begin
      p^.FActiveTime := GetTickCount;
      p^.FSegmentState := ssWaitReply;
      Result := p;
      Break;
    end;
  end;
end;

function TxdFileBlock.GetSegmentInfo: PSegmentBlockInfo;
var
  i: Integer;
  p: PSegmentBlockInfo;
begin
  LockSegment( True );
  try
    //��һ����
    Result := GetPrioritySegmentIndex( FMainPrioritySegments );
    if not Assigned(Result) then
      Result := GetPrioritySegmentIndex( FSecondPrioritySegments ); //�ڶ�����

    if not Assigned(Result) then
    begin
      //�������ȼ�
      for i := FMainDownIndex to FSegmentBlockList.Count - 1 do
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
    end;

    if not Assigned(Result) then
    begin
      //ƽ��
      for i := 0 to FMainDownIndex - 1 do
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
    end;
  finally
    LockSegment( False );
  end;
end;

procedure TxdFileBlock.InitMpegFileBlock;
begin
  //��ȡ�ļ�ǰ�� 6M ���ݣ���ȡ�ļ������ 1M ���ݣ�֮���ͷ��������
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
  FEmptyListIndex := 0;
  FEmptyLastListIndex := nSegmentCount - 1;
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

procedure TxdFileBlock.InitWMVFileBlock;
const
  CtWMVHeaderSize = 1024 * 6;
  CtWMVTailSize = 1024;
var
  i, nIndex: Integer;
  nCount1, nCount2: Integer;
  p: PSegmentBlockInfo;
begin
  //WMV����ʱ��Ҫ��ȡ������
  //��ȡ�ļ�ǰ�� 6K ���ݣ���ȡ�ļ������ 1K ���ݣ�֮���ͷ��������
  nCount1 := (CtWMVHeaderSize + FBlockSize - 1) div FBlockSize;
  nCount2 := (CtWMVTailSize + FBlockSize - 1) div FBlockSize;
  SetLength( FMainPrioritySegments, nCount1 + nCount2 );
  nIndex := 0;
  for i := 0 to nCount1 - 1 do
  begin
    p := SegmentItem( i );
    if Assigned(p) and (p^.FSegmentState = ssEmpty) then
    begin
      FMainPrioritySegments[ nIndex ] := i;
      Inc( nIndex );
    end;
  end;
  for i := FSegmentBlockList.Count - nCount2 to FSegmentBlockList.Count - 1 do
  begin
    p := SegmentItem( i );
    if Assigned(p) and (p^.FSegmentState = ssEmpty) then
    begin
      FMainPrioritySegments[ nIndex ] := i;
      Inc( nIndex );
    end;
  end;
  if nIndex <> (nCount1 + nCount2) then
    SetLength( FMainPrioritySegments, nIndex );
end;

function TxdFileBlock.IsFirst: Boolean;
begin
  Result := FIsFirst;
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
      FEmptyListIndex := MaxInt;
      FEmptyLastListIndex := 0;
      FFileCompleted := True;
      for i := 0 to nSegmentCount - 1 do
      begin
        FSegmentManage.GetMem( Pointer(p) );
        ReadLong( p^, CtSegmentBlockInfoSize );
        p^.FActiveTime := 0;
        nIndex := FSegmentBlockList.Add( p );
        if p^.FSegmentState = ssEmpty then
        begin
          if nIndex < FEmptyListIndex then
            FEmptyListIndex := nIndex
          else if nIndex > FEmptyLastListIndex then
            FEmptyLastListIndex := nIndex;
          FFileCompleted := False;
          FIsFirst := False;
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

procedure TxdFileBlock.SetMusicStyle(const Value: TMusicStyle);
begin
  if (FMusicStyle <> Value) and (Value <> msHelp_ffdShow) then
  begin
    FMusicStyle := Value;
    case FMusicStyle of
      msWMV: InitWMVFileBlock;
      msMPEG: InitMpegFileBlock;
      msRMVB: ;
      msFLV: ;
      msMP4: ;
      msNULL: ;
    end;
  end;
end;

procedure TxdFileBlock.SetMainDownPosition(const APercent: Double);
begin
  FMainDownIndex := Round( APercent * FSegmentBlockList.Count );
  if FMainDownIndex < 0 then
  begin
    OutputDebugString( 'eror' );
    FMainDownIndex := 0;
  end
  else if FMainDownIndex >= FSegmentBlockList.Count then
  begin
    OutputDebugString( 'eror' );
    FMainDownIndex := FSegmentBlockList.Count - 1;
  end;
end;

end.
