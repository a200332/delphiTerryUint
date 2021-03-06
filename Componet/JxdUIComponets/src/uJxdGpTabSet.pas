{
TabSet
作者: Terry(江晓德)
QQ:   67068633
Email:jxd524@163.com

创建时间：2012-1-30
最后修改时间 2012-1-31
}

unit uJxdGpTabSet;

interface

uses
  Classes, Windows, Controls, Graphics, Messages, ExtCtrls, SysUtils,
  GDIPAPI, GDIPOBJ, uJxdGpBasic, uJxdGpCommon, uJxdGpStyle;

type
  TxdGpTabSet = class(TxdGpCommon)
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    function  AddTabItem(const ACaption: string; const AItemTag: Integer): Integer;
    procedure DeleteTabItem(const AIndex: Integer);
  protected
    procedure DrawGraphics(const AGh: TGPGraphics); override;
    function  DoGetDrawState(const Ap: PDrawInfo): TxdGpUIState; override;
    procedure DoSubItemMouseDown(const Ap: PDrawInfo); override;
    procedure Resize; override;
    procedure WMMouseMove(var Message: TWMMouseMove); message WM_MOUSEMOVE;
  private
    FCurCloseRect: TGPRect;
    FCurCloseState: TxdGpUIState;
    FTabItemGuid: Integer;
    FCurTabItemWidth: Integer;
    function  GetLastRect: TGPRect;
    procedure CalcCurTabItemWidth;
    procedure ReSetAllTabItemWidth;
    procedure ChangedNewTabItem(const Ap: PDrawInfo);
  private
    FTabItemDrawStyle: TxdGpDrawStyle;
    FItemIndex: Integer;
    FImageTabItemClose: TImageInfo;
    procedure SetTabItemDrawStyle(const Value: TxdGpDrawStyle);
    procedure SetItemIndex(const Value: Integer);
    procedure SetImageTabItemClose(const Value: TImageInfo);
  published
    property ImageTabItemClose: TImageInfo read FImageTabItemClose write SetImageTabItemClose; 
    property TabItemDrawStyle: TxdGpDrawStyle read FTabItemDrawStyle write SetTabItemDrawStyle;
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
  end;

implementation

uses
  uJxdGpSub;

const
  CtTabItemMaxWidth = 220;
  CtTabItemMinWidth = 5;

{ TxdGpTabSet }

function TxdGpTabSet.AddTabItem(const ACaption: string; const AItemTag: Integer): Integer;
var
  it: TDrawInfo;
  R: TGPRect;
  nTemp, nImgW: Integer;
begin
  if not Assigned(ImageInfo.Image) then
  begin
    Result := -1;
    Exit;
  end;
  
  R := GetLastRect;
  if R.Width = 0 then
  begin
    //first
    R.Width := FCurTabItemWidth;
    R.Height := Height;
  end
  else
  begin
    Inc( R.X, FCurTabItemWidth );
  end;
  it.FText := ACaption;
  it.FDestRect := R;
  it.FItemTag := AItemTag;
  it.FLayoutIndex := 0;
  it.FClickID := FTabItemGuid;
  it.FDrawStyle := TabItemDrawStyle;

  nTemp := Integer(ImageInfo.Image.GetHeight) div ImageInfo.ImageCount;
  nImgW := Integer(ImageInfo.Image.GetWidth);
  //Down
  if ImageInfo.ImageCount >= 3 then
    it.FDownSrcRect := MakeRect(0, nTemp * 2, nImgW, nTemp)
  else
    it.FDownSrcRect := MakeRect(0, nTemp, nImgW, nTemp);
  //Active
  if ImageInfo.ImageCount >= 2 then
    it.FActiveSrcRect := MakeRect(0, nTemp, nImgW, nTemp)
  else
    it.FActiveSrcRect := MakeRect(0, 0, nImgW, nTemp);
  //Normal
  it.FNormalSrcRect := MakeRect(0, 0, nImgW, nTemp);

  Result := ImageDrawMethod.AddDrawInfo( @it );
  if FItemIndex = -1 then
    FItemIndex := FTabItemGuid;
  Inc( FTabItemGuid );
  CalcCurTabItemWidth;
  ReSetAllTabItemWidth;
  Invalidate;
end;

procedure TxdGpTabSet.CalcCurTabItemWidth;
var
  nWidth: Integer;
begin
  FCurTabItemWidth := CtTabItemMaxWidth;
  if ImageDrawMethod.CurDrawInfoCount = 0 then Exit;

  nWidth := Width div ImageDrawMethod.CurDrawInfoCount;

  if nWidth > CtTabItemMaxWidth then
    FCurTabItemWidth := CtTabItemMaxWidth
  else if nWidth >= CtTabItemMinWidth then
    FCurTabItemWidth := nWidth
  else
    FCurTabItemWidth := CtTabItemMinWidth;
end;

procedure TxdGpTabSet.ChangedNewTabItem(const Ap: PDrawInfo);
var
  p: PDrawInfo;
  i, nOldIndex: Integer;
begin
  if FItemIndex <> Ap^.FClickID then
  begin
    nOldIndex := FItemIndex;
    FItemIndex := Ap^.FClickID;
    InvalidateRect( Ap^.FDestRect );
    for i := 0 to ImageDrawMethod.CurDrawInfoCount - 1 do
    begin
      p := ImageDrawMethod.GetDrawInfo(i);
      if p^.FClickID = nOldIndex then
      begin
        InvalidateRect( p^.FDestRect );
        Break;
      end;
    end;
  end;
end;

constructor TxdGpTabSet.Create(AOwner: TComponent);
begin
  inherited;
  ImageDrawMethod.DrawStyle := dsDrawByInfo;
  Width := 500;
  Height := 25;
  FCurTabItemWidth := CtTabItemMaxWidth;
  FTabItemDrawStyle := dsStretchByVH;
  FItemIndex := -1;
  Caption := '';
  ImageDrawMethod.AutoSort := False;
  FTabItemGuid := 999;

  FImageTabItemClose := TImageInfo.Create;
  FImageTabItemClose.OnChange := DoObjectChanged;
  FCurCloseRect := MakeRect(0, 0, 0, 0);
  FCurCloseState := uiNormal;
end;

procedure TxdGpTabSet.DeleteTabItem(const AIndex: Integer);
var
  nIndex: Integer;
  p: PDrawInfo;
begin
  if (AIndex >= 0) and (AIndex < ImageDrawMethod.CurDrawInfoCount) then
  begin
    p := ImageDrawMethod.GetDrawInfo( AIndex );
    if FItemIndex = p^.FClickID then
      FItemIndex := -1;
    ImageDrawMethod.DeleteDrawInfo( AIndex );
    CalcCurTabItemWidth;
    ReSetAllTabItemWidth;
    if FItemIndex = -1 then
    begin
      nIndex := AIndex mod ImageDrawMethod.CurDrawInfoCount;
      p := ImageDrawMethod.GetDrawInfo( nIndex );
      if Assigned(p) then
        FItemIndex := p^.FClickID;
    end;
    Invalidate;
  end;
end;

destructor TxdGpTabSet.Destroy;
begin

  inherited;
end;

function TxdGpTabSet.DoGetDrawState(const Ap: PDrawInfo): TxdGpUIState;
begin
  if Assigned(Ap) and (FItemIndex = Ap^.FClickID) then
    Result := uiDown
  else
    Result := inherited DoGetDrawState(Ap);
end;

procedure TxdGpTabSet.DoSubItemMouseDown(const Ap: PDrawInfo);
begin
  if Assigned(Ap) then
    ChangedNewTabItem( Ap );
end;

procedure TxdGpTabSet.DrawGraphics(const AGh: TGPGraphics);
var
  pt: TPoint;
  p: PDrawInfo;
  bmpR: TGPRect;
  nW, nH: Integer;
  st: TxdGpUIState;
begin
  //TabItem
  DrawImageCommon( AGh, MakeRect(0, 0, Width, Height), ImageInfo, ImageDrawMethod,
    DoGetDrawState, DoIsDrawSubItem, DoDrawSubItemText, DoChangedSrcBmpRect );
    
  //TabItem Close Button
  p := CurActiveSubItem;
  if Assigned(p) and Assigned(FImageTabItemClose.Image) then
  begin
    GetCursorPos( pt );
    pt := ScreenToClient(pt);
    nW := FImageTabItemClose.Image.GetWidth;
    nH := Integer(FImageTabItemClose.Image.GetHeight) div FImageTabItemClose.ImageCount;

    FCurCloseRect := MakeRect( p^.FDestRect.X  + p^.FDestRect.Width - nW - 2,
     2, nW, nH );

     //
    if PtInGpRect(pt.X, pt.Y, FCurCloseRect) then
    begin
      st := uiActive;
      if GetCurControlState = uiDown then
        st := uiDown;
    end
    else
      st :=  uiNormal;
    case st of
      uiDown:
      begin
        if FImageTabItemClose.ImageCount >= 3 then
          BmpR := MakeRect(0, nH * 2, nW, nH)
        else
          bmpR := MakeRect(0, nH, nW, nH)
      end;
      uiActive:
      begin
        if FImageTabItemClose.ImageCount >= 2 then
          bmpR := MakeRect(0, nH, nW, nH)
        else
          bmpR := MakeRect(0, 0, nW, nH)
      end;
      else
        bmpR := MakeRect(0, 0, nW, nH);
    end;

    //Paste
    AGh.DrawImage( FImageTabItemClose.Image, FCurCloseRect, BmpR.X, BmpR.Y, nW, nH, UnitPixel );
  end;
end;

function TxdGpTabSet.GetLastRect: TGPRect;
var
  i: Integer;
  p: PDrawInfo;
begin
  Result := MakeRect(0, 0, 0, 0);
  for i := 0 to ImageDrawMethod.CurDrawInfoCount - 1 do
  begin
    p := ImageDrawMethod.GetDrawInfo(i);
    if p^.FDestRect.X >= Result.X then
      Result := p^.FDestRect;
  end;
end;

procedure TxdGpTabSet.ReSetAllTabItemWidth;
var
  i, X: Integer;
  p: PDrawInfo;
begin
  x := 0;
  for i := 0 to ImageDrawMethod.CurDrawInfoCount - 1 do
  begin
    p := ImageDrawMethod.GetDrawInfo(i);
    p^.FDestRect.X := x;
    p^.FDestRect.Width := FCurTabItemWidth;
    Inc( x, FCurTabItemWidth );
  end;
end;

procedure TxdGpTabSet.Resize;
begin
  inherited;
  CalcCurTabItemWidth;
  ReSetAllTabItemWidth;
end;

procedure TxdGpTabSet.SetImageTabItemClose(const Value: TImageInfo);
begin
  FImageTabItemClose.Assign( Value );
end;

procedure TxdGpTabSet.SetItemIndex(const Value: Integer);
var
  p: PDrawInfo;
begin
  if (Value >= 0) and (Value < ImageDrawMethod.CurDrawInfoCount) then
  begin
    p := ImageDrawMethod.GetDrawInfo(Value);
    if Assigned(p) then
      ChangedNewTabItem( p );
  end;
end;

procedure TxdGpTabSet.SetTabItemDrawStyle(const Value: TxdGpDrawStyle);
begin
  if FTabItemDrawStyle <> Value then
  begin
    FTabItemDrawStyle := Value;
    Invalidate;
  end;
end;

procedure TxdGpTabSet.WMMouseMove(var Message: TWMMouseMove);
begin
  inherited;
  
end;

end.
