unit uNetwork;

interface
  uses Windows, SysUtils, UrlMon, WinInet, IdHttp, uStringHandle, ComObj, ShellAPI, WinSock;

  function DownFile(ASrcUrl, AFileName: string; TryCount: Integer = 4): Boolean;
  //�õ�ĳһ�����ʹ�����վ��Cookie
  function GetCookieValue(const ASrcUrl: string): string;
  //AAutoRedirects: �Զ���ת, ���ΪFalse. ���������ַ��Ҫ��תʱ,��ô��������Ҫ��ת��URL;
  function GetUrlSourceText(const ASrcUrl: string; ARefererUrl: string = ''; AIdHttp: TIdHttp = nil; AAutoGetCookie: Boolean = True;
                            ACookie: string = ''; AAutoRedirects: Boolean = True; const ATryCount: Integer = 4): string;
  //���ASrcUrl ��Ҫ��ת.��ô������.���򷵻�Դ�ļ�
  function GetRedirectUrl(const ASrcUrl: string): string;

  //��һ����ҳ
  procedure OpenExplorer(const AUrl: string; const AIsNewIE: Boolean = True; const AIsVisible: Boolean = True);

  function GetLocalIP:string;   //��ȡ���ػ���IP��ַ

implementation

function GetLocalIP:string;   //��ȡ���ػ���IP��ַ
type 
   TaPInAddr = array [0..10] of PInAddr; 
   PaPInAddr = ^TaPInAddr;
var
   phe  : PHostEnt; 
   pptr : PaPInAddr; 
   Buffer : array [0..63] of char; 
   I    : Integer; 
   GInitData      : TWSADATA;
begin 
   WSAStartup($101, GInitData); 
   Result := ''; 
   GetHostName(Buffer, SizeOf(Buffer)); 
   phe :=GetHostByName(buffer); 
   if phe = nil then Exit; 
   pptr := PaPInAddr(Phe^.h_addr_list); 
   I := 0; 
   while pptr^[I] <> nil do 
   begin 
     result:=StrPas(inet_ntoa(pptr^[I]^)); 
     Inc(I); 
   end; 
   WSACleanup; 
end;

procedure OpenExplorer(const AUrl: string; const AIsNewIE: Boolean; const AIsVisible: Boolean);
  procedure OpenNewWinExplorer;
  var
    IE: Variant;
  begin
    IE   :=   CreateOleObject('InternetExplorer.Application');
    IE.Visible   :=   AIsVisible;
    IE.Navigate(AUrl);
  end;
begin
  if AIsNewIE then
    OpenNewWinExplorer
  else
    if AIsVisible then
      ShellExecute(0,'open','iexeplore.exe', PChar(AUrl), nil, SW_SHOW)
    else
      ShellExecute(0,'open','iexeplore.exe', PChar(AUrl), nil, SW_HIDE)
end;

function DownFile(ASrcUrl, AFileName: string; TryCount: Integer = 4): Boolean;
var
  downCount: Integer;
begin
  Result := False;
  if FileExists(AFileName) then
  begin
    Result := True;
    Exit;
  end;
  if not DirectoryExists(ExtractFileDir(AFileName)) then
  begin
    ForceDirectories(ExtractFileDir(AFileName));
  end;
  for downCount := 1 to TryCount do
  begin
    Result := UrlDownloadToFile(nil, PChar(ASrcUrl), PChar(AFileName), 0, nil) = S_OK;
    if Result then
      Break
    else
      Sleep(1000 * 3 * (downCount-1));
  end;
end;

function GetCookieValue(const ASrcUrl: string): string;
var
  pBuf: PChar;
  nLen: DWORD;
  strURL: string;
begin
  strURL := IncludeString(ASrcUrl, 'http://', 1);
  nLen := 1024;
  GetMem(pBuf, nLen);
  try
    if not InternetGetCookie(PChar(strURL), nil, pBuf, nLen) then
    begin
      FreeMem(pBuf);
      GetMem(pBuf, nLen);
      InternetGetCookie(PChar(strURL), nil, pBuf, nLen);
    end;
    Result := pBuf;
  finally
    FreeMem(pBuf);
  end;
end;

function GetRedirectUrl(const ASrcUrl: string): string;
begin
  Result := GetUrlSourceText(ASrcUrl, '', nil, True, '', False);
end;

function GetUrlSourceText(const ASrcUrl: string; ARefererUrl: string; AIdHttp: TIdHttp; AAutoGetCookie: Boolean;
                            ACookie: string; AAutoRedirects: Boolean; const ATryCount: Integer): string;
var
  strUrl: string;
  bFreeIdHttp: Boolean;
  nResovleCount: Integer; //����ض������
begin
  strURL := IncludeString(ASrcUrl, 'http://', 1);
  if AIdHttp = nil then
  begin
    AIdHttp := TIdHttp.Create(nil);
    bFreeIdHttp := True;
  end
  else
    bFreeIdHttp := False;
  if AAutoGetCookie then
    ACookie := GetCookieValue(strURL);

  if ACookie <> '' then
    AIdHttp.Request.CustomHeaders.Add('Cookie: ' + ACookie);

  if ARefererUrl <> '' then
    AIdHttp.Request.Referer := IncludeString(ARefererUrl, 'http://', 1);

  nResovleCount := ATryCount;
  AIdHttp.HandleRedirects := AAutoRedirects;
  while nResovleCount > 0 do
  begin
    try
      Result := AIdHttp.Get(strUrl);
      Break;
    except
      if not AAutoRedirects then
      begin
        Result := AIdhttp.Response.Location;
        Break;
      end;
      if (AIdHttp.ResponseCode >= 301) and (AIdHttp.ResponseCode <= 304) then
      begin
        strUrl := AIdhttp.Response.Location;
        if (strUrl = '') or (nResovleCount < 0) then
          Break;
      end;
      Dec(nResovleCount);
    end;
  end;

  if bFreeIdHttp then
    AIdHttp.Free;
end;

end.
