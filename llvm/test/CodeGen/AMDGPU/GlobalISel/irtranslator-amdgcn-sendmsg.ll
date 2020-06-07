; NOTE: Assertions have been autogenerated by utils/update_mir_test_checks.py
; RUN: llc -march=amdgcn -O0 -stop-after=irtranslator -global-isel -verify-machineinstrs %s -o - | FileCheck %s

declare void @llvm.amdgcn.s.sendmsg(i32 immarg, i32)

define amdgpu_ps void @test_sendmsg(i32 inreg %m0) {
  ; CHECK-LABEL: name: test_sendmsg
  ; CHECK: bb.1 (%ir-block.0):
  ; CHECK:   liveins: $sgpr0
  ; CHECK:   [[COPY:%[0-9]+]]:_(s32) = COPY $sgpr0
  ; CHECK:   G_INTRINSIC_W_SIDE_EFFECTS intrinsic(@llvm.amdgcn.s.sendmsg), 12, [[COPY]](s32)
  ; CHECK:   S_ENDPGM
  call void @llvm.amdgcn.s.sendmsg(i32 12, i32 %m0)
  ret void
}
