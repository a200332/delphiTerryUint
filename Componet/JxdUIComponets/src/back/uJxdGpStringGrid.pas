{
�Ի�StringGrid

    ============��Ԫ���Ʋ���==============
CellImageͼƬ��Ϣ
CellImageDrawMethod.DrawStyle ֻ֧�֣�dsPaste, dsStretchByVH, dsStretchAll

CellImage.ImageCount���ϵ���ͼƬ��ʾ���� �̶�Ϊ 5 
1�������б���
2��ż���б���
3�������ĳһ��ʱ����
4��ѡ��ʱ����
5������ʱ����


   ==========�̶����л��Ʋ���==============
FFixedImage
FFixedImageDrawMethod

FFixedImageDrawMethod.DrawStyle ֻ֧�֣�dsPaste, dsStretchByVH, dsStretchAll
FFixedImage.ImageCount �������Ƶ�״̬�����Ϊ3��

FixedGradientDrawInfo
  ֻʹ�� GradientNormalText ���л���
FixedBitmap
  �� FixedBitmap.BitmapCount Ϊ 1 ʱ, ���й̶��ж�ʹ������FixedBitmap������
  �� FixedBitmap.BitmapCount > 1 ʱ, ʹ������ FixedBitmap�����һ�������Ƶ�һ���̶��У�
    �м�һ�������������м����й̶��У��ұ�һ�����������һ���̶���
  
}
unit uJxdGpStringGrid;

interface
uses
  Windows, Messages, Grids, Classes, StdCtrls, uJxdGpScrollBar, Controls, ExtCtrls, uJxdGpStyle,
  SysUtils, Graphics, Forms, ShellAPI, GDIPAPI, GDIPOBJ, Math;

type
  TCellInfo = record
    FRowIndex: Integer;
    FColIndex: Integer;
  end;
  {�¼�ģʽ����}
  TOnGridOpt = procedure(Sender: TObject; const ACellInfo: TCellInfo) of object;
  TOnColSizing = procedure(Sender: TObject; const AColIndex: Integer; var AAllow: Boolean) of object;
  TOnDragFiles = procedure(Sender: TObject; const AFiles: TStringList) of object;
  TOnXdDrawGrid = procedure(Sender: TObject; const AGh: TGPGraphics;
                          const ACol, ARow: Integer; var AGpRect: TGPRect; 
                          const AState: TGridDrawState; var ADefaultDraw: Boolean) of object;

  TxdStringGrid = class(TStringGrid)
  public   
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    function  IsRowSelected(const ARow: Integer): Boolean;
    function  SelectedCount: Integer;
    function  GetSelectedIndex(const AIndex: Integer): Integer;
    procedure AddSelected(const ARowIndex: Integer);
    procedure UnSelectedAll;
    procedure DeleteAllSelected;
    procedure DeleteRow(ARow: Longint); override;
    procedure HighRow(const ARow: Integer);  //ʹ�ã� GradientHoverText
    procedure InvalidateCell(ACol, ARow: Longint);
  protected
    {���ദ��}
    property  BevelInner;
    procedure Paint; override;
    procedure Loaded; override;
    procedure DblClick; override;
  protected
    {����ʵ��}
    procedure ParentPaint;
    procedure DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState); override;    
    procedure DrawFixedBK(const AGh: TGPGraphics; ACol, ARow: Longint; ADestR: TGPRect; AState: TGridDrawState); virtual;
    procedure DrawRowCellBK(const AGh: TGPGraphics; ACol, ARow: Longint; ADestR: TGPRect; AState: TGridDrawState); virtual;    
    procedure DrawCellText(const AGh: TGPGraphics; const AFontInfo: TFontInfo; ACol, ARow: Longint; ADestR: TGPRect; AState: TGridDrawState); virtual;

    procedure SizeChanged(OldColCount, OldRowCount: Longint); override;
    procedure TopLeftChanged; override;
    procedure Resize; override;
    procedure ColWidthsChanged; override;
    function  SelectCell(ACol, ARow: Longint): Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;

    procedure CalcSizingState(X, Y: Integer; var State: TGridState;
      var Index: Longint; var SizingPos, SizingOfs: Integer;
      var FixedInfo: TGridDrawInfo); override;

    procedure WMDragDropFiles(var msg:TMessage); message WM_DROPFILES;
    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    
    procedure DoMousePosChanged(const ANewRowIndex, ANewCellIndex: Integer);  //���λ�ñ䶯
    procedure DoDownPosChanged(const ANewRowIndex, AnewColIndex: Integer); //����λ�ñ䶯

    {��ض����¼�����}
    procedure DoObjectChanged(Sender: TObject);
    procedure DoHorizontalScrollPosChanged(Sender: TObject; const AChangedStyle: TxdChangedStyle);
    procedure DoVericalScrollPosChanged(Sender: TObject; const AChangedStyle: TxdChangedStyle);
  private
    FHighRow: Integer;
    FDeleteSelected: Boolean;
    FSelectedRows: array of Integer;
    FSelectRect: TRect;
    FCurDownCell: TCellInfo; //��ǰ��������λ��
    FCurMouseCell: TCellInfo; //��ǰ�������λ��
    procedure CheckSelectRow(const ARow: Integer);

    procedure CheckScrollBarHor;
    procedure ChangedScrollBarPosHor;
    procedure CheckScrollBarVer;
    procedure ChangedScrollBarPosVer;
    
    procedure InitSetting;

    function IsActiveControl: Boolean;
  private
    FScrollBarHorizontal: TxdScrollBar;
    FScrollBarVerical: TxdScrollBar;
    FOnColSizing: TOnColSizing;
    FDragAcceptFile: Boolean;
    FOnDragFiles: TOnDragFiles;
    FHighRowHeight: Integer;
    FOnDrawText: TOnXdDrawGrid;
    FFixedImage: TImageInfo;
    FCellImage: TImageInfo;
    FFixedImageDrawMethod: TDrawMethod;
    FFixedFont: TFontInfo;
    FCellFont: TFontInfo;
    FCellImageDrawMethod: TDrawMethod;
    FOnXdDblClickCell: TOnGridOpt;
    FOnXdDrawCellBefor: TOnXdDrawGrid;
    FOnXdDrawCellAfter: TOnXdDrawGrid;
    procedure SetScrollBarHorizontal(const Value: TxdScrollBar);
    procedure SetScrollBarVerical(const Value: TxdScrollBar);
    procedure SetDragAcceptFile(const Value: Boolean);
    procedure SetHighRowHeight(const Value: Integer);
    procedure SetCellImage(const Value: TImageInfo);
    procedure SetFixedBitmap(const Value: TImageInfo);
    procedure SetFixedImageDrawMethod(const Value: TDrawMethod);
    procedure SetFixedFont(const Value: TFontInfo);
    procedure SetCellFont(const Value: TFontInfo);
    procedure SetCellImageDrawMethod(const Value: TDrawMethod);
  published
    {����}
    property OnResize;
    property FixedRows;
    property FixedCols;
    
    //�ⲿ�ṩ����������
    property ScrollBarHorizontal: TxdScrollBar read FScrollBarHorizontal write SetScrollBarHorizontal;
    property ScrollBarVerical: TxdScrollBar read FScrollBarVerical write SetScrollBarVerical;
    //�̶��л�������
    property FixedImage: TImageInfo read FFixedImage write SetFixedBitmap;
    property FixedImageDrawMethod: TDrawMethod read FFixedImageDrawMethod write SetFixedImageDrawMethod;
    property FixedFont: TFontInfo read FFixedFont write SetFixedFont;
    //��Ϣ��ʾ�л�������
    property CellImage: TImageInfo read FCellImage write SetCellImage;
    property CellImageDrawMethod: TDrawMethod read FCellImageDrawMethod write SetCellImageDrawMethod;
    property CellFont: TFontInfo read FCellFont write SetCellFont;
    //��������Ϣ    
    property HighRowHeight: Integer read FHighRowHeight write SetHighRowHeight;
    property CurHighRow: Integer read FHighRow;    
    property CurDownCell: TCellInfo read FCurDownCell; //��ǰ��������λ��
    property CurMouseCell: TCellInfo read FCurMouseCell; //��ǰ�������λ��
    //�ⲿ��������
    property DragAcceptFile: Boolean read FDragAcceptFile write SetDragAcceptFile;
    property OnDragFiles: TOnDragFiles read FOnDragFiles write FOnDragFiles; 

    //�¼�
    property OnColSizing: TOnColSizing read FOnColSizing write FOnColSizing; //�д�С�ı�
    property OnXdDblClickCell: TOnGridOpt read FOnXdDblClickCell write FOnXdDblClickCell; //˫��
    property OnXdDrawCellBefor: TOnXdDrawGrid read FOnXdDrawCellBefor write FOnXdDrawCellBefor; //���Ƶ�Ԫ
    property OnXdDrawCellAfter: TOnXdDrawGrid read FOnXdDrawCellAfter write FOnXdDrawCellAfter; //���Ƶ�Ԫ
    property OnXdDrawText: TOnXdDrawGrid read FOnDrawText write FOnDrawText; //��������¼�
  end;

implementation

uses
  uJxdGpSub;

{ TxdStringGrid }
function IsCtrlDown: Boolean;
var
  n: Smallint;
begin
  n := GetKeyState(VK_CONTROL) and 128;
  Result := n = 128;
end;

function IsShiftDown: Boolean;
var
  n: Smallint;
begin
  n := GetKeyState(VK_SHIFT) and 128;
  Result := n = 128;
end;


constructor TxdStringGrid.Create(AOwner: TComponent);
begin
  inherited;
  DoubleBuffered := True;
  InitSetting;
  FScrollBarHorizontal := nil;
  FScrollBarVerical := nil;
  SetLength( FSelectedRows, 0 );
  FDeleteSelected := False;
  FSelectRect := Rect( -1, -1, -1, -1 );
  FCurDownCell.FRowIndex := -1;
  FCurDownCell.FColIndex := -1;
  FCurMouseCell.FRowIndex := -1;
  FCurMouseCell.FColIndex := -1;
  FHighRowHeight := DefaultRowHeight * 2; 
  FDragAcceptFile := False;
  Options := Options - [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine];
  Options := Options + [goRowSelect];
  
  FFixedImage := TImageInfo.Create;
  FFixedImageDrawMethod := TDrawMethod.Create;
  FFixedFont := TFontInfo.Create;
  FCellImage := TImageInfo.Create;
  FCellFont := TFontInfo.Create;
  FCellImageDrawMethod := TDrawMethod.Create;

  FFixedImage.OnChange := DoObjectChanged;
  FFixedImageDrawMethod.OnChange := DoObjectChanged;  
  FFixedFont.OnChange := DoObjectChanged;
  FCellImage.OnChange := DoObjectChanged;
  FCellFont.OnChange := DoObjectChanged;
  FCellImageDrawMethod.OnChange := DoObjectChanged;
end;

procedure TxdStringGrid.AddSelected(const ARowIndex: Integer);
var
  n: Integer;
begin
  if not IsRowSelected(ARowIndex) then
  begin
    n := Length( FSelectedRows );
    SetLength( FSelectedRows, n + 1 );
    FSelectedRows[n] := ARowIndex;
    InvalidateRow( ARowIndex );
  end;
end;

procedure TxdStringGrid.CalcSizingState(X, Y: Integer; var State: TGridState; var Index, SizingPos, SizingOfs: Integer;
  var FixedInfo: TGridDrawInfo);
var
  bAllow: Boolean;
begin
  inherited;
  if (State = gsColSizing) and Assigned(OnColSizing) then
  begin
    bAllow := True;
    OnColSizing( Self, Index, bAllow );
    if not bAllow then
      State := gsNormal;
  end;
end;

procedure TxdStringGrid.ChangedScrollBarPosHor;
begin
  if Assigned(FScrollBarHorizontal) then
  begin
    with FScrollBarHorizontal do
    begin
      OnPosChanged := nil;
      Position := TopRow - FixedRows;
      OnPosChanged := DoHorizontalScrollPosChanged;
    end;
  end;
end;

procedure TxdStringGrid.ChangedScrollBarPosVer;
begin
  if Assigned(FScrollBarVerical) then
  begin
    with FScrollBarVerical do
    begin
      OnPosChanged := nil;
      Position := LeftCol;
      OnPosChanged := DoVericalScrollPosChanged;
    end;
  end;
end;

procedure TxdStringGrid.CheckSelectRow(const ARow: Integer);
var
  i, j, nCount: Integer;
  nMin, nMax: Integer;
  bExsits: Boolean;
  nReDrawRows: array of Integer;
begin
  if ARow < FixedRows then Exit;
  if (goRangeSelect in Options) and IsCtrlDown then
  begin
    //����Ctrl
    bExsits := False;
    nCount := Length(FSelectedRows);
    for i := Low(FSelectedRows) to nCount - 1 do
    begin
      if ARow = FSelectedRows[i] then
      begin
        bExsits := True;
        SetLength( nReDrawRows, 1 );
        nReDrawRows[0] := FSelectedRows[i];
        if i <> (nCount - 1) then
          Move( FSelectedRows[i + 1], FSelectedRows[i], 4 * (nCount - i) );
        SetLength( FSelectedRows, nCount - 1 );
        Break;
      end;
    end;
    if not bExsits then
    begin
      SetLength( nReDrawRows, 1 );
      nReDrawRows[0] := ARow;
      SetLength( FSelectedRows, nCount + 1 );
      FSelectedRows[nCount] := ARow;
    end;
  end
  else if (goRangeSelect in Options) and IsShiftDown then
  begin
    //����Shift��
    nMin := MaxInt;
    nMax := -1;
    for i := Low(FSelectedRows) to High(FSelectedRows) do
    begin
      if FSelectedRows[i] < nMin then nMin := FSelectedRows[i];
      if FSelectedRows[i] > nMax then nMax := FSelectedRows[i];
    end;

    if nMax = -1 then
    begin
      //û��ѡ����
      nMin := ARow;
      nMax := ARow;
    end
    else
    begin
      if nMin > ARow then
        nMin := ARow
      else if nMax < ARow then
        nMax := ARow
      else
      begin
        if FSelectedRows[High(FSelectedRows)] > ARow then
        begin
          nMin := ARow;
          nMax := FSelectedRows[High(FSelectedRows)];
        end
        else
        begin
          nMin := FSelectedRows[High(FSelectedRows)];
          nMax := ARow;
        end;
      end;
    end;

    SetLength( nReDrawRows, Length(FSelectedRows) );
    Move( FSelectedRows[0], nReDrawRows[0], 4 * Length(FSelectedRows) );
    SetLength( FSelectedRows, nMax + 1 - nMin );
    nCount := 0;
    for i := nMin to nMax do
    begin
      FSelectedRows[nCount] := i;
      Inc( nCount );
      bExsits := False;
      for j := Low(nReDrawRows) to High(nReDrawRows) do
      begin
        if nReDrawRows[j] = i then
        begin
          bExsits := True;
          Break;
        end;
      end;
      if not bExsits then
      begin
        SetLength( nReDrawRows, Length(nReDrawRows) + 1 );
        nReDrawRows[ High(nReDrawRows) ] := i;
      end;
    end;
  end
  else
  begin
    SetLength( nReDrawRows, Length(FSelectedRows) );
    Move( FSelectedRows[0], nReDrawRows[0], 4 * Length(FSelectedRows) );
    SetLength( FSelectedRows, 1 );
    FSelectedRows[0] := ARow;
    InvalidateRow( ARow );
  end;
  for i := Low(nReDrawRows) to High(nReDrawRows) do
    InvalidateRow( nReDrawRows[i] );
  SetLength( nReDrawRows, 0 );
end;

procedure TxdStringGrid.CheckScrollBarHor;
var
  nCount: Integer;
begin
  if Assigned(FScrollBarHorizontal) then
  begin
    nCount := RowCount - FixedRows;
    FScrollBarHorizontal.Visible := nCount > VisibleRowCount;
    FScrollBarHorizontal.Max := nCount - VisibleRowCount;
    FScrollBarHorizontal.OnPosChanged := DoHorizontalScrollPosChanged;
  end;
end;

procedure TxdStringGrid.CheckScrollBarVer;
var
  nCount: Integer;
  bVisble: Boolean;
begin
  if Assigned(FScrollBarVerical) then
  begin
    nCount := ColCount - FixedCols;
    bVisble := nCount > VisibleColCount;
    if bVisble then
      FScrollBarVerical.Max := nCount - VisibleColCount
    else
      FScrollBarVerical.Position := 0;
    FScrollBarVerical.OnPosChanged := DoVericalScrollPosChanged;
    FScrollBarVerical.Visible := bVisble;
  end;
end;

procedure TxdStringGrid.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FSelectRect := Rect( -1, -1, -1, -1 );
  FCurDownCell.FRowIndex := -1;
  FCurDownCell.FColIndex := -1;
  FCurMouseCell.FRowIndex := -1;
  FCurMouseCell.FRowIndex := -1;
//  InvalidateGrid;
end;

procedure TxdStringGrid.ColWidthsChanged;
begin
  inherited;
  CheckScrollBarVer;
end;

procedure TxdStringGrid.DblClick;
begin
  inherited DblClick;
  if Assigned(OnXdDblClickCell) then
    OnXdDblClickCell( Self, FCurMouseCell );
//  PostMessage( Handle, WM_LBUTTONUP, 0, 0 );
end;

procedure TxdStringGrid.DeleteAllSelected;
var
  i: Integer;
begin
  for i := High(FSelectedRows) downto Low(FSelectedRows) do
    DeleteRow( FSelectedRows[i] );
end;

procedure TxdStringGrid.DeleteRow(ARow: Integer);
var
  i, nLen: Integer;
begin
  if (ARow < 0) or (ARow >= RowCount) then Exit;
  i := Low(FSelectedRows);
  while i <= High(FSelectedRows) do
  begin
    if FSelectedRows[i] = ARow then
    begin
      nLen := 4 * ( Length( FSelectedRows ) - i );
      if nLen > 0 then
        Move( FSelectedRows[i + 1], FSelectedRows[i], nLen );
      SetLength( FSelectedRows, Length( FSelectedRows ) - 1 );
    end
    else
    begin
      if FSelectedRows[i] > ARow then
        FSelectedRows[i] := FSelectedRows[i] - 1;
      Inc( i );
    end;
  end;
  FDeleteSelected := True;
  inherited DeleteRow( ARow );
  FDeleteSelected := False;
end;

destructor TxdStringGrid.Destroy;
begin
  SetLength( FSelectedRows, 0 );
  FreeAndNil( FFixedImage );
  FreeAndNil( FFixedImageDrawMethod );
  FreeAndNil( FFixedFont );
  FreeAndNil( FCellImage );
  FreeAndNil( FCellFont );
  FreeAndNil( FCellImageDrawMethod );
  inherited;
end;

procedure TxdStringGrid.DoMousePosChanged(const ANewRowIndex, ANewCellIndex: Integer);
var
  old: TCellInfo;
begin
  if goRowSelect in Options then
  begin
    //����ѡ��
    if FCurMouseCell.FRowIndex <> ANewRowIndex then
    begin
      old := FCurMouseCell;
      FCurMouseCell.FRowIndex := ANewRowIndex;
      FCurMouseCell.FColIndex := ANewCellIndex;

      if old.FRowIndex <> FCurMouseCell.FRowIndex then
      begin
        if old.FRowIndex <> -1 then
          InvalidateRow( old.FRowIndex );
        if FCurMouseCell.FRowIndex <> -1 then
          InvalidateRow( FCurMouseCell.FRowIndex );
      end;
    end;
  end
  else
  begin
    if (FCurMouseCell.FRowIndex <> ANewRowIndex) or (FCurMouseCell.FColIndex <> ANewCellIndex) then
    begin
      old := FCurMouseCell;
      FCurMouseCell.FRowIndex := ANewRowIndex;
      FCurMouseCell.FColIndex := ANewCellIndex;

      if (old.FRowIndex <> FCurMouseCell.FRowIndex) or (old.FColIndex <> FCurMouseCell.FColIndex) then
      begin
        if (old.FRowIndex <> -1) and (old.FColIndex <> -1) then
          InvalidateCell( old.FColIndex, old.FRowIndex );
        if (FCurMouseCell.FRowIndex <> -1) and (FCurMouseCell.FColIndex <> -1) then
          InvalidateCell( FCurMouseCell.FColIndex, FCurMouseCell.FRowIndex );
      end;
    end;
  end;
//    if (old.FRowIndex <> -1) and then
//      InvalidateRow( nOldIndex );
//    if FCurMouseCell.FRowIndex <> -1 then
//      InvalidateRow( FCurMouseCell.FRowIndex );
//    if Assigned(OnChangedMouseOnRow) then
//      OnChangedMouseOnRow( Self, ACurColIndex, FCurMouseCell.FRowIndex, nOldIndex );
//    OutputDebugString( PChar('��ǰ���λ�ڣ�' + IntToStr(FCurMouseCell.FRowIndex) + ' ' + 
//      IntToStr(FCurMouseCell.FColIndex)) );
end;

procedure TxdStringGrid.DoDownPosChanged(const ANewRowIndex, AnewColIndex: Integer);
var
  old: TCellInfo;
begin
  if goRowSelect in Options then
  begin
    //����ѡ��
    if FCurDownCell.FRowIndex <> ANewRowIndex then
    begin
      old := FCurDownCell;
      FCurDownCell.FRowIndex := ANewRowIndex;
      FCurDownCell.FColIndex := AnewColIndex;

      if old.FRowIndex <> FCurDownCell.FRowIndex then
      begin
        if old.FRowIndex <> -1 then
          InvalidateRow( old.FRowIndex );
        if FCurDownCell.FRowIndex <> -1 then
          InvalidateRow( FCurDownCell.FRowIndex );
      end;
    end;
  end
  else
  begin
    if (FCurDownCell.FRowIndex <> ANewRowIndex) or (FCurDownCell.FColIndex <> AnewColIndex) then
    begin
      old := FCurDownCell;
      FCurDownCell.FRowIndex := ANewRowIndex;
      FCurDownCell.FColIndex := AnewColIndex;

      if (old.FRowIndex <> FCurDownCell.FRowIndex) or (old.FColIndex <> FCurDownCell.FColIndex) then
      begin
        if (old.FRowIndex <> -1) and (old.FColIndex <> -1) then
          InvalidateCell( old.FColIndex, old.FRowIndex );
        if (FCurDownCell.FRowIndex <> -1) and (FCurDownCell.FColIndex <> -1) then
          InvalidateCell( FCurDownCell.FColIndex, FCurDownCell.FRowIndex );
      end;
    end;
  end;
end;

procedure TxdStringGrid.DoHorizontalScrollPosChanged(Sender: TObject; const AChangedStyle: TxdChangedStyle);
begin
  if (AChangedStyle <> csNull) and Assigned(FScrollBarHorizontal) then
  begin
    TopRow := FScrollBarHorizontal.Position + FixedRows;
    CheckScrollBarHor;
  end;
end;

procedure TxdStringGrid.DoObjectChanged(Sender: TObject);
begin
  InvalidateGrid;
end;

procedure TxdStringGrid.DoVericalScrollPosChanged(Sender: TObject; const AChangedStyle: TxdChangedStyle);
begin
  if (AChangedStyle <> csNull) and Assigned(FScrollBarVerical) then
  begin
    LeftCol := FScrollBarVerical.Position;
    CheckScrollBarVer;
  end;
end;

procedure TxdStringGrid.DrawCell(ACol, ARow: Integer; ARect: TRect; AState: TGridDrawState);
var
  R: TGPRect;
  G: TGPGraphics;
  bDefaultDraw: Boolean;
begin
  if ARow < 0 then Exit;
  bDefaultDraw := True;
  R := MakeRect( ARect.Left, ARect.Top, ARect.Right - ARect.Left, ARect.Bottom - ARect.Top );
  G := TGPGraphics.Create( Canvas.Handle );
  try
    if Assigned(OnXdDrawCellBefor) then
      OnXdDrawCellBefor( Self, G, ACol, ARow, R, AState, bDefaultDraw ); 
      
    if bDefaultDraw then
    begin
      if gdFixed in AState then
        DrawFixedBK( G, ACol, ARow, R, AState )
      else
        DrawRowCellBK( G, ACol, ARow, R, AState );
    end;

    if Assigned(OnXdDrawCellAfter) then
      OnXdDrawCellAfter( Self, G, ACol, ARow, R, AState, bDefaultDraw );   

    if gdFixed in AState then
      DrawCellText( G, FFixedFont, ACol, ARow, R, AState )
    else
      DrawCellText( G, FCellFont, ACol, ARow, R, AState );
  finally
    G.Free;
  end;  
  if Assigned(OnDrawCell) then
    OnDrawCell( Self, ACol, ARow, ARect, AState );
end;

procedure TxdStringGrid.DrawCellText(const AGh: TGPGraphics; const AFontInfo: TFontInfo; ACol, ARow: Longint; ADestR: TGPRect; AState: TGridDrawState);
var
  strText: string;
  bDefaultDraw: Boolean;
  R: TGPRectF;
begin
  bDefaultDraw := True;
  if Assigned(OnXdDrawText) then
    OnXdDrawText( Self, AGh, ACol, ARow, ADestR, AState, bDefaultDraw );
  if bDefaultDraw then
  begin
    strText := Cells[ACol, ARow];
    if strText <> '' then
    begin
      R.X := ADestR.X; 
      R.Y := ADestR.Y;
      R.Width := ADestR.Width;
      R.Height := ADestR.Height;
      AGh.DrawString( strText, -1, AFontInfo.Font, R, AFontInfo.Format, AFontInfo.FontBrush )
    end;
  end;
end;

procedure TxdStringGrid.DrawFixedBK(const AGh: TGPGraphics; ACol, ARow: Integer; ADestR: TGPRect; AState: TGridDrawState);
var
  BmpR: TGPRect;
  nTemp, nH, nW: Integer;
begin
  if not Assigned(FFixedImage.Image) then Exit;

  {
    FFixedImageDrawMethod.DrawStyle ֻ֧�֣�dsPaste, dsStretchByVH, dsStretchAll
    FFixedImage.ImageCount �������Ƶ�״̬�����Ϊ3��
  }
  BmpR := MakeRect(0, 0, Integer(FFixedImage.Image.GetWidth), 
    Integer(FFixedImage.Image.GetHeight) div FFixedImage.ImageCount);
  
  if goRowSelect in Options then
  begin
    if FCurDownCell.FRowIndex = ARow then
    begin
      if FFixedImage.ImageCount >= 3 then
        Inc(BmpR.Y, BmpR.Height * 2)
      else if FFixedImage.ImageCount >= 2 then
        Inc(BmpR.Y, BmpR.Height);
    end
    else if FCurMouseCell.FRowIndex = ARow then
    begin
      if FFixedImage.ImageCount >= 2 then
        Inc(BmpR.Y, BmpR.Height);
    end;
  end
  else
  begin
    if (FCurDownCell.FRowIndex = ARow) and (FCurDownCell.FColIndex = ACol) then
    begin
      if FFixedImage.ImageCount >= 3 then
        Inc(BmpR.Y, BmpR.Height * 2)
      else if FFixedImage.ImageCount >= 2 then
        Inc(BmpR.Y, BmpR.Height);
    end
    else if (FCurMouseCell.FRowIndex = ARow) and (FCurMouseCell.FColIndex = ACol) then
    begin
      if FFixedImage.ImageCount >= 2 then
        Inc(BmpR.Y, BmpR.Height);
    end;
  end;

  case FFixedImageDrawMethod.DrawStyle of
    dsPaste: 
    begin
      if BmpR.Width > ADestR.Width then
        nW := ADestR.Width
      else
      begin
        nW := BmpR.Width;
        ADestR.Width := nW;
      end;

      if BmpR.Height > ADestR.Height then
        nH := BmpR.Height
      else
      begin
        nH := BmpR.Height;
        ADestR.Height := nH;
      end;        
      AGh.DrawImage( FFixedImage.Image, ADestR, BmpR.X, BmpR.Y, nW, nH, UnitPixel );
    end;
    dsStretchByVH: 
    begin
      if goRowSelect in Options then
      begin
        //����ѡ��
        //ͼƬ�Զ������������
        if ColCount = 1 then
          DrawStretchImage( AGh, FFixedImage.Image, ADestR, BmpR )
        else
        begin
          if ACol = 0 then
          begin
            //�����
            nW := ADestR.Width;
            nTemp := BmpR.Width div 2;
            BmpR.Width := nTemp;
            ADestR.Width :=  BmpR.Width;
            AGh.DrawImage( FFixedImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );

            Inc(BmpR.X, nTemp); 
            Inc(ADestR.X, nTemp);
            BmpR.Width := 1;
            ADestR.Width := nW - nTemp;
            AGh.DrawImage( FFixedImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );
          end
          else if ACol = ColCount - 1 then
          begin
            //���ұ�
            nW := BmpR.Width div 2;
            nTemp := ADestR.Width - nW + BmpR.Width mod 2;
            Inc(BmpR.X, nW + BmpR.Width mod 2);
            BmpR.Width := 1;            
            ADestR.Width := nTemp;
            AGh.DrawImage( FFixedImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );

            Inc(BmpR.X, 1); 
            Inc(ADestR.X, nTemp);
            BmpR.Width := nW;
            ADestR.Width := nW;
            AGh.DrawImage( FFixedImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );
          end
          else
          begin
            Inc( BmpR.X, BmpR.Width div 2 );
            BmpR.Width := 1;
            AGh.DrawImage( FFixedImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );
          end;
        end;
      end
      else      
        DrawStretchImage( AGh, FFixedImage.Image, ADestR, BmpR );
    end
    else  
      AGh.DrawImage( FFixedImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );
  end;  
end;

procedure TxdStringGrid.DrawRowCellBK(const AGh: TGPGraphics; ACol, ARow: Integer; ADestR: TGPRect; AState: TGridDrawState);
var
  nTemp, nW, nH: Integer;
  BmpR: TGPRect;
begin
  if not Assigned(FCellImage.Image) then Exit;
    {
    CellBitmapͼƬ��Ϣ��
      1�������б���
      2��ż���б���
      3�������ĳһ��ʱ����
      4��ѡ��ʱ����
      5������ʱ����
  end;}
    //ʹ��ͼƬ�����ƽ���
  BmpR := MakeRect(0, 0, Integer(FCellImage.Image.GetWidth), 
    Integer(FCellImage.Image.GetHeight) div 5);
      
  nTemp := 0;
  
  if FHighRow = ARow then
    nTemp := 4
  else if IsRowSelected(ARow) then
    nTemp := 3
  else 
  begin
    if goRowSelect in Options then
    begin
      if FCurMouseCell.FRowIndex = ARow then
        nTemp := 2;
    end
    else
    begin
      if (FCurMouseCell.FRowIndex = ARow) and (FCurMouseCell.FColIndex = ACol) then
        nTemp := 2;
    end;
    if nTemp = 0 then
    begin
      if ARow mod 2 = 0 then 
        nTemp := 1
    end;
  end;

  Inc( BmpR.Y, BmpR.Height * nTemp );

  case FCellImageDrawMethod.DrawStyle of
    dsPaste: 
    begin
      if BmpR.Width > ADestR.Width then
        nW := ADestR.Width
      else
      begin
        nW := BmpR.Width;
        ADestR.Width := nW;
      end;

      if BmpR.Height > ADestR.Height then
        nH := BmpR.Height
      else
      begin
        nH := BmpR.Height;
        ADestR.Height := nH;
      end;        
      AGh.DrawImage( FCellImage.Image, ADestR, BmpR.X, BmpR.Y, nW, nH, UnitPixel );
    end;
    dsStretchByVH: 
    begin
      if goRowSelect in Options then
      begin
        //����ѡ��
        //ͼƬ�Զ������������
        if ColCount = 1 then
          DrawStretchImage( AGh, FCellImage.Image, ADestR, BmpR )
        else
        begin
          if ACol = 0 then
          begin
            //�����
            nW := ADestR.Width;
            nTemp := BmpR.Width div 2;
            BmpR.Width := nTemp;
            ADestR.Width :=  BmpR.Width;
            AGh.DrawImage( FCellImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );

            Inc(BmpR.X, nTemp); 
            Inc(ADestR.X, nTemp);
            BmpR.Width := 1;
            ADestR.Width := nW - nTemp;
            AGh.DrawImage( FCellImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );
          end
          else if ACol = ColCount - 1 then
          begin
            //���ұ�
            nW := BmpR.Width div 2;
            nTemp := ADestR.Width - nW + BmpR.Width mod 2;
            Inc(BmpR.X, nW + BmpR.Width mod 2);
            BmpR.Width := 1;            
            ADestR.Width := nTemp;
            AGh.DrawImage( FCellImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );

            Inc(BmpR.X, 1); 
            Inc(ADestR.X, nTemp);
            BmpR.Width := nW;
            ADestR.Width := nW;
            AGh.DrawImage( FCellImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );
          end
          else
          begin
            Inc( BmpR.X, BmpR.Width div 2 );
            BmpR.Width := 1;
            AGh.DrawImage( FCellImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );
          end;
        end;
      end
      else      
        DrawStretchImage( AGh, FCellImage.Image, ADestR, BmpR );
    end
    else  AGh.DrawImage( FCellImage.Image, ADestR, BmpR.X, BmpR.Y, BmpR.Width, BmpR.Height, UnitPixel );
  end;  
end;

function TxdStringGrid.GetSelectedIndex(const AIndex: Integer): Integer;
begin
  if (AIndex >= Low(FSelectedRows)) and (AIndex <= High(FSelectedRows)) then
    Result := FSelectedRows[AIndex]
  else
    Result := -1;
end;

procedure TxdStringGrid.HighRow(const ARow: Integer);
var
  nOldRow: Integer;
begin
  if FHighRow <> ARow then
  begin
    nOldRow := FHighRow;
    FHighRow := ARow;
    if (nOldRow >= FixedRows) and (nOldRow < RowCount) then
    begin
      RowHeights[nOldRow] := DefaultRowHeight;
//      InvalidateRow( nOldRow );
    end;
    if FHighRow > -1 then
    begin
      RowHeights[ARow] := FHighRowHeight;
//      InvalidateRow( FHighRow );
    end;
  end;
end;

procedure TxdStringGrid.InitSetting;
begin
  BevelInner := bvNone;
  BevelKind := bkNone;
  BevelOuter := bvNone;
  BorderStyle := bsNone;
  Ctl3D := False;
  DefaultDrawing := False;
  ScrollBars := ssNone;
  DoubleBuffered := True;
end;

procedure TxdStringGrid.InvalidateCell(ACol, ARow: Integer);
begin
  inherited InvalidateCell(ACol, ARow);
end;

function TxdStringGrid.IsActiveControl: Boolean;
var
  H: Hwnd;
  ParentForm: TCustomForm;
begin
  Result := False;
  ParentForm := GetParentForm(Self);
  if Assigned(ParentForm) then
  begin
    if (ParentForm.ActiveControl = Self) then
      Result := True
  end
  else
  begin
    H := GetFocus;
    while IsWindow(H) and (Result = False) do
    begin
      if H = WindowHandle then
        Result := True
      else
        H := GetParent(H);
    end;
  end;
end;


function TxdStringGrid.IsRowSelected(const ARow: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  if goRowSelect in Options then
  begin
    for i := 0 to Length(FSelectedRows) - 1 do
    begin
      if ARow = FSelectedRows[i] then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
end;

procedure TxdStringGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  i, n: Integer;
begin
  if not (goRowSelect in Options) then
  begin
    inherited;
    Exit;
  end;

  if goRangeSelect in Options then
  begin
    //�ɶ�ѡ
    if (ssCtrl in Shift) and ( (Key = Ord('a')) or (Key = Ord('A')) ) then
    begin
      //ȫѡ
      SetLength( FSelectedRows, RowCount - FixedRows );
      n := 0;
      for i := FixedRows to RowCount - 1 do
      begin
        FSelectedRows[n] := i;
        Inc( n );
      end;
      InvalidateGrid;
      Exit;
    end;
  end;

  case Key of
    VK_ESCAPE: UnSelectedAll;
    VK_HOME: TopRow := FixedRows;
    VK_END: TopRow := RowCount - VisibleRowCount;
    VK_UP, VK_DOWN:
    begin
      if Assigned(FScrollBarHorizontal) and FScrollBarHorizontal.Visible then
      begin
        if Key = VK_UP then
          FScrollBarHorizontal.Position := FScrollBarHorizontal.Position - 1
        else
          FScrollBarHorizontal.Position := FScrollBarHorizontal.Position + 1;
        DoHorizontalScrollPosChanged( FScrollBarHorizontal, csKey );
      end;
    end;
    VK_LEFT, VK_RIGHT:
    begin
      if Assigned(FScrollBarVerical) and FScrollBarVerical.Visible then
      begin
        if Key = VK_LEFT then
          FScrollBarVerical.Position := FScrollBarVerical.Position - 1
        else
          FScrollBarVerical.Position := FScrollBarVerical.Position + 1;
        DoVericalScrollPosChanged( FScrollBarVerical, csKey );
      end;
    end;
  end;
end;

procedure TxdStringGrid.Loaded;
begin
  inherited;
  InitSetting;
  CheckScrollBarHor;
  ChangedScrollBarPosHor;
  CheckScrollBarVer;
  ChangedScrollBarPosVer;
  DoVericalScrollPosChanged( nil, csMouse );
end;

procedure TxdStringGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  nRow, nCol: Integer;
begin
  if Button = mbLeft then
  begin
    MouseToCell( X, Y, nCol, nRow );
    if (nRow >= FixedRows) and (nCol >= FixedCols) then
    begin
      CheckSelectRow( nRow );
      FSelectRect := Rect( X, Y, -1, -1 );
    end;
    DoDownPosChanged( nRow, nCol );
  end
  else
  begin
    if SelectedCount = 0 then
    begin
      MouseToCell( X, Y, nCol, nRow );
      CheckSelectRow( nRow );
    end;
  end;
  inherited ;
end;

procedure TxdStringGrid.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  nRow1, nRow2, nCol: Integer;
  i: Integer;
  R: TRect;
  nOldX, nOldY: Integer;
begin  
  inherited;
  MouseToCell( x, y, nCol, nRow1 );
  DoMousePosChanged( nRow1, nCol );
  if (goRangeSelect in Options) and (FSelectRect.Left <> -1) and (FSelectRect.Top <> -1) then
  begin 
    R := FSelectRect;
    nOldX := R.Right;
    nOldY := R.Bottom;
    FSelectRect.Right := X;
    FSelectRect.Bottom := Y; 
    
    nRow1 := FCurDownCell.FRowIndex;
    MouseToCell( 1, FSelectRect.Bottom, nCol, nRow2 );    

    if nRow2 = -1 then
      nRow2 := RowCount;
    if nRow1 > nRow2 then
    begin
      nCol := nRow1;
      nRow1 := nRow2;
      nRow2 := nCol;
    end;

    if nRow2 > nRow1 then
    begin
      SetLength( FSelectedRows, nRow2 - nRow1 + 1 );
      for i := Low(FSelectedRows) to High(FSelectedRows) do
      begin
        FSelectedRows[i] := nRow1;
        Inc( nRow1 );
      end;
    end;
    if R.Right < FSelectRect.Right then
      R.Right := FSelectRect.Right;
    if R.Bottom < FSelectRect.Bottom then
      R.Bottom := FSelectRect.Bottom;
    if R.Left > R.Right then
    begin
      i := R.Left;
      R.Left := R.Right;
      R.Right := i;
      if R.Left > nOldX then
        R.Left := nOldX;
    end;
    if R.Top > R.Bottom then
    begin
      i := R.Top;
      R.Top := R.Bottom;
      R.Bottom := i; 
      if R.Top > nOldY then
        R.Top := nOldY;
    end;
    InvalidateRect(Handle, @R, False );    
  end;
end;

procedure TxdStringGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
begin
  R := FSelectRect;
  FSelectRect := Rect( -1, -1, -1, -1 );
  FCurDownCell.FRowIndex := -1;
  FCurDownCell.FColIndex := -1;
  InvalidateRect(Handle, @R, False );
  inherited;
end;

procedure TxdStringGrid.Paint;
var
  ps: TPenStyle;
  bs: TBrushStyle;
  nColor: TColor;
begin
  Canvas.Brush.Color := 0;
  Canvas.FillRect( ClientRect );

  ParentPaint;
  //inherited Paint;
  
  if (goRangeSelect in Options) and (FSelectRect.Left <> -1) and (FSelectRect.Top <> -1) and
     (FSelectRect.Right <> -1) and (FSelectRect.Bottom <> -1) then
  begin
    ps := Canvas.Pen.Style;
    bs := Canvas.Brush.Style;
    nColor := Canvas.Pen.Color;

    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Style := psDot;
    Canvas.Pen.Color := 0;    
    Canvas.Rectangle( FSelectRect.Left, FSelectRect.Top, FSelectRect.Right, FSelectRect.Bottom );
  
    Canvas.Pen.Style := ps;
    Canvas.Pen.Color := nColor;
    Canvas.Brush.Style := bs;
  end;
end;

function PointInGridRect(Col, Row: Longint; const Rect: TGridRect): Boolean;
begin
  Result := (Col >= Rect.Left) and (Col <= Rect.Right) and (Row >= Rect.Top)
    and (Row <= Rect.Bottom);
end;

function StackAlloc(Size: Integer): Pointer; register;
asm
  POP   ECX          { return address }
  MOV   EDX, ESP
  ADD   EAX, 3
  AND   EAX, not 3   // round up to keep ESP dword aligned
  CMP   EAX, 4092
  JLE   @@2
@@1:
  SUB   ESP, 4092
  PUSH  EAX          { make sure we touch guard page, to grow stack }
  SUB   EAX, 4096
  JNS   @@1
  ADD   EAX, 4096
@@2:
  SUB   ESP, EAX
  MOV   EAX, ESP     { function result = low memory address of block }
  PUSH  EDX          { save original SP, for cleanup }
  MOV   EDX, ESP
  SUB   EDX, 4
  PUSH  EDX          { save current SP, for sanity check  (sp = [sp]) }
  PUSH  ECX          { return to caller }
end;

procedure StackFree(P: Pointer); register;
asm
  POP   ECX                     { return address }
  MOV   EDX, DWORD PTR [ESP]
  SUB   EAX, 8
  CMP   EDX, ESP                { sanity check #1 (SP = [SP]) }
  JNE   @@1
  CMP   EDX, EAX                { sanity check #2 (P = this stack block) }
  JNE   @@1
  MOV   ESP, DWORD PTR [ESP+4]  { restore previous SP  }
@@1:
  PUSH  ECX                     { return to caller }
end;


procedure FillDWord(var Dest; Count, Value: Integer); register;
asm
  XCHG  EDX, ECX
  PUSH  EDI
  MOV   EDI, EAX
  MOV   EAX, EDX
  REP   STOSD
  POP   EDI
end;

procedure TxdStringGrid.ParentPaint;
type
  PIntArray = ^TIntArray;
  TIntArray = array[0..MaxCustomExtents] of Integer;  
var
  LineColor: TColor;
  DrawInfo: TGridDrawInfo;
  Sel: TGridRect;
  UpdateRect: TRect;
  AFocRect, FocRect: TRect;
  PointsList: PIntArray;
  StrokeList: PIntArray;
  MaxStroke: Integer;
  FrameFlags1, FrameFlags2: DWORD;

  procedure DrawLines(DoHorz, DoVert: Boolean; Col, Row: Longint;
    const CellBounds: array of Integer; OnColor, OffColor: TColor);

  { Cellbounds is 4 integers: StartX, StartY, StopX, StopY
    Horizontal lines:  MajorIndex = 0
    Vertical lines:    MajorIndex = 1 }

  const
    FlatPenStyle = PS_Geometric or PS_Solid or PS_EndCap_Flat or PS_Join_Miter;

    procedure DrawAxisLines(const AxisInfo: TGridAxisDrawInfo;
      Cell, MajorIndex: Integer; UseOnColor: Boolean);
    var
      Line: Integer;
      LogBrush: TLOGBRUSH;
      Index: Integer;
      Points: PIntArray;
      StopMajor, StartMinor, StopMinor, StopIndex: Integer;
      LineIncr: Integer;
    begin
      with Canvas, AxisInfo do
      begin
        if EffectiveLineWidth <> 0 then
        begin
          Pen.Width := GridLineWidth;
          if UseOnColor then
            Pen.Color := OnColor
          else
            Pen.Color := OffColor;
          if Pen.Width > 1 then
          begin
            LogBrush.lbStyle := BS_Solid;
            LogBrush.lbColor := Pen.Color;
            LogBrush.lbHatch := 0;
            Pen.Handle := ExtCreatePen(FlatPenStyle, Pen.Width, LogBrush, 0, nil);
          end;
          Points := PointsList;
          Line := CellBounds[MajorIndex] + EffectiveLineWidth shr 1 +
            GetExtent(Cell);
          //!!! ??? Line needs to be incremented for RightToLeftAlignment ???
          if UseRightToLeftAlignment and (MajorIndex = 0) then Inc(Line);
          StartMinor := CellBounds[MajorIndex xor 1];
          StopMinor := CellBounds[2 + (MajorIndex xor 1)];
          StopMajor := CellBounds[2 + MajorIndex] + EffectiveLineWidth;
          StopIndex := MaxStroke * 4;
          Index := 0;
          repeat
            Points^[Index + MajorIndex] := Line;         { MoveTo }
            Points^[Index + (MajorIndex xor 1)] := StartMinor;
            Inc(Index, 2);
            Points^[Index + MajorIndex] := Line;         { LineTo }
            Points^[Index + (MajorIndex xor 1)] := StopMinor;
            Inc(Index, 2);
            // Skip hidden columns/rows.  We don't have stroke slots for them
            // A column/row with an extent of -EffectiveLineWidth is hidden
            repeat
              Inc(Cell);
              LineIncr := GetExtent(Cell) + EffectiveLineWidth;
            until (LineIncr > 0) or (Cell > LastFullVisibleCell);
            Inc(Line, LineIncr);
          until (Line > StopMajor) or (Cell > LastFullVisibleCell) or (Index > StopIndex);
           { 2 integers per point, 2 points per line -> Index div 4 }
          PolyPolyLine(Canvas.Handle, Points^, StrokeList^, Index shr 2);
        end;
      end;
    end;

  begin
    if (CellBounds[0] = CellBounds[2]) or (CellBounds[1] = CellBounds[3]) then Exit;
    if not DoHorz then
    begin
      DrawAxisLines(DrawInfo.Vert, Row, 1, DoHorz);
      DrawAxisLines(DrawInfo.Horz, Col, 0, DoVert);
    end
    else
    begin
      DrawAxisLines(DrawInfo.Horz, Col, 0, DoVert);
      DrawAxisLines(DrawInfo.Vert, Row, 1, DoHorz);
    end;
  end;

  procedure DrawCells(ACol, ARow: Longint; StartX, StartY, StopX, StopY: Integer;
    Color: TColor; IncludeDrawState: TGridDrawState);
  var
    CurCol, CurRow: Longint;
    AWhere, Where, TempRect: TRect;
    DrawState: TGridDrawState;
    Focused: Boolean;
  begin
    CurRow := ARow;
    Where.Top := StartY;
    while (Where.Top < StopY) and (CurRow < RowCount) do
    begin
      CurCol := ACol;
      Where.Left := StartX;
      Where.Bottom := Where.Top + RowHeights[CurRow];
      while (Where.Left < StopX) and (CurCol < ColCount) do
      begin
        Where.Right := Where.Left + ColWidths[CurCol];
        if (Where.Right > Where.Left) and RectVisible(Canvas.Handle, Where) then
        begin
          DrawState := IncludeDrawState;
          Focused := IsActiveControl;
          if Focused and (CurRow = Row) and (CurCol = Col)  then
          begin
            SetCaretPos(Where.Left, Where.Top);          
            Include(DrawState, gdFocused);
          end;
          if PointInGridRect(CurCol, CurRow, Sel) then
            Include(DrawState, gdSelected);
          if not (gdFocused in DrawState) or not (goEditing in Options) or
            not EditorMode or (csDesigning in ComponentState) then
          begin
            if DefaultDrawing or (csDesigning in ComponentState) then
              with Canvas do
              begin
                Font := Self.Font;
                if (gdSelected in DrawState) and
                  (not (gdFocused in DrawState) or
                  ([goDrawFocusSelected, goRowSelect] * Options <> [])) then
                begin
                  Brush.Color := clHighlight;
                  Font.Color := clHighlightText;
                end
                else
                  Brush.Color := Color;
                FillRect(Where);
              end;
            DrawCell(CurCol, CurRow, Where, DrawState);
            if DefaultDrawing and (gdFixed in DrawState) and Ctl3D and
              ((FrameFlags1 or FrameFlags2) <> 0) then
            begin
              TempRect := Where;
              if (FrameFlags1 and BF_RIGHT) = 0 then
                Inc(TempRect.Right, DrawInfo.Horz.EffectiveLineWidth)
              else if (FrameFlags1 and BF_BOTTOM) = 0 then
                Inc(TempRect.Bottom, DrawInfo.Vert.EffectiveLineWidth);
              DrawEdge(Canvas.Handle, TempRect, BDR_RAISEDINNER, FrameFlags1);
              DrawEdge(Canvas.Handle, TempRect, BDR_RAISEDINNER, FrameFlags2);
            end;

            if DefaultDrawing and not (csDesigning in ComponentState) and
              (gdFocused in DrawState) and
              ([goEditing, goAlwaysShowEditor] * Options <>
              [goEditing, goAlwaysShowEditor])
              and not (goRowSelect in Options) then
            begin
              if not UseRightToLeftAlignment then
                DrawFocusRect(Canvas.Handle, Where)
              else
              begin
                AWhere := Where;
                AWhere.Left := Where.Right;
                AWhere.Right := Where.Left;
                DrawFocusRect(Canvas.Handle, AWhere);
              end;
            end;
          end;
        end;
        Where.Left := Where.Right + DrawInfo.Horz.EffectiveLineWidth;
        Inc(CurCol);
      end;
      Where.Top := Where.Bottom + DrawInfo.Vert.EffectiveLineWidth;
      Inc(CurRow);
    end;
  end;

begin
  if UseRightToLeftAlignment then ChangeGridOrientation(True);

  UpdateRect := Canvas.ClipRect;
  CalcDrawInfo(DrawInfo);
  with DrawInfo do
  begin
    if (Horz.EffectiveLineWidth > 0) or (Vert.EffectiveLineWidth > 0) then
    begin
      { Draw the grid line in the four areas (fixed, fixed), (variable, fixed),
        (fixed, variable) and (variable, variable) }
      LineColor := clSilver;
      MaxStroke := Max(Horz.LastFullVisibleCell - LeftCol + FixedCols,
                        Vert.LastFullVisibleCell - TopRow + FixedRows) + 3;
      PointsList := StackAlloc(MaxStroke * sizeof(TPoint) * 2);
      StrokeList := StackAlloc(MaxStroke * sizeof(Integer));
      FillDWord(StrokeList^, MaxStroke, 2);

      if ColorToRGB(Color) = clSilver then LineColor := clGray;
      DrawLines(goFixedHorzLine in Options, goFixedVertLine in Options,
        0, 0, [0, 0, Horz.FixedBoundary, Vert.FixedBoundary], clBlack, FixedColor);
      DrawLines(goFixedHorzLine in Options, goFixedVertLine in Options,
        LeftCol, 0, [Horz.FixedBoundary, 0, Horz.GridBoundary,
        Vert.FixedBoundary], clBlack, FixedColor);
      DrawLines(goFixedHorzLine in Options, goFixedVertLine in Options,
        0, TopRow, [0, Vert.FixedBoundary, Horz.FixedBoundary,
        Vert.GridBoundary], clBlack, FixedColor);
      DrawLines(goHorzLine in Options, goVertLine in Options, LeftCol,
        TopRow, [Horz.FixedBoundary, Vert.FixedBoundary, Horz.GridBoundary,
        Vert.GridBoundary], LineColor, Color);

      StackFree(StrokeList);
      StackFree(PointsList);
    end;

    { Draw the cells in the four areas }
    Sel := Selection;
    FrameFlags1 := 0;
    FrameFlags2 := 0;
    if goFixedVertLine in Options then
    begin
      FrameFlags1 := BF_RIGHT;
      FrameFlags2 := BF_LEFT;
    end;
    if goFixedHorzLine in Options then
    begin
      FrameFlags1 := FrameFlags1 or BF_BOTTOM;
      FrameFlags2 := FrameFlags2 or BF_TOP;
    end;
    DrawCells(0, 0, 0, 0, Horz.FixedBoundary, Vert.FixedBoundary, FixedColor,
      [gdFixed]);
    DrawCells(LeftCol, 0, Horz.FixedBoundary - 0, 0, Horz.GridBoundary,  //!! clip
      Vert.FixedBoundary, FixedColor, [gdFixed]);
    DrawCells(0, TopRow, 0, Vert.FixedBoundary, Horz.FixedBoundary,
      Vert.GridBoundary, FixedColor, [gdFixed]);
    DrawCells(LeftCol, TopRow, Horz.FixedBoundary - 0,                   //!! clip
      Vert.FixedBoundary, Horz.GridBoundary, Vert.GridBoundary, Color, []);

    { Fill in area not occupied by cells }
    if Horz.GridBoundary < Horz.GridExtent then
    begin
      Canvas.Brush.Color := Color;
      Canvas.FillRect(Rect(Horz.GridBoundary, 0, Horz.GridExtent, Vert.GridBoundary));
    end;
    if Vert.GridBoundary < Vert.GridExtent then
    begin
      Canvas.Brush.Color := Color;
      Canvas.FillRect(Rect(0, Vert.GridBoundary, Horz.GridExtent, Vert.GridExtent));
    end;
  end;

  if UseRightToLeftAlignment then ChangeGridOrientation(False);
end;

procedure TxdStringGrid.Resize;
begin
  CheckScrollBarHor;
  CheckScrollBarVer;
  inherited Resize;
end;

function TxdStringGrid.SelectCell(ACol, ARow: Integer): Boolean;
begin
  Result := inherited SelectCell(ACol, ARow);
  if FDeleteSelected then
    Result := False;
end;

function TxdStringGrid.SelectedCount: Integer;
begin
  Result := Length( FSelectedRows );
end;

procedure TxdStringGrid.SetCellFont(const Value: TFontInfo);
begin
  FCellFont.Assign( Value );
end;

procedure TxdStringGrid.SetCellImage(const Value: TImageInfo);
begin
  FCellImage.Assign( Value );
end;

procedure TxdStringGrid.SetCellImageDrawMethod(const Value: TDrawMethod);
begin
  FCellImageDrawMethod.Assign( Value );
end;

procedure TxdStringGrid.SetDragAcceptFile(const Value: Boolean);
begin
  if FDragAcceptFile <> Value then
  begin
    FDragAcceptFile := Value;
    if FDragAcceptFile then
      DragAcceptFiles( Handle, True )
    else
      DragAcceptFiles( Handle, False );
  end;
end;

procedure TxdStringGrid.SetFixedBitmap(const Value: TImageInfo);
begin
  FFixedImage := Value;
end;

procedure TxdStringGrid.SetFixedFont(const Value: TFontInfo);
begin
  FFixedFont.Assign( Value );
end;

procedure TxdStringGrid.SetFixedImageDrawMethod(const Value: TDrawMethod);
begin
  FFixedImageDrawMethod.Assign( Value );
end;

procedure TxdStringGrid.SetHighRowHeight(const Value: Integer);
begin
  FHighRowHeight := Value;
end;

procedure TxdStringGrid.SetScrollBarHorizontal(const Value: TxdScrollBar);
begin
  FScrollBarHorizontal := Value;
  CheckScrollBarHor;
  ChangedScrollBarPosHor;
end;

procedure TxdStringGrid.SetScrollBarVerical(const Value: TxdScrollBar);
begin
  FScrollBarVerical := Value;
  CheckScrollBarVer;
  ChangedScrollBarPosVer;
end;

procedure TxdStringGrid.SizeChanged(OldColCount, OldRowCount: Integer);
var
  i, nH, nTemp: Integer;
begin
  inherited;
  if TopRow > FixedRows then
  begin
    nH := Height;
    for i := 0 to FixedRows - 1 do
      Dec( nH, RowHeights[i] );
    nTemp := 0;
    for i := TopRow to TopRow + VisibleRowCount - 1 do
      nTemp := nTemp + RowHeights[i];
    nTemp := nH - nTemp;
    if nTemp > 0 then
    begin
      for i := TopRow downto FixedRows do
      begin
        Dec( nTemp, RowHeights[i] );
        if nTemp <= 10  then Break;
      end;
      TopRow := i;
    end;
  end;
  CheckScrollBarHor;

  nTemp := RowCount;
  if nTemp < OldRowCount then
  begin
    i := 0;
    while i <= High(FSelectedRows) do
    begin
      if FSelectedRows[i] > nTemp then
      begin
        nH := Length(FSelectedRows);
        if nH - i > 0 then
          Move( FSelectedRows[i + 1], FSelectedRows[i], 4 * (nH - i) );
        SetLength( FSelectedRows, nH - 1 );
      end
      else
        Inc( i );
    end;
  end;
end;

procedure TxdStringGrid.TopLeftChanged;
var
  R: TRect;
begin
  inherited;
  ChangedScrollBarPosHor;
  if (FCurDownCell.FRowIndex <> -1) and (FCurDownCell.FColIndex <> -1) then
  begin
    R := CellRect( FCurDownCell.FColIndex, FCurDownCell.FRowIndex );
    FSelectRect.Top := R.Top;
    if R.Top = 0 then
    begin
      if FCurDownCell.FRowIndex < TopRow then
        FSelectRect.Top := RowHeights[FixedRows]
      else
        FSelectRect.Top := Height;
    end;
  end;
end;

procedure TxdStringGrid.UnSelectedAll;
var
  nReDrawRows: array of Integer;
  i, nLen: Integer;
begin
  nLen := Length(FSelectedRows);
  if nLen > 0 then
  begin
    SetLength( nReDrawRows, nLen );
    Move( FSelectedRows[0], nReDrawRows[0], 4 * nLen );
    SetLength( FSelectedRows, 0 );
    for i := 0 to nLen - 1 do
      InvalidateRow( nReDrawRows[i] );
    SetLength( nReDrawRows, 0 );
  end;
end;

procedure TxdStringGrid.WMDragDropFiles(var msg: TMessage);
var
  FileName: array[0..MAX_PATH] of Char;
  i, Sum: Integer;
  Files: TStringList;
begin
  inherited;
  if not Assigned(OnDragFiles) then Exit;
  Files := TStringList.Create;
  try
    //   ����������ļ���Ŀ���ù����ɵڶ�����������
    Sum:=DragQueryFile( msg.WParam, $FFFFFFFF, nil, 0 );
    for i := 0 to Sum - 1 do
    begin
      //��ȡ�ļ���
      FillChar( FileName, MAX_PATH, 0 );
      DragQueryFile( msg.WParam, i, FileName, MAX_PATH );
      Files.Add( FileName );
    end;
    OnDragFiles( Self, Files );
  finally
    DragFinish(msg.WParam);
    Files.Free;
  end;
end;

procedure TxdStringGrid.WMMouseWheel(var Message: TWMMouseWheel);
var
  nTopRow, nSize: Integer;
begin
  if IsCtrlDown then
    nSize := 5
  else
    nSize := 1;

  if Message.WheelDelta > 0 then
    nTopRow := TopRow - nSize
  else
    nTopRow := TopRow + nSize;
  if (nTopRow > 0) and (nTopRow + VisibleRowCount <= RowCount) then
    TopRow := nTopRow
  else if nSize = 5 then
  begin
    nSize := 1;
    if Message.WheelDelta > 0 then
      nTopRow := TopRow - nSize
    else
      nTopRow := TopRow + nSize;
    if (nTopRow > 0) and (nTopRow + VisibleRowCount <= RowCount) then
      TopRow := nTopRow
  end;
end;

end.
