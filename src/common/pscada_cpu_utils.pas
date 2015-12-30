{ System depending code for light weight threads.

  This file is part of the Free Pascal run time library.

  Copyright (C) 2008 Mattias Gaertner mattias@freepascal.org

  See the file COPYING.FPC, included in this distribution,
  for details about the copyright.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
{$i ../common/pscada_settings.inc}
{$i ../common/pscada_compiler_versions.inc}
unit pSCADA_cpu_utils;

{$IFDEF FPC}
{$mode delphi}
{$ENDIF}

interface

{$IF defined(WIN32) or defined(WIN64) or defined(WINCE)}
uses pSCADA_types, Windows;
{$ELSEIF defined(freebsd) or defined(darwin)}
uses pSCADA_types, ctypes, sysctl;
{$ELSEIF defined(linux)}
{$linklib c}
uses pSCADA_types, pthreads, ctypes;
{$IFEND}


{$IFDEF PORTUGUES}
{:
Retorna o número de processadores instalados.
}
{$ELSE}
{:
Return the number of processor threads installed.
}
{$ENDIF}
function GetSystemThreadCount: LongInt;

{$IFDEF PORTUGUES}
{:
Troca a thread em execução da maneira mais eficiente de acordo com várias
configurações de sistema operacional/número de processadores.
}
{$ELSE}
{:
More efficient thread switch, checking the OS/number of processors.
}
{$ENDIF}
procedure CrossThreadSwitch;

{$IFDEF PORTUGUES}
{:
Configura a afinidade de uma thread com um ou mais processadores processador especifico.
}
{$ELSE}
{:
Sets the thread affinity with one or more processors.
}
{$ENDIF}
function SetThreadCPUAffinityMask(ThreadID:TpSCADAThreadID; CPUAffinity:TpSCADA_CPUs):Boolean;

implementation

{$IFDEF Linux}
const _SC_NPROCESSORS_ONLN = 83;
function sysconf(i: cint): clong; cdecl; external name 'sysconf';
{$ENDIF}

function GetSystemThreadCount: LongInt;
// returns a good default for the number of threads on this system
{$IF defined(WIN32) or defined(WIN64)}
//returns total number of processors available to system including logical hyperthreaded processors
var
  i: LongInt;
  ProcessAffinityMask, SystemAffinityMask: crossNativeUInt;
  Mask: DWORD;
  SystemInfo: SYSTEM_INFO;
begin
  if GetProcessAffinityMask(GetCurrentProcess, ProcessAffinityMask, SystemAffinityMask)
  then begin
    Result := 0;
    for i := 0 to 31 do begin
      Mask := 1 shl i;
      if (ProcessAffinityMask and Mask)<>0 then
        inc(Result);
    end;
  end else begin
    //can't get the affinity mask so we just report the total number of processors
    GetSystemInfo(SystemInfo);
    Result := SystemInfo.dwNumberOfProcessors;
  end;
end;
{$ELSEIF defined(WINCE)}
begin
  Result:=1;
end;
{$ELSEIF defined(UNTESTEDsolaris)}
  begin
    t = sysconf(_SC_NPROC_ONLN);
  end;
{$ELSEIF defined(freebsd) or defined(darwin)}
var
  mib: array[0..1] of cint;
  len: cint;
  t: cint;
begin
  mib[0] := CTL_HW;
  mib[1] := HW_NCPU;
  len := sizeof(t);
  fpsysctl(pchar(@mib), 2, @t, @len, Nil, 0);
  Result:=t;
end;
{$ELSEIF defined(linux)}
  begin
    Result:=sysconf(_SC_NPROCESSORS_ONLN);
  end;
{$ELSE}
  begin
    Result:=1;
  end;
{$IFEND}

procedure CrossThreadSwitch;
begin
  if GetSystemThreadCount>1 then
    {$IFDEF FPC}
    ThreadSwitch
    {$ELSE}
    SwitchToThread
    {$ENDIF}
  else
    {$IF defined(WINDOWS) or defined(WIN32) or defined(WIN64) or defined(WINCE)}
    Sleep(1);
    {$ELSE}
    {$IFDEF FPC}
    ThreadSwitch;
    {$ELSE}
    SwitchToThread;
    {$ENDIF}
    {$IFEND}
end;

function SetThreadCPUAffinityMask(ThreadID:TpSCADAThreadID; CPUAffinity:TpSCADA_CPUs):Boolean;
begin

end;

end.
