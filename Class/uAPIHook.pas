unit uAPIHook;

interface

uses classes, Windows,SysUtils, messages,dialogs;

type
  TImportCode = packed record
     JumpInstruction: Word;
     AddressOfPointerToFunction: PPointer;
  end;
  PImportCode = ^TImportCode;
  PImage_Import_Entry = ^Image_Import_Entry;
  Image_Import_Entry = record
    Characteristics: DWORD;
    TimeDateStamp: DWORD;
    MajorVersion: Word;
    MinorVersion: Word;
    Name: DWORD;
    LookupTable: DWORD;
  end;
  TLongJmp = packed record
     JmpCode: ShortInt; {ָ���$E9������ϵͳ��ָ��}
     FuncAddr: DWORD; {������ַ}
  end;

  TAPIHook = class
  public
    constructor Create(IsTrap:boolean;OldFun,NewFun:pointer);
    destructor Destroy; override;
    procedure Restore;
    procedure Change;
  private
    FOldFunction,FNewFunction:Pointer;{���غ������Զ��庯��}
    Trap:boolean; {���÷�ʽ��True����ʽ��False�������ʽ}
    hProcess: Cardinal; {���̾����ֻ��������ʽ}
    AlreadyHook:boolean; {�Ƿ��Ѱ�װHook��ֻ��������ʽ}
    AllowChange:boolean; {�Ƿ�����װ��ж��Hook��ֻ���ڸ������ʽ}
    Oldcode: array[0..4]of byte; {ϵͳ����ԭ����ǰ5���ֽ�}
    Newcode: TLongJmp; {��Ҫд��ϵͳ������ǰ5���ֽ�}
  public
    property OldFunction: Pointer read FOldFunction;
    property NewFunction: Pointer read FNewFunction;
  end;

implementation

{ȡ������ʵ�ʵ�ַ����������ĵ�һ��ָ����Jmp����ȡ��������ת��ַ��ʵ�ʵ�ַ���������������ڳ����к���Debug������Ϣ�����}
function FinalFunctionAddress(Code: Pointer): Pointer;
Var
  Func: PImportCode;
begin
  Result:=Code;
  if Code=nil then exit;
  try
    func:=code;
    if (func.JumpInstruction=$25FF) then
      {ָ���������FF 25  ���ָ��jmp [...]}
      Func:=func.AddressOfPointerToFunction^;
    result:=Func;
  except
    Result:=nil;
  end;
end;

{�����������ָ�������ĵ�ַ��ֻ���ڸ������ʽ}
function PatchAddressInModule(BeenDone:Tlist;hModule: THandle; OldFunc,NewFunc: Pointer):integer;
const
   SIZE=4;
Var
   Dos: PImageDosHeader;
   NT: PImageNTHeaders;
   ImportDesc: PImage_Import_Entry;
   rva: DWORD;
   Func: PPointer;
   DLL: String;
   f: Pointer;
   written: DWORD;
   mbi_thunk:TMemoryBasicInformation;
   dwOldProtect:DWORD;
begin
  Result:=0;
  if hModule=0 then exit;
  Dos:=Pointer(hModule);
  {������DLLģ���Ѿ�����������˳���BeenDone�����Ѵ����DLLģ��}
  if BeenDone.IndexOf(Dos)>=0 then exit;
  BeenDone.Add(Dos);{��DLLģ��������BeenDone}
  OldFunc:=FinalFunctionAddress(OldFunc);{ȡ������ʵ�ʵ�ַ}

  {������DLLģ��ĵ�ַ���ܷ��ʣ����˳�}
  if IsBadReadPtr(Dos,SizeOf(TImageDosHeader)) then exit;
  {������ģ�鲻����'MZ'��ͷ����������DLL�����˳�}
  if Dos.e_magic<>IMAGE_DOS_SIGNATURE then exit;{IMAGE_DOS_SIGNATURE='MZ'}

  {��λ��NT Header}
  NT :=Pointer(Integer(Dos) + dos._lfanew);
  {��λ�����뺯����}
  RVA:=NT^.OptionalHeader.
     DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
  if RVA=0 then exit;{������뺯����Ϊ�գ����˳�}
  {�Ѻ�����������Ե�ַRVAת��Ϊ���Ե�ַ}
  ImportDesc := pointer(DWORD(Dos)+RVA);{Dos�Ǵ�DLLģ����׵�ַ}

  {�������б�������¼�DLLģ��}
  While (ImportDesc^.Name<>0) do
  begin
    {��������¼�DLLģ������}
    DLL:=PChar(DWORD(Dos)+ImportDesc^.Name);
    {�ѱ�������¼�DLLģ�鵱����ǰģ�飬���еݹ����}
    PatchAddressInModule(BeenDone,GetModuleHandle(PChar(DLL)),OldFunc,NewFunc);

    {��λ����������¼�DLLģ��ĺ�����}
    Func:=Pointer(DWORD(DOS)+ImportDesc.LookupTable);
    {������������¼�DLLģ������к���}
    While Func^<>nil do
    begin
      f:=FinalFunctionAddress(Func^);{ȡʵ�ʵ�ַ}
      if f=OldFunc then {�������ʵ�ʵ�ַ������Ҫ�ҵĵ�ַ}
      begin
         VirtualQuery(Func,mbi_thunk, sizeof(TMemoryBasicInformation));
         VirtualProtect(Func,SIZE,PAGE_EXECUTE_WRITECOPY,mbi_thunk.Protect);{�����ڴ�����}
         WriteProcessMemory(GetCurrentProcess,Func,@NewFunc,SIZE,written);{���º�����ַ������}
         VirtualProtect(Func, SIZE, mbi_thunk.Protect,dwOldProtect);{�ָ��ڴ�����}
      end;
      If Written=4 then Inc(Result);
//      else showmessagefmt('error:%d',[Written]);
      Inc(Func);{��һ�����ܺ���}
    end;
    Inc(ImportDesc);{��һ����������¼�DLLģ��}
  end;
end;

{HOOK����ڣ�����IsTrap��ʾ�Ƿ��������ʽ}
constructor TAPIHook.Create(IsTrap:boolean;OldFun,NewFun:pointer);
begin
   {�󱻽غ������Զ��庯����ʵ�ʵ�ַ}
   FOldFunction:=FinalFunctionAddress(OldFun);
   FNewFunction:=FinalFunctionAddress(NewFun);

   Trap:=IsTrap;
   if Trap then{���������ʽ}
   begin
      {����Ȩ�ķ�ʽ���򿪵�ǰ����}
      hProcess := OpenProcess(PROCESS_ALL_ACCESS,FALSE, GetCurrentProcessID);
      {����jmp xxxx�Ĵ��룬��5�ֽ�}
      Newcode.JmpCode := ShortInt($E9); {jmpָ���ʮ�����ƴ�����E9}
      NewCode.FuncAddr := DWORD(FNewFunction) - DWORD(FOldFunction) - 5;
      {���汻�غ�����ǰ5���ֽ�}
      move(FOldFunction^,OldCode,5);
      {����Ϊ��û�п�ʼHOOK}
      AlreadyHook:=false;
   end;
   {����Ǹ������ʽ��������HOOK}
   if not Trap then AllowChange:=true;
   Change; {��ʼHOOK}
   {����Ǹ������ʽ������ʱ������HOOK}
   if not Trap then AllowChange:=false;
end;

{HOOK�ĳ���}
destructor TAPIHook.Destroy;
begin
   {����Ǹ������ʽ��������HOOK}
   if not Trap then AllowChange:=true;
   Restore; {ֹͣHOOK}
   if Trap then{���������ʽ}
      CloseHandle(hProcess);
end;

{��ʼHOOK}
procedure TAPIHook.Change;
var
   nCount: DWORD;
   BeenDone: TList;
begin
  if Trap then{���������ʽ}
  begin
    if (AlreadyHook)or (hProcess = 0) or (FOldFunction = nil) or (FNewFunction = nil) then
        exit;
    AlreadyHook:=true;{��ʾ�Ѿ�HOOK}
    WriteProcessMemory(hProcess, FOldFunction, @(Newcode), 5, nCount);
  end
  else begin{����Ǹ������ʽ}
       if (not AllowChange)or(FOldFunction=nil)or(FNewFunction=nil)then exit;
       BeenDone:=TList.Create; {���ڴ�ŵ�ǰ��������DLLģ�������}
       try
         PatchAddressInModule(BeenDone,GetModuleHandle(nil),FOldFunction,FNewFunction);
       finally
         BeenDone.Free;
       end;
  end;
end;

{�ָ�ϵͳ�����ĵ���}
procedure TAPIHook.Restore;
var
   nCount: DWORD;
   BeenDone: TList;
begin
  if Trap then{���������ʽ}
  begin
    if (not AlreadyHook) or (hProcess = 0) or (FOldFunction = nil) or (FNewFunction = nil) then
    begin
      OutputDebugString( 'do not need to hook' );
      exit;
    end;
    WriteProcessMemory(hProcess, FOldFunction, @(Oldcode), 5, nCount);
    AlreadyHook:=false;{��ʾ�˳�HOOK}
  end
  else begin{����Ǹ������ʽ}
    if (not AllowChange)or(FOldFunction=nil)or(FNewFunction=nil)then exit;
    BeenDone:=TList.Create;{���ڴ�ŵ�ǰ��������DLLģ�������}
    try
      PatchAddressInModule(BeenDone,GetModuleHandle(nil),FNewFunction,FOldFunction);
    finally
      BeenDone.Free;
    end;
  end;
end;

end.

