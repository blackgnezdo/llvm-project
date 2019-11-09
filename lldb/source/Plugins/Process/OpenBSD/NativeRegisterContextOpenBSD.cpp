//===-- NativeRegisterContextOpenBSD.cpp -------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "NativeRegisterContextOpenBSD.h"

#include "lldb/Host/common/NativeProcessProtocol.h"

using namespace lldb_private;
using namespace lldb_private::process_openbsd;

// clang-format off
#include <sys/types.h>
#include <sys/ptrace.h>
// clang-format on

NativeRegisterContextOpenBSD::NativeRegisterContextOpenBSD(
    NativeThreadProtocol &native_thread,
    RegisterInfoInterface *reg_info_interface_p)
    : NativeRegisterContextRegisterInfo(native_thread,
                                        reg_info_interface_p) {}

Status NativeRegisterContextOpenBSD::ReadGPR() {
  void *buf = GetGPRBuffer();
  if (!buf)
    return Status("GPR buffer is NULL");

  return DoReadGPR(buf);
}

Status NativeRegisterContextOpenBSD::WriteGPR() {
  void *buf = GetGPRBuffer();
  if (!buf)
    return Status("GPR buffer is NULL");

  return DoWriteGPR(buf);
}

Status NativeRegisterContextOpenBSD::ReadFPR() {
  void *buf = GetFPRBuffer();
  if (!buf)
    return Status("FPR buffer is NULL");

  return DoReadFPR(buf);
}

Status NativeRegisterContextOpenBSD::WriteFPR() {
  void *buf = GetFPRBuffer();
  if (!buf)
    return Status("FPR buffer is NULL");

  return DoWriteFPR(buf);
}

Status NativeRegisterContextOpenBSD::DoReadGPR(void *buf) {
  return NativeProcessOpenBSD::PtraceWrapper(PT_GETREGS, GetProcessPid(), buf,
                                            m_thread.GetID());
}

Status NativeRegisterContextOpenBSD::DoWriteGPR(void *buf) {
  return NativeProcessOpenBSD::PtraceWrapper(PT_SETREGS, GetProcessPid(), buf,
                                            m_thread.GetID());
}

Status NativeRegisterContextOpenBSD::DoReadFPR(void *buf) {
  return NativeProcessOpenBSD::PtraceWrapper(PT_GETFPREGS, GetProcessPid(), buf,
                                            m_thread.GetID());
}

Status NativeRegisterContextOpenBSD::DoWriteFPR(void *buf) {
  return NativeProcessOpenBSD::PtraceWrapper(PT_SETFPREGS, GetProcessPid(), buf,
                                            m_thread.GetID());
}

NativeProcessOpenBSD &NativeRegisterContextOpenBSD::GetProcess() {
  return static_cast<NativeProcessOpenBSD &>(m_thread.GetProcess());
}

::pid_t NativeRegisterContextOpenBSD::GetProcessPid() {
  return GetProcess().GetID();
}
