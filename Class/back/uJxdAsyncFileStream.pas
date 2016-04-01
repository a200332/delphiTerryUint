{
��Ԫ����: uJxdAsyncFileStream
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ���ļ����зֿ鴦�������ļ����ݵ���ش���
��ʼʱ��: 2010-10-27
�޸�ʱ��: 2011-01-13 (����޸�)

    �ṩ�����أ��߲��ŵ��ļ�����
    ���ڴ��ļ�����Ҫ�ٽ��д�����Ҫ����Ϊ�ڴ�ӳ������⣬̫����ļ��޷�ȫ��ӳ�䵽�����ڴ�
}
unit uJxdAsyncFileStream;

interface

uses
  Windows, SysUtils, Classes, uJxdDataStream, uSysSub,
  uJxdFileBlock, uJxdPlayerConsts;

type
  TxdMemoryMapFile = class(TxdMemoryFile)
  public
    //ReadBuffer �� WriteBuffer �Զ�д�����κ��жϣ����ⲿȥ�ж�
    function  ReadBuffer(var ABuffer; const AByteCount: Integer; const APosition: Cardinal): Integer;
    function  WriteBuffer(const ABuffer; const AByteCount: Integer; const APosition: Cardinal): Integer;
  end;

  TxdAsyncFileStream = class
  public
    constructor Create;
    destructor  Destroy; override;
    //�ļ�����д
    function  ReadBuffer(ABuffer: PByte; ABytesToRead: Cardinal; out ABytesRead: DWord): Boolean;
    procedure WriteBuffer(const ABuffer: PByte; const AWritePos: Int64; const ABytesToWrite: Cardinal);
    //��ȡ��Ҫд��λ��
    function  GetEmptySegmentInfo: PSegmentBlockInfo;  //�ṩ����������ȡ��Ҫ������Ϣ
    function  IsCanPlayNow: Boolean; //�ļ��Ƿ�ɲ���, ��ͬ�ļ��в�ͬ�Ĵ���ʽ
    procedure SetDownPosition(const APercent: Double);

    function  FileName: string;
    function  Size: Cardinal;
    function  BlockSize: Cardinal;
  private
    FMemoryFile: TxdMemoryMapFile;
    FFileBlock: TxdFileBlock;
    FWriteLock, FSegmentLock: TRTLCriticalSection;
    FCurReadPos: Int64;
    FStreamID: Cardinal;

    function  InitFileStream(const AFileName: string; const AFileSize: Int64; const ASegmentSize: Cardinal): Boolean;
    function  GetIsFileCompleted: Boolean;
    procedure SetCurReadPos(const Value: Int64);
    function GetFinishedByteCount: Int64;
  public
    property FinishedByteCount: Int64 read GetFinishedByteCount;
    property StreamID: Cardinal read FStreamID;
    property CurReadPos: Int64 read FCurReadPos write SetCurReadPos;
    property IsFileCompleted: Boolean read GetIsFileCompleted;
  end;

function  CreateFileStream(const AFileName: string; const AFileSize: Int64; const ASegmentSize: Cardinal; var AFileStream: TxdAsyncFileStream): Boolean;
function  QueryFileStream(const AFileStreamID: Cardinal): TxdAsyncFileStream;
procedure ReleaseFileStream(const AStream: TxdAsyncFileStream);

implementation

type
  PFileStreamInfo = ^TFileStreamInfo;
  TFileStreamInfo = record
    FCount: Integer;
    FFileStream: TxdAsyncFileStream;
  end;

var
  _FileStreamList: TList;
  _FileStreamID: Cardinal;
  _Lock: TRTLCriticalSection;

{ TxdAsyncShareFile }

function TxdAsyncFileStream.BlockSize: Cardinal;
begin
  if Assigned(FFileBlock) then
    Result := FFileBlock.SegmentBlockSize
  else
    Result := 0;
end;

constructor TxdAsyncFileStream.Create;
begin
  FMemoryFile := nil;
  FCurReadPos := 0;
  InitializeCriticalSection( FWriteLock );
  InitializeCriticalSection( FSegmentLock );
  FFileBlock := nil;
  FMemoryFile := nil;
  {$IFDEF PlayerDebug}
  IsConnected := False;
  {$ENDIF}
end;

function CreateFileStream(const AFileName: string; const AFileSize: Int64; const ASegmentSize: Cardinal;
  var AFileStream: TxdAsyncFileStream): Boolean;
var
  i: Integer;
  p: PFileStreamInfo;
  obj: TxdAsyncFileStream;
begin
  //���� ����False��ʾ��������
  Result := False;
  for i := 0 to _FileStreamList.Count - 1 do
  begin
    p := _FileStreamList[i];
    if Assigned(p) and (Assigned(p^.FFileStream)) then
    begin
      if CompareText(AFileName, p^.FFileStream.FileName) = 0 then
      begin
        p^.FCount := p^.FCount + 1;
        AFileStream := p^.FFileStream;
        Result := True;
        Exit;
      end;
    end;
  end;
  //���Ҳ���,��Ҫ����
  obj := TxdAsyncFileStream.Create;
  if not obj.InitFileStream( AFileName, AFileSize, ASegmentSize ) then
  begin
    obj.Free;
    Exit;
  end;


  New( p );
  p^.FFileStream := obj;
  EnterCriticalSection( _Lock );
  try
    p^.FFileStream.FStreamID := _FileStreamID;
    _FileStreamID := _FileStreamID + 1;
  finally
    LeaveCriticalSection( _Lock );
  end;
  p^.FCount := 1;
  if _FileStreamList.Add( p ) <> -1 then
  begin
    Result := True;
    AFileStream := p^.FFileStream;
  end
  else
  begin
    p^.FFileStream.Free;
    Dispose( p );
  end;
end;

destructor TxdAsyncFileStream.Destroy;
begin
  FreeAndNil( FFileBlock );
  FreeAndNil( FMemoryFile );
  DeleteCriticalSection( FWriteLock );
  DeleteCriticalSection( FSegmentLock );
  inherited;
end;

function TxdAsyncFileStream.FileName: string;
begin
  if Assigned(FMemoryFile) then
    Result := FMemoryFile.FileName
  else
    Result := '';
end;

procedure ReleaseFileStream(const AStream: TxdAsyncFileStream);
var
  i: Integer;
  p: PFileStreamInfo;
begin
  for i := 0 to _FileStreamList.Count - 1 do
  begin
    p := _FileStreamList[i];
    if Assigned(p) and (Assigned(p^.FFileStream)) then
    begin
      if p^.FFileStream = AStream then
      begin
        p^.FCount := p^.FCount - 1;
        if p^.FCount <= 0 then
        begin
          _FileStreamList.Delete( i );
          if p^.FFileStream.FFileBlock.IsFileCompleted then
            RenameFile( p^.FFileStream.FileName, StringReplace(p^.FFileStream.FileName, CtDownTempExtName, '', [rfReplaceAll] ));
          p^.FFileStream.Free;
          Dispose( p );
        end;
        Exit;
      end;
    end;
  end;
end;

function TxdAsyncFileStream.GetEmptySegmentInfo: PSegmentBlockInfo;
begin
  EnterCriticalSection( FSegmentLock );
  try
    Result := FFileBlock.GetSegmentInfo;
  finally
    LeaveCriticalSection( FSegmentLock );
  end;
end;

function TxdAsyncFileStream.GetFinishedByteCount: Int64;
begin
  if Assigned(FFileBlock) then
    Result := FFileBlock.FinishedByteCount
  else
    Result := 0;
end;

function QueryFileStream(const AFileStreamID: Cardinal): TxdAsyncFileStream;
var
  i: Integer;
  p: PFileStreamInfo;
begin
  Result := nil;
  for i := 0 to _FileStreamList.Count - 1 do
  begin
    p := _FileStreamList[i];
    if Assigned(p) and (Assigned(p^.FFileStream)) then
    begin
      if p^.FFileStream.StreamID = AFileStreamID then
      begin
        p^.FCount := p^.FCount + 1;
        Result := p^.FFileStream;
        Exit;
      end;
    end;
  end;
end;

function TxdAsyncFileStream.GetIsFileCompleted: Boolean;
begin
  Result := Assigned(FFileBlock) and FFileBlock.IsFileCompleted;
end;

function TxdAsyncFileStream.InitFileStream(const AFileName: string; const AFileSize: Int64;
  const ASegmentSize: Cardinal): Boolean;
var
  strConfig: string;
begin
  FMemoryFile := nil;
  FCurReadPos := 0;
  strConfig := AFileName + CtFileBlockExtName;
  if (not FileExists(strConfig)) and (AFileSize <= 0) then
  begin
    Result := False;
    Exit;
  end;
  FFileBlock := TxdFileBlock.Create( strConfig, AFileSize, ASegmentSize );
  if FFileBlock.DestFileSize <= 0 then
  begin
    FFileBlock.Free;
    Result := False;
    Exit;
  end;
  if (AFileSize > 0) and (FFileBlock.DestFileSize <> AFileSize) then
  begin
    FFileBlock.Free;
    DeleteFile( strConfig );
    FFileBlock := TxdFileBlock.Create( strConfig, AFileSize, ASegmentSize );
  end;

  if FileExists(AFileName) and (GetFileSizeEx(AFileName) <> FFileBlock.DestFileSize) then
    DeleteFile( AFileName );
  FMemoryFile := TxdMemoryMapFile.Create( AFileName, FFileBlock.DestFileSize );
  FMemoryFile.MapFileToMemory( 0, 0 );   //ȫ��ӳ��
  Result := True;
end;

function TxdAsyncFileStream.IsCanPlayNow: Boolean;
begin
  Result := FFileBlock.CheckPriorityFinished;
end;

function TxdAsyncFileStream.ReadBuffer(ABuffer: PByte; ABytesToRead: Cardinal; out ABytesRead: DWord): Boolean;
var
  nReadSize: Cardinal;
begin
  {$IFDEF PlayerDebug}
  if not IsConnected then
  begin
    Dbg( '����Filterʱ����Ҫ��%dλ���϶�ȡ%d���ֽڣ�', [FCurReadPos, ABytesToRead] );
  end
  else
  begin
    Dbg( '����Filter�󣬿�ʼ���ţ���Ҫ��%dλ���϶�ȡ%d���ֽڣ�', [FCurReadPos, ABytesToRead] );
  end;
  {$ENDIF}
  if FCurReadPos + ABytesToRead > FMemoryFile.Size then
    nReadSize := FMemoryFile.Size - FCurReadPos
  else
    nReadSize := ABytesToRead;
    
  Result := FFileBlock.CheckCanRead(FCurReadPos, nReadSize);
  if Result then
  begin
    FMemoryFile.ReadBuffer( ABuffer^, nReadSize, FCurReadPos );
    ABytesRead := nReadSize;
    FCurReadPos := FCurReadPos + nReadSize;
  end;
end;

procedure TxdAsyncFileStream.SetCurReadPos(const Value: Int64);
begin
  FCurReadPos := Value;
  {$IFDEF PlayerDebug}
  if not IsConnected then
  begin
    Dbg( '����Filterʱ����Ҫ����λ�ã�' + IntToStr(Value) );
  end
  else
  begin
    Dbg( '�Ѿ�����Filter����Ҫ����λ�ã�' + IntToStr(Value) );
  end;
  {$ENDIF}
end;

procedure TxdAsyncFileStream.SetDownPosition(const APercent: Double);
begin
  FFileBlock.CheckPriorityPosition( APercent );
end;

function TxdAsyncFileStream.Size: Cardinal;
begin
  if not Assigned(FMemoryFile) then
    Result := 0
  else
    Result := FMemoryFile.Size;
end;

procedure TxdAsyncFileStream.WriteBuffer(const ABuffer: PByte; const AWritePos: Int64; const ABytesToWrite: Cardinal);
var
  bOK: Boolean;
begin
  EnterCriticalSection( FSegmentLock );
  try
    bOK := FFileBlock.CompleteSegmentHandle( AWritePos, ABytesToWrite )
  finally
    LeaveCriticalSection( FSegmentLock );
  end;
  EnterCriticalSection( FWriteLock );
  try
    if bOK then
    begin
      FMemoryFile.WriteBuffer( ABuffer^, ABytesToWrite, AWritePos );
//      FMemoryFile.Flush;
    end;
  finally
    LeaveCriticalSection( FWriteLock );
  end;
end;

{ TxdMemoryMapFile }

function TxdMemoryMapFile.ReadBuffer(var ABuffer; const AByteCount: Integer; const APosition: Cardinal): Integer;
begin
  Move( (FMemory + APosition)^, ABuffer, AByteCount );
  Result := AByteCount;
end;

function TxdMemoryMapFile.WriteBuffer(const ABuffer; const AByteCount: Integer; const APosition: Cardinal): Integer;
begin
  Move( ABuffer, (FMemory + APosition)^, AByteCount );
  Result := AByteCount;
end;

procedure InitFileStreamList;
begin
  InitializeCriticalSection( _Lock );
  _FileStreamList := TList.Create;
  _FileStreamID := GetTickCount;
end;

procedure FreeFileStreamList;
var
  i: Integer;
  p: PFileStreamInfo;
begin
  for i := 0 to _FileStreamList.Count - 1 do
  begin
    p := _FileStreamList[i];
    if Assigned(p) then
    begin
      if Assigned(p^.FFileStream) then
        FreeAndNil( p^.FFileStream );
      Dispose( p );
    end;
  end;
  FreeAndNil( _FileStreamList );
  DeleteCriticalSection( _Lock );
end;

initialization
  InitFileStreamList;
finalization
  FreeFileStreamList;

end.
