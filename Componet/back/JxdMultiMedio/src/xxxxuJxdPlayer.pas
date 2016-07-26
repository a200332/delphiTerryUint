unit uJxdPlayer;

//{$define JxdPlayerDebug}

interface
uses
  {$ifdef JxdPlayerDebug}uDebugInfo, {$endif}
  Windows, Classes, SysUtils, Messages, DirectShow9, ActiveX, Controls, BaseClass, DSUtil,
  ExtCtrls, uJxdAudioFilter, Graphics, Forms;

const
  CtWMPlayComplete = WM_USER + 524;  

type
  TZoomMode = (zmNone, zm100, zm150, zm200);
  TJxdPlayerMode = ( pmNoToOpened, pmOpened, pmPlaying, pmStoped, pmPaused );
{$M+}
  TxdPlayer = class(TCustomPanel)
  public
    function  Open(const AFileName: string): Boolean;
    function  Play: Boolean;
    procedure Pause;
    procedure Stop;

    procedure RepaintVideo;

    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
  protected
    procedure Close;
    procedure DoErrorHResult(const ARet: HRESULT);
    procedure SetVideoPosition;
    function  GetEventCode: Integer;
    function  AddVideoMixingRenderToFilterGraph: HRESULT;
    function  RenderFile: Boolean;
    function  GetPlayerEventHandle: Cardinal;
    procedure DoPlayerEventHandleExecute;
    procedure DoThreadEnd;

    procedure Paint; override;
    procedure DblClick; override;

    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure WMDisplayChange(var Message: TMessage); message WM_DISPLAYCHANGE;
    procedure WMPlayComplete(var message: TMessage); message CtWMPlayComplete;

    procedure OnMove; virtual;
    procedure OnPaint; virtual;
    procedure OnSize; virtual;

    procedure DoPause;
    procedure DoPlayComplete;
    procedure DispChange(ASetMsg: Boolean = False; ASetHandle: Boolean = True);
  private
    //DirectShow �ӿ�
    FFilterGraph: IFilterGraph;
    FGraphBuilder: IGraphBuilder;
    FMediaControl: IMediaControl;
    FMediaSeek: IMediaSeeking;
    FMediaEvent: IMediaEvent;
    FVmrWC: IVMRWindowlessControl;
    FVmrMixCtrl: IVMRMixerControl;
    FAudioFilter: TAudioFilter;
    FAudioControl: IBasicAudio;
    FVideoRender: IBaseFilter;
    FVideoWindow:  IVideoWindow;

    FPlayerMode: TJxdPlayerMode;
    FMediaHandle: Cardinal;

    FFileName: WideString;
    FBackBitmap: TBitmap;
    FStoping: Boolean;
  private
    FAudioState: TAudioState;
    FOnPlay: TNotifyEvent;
    FOnPause: TNotifyEvent;
    FOnStop: TNotifyEvent;
    FIsContainVideo: Boolean;
    FVolume: Integer;
    FFullDisp: Boolean;
    function GetCurPlayPos: Int64;
    function GetCurTimeFormat: TGUID;
    function GetDuration: Int64;
    procedure SetCurPlayPos(const Value: Int64);
    procedure SetAudioState(const Value: TAudioState);
    procedure SetBackBitmap(const Value: TBitmap);
    procedure SetVolume(const Value: Integer);
    function  GetVolume: Integer;
    procedure SetFullDisp(const Value: Boolean);
  published
    property Align;
    property Alignment;
    property Anchors;
    property Color;
    property TabStop;
    property OnClick;
    property OnDblClick;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnCanResize;
    
    property BackBitmap: TBitmap read FBackBitmap write SetBackBitmap;
    property Duration: Int64 read GetDuration;                         //��λ: ʮ�ڷ�֮һ ��
    property CurPlayPos: Int64 read GetCurPlayPos write SetCurPlayPos; //��λ: ʮ�ڷ�֮һ ��
    property CurTimeFormat: TGUID read GetCurTimeFormat;
    property CurPlayerMode: TJxdPlayerMode read FPlayerMode;
    property AudioState: TAudioState read FAudioState write SetAudioState; //��������
    property IsContainVideo: Boolean read FIsContainVideo;
    property Volume: Integer read GetVolume write SetVolume default 100;
    property FullScreen: Boolean read FFullDisp write SetFullDisp;

    property OnPlay: TNotifyEvent read FOnPlay write FOnPlay;
    property OnPause: TNotifyEvent read FOnPause write FOnPause;
    property OnStop: TNotifyEvent read FOnStop write FOnStop;
  end;
{$M-}

  TPlayerEventHandle = class(TThread)
  public
    constructor Create(AOwnerPlayer: TxdPlayer);
    destructor  Destroy; override;
  protected
    procedure Execute; override;
  private
    FOwnerPlayer: TxdPlayer;
  end;

implementation

{ TJxdPlayer }


const
  IID_IUnknown: TGUID = ( D1:$00000000;D2:$0000;D3:$0000;D4:($C0,$00,$00,$00,$00,$00,$00,$46) );

procedure JxdPlayerDebug(const AInfo: string); overload;
begin
  OutputDebugString( PChar(AInfo) );
  {$ifdef JxdPlayerDebug}
  _Log( AInfo, 'PlayerInfo.txt' );
  {$endif}
end;

procedure JxdPlayerDebug(const AInfo: string; const Args: array of const); overload;
begin
  JxdPlayerDebug( Format(AInfo, Args) );
end;

function TxdPlayer.AddVideoMixingRenderToFilterGraph: HRESULT;
var
  pConfig: IVMRFilterConfig;
  pMonitorConfig: IVMRMonitorConfig;
  hRes: HRESULT;
  guid: VMRGUID;
begin
  Result := CoCreateInstance( CLSID_VideoMixingRenderer, nil, CLSCTX_INPROC,
                            IID_IBaseFilter, FVideoRender );
  if Failed(Result) then Exit;

  Result := FFilterGraph.AddFilter( FVideoRender, StringToOleStr('JxdVideo Mixing Render') );
  if Failed(Result) then Exit;

//  hRes := FVideoRender.QueryInterface( IID_IVMRFilterConfig, pConfig );
//  if Succeeded(hRes) then
//  begin
//    pConfig.SetNumberOfStreams( 2 );
//    pConfig.SetRenderingMode( VMRMode_Windowless );
//    pConfig.SetRenderingPrefs( RenderPrefs_AllowOverlays );
//    pConfig := nil;
//  end;
//  hRes := FVideoRender.QueryInterface( IID_IVMRMonitorConfig, pMonitorConfig );
//  if Succeeded(hRes) then
//  begin
//    pMonitorConfig.GetMonitor( guid );
//    pMonitorConfig := nil;
//  end;
//
//  Result := FVideoRender.QueryInterface( IID_IVMRWindowlessControl, FVmrWC );
//
//  if Succeeded(Result) then
//  begin
//    FVmrWC.SetVideoClippingWindow( Handle );
//    FVmrWC.SetAspectRatioMode( VMR_ARMODE_LETTER_BOX );
//  end
//  else
//    FVmrWC := nil;
end;

procedure TxdPlayer.Close;
begin
  if Assigned(FVideoWindow) then
  begin
    FVideoWindow.put_MessageDrain(0);
    FVideoWindow.put_Visible(False);
    FVideoWindow := nil;
  end;
  FMediaHandle := 0;
  FMediaEvent  := nil;
  FAudioControl:= nil;
  FVmrMixCtrl  := nil;
  FMediaSeek   := nil;
  FVmrWC       := nil;
  FMediaControl:= nil;
  FAudioFilter := nil;
  FGraphBuilder:= nil;
  FVideoRender := nil;
  FFilterGraph := nil;
  FPlayerMode  := pmNoToOpened;
  CoUninitialize;
end;

constructor TxdPlayer.Create(AOwner: TComponent);
begin
  inherited;
  FFilterGraph := nil;
  FGraphBuilder:= nil;
  FMediaControl:= nil;
  FMediaSeek   := nil;
  FMediaEvent  := nil;
  FVmrWC       := nil;
  FVmrMixCtrl  := nil;
  FMediaHandle := 0;
  FAudioFilter := nil;
  FAudioControl:= nil;

  FAudioState := asAll;
  
  FPlayerMode  := pmNoToOpened;
  FBackBitmap  := TBitmap.Create;
  FStoping := False;
  FVolume := 100;
end;

procedure TxdPlayer.DblClick;
begin
  inherited;
  FullScreen := not FullScreen;
end;

destructor TxdPlayer.Destroy;
begin
  Stop;
  FBackBitmap.Free;
  inherited;
end;

procedure TxdPlayer.DispChange(ASetMsg, ASetHandle: Boolean);
const
  CZoom: array[TZoomMode] of Integer = (0, 100, 150, 200);
  CARMODE: array[Boolean] of TVMRAspectRatioMode = (VMR_ARMODE_NONE, VMR_ARMODE_LETTER_BOX);
var
  VMRConfig: IVMRFilterConfig9;
  AspectRatioControl: IVMRAspectRatioControl9;
  VMRMixer: IVMRMixerControl9;
  pVideo: IBasicVideo;
  R: TVMR9NormalizedRect;
  W, H, VW, VH: Integer;
  AspectRatio: Boolean;
begin
  if Assigned(FVideoWindow) and FIsContainVideo then
  begin
    if ASetMsg then
    begin
      if Succeeded(FVideoRender.QueryInterface(IID_IVMRFilterConfig9, VMRConfig)) then
      begin
        VMRConfig.SetRenderingMode(VMR9Mode_Windowed);
        VMRConfig := nil;
      end;
      FVideoWindow.put_MessageDrain(Handle);
      FVideoWindow.put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS);
//      if FFullDisp then
        FVideoWindow.put_WindowStyleEx(WS_EX_TOPMOST);
    end;
    if FFullDisp then
    begin
      W := GetSystemMetrics(SM_CXSCREEN);
      H := GetSystemMetrics(SM_CYSCREEN);
    end
    else
    begin
      W := Width;
      H := Height;
    end;

    AspectRatio := True;//FZoom = zmNone;
    if Succeeded(FVideoRender.QueryInterface(IID_IVMRMixerControl9, VMRMixer)) then
    begin
      R.left := 0;
      R.top := 0;
      R.right := 1;
      R.bottom := 1;

      VMRMixer.SetOutputRect(0, @R);
      VMRMixer.SetAlpha(1, 0.2);
      VMRMixer := nil;
    end;

    if Succeeded(FVideoWindow.QueryInterface(IID_IVMRAspectRatioControl9, AspectRatioControl)) then
    begin
      AspectRatioControl.SetAspectRatioMode(CARMODE[AspectRatio]);
      AspectRatioControl := nil;
    end;

    if ASetHandle then
        FVideoWindow.put_Owner(Handle)
      else
        FVideoWindow.put_Owner(0);
    FVideoWindow.SetWindowPosition(0, 0, W, H);
    FVideoWindow.put_FullScreenMode( FFullDisp );
  end;
end;

procedure TxdPlayer.DoErrorHResult(const ARet: HRESULT);
var
  res: Cardinal;
  pBuf: array[0..MAX_ERROR_TEXT_LEN] of Char;
begin
  res := AMGetErrorText( ARet, pBuf, MAX_ERROR_TEXT_LEN );
  if res = 0 then
    JxdPlayerDebug( 'Unkown Error' )
  else
    JxdPlayerDebug( pBuf );
end;

procedure TxdPlayer.DoPlayComplete;
begin
  if Assigned(OnStop) then
    OnStop( Self );
end;

procedure TxdPlayer.DoPlayerEventHandleExecute;
var
  dwResult: Cardinal;
  h: Cardinal;
  nEventCode: Integer;
begin
  h := GetPlayerEventHandle;
  if h <> 0 then
  begin
    dwResult := WaitForSingleObject( h, 1000 );
    if dwResult <> WAIT_TIMEOUT then
    begin
      nEventCode := GetEventCode;
      JxdPlayerDebug( PChar('PlayerCmd: ' + IntToStr(nEventCode)) );
      case nEventCode of
        EC_COMPLETE:
        begin
          FStoping := True;
          PostMessage( Handle, CtWMPlayComplete, 0, 0 );
        end;
      end;
    end;
  end;
end;

procedure TxdPlayer.DoThreadEnd;
begin
  FStoping := False;
end;

function TxdPlayer.GetCurPlayPos: Int64;
begin
  if FMediaSeek <> nil then
    FMediaSeek.GetCurrentPosition( Result )
  else
    Result := 0;
end;

function TxdPlayer.GetCurTimeFormat: TGUID;
begin
  if FMediaSeek <> nil then
    FMediaSeek.GetTimeFormat( Result )
  else
    Result := TIME_FORMAT_NONE;
end;

function TxdPlayer.GetDuration: Int64;
begin
  if FMediaSeek <> nil then
    FMediaSeek.GetDuration( Result )
  else
    Result := 0;
end;

function TxdPlayer.GetEventCode: Integer;
var
  nCode, nParam1, nParam2: Integer;
  hRes: HRESULT;
begin
  nCode := -1;
  if Assigned(FMediaEvent) then
  begin
    hRes := FMediaEvent.GetEvent( nCode, nParam1, nParam2, 0 );
    if Failed(hRes) then
      DoErrorHResult( hRes )
    else
      FMediaEvent.FreeEventParams( nCode, nParam1, nParam2 );
  end;
  Result := nCode;
end;

function TxdPlayer.GetPlayerEventHandle: Cardinal;
var
  hEvent: OAEVENT;
begin
  if FMediaEvent <> nil then
    if FMediaHandle = 0 then
    begin
      FMediaEvent.GetEventHandle( hEvent );
      FMediaHandle := hEvent;
    end;
  Result := FMediaHandle;
end;

function TxdPlayer.GetVolume: Integer;
var
  nVolume: Integer;
begin
  if Assigned(FAudioControl) then
  begin
    FAudioControl.get_Volume(nVolume);
    Result := (nVolume + 10000) div 100;
  end
  else
    Result := 100;

//  OutputDebugString( PChar(IntToStr(FVolume * 100 - 10000)) );
end;

procedure TxdPlayer.OnMove;
begin
  
end;

procedure TxdPlayer.OnPaint;
var
  dc: HDC;
begin
  if Assigned(FVmrWC) then
  begin
    dc := GetDC( Handle );
    FVmrWC.RepaintVideo( Handle, dc );
    ReleaseDC( Handle, dc );
  end;
end;

procedure TxdPlayer.DoPause;
begin
  if Assigned(OnPause) then
    OnPause( Self );
end;

procedure TxdPlayer.OnSize;
begin
  SetVideoPosition;
  OnPaint;
end;

function CheckFilterConnected(pFilter: IBaseFilter; bAllPin: Boolean = False): Boolean;
var
  ppEnum: IEnumPins;
  pPin, pTo: IPin;
  bConnected: Boolean;
begin
  Result := False;
  if pFilter = nil then Exit;
  if Succeeded(pFilter.EnumPins(ppEnum)) then
    try
      bConnected := False;
      while ppEnum.Next(1, pPin, nil) = S_OK do
      begin
        if pPin.ConnectedTo(pTo) = S_OK then
        begin
          bConnected := True;
          if not bAllPin then Break;
        end
        else if bAllPin then
          Exit;
      end;
      Result := bConnected;
    finally
      pTo := nil;
      pPin := nil;
    end;
end;

function TxdPlayer.Open(const AFileName: string): Boolean;
var
  pUnk: IUnknown;
  hRes: HRESULT;
begin
  Result := False;
  if FPlayerMode <> pmNoToOpened then Exit;

  hRes := CoInitializeEx( nil, COINIT_APARTMENTTHREADED );
  if S_FALSE = hRes then CoUninitialize;

  hRes := CoCreateInstance( CLSID_FilterGraph, nil, CLSCTX_INPROC, IID_IUnknown, pUnk );
  if Failed(hRes) then
  begin
    DoErrorHResult(hRes);
    Close;
    Exit;
  end;

  try
    hRes := pUnk.QueryInterface( IID_IFilterGraph, FFilterGraph );
    if Failed(hRes) then
    begin
      DoErrorHResult(hRes);
      Close;
      Exit;
    end;

    hRes := AddVideoMixingRenderToFilterGraph;
    if Failed(hRes) then
    begin
      DoErrorHResult(hRes);
      Close;
      Exit;
    end;

    hRes := pUnk.QueryInterface( IID_IGraphBuilder, FGraphBuilder );
    if Failed(hRes) then
    begin
      DoErrorHResult( hRes );
      Close;
      Exit;
    end;

    //��ѯý����ؽӿ�
//    hRes := FVmrWC.QueryInterface( IID_IVMRMixerControl, FVmrMixCtrl );
//    if Failed(hRes) then
//    begin
//      DoErrorHResult( hRes );
//      Close;
//      Exit;
//    end;

    hRes := pUnk.QueryInterface( IID_IMediaControl, FMediaControl );
    if Failed(hRes) then
    begin
      DoErrorHResult( hRes );
      Close;
      Exit;
    end;

    pUnk.QueryInterface( IID_IMediaEvent, FMediaEvent );
    pUnk.QueryInterface( IID_IMediaSeeking, FMediaSeek );


    //����������ƹ�����
    FAudioFilter := TAudioFilter.Create;
    FFilterGraph.AddFilter( FAudioFilter as IBaseFilter, 'Jxd AudioState Handle' );

    FFileName := StringToOleStr( AFileName );
    if not RenderFile then
    begin
      Close;
      Exit;
    end;
    SetVideoPosition;
//    FIsContainVideo := CheckFilterConnected( FVmrWC as IBaseFilter );
    FPlayerMode := pmOpened;

    FGraphBuilder.QueryInterface( IID_IBasicAudio, FAudioControl );

    FVideoRender.QueryInterface( IID_IVideoWindow, FVideoWindow );
    FIsContainVideo := CheckFilterConnected( FVideoRender );
    DispChange(True);
  finally
    pUnk := nil;
  end;
  AudioState := AudioState;
  TPlayerEventHandle.Create( Self );
  Result := True;
end;

procedure TxdPlayer.Paint;
begin
  if not IsContainVideo then
  begin
    if (FBackBitmap.Width > 0) and (FBackBitmap.Height > 0) then
      Canvas.CopyRect( Rect(0, 0, Width, Height), FBackBitmap.Canvas, Rect(0, 0, FBackBitmap.Width, FBackBitmap.Height) )
    else
      inherited;
    Exit;
  end; 
  case FPlayerMode of
    pmNoToOpened,
    pmOpened:
    begin
      if (FBackBitmap.Width > 0) and (FBackBitmap.Height > 0) then
        Canvas.CopyRect( Rect(0, 0, Width, Height), FBackBitmap.Canvas, Rect(0, 0, FBackBitmap.Width, FBackBitmap.Height) )
      else
        inherited;
    end;
    pmPlaying,
    pmStoped,
    pmPaused:   OnPaint;
  end;
end;

procedure TxdPlayer.Pause;
begin
  if Assigned(FMediaControl) then
  begin
    if Succeeded(FMediaControl.Pause) then
      FPlayerMode := pmPaused;
  end;
  if FPlayerMode = pmPaused then
    DoPause;
end;

function TxdPlayer.Play: Boolean;
begin
  Result := False;
  if Assigned(FMediaControl) then
  begin
    Result := Succeeded( FMediaControl.Run );
    if Result then
      FPlayerMode := pmPlaying;
  end;
  if Assigned(OnPlay) and (FPlayerMode = pmPlaying) then
    OnPlay( Self );
  OnPaint;
end;

function TxdPlayer.RenderFile: Boolean;
var
  hRes: HRESULT;
begin
  Result := False;
  //��ʱֱ��ʹ����������,�������ж��ļ���ʽ��Ȼ����ֱ��ʹ��Filter����
  if FileExists(FFileName) then
  begin
    //�����ļ�����
    hRes := FGraphBuilder.RenderFile( PWideChar(FFileName), nil);
    Result := Succeeded( hRes );
    if not Result then
      DoErrorHResult( hRes );
  end;
end;

procedure TxdPlayer.RepaintVideo;
begin
  if FPlayerMode = pmPaused then
    OnPaint;
end;

procedure TxdPlayer.SetAudioState(const Value: TAudioState);
begin
  FAudioState := Value;
  if Assigned(FAudioFilter) then
    FAudioFilter.put_State( FAudioState );
end;

procedure TxdPlayer.SetBackBitmap(const Value: TBitmap);
begin
  FBackBitmap.Assign( Value );
end;

procedure TxdPlayer.SetCurPlayPos(const Value: Int64);
var
  nValue: Int64;
begin
  if FMediaSeek <> nil then
  begin
    nValue := Value;
    FMediaSeek.SetPositions(nValue, AM_SEEKING_AbsolutePositioning, nValue, AM_SEEKING_AbsolutePositioning);
  end;
end;

procedure TxdPlayer.SetFullDisp(const Value: Boolean);
begin
  if FIsContainVideo and (FFullDisp <> Value) then
  begin
    FFullDisp := Value;
    DispChange;
  end;
end;

procedure TxdPlayer.SetVideoPosition;
var
  R: TRect;
begin
  if Assigned(FVmrWC) then
  begin
    R := GetClientRect;
    FVmrWC.SetVideoPosition( nil, @R );
    RepaintVideo;
  end;
end;

procedure TxdPlayer.SetVolume(const Value: Integer);
begin
  if Value < 0 then
    FVolume := 0
  else if Value > 100 then
    FVolume := 100
  else
    FVolume := Value;
  if Assigned(FAudioControl) then
    FAudioControl.put_Volume(FVolume * 100 - 10000);
end;

procedure TxdPlayer.Stop;
begin
  if Assigned(FMediaControl) then
  begin    
    if Succeeded(FMediaControl.Stop) then
    begin
      FFilterGraph.RemoveFilter( FAudioFilter );
      FPlayerMode := pmStoped;
    end;

    if FPlayerMode = pmStoped then
    begin
      Close;
      Invalidate;
    end;

    while FStoping do
    begin
      Sleep( 50 );
      Application.ProcessMessages;
    end;
    DoPlayComplete;
  end;
end;

procedure TxdPlayer.WMDisplayChange(var Message: TMessage);
begin
  if FVmrWC <> nil then
    FVmrWC.DisplayModeChanged;
end;

procedure TxdPlayer.WMPlayComplete(var message: TMessage);
begin
  Stop;
end;

procedure TxdPlayer.WMSize(var Message: TWMSize);
begin
  inherited;
  OnSize;
  Invalidate;
end;

{ TPlayerEventHandle }

constructor TPlayerEventHandle.Create(AOwnerPlayer: TxdPlayer);
begin
  FreeOnTerminate := True;
  FOwnerPlayer := AOwnerPlayer;
  inherited Create(False);
end;

destructor TPlayerEventHandle.Destroy;
begin

  inherited;
end;

procedure TPlayerEventHandle.Execute;
begin
  inherited;
  while (not Terminated) and Assigned(FOwnerPlayer) and (FOwnerPlayer.CurPlayerMode <> pmNoToOpened) do
    FOwnerPlayer.DoPlayerEventHandleExecute;
  FOwnerPlayer.DoThreadEnd;
end;

end.
