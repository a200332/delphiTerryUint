unit uJxdParseGradient;

interface
  uses uStringHandle, Graphics, Classes, SysUtils;

{$M+}
type
  PGradient = ^TGradient;
  TGradient = record
    FFromColor: TColor;
    FColorTo:   TColor;
    FPercent:   Double;
  end;

  TParseGradient = class
  private
    FGradientList: TList;
    FGradientMsgText: string;
    procedure ClearAllListNode;
    procedure SetGradientMsgText(const Value: string);
    procedure ParseMsg(AMsgText: string; AIsAddToList: Boolean);
    procedure OnAddMsgToList(const AFromColor, ColorTo: TColor; const APercent: Double);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property GradientMsg: string read FGradientMsgText write SetGradientMsgText;
    property GradientList: TList read FGradientList;
  end;

implementation

{ TParseGradient }

procedure TParseGradient.ClearAllListNode;
var
  iLoop: Integer;
begin
  for iLoop := 0 to FGradientList.Count - 1 do
    Dispose(FGradientList[iLoop]);
  FGradientList.Clear;
end;

constructor TParseGradient.Create;
begin
  FGradientList := TList.Create;
end;

destructor TParseGradient.Destroy;
begin
  ClearAllListNode;
  FGradientList.Free;
  inherited;
end;

procedure TParseGradient.OnAddMsgToList(const AFromColor, ColorTo: TColor; const APercent: Double);
var
  p: PGradient;
begin
  New(p);
  p^.FFromColor := AFromColor;
  p^.FColorTo := ColorTo;
  p^.FPercent := APercent;
  FGradientList.Add(p);
end;

procedure TParseGradient.ParseMsg(AMsgText: string; AIsAddToList: Boolean);
  function HandleContent(const AText: string): string;
  begin
    Result := AText;
    uStringHandle.StringReplace(Result, ':', '');
    uStringHandle.StringReplace(Result, ';', '');
    uStringHandle.StringReplace(Result, '��', '');
    uStringHandle.StringReplace(Result, '��', '');
    uStringHandle.StringReplace(Result, ' ', '');
    uStringHandle.StringReplace(Result, #10, '');
    uStringHandle.StringReplace(Result, #13, '');
  end;
  procedure HandleStrToColor(const AStr: string; var AValue: TColor);
  begin
    try
      AValue := StringToColor(AStr);
    except
      raise Exception.Create('��ɫֵ����ȷ,����ȷ��д');
    end;
  end;
  function HandleStrToPercent(const AStr: string): Double;
  var
    strTmp: string;
    nValue: Integer;
  begin
    try
      if Pos('%', AStr) > 0 then
      begin
        strTmp := Astr;
        strTmp := GetRangString(strTmp, '%');
        nValue := StrToInt(strTmp);
        if (nValue > 100) or (nValue <= 0) then
          raise Exception.Create('Percent ��ֵҪ�� 1% ~ 100%֮��');
        Result := nValue / 100.00;
      end
      else
      begin
        Result := StrToFloat(Astr);
        if Result > 1.0 then
          raise Exception.Create('Percent ��ֵ���ܳ��� 1');
      end;
    except
      raise Exception.Create('Percent ֵ�ĸ�ʽ����');
    end;
  end;

var
  strFromColor, strColorTo, strPercent, strTmpContent: string;
  cFromColor, cColorTo: TColor;
  dPercent: Double;
  nCount: Integer;
begin
  nCount := 0;
  while True do
  begin
    strTmpContent := GetRangString(AMsgText, '#Gradient', '}');
    if strTmpContent = '' then
    begin
      if nCount = 0 then
        raise Exception.Create('�������Ϣ����ȷ')
      else
        Break;
    end;
    inc(nCount);
    strFromColor := HandleContent(GetRangString(strTmpContent, 'FromColor', ';'));
    if strFromColor = '' then
       raise Exception.Create('FromColor ����Ϊ��');
    HandleStrToColor(strFromColor, cFromColor);

    strColorTo := HandleContent(GetRangString(strTmpContent, 'ColorTo', ';'));
    if strColorTo = '' then
      raise Exception.Create('ColorTo ����Ϊ��');
    HandleStrToColor(strColorTo, cColorTo);

    strPercent := HandleContent(GetRangString(strTmpContent, 'Percent', False));
    if strPercent = '' then
      raise Exception.Create('Percent ����Ϊ��');
    dPercent := HandleStrToPercent(strPercent);

    if AIsAddToList then
      OnAddMsgToList(cFromColor, cColorTo, dPercent);
  end;
end;

procedure TParseGradient.SetGradientMsgText(const Value: string);
begin
  ParseMsg(Value, False);
  ClearAllListNode;
  FGradientMsgText := Value;
  ParseMsg(FGradientMsgText, True);
end;

end.
