{
TRequestBlockManage: 
  �ǰ�ȫģʽ����Ҫ�ⲿ�ṩ����������
  �������ڣ��Լ���Ӧ����Ĵ�С
}
unit uJxdTaskDefine;

interface

uses
  Windows, SysUtils, uJxdUdpDefine, uJxdFileSegmentStream, uJxdHashCalc;
  
type
  TDownTaskStyle = (dssDefaul, dssSoftUpdata);
  ///////////////////////////////////////////////////////////////////////////////////////////////////
  ///                                                                                            ///
  //����ֿ������, ÿ����������ʱ���á�ʵ����һ���������Ļ�������                               ///
  ///                                                                                            ///
  //////////////////////////////////////////////////////////////////////////////////////////////////
  PRequestTableInfo = ^TRequestTableInfo;
  TRequestTableInfo = record    
    FCurRequestBlockCount: Integer; //��ǰ����ֿ������
    FCurRespondBlockCount: Integer; //��ǰ��Ӧ�ֳ�������    
    FBlockTables: array of Cardinal; //��¼ÿ������С�ֿ����Ϣ
  end;
  TRequestBlockManage = class
  public
    constructor Create(const ATableCount: Integer = 2; const AInitBlockCount: Integer = 32 );
    destructor  Destroy; override;
    
    //����ʼ
    function  BeginRequest: Integer; //��ʼ����ֿ�, ���ؿ���������
    function  AddRequestBlock(const ASegIndex, ABlockIndex: Integer): Boolean; //�������,��¼������Ϣ    
    procedure FinishedRequestBlock(const ASegIndex, ABlockIndex: Integer; const ARecvByteCount: Cardinal); //�������
  private
    FTables: array of TRequestTableInfo;
    FTableCount: Integer;
    FCurTableIndex: Integer;
    FBlockCount: Integer;
    FMaxContiguousCount: Integer; //�������������������
    FLessThanHalfContiguousCount: Integer; //����С�����ֵ��һ������
    FAutoChangedBlockCount: Boolean;
    FRecvByteCount: Integer; 
    FBeginRequestTime: Cardinal;
    FCurSize: Cardinal;
    FCurSpeed: Integer;
    function  CalcID(const ASegIndex, ABlockIndex: Integer): Cardinal; inline;
    procedure ReBuildBlockTable(const ANewBlockCount: Integer);
  public
    property CurSpeed: Integer read FCurSpeed;   //��ǰ�ٶ�
    property RecvByteCount: Integer read FRecvByteCount; //�ܹ����ش�С
    property AutoChangedBlockCount: Boolean read FAutoChangedBlockCount write FAutoChangedBlockCount; //�Ƿ��Զ���չ�����б�
  end;
  
  {
                                               P2PԴ��Ϣ�ṹ
  }
  TSourceState = (ssUnkown, ssChecking, ssSuccess, ssFail);
  PP2PSourceInfo = ^TP2PSourceInfo;
  TP2PSourceInfo = record
    FIP: Cardinal; //P2P�û�ID
    FPort: Word; //P2P�û��˿�
    FState: TSourceState; //P2P״̬
    FServerSource: Boolean; //�Ƿ��Ƿ���Դ��������Դ��ʾ��Դ�Դ��ļ�ӵ���������ݣ�������Ҫ��ʱ��ѯ��Դ�ķֶ���Ϣ  
    FNextTimeoutTick: Cardinal; //�´γ�ʱʱ��
    FTimeoutCount: Integer; //��ʱ�������������ݺ��޽��յ�����ʱʹ��
    FRequestBlockManage: TRequestBlockManage; //����ֿ������������Ļ������ڣ�
    FSegTableState: TxdSegmentStateTable; //P2P�û������ļ��ֶ���Ϣ��, ����Ƿ�����Դ����Ҫ
  end;
  
  {
                                              HttpԴ��Ϣ�ṹ
  }
  PHttpSourceInfo = ^THttpSourceInfo;
  THttpSourceInfo = record
    FUrl: string;
    FReferUrl: string;
    FCookies: string;
    FCheckSizeStyle: TSourceState; //����Դ״̬
    FTotalRecvByteCount: Cardinal; //���յ����ݴ�С
    FRefCount: Integer; //��������
    FErrorCount: Integer; //�����޷���ȡ���ݴ���
    FCheckingSize: Boolean; //�Ƿ����ڼ���С
  end;
  
  {
                                   �ȴ���ѯ�����Ե�P2P����Դ�ṹ��
  }
  PCheckSourceInfo = ^TCheckSourceInfo;
  TCheckSourceInfo = record
    FUserID: Cardinal;    
    FIP: Cardinal;
    FPort: Word;
    FCheckState: TConnectState; 
    FLastActiveTime: Cardinal;   
  end;
  THashThreadState = (htsNULL, htsRunning, htsFinished);

  {
                                            ��������������
  }
  PdtpP2PSourceInfo = ^TdtpP2PSourceInfo;
  TdtpP2PSourceInfo = record
    FIP: Cardinal;
    FPort: Word;
  end;
  TArydtpP2PSourceInfo = array of TdtpP2PSourceInfo;  

  PdtpHttpSourceInfo = ^TdtpHttpSourceInfo;
  TdtpHttpSourceInfo = record
    FUrl: string;
    FReferUrl: string;
    FCookie: string;
    FTotoalByteCount: Integer;
  end;
  TArydtpHttpSourceInfo = array of TdtpHttpSourceInfo;
  
  PDownTaskParam = ^TDownTaskParam;
  TDownTaskParam = record
    FTaskID: Integer;
    FTaskStyle: TDownTaskStyle; //����
    FTaskName: string; //�������� ��Ϊ��
    FFileName: string; //�������񱣴��ļ����� ����ȫ�ļ���������Ϊ��
    FSegmentSize: Integer;
    FFileSize: Int64;
    FFileHash, FWebHash: TxdHash;
    FP2PSource: TArydtpP2PSourceInfo; //P2PԴ    
    FHttpSource: TArydtpHttpSourceInfo; //HttpԴ
    FFileFinishedInfos: TAryFileFinishedInfos; //�ļ��Ѿ���ɵ���Ϣ
    FTaskData: Pointer;
  end;

  {
                                           ����������Ϣ�ṹ��
  }
  PTaskProgressInfo = ^TTaskProgressInfo;
  TTaskProgressInfo = record
    FTaskID: Integer;
    FActive: Boolean;
    FFail: Boolean;
    FTaskName: string;
    FFileName: string;
    FFileSize, FCompletedSize: Int64; //�ļ���С����ɴ�С
    FCurSpeed, FAdvSpedd: Integer; //��ǰ�ٶȣ���ƽ���ٶ�
    FTaskStyle: TDownTaskStyle; //���������
  end;

  {
                                        ����������ϸ��Ϣ�ṹ��  
  }
  TP2PDownDetailInfo = record
    FIP: Cardinal;
    FPort: Word;
    FCurSpeed: Integer; //��ǰ�ٶ� b/ms
    FTotalByteCount: Integer; 
  end;  
  TAryP2PDownDetailInfos = array of TP2PDownDetailInfo;
  
  TOtherDownDetailInfo = record
    FProviderInfo: string; //�ṩ����Ϣ
    FCurSpeed: Integer;
    FTotalByteCount: Integer;
  end;
  TAryOtherDownDetailInfos = array of TOtherDownDetailInfo;
  
  PTaskDownDetailInfo = ^TTaskDownDetailInfo;
  TTaskDownDetailInfo = record
    FTaskID: Integer;
    FInvalideBufferSize: Cardinal; //��Ч����
    FP2PDownDetails: TAryP2PDownDetailInfos;
    FOtherDownDetails: TAryOtherDownDetailInfos
  end;
  
const
  CtP2PSourceInfoSize = SizeOf(TP2PSourceInfo);
  CtHttpSourceInfoSize = SizeOf(THttpSourceInfo);
  CtRequestTableInfoSize = SizeOf(TRequestTableInfo);
  CtDownTaskParamSize = SizeOf(TDownTaskParam);

implementation

const
  CtContiguousCount = 32; //���ӱ���ָ������������ĳ���

{ TRequestBlockManage }

function TRequestBlockManage.AddRequestBlock(const ASegIndex, ABlockIndex: Integer): Boolean;
var
  p: PRequestTableInfo;
begin
  p := @FTables[FCurTableIndex];
  Result := p^.FCurRequestBlockCount + 1 <= FBlockCount;
  if Result then
  begin
    p^.FBlockTables[p^.FCurRequestBlockCount] := CalcID( ASegIndex, ABlockIndex );
    Inc( p^.FCurRequestBlockCount );
  end;
end;

function TRequestBlockManage.BeginRequest: Integer;
var
  p: PRequestTableInfo;
  dwTime: Cardinal;
begin
  FCurTableIndex := (FCurTableIndex + 1) mod FTableCount;
  p := @FTables[FCurTableIndex];
  Result := p^.FCurRespondBlockCount + 1;
  if Result > FBlockCount then
    Result := FBlockCount; 

  if AutoChangedBlockCount then
  begin
    if Result = FBlockCount then
    begin
      FLessThanHalfContiguousCount := 0;
      Inc( FMaxContiguousCount );
      if FMaxContiguousCount >= CtContiguousCount then
      begin
        ReBuildBlockTable( FBlockCount * 2 ); 
        Result := FBlockCount + 1;
      end;  
    end
    else
    begin
      FMaxContiguousCount := 0;
      if Result < FBlockCount div 2 then
      begin
        Inc( FLessThanHalfContiguousCount );
        if FLessThanHalfContiguousCount >= CtContiguousCount * 2 then
        begin
          ReBuildBlockTable( FBlockCount div 2 );
          if Result > FBlockCount then
            Result := FBlockCount;
        end;
      end;
    end;
  end;
  
  FillChar( p^.FBlockTables[0], FBlockCount * 4, 0 );
  p^.FCurRequestBlockCount := 0;
  p^.FCurRespondBlockCount := 0;
  dwTime := GetTickCount;
  if (dwTime - FBeginRequestTime > 0) and (FCurSize <> 0) then
    FCurSpeed := FCurSize div (dwTime - FBeginRequestTime);
  FBeginRequestTime := dwTime;
  FCurSize := 0;
end;

function TRequestBlockManage.CalcID(const ASegIndex, ABlockIndex: Integer): Cardinal;
begin
  Result := ASegIndex * 10000 + ABlockIndex;
end;

constructor TRequestBlockManage.Create(const ATableCount: Integer; const AInitBlockCount: Integer);
var
  i: Integer;
begin  
  if AInitBlockCount <= 0 then
    FBlockCount := 32 //Ĭ�����
  else
    FBlockCount := AInitBlockCount;
  AutoChangedBlockCount := True;
  if ATableCount >= 1 then
    FTableCount := ATableCount
  else
    FTableCount := 2;
  SetLength( FTables, FTableCount );
  for i := 0 to FTableCount - 1 do    
  begin
    SetLength( FTables[i].FBlockTables, FBlockCount );
    FillChar( FTables[i].FBlockTables[0], FBlockCount * 4, 0 );
    FTables[i].FCurRequestBlockCount := 0;
    FTables[i].FCurRespondBlockCount := 0;
  end;
  FCurTableIndex := -1;
  FMaxContiguousCount := 0;
  FLessThanHalfContiguousCount := 0;
  FBeginRequestTime := 0;
  FCurSize := 0;
  FCurSpeed := 0;
end;

destructor TRequestBlockManage.Destroy;
var
  i: Integer;
begin
  for i := 0 to FTableCount - 1 do
    SetLength( FTables[i].FBlockTables, 0 );
  SetLength( FTables, 0 );
  inherited;
end;

procedure TRequestBlockManage.FinishedRequestBlock(const ASegIndex, ABlockIndex: Integer; const ARecvByteCount: Cardinal);
var
  i, j: Integer;
  p: PRequestTableInfo;
  nID: Cardinal;
begin  
  Inc( FRecvByteCount, ARecvByteCount );
  FCurSize := FCurSize + ARecvByteCount;
  nID := CalcID( ASegIndex, ABlockIndex );
  for i := 0 to FTableCount - 1 do
  begin
    p := @FTables[i];
    for j := 0 to p^.FCurRequestBlockCount - 1 do
    begin
      if p^.FBlockTables[j] = nID then
      begin
        Inc( p^.FCurRespondBlockCount );        
        Exit;
      end;
    end;
  end;
end;

procedure TRequestBlockManage.ReBuildBlockTable(const ANewBlockCount: Integer);
var
  i: Integer;
begin
  FMaxContiguousCount := 0;
  FLessThanHalfContiguousCount := 0;
  for i := 0 to FTableCount - 1 do
  begin
    SetLength( FTables[i].FBlockTables, ANewBlockCount );
    if FTables[i].FCurRequestBlockCount > ANewBlockCount then
      FTables[i].FCurRequestBlockCount := ANewBlockCount;
    if FTables[i].FCurRespondBlockCount > ANewBlockCount then
      FTables[i].FCurRespondBlockCount := ANewBlockCount;
  end;
  FBlockCount := ANewBlockCount;
  OutputDebugString( PChar('���Ĵ�С: ' + IntToStr(ANewBlockCount)) );
end;

end.
