unit uJxdGpGifShow;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, ExtCtrls, GDIPAPI, GDIPOBJ, uJxdGpStyle, uJxdGpBasic
  {$IF Defined(ResManage)}
  ,uJxdGpResManage
  {$ELSEIF Defined(BuildResManage)}
  ,uJxdGpResManage
  {$IFEND};

type
  PGifInfo = ^TGifInfo;
  TGifInfo = record
    FPosIndex: Integer;
    FPauseTime: Cardinal;
  end;
  TxdGifShow = class(TxdGraphicsBasic)
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
  protected
    //����ʵ��
    procedure DrawGraphics(const AGh: TGPGraphics); override;
    procedure DoControlStateChanged(const AOldState, ANewState: TxdGpUIState; const ACurPt: TPoint); override;    

    procedure SetAutoSize(Value: Boolean); override;
  private    
    FAutToFreeGif: Boolean;
    FShowTime: TTimer;
    FCurShowIndex: Integer;
    FImgWidth, FImgHeight: Integer;
    FGifInfoList: TList;
    procedure ClearList;
    procedure ReBuildGifImageInfo;
    procedure DoTimeToChangedGif(Sender: TObject);
  private
    FGifImage: TGPBitmap;
    FGifImgFileName: string;
    FAutoShowGif: Boolean;
    procedure SetGifImage(const Value: TGPBitmap);
    procedure SetGifImgFileName(const Value: string);
    function  GetGifImage: TGPBitmap; inline;
    procedure SetAutoShowGif(const Value: Boolean);
  published
    property AutoSize;
    property AutoShowGif: Boolean read FAutoShowGif write SetAutoShowGif;
    property GifImage: TGPBitmap read GetGifImage write SetGifImage;
    property GifImageFileName: string read FGifImgFileName write SetGifImgFileName;    
  end;

implementation

{ TxdGifShow }

procedure TxdGifShow.ClearList;
var
  i: Integer;
begin
  for i := 0 to FGifInfoList.Count - 1 do
    Dispose( FGifInfoList[i] );
  FGifInfoList.Clear;
end;

constructor TxdGifShow.Create(AOwner: TComponent);
begin
  inherited;
  FGifInfoList := TList.Create;
  FCurShowIndex := -1;
  FShowTime := nil;
  FGifImage := nil;
  FAutToFreeGif := False;
  FImgWidth := 0;
  FImgHeight := 0;
  AutoSize := True;
  FAutoShowGif := True;
end;

destructor TxdGifShow.Destroy;
begin
  ClearList;
  FGifInfoList.Free;
  FreeAndNil( FShowTime );
  if FAutToFreeGif then
    FreeAndNil( FGifImage );
  inherited;
end;

procedure TxdGifShow.DoControlStateChanged(const AOldState, ANewState: TxdGpUIState; const ACurPt: TPoint);
begin
  //�����ø��෽��
end;

procedure TxdGifShow.ReBuildGifImageInfo;
var
  i, nCount: Cardinal;
  pGuids: PGUID;
  pItem: PPropertyItem;
  nSize: Cardinal;
  p: PGifInfo;
  pPauseTime: PInteger;
begin
  ClearList;
  if not Assigned(GifImage) then Exit;

  FImgWidth := GifImage.GetWidth;
  FImgHeight := GifImage.GetHeight;
  FCurShowIndex := -1;
  FreeAndNil( FShowTime );

  if AutoSize then
  begin
    Width := FImgWidth;
    Height := FImgHeight;
  end;
  
  nCount := GifImage.GetFrameDimensionsCount;
  if nCount > 0 then
  begin
    GetMem( pGuids, SizeOf(TGUID) * nCount );
    try
      GifImage.GetFrameDimensionsList( pGuids, nCount );
      nCount := GifImage.GetFrameCount( pGuids^ );
    finally
      FreeMem( pGuids );
    end; 
    nSize := GifImage.GetPropertyItemSize( PropertyTagFrameDelay );
    if nSize = 0 then Exit;    
    GetMem( pItem, nSize );
    try
      GifImage.GetPropertyItem( PropertyTagFrameDelay, nSize, pItem ); 
      pPauseTime := pItem^.value;
      for i := 0 to nCount - 1 do
      begin
        New( p );
        p^.FPosIndex := i;
        p^.FPauseTime := pPauseTime^ * 10;
        FGifInfoList.Add( p );
        Inc( pPauseTime );
      end;
    finally
      FreeMem( pItem );
    end;  
  end;
  if (FGifInfoList.Count > 1) and FAutoShowGif then
  begin
    FShowTime := TTimer.Create( Self );
    FShowTime.OnTimer := DoTimeToChangedGif;    
    FShowTime.Interval := 500;
    FShowTime.Enabled := True;
  end;
end;

procedure TxdGifShow.DoTimeToChangedGif(Sender: TObject);
var
  p: PGifInfo;
begin
  if FGifInfoList.Count = 0 then
  begin
    FreeAndNil( FShowTime );
    Exit;
  end;
  
  FCurShowIndex := (FCurShowIndex + 1) mod FGifInfoList.Count;
  p := FGifInfoList[FCurShowIndex];
  FShowTime.Interval := p^.FPauseTime;
  GifImage.SelectActiveFrame( FrameDimensionTime, p^.FPosIndex );
  Invalidate;
end;

procedure TxdGifShow.DrawGraphics(const AGh: TGPGraphics);
var
  dest: TGPRect;
begin
  if not Assigned(GifImage) then Exit;
  
  dest := MakeRect( 0, 0, Width, Height );
  AGh.DrawImage( GifImage, dest, 0, 0, FImgWidth, FImgHeight, UnitPixel );
end;

function TxdGifShow.GetGifImage: TGPBitmap;
begin
  if not Assigned(FGifImage) then
  begin
    if FileExists(FGifImgFileName) then
    begin
      FGifImage := TGPBitmap.Create( FGifImgFileName );
      FAutToFreeGif := True;
//      ReBuildGifImageInfo;
    end
    {$IFDEF ResManage}
    else
    begin
      if Assigned(GResManage) then
      begin
        FGifImage := GResManage.GetRes( FGifImgFileName );
        if Assigned(FGifImage) then
        begin
          FAutToFreeGif := False;
          ReBuildGifImageInfo;
        end;
      end;
    end;
    {$ENDIF}
    ;
  end;
  Result := FGifImage;
end;

procedure TxdGifShow.SetAutoShowGif(const Value: Boolean);
begin
  if FAutoShowGif <> Value then
  begin
    FAutoShowGif := Value;
    if Value then
    begin
      if (FGifInfoList.Count > 0) and not Assigned(FShowTime) then
      begin
        FShowTime := TTimer.Create( Self );
        FShowTime.OnTimer := DoTimeToChangedGif;    
        FShowTime.Interval := 500;
        FShowTime.Enabled := True;
      end;
    end
    else
    begin
      if Assigned(FShowTime) then
      begin
        FShowTime.Enabled := False;
        FreeAndNil( FShowTime );
        FCurShowIndex := 0;
        if FGifInfoList.Count > 0 then
        begin
          GifImage.SelectActiveFrame( FrameDimensionTime, FCurShowIndex );
          Invalidate;
        end;
      end;
    end;
  end;
end;

procedure TxdGifShow.SetAutoSize(Value: Boolean);
begin
  inherited;
  if AutoSize and (FImgWidth > 0) and (FImgHeight > 0) then
  begin
    Width := FImgWidth;
    Height := FImgHeight;
  end;
end;

procedure TxdGifShow.SetGifImage(const Value: TGPBitmap);
begin
  if Assigned(FGifImage) and FAutToFreeGif then
    FreeAndNil( FGifImage );
  FGifImage := Value;
  FAutToFreeGif := False;
  ReBuildGifImageInfo;
end;

procedure TxdGifShow.SetGifImgFileName(const Value: string);
begin
  if Assigned(FGifImage) and FAutToFreeGif then
    FreeAndNil( FGifImage );
  FGifImgFileName := Value;
  {$IFDEF BuildResManage}
  if Assigned(GBuildResManage) then  
    GBuildResManage.AddToRes( FGifImgFileName );
  {$ENDIF}
  FAutToFreeGif := True;
  ReBuildGifImageInfo;
  Invalidate;
end;


end.
