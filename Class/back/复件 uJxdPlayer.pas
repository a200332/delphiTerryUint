{
��Ԫ����: uJxdPlayer
��Ԫ����: ������(Terry)
��    ��: jxd524@163.com
˵    ��: ��������ϵͳ��Ҫ��װDirectX9.0c
��ʼʱ��: 2010-11-01
�޸�ʱ��: 2010-11-11 (����޸�)

    ��������֧�ֱ��ز��ţ�Ҳ����ֱ�Ӳ���������ҪTxdAsyncFileStreamԴ��֧�֣���
    �������ķ�ʽ��
        WMV��     Stream -> ASF splitter filter(1932C124-77DA-4151-99AA-234FEA09F463) -> ��������
        MP3:      Stream -> ASF splitter filter -> MPEG Layer-3 Decoder(38BE3000-DBF4-11D0-860E-00A024CFEF6D) -> ��������
        MPEG:     Stream -> MPEG Splitter(DC257063-045F-4BE2-BD5B-E12279C464F0) -> ��������
        RMVB/RM:  Stream -> RealMedia Splitter(E21BE468-5C18-43EB-B0CC-DB93A847D769) -> ��������
        FLV/F4V:  Stream -> FLV Splitter(47E792CF-0BBE-4F7A-859C-194B0768650A) -> ��������
        MP4:      Stream -> Haali Splitter(564FD788-86C9-4444-971E-CC4A243DA150) -> ��������

��ע��
      ��ͬ��ʽ�ļ���������Ҫ�����ı����ʧ�ܣ���ʹ�����ܴ�����ʽ��
      1��WMV��һ����� ASF splitter filter ֮�⣬����Ҫ�ٰ�װ������FilterҲ����������)
      2: MP3, MPEG ���ܻ���Ҫ ffdshow �������İ���(�ļ����ƣ�filters\ffdshow.ax��
}
unit uJxdPlayer;

interface

uses
  Windows, Classes, Messages, SysUtils, Controls, Graphics, DirectShow9, ActiveX,
  Math, ShellAPI, DSUtil, uJxdAudioFilter, ExtCtrls, MMSystem, Forms,
  uJxdAsyncSource, uJxdAsyncFileStream, uJxdPlayerConsts, uDShowSub;

const
  WM_GraphNotify = WM_USER + $9878;
  WM_StopPlayer  = WM_GraphNotify + 1;
type
  TPlayState = (psOpening, psOpened, psStop, psPlay, psPause, psCancel);
  TVideoMode = (vmDefault, vmVMR9);
  //vmVMR9: ʹ����Direct3D 9�ļ��������ܱ�VMR-7����ǿ����VMR9��Ҫ�����ϵͳ��Դ��
  //vmDefault: ��ѡ����VMR-7,�������ʧ�ܣ��ٴ����ɵ���Ⱦ��; һ�㲻��ʧ��

  PVideoMixerBitmapInfo = ^TVideoMixerBitmapInfo;
  TVideoMixerBitmapInfo = record
    FDC: HDC;
    FSrcRect: TRect;
    FDestLeft: Single;
    FDestTop: Single;
    FDestRight: Single;
    FDestBottom: Single;
    FAlphaValue: single;
    FclrSrcKey: COLORREF;
  end;

  {$M+}
  TxdPlayer = class(TCustomControl)
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    procedure Play;
    procedure Pause;
    procedure Stop;

    {����}
    function  OpenFileStream(const AFileStreamID: Cardinal; const AMaxWaitTime: Cardinal = 1000 * 30): Boolean;
    function  OpenFile(const AFileName: string): Boolean;

    {���ͼƬ}
    function  MixerBitmap(const AMixerInfo: TVideoMixerBitmapInfo): Boolean;
    function  MixerBitmapInfo(var AMixerInfo: TVideoMixerBitmapInfo): Boolean;
    procedure MixerDisable(const AAnimateBmp: Boolean);

    {��ͼ}
    function  GetCurrentBitmap(var ABmp: TBitmap): Boolean;

    procedure HideCursor(bHide: Boolean);
  protected
    procedure Resize; override;
    procedure DblClick; override;
    procedure Paint; override;
    procedure WMEraseBkGnd(var Message: TWMEraseBkGnd); message WM_ERASEBKGND;
    procedure WMDisplayChange(var Message: TMessage); message WM_DISPLAYCHANGE;
  private
    {DirectShow�ӿ�}
    FGraph: IGraphBuilder;
    FRenderVideo: IBaseFilter;
    FRenderAudio: IBasicAudio;
    FMediaControl: IMediaControl;
    FVideoWindow: IVideoWindow;
    FSeeking: IMediaSeeking;
    FEvent: IMediaEventEx;
    FSpliter: IBaseFilter;
    FVMR9WinlessCtrl: IVMRWindowlessControl9;
    FVMRWinlessCtrl: IVMRWindowlessControl;
    FAsyncSourceFilter: TxdAsyncFilter;
    FAudioFilter: IBaseFilter;

    FGraphEditID: Integer;
    FFileStream: TxdAsyncFileStream;
    FFullSrceenForm: TForm;
    FMixerBitmapTimer: TTimer;


    function  OpenDS: Boolean;
    procedure CloseDS;
    //����ý���ļ�֮ǰ
    procedure ConfigDefaultVMR; //����Ĭ��VMR��������VMR7����������Ⱦ��
    procedure ConfigVMR9; //����VMR9��Ⱦ��
    //����ý���ļ�֮��
    function  ConfigPlayerAfterLoadFile: Boolean; //�����ļ�֮�������ò�����
    
    function  CreateFilter(const guid: TGUID; const AIsAddToGraph: Boolean; const AFilterName: WideString; var AFilter: IBaseFilter): Boolean;
    function  RenderOutPin(var AFilter: IBaseFilter): Boolean;
    function  GetStreamSplitter(const AFileName: string): TGUID;   //ѡ�����������Ӱ�����߲�������
    procedure ChangedVideoPosition(const AShowWinHandle: HWND; const ApRect: PRect = nil);
    procedure WMGraphNotify(var Message: TMessage); message WM_GraphNotify;
    procedure WMStopPlayer(var message: TMessage); message WM_StopPlayer;

    procedure DoErrorInfo(const AInfo: string); overload;
    procedure DoErrorInfo(const AInfo: string; const Args: array of const); overload;

    function  GetMixerBitmapInterface(var AMixerBmp: IVMRMixerBitmap): Boolean; overload;
    function  GetMixerBitmapInterface(var AMixerBmp: IVMRMixerBitmap9): Boolean; overload;
    procedure VMRToMixerBmpInfo(const AVMR: TVMRAlphaBitmap; AMixerBmpInfo: TVideoMixerBitmapInfo); overload;
    procedure VMRToMixerBmpInfo(const AVMR9: TVMR9AlphaBitmap; AMixerBmpInfo: TVideoMixerBitmapInfo); overload;
    procedure DoTimeToDisableMixerBitmap(Sender: TObject);

    {ȫ���������}
    procedure CreateFullSrceen;
    procedure ReleaseFullScreen;
    procedure DoFullSrceenFormDbClick(Sender: TObject);
    procedure DoFullSrceenFormKeyPress(Sender: TObject; var Key: Char);
    procedure DoFullSrceenFormClose(Sender: TObject; var Action: TCloseAction);
    procedure DoFreeFullScreenForm(Sender: TObject);
  private
    FVideoMode: TVideoMode;
    FPlayState: TPlayState;
    FGraphEdit: Boolean;
    FIsContainVideo: Boolean;
    FFullScreen: Boolean;
    FAudioState: TAudioState;
    FCurShowWinHandle: HWND;
    FVolume: Integer;
    FLinearVolume: Boolean;
    FMute: Boolean;
    FDuration: Cardinal;
    FIsCanSeek: Boolean;
    FOnOpenPlayer: TNotifyEvent;
    FOnClosePlayer: TNotifyEvent;
    FOnFullSrceenPlay: TNotifyEvent;
    FCloseByPlayer: Boolean;
    FEnableMixerBmp: Boolean;

    procedure SetVideoMode(const Value: TVideoMode);
    procedure SetGraphEdit(const Value: Boolean);
    procedure SetFullScreen(const Value: Boolean);
    procedure SetAudioState(const Value: TAudioState);
    procedure SetShowVideoByWinHandle(const Value: HWND);
    procedure SetVolume(const Value: Integer);
    procedure SetMute(const Value: Boolean);
    function  GetPosition: Cardinal;
    procedure SetPosition(const Value: Cardinal);
    procedure SetEnableMixerBmp(const Value: Boolean);
  published
    property CloseByPlayer: Boolean read FCloseByPlayer; //�Ƿ��ǲ��ŵ���󣬲������Լ�ֹͣ
    property PlayState: TPlayState read FPlayState; //��ǰ����״̬
    property Duration:Cardinal read FDuration;
    property IsContainVideo: Boolean read FIsContainVideo; //�Ƿ������Ƶ��
    property IsCanSeek: Boolean read FIsCanSeek;

    property GraphEdit: Boolean read FGraphEdit write SetGraphEdit default False; //Զ�̲鿴����
    property Position: Cardinal read GetPosition write SetPosition;
    {��Ƶ����}
    property VideoMode: TVideoMode read FVideoMode write SetVideoMode default vmDefault; //��Ƶ��Ⱦģʽ
    property EnableVideoMixerBitmap: Boolean read FEnableMixerBmp write SetEnableMixerBmp; //�Ƿ�ʹ��ͼƬ�������Ƶ
    property FullScreen: Boolean read FFullScreen write SetFullScreen default False; //ȫ��ģʽ
    property ShowVideoByWinHandle: HWND read FCurShowWinHandle write SetShowVideoByWinHandle;  //��Ƶ��ʾ��ָ��������
    {��Ƶ����}
    property AudioState: TAudioState read FAudioState write SetAudioState;  //��Ƶ��������
    property Volume: Integer read FVolume write SetVolume default 100; //��������
    property LinearVolume: Boolean read FLinearVolume write FLinearVolume default True;
    property Mute: Boolean read FMute write SetMute;
    {�¼�}
    property OnOpenPlayer: TNotifyEvent read FOnOpenPlayer write FOnOpenPlayer;
    property OnClosePlayer: TNotifyEvent read FOnClosePlayer write FOnClosePlayer;
    property OnFullSrceenPlay: TNotifyEvent read FOnFullSrceenPlay write FOnFullSrceenPlay;
  end;
  {$M-}

implementation

//��Ҫ������֧�ֵ�GUID
type
  TFilterInfo = record
    Style: TMusicStyle;
    SplitterCLSID: string;
    SplitterFileName: string;
  end;
  
const
  CtFilterPath = 'filters\';
  CtAryFilters: array[0..5] of TFilterInfo =
  (
    (Style: msWMV; SplitterCLSID: '{1932C124-77DA-4151-99AA-234FEA09F463}'; SplitterFileName: 'asfsplliter.ax'),
    (Style: msMPEG; SplitterCLSID: '{DC257063-045F-4BE2-BD5B-E12279C464F0}'; SplitterFileName: 'MpegSplitter.ax'),
    (Style: msRMVB; SplitterCLSID: '{E21BE468-5C18-43EB-B0CC-DB93A847D769}'; SplitterFileName: 'RealMediaSplitter.ax'),
    (Style: msFLV; SplitterCLSID: '{47E792CF-0BBE-4F7A-859C-194B0768650A}'; SplitterFileName: 'FLVSplitter.ax'),
    (Style: msMP4; SplitterCLSID: '{564FD788-86C9-4444-971E-CC4A243DA150}'; SplitterFileName: 'HaaliSplitter.ax'),
    (Style: msHelp_ffdShow; SplitterCLSID: '{0B0EFF97-C750-462C-9488-B10E7D87F1A6}'; SplitterFileName: 'ffdshow.ax')
  );

{ TxdPlayer }

procedure TxdPlayer.ChangedVideoPosition(const AShowWinHandle: HWND; const ApRect: PRect);
var
  R: TRect;
  dc: HDC;
  bSuccess: Boolean;
begin
  if ApRect = nil then
    Windows.GetClientRect( AShowWinHandle, R )
  else
    R := ApRect^;
  bSuccess := False;
  case VideoMode of
    vmDefault:
    begin
      if Assigned(FVideoWindow) then
      begin
//        with FVideoWindow do
//        begin
//          put_Owner( OAHWND(AShowWinHandle) );
//          put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS);
//          put_WindowStyleEx(WS_EX_TOPMOST);
//          put_Visible( True );
//          SetWindowPosition( R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top );
//        end;
        bSuccess := True;
      end;
    end;
    vmVMR9:
    begin
      if Assigned(FVMR9WinlessCtrl) then
      begin
        with FVMR9WinlessCtrl do
        begin
          SetVideoClippingWindow( AShowWinHandle );
          SetVideoPosition( nil, @R );
          if PlayState = psPause then
          begin
            dc := GetDC( AShowWinHandle );
            RepaintVideo( AShowWinHandle, dc );
            ReleaseDC( AShowWinHandle, dc );
          end;
        end;
        bSuccess := True;
      end;
    end;
  end;
  if bSuccess then
    FCurShowWinHandle := AShowWinHandle
  else
    FCurShowWinHandle := Handle;
end;

procedure TxdPlayer.CloseDS;
begin
  FPlayState := psStop;
  FreeAndNil( FMixerBitmapTimer );
  if FGraphEditID <> 0 then
  begin
    RemoveGraphFromRot( FGraphEditID );
    FGraphEditID := 0;
  end;
  if Assigned(FEvent) then
  begin
    FEvent.SetNotifyWindow( 0, 0, 0 );
    FEvent := nil;
  end;
  if Assigned(FAsyncSourceFilter) then
    FAsyncSourceFilter.FilterStop := True; //��ֹһֱ�ȴ�
  if Assigned(FMediaControl) then
  begin
    FMediaControl.Stop;
    FMediaControl := nil;
  end;
  if Assigned(FVideoWindow) then
  begin
    FVideoWindow.put_MessageDrain(0);
    FVideoWindow.put_Visible(False);
    FVideoWindow := nil;
  end;
  FDuration := 0;
  FIsCanSeek := False;

  FGraph       := nil;
  FRenderAudio := nil;
  FSeeking     := nil;
  FRenderVideo := nil;
  FSpliter     := nil;
  FVMR9WinlessCtrl := nil;
  FAsyncSourceFilter := nil;
  FAudioFilter := nil;

  if Assigned(FFileStream) then
  begin
    ReleaseFileStream( FFileStream );
    FFileStream := nil;
  end;
  Windows.InvalidateRect( FCurShowWinHandle, nil, True );
  if Assigned(OnClosePlayer) then
    OnClosePlayer( Self );
end;

procedure TxdPlayer.ConfigDefaultVMR;
var
  cfg: IVMRFilterConfig;
  ctrl: IVMRWindowlessControl;
  R: TRect;
begin
  if Succeeded( FRenderVideo.QueryInterface(IID_IVMRFilterConfig, cfg) ) then
  begin
    try
      if EnableVideoMixerBitmap then
        cfg.SetNumberOfStreams( 1 ); //�ɻ��ͼ����        
      cfg.SetRenderingMode(VMRMode_Windowless);
    finally
      cfg := nil;
    end;
  end;
  if Succeeded(FRenderVideo.QueryInterface(IID_IVMRWindowlessControl, ctrl)) then
  begin
    ctrl.SetVideoClippingWindow( Handle );
    R := GetClientRect;
    ctrl.SetVideoPosition( nil, @R );
    ctrl := nil;
  end;
end;

function TxdPlayer.ConfigPlayerAfterLoadFile: Boolean;
var
  pin: IPin;
  dwCapabilities: Cardinal;
  t: Int64;
begin
  pin := nil;
  FIsContainVideo := Succeeded( GetConnectedPin(FRenderVideo, PINDIR_INPUT, pin, 0) );
  if not FIsContainVideo then
  begin
    pin := nil;
    FGraph.RemoveFilter( FRenderVideo );
    FRenderVideo := nil;
    FCurShowWinHandle := Handle;
  end
  else
  begin
    //������Ƶ��Ⱦ��, Ĭ����Ҫ������֮����������Ƶ����
    if FVideoMode = vmDefault then
    begin
//      if Assigned(FVideoWindow) then
//      begin
//        with FVideoWindow do
//        begin
//          put_BorderColor( 0 );
//          put_MessageDrain( OAHWND(Handle) );
//        end;
//      end;

      if FFullScreen then
      begin
        CreateFullSrceen;
        ChangedVideoPosition( FFullSrceenForm.Handle );
      end
      else
        ChangedVideoPosition( Handle );
    end;
  end;
  SetAudioState( FAudioState );
  SetVolume( FVolume );
  if Assigned(FSeeking) then
  begin
    FSeeking.GetCapabilities( dwCapabilities );
    FIsCanSeek := dwCapabilities and AM_SEEKING_CanSeekAbsolute <> 0;
    FSeeking.GetDuration( t );
    FDuration := t div 10000;
  end
  else
  begin
    FIsCanSeek := False;
    FDuration := 0;
  end;

  Result := True;
  if Assigned(OnOpenPlayer) then
    OnOpenPlayer(Self );
end;

procedure TxdPlayer.ConfigVMR9;
var
  cfg: IVMRFilterConfig9;
begin
  if Succeeded( FRenderVideo.QueryInterface(IID_IVMRFilterConfig9, cfg) ) then
  begin
    try
      if EnableVideoMixerBitmap then
        cfg.SetNumberOfStreams( 2 )   //���ͼƬʱ��Ҫ�趨Ϊ2 ����Ϊ1
      else
        cfg.SetNumberOfStreams( 1 );
      cfg.SetRenderingMode( VMR9Mode_Windowless );
    finally
      cfg := nil;
    end;
  end;
  if Succeeded( FRenderVideo.QueryInterface(IID_IVMRWindowlessControl9, FVMR9WinlessCtrl) ) then
  begin
    FVMR9WinlessCtrl.SetBorderColor( 0 );
    if FFullScreen then
    begin
      CreateFullSrceen;
      ChangedVideoPosition( FFullSrceenForm.Handle );
    end
    else
      ChangedVideoPosition( Handle );
  end;
end;

constructor TxdPlayer.Create(AOwner: TComponent);
begin
  inherited;
  Canvas.Brush.Color := clBlack;
  Width := 320;
  Height := 240;
  DoubleBuffered := True;

  FVideoMode := vmDefault;
  FPlayState := psStop;
  FGraphEdit := False;
  FGraphEditID := 0;
  FFullScreen := False;
  FFileStream := nil;
  FFullSrceenForm := nil;
  FCurShowWinHandle := 0;
  FEnableMixerBmp := False;
  FMixerBitmapTimer := nil;

  FGraph := nil;
  FMediaControl := nil;
  FEvent := nil;
  FRenderVideo := nil;
  FRenderAudio := nil;
  FVideoWindow := nil;
  FSeeking := nil;
  FSpliter := nil;
  FVMR9WinlessCtrl := nil;

  FIsCanSeek := False;
  FDuration := 0;
  FVolume := 100;
  FLinearVolume := True;

  BevelInner := bvNone;
  BevelOuter := bvNone;
  BevelKind := bkNone;
  Ctl3D := False;
  BorderWidth := 0;
end;

function TxdPlayer.CreateFilter(const guid: TGUID; const AIsAddToGraph: Boolean; const AFilterName: WideString; var AFilter: IBaseFilter): Boolean;
begin
  Result := Succeeded( CoCreateInstance(guid, nil, CLSCTX_INPROC_SERVER, IID_IBaseFilter, AFilter) );
  if AIsAddToGraph and Result and (FGraph <> nil) then
  begin
    Result := Succeeded( FGraph.AddFilter(AFilter, PWideChar(AFilterName)) );
    if not Result then
      AFilter := nil;
  end;
end;

procedure TxdPlayer.CreateFullSrceen;
begin
  if not Assigned(FFullSrceenForm) then
  begin
    FFullSrceenForm := TForm.Create( nil );
    with FFullSrceenForm do
    begin
      BorderIcons := [];
      BorderStyle := bsNone;
      Caption := '';
      Color := 0;
      FormStyle := fsStayOnTop;
      OnDblClick := DoFullSrceenFormDbClick;
      OnKeyPress := DoFullSrceenFormKeyPress;
      OnClose := DoFullSrceenFormClose;
    end;
  end;
  FFullSrceenForm.Visible := True;
  FFullSrceenForm.Show;
  FFullSrceenForm.WindowState := wsMaximized;
end;

procedure TxdPlayer.DblClick;
begin
  inherited;
  FullScreen := not FullScreen;
end;

destructor TxdPlayer.Destroy;
begin
  Stop;
  if Assigned(FFullSrceenForm) then
    FreeAndNil( FFullSrceenForm );
  inherited;
end;

procedure TxdPlayer.DoErrorInfo(const AInfo: string);
begin
  Dbg( AInfo );
end;

procedure TxdPlayer.DoErrorInfo(const AInfo: string; const Args: array of const);
begin
  DoErrorInfo( Format(AInfo, Args) );
end;

procedure TxdPlayer.DoFreeFullScreenForm(Sender: TObject);
begin
  if Sender is TTimer then
    (Sender as TTimer).Free;
  if Assigned(FFullSrceenForm) and not FullScreen then
    FreeAndNil( FFullSrceenForm );
end;

procedure TxdPlayer.DoFullSrceenFormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FullScreen then
    FullScreen := False;
end;

procedure TxdPlayer.DoFullSrceenFormDbClick(Sender: TObject);
begin
  FullScreen := not FullScreen;
end;

procedure TxdPlayer.DoFullSrceenFormKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #27) and FullScreen then
    FullScreen := False;
end;

procedure TxdPlayer.DoTimeToDisableMixerBitmap(Sender: TObject);
  procedure DisableDefault;
  var
    iBmp: IVMRMixerBitmap;
    param: TVMRAlphaBitmap;
  begin
    if GetMixerBitmapInterface(iBmp) then
    begin
      if Failed(iBmp.GetAlphaBitmapParameters( param )) then
      begin
        FreeAndNil( FMixerBitmapTimer );
        Exit;
      end;
      if param.fAlpha <= 0 then
      begin
        FreeAndNil( FMixerBitmapTimer );
        MixerDisable( False );
        Exit;
      end;

      param.fAlpha := param.fAlpha - 0.1;

      if Failed(iBmp.UpdateAlphaBitmapParameters( @param )) then
      begin
        FreeAndNil( FMixerBitmapTimer );
        MixerDisable( False );
      end;
    end;
  end;

  procedure DisableVMR9;
  var
    iBmp: IVMRMixerBitmap9;
    param: TVMR9AlphaBitmap;
  begin
    if GetMixerBitmapInterface(iBmp) then
    begin
      if Failed(iBmp.GetAlphaBitmapParameters( param )) then
      begin
        FreeAndNil( FMixerBitmapTimer );
        Exit;
      end;
      if param.fAlpha <= 0 then
      begin
        FreeAndNil( FMixerBitmapTimer );
        MixerDisable( False );
        Exit;
      end;

      param.fAlpha := param.fAlpha - 0.1;

      if Failed(iBmp.UpdateAlphaBitmapParameters( @param )) then
      begin
        FreeAndNil( FMixerBitmapTimer );
        MixerDisable( False );
      end;
    end;
  end;
begin
  if FVideoMode = vmDefault then
    DisableDefault
  else
    DisableVMR9;
end;

function TxdPlayer.GetMixerBitmapInterface(var AMixerBmp: IVMRMixerBitmap): Boolean;
begin
  Result := IsContainVideo and Assigned(FRenderVideo) and
       Succeeded(FRenderVideo.QueryInterface( IID_IVMRMixerBitmap, AMixerBmp ) );
end;

function TxdPlayer.GetCurrentBitmap(var ABmp: TBitmap): Boolean;
var
  Image: PBitmapInfoHeader;
  BFH: TBITMAPFILEHEADER;
  Stream: TStream;
  wc: IVMRWindowlessControl;
  
  function DibSize: cardinal;
  begin 
    result := (Image.biSize + Image.biSizeImage + Image.biClrUsed * sizeof(TRGBQUAD)); 
  end;
  function DibNumColors: cardinal;
  begin 
    if (image.biClrUsed = 0) and (image.biBitCount <= 8) then
      result := 1 shl integer(image.biBitCount) 
    else    
      result := image.biClrUsed; 
  end;
  function DibPaletteSize: cardinal; 
  begin 
    result := (DibNumColors * sizeof(TRGBQUAD)) 
  end;
  
begin
  Stream := TMemoryStream.Create;
  assert(assigned(Stream));
  result := false;

  if Failed( FRenderVideo.QueryInterface(IID_IVMRWindowlessControl, wc) ) then Exit;
  
//  if FVMR9WinlessCtrl <> nil then
  if Succeeded(wc.GetCurrentImage(PByte(image))) then
  begin
    BFH.bfType      := $4d42; // BM
    BFH.bfSize      := DibSize + sizeof(TBITMAPFILEHEADER);
    BFH.bfReserved1 := 0;
    BFH.bfReserved2 := 0;
    BFH.bfOffBits   := sizeof(TBITMAPFILEHEADER) + image.biSize + DibPaletteSize;
    Stream.Write(BFH, SizeOf(TBITMAPFILEHEADER));
    Stream.Write(image^, BFH.bfSize);
    Stream.Position :=0;
    CoTaskMemFree(image);
    result := true;
  end;
  ABmp.LoadFromStream( Stream );
  Stream.Free;
end;

function TxdPlayer.GetMixerBitmapInterface(var AMixerBmp: IVMRMixerBitmap9): Boolean;
begin
  Result := IsContainVideo and Assigned(FRenderVideo) and
       Succeeded(FRenderVideo.QueryInterface( IID_IVMRMixerBitmap9, AMixerBmp ) );
end;

function TxdPlayer.GetPosition: Cardinal;
var
  nPos: Int64;
begin
  Result := 0;
  if (PlayState = psStop) or not Assigned(FSeeking) then Exit;
  Result := FSeeking.GetCurrentPosition( nPos );
  if Result <> S_OK then
  begin
    Result := 0;
    Exit;
  end;
  Result := nPos div 10000;
end;

function TxdPlayer.GetStreamSplitter(const AFileName: string): TGUID;
var
  mStyle: TMusicStyle;
  i: Integer;
begin
  //�˺����������߲��ŵ�����
  mStyle := GetFileMusicStyle( AFileName );
  if mStyle <> msNULL then
  begin
    for i := Low(CtAryFilters) to High(CtAryFilters) do
    begin
      if CtAryFilters[i].Style = mStyle then
      begin
        Result := StringToGUID( CtAryFilters[i].SplitterCLSID );
        Exit;
      end;
    end;
  end;
  Result := GUID_NULL;
end;

procedure TxdPlayer.HideCursor(bHide: Boolean);
begin
  ShowCursor( bHide );
end;

function TxdPlayer.OpenDS: Boolean;
var
  hr: HRESULT;

  //----------����һ�����Ƶ��Ⱦ��
  function ConfigDefaultVideoRenderer: Boolean;
  begin
    Result := False;
    if not CreateFilter(CLSID_VideoRendererDefault, True, 'xd Default Video Renderer', FRenderVideo) then
    begin
      DoErrorInfo( '�޷�����Ĭ�ϵ���Ƶ��Ⱦ��: %s', [GUIDToString(CLSID_VideoRendererDefault)] );
      Exit;
    end;
    hr := FRenderVideo.QueryInterface(IID_IVideoWindow, FVideoWindow);
    if Failed(hr) then
    begin
      DoErrorInfo( '�޷�����Ƶ��Ⱦ���ϲ�ѯ�ӿ�IID_IVideoWindow��%s', [GetAMErrorText(hr)] );
      Exit;
    end;
    Result := True;
  end;

begin
  FCloseByPlayer := False;
  Result := False;
  if not Succeeded(CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC_SERVER, IID_IGraphBuilder, FGraph)) then
  begin
    DoErrorInfo( '�޷����� IGraphBuilder�����Ȱ�װDirectX' );
    Exit;
  end;
  if FVideoMode = vmDefault then
  begin
    if not ConfigDefaultVideoRenderer then Exit;
    //����Ĭ����Ⱦ��
    ConfigDefaultVMR;
  end
  else
  begin
    if not CreateFilter(CLSID_VideoMixingRenderer9, True, 'xd Video Mixing Renderer9', FRenderVideo) then
    begin
      FVideoMode := vmDefault;
      DoErrorInfo( '�޷�������Ƶ��Ⱦ��9: %s.������ʹ��ϵͳĬ�ϵ���Ƶ��Ⱦ��', [GUIDToString(CLSID_VideoMixingRenderer9)] );
      if not ConfigDefaultVideoRenderer then Exit;
    end
    else
    //����Video Mixing Renderer9 ��Ⱦ������
      ConfigVMR9;
  end;

  hr := NOERROR;
  hr := hr or FGraph.QueryInterface( IID_IMediaControl, FMediaControl );   //ý�����
  hr := hr or FGraph.QueryInterface( IID_IMediaEventEx, FEvent );          //�¼�
  hr := hr or FGraph.QueryInterface( IID_IMediaSeeking, FSeeking );        //�϶�
  hr := hr or FGraph.QueryInterface( IID_IBasicAudio, FRenderAudio );      //��Ƶ����
  if FSeeking <> nil then
    FSeeking.SetTimeFormat( TIME_FORMAT_MEDIA_TIME );
  if not Succeeded(hr) then
    Dbg( '�޷���ѯ����DirectShow�ӿ�, �ڲ���ʱ������Щ�����޷���������' );
  FEvent.SetNotifyFlags( 0 );
  FEvent.SetNotifyWindow( Handle, WM_GRAPHNOTIFY, 0 );

  FAudioFilter := TAudioFilter.Create as IBaseFilter;
  FGraph.AddFilter(FAudioFilter, AudioFilter_Name);

  Result := True;
end;

function TxdPlayer.OpenFile(const AFileName: string): Boolean;
var
  h: HRESULT;
  guid: TGUID;
  bCreateFilter: Boolean;
  pin: IPin;
begin
  Result := False;
  if FPlayState = psCancel then Exit;
  //ֹͣ����
  if FPlayState <> psStop then Stop;
  //���´���
  FPlayState := psOpening;
  if not OpenDS then
  begin
    FCloseByPlayer := True;
    CloseDS;
    Exit;
  end;

  //��׼���Ѿ����úõ���·
  guid := GetStreamSplitter(AFileName);
  bCreateFilter := not IsEqualGUID(guid, GUID_NULL);
  if bCreateFilter then
  begin
    if not CreateFilter(guid, True, 'xdSplitter', FSpliter)  then
    begin
      bCreateFilter := False;
      DoErrorInfo( '�޷������Զ���Filter���Ҳ���ָ��Filter(%s)��������ʹ��ϵͳ��������', [GUIDToString(guid)] );
    end;
  end;
  h := FGraph.RenderFile( StringToOleStr(AFileName), nil );
  Result := Succeeded( h );
  if bCreateFilter and Succeeded( GetUnConnectedPin(FSpliter, PINDIR_INPUT, pin, 0) ) then
  begin
    FGraph.RemoveFilter( FSpliter );
    FSpliter := nil;
  end;
  if not Result then
  begin
    OutputDebugString( PChar(GetAMErrorText(h)) );
    CloseDS;
    Exit;
  end;
  //�����������
  Result := ConfigPlayerAfterLoadFile;
  if Result then
  begin
    if FGraphEdit then
      AddGraphToRot( FGraph, FGraphEditID );
  end
  else
  begin
    CloseDS;
    DoErrorInfo( '�޷����ò���������' );
  end;
  FPlayState := psOpened;
end;

function TxdPlayer.OpenFileStream(const AFileStreamID: Cardinal; const AMaxWaitTime: Cardinal): Boolean;
var
  dwNow: Cardinal;
  bCanPlay: Boolean;
  guid: TGUID;
  bAutoConnect: Boolean;
  filter: IBaseFilter;
label
  llAutoConnect;
begin
  Result := False;
  //ֹͣ����
  if FPlayState = psCancel then Exit;

  if FPlayState <> psStop then Stop;

  FPlayState := psOpening;
  FFileStream := QueryFileStream( AFileStreamID );
  if FFileStream = nil then
  begin
    FPlayState := psStop;
    DoErrorInfo( '�Ҳ���ָ����' );
    Exit;
  end;
  //���´���
  if not OpenDS then
  begin
    FCloseByPlayer := True;
    CloseDS;
    Exit;
  end;

  //�ȴ��ļ��ɲ���
  bCanPlay := True;
  dwNow := GetTickCount;
  while not FFileStream.IsCanPlayNow do
  begin
    Sleep( 50 );
    Application.ProcessMessages;
    if GetTickCount - dwNow > AMaxWaitTime then
    begin
      bCanPlay := FFileStream.IsCanPlayNow;
      Break;
    end;
  end;
  if not bCanPlay then
  begin
    DoErrorInfo( '���㹻����ɲ��ţ����Ժ�����' );
    CloseDS;
    Exit;
  end;
  if FPlayState <> psOpening then
  begin
    CloseDS;
    Exit;
  end;

  //������������Ҫ����
  FAsyncSourceFilter := TxdAsyncFilter.Create;
  FAsyncSourceFilter.SetAsyncFileStream( FFileStream );
  FAsyncSourceFilter.Load( nil, nil );
  {$IFDEF PlayerDebug}
  FFileStream.IsConnected := False;
  {$ENDIF}
  if Failed(FGraph.AddFilter(FAsyncSourceFilter as IBaseFilter, 'xdSourceFilter') ) then
  begin
    DoErrorInfo( '�޷����xdSourceFilter' );
    CloseDS;
    Exit;
  end;

  //��������Ҫ��Splitter
  guid := GetStreamSplitter( FFileStream.FileName );
  bAutoConnect := IsEqualGUID(guid, GUID_NULL);
  if not bAutoConnect  then
  begin
    if not CreateFilter(guid, True, 'xdSplitter', FSpliter)  then
    begin
      bAutoConnect := True;
      DoErrorInfo( '�޷������Զ���Filter���Ҳ���ָ��Filter(%s)��������ʹ��ϵͳ��������', [GUIDToString(guid)] );
      goto llAutoConnect;
    end;


    if Failed( ConnectFilters(FGraph, FAsyncSourceFilter as IBaseFilter, FSpliter) ) then
    begin
      if FPlayState <> psOpening then
      begin
        CloseDS;
        Exit;
      end;
      bAutoConnect := True;
      DoErrorInfo( '�޷�ʹ��ָ����Filter��Ϊ��ǰ�ļ��ķ�������������ʹ��ϵͳ��������' );
      FGraph.RemoveFilter( FSpliter );
      FSpliter := nil;
      goto llAutoConnect;
    end;
    if FPlayState <> psOpening then
    begin
      CloseDS;
      Exit;
    end;

    {$IFDEF PlayerDebug}
    FFileStream.IsConnected := True;
    {$ENDIF}
    if not RenderOutPin( FSpliter ) then
    begin
      bAutoConnect := True;
      DoErrorInfo( '�޷�����ָ��Fitler, �ļ�����%s, ��Ҫ���ӵ�Filter: %s��������ʹ��ϵͳ��������', [FFileStream.FileName, GUIDToString(guid)] );
      FSpliter := nil;
      goto llAutoConnect;
    end;
  end;

llAutoConnect: //ϵͳ��������
  if bAutoConnect then
  begin
    {��ϵͳֱ��ȥ�������ӣ������������: WMV MPEG; AVI��ʽ������������}
    DoErrorInfo( 'ʹ����������ȥ���Բ����ļ���%s', [FFileStream.FileName] );
    filter := FAsyncSourceFilter as IBaseFilter;
    Result := RenderOutPin( filter );
    if not Result then
    begin
      DoErrorInfo( '�޷�ʹ����������ȥ�����ļ���%s', [FFileStream.FileName] );
      CloseDS;
      Exit;
    end;
    {$IFDEF PlayerDebug}
    FFileStream.IsConnected := True;
    {$ENDIF}
  end;

  //�����������
  Result := ConfigPlayerAfterLoadFile;
  if Result then
  begin
    if FGraphEdit then
      AddGraphToRot( FGraph, FGraphEditID );
  end
  else
  begin
    CloseDS;
    DoErrorInfo( '�޷����ò���������' );
  end;
  FPlayState := psOpened;
end;

procedure TxdPlayer.Play;
begin
  if FPlayState = psCancel then Exit;
  if Assigned(FMediaControl) then
  begin
    if (FPlayState = psOpened) or (FPlayState = psPause) then
    begin
      if Succeeded(FMediaControl.Run) then
        FPlayState := psPlay;
    end;         
  end;
end;

procedure TxdPlayer.ReleaseFullScreen;
begin
  if Assigned(FFullSrceenForm) then
  begin
    FFullSrceenForm.Visible := False;
    with TTimer.Create( Self ) do
    begin
      OnTimer := DoFreeFullScreenForm;
      Interval := 30000;   //30��֮���Զ��ͷ�
      Enabled := True;
    end;
  end;
end;

function TxdPlayer.RenderOutPin(var AFilter: IBaseFilter): Boolean;
var
  pinEnum: IEnumPins;
  pin: IPin;
  fetchCount: Cardinal;
  pinInfo: TPinInfo;
begin
  Result := False;
  if not Succeeded(AFilter.EnumPins(pinEnum)) then Exit;
  pinEnum.Reset;

  fetchCount := 0;
  while Succeeded(pinEnum.Next(1, pin, @fetchCount)) and (fetchCount <> 0) do
  begin
    if Succeeded(pin.QueryPinInfo(pinInfo)) then
    begin
      pinInfo.pFilter := nil;
      if pinInfo.dir = PINDIR_OUTPUT then
      begin
        if Succeeded(FGraph.Render(pin)) then
          Result := True;
      end;
    end;
    pin := nil;
  end;
  pinEnum := nil;
end;

procedure TxdPlayer.Resize;
var
  R: TRect;
begin
  inherited;
  if FPlayState <> psStop then
  begin
    if (FVideoMode = vmVMR9) and Assigned(FVMR9WinlessCtrl) then
    begin
      R := GetClientRect;
      FVMR9WinlessCtrl.SetVideoPosition( nil, @R );
    end
    else if (FVideoMode = vmDefault) and Assigned(FVideoWindow) then
      FVideoWindow.SetWindowPosition(0, 0, Width, Height);
  end;
end;

function TxdPlayer.MixerBitmap(const AMixerInfo: TVideoMixerBitmapInfo): Boolean;
  function SetDefaulMixer: Boolean;
  var
    iBmp: IVMRMixerBitmap;
    param: TVMRAlphaBitmap;
    h: HRESULT;
  begin
    Result := GetMixerBitmapInterface( iBmp );
    if Result then
    begin
      param.dwFlags := VMRBITMAP_HDC or VMRBITMAP_SRCCOLORKEY;
      param.hdc := AMixerInfo.FDC;
      param.pDDS := nil;
      param.rSrc := AMixerInfo.FSrcRect;
      param.rDest.left := AMixerInfo.FDestLeft;
      param.rDest.top := AMixerInfo.FDestTop;
      param.rDest.right := AMixerInfo.FDestRight;
      param.rDest.bottom := AMixerInfo.FDestBottom;
      param.fAlpha := AMixerInfo.FAlphaValue;
      param.clrSrcKey := AMixerInfo.FclrSrcKey;

      h := ibmp.SetAlphaBitmap( param );
      if Failed( h ) then
        DoErrorInfo( 'Error��%s', [GetAMErrorText(h)] )
      else
        Result := True;
      iBmp := nil;
    end;
  end;

  function SetVMR9Mixer: Boolean;
  var
    iBmp9: IVMRMixerBitmap9;
    param9: TVMR9AlphaBitmap;
    h: HRESULT;
  begin
    Result := GetMixerBitmapInterface( iBmp9 );
    if Result then
    begin
      param9.dwFlags := VMRBITMAP_HDC or VMRBITMAP_SRCCOLORKEY;
      param9.hdc := AMixerInfo.FDC;
      param9.pDDS := nil;
      param9.rSrc := AMixerInfo.FSrcRect;
      param9.rDest.left := AMixerInfo.FDestLeft;
      param9.rDest.top := AMixerInfo.FDestTop;
      param9.rDest.right := AMixerInfo.FDestRight;
      param9.rDest.bottom := AMixerInfo.FDestBottom;
      param9.fAlpha := AMixerInfo.FAlphaValue;
      param9.clrSrcKey := AMixerInfo.FclrSrcKey;

      h := ibmp9.SetAlphaBitmap( @param9 );
      if Failed( h ) then
        DoErrorInfo( 'Error��%s', [GetAMErrorText(h)] )
      else
        Result := True;
      ibmp9 := nil;
    end;
  end;
begin
  if Assigned(FMixerBitmapTimer) then
    FreeAndNil( FMixerBitmapTimer );
  if FVideoMode = vmDefault then
    Result := SetDefaulMixer
  else
    Result := SetVMR9Mixer;
end;

function TxdPlayer.MixerBitmapInfo(var AMixerInfo: TVideoMixerBitmapInfo): Boolean;
var
  iBmp: IVMRMixerBitmap;
  param: TVMRAlphaBitmap;
  iBmp9: IVMRMixerBitmap9;
  param9: TVMR9AlphaBitmap;
begin
  if FVideoMode = vmDefault then
  begin
    Result := GetMixerBitmapInterface( iBmp );
    if Result then
    begin
      iBmp.GetAlphaBitmapParameters( param );
      VMRToMixerBmpInfo( param, AMixerInfo );
    end;
  end
  else
  begin
    Result := GetMixerBitmapInterface( iBmp9 );
    if Result then
    begin
      iBmp9.GetAlphaBitmapParameters( param9 );
      VMRToMixerBmpInfo( param9, AMixerInfo );
    end;
  end;
end;

procedure TxdPlayer.MixerDisable(const AAnimateBmp: Boolean);
  function SetDefaulMixer: Boolean;
  var
    iBmp: IVMRMixerBitmap;
    param: TVMRAlphaBitmap;
    h: HRESULT;
  begin
    Result := GetMixerBitmapInterface( iBmp );
    if Result then
    begin
      ZeroMemory( @param, SizeOf(param) );
      param.dwFlags := VMRBITMAP_DISABLE;
      h := ibmp.SetAlphaBitmap( param );
      if Failed( h ) then
        DoErrorInfo( 'Error��%s', [GetAMErrorText(h)] )
      else
        Result := True;
      iBmp := nil;
    end;
  end;

  function SetVMR9Mixer: Boolean;
  var
    iBmp9: IVMRMixerBitmap9;
    param9: TVMR9AlphaBitmap;
    h: HRESULT;
  begin
    Result := GetMixerBitmapInterface( iBmp9 );
    if Result then
    begin
      ZeroMemory( @param9, SizeOf(param9) );
      param9.dwFlags := VMRBITMAP_DISABLE;
      h := ibmp9.SetAlphaBitmap( @param9 );
      if Failed( h ) then
        DoErrorInfo( 'Error��%s', [GetAMErrorText(h)] )
      else
        Result := True;
      ibmp9 := nil;
    end;
  end;
begin
  if not AAnimateBmp then
  begin
    if FVideoMode = vmDefault then
      SetDefaulMixer
    else
      SetVMR9Mixer;
  end
  else
  begin
    if not Assigned(FMixerBitmapTimer) then
    begin
      FMixerBitmapTimer := TTimer.Create( Self );
      FMixerBitmapTimer.Interval := 100;
      FMixerBitmapTimer.OnTimer := DoTimeToDisableMixerBitmap;
      FMixerBitmapTimer.Enabled := True;
    end;
  end;
end;

procedure TxdPlayer.SetAudioState(const Value: TAudioState);
var
  pAudioState: IAudioState;
begin
  FAudioState := Value;
  if Assigned(FAudioFilter) and Succeeded(FAudioFilter.QueryInterface(IAudioState, pAudioState)) then
  begin
    try
      pAudioState.put_State(FAudioState);
    finally
      pAudioState := nil;
    end;
  end;
end;

procedure TxdPlayer.SetEnableMixerBmp(const Value: Boolean);
begin
  if (FEnableMixerBmp <> Value) and (FPlayState = psStop) then
    FEnableMixerBmp := Value;
end;

procedure TxdPlayer.SetFullScreen(const Value: Boolean);
var
  h: HWND;
begin
  if FFullScreen <> Value then
  begin
    FFullScreen := Value;
    if Value then
    begin
      CreateFullSrceen;
      h := FFullSrceenForm.Handle;
    end
    else
    begin
      ReleaseFullScreen;
      h := Handle;
    end;
    ChangedVideoPosition( h );
    ShowCursor( not Value );
  end;
end;

procedure TxdPlayer.SetGraphEdit(const Value: Boolean);
begin
  if FGraphEdit <> Value then
  begin
    FGraphEdit := Value;
    if Assigned(FGraph) then
    begin
      if FGraphEdit then
        AddGraphToRot(FGraph, FGraphEditID)
      else if FGraphEditID <> 0 then
      begin
        RemoveGraphFromRot(FGraphEditID);
        FGraphEditID := 0;
      end;
    end;
  end;
end;

procedure TxdPlayer.SetMute(const Value: Boolean);
begin
  if FMute <> Value then
  begin
    FMute := Value;
    SetVolume(FVolume);
  end;
end;

procedure TxdPlayer.SetPosition(const Value: Cardinal);
var
  nPos, nDur: Int64;
  fPer: Double;
begin
  if PlayState = psStop then Exit;
  if Assigned(FSeeking) and FIsCanSeek then
  begin
    nPos := Int64(Value)*10000 ;
    nDur := Int64(FDuration) * 10000;
    if Assigned(FFileStream) then
    begin
      fPer := Value / FDuration;
      FFileStream.SetDownPosition( fPer  );
    end;
    if Assigned(FSeeking) then
      FSeeking.SetPositions(nPos, AM_SEEKING_AbsolutePositioning, nDur, AM_SEEKING_AbsolutePositioning);
  end;
end;

procedure TxdPlayer.SetShowVideoByWinHandle(const Value: HWND);
begin
  if Value = 0 then
    ChangedVideoPosition( Handle )
  else if FCurShowWinHandle <> Value then
    ChangedVideoPosition( Value );
end;

procedure TxdPlayer.SetVideoMode(const Value: TVideoMode);
var
  vmr9: IBaseFilter;
begin
  if (FPlayState = psStop) and (FVideoMode <> Value) then
  begin
    if Value = vmVMR9 then
    begin
      if CreateFilter(CLSID_VideoMixingRenderer9, False, '', vmr9) then
      begin
        FVideoMode := vmVMR9;
        vmr9 := nil;
      end;
    end
    else
      FVideoMode := Value;
  end;
end;

procedure TxdPlayer.SetVolume(const Value: Integer);
begin
  FVolume := EnsureRange(Value, 0, 100);
  if not Assigned(FRenderAudio) then Exit;
  if FMute then
    FRenderAudio.put_Volume(-10000)
  else if FLinearVolume then
    FRenderAudio.put_Volume(Round(1085.73 * ln(FVolume * 100 + 1)) - 10000)
  else
    FRenderAudio.put_Volume(FVolume * 100 - 10000);
end;

procedure TxdPlayer.Stop;
var
  p: IPin;
begin
  if FPlayState in [psCancel, psStop] then Exit;
  if FPlayState = psOpening then
  begin
    FPlayState := psCancel;
    if Assigned(FAsyncSourceFilter) then
    begin
      FAsyncSourceFilter.FilterStop := True;
      p := GetPin( FAsyncSourceFilter as IBaseFilter, PINDIR_OUTPUT, 0 );
      if Assigned(p) then
      begin
        p.Disconnect;
        p := nil;
      end;
    end;
    if Assigned(FGraph) then
      FGraph.Abort;
  end
  else if FPlayState <> psStop then
  begin
    CloseDS;
    Invalidate;
  end;
end;

procedure TxdPlayer.VMRToMixerBmpInfo(const AVMR9: TVMR9AlphaBitmap; AMixerBmpInfo: TVideoMixerBitmapInfo);
begin
  AMixerBmpInfo.FDC := AVMR9.hdc;
  AMixerBmpInfo.FSrcRect := AVMR9.rSrc;
  AMixerBmpInfo.FDestLeft := AVMR9.rDest.left;
  AMixerBmpInfo.FDestTop := AVMR9.rDest.top;
  AMixerBmpInfo.FDestRight := AVMR9.rDest.right;
  AMixerBmpInfo.FDestBottom := AVMR9.rDest.bottom;
  AMixerBmpInfo.FAlphaValue := AVMR9.fAlpha;
  AMixerBmpInfo.FclrSrcKey := AVMR9.clrSrcKey;
end;

procedure TxdPlayer.VMRToMixerBmpInfo(const AVMR: TVMRAlphaBitmap; AMixerBmpInfo: TVideoMixerBitmapInfo);
begin
  AMixerBmpInfo.FDC := AVMR.hdc;
  AMixerBmpInfo.FSrcRect := AVMR.rSrc;
  AMixerBmpInfo.FDestLeft := AVMR.rDest.left;
  AMixerBmpInfo.FDestTop := AVMR.rDest.top;
  AMixerBmpInfo.FDestRight := AVMR.rDest.right;
  AMixerBmpInfo.FDestBottom := AVMR.rDest.bottom;
  AMixerBmpInfo.FAlphaValue := AVMR.fAlpha;
  AMixerBmpInfo.FclrSrcKey := AVMR.clrSrcKey;
end;

procedure TxdPlayer.Paint;
begin
  if not (FPlayState in [psPlay, psPause]) or not IsContainVideo then
  begin
    TControlCanvas(Canvas).UpdateTextFlags;
    Canvas.Brush.Color := 0;
    Canvas.FillRect(Rect(0, 0, Width, Height));
  end
  else
  begin
    if (FVideoMode = vmVMR9) and Assigned(FVMR9WinlessCtrl) then
    begin
      FVMR9WinlessCtrl.RepaintVideo( Handle, Canvas.Handle );
//      OutputDebugString( 'ssssssssssssssssssssssssssssssss' );
    end
    else if (FVideoMode = vmDefault) and Assigned(FVideoWindow) then
    begin
//        FVideoWindow.SetWindowForeground( 0 );
//        FVideoWindow.SetWindowPosition( 0, 0, Width, Height );
//        OutputDebugString( 'xxxxxxxxxxxxxxx' );
    end;
  end;
end;

procedure TxdPlayer.Pause;
begin
  if FPlayState = psCancel then Exit;
  if Assigned(FMediaControl) then
  begin
    if (FPlayState = psPlay) then
    begin
      if Succeeded(FMediaControl.Pause) then
        FPlayState := psPause;
    end;
  end;
end;

procedure TxdPlayer.WMDisplayChange(var Message: TMessage);
begin
  inherited;
end;

procedure TxdPlayer.WMEraseBkGnd(var Message: TWMEraseBkGnd);
begin
  Message.Result := 1;
end;

procedure TxdPlayer.WMGraphNotify(var Message: TMessage);
var
  EventCode, Param1, Param2: Integer;
begin
  if Assigned(FEvent) then
  begin
    EventCode:= 0;
    Param1:= 0;
    Param2:= 0;
    while FEvent.GetEvent(EventCode,Param1,Param2,0) = S_OK do
    begin
      FEvent.FreeEventParams(EventCode,Param1,Param2);
      Dbg( 'DirectShow �¼���%d', [EventCode] );
      case EventCode of
        EC_COMPLETE: PostMessage(Handle, WM_StopPlayer, 0, 0 );
//        EC_USERABORT,//:  OutputDebugString( 'EC_USERABORT');
//        EC_ERRORABORT: //OutputDebugString( 'EC_ERRORABORT');

      end;
    end;
  end;
end;

procedure TxdPlayer.WMStopPlayer(var message: TMessage);
begin
  FCloseByPlayer := True;
  Stop;
end;

procedure InitPlayerFilter;
var
  strPath, strFilter: string;
  i: Integer;
begin
  CoInitialize( nil );
  strPath := ExtractFilePath( ParamStr(0) );
  for i := Low(CtAryFilters) to High(CtAryFilters) do
  begin
    if not IsFillterRegistered(StringToGUID(CtAryFilters[i].SplitterCLSID)) then
    begin
       strFilter := strPath + CtFilterPath + CtAryFilters[i].SplitterFileName;
       if FileExists(strFilter) then
         RegisterFilter( strFilter );
    end;
  end;
end;

initialization
  InitPlayerFilter;
finalization
  CoUninitialize;

end.
