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
     JmpCode: ShortInt; {指令，用$E9来代替系统的指令}
     FuncAddr: DWORD; {函数地址}
  end;

  TAPIHook = class
  public
    constructor Create(IsTrap:boolean;OldFun,NewFun:pointer);
    destructor Destroy; override;
    procedure Restore;
    procedure Change;
  private
    FOldFunction,FNewFunction:Pointer;{被截函数、自定义函数}
    Trap:boolean; {调用方式：True陷阱式，False改引入表式}
    hProcess: Cardinal; {进程句柄，只用于陷阱式}
    AlreadyHook:boolean; {是否已安装Hook，只用于陷阱式}
    AllowChange:boolean; {是否允许安装、卸载Hook，只用于改引入表式}
    Oldcode: array[0..4]of byte; {系统函数原来的前5个字节}
    Newcode: TLongJmp; {将要写在系统函数的前5个字节}
  public
    property OldFunction: Pointer read FOldFunction;
    property NewFunction: Pointer read FNewFunction;
  end;

implementation

{取函数的实际地址。如果函数的第一个指令是Jmp，则取出它的跳转地址（实际地址），这往往是由于程序中含有Debug调试信息引起的}
function FinalFunctionAddress(Code: Pointer): Pointer;
Var
  Func: PImportCode;
begin
  Result:=Code;
  if Code=nil then exit;
  try
    func:=code;
    if (func.JumpInstruction=$25FF) then
      {指令二进制码FF 25  汇编指令jmp [...]}
      Func:=func.AddressOfPointerToFunction^;
    result:=Func;
  except
    Result:=nil;
  end;
end;

{更改引入表中指定函数的地址，只用于改引入表式}
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
  {如果这个DLL模块已经处理过，则退出。BeenDone包含已处理的DLL模块}
  if BeenDone.IndexOf(Dos)>=0 then exit;
  BeenDone.Add(Dos);{把DLL模块名加入BeenDone}
  OldFunc:=FinalFunctionAddress(OldFunc);{取函数的实际地址}

  {如果这个DLL模块的地址不能访问，则退出}
  if IsBadReadPtr(Dos,SizeOf(TImageDosHeader)) then exit;
  {如果这个模块不是以'MZ'开头，表明不是DLL，则退出}
  if Dos.e_magic<>IMAGE_DOS_SIGNATURE then exit;{IMAGE_DOS_SIGNATURE='MZ'}

  {定位至NT Header}
  NT :=Pointer(Integer(Dos) + dos._lfanew);
  {定位至引入函数表}
  RVA:=NT^.OptionalHeader.
     DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
  if RVA=0 then exit;{如果引入函数表为空，则退出}
  {把函数引入表的相对地址RVA转换为绝对地址}
  ImportDesc := pointer(DWORD(Dos)+RVA);{Dos是此DLL模块的首地址}

  {遍历所有被引入的下级DLL模块}
  While (ImportDesc^.Name<>0) do
  begin
    {被引入的下级DLL模块名字}
    DLL:=PChar(DWORD(Dos)+ImportDesc^.Name);
    {把被导入的下级DLL模块当做当前模块，进行递归调用}
    PatchAddressInModule(BeenDone,GetModuleHandle(PChar(DLL)),OldFunc,NewFunc);

    {定位至被引入的下级DLL模块的函数表}
    Func:=Pointer(DWORD(DOS)+ImportDesc.LookupTable);
    {遍历被引入的下级DLL模块的所有函数}
    While Func^<>nil do
    begin
      f:=FinalFunctionAddress(Func^);{取实际地址}
      if f=OldFunc then {如果函数实际地址就是所要找的地址}
      begin
         VirtualQuery(Func,mbi_thunk, sizeof(TMemoryBasicInformation));
         VirtualProtect(Func,SIZE,PAGE_EXECUTE_WRITECOPY,mbi_thunk.Protect);{更改内存属性}
         WriteProcessMemory(GetCurrentProcess,Func,@NewFunc,SIZE,written);{把新函数地址覆盖它}
         VirtualProtect(Func, SIZE, mbi_thunk.Protect,dwOldProtect);{恢复内存属性}
      end;
      If Written=4 then Inc(Result);
//      else showmessagefmt('error:%d',[Written]);
      Inc(Func);{下一个功能函数}
    end;
    Inc(ImportDesc);{下一个被引入的下级DLL模块}
  end;
end;

{HOOK的入口，其中IsTrap表示是否采用陷阱式}
constructor TAPIHook.Create(IsTrap:boolean;OldFun,NewFun:pointer);
begin
   {求被截函数、自定义函数的实际地址}
   FOldFunction:=FinalFunctionAddress(OldFun);
   FNewFunction:=FinalFunctionAddress(NewFun);

   Trap:=IsTrap;
   if Trap then{如果是陷阱式}
   begin
      {以特权的方式来打开当前进程}
      hProcess := OpenProcess(PROCESS_ALL_ACCESS,FALSE, GetCurrentProcessID);
      {生成jmp xxxx的代码，共5字节}
      Newcode.JmpCode := ShortInt($E9); {jmp指令的十六进制代码是E9}
      NewCode.FuncAddr := DWORD(FNewFunction) - DWORD(FOldFunction) - 5;
      {保存被截函数的前5个字节}
      move(FOldFunction^,OldCode,5);
      {设置为还没有开始HOOK}
      AlreadyHook:=false;
   end;
   {如果是改引入表式，将允许HOOK}
   if not Trap then AllowChange:=true;
   Change; {开始HOOK}
   {如果是改引入表式，将暂时不允许HOOK}
   if not Trap then AllowChange:=false;
end;

{HOOK的出口}
destructor TAPIHook.Destroy;
begin
   {如果是改引入表式，将允许HOOK}
   if not Trap then AllowChange:=true;
   Restore; {停止HOOK}
   if Trap then{如果是陷阱式}
      CloseHandle(hProcess);
end;

{开始HOOK}
procedure TAPIHook.Change;
var
   nCount: DWORD;
   BeenDone: TList;
begin
  if Trap then{如果是陷阱式}
  begin
    if (AlreadyHook)or (hProcess = 0) or (FOldFunction = nil) or (FNewFunction = nil) then
        exit;
    AlreadyHook:=true;{表示已经HOOK}
    WriteProcessMemory(hProcess, FOldFunction, @(Newcode), 5, nCount);
  end
  else begin{如果是改引入表式}
       if (not AllowChange)or(FOldFunction=nil)or(FNewFunction=nil)then exit;
       BeenDone:=TList.Create; {用于存放当前进程所有DLL模块的名字}
       try
         PatchAddressInModule(BeenDone,GetModuleHandle(nil),FOldFunction,FNewFunction);
       finally
         BeenDone.Free;
       end;
  end;
end;

{恢复系统函数的调用}
procedure TAPIHook.Restore;
var
   nCount: DWORD;
   BeenDone: TList;
begin
  if Trap then{如果是陷阱式}
  begin
    if (not AlreadyHook) or (hProcess = 0) or (FOldFunction = nil) or (FNewFunction = nil) then
    begin
      OutputDebugString( 'do not need to hook' );
      exit;
    end;
    WriteProcessMemory(hProcess, FOldFunction, @(Oldcode), 5, nCount);
    AlreadyHook:=false;{表示退出HOOK}
  end
  else begin{如果是改引入表式}
    if (not AllowChange)or(FOldFunction=nil)or(FNewFunction=nil)then exit;
    BeenDone:=TList.Create;{用于存放当前进程所有DLL模块的名字}
    try
      PatchAddressInModule(BeenDone,GetModuleHandle(nil),FNewFunction,FOldFunction);
    finally
      BeenDone.Free;
    end;
  end;
end;

end.

