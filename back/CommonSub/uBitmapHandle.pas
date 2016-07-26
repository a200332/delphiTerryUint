unit uBitmapHandle;

interface
  uses Windows, Classes, Graphics, SysUtils, Forms;

{���Կ���}
//{$define OutPutImage}  //�Ҷ�ͼ��ʱ,�������浽������
//

  //�õ�ָ��������ڵ�ͼ��
  function GetBitmapFromHandle(const AMainHandle, AHandle: HWND;
                               const ASoftWidth, ASoftHeigth: Integer; var ABmp: TBitmap): Boolean;
  //��ͼƬ��ɺڰ�
  procedure BitmapChangeBlackAndWhite(var ABmp: TBitmap);
  //�ı�ͼƬ������
  //ABrightValue: ����: -255(��) ~~ 255(��)
  procedure ChangeBrightness(const ABmp:TBitmap; ABrightValue: Integer);
  //��Canvas ���
  procedure GrapCanvas(ACanvas: TCanvas; const AWidth, AHeight: Integer; ATransColor: TColor);

  //�õ�ĳһ��ͼƬ��ԭͼƬ�����ƶ�. �ٷ�֮��Ϊȫ��ͬ
  //IsStrict : �Ƿ��ϸ�Ա�
  //ErrorValue: �ݴ�Χ  �� IsStrict ʱ��Ч
  function GetBitmapConform(const AOrgBmp, ADesBmp: TBitmap; IsStrict: Boolean = True; ErrorValue: Integer = 200000): Integer;

  //������ɫ,�� FromColor ����� ToColor;
  procedure DrawGradient(Canvas: TCanvas; FromColor, ToColor: TColor; Steps: Integer; R: TRect; Direction: Boolean);

  //��pen �����߿�
  procedure DrawFrameBorder(Canvas: TCanvas; const LienColor: TColor; const LienWidth: Integer; R: TRect);

  procedure OutPutImage(const ABmp: TBitmap; const AFileName: string = '');

  //
  procedure DrawRectangle(ACanvas: TCanvas; const ABmpR, AResR: TRect; AResBmp: TBitmap); overload;
  procedure DrawRectangle(ADesCanvas, ASrcCanvas: TCanvas; const ADesR, ASrcR: TRect; AUpToDown: Boolean); overload;

  //��ɫ
  procedure TransColor(ABmp: TBitmap; AColor: TColor); overload;
  procedure TransColor(ABmp: TBitmap; AColor, ATransparentColor: TColor); overload;

  function  WidthOfRect(const R: TRect): Integer;                        
  function  HeightOfRect(const R: TRect): Integer;

implementation

Type
  pRGBArray  = ^TRGBArray;
  TRGBArray   = array[0..65536 - 1] OF TRGBTriple;

function  WidthOfRect(const R: TRect): Integer;
begin
  Result := R.Right - R.Left;
end;

function  HeightOfRect(const R: TRect): Integer;
begin
  Result := R.Bottom - R.Top;
end;

procedure OutPutImage(const ABmp: TBitmap; const AFileName: string = '');
var
  strFileName: string;
begin
  strFileName := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
  if AFileName = '' then
    strFileName := Format('%s%d %d.bmp', [strFileName, ABmp.Width, ABmp.Height])
  else
    strFileName := strFileName + AFileName;
  ABmp.SaveToFile(strFileName);
end;

function GetBitmapFromHandle(const AMainHandle, AHandle: HWND;
                             const ASoftWidth, ASoftHeigth: Integer; var ABmp: TBitmap): Boolean;
var
  dc: HDC;
  bVisible, bChangePos: Boolean;
  rtOldMain, rtNewMain, rtChild: TRect;
begin
  if IsWindow(AHandle) then
    Result := True
  else
  begin
    Result := False;
    Exit;
  end;
  
  bVisible := IsWindowVisible(AMainHandle);
  bChangePos := False;
  try
    GetWindowRect(AMainHandle, rtOldMain);
    SetWindowPos(AMainHandle, 0, 0, 0, ASoftWidth, ASoftHeigth, SWP_NOMOVE);
    GetWindowRect(AMainHandle, rtNewMain);
    GetWindowRect(AHandle, rtChild);
    ABmp.width := rtChild.Right - rtChild.Left; 
    ABmp.height := rtChild.Bottom - rtChild.Top;

    if not bVisible then
    begin
      bChangePos := True;
      ShowWindow(AMainHandle, SW_SHOW);
    end;
    SetWindowPos(AMainHandle, 0, 10, 10, 0, 0, SWP_NOSIZE);
    Sleep(100);
    
    dc := GetDC(AHandle);
    Bitblt(ABmp.Canvas.Handle, 0, 0, ABmp.Width, ABmp.Height, dc, 0, 0,SRCCOPY);
    ReleaseDC(AHandle, dc);
    if bChangePos then
      ShowWindow(AMainHandle, SW_HIDE);
    SetWindowPos(AMainHandle, 0, rtOldMain.Left, rtOldMain.Top, 0, 0, SWP_NOSIZE);
    SetWindowPos(AMainHandle, 0, 0, 0, rtOldMain.Right - rtOldMain.Left, rtOldMain.Bottom - rtOldMain.Top, SWP_NOMOVE);

{$ifdef OutPutImage}
    OutPutImage(ABmp, 'BitmapFromHandle.bmp');
{$endif}

  except
    ABmp.free;
    raise Exception.Create('��ȡָ���������ͼ�����');
  end;
end;

procedure GrapCanvas(ACanvas: TCanvas; const AWidth, AHeight: Integer; ATransColor: TColor);
type
  TRGBArray = array[0..32767] of TRGBTriple;
  PRGBArray = ^TRGBArray;
var
  x, y, Gray: Integer;
  R, G, B: Byte;
  Pixel: Cardinal;
begin
  for y := 0 to AHeight - 1 do
  begin
    for x := 0 to AWidth - 1 do
    begin
      Pixel := GetPixel( ACanvas.Handle, x, y );
      if Pixel = Cardinal(ATransColor) then Continue;
      if Pixel = 0 then
      begin
        ACanvas.Pixels[X,Y] := $00797978;
        Continue;
      end;
      R := GetRValue( Pixel );
      G := GetGValue( Pixel );
      B := GetBValue( Pixel );
      Gray := ( R + G + B ) div 3;
      ACanvas.Pixels[X,Y] := RGB( Gray,Gray,Gray );
    end;
  end;
end;

procedure BitmapChangeBlackAndWhite(var ABmp: TBitmap);
  function CalcBmpGrayValue: Integer;
  var
    p: PRGBTriple;
    xPos, xCount: Integer;
    yPos, yCount: Integer;
    fResult: Extended;
  begin
    fResult := 0.0;
    yCount := ABmp.Height;
    xCount := ABmp.Width;
    for yPos := 0 to yCount - 1 do
    begin
      p := ABmp.ScanLine[yPos];
      for xPos := 0 to xCount- 1 do
      begin
        fResult := (p^.rgbtRed + p^.rgbtGreen + p^.rgbtBlue) / 3 + fResult;
        inc(p);
      end;
    end;
    Result := Round(fResult / (xCount * yCount));
  end;
var
  xPos, yPos, xCount, yCount: Integer;
  cPixColor: TColor;
  nGrayAVG: Integer;
begin
  try

{$ifdef OutPutImage}
    OutPutImage(ABmp, 'OrgBitmap.bmp');
{$endif}
    ABmp.Canvas.Lock;
    try
      xCount := ABmp.Width;
      yCount := ABmp.Height;
      nGrayAVG := CalcBmpGrayValue;
      for yPos := 0 to yCount - 1 do
      begin
        for xPos := 0 to xCount - 1 do
        begin
          cPixColor := Abmp.Canvas.Pixels[xPos, yPos] ;
          cPixColor := (GetRValue(cPixColor) + GetGValue(cPixColor) + GetBValue(cPixColor)) div 3;
          if cPixColor > nGrayAVG then
            Abmp.Canvas.Pixels[xPos, yPos] := $FFFFFF
          else
            Abmp.Canvas.Pixels[xPos, yPos] := 0;
        end;
      end;
    finally
      ABmp.Canvas.Unlock;
    end;
{$ifdef OutPutImage}
    OutPutImage(ABmp, 'BlackAndWhiteBitmap.bmp');
{$endif}
  except
    raise Exception.Create('�Ҷ�ͼ��ʱ����');
  end;
end;

function GetBitmapConform(const AOrgBmp, ADesBmp: TBitmap; IsStrict: Boolean = True; ErrorValue: Integer = 200000): Integer;
var
  x, xCount, y, yCount: Integer;
  cOrgPix, cDesPic: TColor;
begin
  Result := 0;
  try
    xCount := AOrgBmp.Width;
    yCount := AOrgBmp.Height;
    if xCount > ADesBmp.Width then
      xCount := ADesBmp.Width;
    if yCount > ADesBmp.Height then
      yCount := ADesBmp.Height;

    if IsStrict then
    begin
      for x := 0 to xCount - 1 do //��������
        for y := 0 to yCount - 1 do //��������
        begin
          if AOrgBmp.Canvas.Pixels[x, y] = ADesBmp.Canvas.Pixels[x, y] then
            inc(Result);
        end;
    end
    else
    begin
      for x := 0 to xCount - 1 do //��������
        for y := 0 to yCount - 1 do //��������
        begin
          cOrgPix := AOrgBmp.Canvas.Pixels[x, y];
          cDesPic := ADesBmp.Canvas.Pixels[x, y];
          if abs(cOrgPix - cDesPic) <= ErrorValue then
            inc(Result);
        end;
    end;
    Result :=  round((Result / (xCount * yCount)) * 100) ;
  except
    raise Exception.Create('�Ա�ͼ�����');
  end;
end;

procedure DrawGradient(Canvas: TCanvas; FromColor, ToColor: TColor; Steps: Integer; R: TRect; Direction: Boolean);
var
  diffr, startr, endr: Integer;
  diffg, startg, endg: Integer;
  diffb, startb, endb: Integer;
  rstepr, rstepg, rstepb, rstepw: Real;
  i, stepw: Word;

begin
  if Steps = 0 then
    Steps := 1;

  FromColor := ColorToRGB(FromColor);
  ToColor := ColorToRGB(ToColor);

  startr := (FromColor and $0000FF);
  startg := (FromColor and $00FF00) shr 8;
  startb := (FromColor and $FF0000) shr 16;

  endr := (ToColor and $0000FF);
  endg := (ToColor and $00FF00) shr 8;
  endb := (ToColor and $FF0000) shr 16;

  diffr := endr - startr;
  diffg := endg - startg;
  diffb := endb - startb;

  rstepr := diffr / steps;
  rstepg := diffg / steps;
  rstepb := diffb / steps;

  if Direction then
    rstepw := (R.Right - R.Left) / Steps
  else
    rstepw := (R.Bottom - R.Top) / Steps;

  with Canvas do
  begin
    for i := 0 to steps - 1 do
    begin
      endr := startr + Round(rstepr * i);
      endg := startg + Round(rstepg * i);
      endb := startb + Round(rstepb * i);
      stepw := Round(i * rstepw);
      Pen.Color := endr + (endg shl 8) + (endb shl 16);
      Brush.Color := Pen.Color;
      if Direction then
        Rectangle(R.Left + stepw, R.Top, R.Left + stepw + Round(rstepw) + 1, R.Bottom)
      else
        Rectangle(R.Left, R.Top + stepw, R.Right, R.Top + stepw + Round(rstepw) + 1);
    end;
  end;
end;

procedure DrawFrameBorder(Canvas: TCanvas; const LienColor: TColor; const LienWidth: Integer; R: TRect);
var
  OldPenColor: TColor;
  OldPenWidth: Integer;
  nSpace: Integer;
begin
  OldPenColor := Canvas.Pen.Color;
  OldPenWidth := Canvas.Pen.Width;
  try
    Canvas.Pen.Color := LienColor;
    Canvas.Pen.Width := LienWidth;
    if LienWidth > 1 then
    begin
      nSpace := LienWidth div 2;
      with Canvas do
      begin
        {��}
        MoveTo(R.Left, R.Top + nSpace);
        LineTo(R.Right, R.Top + nSpace);
        {��}
        MoveTo(R.Right - nSpace, R.Top + nSpace);
        LineTo(R.Right - nSpace, R.Bottom);
        {��}
//        MoveTo(R.Right - nSpace, R.Bottom - nSpace);
        LineTo(R.Left, R.Bottom - nSpace);
        {��}
        MoveTo(R.Left + nSpace, R.Bottom);
        LineTo(R.Left + nSpace, R.Top);
      end;
    end
    else
    begin
      with Canvas do
      begin
        {��}
        MoveTo(R.Left, R.Top);
        LineTo(R.Right, R.Top);
        {��}
        MoveTo(R.Right - 1, R.Top);
        LineTo(R.Right - 1, R.Bottom);
        {��}
        MoveTo(R.Right - 1, R.Bottom - 1);
        LineTo(R.Left, R.Bottom - 1);
        {��}
        MoveTo(R.Left, R.Bottom);
        LineTo(R.Left, R.Top);
      end;
    end;
  finally
    Canvas.Pen.Color := OldPenColor;
    Canvas.Pen.Width := OldPenWidth;
  end;
end;

procedure DrawRectangle(ACanvas: TCanvas; const ABmpR, AResR: TRect; AResBmp: TBitmap);
var
  BmpR, DesR: TRect;
  w: Integer;
begin
  BmpR := ABmpR;
  DesR := AResR;
  w := ( AResR.Right - AResR.Left + 1 ) div 2;
  //���
  BmpR.Right := BmpR.Left + w;
  DesR.Right := DesR.Left + w;
  ACanvas.CopyRect( BmpR, AResBmp.Canvas, DesR );
  //�м�, ����
  BmpR.Left := BmpR.Right;
  BmpR.Right := ABmpR.Right - w + 1;
  DesR.Left := DesR.Right - w mod 2;
  DesR.Right := DesR.Left + 1;
  ACanvas.CopyRect( BmpR, AResBmp.Canvas, DesR );
//  //�ұ�
  BmpR.Left := BmpR.Right;
  BmpR.Right := ABmpR.Right;
  DesR.Left := DesR.Right;
  DesR.Right := AResR.Right;
  ACanvas.CopyRect( BmpR, AResBmp.Canvas, DesR );
end;

procedure DrawRectangle(ADesCanvas, ASrcCanvas: TCanvas; const ADesR, ASrcR: TRect; AUpToDown: Boolean);
  procedure DrawUpToDown;
  var
    n, h: Integer;
    SrcWidth, DesWidth, DesHeight: Integer;
  begin
    SrcWidth := ASrcR.Right - ASrcR.Left;
    DesWidth := ADesR.Right - ADesR.Left;
    DesHeight := ADesR.Bottom - ADesR.Top;
    n := (ASrcR.Bottom - ASrcR.Top) mod 2;
    h := (ASrcR.Bottom - ASrcR.Top + n) div 2;
    //��
    StretchBlt( ADesCanvas.Handle, ADesR.Left, ADesR.Top, DesWidth, h,
                ASrcCanvas.Handle, ASrcR.Left, ASrcR.Top, SrcWidth, h, SRCCOPY);
    //��
    n := DesHeight - h;
    StretchBlt( ADesCanvas.Handle, ADesR.Left, ADesR.Top + h, DesWidth, n,
                ASrcCanvas.Handle, ASrcR.Left, ASrcR.Top + h - 1, SrcWidth, 1, SRCCOPY);
//    //��
    StretchBlt( ADesCanvas.Handle, ADesR.Left, ADesR.Top + n, DesWidth, h,
                ASrcCanvas.Handle, ASrcR.Left, ASrcR.Top + h - 1, SrcWidth, h, SRCCOPY);
  end;

  procedure DrawLeftToRight;
  var
    SrcHeight, DesWidth, DesHeight: Integer;
    n, w: Integer;
  begin
    SrcHeight := HeightOfRect( ASrcR );
    DesWidth := WidthOfRect( ADesR );
    DesHeight := HeightOfRect( ADesR );
    n := WidthOfRect( ASrcR ) mod 2;
    w := (WidthOfRect( ASrcR ) + n) div 2;
    //��
    StretchBlt( ADesCanvas.Handle, ADesR.Left, ADesR.Top, w, DesHeight,
                ASrcCanvas.Handle, ASrcR.Left, ASrcR.Top, w, SrcHeight, SRCCOPY);
    //��
    n := DesWidth - w;
    StretchBlt( ADesCanvas.Handle, ADesR.Left + w, ADesR.Top, n, DesHeight,
                ASrcCanvas.Handle, ASrcR.Left + w - 1, ASrcR.Top, 1, SrcHeight, SRCCOPY);
    //��
    StretchBlt( ADesCanvas.Handle, ADesR.Left + n, ADesR.Top, w, DesHeight,
                ASrcCanvas.Handle, ASrcR.Left + w - 1, ASrcR.Top, w, SrcHeight, SRCCOPY);
  end;
  ////////////////////////////////////////
begin
  if AUpToDown then
    DrawUpToDown
  else
    DrawLeftToRight;
end;

procedure TransColor(ABmp: TBitmap; AColor: TColor);
var
  i, j: Integer;
  RGBRow: pRGBArray;
  R, G, B: Byte;
begin
  ABmp.PixelFormat := pf24bit;
  R := GetRValue( AColor );
  G := GetGValue( AColor );
  B := GetBValue( AColor );
  for i := 0 to ABmp.Height - 1 do
  begin
    RGBRow := pRGBArray( ABmp.ScanLine[i] );
    for j := 0 to ABmp.Width - 1 do
    begin
      RGBRow[j].rgbtRed   := 255 - (255 - RGBRow[j].rgbtRed) * (255 - R) div 255;
      RGBRow[j].rgbtGreen := 255 - (255 - RGBRow[j].rgbtGreen) * (255 - G) div 255;
      RGBRow[j].rgbtBlue  := 255 - (255 - RGBRow[j].rgbtBlue) * (255 - B) div 255;
    end;
  end;
end;

procedure TransColor(ABmp: TBitmap; AColor, ATransparentColor: TColor);
var
  i, j: Integer;
  RGBRow: pRGBArray;
  R, G, B: Byte;
  TransR, TransG, TransB: Byte;
begin
  ABmp.PixelFormat := pf24bit;
  R := GetRValue( AColor );
  G := GetGValue( AColor );
  B := GetBValue( AColor );

  TransR := GetRValue( ATransparentColor );
  TransG := GetGValue( ATransparentColor );
  TransB := GetBValue( ATransparentColor );

  for i := 0 to ABmp.Height - 1 do
  begin
    RGBRow := pRGBArray( ABmp.ScanLine[i] );
    for j := 0 to ABmp.Width - 1 do
    begin
      if (TransR = RGBRow[j].rgbtRed) and (TransG  = RGBRow[j].rgbtGreen) and (TransB  = RGBRow[j].rgbtBlue) then Continue;
      RGBRow[j].rgbtRed   := 255 - (255 - RGBRow[j].rgbtRed) * (255 - R) div 255;
      RGBRow[j].rgbtGreen := 255 - (255 - RGBRow[j].rgbtGreen) * (255 - G) div 255;
      RGBRow[j].rgbtBlue  := 255 - (255 - RGBRow[j].rgbtBlue) * (255 - B) div 255;
    end;
  end;
end;

procedure ChangeBrightness(const ABmp:TBitmap; ABrightValue: Integer);
  function BrightValue(ARGB: Integer): Integer;
  begin
    Result := ARGB + ABrightValue;
    if Result < 0 then
      Result := 0
    else if Result > 255 then
      Result := 255;
  end;
var
  i, j: integer;
  pRGB: pRGBTriple;
begin
  for i := 0 to ABmp.Height   -   1   do
  begin
    pRGB := ABmp.ScanLine[i];
    for j := 0 to ABmp.Width - 1 do
    begin
      pRGB.rgbtBlue := BrightValue(pRGB.rgbtBlue);
      pRGB.rgbtGreen := BrightValue(pRGB.rgbtGreen);
      pRGB.rgbtRed := BrightValue(pRGB.rgbtRed);
      Inc(pRGB);
    end;
  end;
end;

end.
