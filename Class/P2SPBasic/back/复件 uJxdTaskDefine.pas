{
TRequestBlockManage: 
  �ǰ�ȫģʽ����Ҫ�ⲿ�ṩ����������
  �������ڣ��Լ���Ӧ����Ĵ�С
}
unit uJxdTaskDefine;

interface

uses
  Windows, SysUtils, uJxdUdpDefine, uJxdFileSegmentStream;

const
  CtMaxRequestBlockCount = 64; //������������
  
type
  //����ֿ������, ÿ����������ʱ���á�ʵ����һ���������Ļ�������
  PRequestTableInfo = ^TRequestTableInfo;
  TRequestTableInfo = record
    FBlockTables: array[0..CtMaxRequestBlockCount - 1] of Cardinal; //��¼ÿ������С�ֿ����Ϣ
    FCurRequestBlockCount: Integer; //��ǰ����ֿ������
    FCurRespondBlockCount: Integer; //��ǰ��Ӧ�ֳ�������    
  end;
  TRequestBlockManage = class
  public
    constructor Create(const ATableCount: Integer = 2 );
    destructor  Destroy; override;
    
    //����ʼ
    function  BeginRequest: Integer; //��ʼ����ֿ�, ���ؿ���������
    function  AddRequestBlock(const ASegIndex, ABlockIndex: Integer): Boolean; //�������,��¼������Ϣ    
    procedure FinishedRequestBlock(const ASegIndex, ABlockIndex: Integer); //�������
  private
    FTables: array of TRequestTableInfo;
    FTableCount: Integer;
    FCurTableIndex: Integer;
    function  CalcID(const ASegIndex, ABlockIndex: Integer): Cardinal; inline;
  end;
  
  {P2PԴ��Ϣ�ṹ}
  TSourceState = (ssUnkown, ssChecking, ssSuccess);
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
    FTotalRecvByteCount: Integer; //�ܹ����յ������ݳ���
  end;
  
  {HttpԴ��Ϣ�ṹ}
  PHttpSourceInfo = ^THttpSourceInfo;
  THttpSourceInfo = record
    FUrl: string;
    FReferUrl: string;
    FCookies: string;
    FTotalRecvByteCount: Integer;
  end;
  
  //�ȴ���ѯ�����Ե�P2P����Դ�ṹ��
  PCheckSourceInfo = ^TCheckSourceInfo;
  TCheckSourceInfo = record
    FUserID: Cardinal;    
    FIP: Cardinal;
    FPort: Word;
    FCheckState: TConnectState; 
    FLastActiveTime: Cardinal;   
  end;
  THashThreadState = (htsNULL, htsRunning, htsFinished);

const
  CtP2PSourceInfoSize = SizeOf(TP2PSourceInfo);
  CtHttpSourceInfoSize = SizeOf(THttpSourceInfo);
  CtRequestTableInfoSize = SizeOf(TRequestTableInfo);

implementation

{ TRequestBlockManage }

function TRequestBlockManage.AddRequestBlock(const ASegIndex, ABlockIndex: Integer): Boolean;
var
  p: PRequestTableInfo;
begin
  p := @FTables[FCurTableIndex];
  Result := p^.FCurRequestBlockCount + 1 <= CtMaxRequestBlockCount;
  if Result then
  begin
    p^.FBlockTables[p^.FCurRequestBlockCount] := CalcID( ASegIndex, ABlockIndex );
    Inc( p^.FCurRequestBlockCount );
  end;
end;

function TRequestBlockManage.BeginRequest: Integer;
var
  p: PRequestTableInfo;
begin
  FCurTableIndex := (FCurTableIndex + 1) mod FTableCount;
  p := @FTables[FCurTableIndex];
  Result := p^.FCurRespondBlockCount + 1;
  if Result > CtMaxRequestBlockCount then
    Result := CtMaxRequestBlockCount;   
  FillChar( p^, CtRequestTableInfoSize, 0 );
  
  if Result = CtMaxRequestBlockCount then  
  OutputDebugString( PChar('��ǰ�������Ϊ��' + InttoStr(Result)) );
end;

function TRequestBlockManage.CalcID(const ASegIndex, ABlockIndex: Integer): Cardinal;
begin
  Result := ASegIndex * 10000 + ABlockIndex;
end;

constructor TRequestBlockManage.Create(const ATableCount: Integer);
var
  i: Integer;
begin  
  if CtMaxRequestBlockCount > CtMaxRequestFileBlockCount then
    raise Exception.Create( 'CtMaxRequestBlockCount > CtMaxRequestFileBlockCount' );
  
  if ATableCount >= 1 then
    FTableCount := ATableCount
  else
    FTableCount := 2;
  SetLength( FTables, FTableCount );
  for i := 0 to FTableCount - 1 do    
    FillChar( FTables[i], CtRequestTableInfoSize, 0 );
  FCurTableIndex := -1;
end;

destructor TRequestBlockManage.Destroy;
begin
  SetLength( FTables, 0 );
  inherited;
end;

procedure TRequestBlockManage.FinishedRequestBlock(const ASegIndex, ABlockIndex: Integer);
var
  i, j: Integer;
  p: PRequestTableInfo;
  nID: Cardinal;
begin  
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

end.
